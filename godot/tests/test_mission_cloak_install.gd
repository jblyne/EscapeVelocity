extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 if FileAccess.file_exists("/tmp/ev-cloak-install.json"): DirAccess.remove_absolute("/tmp/ev-cloak-install.json")
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-cloak-install.json";game.controls.path="/tmp/ev-cloak-install-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.pilot.campaign.bits=[35,44];game.pilot.campaign.rating=10000;game.pilot.reputation["129"]=100
 game.pilot.system_id=game.missions.system_of(161);game.load_system();game.docked_id=161;game.set_mode("dock");game.hud.port_page="bar"
 game.missions.begin_bar_approach()
 for i in 200:
  game.missions.advance_bar(.1)
  if game.mode=="mission_offer": break
 check(int(game.missions.approach.get("id",-1))==164,"Insertion mission approaches at Palshife after special-ops introduction")
 var button=game.hud.modal_root.find_child("AcceptApproach",true,false)
 check(button is Button and button.text=="Accept & install cloak","Offer explicitly identifies installation action")
 check(button.position.x+maxf(button.size.x,button.get_combined_minimum_size().x)<=800,"Full accept label fits inside the approach panel")
 button.pressed.emit()
 check(game.pilot.outfit_count(167)==1 and game.cloak.available(),"Accept button installs actual usable Cloaking Device")
 check(game.pilot.campaign.active.any(func(m):return int(m.id)==164),"Insertion mission is recorded as active")
 check(game.missions.active_landing_report.status.contains("Cloaking Device installed"),"Acceptance confirms installation and K shortcut")
 game.set_mode("flight")
 check(game.cloak.toggle() and game.cloak.active,"K action can engage the newly installed device after launch")
 game.cloak.set_active(false)
 var saved=game.pilot.snapshot();var restored=game.Pilot.new()
 check(restored.restore(saved,game.catalog) and restored.outfit_count(167)==1,"Mission cloak persists through save restoration")
 check(not game.missions.eligibility(164,161,false),"Active insertion mission cannot be repeatedly offered")
 var patrol=game.traffic.spawn(135,128,3,game.pilot.position)
 game.missions.scan_missions()
 check(not game.pilot.campaign.active.any(func(m):return int(m.id)==164) and game.pilot.outfit_count(167)==0,"Confed scan fails the insertion and removes its loaned cloak")
 check(game.missions.flight_alert.contains("Loaned Cloaking Device removed") and game.missions.last_report.contains("patrol detected"),"Failure explicitly explains scan detection and cloak removal")
 game.hud._process(0)
 check(game.hud.mission_failure_label.visible,"Scan failure remains visible on the flight HUD")
 check(game.missions.eligibility(164,161,false),"Failed insertion legitimately becomes available to retry")
 game.free();await process_frame
 print("MISSION CLOAK INSTALL: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
