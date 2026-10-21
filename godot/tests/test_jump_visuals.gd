extends SceneTree
var game
var count: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	count += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1;push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func test_stable_flight() -> void:
	var flame=game.player_model.get_node("Flame-1")
	var model_pose=game.player_model.transform
	game.Models.set_thrust(game.player_model,1,.12)
	var steady=flame.scale
	game.Models.set_thrust(game.player_model,1,.23)
	check(flame.visible and flame.scale==steady and game.player_model.transform==model_pose,"normal thrusters keep steady exhaust and never shake the hull")
	game.Models.set_thrust(game.player_model,1,.12,true)
	var pulsed=flame.scale
	game.Models.set_thrust(game.player_model,1,.23,true)
	check(flame.scale!=pulsed,"hyperspace acceleration retains exhaust vibration")
	var drive=game.Hyperspace.new()
	var quiet=true
	for phase in ["idle","stopping","aligning","spooling"]:
		drive.phase=phase
		quiet=quiet and game.jump_visuals.ship_offset(drive,.23)==Vector3.ZERO
	check(quiet,"coasting, normal thrust, braking, alignment and spooling have no hull vibration")
	drive.phase="accelerating";drive.remaining=.3
	var offset: Vector3=game.jump_visuals.ship_offset(drive,.23)
	check(offset.length()>0 and offset.length()<2 and offset!=game.jump_visuals.ship_offset(drive,.24),"only the hyperspace burn gets a bounded changing hull vibration")
	game.pilot.position=Vector2(12000,12000);game.velocity=Vector2(275,0)
	game.previous_player_position=game.pilot.position;game.previous_player_velocity=game.velocity
	var positions: Array[Vector3]=[]
	for tick in 60:
		game._physics_process(1.0/60)
		for alpha in [0.0,.5]:
			game.update_player_render(alpha);game.update_jump_visuals(0)
			positions.append(game.player_model.position)
	var smooth=true
	for i in range(1,positions.size()):
		smooth=smooth and (positions[i]-positions[i-1]).distance_to(Vector3(275.0/120,0,0))<.003
	check(smooth,"120 Hz rendering advances smoothly between 60 Hz physics ticks instead of alternating jumps and still frames")
	var before=game.pilot.snapshot()
	game.previous_player_heading=deg_to_rad(179);game.pilot.heading=deg_to_rad(-179)
	game.update_player_render(.5)
	check(absf(absf(game.player_model.rotation.y)-PI)<.001,"rendered steering takes the short path across the angle wrap")
	game.pilot.heading=before.heading
	check(game.pilot.snapshot()==before,"render interpolation and hull vibration do not change pilot state")
	game.load_system()
	check(game.rendered_player_position==game.v3(game.pilot.position) and game.previous_player_position==game.pilot.position,"system loading resets interpolation instead of drawing a streak across systems")

func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-jump-visual-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	check(game.player_model.scale==game.player_base_scale and game.jump_visuals.arrival_age<0,"normal startup leaves the ship at its original proportions")
	test_stable_flight()
	game.pilot.position=Vector2(12000,12000)
	game.start_jump()
	for phase in ["stopping","aligning","spooling"]:
		game.hyperdrive.phase=phase;game.update_jump_visuals(0)
		check(game.player_model.scale==game.player_base_scale and game.space_material.get_shader_parameter("warp_stretch")==0.0,"no stretching during "+phase)
	game.hyperdrive.phase="accelerating"
	game.hyperdrive.remaining=2.01;game.update_jump_visuals(0)
	check(game.player_model.scale==game.player_base_scale,"early acceleration retains normal ship and star shapes")
	game.hyperdrive.remaining=1.0;game.update_jump_visuals(0)
	check(game.space_material.get_shader_parameter("warp_stretch")==0.5 and game.player_model.scale.z>game.player_base_scale.z and game.player_model.scale.x<game.player_base_scale.x,"the last two seconds progressively stretch stars and the ship")
	game.hyperdrive.remaining=0.0;game.update_jump_visuals(0)
	var stretched=game.player_model.scale
	check(is_equal_approx(stretched.z/game.player_base_scale.z,2.8),"departure reaches the intended longitudinal stretch")
	game.pilot.heading=PI/2;game.player_model.rotation.y=-game.pilot.heading
	check((-game.player_model.basis.z.normalized()).dot(Vector3.RIGHT)>.999,"ship stretching follows its local forward axis when jumping sideways")
	game.velocity=Vector2(1500,0)
	game.cancel_jump()
	check(game.velocity==Vector2(1500,0) and game.player_model.scale==game.player_base_scale and game.space_material.get_shader_parameter("warp_stretch")==0.0 and game.jump_visuals.arrival_age<0,"manual cancellation clears the visuals while preserving departure momentum")
	game.velocity=Vector2.ZERO
	game.pilot.fuel=game.pilot.fuel_capacity()
	var departure_fuel: float=game.pilot.fuel
	game.start_jump()
	var destination: int=game.hyperdrive.destination
	for i in 1200:
		game._physics_process(1.0/60)
		if game.pilot.system_id==destination: break
		game._process(1.0/60)
	check(game.pilot.system_id==destination and game.pilot.fuel==departure_fuel-100 and absf(game.velocity.length()-float(game.pilot.flight_fields(game.catalog.record("ships",game.pilot.ship_id).fields).Speed))<.01,"visuals preserve successful transition, cruise-speed arrival, and one fuel charge")
	check(game.jump_visuals.arrival_age==0.0 and game.player_model.scale.is_equal_approx(stretched) and game.space_material.get_shader_parameter("warp_stretch")==0.0,"new-system arrival retains the stretched ship and immediately returns stars to normal")
	var saved=game.pilot.snapshot()
	game.update_jump_visuals(.15)
	check(game.player_model.scale.z<game.player_base_scale.z and game.player_model.scale.x>game.player_base_scale.x,"arrival contracts past normal into a brief rubber-band squash")
	var age: float=game.jump_visuals.arrival_age
	var pose=game.player_model.scale
	game.set_mode("pause");game._process(10)
	check(game.jump_visuals.arrival_age==age and game.player_model.scale==pose,"pause freezes the arrival recoil instead of skipping it")
	game.set_mode("flight");game.update_jump_visuals(.17)
	check(game.player_model.scale.z>game.player_base_scale.z,"resuming continues the small elastic rebound")
	game.update_jump_visuals(.4)
	check(game.player_model.scale==game.player_base_scale and game.jump_visuals.arrival_age<0 and game.pilot.snapshot()==saved,"recoil settles to exact original size without altering pilot physics or saved progress")
	for fps in [30,60,120]:
		game.jump_visuals.arrive()
		for frame in int(fps*.3): game.update_jump_visuals(1.0/fps)
		check(absf(game.jump_visuals.arrival_age-.3)<.00001 and absf(game.player_model.scale.z/game.player_base_scale.z-1.042139)<.0001,"recoil agrees at the same elapsed time at %d Hz" % fps)
	game.jump_visuals.arrive();game.update_jump_visuals(0)
	game.load_game()
	check(game.player_model.scale==game.player_base_scale and game.jump_visuals.arrival_age<0,"loading a save removes transient stretch and does not replay arrival")
	game.jump_visuals.arrive();game.update_jump_visuals(0)
	game.set_mode("dead")
	check(game.player_model.scale==game.player_base_scale and game.jump_visuals.arrival_age<0,"death cancels transient jump visuals")
	game.free();await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://../builds/test-jump-visual-pilot.json"))
	print("JUMP VISUAL RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
