extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev-mission-clearance.json";game.controls.path="/tmp/ev-mission-clearance-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.pilot.system_id=game.missions.system_of(128);game.load_system();game.set_mode("flight")
 game.pilot.reputation["128"]=-1000
 var service=game.world_activity
 check(not service.landing_reason(128).is_empty(),"Poor standing normally denies landing")
 game.pilot.mission={"object":128,"system":game.pilot.system_id,"reward":1200}
 check(service.landing_reason(128).is_empty() and not service.can_bribe_landing(128),"Courier delivery grants free destination clearance")
 check(not service.landing_reason(129).is_empty(),"Other station in the same system remains restricted")
 game.pilot.mission={}
 var job=game.missions.offer(128,128);job.dest=129;job.back=128;job.travel_done=false;job.deadline=-1
 game.pilot.campaign.active.append(job)
 check(service.landing_reason(129).is_empty(),"Passenger or cargo mission grants station destination access")
 check(not service.landing_reason(128).is_empty(),"Return port is not cleared before reaching delivery stop")
 job.travel_done=true
 check(service.landing_reason(128).is_empty() and not service.landing_reason(129).is_empty(),"Clearance follows the mission's next return stop")
 game.pilot.campaign.day=2;job.deadline=1
 check(not service.landing_reason(128).is_empty(),"Expired mission cannot bypass reputation")
 job.deadline=-1;service.siege={"port":128}
 check(not service.landing_reason(128).is_empty(),"Mission cannot bypass deployed defense fleet")
 service.siege={};game.pilot.world_killer.destroyed.append(128)
 check(not service.landing_reason(128).is_empty(),"Mission cannot grant landing at a destroyed world")
 game.pilot.world_killer.destroyed.clear();game.pilot.campaign.active.clear()
 check(not service.landing_reason(128).is_empty(),"Completing or removing mission ends its clearance")
 check(game.pilot.reputation["128"]==-1000,"Mission clearance does not alter faction standing")
 game.free();await process_frame
 print("MISSION CLEARANCE: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
