extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-defense-wake.json";game.controls.path="/tmp/ev-defense-wake-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 game.pilot.ship_id=900;game.pilot.ship_fields=game.catalog.record("ships",900).fields.duplicate(true)
 game.pilot.cheat_chain_jump=true;game.pilot.position=Vector2(20000,20000);game.velocity=Vector2(0,-900)
 var npc=game.traffic.spawn(128,128,1,game.pilot.position);var health=npc.health
 game.apply_hyperspace_wake(game.pilot.position,game.pilot.position)
 check(npc in game.npcs and npc.health==health,"Fast Maverick coasting with chain cheat enabled does not kill nearby ships")
 game.hyperdrive.phase="accelerating"
 game.apply_hyperspace_wake(game.pilot.position,game.pilot.position)
 check(npc not in game.npcs,"Actual hyperspace acceleration still produces lethal wake")
 game.hyperdrive.reset();npc=game.traffic.spawn(128,128,1,game.pilot.position);game.chain_route=[128]
 game.apply_hyperspace_wake(game.pilot.position,game.pilot.position)
 check(npc not in game.npcs,"Active chain flyby retains the hyperspace wake")
 game.chain_route.clear();game.velocity=Vector2.ZERO
 var m=game.missions.offer(148,192);m.ship_system=game.pilot.system_id;m.back=192
 game.pilot.campaign.active.append(m);game.missions.arrival_delays[148]=0
 game.missions.spawn_group(m,false)
 var attackers=game.npcs.filter(func(n):return n.get("mission_id",-1)==148)
 check(attackers.size()==5,"Rebel Defense spawns exactly five required attackers")
 for target in attackers: game.damage_npc(target,100000)
 for i in 20: game.missions.advance(.1)
 check(not game.npcs.any(func(n):return n.get("mission_id",-1)==148),"Defeated defense mission attackers do not respawn")
 check(game.missions.combat_return_status().contains("Defense objective complete"),"Defense mission clearly reports it is ready for return and payment")
 game.free();await process_frame
 print("DEFENSE WAKE: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
