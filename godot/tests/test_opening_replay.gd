extends SceneTree
var failures: int=0
var checks: int=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev190-replay.json"
	game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.pilot_ready=true;game.pilot.credits=123456;game.opening_story_seen=true
	var pilot_id: int=game.pilot.get_instance_id()
	for attempt in 2:
		game.muted=attempt==1
		game.set_mode("title")
		var menu=game.hud.modal_root.get_child(0);menu.about_with_modifiers(false,false)
		var replay: Button
		for child in menu.screen.get_children():
			if child is Button and child.text=="Replay opening sequence": replay=child
		check(replay!=null,"About EV exposes temporary replay button")
		if "--visual" in OS.get_cmdline_user_args() and attempt==0:
			for i in 3: await process_frame
			await RenderingServer.frame_post_draw
			check(menu.get_global_rect().encloses(menu.dialog.get_global_rect()),"About popup fits on screen")
			root.get_texture().get_image().save_png("/tmp/ev190-about.png")
		replay.pressed.emit()
		check(game.mode=="intro" and game.has_node("OpeningReplay"),"Replay opens startup overlay")
		var opening=game.get_node("OpeningReplay").get_child(0);opening.set_process(false)
		while opening.scene==null:
			await process_frame
		check(opening.phase=="logo" and opening.replay_only,"Replay begins with Ambrosia")
		check(opening.music==game.audio.menu_music,"Replay shares existing title music player")
		check(not game.audio.menu_hum.playing and not game.audio.menu_slam.playing,"Menu machinery stays silent behind startup overlay")
		check(opening.music.playing==not game.muted,"Replay honors the current mute setting")
		opening._process(0);opening._process(opening.LOGO_HOLD_SECONDS+.01)
		opening._process(opening.FADE_SECONDS+opening.BLACK_HOLD_SECONDS+.01)
		check(opening.phase=="loading","Replay advances to loading artwork")
		opening._process(0);opening._process(.6)
		check(opening.progress.value>0 and opening.progress.value<100,"Replay animates the loading meter")
		opening._process(1);opening._process(.2);opening._process(opening.FADE_SECONDS+opening.BLACK_HOLD_SECONDS+.01);await process_frame;await process_frame
		check(game.mode=="title" and not game.has_node("OpeningReplay"),"Replay returns to fresh title menu without reloading game")
		menu=game.hud.modal_root.get_child(0)
		check(menu.animation_time<.2 and not menu.motion_finished,"Menu folding animation restarts")
		check(game.pilot.get_instance_id()==pilot_id and game.pilot.credits==123456 and game.opening_story_seen,"Replay preserves current pilot and introduction state")
	game.free();await process_frame
	print("OPENING REPLAY: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
