extends SceneTree
var failures: int=0
var checks: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev192-dialog-pilot.json";game.controls.path="/tmp/ev192-dialog-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.set_mode("title");var menu=game.hud.modal_root.get_child(0);menu.animation_time=3;menu.update_presentation()
	for page in ["new_pilot","about"]:
		if page=="about": menu.about_with_modifiers(false,false)
		else: menu.call(page)
		for i in 4: await process_frame
		check(menu.dialog.theme.get_stylebox("panel","PanelContainer").bg_color==Color("e8eeee"),"Original light Mac dialog: "+page)
		check(menu.get_global_rect().encloses(menu.dialog.get_global_rect()),"Dialog stays on screen: "+page)
		check((menu.screen.find_child("NewPilotPrompt",true,false).get_theme_color("font_color") if page=="new_pilot" else menu.screen.get_child(0).get_theme_color("font_color"))==Color.BLACK,"Black caption text: "+page)
		if "--visual" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/ev192-"+page+".png")
	menu.open_pilot()
	check(menu.pilot_picker is ItemList and menu.dialog.visible,"Open Pilot uses the classic modal pilot list")
	for i in 3: await process_frame
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/ev192-open.png")
	menu.pilot_picker.hide();menu.pilot_info()
	menu.original_credits();await process_frame
	check(menu.extras_panel.theme!=null and menu.credits_label.get_theme_color("font_color")==Color.BLACK,"Credits share the classic dialog treatment")
	menu.close_extras();await process_frame
	game.open_controls();await process_frame
	var controls=game.hud.modal_root.get_child(0)
	check(controls.canvas.get_node("PreferencesPaper").get_theme_stylebox("panel").bg_color==Color.WHITE and controls.tabs.size()==2,"Main-menu preferences use the white classic tabbed dialog")
	if "--visual" in OS.get_cmdline_user_args():
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/ev192-controls.png")
	game.free();await process_frame
	print("TITLE DIALOGS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
