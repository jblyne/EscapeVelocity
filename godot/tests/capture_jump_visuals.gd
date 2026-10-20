extends SceneTree
var game

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	game._process(0)
	game.hud._process(0)
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/jump-0115-%s.png" % label))
	print("Captured %s: streak=%.3f, length=%.3f" % [label,game.jump_visuals.departure_strength(game.hyperdrive),game.player_model.scale.z/game.player_base_scale.z])

func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-jump-visuals.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	game.pilot.system_id=129;game.pilot.position=Vector2(-1775.785,-371.617)
	game.pilot.heading=game.Flight.facing(Vector2(39,11))
	game.load_system();game.select_destination(132)
	await process_frame;await process_frame
	game.start_jump()
	var checkpoints={"early":3.0,"streak-start":1.8,"streak-mid":1.0,"streak-full":.1}
	var captured: Dictionary={}
	var draw_times: Array=[]
	for frame in 1200:
		game._physics_process(1.0/60)
		if game.pilot.system_id==132: break
		game._process(1.0/60)
		if game.hyperdrive.phase=="accelerating":
			for label in checkpoints:
				if not captured.has(label) and game.hyperdrive.remaining<=checkpoints[label]:
					await capture(label);captured[label]=true
		await process_frame
		var started=Time.get_ticks_usec()
		RenderingServer.force_draw(false)
		if game.jump_visuals.departure_strength(game.hyperdrive)>.8: draw_times.append((Time.get_ticks_usec()-started)/1000.0)
	await capture("arrival-stretched")
	game.update_jump_visuals(.15);await capture("arrival-squash")
	game.update_jump_visuals(.17);await capture("arrival-rebound")
	game.update_jump_visuals(.4);await capture("arrival-settled")
	draw_times.sort()
	if not draw_times.is_empty(): print("Late-burn explicit draw median: %.3f ms; p95: %.3f ms" % [draw_times[draw_times.size()/2],draw_times[int(draw_times.size()*.95)]])
	var success: bool=game.pilot.system_id==132 and captured.size()==4 and game.player_model.scale==game.player_base_scale
	game.free();await process_frame
	print("Jump visual capture success: ",success)
	quit(0 if success else 1)
