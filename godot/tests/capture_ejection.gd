extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(name: String):
	game.hud._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/ejection-"+name+".png"))
func run():
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-ejection-visual.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.restart()
	game.pilot.outfits={"154":1,"181":1};game.ejection.request();await capture("confirm")
	game.ejection.begin();game._physics_process(.5);await capture("pod")
	game.ejection.advance(3);await capture("rescue")
	game.free();await process_frame;quit()
