extends SceneTree
var failures=0
func check(ok: bool,message: String) -> void:
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev207-pause-pilot.json";game.controls.path="/tmp/ev207-controls.json"
	game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.pilot_ready=true;game.pilot.credits=43210;game.set_mode("pause")
	var menu=game.hud.modal_root.get_child(0)
	var button=menu.find_child("MainMenu",true,false)
	check(button is Button and button.text=="Main Menu","Escape menu has clearly named Main Menu button")
	button.pressed.emit()
	check(game.mode=="title","Main Menu returns to title screen")
	var saved=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(int(saved.credits)==43210,"Returning to menu saves current pilot")
	game.set_mode("pause");game.save_path="/tmp/nonexistent-ev207-folder/pilot.json"
	menu=game.hud.modal_root.get_child(0);menu.find_child("MainMenu",true,false).pressed.emit()
	check(game.mode=="pause" and menu.canvas.get_node("ResumeHint").text.contains("Save failed"),"Failed save keeps player paused and shows error")
	game.free();await process_frame
	print("PAUSE MAIN MENU: %d failures" % failures);quit(1 if failures else 0)
