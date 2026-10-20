extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-asteroid-preview.json"
	game.controls.path="/tmp/ev-asteroid-preview-controls.json"
	game.traffic.enabled=false;game.muted=true
	root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.hud.hide();game.player_model.hide()
	for rock in game.environment_hazards.rocks: rock.node.hide()
	for body in game.planets: body.node.hide()
	game.camera.position=Vector3(0,1200,0);game.camera.size=580
	var rng=RandomNumberGenerator.new();rng.seed=57
	for i in 12:
		var node=game.environment_hazards.AsteroidModels.create(game.world,Vector3((i%4-1.5)*145,0,(i/4-1)*140),rng.randf_range(32,47),i)
		node.rotation=Vector3(rng.randf(),rng.randf(),rng.randf())*TAU
		node.scale*=Vector3(1.1,.85,1.0)
	await process_frame;await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/asteroids-0.1.50.png"))
	game.free();await process_frame;quit()
