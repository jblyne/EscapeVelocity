extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev168-autoboard.json";game.controls.path="/tmp/ev168-autoboard-controls.json";game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 for hz in [30,60,120]:
  game.set_mode("flight")
  var npc=game.traffic.spawn(130,130,1,Vector2(10000,10000))
  npc.disabled=true;npc.velocity=Vector2(12,5);npc.heading=2.1
  game.target_index=game.npcs.find(npc);game.pilot.position=npc.position+Vector2(1400,500);game.velocity=Vector2(0,120);game.last_board_tap=-1000
  game.board_pressed()
  check(game.auto_boarding.is_empty() and game.mode=="flight","Single B retains manual boarding checks")
  game.board_pressed()
  check(not game.auto_boarding.is_empty(),"Double B starts approach")
  for frame in 180*hz:
   game._physics_process(1.0/hz)
   if game.mode!="flight": break
  check(game.mode=="boarding" and npc.get("boarded",false),"Approach boards drifting target at %d Hz" % hz)
  check(game.auto_boarding.is_empty(),"Boarding clears approach")
  game.set_mode("flight");game.pilot.position=npc.position+Vector2(1500,0);game.last_board_tap=-1000
  game.board_pressed();game.board_pressed();game.board_pressed()
  check(game.auto_boarding.is_empty(),"B cancels approach")
  game.last_board_tap=-1000;game.board_pressed();game.board_pressed();game.set_mode("map")
  check(game.auto_boarding.is_empty(),"Menu cancels approach")
  game.traffic.retire(npc)
 game.free();await process_frame
 print("AUTO BOARDING: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
