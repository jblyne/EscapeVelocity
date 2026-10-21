extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func frame(menu,at: float,path: String="") -> Image:
	menu.animation_time=at;menu.canvas.get_node("OriginalAnimation").queue_redraw()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var result: Image=root.get_texture().get_image()
	if not path.is_empty(): result.save_png(ProjectSettings.globalize_path("res://../builds/"+path+".png"))
	return result
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-menu-presentation-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.pilot_ready=true;game.set_mode("title")
	var menu=game.hud.modal_root.get_child(0);menu.set_process(false)
	check(not game.audio.menu_hum.playing,"Mechanical hum waits until menu presentation")
	menu.begin_presentation();menu._process(10)
	check(menu.animation_time==0 and game.audio.menu_music.playing and game.audio.menu_hum.playing,"Presented menu starts audio and discards scene setup delta")
	for key in ["menu_click","menu_hum","menu_slam","menu_music"]:
		check(game.audio[key].stream is AudioStreamWAV and game.audio[key].max_polyphony==1,"Original menu recording loaded with bounded playback: "+key)
	check(menu.animation_sample(.5/15).first==0 and is_equal_approx(menu.animation_sample(.5/15).blend,.5),"Original frames interpolate between source poses")
	var before: Dictionary=menu.animation_sample(menu.OPENING_DURATION-.001)
	var after: Dictionary=menu.animation_sample(menu.OPENING_DURATION+.001)
	check(before.first==16 and after.first==16 and before.next==after.next,"Final mechanical frame stays present across opening completion")
	for row in 3:
		for side in 2:
			var name: String=(["NewPilot","OpenPilot","QuitEV"] if side==0 else ["EnterShip","SetPrefs","AboutEV"])[row]
			var button=menu.canvas.get_node(name)
			check(Rect2(button.position,button.size)==menu.face_rect(row,side),"Clickable area matches registered artwork: "+name)
	menu._process(menu.MOTION_DURATION+.001)
	check(not game.audio.menu_hum.playing and game.audio.menu_slam.playing and menu.motion_finished,"Panel lock stops hum and plays recovered slam once")
	game.audio.menu_slam.stop();menu._process(.2)
	check(not game.audio.menu_slam.playing,"Slam cannot retrigger after motion finishes")
	menu.canvas.get_node("SetPrefs").pressed.emit()
	check(game.audio.menu_click.playing,"Menu button plays original click recording")
	game.toggle_audio()
	check(game.audio.values().all(func(a):return not a.playing),"Mute immediately stops all menu recordings")
	game.toggle_audio()
	check(game.audio.menu_music.playing and not game.audio.menu_slam.playing,"Unmute resumes title music without replaying panel slam")
	menu.pilot_info();game.pilot.credits=24680;game.save_game(false)
	var same_menu: int=menu.get_instance_id();menu.open_pilot()
	check(game.hud.modal_root.get_child(0).get_instance_id()==same_menu and menu.animation_time>0,"Opening pilot preserves menu instance and panel pose")
	if "--visual" in OS.get_cmdline_user_args():
		await frame(menu,0,"menu-opening-start")
		await frame(menu,.35,"menu-opening-moving")
		var a: Image=await frame(menu,menu.OPENING_DURATION-.001,"menu-opening-before")
		var b: Image=await frame(menu,menu.OPENING_DURATION+.001,"menu-opening-after")
		var unchanged: bool=true
		for row in 3:
			for side in 2:
				var panel: Rect2=menu.panel_rect(row,side)
				var face: Rect2=menu.face_rect(row,side)
				for y in range(2,57):
					for x in range(2,238):
						var local: Vector2=panel.position+Vector2(x,y)
						if face.grow(1).has_point(local): continue
						var pixel: Vector2i=Vector2i(menu.canvas.position+local*menu.canvas.scale.x)
						unchanged=unchanged and a.get_pixelv(pixel)==b.get_pixelv(pixel)
		check(unchanged,"Rendered pistons and rails do not move or disappear at completion")
	game.set_mode("flight")
	check(not game.audio.menu_music.playing and not game.audio.menu_hum.playing and not game.audio.menu_slam.playing,"Leaving title stops music and mechanical sounds")
	game.finish_title_motion()
	check(not game.audio.menu_slam.playing,"Deferred menu frame cannot play a slam in flight")
	game.free();await process_frame
	print("MENU PRESENTATION: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
