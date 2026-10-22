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
	menu.animation_time=at;menu.update_presentation()
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
	var readout_font=menu.pilot_readout.get_theme_font("font")
	check(readout_font is SystemFont and readout_font.font_names==PackedStringArray(["Geneva"]),"Pilot readout uses original Geneva family")
	check(menu.pilot_readout.get_theme_font_size("font_size")==12,"Original nine-point readout scales to the HD design canvas")
	check(menu.fade_cover.color.a==1,"Menu begins fully black for its incoming fade")
	check(not game.audio.menu_hum.playing,"Mechanical hum waits until menu presentation")
	menu.begin_presentation();menu._process(10)
	check(menu.animation_time==0 and game.audio.menu_music.playing and game.audio.menu_hum.playing,"Presented menu starts audio and discards scene setup delta")
	for key in ["menu_click","menu_hum","menu_slam","menu_music"]:
		check(game.audio[key].stream is AudioStreamWAV and game.audio[key].max_polyphony==1,"Original menu recording loaded with bounded playback: "+key)
	check(menu.animation_sample(.5/15).first==0 and is_equal_approx(menu.animation_sample(.5/15).blend,.5),"Original frames interpolate between source poses")
	var last_motion: float=-1
	var last_faces: float=-1
	for i in 121:
		var sample: Dictionary=menu.animation_sample(menu.OPENING_DURATION*i/120.0)
		check(sample.motion>=last_motion and sample.faces>=last_faces,"HD pose and text advance monotonically: %d" % i)
		check(sample.ink_phase==menu.Lettering.phase(menu.OPENING_DURATION*i/120.0),"Ink and panels share one animation clock: %d" % i)
		last_motion=sample.motion;last_faces=sample.faces
	var folded=menu.PanelMotion.corners(0)
	var tilted=menu.PanelMotion.corners(5.0/15.0)
	var opened=menu.PanelMotion.corners(menu.PANEL_STOP_SECONDS)
	check(folded[1].distance_to(folded[0])<8,"Original opening starts folded edge-on beside the hinge")
	check(absf(tilted[2].x-tilted[1].x)>35 and absf(tilted[3].y-tilted[0].y)>35,"Original middle pose unfolds in perspective instead of translating a flat rectangle")
	check(opened[0]==Vector2(114,0) and opened[2]==Vector2(240,59),"Original fully open keyframe is retained")
	check(menu.Lettering.phase(9.9/15.0)==-1,"Lettering waits for the early folding poses")
	for timing in [[10,0],[12,1],[14,2],[16,3],[17,4]]:
		check(menu.Lettering.phase(timing[0]/15.0+.00001)==timing[1],"Ink phase follows the overlapping folding timeline: %d" % timing[0])
	check(menu.Lettering.phase(10.5/15.0)>=0 and menu.animation_sample(10.5/15.0).motion<1,"Text materializes while panels are still moving")
	var padded_center=menu.Lettering.bounds(0,0).get_center()
	check(menu.PanelMotion.warp_design(padded_center,0,0,10.5/15.0).distance_to(padded_center)>1,"Materializing ink stays attached to the moving face")
	check(menu.PanelMotion.registered_pose(11,0).distance_to(menu.PanelMotion.registered_pose(12,0))<1,"Final hinge registration does not shift sideways")
	for row in 3:
		for side in 2:
			var ink: Rect2=menu.Lettering.bounds(row,side)
			var top: float=[474.0,587.0,701.0][row]
			var bottom: float=[568.0,682.0,798.0][row]
			var face_top: float=menu.PanelMotion.design(Vector2(0,top)).y
			var face_bottom: float=menu.PanelMotion.design(Vector2(0,bottom)).y
			check(ink.position.y-face_top>=9 and face_bottom-ink.end.y>=9,"Original caption has balanced vertical padding: %d/%d" % [row,side])
	var before: Dictionary=menu.animation_sample(menu.OPENING_DURATION-.001)
	var after: Dictionary=menu.animation_sample(menu.OPENING_DURATION+.001)
	check(before.first==16 and after.first==16 and before.next==after.next,"Final mechanical frame stays present across opening completion")
	for row in 3:
		for side in 2:
			var name: String=(["NewPilot","OpenPilot","QuitEV"] if side==0 else ["EnterShip","SetPrefs","AboutEV"])[row]
			var button=menu.canvas.get_node(name)
			check(Rect2(button.position,button.size)==menu.face_rect(row,side),"Clickable area matches registered artwork: "+name)
	menu.animation_time=menu.FADE_SECONDS*.5;menu.update_presentation()
	check(is_equal_approx(menu.fade_cover.color.a,.5),"Menu fades progressively in from black")
	menu.animation_time=0
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
		for pose in 18:
			var at: float=menu.OPENING_DURATION*pose/17.0
			await frame(menu,at,"menu-hd-pose-%02d" % pose)
			check(menu.PanelMotion.corners(at).size()==4,"Rendered HD pose uses continuous motion: %d" % pose)
		await frame(menu,0,"menu-opening-start")
		await frame(menu,.35,"menu-opening-moving")
		var a: Image=await frame(menu,menu.PANEL_STOP_SECONDS-.001,"menu-opening-before")
		var b: Image=await frame(menu,menu.PANEL_STOP_SECONDS+.001,"menu-opening-after")
		var maximum_change: float=0.0
		for row in 3:
			for side in 2:
				var panel: Rect2=menu.panel_rect(row,side)
				var face: Rect2=menu.face_rect(row,side)
				for y in range(2,57):
					for x in range(2,238):
						var local: Vector2=panel.position+Vector2(x,y)
						if face.grow(1).has_point(local): continue
						if local.distance_to(Vector2(204 if side==0 else 628,345+row*75))<15: continue
						var pixel: Vector2i=Vector2i(menu.canvas.position+local*menu.canvas.scale.x)
						maximum_change=maxf(maximum_change,Vector3(a.get_pixelv(pixel).r-b.get_pixelv(pixel).r,a.get_pixelv(pixel).g-b.get_pixelv(pixel).g,a.get_pixelv(pixel).b-b.get_pixelv(pixel).b).length())
		check(maximum_change<.04,"HD geometry stays continuous across the actual motion boundary")
		var final_a: Image=await frame(menu,menu.OPENING_DURATION-.001,"menu-labels-before")
		var final_b: Image=await frame(menu,menu.OPENING_DURATION+.001,"menu-labels-after")
		var largest_step: int=0
		var pixels_a=final_a.get_data();var pixels_b=final_b.get_data()
		for i in pixels_a.size(): largest_step=maxi(largest_step,absi(int(pixels_a[i])-int(pixels_b[i])))
		check(menu.Lettering.phase(menu.OPENING_DURATION-.001)==3 and menu.Lettering.phase(menu.OPENING_DURATION+.001)==4,"Original final noisy frame resolves to original letterforms on tick 17")
		for dimensions in [Vector2i(1280,720),Vector2i(2560,1080),Vector2i(1024,768)]:
			root.size=dimensions
			for i in 4: await process_frame
			menu.fit()
			await frame(menu,3,"menu-hd-%dx%d" % [dimensions.x,dimensions.y])
			check(menu.backdrop.size==menu.size,"Bridge fills window at %s" % dimensions)
			check(is_equal_approx(menu.canvas.scale.x,menu.canvas.scale.y),"Original console keeps its proportions at %s" % dimensions)
			for name in ["NewPilot","OpenPilot","QuitEV","EnterShip","SetPrefs","AboutEV"]:
				check(menu.get_global_rect().encloses(menu.canvas.get_node(name).get_global_rect()),"Original control stays visible: "+name)
	game.set_mode("flight")
	check(not game.audio.menu_music.playing and not game.audio.menu_hum.playing and not game.audio.menu_slam.playing,"Leaving title stops music and mechanical sounds")
	game.finish_title_motion()
	check(not game.audio.menu_slam.playing,"Deferred menu frame cannot play a slam in flight")
	game.free();await process_frame
	print("MENU PRESENTATION: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
