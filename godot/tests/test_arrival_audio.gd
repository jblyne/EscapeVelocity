extends SceneTree
var game
var count: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	count+=1
	if ok: print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)

func _initialize() -> void:
	call_deferred("run")

func prepare_jump() -> void:
	game.pilot.position=Vector2(12000,12000)
	game.velocity=Vector2.ZERO
	game.pilot.fuel=1000
	game.cycle_destination()

func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-arrival-audio-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled = false # Isolate this feature from independently tested ambient traffic.
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	var arrival: AudioStreamPlayer=game.audio.arrival
	check(not arrival.playing,"starting or loading a system does not play the arrival strike")
	check(arrival.stream!=null and is_equal_approx(arrival.stream.get_length(),3.2) and arrival.pitch_scale==1 and arrival.max_polyphony==1,"arrival has its own unpitched single-voice thunderclap asset")
	prepare_jump()
	var old_system: int=game.pilot.system_id
	game.start_jump()
	var early: bool=false
	for frame in 1800:
		game._physics_process(1.0/60)
		if game.pilot.system_id!=old_system: break
		if arrival.playing: early=true
	check(not early,"the arrival sound remains silent throughout stopping, spooling and acceleration")
	check(game.pilot.system_id!=old_system and arrival.playing,"thunder starts on the same physics tick as entry into the new system")
	check(not game.audio.jump.playing,"departure sound stops before the arrival strike")
	var playback=arrival.get_stream_playback()
	for frame in 10: game._physics_process(1.0/60)
	check(arrival.get_stream_playback()==playback,"coasting after entry does not retrigger the strike")
	game.set_mode("pause")
	check(arrival.stream_paused,"pause freezes the thunder tail")
	game.set_mode("flight")
	check(not arrival.stream_paused,"resume continues the thunder tail")
	game.load_game()
	check(not arrival.playing,"loading a saved pilot stops the tail and does not trigger an arrival strike")
	game.sound("arrival")
	game.toggle_audio()
	check(game.muted and not arrival.playing,"turning sound off immediately stops the strike")
	game.toggle_audio()
	prepare_jump()
	game.start_jump();game.start_jump()
	check(not game.hyperdrive.active() and not arrival.playing,"canceling hyperspace never triggers the arrival strike")
	game.pilot.fuel=0
	game.start_jump()
	check(not game.hyperdrive.active() and not arrival.playing,"a failed jump never triggers the strike")
	game.muted=true
	prepare_jump()
	old_system=game.pilot.system_id
	game.start_jump()
	for frame in 1800:
		game._physics_process(1.0/60)
		if game.pilot.system_id!=old_system: break
	check(game.pilot.system_id!=old_system and not arrival.playing,"a successful muted jump remains silent")
	playback=null
	for player in game.audio.values(): player.stop()
	game.engine_audio.stop()
	# Let the audio mixer retire stopped playbacks before tearing down the scene.
	await create_timer(0.15).timeout
	game.free()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://../builds/test-arrival-audio-pilot.json"))
	print("ARRIVAL AUDIO RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
