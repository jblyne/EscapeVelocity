extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(name: String):
	game.hud._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/world-"+name+".png"))
func run():
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-world-visual.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_physics_process(false);game.set_process(false)
	game.pilot.system_id=game.missions.system_of(146);game.load_system();game.landing_target=146
	game.docked_id=146;game.set_mode("dock");game.world_activity.activate(138,0)
	game.hud.rebuild_modal();await capture("port")
	game.world_activity.open_news();await capture("news")
	game.set_mode("flight");game.world_activity.open_contact();await capture("contact")
	root.size=Vector2i(1100,740);await capture("contact-small")
	game.world_activity.open_news();await capture("news-small")
	game.queue_free();await process_frame;quit()
