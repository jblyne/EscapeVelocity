extends SceneTree
var game
var failures=0
func _initialize(): call_deferred("run")
func check(value: bool, message: String):
	if not value: failures+=1;push_error(message)
	else: print("PASS: "+message)
func capture(name: String):
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/classic-"+name+".png"))
func run():
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-classic-pilot.json")
	game.traffic.enabled=false
	game.muted=true;root.add_child(game)
	game.set_mode("title")
	var menu=game.hud.modal_root.get_child(0)
	check(menu.panel_material.shader.resource_path.ends_with("menu_panels.gdshader"),"Menu uses registered HD artwork for every animated pose")
	menu.animation_time=2
	if "--visual" in OS.get_cmdline_user_args(): await capture("menu")
	game.set_mode("flight");game.hud._process(0)
	check(not game.hud.target_panel.visible,"full target panel hidden during flight")
	check(is_equal_approx(game.hud.flight_panel.panel_width(),root.get_visible_rect().size.y*0.3),"flight panel preserves original 144:480 proportions")
	if "--visual" in OS.get_cmdline_user_args(): await capture("flight")
	game.combat_drill();game.hud._process(0)
	if "--visual" in OS.get_cmdline_user_args(): await capture("target")
	check(not game.selected_contact().is_empty(),"target selection remains available in classic flight layout")
	var info_key=InputEventKey.new();info_key.physical_keycode=KEY_P;info_key.pressed=true
	game._unhandled_key_input(info_key);game.hud._process(0)
	check(game.mode=="info","P opens player information")
	check(game.hud.target_panel.visible,"full target details accessible in information screen")
	var position=game.pilot.position;game._physics_process(1)
	check(game.pilot.position==position,"information screen pauses flight")
	if "--visual" in OS.get_cmdline_user_args(): await capture("info")
	game.set_mode("pause");game.set_mode("info");game.set_mode("flight")
	check(is_instance_valid(game.hud.target_panel),"target panel survives repeated modal rebuilds")
	game.set_mode("info")
	var key=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.pressed=true;game._unhandled_key_input(key)
	check(game.mode=="flight","Escape closes information screen")
	game.hud.flight_panel.nav_hit.pressed.emit()
	check(game.mode=="map","clicking navigation opens map")
	game.set_mode("flight")
	game.hud.flight_panel.info_hit.pressed.emit()
	check(game.mode=="info","clicking target or cargo opens full information")
	game.set_mode("flight")
	game.hud.flight_panel.menu_hit.pressed.emit()
	check(game.mode=="pause","subtle Menu control exposes settings")
	game.set_mode("flight")
	if "--visual" in OS.get_cmdline_user_args():
		root.size=Vector2i(1100,740);await capture("small")
		game.set_mode("pause");await capture("pause")
	game.free();await process_frame
	print("CLASSIC UI RESULT: %d failures" % failures)
	quit(1 if failures else 0)
