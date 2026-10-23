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
 DirAccess.make_dir_recursive_absolute("/tmp/ev232-pilots")
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev232-pilots/current.json";game.controls.path="/tmp/ev103-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 game.save_path="/tmp/ev232-pilots/current.json"
 game.pilot.pilot_name="First Pilot";game.pilot.credits=12345;game.pilot_ready=true;game.save_game(false)
 var original_path: String=game.save_path
 var original: String=FileAccess.get_file_as_string(game.save_path)
 var alternate: Dictionary=game.pilot.snapshot();alternate.pilot_name="Selected Pilot";alternate.credits=98765
 var path=ProjectSettings.globalize_path("/tmp/ev232-pilots/other pilot.json");write_json(path,alternate)
 game.set_mode("title");var menu=game.hud.modal_root.get_child(0)
 write_json("/tmp/ev232-pilots/preferences.json",{"sound":true})
 write_json("/tmp/ev232-pilots/broken.json",{"invalid":true})
 var pad=game.controls.controller
 pad.set_process(false);pad.set_process_input(false);pad.last_mode="title";pad.using_pad=true
 pad.selected=menu.canvas.get_node("OpenPilot")
 pad.menu_button(JOY_BUTTON_A)
 check(menu.pilot_picker.visible and menu.pilot_picker.item_count==2,"Custom list shows only valid pilots, excluding preferences and invalid saves")
 check(menu.canvas.get_node("LogoCreditsHotspot").get_index()<menu.dialog.get_index(),"Logo hotspot stays behind pilot dialog and cannot block the first row")
 check(menu.pilot_picker.get_theme_stylebox("hovered_selected_focus").bg_color==Color.BLACK and menu.pilot_picker.get_theme_color("font_hovered_selected_color")==Color.WHITE,"Focused selected pilot retains contrasting colors on hover")
 check(pad.selected==menu.pilot_picker,"Controller activation preserves the pilot list focus handoff")
 if "--visual" in OS.get_cmdline_user_args():
  menu.animation_time=5;menu.update_presentation();menu.set_process(false)
  for i in 4: await process_frame
  pad.queue_redraw()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/validation/open-pilot-0.1.251.png"))
 var before: int=menu.pilot_picker.get_selected_items()[0]
 pad.menu_button(JOY_BUTTON_DPAD_DOWN)
 check(menu.pilot_picker.get_selected_items()[0]==before+1,"First D-pad press immediately changes pilot, without entering list first")
 pad.menu_button(JOY_BUTTON_DPAD_UP)
 check(menu.pilot_picker.get_selected_items()[0]==before,"Up immediately returns to previous pilot")
 var found: int=-1
 for i in menu.pilot_picker.item_count:
  if menu.pilot_picker.get_item_metadata(i)==path: found=i
 check(found>=0,"Pilot is listed by saved identity")
 menu.pilot_info();check(game.pilot.pilot_name=="First Pilot","Canceling pilot selection preserves the active pilot")
 menu.open_pilot();menu.pilot_picker.select(found)
 menu.pilot_picker.item_activated.emit(found)
 check(game.pilot.pilot_name=="Selected Pilot" and game.pilot.credits==98765 and game.save_path==path,"File selection loads the chosen pilot and activates its save path")
 check(game.mode=="title" and not menu.canvas.get_node("EnterShip").disabled and "Selected Pilot" in menu.pilot_readout.text,"Loaded pilot is shown on title screen before Enter Ship")
 game.save_game(false);check(FileAccess.get_file_as_string(original_path)==original,"Autosave does not overwrite the previous pilot")
 write_json("/tmp/ev103-invalid.json",{"invalid":true});menu.open_pilot_path("/tmp/ev103-invalid.json")
 check(game.pilot.pilot_name=="Selected Pilot" and game.save_path==path,"Invalid pilot leaves the active pilot and save path intact")
 alternate.strict=true;alternate.strict_dead=true;write_json("/tmp/ev103-dead.json",alternate)
 check(not game.open_pilot_file("/tmp/ev103-dead.json").is_empty() and game.save_path==path,"Permanently deceased strict pilot cannot be opened")
 check(not game.open_pilot_file("/tmp/ev103-missing-unique.json").is_empty() and game.pilot.pilot_name=="Selected Pilot","Missing file reports an error without changing pilot")
 game.set_mode("flight");game.load_game();check(game.pilot.pilot_name=="Selected Pilot" and game.mode=="flight","F9 restores the selected pilot")
 game.free();await process_frame
 print("OPEN PILOT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
