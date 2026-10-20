extends SceneTree
var game

func _initialize() -> void: call_deferred("run")

func key(code: int, pressed: bool = true) -> void:
	var event=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event)

func capture(label: String) -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/controls-0118-%s.png" % label))

func tab() -> void:
	var event=InputEventKey.new();event.physical_keycode=KEY_TAB;event.pressed=true
	game._unhandled_key_input(event);game.hud._process(0)

func run() -> void:
	Engine.max_fps=120
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-flight-controls-0118.json")
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.pilot.system_id=129;game.pilot.position=Vector2(12000,12000);game.pilot.heading=0;game.load_system()
	var started: float=game.time
	var samples: Array[Vector2]=[]
	key(KEY_W)
	while game.time-started<5.0:
		await RenderingServer.frame_post_draw
		if game.time-started>3.5:
			samples.append(game.camera.unproject_position(game.player_model.position))
	key(KEY_W,false)
	var low=samples[0];var high=samples[0]
	for point in samples:
		low=low.min(point);high=high.max(point)
	print("Normal thrust: speed %.2f, %d rendered cruise samples, screen-position spread %s pixels" % [game.velocity.length(),samples.size(),high-low])
	var success: bool=absf(game.velocity.length()-275)<.01
	await capture("normal-thrust")
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	for i in 2: game.spawn_npc(false,game.pilot.position+Vector2(-150+i*300,-200),i)
	tab();tab();await capture("last-contact")
	tab();await capture("no-selection")
	success=success and game.target_index==-1 and game.hud.target_panel.preview_model==null
	tab();await capture("first-contact")
	success=success and game.target_index==0
	var target=int(game.catalog.system(game.pilot.system_id).links[0])
	var source_fields=game.catalog.system(game.pilot.system_id).fields
	var target_fields=game.catalog.system(target).fields
	game.pilot.heading=game.Flight.facing(Vector2(target_fields.xPos-source_fields.xPos,target_fields.yPos-source_fields.yPos))
	game.load_system();game.select_destination(target)
	game.set_physics_process(true);game.set_process(true);game.hud.set_process(true)
	game.start_jump()
	var peak_speed=0.0;var captured=false
	started=game.time
	while game.pilot.system_id!=target and game.time-started<12:
		await process_frame
		peak_speed=maxf(peak_speed,game.velocity.length())
		if game.hyperdrive.phase=="accelerating" and game.hyperdrive.remaining<.22 and not captured:
			captured=true;await capture("hyperspace-burn")
	await capture("arrival")
	success=success and captured and game.pilot.system_id==target and peak_speed>2040 and peak_speed<2063 and absf(game.velocity.length()-275)<.01
	print("Departure peak before transition: %.3f; arrival %.3f; visual controls capture success: %s" % [peak_speed,game.velocity.length(),success])
	game.free();await process_frame;quit(0 if success else 1)
