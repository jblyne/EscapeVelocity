extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-assassination-return.json";game.controls.path="/tmp/ev-assassination-return-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 var m=game.missions.offer(146,192);m.back=192;m.ship_system=game.pilot.system_id
 game.pilot.campaign.active.append(m);game.missions.arrival_delays[146]=0
 game.missions.spawn_group(m,false)
 var target={}
 for npc in game.npcs:
  if npc.get("mission_id",-1)==146: target=npc;break
 check(not target.is_empty() and str(target.name).contains("MISSION TARGET"),"Assassination ship is clearly identified")
 check(game.missions.return_for_payment(m).is_empty(),"Return instruction stays hidden while target is alive")
 game.damage_npc(target,100000)
 var status=game.missions.combat_return_status()
 check(status.contains("Darkstar") and status.contains("Nemesis") and status.contains("No more targets required"),"Target destruction names exact return port and explains no further kills needed")
 game.hud._process(0)
 check(game.hud.combat_return_label.visible and game.hud.combat_return_label.text.contains(game.missions.return_for_payment(m)),"Return instruction remains on flight HUD after generic kill notification")
 game.missions.spawn_group(m,false)
 check(not game.npcs.any(func(n):return n.get("mission_id",-1)==146 and not n.get("mission_aux",false)),"Completed target does not respawn")
 game.missions.finish(m,true)
 check(game.missions.combat_return_status().is_empty(),"Return reminder disappears once payment mission is complete")
 game.free();await process_frame
 print("ASSASSINATION RETURN: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
