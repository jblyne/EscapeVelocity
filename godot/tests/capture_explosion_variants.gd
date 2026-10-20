extends SceneTree
const Explosion=preload("res://scripts/explosion.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-explosion-variants.json";game.controls.path="/tmp/ev-explosion-variants-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.hud.hide();game.player_model.hide()
	for rock in game.environment_hazards.rocks: rock.node.hide()
	for body in game.planets: body.node.hide()
	game.camera.position=Vector3(0,1200,0);game.camera.size=920
	var effects: Array=[]
	for i in 4:
		var effect=Explosion.new();game.world.add_child(effect)
		effect.position=Vector3(-270 if i%2==0 else 270,0,-220 if i<2 else 220)
		effect.setup(game.player_model,Vector2.ZERO,42,1.4,i)
		effects.append(effect)
		var label=Label3D.new();label.text=Explosion.STYLE_NAMES[i];label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size=28;label.pixel_size=1.0;label.no_depth_test=true
		label.position=effect.position+Vector3(0,30,155);game.world.add_child(label)
	for time in [.45,1.25]:
		for effect in effects: effect.advance(time-effect.age)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/explosion-variants-0.1.54-%.2f.png" % time))
	game.free();await process_frame;quit()
