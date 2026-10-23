extends SceneTree
var game
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/test-exhaust-pilot.json")
	game.traffic.enabled = false
	game.muted = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	var first = game.ShipModels.create(game.catalog,900,-1)
	var second = game.ShipModels.create(game.catalog,130,-1)
	game.world.add_child(first)
	game.world.add_child(second)
	first.position = game.v3(game.pilot.position+Vector2(-140,0))
	second.position = game.v3(game.pilot.position+Vector2(140,0))
	var flame = first.get_node("Flame-1")
	var other = second.get_node("Flame-1")
	check(flame.material_override is ShaderMaterial,"exhaust uses translucent plasma shader")
	check(flame.material_override != other.material_override,"each ship has independent exhaust material")
	var anchored = true
	for power in [0.25,0.65,1.0,1.6]:
		game.Models.set_thrust(first,power,.4)
		anchored = anchored and (flame.position-Vector3(0,0,.7*flame.scale.z)).is_equal_approx(flame.get_meta("nozzle"))
	check(anchored,"plume remains attached to nozzle at every throttle")
	game.Models.set_thrust(first,1,.4)
	var normal_length: float = flame.scale.z
	game.Models.set_thrust(first,1.6,.4)
	check(flame.scale.z > normal_length,"afterburner produces longer plume")
	game.Models.set_thrust(second,0,.4)
	check(not other.visible and flame.visible,"coasting hides only that ship's exhaust")
	game.Models.set_thrust(first,1,.5)
	check(flame.material_override.get_shader_parameter("clock") == .5,"simulation clock drives plume turbulence")
	game.Models.set_thrust(second,1.6,.5)
	game.Models.set_thrust(game.player_model,1,.5)
	game.Models.set_thrust(first,1.6,10,true)
	check(flame.material_override.get_shader_parameter("afterburner_heat")==0.0,"Hyperspace burn begins with blue exhaust")
	game.Models.set_thrust(first,1.6,10.99,true)
	check(not first.get_meta("afterburner_active"),"Blue exhaust lasts the full first second")
	game.Models.set_thrust(second,1.6,11.01,false,true)
	game.engine_smoke.advance(.016)
	check(game.engine_smoke.puffs.is_empty(),"Other ships never emit afterburner smoke")
	game.Models.set_thrust(second,0,11.02)
	game.Models.set_thrust(second,1.6,10,true)
	game.Models.set_thrust(second,1.6,12,true)
	check(other.material_override.get_shader_parameter("afterburner_heat")==0.0,"Other ships retain blue exhaust throughout hyperspace")
	game.Models.set_thrust(first,1.6,11.01,true)
	var early_heat: float=flame.material_override.get_shader_parameter("afterburner_heat")
	game.Models.set_thrust(first,1.6,11.325,true)
	var middle_heat: float=flame.material_override.get_shader_parameter("afterburner_heat")
	check(early_heat>0 and early_heat<middle_heat and middle_heat<1,"F-14 ignition ramps gradually after its blue warm-up")
	check(flame.material_override.get_shader_parameter("ignition_flare")>.9,"Ignition blooms into a bright expanding flare")
	game.Models.set_thrust(first,1.6,11.66,true)
	check(flame.material_override.get_shader_parameter("afterburner_heat")==1.0,"F-14 finishes transitioning to orange afterburner")
	game.engine_smoke.advance(.016)
	check(not game.engine_smoke.puffs.is_empty(),"Orange afterburner emits smoke")
	var trail_position: Vector2=game.engine_smoke.puffs[0].position
	first.position.x+=100;game.engine_smoke.advance(.016)
	check(game.engine_smoke.puffs[0].position==trail_position,"Smoke remains in world space after ship moves")
	game.Models.set_thrust(first,0,11.7)
	game.engine_smoke.advance(1.01)
	check(game.engine_smoke.puffs.is_empty(),"Smoke dissipates one second after the burn stops")
	game.Models.set_thrust(first,1.6,12,false,true)
	check(first.get_meta("afterburner_active"),"Manual afterburner also leaves smoke")
	game.Models.set_thrust(first,1.6,13,true)
	check(not first.get_meta("afterburner_active"),"A new hyperspace burn restarts blue warm-up")
	if "--visual" in OS.get_cmdline_user_args():
		for frame in 30:
			game.Models.set_thrust(first,1.6,14+float(frame)/60,true)
			first.position.z-=6;game.engine_smoke.advance(1.0/60)
		game.camera.position = game.v3(game.pilot.position+Vector2(0,40),1200)
		game.camera.size = 480
		game.hud._process(0)
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/exhaust-plumes.png"))
	game.free()
	await process_frame
	print("EXHAUST RESULT: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
