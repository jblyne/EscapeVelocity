extends SceneTree
var failures=0
var checks=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-presentation-audio.json";game.controls.path="/tmp/ev-presentation-controls.json"
	game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.muted=false
	game.set_mode("title")
	var menu=game.hud.modal_root.get_child(0);menu.set_process(false)
	check(not menu.presentation_started and not game.audio.menu_hum.playing,"Panel audio waits for presentation")
	menu._process(8)
	check(menu.animation_time==0 and not game.audio.menu_slam.playing,"Large setup delta cannot animate or slam behind logo")
	if DisplayServer.get_name()=="headless": await process_frame
	else: await RenderingServer.frame_post_draw
	check(menu.presentation_started and game.audio.menu_hum.playing,"Panel machinery starts only after menu presentation")
	menu._process(8)
	check(menu.animation_time==0 and not game.audio.menu_slam.playing,"First presented update discards setup delta")
	menu._process(.2)
	check(menu.animation_time==.2 and game.audio.menu_hum.playing,"Visible animation and machinery progress together")
	menu._process(menu.MOTION_DURATION-.2+.001)
	check(menu.motion_finished and not game.audio.menu_hum.playing and game.audio.menu_slam.playing,"Slam follows visible panel movement")
	game.set_mode("flight");game.set_mode("title")
	menu=game.hud.modal_root.get_child(0)
	check(menu.backdrop.hide_static_panels and menu.backdrop.material==null,"Returning from flight masks baked-in panels without relying on a canvas shader")
	check(menu.animation_time==0,"Returning from flight starts fresh panel motion")
	game.set_mode("flight")
	if DisplayServer.get_name()=="headless": await process_frame
	else: await RenderingServer.frame_post_draw
	check(not game.audio.menu_hum.playing,"Leaving before presentation cancels pending panel sound")
	game.free();await process_frame
	print("MENU PRESENTATION AUDIO: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
