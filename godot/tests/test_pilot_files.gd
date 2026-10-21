extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else: failures+=1;push_error(message)
func read_save(path: String) -> Dictionary:
 return JSON.parse_string(FileAccess.get_file_as_string(path))
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var folder="/tmp/ev-pilot-files-%d" % Time.get_ticks_usec();DirAccess.make_dir_recursive_absolute(folder)
 var game=load("res://main.tscn").instantiate();game.save_path=folder.path_join("original.json");game.controls.path=folder.path_join("controls.json");game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 game.remember_pilot_selection=true;game.pilot_selection_path=folder.path_join("active-pilot.json")
 game.pilot_ready=true;game.pilot.pilot_name="Original";game.pilot.credits=12345;game.save_game(false)
 var original=game.save_path;game.pilot.credits=54321
 check(game.create_pilot("Maverick",false),"New pilot creation succeeds")
 var first=game.save_path
 check(read_save(game.pilot_selection_path).path==ProjectSettings.globalize_path(first),"New active pilot is remembered for the next launch")
 check(read_save(original).credits==54321 and read_save(original).pilot_name=="Original","Creating a pilot saves the previous pilot's latest progress")
 check(first!=original and read_save(first).pilot_name=="Maverick","New pilot has its own saved file")
 game.pilot.credits=88888
 check(game.create_pilot("Maverick",true),"Another pilot can use the same display name")
 var second=game.save_path
 check(first!=second and read_save(first).credits==88888 and read_save(second).strict,"Same-name pilots get separate files and prior progress is preserved")
 game.pilot.credits=77777
 check(game.open_pilot_file(original).is_empty(),"Switching back to an existing pilot succeeds")
 check(read_save(second).credits==77777 and game.pilot.pilot_name=="Original" and game.pilot.credits==54321,"Switching pilots saves the outgoing pilot and restores the selected pilot")
 game.pilot.credits=1;game.load_game()
 check(game.pilot.credits==54321,"F9 restores rather than overwriting the last save")
 var active=game.pilot
 game.save_path=folder.path_join("missing/fail.json")
 check(not game.create_pilot("Blocked",false) and game.pilot==active and not game.pilot_file_error.is_empty(),"Failed outgoing save blocks creation and retains the current pilot")
 game.pilot_ready=false
 check(not game.create_pilot("Blocked",false) and game.pilot==active,"Failed new-file creation also retains the current pilot")
 game.save_path=original;game.pilot_ready=true;game.pilot.shield=0;game.pilot.armor=0
 check(game.create_pilot("After death",false) and read_save(original).credits==54321,"New pilot after normal death preserves the last living save")
 game.free();await process_frame
 print("PILOT FILES: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
