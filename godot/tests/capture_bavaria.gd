extends SceneTree
var game
func _initialize(): call_deferred("run")
func snap(name):
 await create_timer(.7).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/ev-bavaria-"+name+".png")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-bavaria.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false)
 game.pilot.system_id=163;game.load_system();game.pilot.position=Vector2.ZERO
 game.camera.position=game.v3(Vector2.ZERO,1200);game.camera.size=550;game.set_mode("flight")
 await snap("space")
 game.docked_id=193;game.hud.port_page="landing";game.set_mode("dock")
 var art=game.hud.modal_root.find_child("LandingScenery",true,false)
 print("BAVARIA ART: ",art.texture," size=",art.size," pos=",art.global_position)
 await snap("landing")
 game.free();await process_frame;quit()
