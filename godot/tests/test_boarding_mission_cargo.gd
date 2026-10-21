extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,s: String):
 checks+=1
 if not ok: failures+=1;push_error(s)
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-boarding-cargo.json";game.controls.path="/tmp/ev-boarding-cargo-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 var service=game.missions;var m=service.offer(235,161);service.state().active=[m];game.pilot.system_id=141;service.arrival_delays[235]=0;service.spawn_group(m,false)
 var target=game.npcs.filter(func(n):return n.get("mission_id",-1)==235 and not n.get("mission_aux",false))[0]
 check(target.name.begins_with("[MISSION TARGET]"),"Boarding target is visually distinguished from escorts")
 target.cargo=[0,0,0,0,0,0];target.disabled=true;game.target_index=game.npcs.find(target);game.pilot.position=target.position;game.pilot.heading=target.heading;game.velocity=target.velocity
 check(game.interactions.board(),"Actual boarding action succeeds with no ordinary cargo")
 check(m.picked and m.actors[0].boarded,"Prototype transfers automatically and records boarding")
 check(game.interactions.response.contains("prototype") and game.interactions.response.contains("Palshife"),"Boarding confirms actual prototype recovery and where to return")
 check(game.hud.modal_root.find_child("BoardingMissionCargo",true,false)!=null,"Dedicated mission cargo explanation remains on boarding screen")
 var escort=target.duplicate();escort.mission_aux=true
 check(service.boarding_report(escort).contains("escort, not"),"Boarding an escort explicitly points to the actual transport")
 if "--visual" in OS.get_cmdline_user_args():
  await create_timer(.5).timeout
  for frame in 8: await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev167-boarding.png")
 target.boarded=false;service.sync_actors()
 check(m.actors[0].boarded,"Later synchronization cannot erase recorded boarding")
 game.set_mode("flight");service.actor_event(target,"kill")
 check(m in service.state().active,"Destroying boarded transport cannot falsely fail as unboarded")
 check(game.save_game(false) and game.Pilot.new().restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)),game.catalog),"Recovered mission cargo passes actual save validation")
 service.landed(161,false)
 check(235 in service.state().completed and game.pilot.outfit_count(173)>0,"Returning to Palshife completes mission and grants prototype reward")
 game.free();await process_frame
 print("BOARDING MISSION CARGO: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
