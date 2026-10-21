extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func silence() -> void:
	for player in game.audio.values(): player.stop()
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-interface-audio-pilot.json";game.controls.path="/tmp/ev-interface-audio-controls.json"
	game.traffic.enabled=false;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.set_mode("flight");game.muted=false
	for key in ["ui_target","ui_open","ui_select","ui_error","ui_confirm","airlock"]:
		check(game.audio.has(key) and game.audio[key].stream.get_length()>0,"Original sound loads: "+key)
	game.select_landing_target(0)
	check(game.audio.ui_select.playing,"World targeting uses original selection beep")
	silence();game.select_landing_target(0)
	check(not game.audio.ui_select.playing,"Reselecting same world does not repeat sound")
	game.land()
	check(game.audio.ui_confirm.playing,"Clearance granted plays confirmation")
	silence();game.pilot.position=game.planets[0].position+Vector2(10000,10000);game.land()
	check(game.audio.ui_error.playing,"Unsafe landing attempt plays refusal beep")
	silence();game.pilot.position=game.planets[0].position;game.velocity=Vector2.ZERO;game.land()
	check(game.mode=="dock" and game.audio.ui_open.playing and not game.audio.land.playing,"Landing uses original interface cue instead of synthesized chime")
	game.set_mode("flight");silence();game.cycle_destination()
	check(game.audio.ui_select.playing,"Navigation selection plays source beep")
	game.spawn_npc(false,game.pilot.position+Vector2(200,0));game.target_index=-1
	var event=InputEventKey.new();event.pressed=true;event.physical_keycode=KEY_TAB
	silence();game._unhandled_key_input(event)
	check(game.audio.ui_target.playing,"Actual Tab targeting plays original targeting beep")
	silence();game.muted=true;game._unhandled_key_input(event)
	check(not game.audio.ui_target.playing,"Mute suppresses targeting")
	game.muted=false;silence();game.set_mode("pause");game._unhandled_key_input(event)
	check(not game.audio.ui_target.playing,"Paused targeting does not produce flight cue")
	game.free();await process_frame
	print("INTERFACE AUDIO: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
