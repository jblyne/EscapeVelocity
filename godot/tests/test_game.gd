extends SceneTree

const Catalog=preload("res://scripts/catalog.gd")
const Pilot=preload("res://scripts/pilot.gd")
const Flight=preload("res://scripts/flight.gd")
const Hyperspace=preload("res://scripts/hyperspace.gd")
const Travel=preload("res://scripts/travel_rules.gd")
const StellarModels=preload("res://scripts/stellar_models.gd")
var count: int=0
var failures: int=0

func check(condition: bool, description: String) -> void:
	count+=1
	if not condition:
		failures+=1
		push_error("FAIL: "+description)
	else: print("PASS: "+description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_travel_rules()
	var c=Catalog.new()
	check(c.data.systems.size()==108 and c.data.ships.size()==28,"original catalog plus SS-Maverick counts")
	var p=Pilot.new()
	check(p.fuel==400,"new pilots use the original four-jump shuttle tank")
	check(not p.trade(0,false,120,20),"cannot sell absent cargo")
	p.credits=0
	check(not p.trade(0,true,120,20),"cannot buy without funds")
	p.credits=10000
	for i in 20: p.trade(0,true,120,20)
	check(p.cargo_used()==20 and not p.trade(1,true,200,20),"cargo capacity is enforced")
	check(not p.accept_job(136,128,20),"mission cargo cannot overfill hold")
	p=Pilot.new()
	check(not p.jump(129,c.system(128).links),"nonadjacent jumps are rejected")
	check(p.jump(136,c.system(128).links) and p.fuel==Pilot.FUEL_CAPACITY-100,"valid jump consumes exactly one fuel unit")
	p.fuel=99
	check(not p.jump(128,c.system(136).links),"low-fuel jump is rejected")
	p=Pilot.new()
	check(p.accept_job(136,134,20),"contract reserves cargo")
	check(p.deliver(134)==0,"delivery requires correct system")
	p.system_id=136
	check(p.deliver(134)==1200 and p.deliver(134)==0,"contract pays exactly once")
	p=Pilot.new()
	p.position=Vector2(123,-456)
	p.cargo[0]=3
	var loaded=Pilot.new()
	check(loaded.restore(JSON.parse_string(JSON.stringify(p.snapshot())),c) and loaded.position==p.position and loaded.cargo[0]==3,"save roundtrip preserves pilot")
	var old_save=p.snapshot();old_save.fuel=400
	check(loaded.restore(old_save,c) and loaded.fuel==400,"older saves with the normal fuel reserve still load")
	var too_much_fuel=p.snapshot();too_much_fuel.fuel=Pilot.FUEL_CAPACITY+1
	check(not loaded.restore(too_much_fuel,c),"save validation enforces the ship fuel limit")
	var invalid=p.snapshot();invalid.system_id=99999
	check(not loaded.restore(invalid,c) and loaded.position==p.position,"invalid save is rejected atomically")
	invalid=p.snapshot();invalid.cargo=[100,0,0,0,0,0]
	check(not loaded.restore(invalid,c),"over-capacity save rejected")
	var ends: Array=[]
	for fps in [30,60,120]:
		var pos=Vector2.ZERO;var vel=Vector2.ZERO;var angle: float=0
		for frame in fps*3:
			var result=Flight.step(pos,vel,angle,0,true,false,c.record("ships",128).fields,1.0/fps)
			pos=result.position;vel=result.velocity;angle=result.heading
		ends.append(pos)
		check(vel.length()<=275.001,"speed limit at %d Hz" % fps)
	check(ends[0].distance_to(ends[2])<0.2,"flight displacement stable across frame rates")
	test_retrograde(c.record("ships",128).fields)
	test_hyperspace(c.record("ships",128).fields)
	test_arrival_geometry(c)
	# Exercise the actual game scene and UI in addition to isolated rules.
	var game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted=true
	game.traffic.enabled = false # Isolate this feature from independently tested ambient traffic.
	root.add_child(game)
	game.set_physics_process(false)
	var home=game.planets[0]
	game.pilot.position=home.position
	game.land()
	check(game.mode=="flight" and game.landing_clearance==home.id,"first L requests clearance even when already stopped over the planet")
	game.pilot.position=home.position+Vector2(0,180)
	game.land()
	check(game.mode=="flight","landing from the old generous approach radius is rejected")
	game.pilot.position=home.position+Vector2(0,home.radius+0.01)
	game.land()
	check(game.mode=="flight","stopped ship just outside the visible planet cannot land")
	game.pilot.position=home.position+Vector2(0,home.radius*0.5)
	game.velocity=Vector2(Travel.MAX_LANDING_SPEED+0.01,0)
	game.land()
	check(game.mode=="flight","ship over a planet but above landing speed cannot land")
	game.pilot.position=home.position+Vector2(0,home.radius)
	game.velocity=Vector2(Travel.MAX_LANDING_SPEED,0)
	game.land()
	check(game.mode=="dock","landing succeeds at the visible edge and maximum permitted speed")
	game.start_jump()
	check(not game.hyperdrive.active() and game.mode=="dock","hyperspace cannot start while docked")
	game.trade(0,true)
	check(game.pilot.cargo[0]==1,"landing-screen purchase updates pilot")
	game.accept_job()
	var destination=int(game.pilot.mission.system)
	var object_id=int(game.pilot.mission.object)
	var credits_before=game.pilot.credits
	game.launch()
	game.start_jump()
	check(not game.hyperdrive.active() and game.pilot.fuel==Pilot.FUEL_CAPACITY and game.pilot.system_id==128,"planet proximity blocks hyperspace without consuming fuel or changing system")
	game.hud._process(0)
	check(game.hud.jump_button.disabled and "Too close to" in game.hud.jump_status.text,"HUD explains and disables a jump blocked by proximity")
	# A charge begun outside the limit must abort if momentum takes us inside.
	game.pilot.position=home.position+Vector2(0,home.radius+Travel.HYPERSPACE_CLEARANCE+0.01)
	game.velocity=Vector2(0,-100)
	game.start_jump()
	check(game.hyperdrive.active(),"clearance allows hyperspace stopping phase to begin")
	game._physics_process(1.0/60.0)
	check(not game.hyperdrive.active() and game.pilot.fuel==Pilot.FUEL_CAPACITY and game.pilot.system_id==128,"drifting into a gravity exclusion area cancels charging without fuel loss")
	game.pilot.position=home.position+Vector2(0,home.radius+Travel.HYPERSPACE_CLEARANCE+2000)
	game.velocity=Vector2.ZERO
	game.start_jump()
	game.land()
	check(game.mode=="flight" and game.hyperdrive.active(),"landing cannot interrupt a charging hyperdrive")
	game.hud._process(0)
	check(not game.hud.jump_button.disabled and game.hud.jump_button.text=="Cancel  J","HUD offers cancellation during hyperspace")
	game.cycle_destination()
	game.select_destination(int(game.catalog.system(128).links[-1]))
	check(game.destination==destination and game.hyperdrive.destination==destination,"active jump locks destination against keyboard and map changes")
	game.set_mode("pause")
	var paused_phase=game.hyperdrive.phase
	var paused_position=game.pilot.position
	game._physics_process(2)
	check(game.hyperdrive.phase==paused_phase and game.pilot.position==paused_position,"pausing freezes the jump sequence and movement")
	game.set_mode("flight")
	for i in 1800:
		game._physics_process(1.0/60.0)
		if game.pilot.system_id==destination: break
	check(game.pilot.system_id==destination and game.pilot.fuel==Pilot.FUEL_CAPACITY-100,"actual hyperdrive transitions systems")
	check(not game.hyperdrive.active() and game.landing_clearance==-1 and game.landing_target==-1,"arrival clears jump and landing state")
	var incoming = Vector2(-21,24).normalized()
	var entry_position: Vector2 = game.pilot.position
	check(game.velocity.distance_to(incoming*275)<0.01 and absf(angle_difference(game.pilot.heading,Flight.facing(incoming)))<0.001,"Levo to Rigel arrives at cruise speed along the incoming route")
	check((game.planets[0].position-entry_position).dot(incoming)>1300,"arrival starts upstream, well outside the immediate planetary view")
	game.hud._process(0)
	check(game.destination==-1 and game.hud.destination_label.text=="No route" and game.hud.jump_button.disabled,"single-hop arrival clears navigation and disables another jump until a route is chosen")
	game.set_mode("map")
	check(game.hud.modal_root.get_child_count()>0,"map opens safely with no selected destination after arrival")
	game.set_mode("flight")
	game.start_jump()
	check(not game.hyperdrive.active(),"J after arrival cannot silently select a new route")
	for frame in 288: game._physics_process(1.0/60)
	check(game.pilot.position.distance_to(entry_position+incoming*1320)<0.1 and game.velocity.distance_to(incoming*275)<0.01,"hands-off arrival coasts steadily for 4.8 seconds without automatic braking")
	check(game.pilot.position.distance_to(game.planets[0].position)<50,"shuttle passes close to the central planet about five seconds after entry")
	for planet in game.planets:
		if planet.id==object_id:game.pilot.position=planet.position
	game.velocity=Vector2.ZERO
	game.land()
	game.land()
	check(game.mode=="dock" and game.pilot.mission.is_empty() and game.pilot.credits==credits_before+1200,"full courier loop completes and pays")
	game.service()
	check(game.pilot.fuel==Pilot.FUEL_CAPACITY,"port service refuels")
	check(game.save_game(false),"save writes atomically to disk")
	game.pilot.credits=0
	game.load_game()
	check(game.pilot.credits>0,"disk save restores progression")
	game.pilot.fuel=0
	var before_refill=game.pilot.snapshot();before_refill.erase("fuel")
	var refill_key=InputEventKey.new()
	refill_key.physical_keycode=KEY_G;refill_key.pressed=true
	game._unhandled_key_input(refill_key)
	var after_refill=game.pilot.snapshot();after_refill.erase("fuel")
	check(game.pilot.fuel==Pilot.FUEL_CAPACITY and before_refill==after_refill,"G refills fuel for free without changing pilot progress or location")
	check(game.service_cost()==0,"servicing a full debugging tank cannot charge or award credits")
	game.pilot.fuel=0
	game.load_game()
	check(game.pilot.fuel==Pilot.FUEL_CAPACITY,"debugging reserve is saved and restored above the old fuel limit")
	test_return_jump(game)
	test_navigation_edges(game)
	game.combat_drill()
	check(game.target_index>=0 and game.npcs[game.target_index].hostile,"combat drill spawns and targets a hostile")
	var npc=game.npcs[game.target_index]
	npc.position=game.pilot.position+Vector2(0,-80)
	var before=float(npc.health)
	game.fire(game.pilot.position,0,false)
	game.update_shots(.1)
	check(npc.health<before,"projectile segment collision damages target")
	game.set_mode("map")
	check(game.mode=="map","galaxy map opens")
	game.set_mode("pause")
	check(game.mode=="pause","pause panel opens")
	await process_frame
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://../builds/test-pilot.json"))
	print("RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)

func test_retrograde(fields: Dictionary) -> void:
	var result = {"position":Vector2.ZERO,"velocity":Vector2(0,-150),"heading":0.0}
	for i in 240:
		result = Flight.step(result.position,result.velocity,result.heading,0,false,true,fields,1.0/60)
	check(result.velocity==Vector2(0,-150) and result.position.distance_to(Vector2(0,-600))<0.01,"Down turns against drift without slowing or redirecting travel")
	check(absf(angle_difference(result.heading,PI))<0.0001,"Down finishes facing opposite actual velocity")
	var slowing = Flight.step(result.position,result.velocity,result.heading,0,true,false,fields,0.1)
	check(slowing.velocity.length()<result.velocity.length(),"main-engine thrust decelerates a ship facing against drift")
	var still = Flight.step(Vector2.ZERO,Vector2.ZERO,0.7,0,false,true,fields,1)
	check(still.heading==0.7 and still.velocity==Vector2.ZERO,"Down at rest preserves heading and velocity")
	var manual = Flight.step(Vector2.ZERO,Vector2(0,-150),0,1,false,true,fields,0.1)
	check(manual.heading>0,"manual steering takes precedence over Down")
	var wrapped = Flight.step(Vector2.ZERO,Vector2(0,150),PI-0.01,0,false,true,fields,0.01)
	check(absf(angle_difference(PI-0.01,wrapped.heading))<=float(fields.Maneuver)*Flight.TURN_SCALE*0.01+0.00001,"retrograde steering respects turn rate across angle wrap")

func test_hyperspace(fields: Dictionary) -> void:
	for fps in [30,60,120]:
		var drive = Hyperspace.new()
		drive.begin(136,PI/2)
		var motion = {"position":Vector2.ZERO,"velocity":Vector2(80,-180),"heading":0.0}
		var phases: Array = []
		var safe_stop: bool = true
		var safe_alignment: bool = true
		var completed: bool = false
		var saw_braking: bool = false
		var safe_spool: bool = true
		var spool_time: float = 0
		var acceleration_time: float = 0
		var burn_distance: float = 0
		var continuous_acceleration: bool = true
		var speed_before: float = motion.velocity.length()
		for frame in fps*30:
			var previous_phase: String = drive.phase
			var previous_speed: float = motion.velocity.length()
			var previous_position: Vector2 = motion.position
			motion = drive.step(motion.position,motion.velocity,motion.heading,fields,1.0/fps)
			if drive.phase not in phases: phases.append(drive.phase)
			if previous_phase=="stopping":
				if motion.thrust>0: saw_braking=true
				if motion.velocity.length()>previous_speed+0.001: safe_stop=false
				if motion.thrust==0 and previous_speed>Hyperspace.STOP_TOLERANCE and absf(previous_speed-motion.velocity.length())>0.001: safe_stop=false
			if drive.phase=="aligning" and motion.velocity.length()>0.001: safe_alignment=false
			if previous_phase=="spooling":
				spool_time+=1.0/fps
				if motion.thrust!=0 or motion.velocity.length()>0.001 or absf(angle_difference(motion.heading,PI/2))>0.001: safe_spool=false
			if drive.phase=="accelerating" and absf(angle_difference(motion.heading,PI/2))>0.001: safe_alignment=false
			if previous_phase=="accelerating":
				acceleration_time+=1.0/fps
				burn_distance+=motion.position.distance_to(previous_position)
				if not motion.complete and motion.velocity.length()<=previous_speed: continuous_acceleration=false
			if frame==0:
				check(motion.thrust==0 and is_equal_approx(motion.velocity.length(),speed_before),"misaligned autopilot turns before firing engines at %d Hz" % fps)
			if motion.complete:
				completed=true
				break
		check(completed and phases==["stopping","aligning","spooling","accelerating"],"jump completes stop → align → spool → accelerate at %d Hz" % fps)
		check(saw_braking and safe_stop and safe_alignment,"engine braking stops before alignment and acceleration at %d Hz" % fps)
		check(safe_spool and absf(spool_time-0.6)<=1.01/fps,"aligned spool lasts only 0.6 seconds at %d Hz" % fps)
		check(motion.velocity.x>0 and absf(motion.velocity.y)<0.001,"hyperspace acceleration follows the warp line at %d Hz" % fps)
		check(continuous_acceleration and absf(acceleration_time-4.8)<=1.01/fps,"departure keeps accelerating for 4.8 seconds at %d Hz" % fps)
		check(absf(motion.velocity.length()-2062.5)<0.1 and absf(burn_distance-4950)<0.5,"departure reaches 7.5 times cruise speed and travels 4950 units at %d Hz" % fps)
		var coasting=Flight.step(motion.position,motion.velocity,motion.heading,0,false,false,fields,1.0/fps)
		check(coasting.velocity.distance_to(motion.velocity)<0.001,"canceling a fast departure can coast without a one-frame speed clamp at %d Hz" % fps)
		var braking=Flight.step(motion.position,motion.velocity,Flight.facing(-motion.velocity),0,true,false,fields,1.0/fps)
		check(braking.velocity.length()<motion.velocity.length() and braking.velocity.length()>float(fields.Speed),"main engines can brake excess departure momentum progressively at %d Hz" % fps)

func test_arrival_geometry(c) -> void:
	var fields: Dictionary=c.record("ships",128).fields
	var primary={"name":"Offset primary","position":Vector2(900,-600),"radius":100.0}
	var entry=Hyperspace.arrival(PI/2,fields,[primary])
	check(entry.position.x<primary.position.x-1300 and absf(entry.position.y-primary.position.y)<50,"offset primary gets the same directional approach as a central world")
	var upstream={"name":"Upstream world","position":entry.position,"radius":120.0}
	var extended=Hyperspace.arrival(PI/2,fields,[primary,upstream])
	check(extended.position.x<entry.position.x and Travel.hyperspace_obstacle(extended.position,[primary,upstream]).is_empty(),"multi-world arrival extends upstream to clear every gravity exclusion circle")
	var empty=Hyperspace.arrival(0,fields,[])
	check(empty.position.is_equal_approx(Vector2(0,1320)) and empty.velocity.is_equal_approx(Vector2(0,-275)),"empty systems arrive on a moving approach toward system center")
	var all_clear: bool=true
	var routes: int=0
	for system in c.data.systems.values():
		var bodies: Array=[]
		for id in system.objects:
			var obj=c.record("objects",int(id))
			bodies.append({"name":obj.name,"position":Vector2(obj.fields.xPos,obj.fields.yPos),"radius":StellarModels.radius(c.stellar_type(int(obj.fields.Type)))})
		for source_id in system.links:
			var source=c.system(int(source_id))
			var direction=Vector2(system.fields.xPos-source.fields.xPos,system.fields.yPos-source.fields.yPos)
			var arrival=Hyperspace.arrival(Flight.facing(direction),fields,bodies)
			if not Travel.hyperspace_obstacle(arrival.position,bodies).is_empty(): all_clear=false
			routes+=1
	check(all_clear and routes>200,"every connected catalog approach starts clear of all planets and stations")

func test_return_jump(game) -> void:
	game.select_destination(128)
	game.pilot.position=Vector2(12000,12000)
	game.velocity=Vector2(-21,24).normalized()*275
	game.pilot.heading=Flight.facing(game.velocity)
	var reserve: float=game.pilot.fuel
	game.start_jump()
	var duration: float=0
	var checked_spool: bool=false
	for frame in 1800:
		game._physics_process(1.0/60)
		duration+=1.0/60
		if game.hyperdrive.phase=="spooling" and not checked_spool:
			checked_spool=true
			var remaining: float=game.hyperdrive.remaining
			game.set_mode("pause")
			game._physics_process(10)
			check(game.hyperdrive.remaining==remaining,"pause freezes the aligned spool countdown")
			game.set_mode("flight")
		if not game.hyperdrive.active(): break
	var recording_extension: float=game.audio.jump_start.stream.get_length()-game.hyperdrive.SPOOL_SECONDS-game.hyperdrive.ACCELERATION_SECONDS
	check(game.pilot.system_id==128 and duration>=7+recording_extension and duration<=8+recording_extension,"return jump preserves alignment time and the complete native warp recording")
	print("Observed-reference return maneuver in remake: %.3f s" % duration)
	check(game.pilot.fuel==reserve-100 and game.velocity.x>0 and game.velocity.y<0 and game.pilot.position.x<0 and game.pilot.position.y>0,"Rigel to Levo arrives from the opposite side, moving northeast, spending fuel once")
	# Select a new route after the one-hop navigation reset.
	game.cycle_destination()
	check(game.destination in game.catalog.system(128).links,"N selects a connected route after arrival clears navigation")

func test_navigation_edges(game) -> void:
	game.pilot.position=Vector2(12000,12000)
	game.velocity=Vector2(125,20)
	var reserve: float=game.pilot.fuel
	game.start_jump()
	game._physics_process(0.1)
	var coast: Vector2=game.velocity
	game.start_jump()
	check(not game.hyperdrive.active() and game.velocity==coast and game.pilot.fuel==reserve,"J cancels without removing momentum or using fuel")
	game.velocity=Vector2.ZERO
	game.start_jump()
	for frame in 1200:
		game._physics_process(1.0/60)
		if game.hyperdrive.phase=="accelerating" and game.velocity.length()>800: break
	var burn_remaining: float=game.hyperdrive.remaining
	var fast_velocity: Vector2=game.velocity
	var fast_position: Vector2=game.pilot.position
	game.set_mode("pause")
	game._physics_process(5)
	check(game.hyperdrive.remaining==burn_remaining and game.velocity==fast_velocity and game.pilot.position==fast_position,"pause freezes high-speed departure motion and countdown")
	game.set_mode("flight")
	game.start_jump()
	game._physics_process(1.0/60)
	check(not game.hyperdrive.active() and game.velocity.distance_to(fast_velocity)<0.001 and game.velocity.length()>800 and game.pilot.fuel==reserve,"J cancels an actual boosted departure without spending fuel or discarding momentum")
	game.start_jump()
	game.load_game()
	check(not game.hyperdrive.active() and game.landing_clearance==-1,"loading a save discards transient navigation state")
	# Exercise world selection in a system with multiple landable objects.
	for system in game.catalog.data.systems.values():
		if system.objects.size()>=2:
			game.pilot.system_id=int(system.id)
			break
	game.load_system()
	var first=game.planets[0]
	var second=game.planets[1]
	game.select_landing_target(0)
	game.land()
	game.pilot.position=second.position
	game.velocity=Vector2.ZERO
	game.land()
	check(game.mode=="flight" and game.landing_clearance==first.id,"clearance for one world cannot dock at another")
	var selection=InputEventKey.new()
	selection.physical_keycode=KEY_2;selection.pressed=true
	game._unhandled_key_input(selection)
	check(game.landing_target==second.id and game.landing_clearance==-1,"number keys select a world and require fresh clearance")
	game.land()
	check(game.mode=="flight" and game.landing_clearance==second.id,"selected world grants clearance before landing")
	game.land()
	check(game.mode=="dock" and game.docked_id==second.id,"second L docks at the selected cleared world")
	game.launch()
	check(game.landing_clearance==-1,"launch requires new clearance for the next landing")
	# Proximity is checked through the last spool tick, before the burn begins.
	game.pilot.position=Vector2(12000,12000)
	game.start_jump()
	game.hyperdrive.phase="spooling"
	game.hyperdrive.remaining=0
	game.hyperdrive.heading=0
	game.pilot.heading=0
	game.pilot.position=first.position
	game._physics_process(1.0/60)
	check(not game.hyperdrive.active() and game.pilot.fuel==reserve,"gravity exclusion prevents departure from starting at the end of the spool without fuel loss")

func test_travel_rules() -> void:
	var small={"name":"Station","position":Vector2.ZERO,"radius":40.0}
	var large={"name":"Planet","position":Vector2(800,0),"radius":100.0}
	check(Travel.landing_body(Vector2(40.01,0),[small]).is_empty(),"small bodies use their own visible landing radius")
	check(not Travel.landing_body(Vector2(40,0),[small]).is_empty(),"landing is allowed exactly on a small body's edge")
	var overlapping={"name":"Large world","position":Vector2(100,0),"radius":120.0}
	check(Travel.landing_body(Vector2(50,0),[small,overlapping]).name=="Large world","landing finds a covered body even if a closer center is outside its disk")
	check(Travel.hyperspace_obstacle(Vector2.ZERO,[]).is_empty(),"empty systems have no planet proximity restriction")
	check(not Travel.hyperspace_obstacle(Vector2(539.99,0),[small]).is_empty(),"jump blocked just inside surface clearance")
	check(Travel.hyperspace_obstacle(Vector2(540,0),[small]).is_empty(),"jump allowed exactly at surface clearance")
	check(Travel.hyperspace_obstacle(Vector2(541,0),[small,large]).body.name=="Planet","being clear of one body does not bypass another body's exclusion area")
	var nearer={"name":"Near small station","position":Vector2(0,550),"radius":40.0}
	var farther={"name":"Far large planet","position":Vector2(0,-590),"radius":100.0}
	check(Travel.hyperspace_obstacle(Vector2.ZERO,[nearer,farther]).body.name=="Far large planet","clearance checks every surface, not only the nearest center")
