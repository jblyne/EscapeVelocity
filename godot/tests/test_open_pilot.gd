extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
 else: print("PASS: "+message)
func write_json(path: String,value) -> void:
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(value));file.close()
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev103-current.json";game.controls.path="/tmp/ev103-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 game.pilot.pilot_name="First Pilot";game.pilot.credits=12345;game.pilot_ready=true;game.save_game(false)
 var original: String=FileAccess.get_file_as_string(game.save_path)
 var alternate: Dictionary=game.pilot.snapshot();alternate.pilot_name="Selected Pilot";alternate.credits=98765
 var path="/tmp/ev103-other pilot.json";write_json(path,alternate)
 game.set_mode("title");var menu=game.hud.modal_root.get_child(0)
 menu.open_pilot();check(menu.pilot_picker.visible and menu.pilot_picker.file_mode==FileDialog.FILE_MODE_OPEN_FILE,"File chooser opens for pilot selection")
 menu.pilot_picker.hide();check(game.pilot.pilot_name=="First Pilot","Canceling file selection preserves the active pilot")
 menu.pilot_picker.file_selected.emit(path)
 check(game.pilot.pilot_name=="Selected Pilot" and game.pilot.credits==98765 and game.save_path==path,"File selection loads the chosen pilot and activates its save path")
 check(game.mode=="title" and not menu.canvas.get_node("EnterShip").disabled and "Selected Pilot" in menu.pilot_readout.text,"Loaded pilot is shown on title screen before Enter Ship")
 game.save_game(false);check(FileAccess.get_file_as_string("/tmp/ev103-current.json")==original,"Autosave does not overwrite the previous pilot")
 write_json("/tmp/ev103-invalid.json",{"invalid":true});menu.open_pilot_path("/tmp/ev103-invalid.json")
 check(game.pilot.pilot_name=="Selected Pilot" and game.save_path==path,"Invalid pilot leaves the active pilot and save path intact")
 alternate.strict=true;alternate.strict_dead=true;write_json("/tmp/ev103-dead.json",alternate)
 check(not game.open_pilot_file("/tmp/ev103-dead.json").is_empty() and game.save_path==path,"Permanently deceased strict pilot cannot be opened")
 check(not game.open_pilot_file("/tmp/ev103-missing-unique.json").is_empty() and game.pilot.pilot_name=="Selected Pilot","Missing file reports an error without changing pilot")
 game.set_mode("flight");game.load_game();check(game.pilot.pilot_name=="Selected Pilot" and game.mode=="flight","F9 restores the selected pilot")
 game.free();await process_frame
 print("OPEN PILOT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
