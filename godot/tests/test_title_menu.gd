extends SceneTree
var game
var failures=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1;push_error(message)
	else: print("PASS: "+message)
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-title-menu-test.json"
	game.controls.path="/tmp/ev-title-menu-controls.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game)
	game.pilot_ready=false;game.set_mode("title")
	var menu=game.hud.modal_root.get_child(0)
	check(menu.canvas.get_node("EnterShip").disabled,"ship entry disabled without a pilot")
	var event=InputEventKey.new();event.pressed=true;event.physical_keycode=KEY_M
	game._unhandled_key_input(event)
	check(game.mode=="title","flight shortcuts cannot bypass title menu")
	menu.open_pilot()
	check(not game.pilot_ready and game.mode=="title","missing save stays in title menu")
	check(is_instance_valid(menu.pilot_picker) and menu.pilot_picker.visible,"Open Pilot presents a file chooser")
	menu.pilot_picker.hide()
	menu.new_pilot()
	check(not game.pilot_ready,"new pilot requires explicit Begin action")
	event.physical_keycode=KEY_ENTER;menu._unhandled_key_input(event)
	check(game.mode=="title","Enter does not bypass new-pilot creation")
	for child in menu.screen.get_children():
		if child is Button and child.text=="Begin new flight": child.pressed.emit();break
	check(game.pilot_ready and game.mode=="flight","New Pilot begins a flight")
	game.pilot.credits=23456;game.save_game(false)
	game.pilot.credits=99;game.set_mode("title")
	menu=game.hud.modal_root.get_child(0)
	menu.open_pilot_path(game.save_path)
	check(game.mode=="title" and game.pilot.credits==23456,"Open Pilot restores save and waits for Enter Ship")
	menu=game.hud.modal_root.get_child(0)
	event.physical_keycode=KEY_E;menu._unhandled_key_input(event)
	check(game.mode=="flight","Enter Ship resumes loaded pilot")
	game.set_mode("title")
	var position=game.pilot.position
	game._physics_process(1.0)
	check(game.pilot.position==position,"flight pauses behind menu")
	menu=game.hud.modal_root.get_child(0)
	event.physical_keycode=KEY_P;menu._unhandled_key_input(event)
	check(menu.screen.get_child(1) is CheckBox,"preferences offers sound control")
	menu.pilot_info()
	if "--visual" in OS.get_cmdline_user_args():
		for i in 10: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/title-menu.png"))
	game.free();await process_frame
	print("TITLE MENU RESULT: %d failures" % failures)
	quit(1 if failures else 0)
