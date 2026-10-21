extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev172-survival.json";game.controls.path="/tmp/ev172-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false);game.set_mode("flight")
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 var m=game.missions.offer(235,161);game.missions.state().active=[m];game.pilot.system_id=141;game.missions.arrival_delays[235]=0;game.missions.spawn_group(m,false)
 var target=game.npcs.filter(func(n):return n.get("mission_id",-1)==235 and not n.get("mission_aux",false))[0]
 var attacker=game.traffic.spawn(131,136,3,target.position+Vector2(100,0))
 var initial: float=target.health
 check(game.missions.needs_boarding(target),"Weapons Convoy transport requires boarding")
 game.pilot.cheat_chain_jump=true;game.chain_route=[142];game.velocity=Vector2(0,-100000)
 game.apply_hyperspace_wake(target.position-Vector2(0,100),target.position+Vector2(0,100))
 check(target in game.npcs and target.health==initial and m in game.missions.state().active,"Actual chain-warp wake cannot instantly fail boarding objective")
 game.chain_route.clear();game.velocity=Vector2.ZERO
 game.damage_npc(target,100000,attacker,Vector2.ZERO,false,100000)
 check(target.health==initial,"Arrival grants eight seconds against NPC fire")
 target.age=9
 game.damage_npc(target,100000,attacker,Vector2.ZERO,false,100000)
 check(target in game.npcs and target.disabled and target.health>0 and m in game.missions.state().active,"Lethal ambient attack disables rather than destroys required carrier")
 attacker.player_ally=true
 for i in 5: game.damage_npc(target,100000,attacker,Vector2.ZERO,false,100000)
 check(target in game.npcs and target.health>0,"Repeated escort fire leaves transport boardable")
 game.target_index=game.npcs.find(target);game.pilot.position=target.position;game.pilot.heading=target.heading;game.velocity=target.velocity
 check(game.interactions.board() and m.picked and m.actors[0].boarded,"Surviving transport transfers actual mission prototype when boarded")
 game.set_mode("flight")
 check(not game.missions.needs_boarding(target),"Protection ends after boarding objective is secured")
 game.damage_npc(target,100000,attacker,Vector2.ZERO,false,100000)
 check(target not in game.npcs and m in game.missions.state().active,"Post-boarding destruction does not undo cargo recovery")
 game.missions.landed(161,false)
 check(235 in game.missions.state().completed,"Return to Palshife still completes protected boarding mission")
 var retry=game.missions.offer(235,161);game.missions.state().active=[retry];game.missions.arrival_delays[235]=0;game.missions.spawn_group(retry,false)
 var second=game.npcs.filter(func(n):return n.get("mission_id",-1)==235 and not n.get("mission_aux",false))[0]
 game.damage_npc(second,100000,{},Vector2.ZERO,false,100000)
 check(second not in game.npcs and retry not in game.missions.state().active,"Direct player lethal fire still fails unboarded objective")
 game.free();await process_frame
 print("BOARDING TARGET SURVIVAL: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
