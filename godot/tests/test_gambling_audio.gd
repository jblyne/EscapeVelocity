extends SceneTree
var failures: int=0
var checks: int=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func seed_for(kind: String) -> int:
 var rng=RandomNumberGenerator.new()
 for seed_value in 10000:
  rng.seed=seed_value
  var symbols=[rng.randi_range(0,5),rng.randi_range(0,5),rng.randi_range(0,5)]
  var actual="triple" if symbols[0]==symbols[1] and symbols[1]==symbols[2] else ("pair" if symbols[0]==symbols[1] or symbols[0]==symbols[2] or symbols[1]==symbols[2] else "loss")
  if actual==kind:return seed_value
 return -1
func run() -> void:
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev257-slot-audio-pilot.json";game.controls.path="/tmp/ev257-slot-controls.json";game.traffic.enabled=false;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.controls.controller.set_process(false)
 game.docked_id=133;game.pilot.credits=100000;game.hud.port_page="gambling";game.set_mode("dock");game.muted=false
 var machine=game.hud.modal_root.get_child(0);machine.set_process(false)
 check(game.audio.slot_win.stream==game.audio.heavy_explosion.stream and game.audio.slot_jackpot.stream==game.audio.explosion.stream,"Payouts use original pair and triple recordings on separate players")
 for kind in ["pair","triple","loss"]:
  machine.rng.seed=seed_for(kind);machine.spin(1000)
  check(machine.spinning and game.audio.slot_flip.playing,"Valid wager starts reel flip audio: "+kind)
  machine._process(1.21)
  check(machine.stopped_reels==[true,false,false] and game.audio.slot_lock.playing,"First reel locks independently: "+kind)
  machine._process(.5)
  check(machine.stopped_reels==[true,true,false],"Second reel locks independently: "+kind)
  machine._process(.5)
  check(not machine.spinning and not game.audio.slot_flip.playing,"Flip stops with final reel: "+kind)
  check(game.audio.slot_win.playing==(kind=="pair") and game.audio.slot_jackpot.playing==(kind=="triple"),"Correct win cue, silence on losses: "+kind)
 machine.stop_slot_audio();game.pilot.credits=999;machine.spin(1000)
 check(not game.audio.slot_flip.playing,"Rejected wager is silent")
 game.pilot.credits=10000;game.muted=true;machine.rng.seed=seed_for("triple");machine.spin(1000);machine._process(3)
 check(machine.SLOT_AUDIO.all(func(key):return not game.audio[key].playing),"Muted spins and payouts remain silent")
 game.muted=false;machine.rng.seed=seed_for("triple");machine.spin(1000);machine._process(3);game.toggle_audio()
 check(machine.SLOT_AUDIO.all(func(key):return not game.audio[key].playing),"Muting stops a playing payout")
 game.toggle_audio();machine.rng.seed=seed_for("pair");machine.spin(1000);machine.page("bar");await process_frame
 check(["slot_flip","slot_lock","slot_win","slot_jackpot"].all(func(key):return not game.audio[key].playing),"Leaving mid-spin stops all slot audio")
 print("Gambling audio: %d checks, %d failures"%[checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
