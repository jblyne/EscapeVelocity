extends SceneTree
const DeathStar=preload("res://scripts/death_star.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-death-star-surface.json";game.controls.path="/tmp/ev-death-star-surface-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.hud.hide();game.player_model.hide()
	for rock in game.environment_hazards.rocks: rock.node.hide()
	for body in game.planets: body.node.hide()
	game.camera.position=Vector3(0,1200,0);game.camera.size=450
	for i in 3:
		var station=DeathStar.new();station.game=game;game.world.add_child(station);station.setup()
		station.update_sequence(99,Vector3(0,0,-1000))
		station.position=Vector3((i-1)*190,0,0)
		station.scale=Vector3.ONE*(1.25 if i==0 else .85 if i==1 else .4)
		station.rotation=Vector3(.2*i,.9*i,.15*i)
		station.counter.hide()
	await process_frame;await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/death-star-surface-0.1.53.png"))
	game.free();await process_frame;quit()
