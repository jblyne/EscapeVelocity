extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-bar-offer-list.json";game.controls.path="/tmp/ev-bar-offer-controls.json"
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.pilot.campaign.bits=[44];game.pilot.campaign.rating=22000;game.pilot.reputation["129"]=639
 game.docked_id=208;game.set_mode("dock")
 var service=game.missions
 for visit in 20:
  game.pilot.campaign.visit=visit
  var offers=service.offers(208,1)
  check(offers.any(func(m):return int(m.id)==148) and offers.any(func(m):return int(m.id)==146),"Eligible Rebel Defense and Assassination visible at Virgo regardless of approach roll %d" % visit)
 # Find a failed random roll, then prove that a displayed offer can be accepted.
 for visit in 100:
  game.pilot.campaign.visit=visit
  if not service.eligibility(148,208): break
 service.last_report="Mission complete: old job from another system"
 service.channel=1;service.open()
 check(service.last_report.is_empty(),"Opening local offers clears a stale prior completion report")
 var list=game.hud.modal_root.find_child("MissionList",true,false)
 check(list is ItemList and list.item_count>0,"Actual Bar Offers UI contains local jobs")
 check(service.accept(service.offer(148,208)),"Visible job can be accepted despite failed random approach roll")
 check(not service.offers(208,1).any(func(m):return int(m.id)==148),"Already active mission stays excluded")
 service.last_report="Old completion";service.begin_port_visit()
 check(service.last_report.is_empty(),"Arriving at another port also clears stale report")
 game.pilot.campaign.bits=[];game.pilot.reputation["129"]=-1
 check(not service.offers(208,1).any(func(m):return int(m.id)==172),"List still enforces actual reputation requirements")
 game.free();await process_frame
 print("BAR OFFER LIST: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
