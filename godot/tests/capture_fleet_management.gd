extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(name: String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/fleet-"+name+".png"))
func run():
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/fleet-ui-pilot.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.restart();game.pilot.credits=1000000;game.pilot.fleet=[{"id":146},{"id":132}];game.load_system()
	game.docked_id=128;game.set_mode("dock");game.toggle_fleet_menu()
	await capture("management")
	game.fleet_service.takeover_candidate=game.escorts[0];game.hud.rebuild_modal()
	await capture("takeover")
	game.free();await process_frame;quit()
