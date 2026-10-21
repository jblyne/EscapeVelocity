extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func hunter() -> Dictionary:
 for npc in game.npcs:
  if npc.has("bounty_port"): return npc
 return {}
func clear_contacts():
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
func kill(npc: Dictionary,credit: bool=true):
 game.damage_npc(npc,100000,{} if credit else {"model":game.player_model,"faction":130,"position":game.pilot.position},Vector2.ZERO,false,100000)
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-tribute-hunters.json";game.controls.path="/tmp/ev-tribute-hunters-controls.json"
 if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.pilot_ready=true;game.set_mode("flight")
 clear_contacts();game.pilot.position=Vector2(10000,10000)
 var world=game.world_activity
 game.pilot.world_state=world.fresh();game.pilot.world_state.dominated=[128]
 var base: int=world.tribute(128)
 game.traffic.enabled=true;world.advance_hunters()
 check(hunter().is_empty() and world.hunter_record(128).sent==0,"New domination waits a game day before hiring")
 game.pilot.campaign.day=1;world.sync();world.advance_hunters()
 var first=hunter();var record=world.hunter_record(128)
 check(not first.is_empty() and record.sent==1 and record.active==1,"First contract dispatches once")
 check(first.name.contains("Earth") and first.name.contains("Sol"),"Hunter name identifies employer world and system")
 world.advance_hunters();check(game.npcs.filter(func(n):return n.has("bounty_port")).size()==1 and record.sent==1,"Frame updates cannot duplicate a contract or its sent count")
 game.set_mode("pause");var sent: int=record.sent;world.advance_hunters()
 check(record.sent==sent,"Menus do not dispatch hunters")
 game.set_mode("flight");first.disabled=true;world.advance(1)
 check(world.tribute(128)==base and record.defeated==0,"Disabling a hunter does not falsely count as destroying one")
 first.disabled=false;kill(first)
 check(record.defeated==1 and record.active==0 and world.tribute(128)==base+5000,"Actual player kill raises only sponsor's daily tribute by 5000")
 check(world.hunter_alert.contains("Earth") and world.hunter_alert.contains("Sol") and world.hunter_alert.contains("+5,000"),"Persistent flight alert identifies sponsor and tribute increase")
 game.hud._process(0)
 check(not game.hud.hunter_tribute_label.visible and game.hud.hunter_announcement!=null and not world.hunter_celebration.is_empty(),"Flight screen displays defeat independently of ordinary combat log")
 world.hunter_destroyed(first,true)
 check(record.defeated==1 and world.tribute(128)==base+5000,"Duplicate death callback cannot reward twice")
 var credits: int=game.pilot.credits
 game.pilot.campaign.day+=1;world.sync()
 check(game.pilot.credits==credits+base+5000,"Daily payment includes new tribute rate")
 var snapshot=game.pilot.snapshot();var restored=game.Pilot.new()
 check(restored.restore(JSON.parse_string(JSON.stringify(snapshot)),game.catalog),"Hunter counters pass actual JSON save validation")
 check(restored.world_state.hunters["128"].defeated==1 and restored.world_state.hunters["128"].sent==1,"Save/reload preserves tribute increases and dispatch counts")
 game.pilot.campaign.day=int(record.next_day);world.sync();world.advance_hunters();var second=hunter()
 check(record.sent==2,"Second contract uses new serial after cooldown")
 game.load_system();game.set_mode("flight");clear_contacts();world.advance_hunters();var resumed=hunter()
 check(not resumed.is_empty() and resumed.bounty_contract==2 and record.sent==2,"Travel resumes existing hunter without incrementing sent count")
 check(game.save_game(false),"Active hunter contract can be saved")
 clear_contacts();game.load_game();game.set_mode("flight");game.traffic.enabled=true;clear_contacts();world.advance_hunters();record=world.hunter_record(128)
 check(not hunter().is_empty() and hunter().bounty_contract==2 and record.sent==2,"Reload resumes same pending contract")
 kill(hunter(),false)
 check(record.defeated==1 and record.active==0 and world.tribute(128)==base+5000,"Other NPC kills resolve hunter without player reward")
 for defeat in range(2,6):
  game.pilot.campaign.day=int(record.next_day);world.sync();world.advance_hunters()
  check(not hunter().is_empty(),"Eligible retaliation dispatches hunter before defeat %d" % defeat)
  kill(hunter())
  check(record.defeated==defeat and world.tribute(128)==base+5000*defeat,"Defeat %d increases tribute exactly once" % defeat)
 game.pilot.campaign.day+=100;world.sync();world.advance_hunters()
 check(hunter().is_empty() and record.defeated==5,"World gives up after five defeats and cannot send more hunters")
 check(world.hunter_alert.contains("give up"),"Final defeat explicitly announces surrender")
 var summary: Dictionary=world.tribute_summary(129)
 check(summary.income==base+25000 and summary.sent==6 and summary.defeated==5 and summary.gave_up==1,"Map summary reports current payment, all dispatches and give-up state")
 game.set_mode("map");game.map_selected=129
 var map=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1);map.refresh_details()
 check(map.details().tribute.sent==6 and map.details().tribute.income==base+25000,"Actual map readout uses live tribute and hunter counters")
 if "--visual" in OS.get_cmdline_user_args():
  game.map_center=Vector2(game.catalog.system(129).fields.xPos,game.catalog.system(129).fields.yPos);map.chart.queue_redraw()
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev162-map.png")
  game.set_mode("flight");game.hud._process(0)
  await create_timer(0.5).timeout
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev162-flight.png")
 var old=game.pilot.snapshot();old.world.erase("hunters")
 check(game.Pilot.new().restore(old,game.catalog),"Older pilots without hunter fields remain compatible")
 for field in ["sent","defeated","active","next_day"]:
  var bad=game.pilot.snapshot();bad.world.hunters["128"][field]=-1
  check(not game.Pilot.new().restore(bad,game.catalog),"Invalid hunter %s is rejected atomically" % field)
 game.set_mode("flight");game.pilot.world_state.dominated=[];world.advance_hunters()
 check(world.daily_income()==0 and world.tribute_summary(129).worlds==0,"Released agreements disappear from current map income")
 game.pilot.world_state.dominated=[128];game.pilot.world_killer.destroyed.append(128)
 check(world.daily_income()==0 and world.tribute_summary(129).sent==0,"Obliterated sponsor neither pays nor shows active tribute statistics")
 game.free();await process_frame
 print("TRIBUTE HUNTERS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
