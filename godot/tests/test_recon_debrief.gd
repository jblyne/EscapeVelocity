extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-recon-debrief.json";game.controls.path="/tmp/ev-recon-debrief-controls.json"
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 var service=game.missions
 game.pilot.campaign.active=[];game.pilot.campaign.bits=[56];game.pilot.reputation["129"]=100
 game.pilot.system_id=service.system_of(209);game.load_system();game.docked_id=209;game.set_mode("dock")
 service.return_mode="dock";service.channel=1;game.set_mode("missions")
 check(service.accept(service.offer(185,209)),"Actual Sirgil III bar offer accepts Lead Rebel Patrol")
 var mission=game.pilot.campaign.active[0]
 var instruction=service.next_objective(mission)
 check(instruction.contains("Topaz") and instruction.contains("destroying them is not required"),"Patrol guidance identifies the catalog's encounter system and observation objective")
 check(not instruction.contains("payment") and not instruction.contains("reward"),"Unpaid patrol does not promise a bounty")
 game.pilot.system_id=int(mission.ship_system);game.load_system();game.set_mode("flight")
 check(service.ship_goal_done(mission),"Observing patrol contacts fulfills the original ShipGoal 4")
 instruction=service.next_objective(mission)
 check(instruction.contains("Reconnaissance complete") and instruction.contains("Sirgil III") and instruction.contains("No kills required"),"Return instruction explains that reconnaissance succeeded without destruction")
 check(not instruction.contains("payment") and not instruction.contains("reward"),"Return hint does not falsely promise money")
 var original=service.text_for(mission,"CompText")
 game.pilot.system_id=service.system_of(209);game.load_system();game.docked_id=209;game.set_mode("flight")
 var before=game.pilot.credits;var rep=game.pilot.reputation["129"]
 service.landed(209,true);service.show_next_landing_report()
 check(game.mode=="mission_report" and 185 in game.pilot.campaign.completed,"Returning completes the patrol successfully")
 check(game.pilot.credits==before and game.pilot.reputation["129"]==rep+10,"Original reward is ten Rebel reputation, with no credit payment")
 check(service.active_landing_report.body==original and original.contains("come up empty"),"Original successful story text is retained verbatim")
 var heading=game.hud.modal_root.find_child("MissionReportHeading",true,false)
 var status=game.hud.modal_root.find_child("MissionReportStatus",true,false)
 check(heading!=null and heading.text.contains("MISSION COMPLETE") and heading.text.contains("Lead Rebel Patrol"),"Report visibly labels the mission as successfully completed")
 check(status!=null and status.text.contains("No credit payment") and status.text.contains("+10 Rebellion reputation"),"Report visibly explains the actual reward")
 check(status.text.contains("spaceport bar at Sirgil III"),"Report names the exact next story location")
 var body=game.hud.modal_root.find_child("MissionReportNarrative",true,false)
 var button=game.hud.modal_root.find_child("DismissMissionReport",true,false)
 check(status.position.y+status.size.y<=body.position.y and body.position.y+body.size.y<button.position.y,"Status, story and Okay button do not overlap")
 if "--visual" in OS.get_cmdline_user_args():
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev156-recon-report.png")
 service.dismiss_landing_report()
 check(service.offers(209,1).any(func(m):return int(m.id)==186),"Rescue Rebel Spy is available in the same port's bar after the debrief")
 var paid=service.offer(227,209);paid.actors=[]
 for i in int(game.catalog.field("missions",227,"ShipCount")): paid.actors.append({"observed":true})
 check(service.next_objective(paid).contains("40000 credits"),"Paid reconnaissance still displays its actual cash reward")
 game.free();await process_frame
 print("RECON DEBRIEF: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
