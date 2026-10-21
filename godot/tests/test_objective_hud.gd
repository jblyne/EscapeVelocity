extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-objective-hud.json";game.controls.path="/tmp/ev-objective-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.pilot.campaign.active=[];game.pilot.mission={};game.set_mode("flight")
 var service=game.missions
 check(service.tracked_objective().is_empty(),"No mission readout without active jobs")
 var delivery=service.offer(128,128);delivery.dest=132;delivery.back=-1;delivery.travel_done=false;delivery.picked=true
 game.pilot.campaign.active.append(delivery);service.tracked_id=128
 check(service.next_objective(delivery).contains("Luna") and service.next_objective(delivery).contains("deliver passengers"),"Delivery instruction identifies action and exact planet")
 game.hud._process(0)
 check(game.hud.combat_return_label.visible and game.hud.combat_return_label.text.contains("NEXT"),"Current objective is displayed persistently in flight")
 var insertion=service.offer(164,161);game.pilot.campaign.active.append(insertion);service.tracked_id=164
 check(service.tracked_objective().contains("Cloak with K") and service.tracked_objective().contains("Luna"),"Special Ops shows immediate destination and cloak warning")
 insertion.travel_done=true;insertion.delivered=true
 check(service.next_objective(insertion).contains("Return to") and not service.next_objective(insertion).contains("reward"),"Completed insertion delivery advances to return objective")
 var defense=service.offer(148,192);defense.ship_system=game.pilot.system_id
 defense.actors=[]
 for i in 5: defense.actors.append({"dead":i<2})
 check(service.next_objective(defense).contains("3 remaining attacker"),"Combat readout counts remaining targets")
 for actor in defense.actors: actor.dead=true
 check(service.next_objective(defense).contains("for payment"),"Combat readout changes to payment objective")
 game.missions.return_mode="flight";game.missions.channel=2;game.set_mode("missions")
 var list=game.hud.modal_root.find_child("MissionList",true,false)
 list.item_selected.emit(0)
 check(service.tracked_id==128,"Choosing journal entry switches tracked mission")
 game.set_mode("flight");game.pilot.campaign.active.clear();game.pilot.mission={"object":128,"system":game.missions.system_of(128),"reward":1200}
 service.tracked_id=-2
 check(service.tracked_objective().contains("Earth") and service.tracked_objective().contains("deliver your parcels"),"Introductory courier job also has a next action")
 game.pilot.mission={};game.hud._process(0)
 check(not game.hud.combat_return_label.visible,"Readout disappears after all jobs finish")
 game.free();await process_frame
 print("OBJECTIVE HUD: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
