extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var boot=load("res://startup.tscn").instantiate();root.add_child(boot);boot.set_process(false)
	while boot.scene==null and not boot.loading_error:
		boot._process(0);await process_frame
	check(boot.phase=="logo" and boot.art.texture.resource_path.ends_with("ambrosia_hd.png"),"Original publisher logo opens first")
	check(boot.music.playing and boot.music.stream.resource_path.ends_with("menu_music.wav"),"Title music starts with publisher logo")
	check(boot.art.texture.get_height()>=1000,"Publisher logo uses high definition artwork")
	if "--visual" in OS.get_cmdline_user_args():
		for dimensions in [Vector2i(1280,720),Vector2i(2560,1080)]:
			root.size=dimensions
			for i in 3: await process_frame
			boot.fit()
			for phase in ["logo","loading"]:
				boot.show_phase(phase);boot.art.modulate.a=1;boot.wide_art.modulate.a=1
				if phase=="loading": boot.progress.value=52
				for i in 3: await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("/tmp/ev187-%s-%dx%d.png" % [phase,dimensions.x,dimensions.y])
				check(boot.wide_art.size==boot.size,"Loading artwork covers the viewport")
				check(boot.get_global_rect().encloses(boot.art.get_global_rect()),"Logo remains inside the viewport")
		boot.show_phase("logo")
	boot.show_phase("logo")
	var player=boot.music
	boot._process(10)
	check(boot.phase=="logo" and boot.elapsed==0,"Setup/loading delta cannot skip the publisher screen")
	check(boot.hint.text.is_empty() and not boot.hint.visible,"Publisher screen has no added input prompt")
	var space=InputEventKey.new();space.pressed=true;space.physical_keycode=KEY_SPACE
	boot._input(space)
	check(boot.phase=="logo","Space does not bypass the automatic publisher hold")
	boot._process(boot.LOGO_HOLD_SECONDS-.01)
	check(boot.phase=="logo","Publisher remains visible for its full hold")
	boot._process(.02)
	check(boot.transition_to=="loading" and boot.phase=="logo","Logo fades out before loading artwork")
	boot._process(boot.FADE_SECONDS*.5)
	check(boot.fade_cover.color.a>.4 and boot.fade_cover.color.a<.6,"Outgoing startup screen fades progressively to black")
	boot._process(boot.FADE_SECONDS*.5)
	check(boot.fade_cover.color.a==1 and boot.phase=="logo","Startup transition reaches full black before switching")
	boot._process(boot.BLACK_HOLD_SECONDS+.01)
	check(boot.phase=="loading" and boot.progress.visible and boot.art.texture.resource_path.ends_with("loading_hd.png"),"Loading artwork follows logo")
	check(boot.music==player and player.playing,"Music continues across loading screen")
	check(boot.hint.text.is_empty() and not boot.hint.visible,"Loading artwork has no added caption or input prompt")
	check(boot.progress.size==Vector2(200,10) and boot.progress.position==Vector2(316,579),"Loading meter uses recovered original geometry")
	check(boot.progress.value==0,"Loading meter begins empty")
	boot._process(0)
	var previous: float=0
	for i in 4:
		boot._process(.25)
		check(boot.progress.value>previous and boot.progress.value<100,"Loading meter fills incrementally: %d" % i)
		previous=boot.progress.value
	var ready_scene=boot.scene;boot.scene=null
	boot._process(.6)
	check(boot.progress.value==96 and boot.phase=="loading","Meter cannot complete before scene readiness")
	boot.scene=ready_scene;boot._process(0)
	check(boot.progress.value==100,"Loading meter reaches full before menu handoff")
	boot._process(.1)
	check(boot.phase=="loading","Full loading meter stays visible briefly before menu handoff")
	current_scene=boot;boot._process(.16)
	check(boot.transition_to=="menu" and not boot.finished,"Full loading meter starts the menu fade-out")
	boot._process(boot.FADE_SECONDS)
	check(boot.fade_cover.color.a==1 and not boot.finished,"Loading reaches black before menu handoff")
	boot._process(boot.BLACK_HOLD_SECONDS+.01);await process_frame;await process_frame
	var game=current_scene;game.set_process(false);game.set_physics_process(false)
	game.set_mode("title")
	check(game.audio.menu_music==player and player.playing,"Menu adopts same player without restarting title music")
	game.opening_story_seen=false
	game.enter_ship_with_intro(true)
	var layer=game.get_child(game.get_child_count()-1)
	var intro=layer.get_child(0);intro.set_process(false)
	check(intro.canvas.scale.x>0,"Story overlay fills the viewport")
	check(game.mode=="intro" and intro.phase=="arrival","First Enter Ship starts arrival image before story")
	check(game.hud.modal_root.get_child_count()==0,"Intro does not construct a hidden pause menu")
	check(intro.art.texture.resource_path.ends_with("levo_arrival_hd.png") and intro.art.texture.get_width()>=1400,"Levo arrival uses restored high-definition artwork")
	check(not player.playing and intro.music.stream.resource_path.ends_with("intro_transition.wav"),"Transition recording replaces title music on story arrival")
	if "--visual" in OS.get_cmdline_user_args():
		intro.art.modulate.a=1
		intro.fade_cover.hide()
		await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/ev195-arrival.png")
		intro.fade_cover.show()
	intro._process(7.99)
	check(intro.phase=="arrival","Arrival picture holds for original 480 ticks")
	intro._process(.02)
	check(intro.phase=="story" and intro.art.texture==null,"Story scroll follows arrival on black")
	check(intro.music.stream.resource_path.ends_with("intro_drums.wav"),"Original drum intro starts with story text")
	intro.next_drum()
	check(intro.music.get_meta("original_resource",0)==30002 and intro.music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Drum intro hands off to original drum loop")
	check(intro.story.text.begins_with("The new age of peace") and intro.story.text.ends_with("Good luck, captain."),"Complete original story is retained")
	var before: float=intro.story.position.y;intro._process(1)
	check(is_equal_approx(before-intro.story.position.y,39),"Story uses original one pixel per two ticks scaled to design canvas")
	intro.finish()
	check(game.mode=="intro","Story remains covered while fading out")
	intro._process(intro.STORY_FADE_SECONDS+intro.BLACK_HOLD_SECONDS)
	check(intro.fade_cover.color.a==1 and intro.phase=="game_reveal","Flight starts under an opaque black cover")
	intro._process(intro.STORY_FADE_SECONDS*.5)
	check(intro.fade_cover.color.a>0 and intro.fade_cover.color.a<1,"Gameplay fades in from black")
	intro._process(intro.STORY_FADE_SECONDS)
	check(game.hud.modal_root.get_child_count()==0 and not is_instance_valid(game.hud.modal_outgoing),"Story enters flight without a fading menu overlay")
	await process_frame
	check(game.mode=="flight","Story completion enters flight")
	game.set_mode("title");game.enter_ship_with_intro(true)
	check(game.mode=="flight","Returning to ship in same session does not replay story")
	game.free();await process_frame
	print("STARTUP: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
