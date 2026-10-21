extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func origin_for(id: int) -> int:
 var code=int(game.catalog.field("missions",id,"AvailStel"))
 for port in game.catalog.data.objects.values():
  if game.missions.port_matches(code,int(port.id)): return int(port.id)
 return -1
func settled(m,fields):
 m.met=true;m.actors=[]
 var encounter=game.catalog.record("encounters",int(fields.ShipDude))
 var ship=128
 if not encounter.is_empty():
  for candidate in encounter.fields.ShipTypes:
   if not game.catalog.record("ships",int(candidate)).is_empty(): ship=int(candidate);break
 for i in maxi(0,int(fields.ShipCount)):
  m.actors.append({"ship":ship,"health":-1.0,"disabled":int(fields.ShipGoal)==1,"boarded":true,"observed":true,"dead":int(fields.ShipGoal) in [0,6]})
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-phase1.json";game.controls.path="/tmp/ev-phase1-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 var service=game.missions
 game.pilot.campaign.active=[];game.pilot.campaign.day=20
 var covered=0
 for record in game.catalog.data.missions.values():
  var id=int(record.id);var origin=origin_for(id);check(origin>=0,"Mission %d resolves a real offer port" % id)
  if origin<0: continue
  var m=service.offer(id,origin);var f=record.fields;game.pilot.campaign.active=[m]
  var action=service.next_objective(m)
  check(not action.is_empty() and not action.contains("<") and not action.contains("the mission destination"),"Mission %d has concrete initial guidance" % id)
  if int(f.CanAbort)==0: check(service.commitment_notes(m).contains("cannot be voluntarily aborted"),"Mission %d warns of its commitment before acceptance" % id)
  check(not service.reward_summary(m).is_empty(),"Mission %d exposes its actual reward type" % id)
  check(game.pilot.CampaignState.valid(game.pilot.campaign,game.catalog),"Mission %d guidance starts from save-valid state" % id)
  var snapshot=game.pilot.campaign.duplicate(true)
  service.next_objective(m);service.reward_summary(m)
  check(game.pilot.campaign==snapshot,"Reading mission %d guidance never advances its state" % id)
  settled(m,f);m.picked=true
  if int(m.dest)>=0:
   m.travel_done=false
   check(service.next_objective(m).contains(game.catalog.record("objects",int(m.dest)).name),"Mission %d names its travel destination after ship objectives" % id)
  m.travel_done=true
  if int(m.back)>=0:
   check(service.next_objective(m).contains(game.catalog.record("objects",int(m.back)).name),"Mission %d names its return port" % id)
  covered+=1
 check(covered==116,"All 116 original mission records were audited")
 game.pilot.campaign.active=[];game.pilot.campaign.bits=[35];game.pilot.reputation["129"]=100
 var loan=service.offer(164,161);loan.prepaid=true;game.pilot.campaign.active=[loan];game.pilot.outfits["167"]=1
 check(not service.abort_reason(loan).is_empty(),"Original non-abortable story assignment is identified")
 service.abort(loan)
 check(loan in game.pilot.campaign.active and game.pilot.outfit_count(167)==1,"Blocked abort does not lose the mission or its cloak")
 game.set_mode("flight");service.channel=2;service.return_mode="flight";game.set_mode("missions")
 var abort_button=game.hud.modal_root.find_child("AbortMission164",true,false)
 check(abort_button!=null and abort_button.disabled and not abort_button.tooltip_text.is_empty(),"Journal disables and explains forbidden abort")
 if "--visual" in OS.get_cmdline_user_args():
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev158-journal.png")
 game.set_mode("flight");loan.deadline=int(service.state().day);service.jumped()
 check(loan not in service.state().active and game.pilot.outfit_count(167)==0,"Deadline failure still removes a loan even when voluntary abort is forbidden")
 check(service.flight_alert.contains("Deadline missed") and service.flight_alert.contains("Cloaking Device") and service.flight_alert.contains("Retry:"),"Failure explains cause, equipment loss and valid retry location")
 check(service.eligibility(164,161,false),"Failed insertion remains naturally available for retry")
 var escort=service.offer(151,128);settled(escort,game.catalog.record("missions",151).fields)
 check(service.next_objective(escort).contains("Keep them alive"),"Escort guidance retains its protection requirement after rendezvous")
 for entry in [[170,166],[235,173]]:
  var m=service.offer(entry[0],origin_for(entry[0]));game.pilot.campaign.active=[m]
  var before=game.pilot.outfit_count(entry[1]);service.finish(m,true)
  check(game.pilot.outfit_count(entry[1])==mini(int(game.catalog.field("outfits",entry[1],"Max")),before+1),"Mission %d grants its real equipment reward" % entry[0])
  check(service.completion_status(m).contains(game.catalog.record("outfits",entry[1]).name),"Mission %d names the awarded equipment" % entry[0])
  var loaded=game.Pilot.new()
  check(loaded.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)),game.catalog) and loaded.outfit_count(entry[1])==game.pilot.outfit_count(entry[1]),"Mission %d equipment reward survives actual disk reload" % entry[0])
  var count=game.pilot.outfit_count(entry[1]);service.finish(m,true)
  check(game.pilot.outfit_count(entry[1])==count,"Completed mission %d cannot grant its reward twice" % entry[0])
 for finale in [189,194]:
  var m=service.offer(finale,origin_for(finale))
  check(service.reward_summary(m).contains("military clearance") and service.completion_status(m).contains("unlocked"),"Mission %d announces its earned military access" % finale)
 var switching=service.offer(200,origin_for(200));game.pilot.reputation["129"]=-1000;game.pilot.campaign.active=[switching];service.finish(switching,true)
 check(game.pilot.reputation["129"]>=0 and service.completion_status(switching).contains("record cleared"),"Switch Sides grants and describes its actual legal-record reward")
 var boarding=service.offer(186,209);settled(boarding,game.catalog.record("missions",186).fields);boarding.actors[0].boarded=false;game.pilot.campaign.active=[boarding]
 check(service.next_objective(boarding).contains("Board") and not service.next_objective(boarding).contains("Disable and"),"Rescue guidance does not order a disabled target to be shot again")
 service.actor_event({"mission_id":186,"mission_aux":false,"mission_slot":0},"kill")
 check(service.flight_alert.contains("destroyed before boarding"),"Destroying a rescue target explains the failed boarding objective")
 var assassination=service.offer(146,192);settled(assassination,game.catalog.record("missions",146).fields);assassination.actors[0].dead=false;game.pilot.campaign.active=[assassination]
 service.actor_event({"mission_id":146,"mission_aux":false,"mission_slot":0},"escape")
 check(service.flight_alert.contains("target escaped"),"Escaping assassination target reports the actual failure")
 var failure=service.offer(128,128);game.pilot.campaign.active=[failure];game.pilot.campaign.completed.append(128)
 game.autopilot.job={"kind":"mission","id":128,"name":"Repeat delivery"}
 service.finish(failure,false,false,true,"Delivery failed during the test.")
 check(not game.autopilot.active() and game.autopilot.status.contains("Mission failed"),"A failed repeat mission cannot be reported as an old autopilot success")
 check(service.landing_reports.back().heading=="MISSION FAILED" and service.landing_reports.back().status!="Mission complete","Failure report cannot carry success status text")
 game.pilot.campaign.bits=[];game.pilot.campaign.active=[]
 check(service.eligibility_reason(164,161).contains("Special Ops"),"Missing story prerequisite names earlier work")
 game.pilot.campaign.bits=[44];game.pilot.reputation["129"]=-1
 check(service.eligibility_reason(230,161).contains("standing"),"Qualification guidance identifies reputation gate")
 game.pilot.reputation["129"]=3000;game.pilot.campaign.rating=0
 check(service.eligibility_reason(230,161).contains("6400"),"Qualification guidance identifies exact combat requirement")
 if "--visual" in OS.get_cmdline_user_args():
  service.approach=service.offer(164,161);service.approach_port=161;game.docked_id=161;game.set_mode("mission_offer")
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev158-offer.png")
 game.free();await process_frame
 print("PHASE 1 MISSIONS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
