extends SceneTree
const Debris=preload("res://scripts/planet_debris.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-remnant-preview.json";game.controls.path="/tmp/ev-remnant-preview-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.hud.hide();game.player_model.hide()
	for rock in game.environment_hazards.rocks: rock.node.hide()
	for body in game.planets: body.node.hide()
	game.camera.position=Vector3(0,1200,0);game.camera.size=430
	for i in 2:
		var debris=Debris.new();game.world.add_child(debris)
		debris.setup(Vector3(-160 if i==0 else 160,0,0),65,128+i,i==1);debris.advance(.5)
		var title=Label3D.new();title.text="Shattered planet" if i==0 else "Destroyed station"
		title.billboard=BaseMaterial3D.BILLBOARD_ENABLED;title.font_size=26;title.pixel_size=.5;title.position=Vector3(-160 if i==0 else 160,30,125)
		game.world.add_child(title)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/remnants-0.1.59.png"))
	game.free();await process_frame;quit()
