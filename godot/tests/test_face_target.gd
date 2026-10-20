extends SceneTree
var game
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func key(code: int, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-face-target-pilot.json")
	game.traffic.enabled=false
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.pilot.position=Vector2(5000,5000)
	game.velocity=Vector2(0,30)
	game.pilot.heading=0
	var npc=game.traffic.spawn(130,-1,1,game.pilot.position+Vector2(300,0))
	npc.disabled=true
	game.target_index=game.npcs.find(npc)
	key(KEY_T,true)
	game._physics_process(.1)
	check(game.pilot.heading>0 and game.pilot.heading<PI/2,"holding T turns toward ship at normal turn rate")
	check(game.velocity==Vector2(0,30),"alignment preserves drift without adding thrust")
	for i in 120: game._physics_process(1.0/60)
	var direction: Vector2=npc.position-game.pilot.position
	check(absf(angle_difference(game.pilot.heading,game.Flight.facing(direction)))<.02,"held key keeps nose aimed at target while moving")
	npc.position=game.pilot.position+Vector2(-300,0)
	for i in 120: game._physics_process(1.0/60)
	check(absf(angle_difference(game.pilot.heading,game.Flight.facing(npc.position-game.pilot.position)))<.02,"tracking follows target as it changes position")
	key(KEY_T,false)
	var heading: float=game.pilot.heading
	npc.position=game.pilot.position+Vector2(300,0)
	game._physics_process(.1)
	check(game.pilot.heading==heading,"release stops automatic steering")
	key(KEY_T,true)
	key(KEY_D,true)
	game._physics_process(.1)
	check(angle_difference(heading,game.pilot.heading)>0,"manual steering overrides target facing")
	key(KEY_D,false)
	game.traffic.retire(npc)
	game.target_index=-1
	game.landing_target=game.planets[0].id
	for i in 180: game._physics_process(1.0/60)
	check(absf(angle_difference(game.pilot.heading,game.Flight.facing(game.planets[0].position-game.pilot.position)))<.02,"without ship target, selected planet is tracked")
	game.landing_target=-1
	heading=game.pilot.heading
	game._physics_process(.1)
	check(game.pilot.heading==heading,"no selected target leaves heading unchanged")
	key(KEY_W,true)
	game._physics_process(.1)
	check(game.velocity!=Vector2(0,30),"thrust remains independently controllable")
	key(KEY_W,false)
	game.set_mode("pause")
	heading=game.pilot.heading
	game._physics_process(1)
	check(game.pilot.heading==heading,"target facing respects pause")
	key(KEY_T,false)
	game.free()
	await process_frame
	print("FACE TARGET RESULT: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
