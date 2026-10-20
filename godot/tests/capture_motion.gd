extends SceneTree

# Visual review in empty space; never reads or writes the player's pilot save.
# Run with --fixed-fps 30 --write-movie ../builds/motion-review.avi.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/qa-motion-pilot.json")
	game.muted = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.Models.set_thrust(game.player_model,0,0)
	game.pilot.position = Vector2(12000,12000)
	game.camera.position = game.v3(game.pilot.position,1200)
	var captures = {29:"stopped", 89:"coasting", 119:"turning", 149:"sideways", 209:"braked"}
	for frame in 240:
		var phase: String = "STOPPED"
		game.velocity = Vector2.ZERO
		game.pilot.heading = 0
		if frame >= 30 and frame < 120:
			game.velocity = Vector2(0,-275)
			phase = "COASTING NORTH · engines off"
			if frame >= 90:
				game.pilot.heading = (frame-90)*PI/60.0
				phase = "TURNING EAST · still drifting north"
		elif frame >= 120 and frame < 180:
			game.pilot.heading = PI/2
			game.velocity = Vector2(275,0)
			phase = "MOVING EAST"
			if frame >= 150:
				game.velocity *= 1.0-(frame-150)/30.0
				phase = "BRAKING"
		if frame == 210:
			game.set_mode("pause")
		game.pilot.position += game.velocity/30.0
		game.player_model.position = game.v3(game.pilot.position)
		game.player_model.rotation.y = -game.pilot.heading
		game._process(1.0/30.0)
		game.hud._process(0)
		game.hud.mission_label.text = "MOTION REVIEW   /   " + phase
		await process_frame
		await RenderingServer.frame_post_draw
		if captures.has(frame):
			var path = ProjectSettings.globalize_path("res://../builds/motion-%s.png" % captures[frame])
			root.get_texture().get_image().save_png(path)
	print("Motion review captured: stopped, coasting, turning, sideways drift, braking, pause.")
	quit()
