extends SceneTree
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func point_at(point: Vector2) -> void:
	var event=InputEventMouseMotion.new();event.position=point;event.global_position=point
	root.push_input(event,true)
	await process_frame
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-menu-hover-test.json";game.traffic.enabled=false
	root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.pilot_ready=true;game.set_mode("title")
	var menu=game.hud.modal_root.get_child(0);menu.set_process(false)
	await process_frame
	menu.animation_time=3*menu.PanelMotion.ROW_SECONDS;menu.pilot_info()
	root.gui_release_focus()
	var enter: Button=menu.canvas.get_node("EnterShip")
	var prefs: Button=menu.canvas.get_node("SetPrefs")
	await point_at(enter.get_global_rect().get_center());menu.update_presentation()
	check(menu.canvas.get_node("Globe01").active,"Mouse over Enter Ship lights its globe")
	check(not menu.canvas.get_node("Globe11").active,"Other panel spheres stay unlit")
	await point_at(prefs.get_global_rect().get_center());menu.update_presentation()
	check(menu.canvas.get_node("Globe11").active and not menu.canvas.get_node("Globe01").active,"Moving between panels transfers the hover animation")
	await point_at(Vector2(1,1));menu.update_presentation()
	check(not menu.canvas.get_node("Globe11").active,"Leaving the panel restores the unlit sphere")
	enter.grab_focus();menu.update_presentation()
	check(menu.canvas.get_node("Globe01").active,"Controller/keyboard focus also lights the sphere")
	enter.disabled=true;menu.update_presentation()
	check(not menu.canvas.get_node("Globe01").active,"Disabled Enter Ship never lights")
	enter.disabled=false;prefs.grab_focus();menu.new_pilot();menu.update_presentation()
	check(not menu.canvas.get_node("Globe11").active,"A modal suppresses background panel hover")
	menu.pilot_info();prefs.grab_focus();menu.animation_time=0;menu.update_presentation()
	check(not menu.canvas.get_node("Globe11").active,"Spheres do not float over unopened panels")
	check(menu.OPENING_DURATION<1.0 and menu.PanelMotion.ROW_SECONDS==menu.OPENING_DURATION,"Entrance is faster and retains sequential pairs")
	if "--visual" in OS.get_cmdline_user_args():
		menu.animation_time=3.0;menu.update_presentation()
		var shots: Array[Image]=[]
		for tick in 4:
			menu.animation_time=3.0+tick*.1;menu.update_presentation()
			for i in 3: await process_frame
			await RenderingServer.frame_post_draw
			var shot: Image=root.get_texture().get_image();shots.append(shot)
			shot.save_png(ProjectSettings.globalize_path("res://../builds/validation/menu-hover-%d.png" % tick))
		check(shots[0].get_data()!=shots[1].get_data() and shots[1].get_data()!=shots[2].get_data(),"Rendered illuminated sphere visibly rotates through distinct frames")
	game.free();await process_frame
	print("MENU HOVER: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
