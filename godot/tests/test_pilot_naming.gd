extends SceneTree
var failures=0
func check(ok: bool,message: String):
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.controls.path="/tmp/ev244-naming-controls.json";game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 game.set_mode("title");var menu=game.hud.modal_root.get_child(0);menu.set_process(false)
 var previous=game.pilot;var previous_path: String=game.save_path
 menu.new_pilot()
 check(menu.screen.find_child("PilotName",true,false).text in menu.DEFAULT_NAMES.data.pilots,"Pilot default is one of the three recovered original names")
 menu.screen.find_child("PilotName",true,false).text="Stud Beefpile"
 menu.screen.find_child("StrictPlay",true,false).button_pressed=true
 menu.screen.find_child("ConfirmPilotName",true,false).pressed.emit()
 check(menu.naming_stage=="ship" and game.pilot==previous and game.save_path==previous_path,"Naming pilot only stages changes")
 check(menu.screen.find_child("ShipName",true,false).text in menu.DEFAULT_NAMES.data.ships,"Ship default is one of the three recovered original names")
 menu.screen.find_child("CancelShipName",true,false).pressed.emit()
 check(game.pilot==previous and game.save_path==previous_path and not menu.dialog.visible,"Cancel ship naming preserves active pilot")
 menu.new_pilot();menu.screen.find_child("PilotName",true,false).text="Stud Beefpile"
 menu.screen.find_child("ConfirmPilotName",true,false).pressed.emit()
 menu.screen.find_child("ShipName",true,false).text="Adventurer"
 menu.screen.find_child("ConfirmShipName",true,false).pressed.emit()
 check(game.mode=="title" and game.pilot_ready and game.hud.modal_root.get_child(0)==menu,"Creation stays on the same menu without entering flight or intro")
 check(game.pilot.ship_name=="Adventurer" and game.pilot.pilot_name=="Stud Beefpile","Pilot and ship names retained independently")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(game.save_path));var restored=game.Pilot.new()
 check(restored.restore(saved,game.catalog) and restored.ship_name=="Adventurer","Ship name persists through save and load")
 saved.erase("ship_name");check(restored.restore(saved,game.catalog),"Existing pilots without ship names remain compatible")
 check(menu.pilot_readout.text.contains("Pilot Name:") and menu.pilot_readout.text.contains("Ship Name:") and menu.pilot_readout.text.contains("Harmless") and menu.pilot_readout.text.contains("Current Date:"),"Readout contains original summary sections before Enter Ship")
 if "--visual" in OS.get_cmdline_user_args():
  menu.animation_time=5;menu.update_presentation()
  var folder=ProjectSettings.globalize_path("res://../builds/validation/pilot-naming");DirAccess.make_dir_recursive_absolute(folder)
  for stage in ["summary","pilot","ship"]:
   if stage=="pilot":menu.new_pilot()
   if stage=="ship":menu.name_ship()
   for i in 4:await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(folder.path_join(stage+".png"))
 game.free();await process_frame
 print("PILOT NAMING: %d failures" % failures);quit(1 if failures else 0)
