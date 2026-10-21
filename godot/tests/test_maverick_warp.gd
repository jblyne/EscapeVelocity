extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if ok: print("PASS: "+message)
 else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev114-warp-test.json";game.controls.path="/tmp/ev114-controls.json";game.traffic.enabled=false;game.muted=false
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 game.pilot.ship_id=900;game.pilot.ship_fields=game.catalog.record("ships",900).fields.duplicate(true);game.load_system();game.set_mode("flight")
 game.pilot.position=Vector2(20000,20000);game.destination=int(game.catalog.system(game.pilot.system_id).links[0]);game.start_jump()
 var service=game.traffic.maverick;var music=game.audio.maverick_warp
 check(game.hyperdrive.active() and music.playing and service.warp_active,"Maverick warp music starts with actual jump preparation")
 check(music.stream.resource_path=="res://audio/maverick_warp.mp3" and music.stream.loop,"Supplied warp clip loops for long chains")
 game.chain_route=[game.destination,game.pilot.system_id]
 game.chain_hop();service.advance_warp(game,1)
 check(not game.chain_route.is_empty() and music.playing and is_zero_approx(service.warp_fade),"Intermediate chain arrival keeps the same music player running without fading")
 game.chain_hop();service.advance_warp(game,1.5)
 check(game.chain_route.is_empty() and music.playing and music.volume_db<service.WARP_VOLUME,"Final chain arrival starts a gradual fade")
 game.set_mode("pause");var fading=service.warp_fade;service.advance_warp(game,4)
 check(music.stream_paused and service.warp_fade==fading,"Pause menu suspends both music and fade")
 game.set_mode("flight");service.advance_warp(game,1.5)
 check(not music.playing and not service.warp_active,"Music stops after the three-second fade")
 game.pilot.position=Vector2(20000,20000);game.destination=int(game.catalog.system(game.pilot.system_id).links[0]);game.start_jump();game.cancel_jump(false);service.advance_warp(game,1)
 check(music.playing and service.warp_fade>0,"Canceling a jump fades rather than abruptly cutting music")
 game.start_jump();service.advance_warp(game,.1)
 check(music.playing and is_zero_approx(service.warp_fade),"Starting another jump during fade continues music")
 game.toggle_audio();check(not music.playing,"Mute stops warp music")
 service.advance_warp(game,.1);check(not music.playing,"Muted warp cannot restart playback")
 game.toggle_audio();service.advance_warp(game,.1);check(music.playing,"Unmuting during warp restores music")
 game.cancel_jump(false);game.pilot.ship_id=128;service.advance_warp(game,.1)
 service.begin_warp(game);check(not music.playing and not service.warp_active,"Other ships do not play Maverick warp music")
 game.free();await process_frame
 print("MAVERICK WARP: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
