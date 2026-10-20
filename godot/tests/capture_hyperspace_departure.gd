extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/qa-hyperspace-departure.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	root.add_child(game)
	game.set_physics_process(false)
	game.pilot.system_id = 129
	game.pilot.position = Vector2(-1775.78515625, -371.617431640625)
	game.pilot.heading = game.Flight.facing(Vector2(39,11))
	game.pilot.fuel = 1000
	game.load_system()
	game.select_destination(132)
	await create_timer(0.5).timeout
	game.start_jump()
	game.set_physics_process(true)
	var started = Time.get_ticks_msec()
	var captured_crossing: bool = false
	while game.hyperdrive.active() and Time.get_ticks_msec()-started < 20000:
		await process_frame
		if not captured_crossing and game.pilot.system_id == 129 and game.hyperdrive.phase == "accelerating" and not game.Travel.hyperspace_obstacle(game.pilot.position,game.planets).is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/hyperspace-0113-crossing.png"))
			captured_crossing = true
	game.set_physics_process(false)
	var success: bool = captured_crossing and game.pilot.system_id == 132 and game.pilot.fuel == 900 and game.audio.arrival.playing and not game.audio.jump.playing
	game.hud._process(0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/hyperspace-0113-arrival.png"))
	print("REALTIME DEPARTURE: success=%s, system=%s, fuel=%s, speed=%.2f, arrival_sound=%s, seconds=%.2f" % [success,game.catalog.system(game.pilot.system_id).name,game.pilot.fuel,game.velocity.length(),game.audio.arrival.playing,(Time.get_ticks_msec()-started)/1000.0])
	for player in game.audio.values(): player.stop()
	game.engine_audio.stop()
	await create_timer(0.15).timeout
	game.free()
	await process_frame
	quit(0 if success else 1)
