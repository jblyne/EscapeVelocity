extends SceneTree
const Departure=preload("res://scripts/ship_departure.gd")
var game
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func screen(name: String) -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	game.hud._process(0)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/departure-"+name+".png"))
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-ship-departure-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.pilot.cheat_world_killer=true
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.restart();game.pilot.cheat_world_killer=true
	for rate in [30,60,120]:
		var node=game.ShipModels.create(game.catalog,128,-1);game.world.add_child(node)
		node.position=game.v3(Vector2(4000,4000))
		var dep=Departure.new();var fields: Dictionary=game.catalog.record("ships",128).fields
		dep.setup(game,node,node,Vector2(4000,4000),Vector2(0,120),.7,fields)
		var reference=game.Hyperspace.new();reference.begin(dep.destination,dep.route_heading)
		var p=dep.position;var v=dep.velocity;var h: float=dep.heading
		var exact: bool=true;var phases: Array=[]
		for i in rate*40:
			var expected: Dictionary=reference.step(p,v,h,fields,1.0/rate)
			p=expected.position;v=expected.velocity;h=expected.heading
			var done: bool=dep.advance(1.0/rate)
			exact=exact and p.distance_to(dep.position)<.001 and v.distance_to(dep.velocity)<.001 and absf(angle_difference(h,dep.heading))<.0001
			if dep.drive.phase not in phases: phases.append(dep.drive.phase)
			if done: break
		check(dep.complete and exact,"Departure exactly follows player integration at %d Hz" % rate)
		check(phases.has("stopping") and phases.has("aligning") and phases.has("spooling") and phases.has("accelerating"),"All player jump phases execute at %d Hz" % rate)
		check(dep.velocity.length()>2000 and dep.position.distance_to(Vector2(4000,4000))>4000,"Warp carries ship thousands of units instead of stretching in place at %d Hz" % rate)
		check(is_equal_approx(node.scale.z/dep.base_scale.z,game.JumpVisuals.MAX_LENGTH),"Warp reaches normal final stretch at %d Hz" % rate)
		node.queue_free()
	# Real traffic lifecycle keeps selected contacts until their drive finishes.
	var npc: Dictionary=game.traffic.spawn(128,-1,1,Vector2(4000,0));npc.ambient=true;npc.age=101;npc.goal=Vector2(10000,0)
	game.target_index=game.npcs.find(npc);game.traffic.update(.01)
	check(npc in game.npcs and npc.has("departure") and game.selected_contact()==npc,"Ambient exit starts a real jump and preserves targeting")
	var origin: Vector2=npc.position
	game.set_mode("pause");game.traffic.update(10)
	check(npc.position==origin,"NPC jump pauses with menus")
	game.set_mode("flight");var max_speed: float=0;var saw_stretch: bool=false
	for i in 3000:
		if npc not in game.npcs: break
		game.traffic.update(1.0/60);max_speed=maxf(max_speed,npc.velocity.length())
		if npc in game.npcs and npc.departure.drive.phase=="accelerating" and npc.departure.drive.remaining<.8:
			saw_stretch=true
	check(npc not in game.npcs and game.target_index==-1,"NPC retires and selection clears only after completed jump")
	check(max_speed>2000 and saw_stretch and npc.position.distance_to(origin)>4000,"NPC visibly accelerates away and stretches before departure")
	# Starting over a planet must clear its gravity well before spooling.
	npc=game.traffic.spawn(128,-1,1,game.planets[0].position)
	check(game.traffic.request_departure(npc),"Planet-adjacent ship can request departure")
	game.traffic.update(.1)
	check(npc.departure.clearing and npc.departure.drive.phase=="idle","NPC cannot spool inside gravity exclusion")
	for i in 9000:
		if npc not in game.npcs: break
		game.traffic.update(1.0/60)
	check(npc not in game.npcs,"Planet-adjacent ship clears gravity and successfully jumps")
	# Disabling a departing ship cancels its jump without making it disappear.
	npc=game.traffic.spawn(128,-1,1,Vector2(4000,0));game.traffic.request_departure(npc)
	npc.disabled=true;game.traffic.update(.1)
	check(npc in game.npcs and not npc.has("departure"),"Disabled contact cancels hyperdrive and remains boardable")
	var pod: Dictionary=game.traffic.spawn(191,-1,1,Vector2(4000,0))
	check(not game.traffic.request_departure(pod),"Escape pods do not gain fictional hyperdrives")
	game.pilot.fleet=[{"id":128}];game.fleet_service.restore()
	check(not game.traffic.request_departure(game.escorts[0]),"Fleet escorts never autonomously disappear")
	# Death Star: exercise actual controller, not just an isolated scale callback.
	game.restart();game.pilot.cheat_world_killer=true;game.landing_target=int(game.planets[0].id);game.world_activity.open_contact();game.world_killer.threaten();game.world_killer.deploy()
	var station=game.world_killer.station;game.world_killer.open_active();game.world_killer.spare();game.set_mode("flight")
	for i in 850: game.world_killer.advance(1.0/60)
	check(station.departure_started,"Death Star hands withdrawal to shared player hyperdrive")
	var burn_origin=Vector2.ZERO;var peak: float=0;var burned: bool=false;var shot: bool=false
	for i in 3000:
		if station not in game.world_killer.effects: break
		game.world_killer.advance(1.0/60)
		if station.departure.drive.phase=="accelerating":
			if not burned: burn_origin=station.departure.position;burned=true
			peak=maxf(peak,station.departure.velocity.length())
			if not shot and station.departure.drive.remaining<.6:
				game.camera.position=Vector3(station.position.x+100,1200,station.position.z);game.camera.size=900
				await screen("death-star-burn");shot=true
	check(burned and peak>2000,"Death Star uses actual player-speed burn instead of a slow cosmetic stretch")
	check(station.departure.position.distance_to(burn_origin)>4000,"Death Star crosses thousands of units during its warp burn")
	check(station not in game.world_killer.effects,"Death Star leaves the scene after its completed physical departure")
	game.free();await process_frame
	print("SHIP DEPARTURES: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
