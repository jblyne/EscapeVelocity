extends SceneTree

# Captures the real flight HUD using an isolated pilot, never the player's save.
var game

func _initialize() -> void:
	call_deferred("capture")

func screenshot(name: String) -> void:
	game.player_model.position=game.v3(game.pilot.position)
	game.player_model.rotation.y=-game.pilot.heading
	game.camera.position=game.v3(game.pilot.position,1200)
	game._process(0)
	game.hud._process(0)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/navigation-%s.png" % name))

func capture() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-navigation-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.select_landing_target(0)
	await screenshot("selected")
	game.land()
	await screenshot("clearance")
	game.pilot.position=game.planets[0].position
	game.velocity=Vector2(80,0)
	await screenshot("slow-down")
	game.velocity=Vector2.ZERO
	await screenshot("ready-to-land")
	game.land()
	await screenshot("port")
	game.launch()
	game.pilot.position=Vector2(12000,12000)
	game.velocity=Vector2(60,-175)
	game.select_destination(136)
	game.start_jump()
	await screenshot("stopping")
	var previous_phase: String=game.hyperdrive.phase
	var captured_acceleration: bool=false
	for frame in 1800:
		game._physics_process(1.0/60)
		if game.hyperdrive.phase!=previous_phase and game.hyperdrive.active():
			previous_phase=game.hyperdrive.phase
			await screenshot(previous_phase)
		if game.hyperdrive.phase=="accelerating" and game.hyperdrive.remaining<1.0 and not captured_acceleration:
			captured_acceleration=true
			await screenshot("acceleration-late")
		if not game.hyperdrive.active(): break
	await screenshot("arrived")
	for frame in 288:
		game._physics_process(1.0/60)
		if frame==59: await screenshot("arrival-plus-1s")
		if frame==179: await screenshot("arrival-plus-3s")
	await screenshot("arrival-plus-4_8s")
	game.set_mode("map")
	await screenshot("arrival-no-route-map")
	game.set_mode("pause")
	await screenshot("pause")
	print("Navigation visual review complete.")
	game.free()
	await process_frame
	quit()
