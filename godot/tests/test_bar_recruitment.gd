extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-bar-recruit.json";game.controls.path="/tmp/ev-bar-recruit-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 var m=game.missions;game.pilot.campaign.bits=[];game.pilot.campaign.active=[];game.pilot.campaign.rating=1000
 game.pilot.reputation["129"]=0;game.pilot.reputation["128"]=0
 game.docked_id=161;game.set_mode("dock");game.hud.port_page="bar"
 for visit in 20:
  game.pilot.campaign.visit=visit
  check(m.eligibility(172,161),"Neutral Rebel recruit offer is available on visit %d" % visit)
 m.begin_bar_approach()
 check(172 in m.bar_queue,"Bar queues the neutral Rebel recruitment approach")
 for i in 100:
  m.advance_bar(.1)
  if game.mode=="mission_offer": break
 check(game.mode=="mission_offer" and int(m.approach.id)==172,"Waiting at the bar actually triggers Rebel recruitment")
 m.resolve_approach(true)
 check(game.pilot.campaign.active.any(func(job):return int(job.id)==172),"Bar recruitment can be accepted through its normal dialog")
 game.set_mode("dock");game.pilot.reputation["129"]=-1
 check(not m.eligibility(172,161),"Negative Rebel standing still blocks recruitment")
 game.pilot.reputation["129"]=0;game.pilot.campaign.bits=[43]
 check(not m.eligibility(172,161),"Confederation allegiance still blocks Rebel introduction")
 game.pilot.campaign.bits=[44]
 check(not m.eligibility(172,161),"Completed recruitment is not offered again")
 game.pilot.campaign.bits=[]
 check(m.eligibility(171,128),"Neutral Confederation recruitment also avoids the progression dead end")
 check(not m.eligibility(184,161),"Later story missions retain their requirements")
 game.free();await process_frame
 print("BAR RECRUITMENT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
