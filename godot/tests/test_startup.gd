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
	check(boot.phase=="logo" and boot.art.texture.resource_path.ends_with("8100.png"),"Original publisher logo opens first")
	check(boot.music.playing and boot.music.stream.resource_path.ends_with("menu_music.wav"),"Title music starts with publisher logo")
	var player=boot.music
	boot._process(.3)
	check(boot.phase=="loading" and boot.progress.visible and boot.art.texture.resource_path.ends_with("131.png"),"Loading artwork follows logo")
	check(boot.music==player and player.playing,"Music continues across loading screen")
	current_scene=boot;boot.finish();await process_frame;await process_frame
	var game=current_scene;game.set_process(false);game.set_physics_process(false)
	game.set_mode("title")
	check(game.audio.menu_music==player and player.playing,"Menu adopts same player without restarting title music")
	game.opening_story_seen=false
	game.enter_ship_with_intro(true)
	var layer=game.get_child(game.get_child_count()-1)
	var intro=layer.get_child(0);intro.set_process(false)
	check(intro.canvas.scale.x>0,"Story overlay fills the viewport")
	check(game.mode=="intro" and intro.phase=="arrival","First Enter Ship starts arrival image before story")
	check(not player.playing and intro.music.stream.resource_path.ends_with("intro_transition.wav"),"Transition recording replaces title music on story arrival")
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
	intro.finish();await process_frame
	check(game.mode=="flight","Story completion enters flight")
	game.set_mode("title");game.enter_ship_with_intro(true)
	check(game.mode=="flight","Returning to ship in same session does not replay story")
	game.free();await process_frame
	print("STARTUP: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
