extends SceneTree
const Projectiles=preload("res://scripts/projectile_models.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-projectile-preview.json";game.controls.path="/tmp/ev-projectile-preview-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.hud.hide();game.player_model.hide()
	for rock in game.environment_hazards.rocks: rock.node.hide()
	for body in game.planets: body.node.hide()
	game.camera.position=Vector3(0,1200,0);game.camera.size=180
	var ids=[140,139,132,131,150,141]
	var names=["Space bomb","Heavy rocket","Missile","Torpedo","Decoy flare","Javelin rocket"]
	for i in ids.size():
		var model=Projectiles.create(ids[i]);game.world.add_child(model)
		model.position=Vector3((i-2.5)*44,0,0);Projectiles.advance(model,.3)
		var label=Label3D.new();label.text=names[i];label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size=24;label.pixel_size=.16;label.position=model.position+Vector3(0,30,45);game.world.add_child(label)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/projectile-models-0.1.61.png"))
	game.free();await process_frame;quit()
