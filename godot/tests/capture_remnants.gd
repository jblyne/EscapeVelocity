extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-remnant-preview.json";game.controls.path="/tmp/ev-remnant-preview-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.hide();game.player_model.hide()
	for body in game.planets: body.node.hide()
	for rock in game.environment_hazards.rocks: rock.node.hide()
	game.camera.position=Vector3(0,1200,0);game.camera.size=390
	for metallic in [true,false]:
		var debris=load("res://scripts/planet_debris.gd").new();game.world.add_child(debris)
		debris.setup(Vector3(-165 if metallic else 165,0,0),100,129,metallic,true);debris.advance(12)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/remnants-0.1.65.png"))
	game.free();await process_frame;quit()
