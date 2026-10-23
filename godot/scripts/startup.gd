extends Control
# Original startup call order and music resources verified in EV 1.0.5 PPC.
# Loading duration depends on hardware; palette fades are mapped to 60 Hz.
const GAME="res://main.tscn"
const STORY=preload("res://data/intro_story.json")
signal story_revealed
signal story_finished
signal opening_finished
var replay_only: bool=false
var replay_music: AudioStreamPlayer
var finished: bool=false
var fade_cover: ColorRect
var transition_to: String=""
var transition_elapsed: float=0
const STORY_FADE_SECONDS=0.6
const FADE_SECONDS=16.0/60.0
const BLACK_HOLD_SECONDS=.08
const LOGO_HOLD_SECONDS=2.0
const LOADING_SECONDS=1.5
const COMPLETE_HOLD_SECONDS=.25
const ARRIVAL_SECONDS=480.0/60.0
const STORY_SPEED=30.0*1.3
var story_only: bool=false
var music_muted: bool=false
var music: AudioStreamPlayer
var phase: String="logo"
var elapsed: float=0
var canvas: Control
var art: TextureRect
var wide_art: Control
var progress: ProgressBar
var story_clip: Control
var story_paintings: Control
var story: Label
var hint: Label
var scene: PackedScene
var loading_error: bool=false
var discard_setup_delta: bool=false
var complete_elapsed: float=0

func _ready() -> void:
	var preferences=preload("res://scripts/control_settings.gd").new()
	preferences.load_settings();preferences.apply_audio()
	music_muted=music_muted or not preferences.intro_music
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args=OS.get_cmdline_user_args()
	if not story_only and not replay_only and Array(args).any(func(arg):return arg in ["--skip-intro","--show-menu","--show-map","--show-port","--show-cheats"]):
		get_tree().call_deferred("change_scene_to_file",GAME)
		return
	var black=ColorRect.new();black.color=Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(black)
	wide_art=load("res://scripts/title_bridge.gd").new()
	wide_art.artwork=load("res://assets/startup/loading_hd.png")
	wide_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	wide_art.hide();add_child(wide_art)
	story_paintings=preload("res://scripts/story_paintings.gd").new()
	story_paintings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	story_paintings.hide();add_child(story_paintings)
	canvas=Control.new();canvas.size=Vector2(832,624);add_child(canvas)
	art=TextureRect.new();art.size=canvas.size
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	canvas.add_child(art)
	progress=ProgressBar.new();progress.position=Vector2(316,579);progress.size=Vector2(200,10)
	progress.show_percentage=false;progress.add_theme_font_size_override("font_size",1);canvas.add_child(progress)
	var track=StyleBoxFlat.new();track.bg_color=Color.BLACK
	track.border_color=Color("036a00");track.set_border_width_all(1)
	var fill=StyleBoxFlat.new();fill.bg_color=Color("08eb00")
	fill.border_color=Color("7b7384");fill.set_border_width_all(1)
	progress.add_theme_stylebox_override("background",track)
	progress.add_theme_stylebox_override("fill",fill)
	progress.size=Vector2(200,10)
	story_clip=Control.new();story_clip.position=Vector2(150,0);story_clip.size=Vector2(532,624)
	story_clip.clip_contents=true;canvas.add_child(story_clip)
	var shade=ColorRect.new();shade.color=Color.TRANSPARENT;shade.size=story_clip.size;story_clip.add_child(shade)
	story=Label.new();story.size=Vector2(532,0);story.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var font=SystemFont.new();font.font_names=PackedStringArray(["Times New Roman","Times","Liberation Serif"])
	story.add_theme_font_override("font",font)
	var font_size: int=31
	var max_width: float=0
	for line in STORY.data: max_width=maxf(max_width,font.get_string_size(str(line),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
	if max_width>512: font_size=floori(font_size*512/max_width)
	story.add_theme_font_size_override("font_size",font_size)
	story.add_theme_constant_override("line_spacing",roundi(39-font.get_height(font_size)))
	story.add_theme_color_override("font_outline_color",Color.BLACK)
	story.add_theme_constant_override("outline_size",2)
	story.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	story.text="\n".join(PackedStringArray(STORY.data))
	story_clip.add_child(story)
	hint=Label.new();hint.position=Vector2(0,598);hint.size.x=832
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",13)
	hint.modulate=Color(.7,.7,.7);canvas.add_child(hint)
	fade_cover=ColorRect.new();fade_cover.color=Color(0,0,0,0)
	fade_cover.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fade_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(fade_cover)
	resized.connect(fit);fit()
	music=replay_music if is_instance_valid(replay_music) else AudioStreamPlayer.new()
	if not replay_only: music.volume_db=-80 if music_muted else -20;music.max_polyphony=1
	if story_only:
		music.volume_db=-80 if music_muted else -20
		add_child(music);music.finished.connect(next_drum)
		show_phase("arrival")
		return
	if not replay_only:
		music.name="BootTitleMusic"
		add_child(music)
	music.stream=load("res://audio/menu_music.wav")
	if not music_muted: music.play()
	show_phase("logo")
	call_deferred("load_game_scene")

func load_game_scene() -> void:
	# Script shader/texture preloads must resolve on the main thread in exports.
	# Let the logo render first; loading does not instantiate or animate the menu.
	await get_tree().process_frame
	scene=load(GAME)
	loading_error=scene==null

func fit() -> void:
	var factor=minf(size.x/832.0,size.y/624.0)
	canvas.scale=Vector2.ONE*factor;canvas.position=(size-canvas.size*factor)*.5
	wide_art.size=size;wide_art.queue_redraw()
	if is_instance_valid(story_clip):
		story_clip.position.y=-canvas.position.y/factor
		story_clip.size.y=size.y/factor
		if phase=="story": story.position.y=story_clip.size.y-elapsed*STORY_SPEED

func show_phase(value: String) -> void:
	phase=value;elapsed=0
	story_paintings.visible=value=="story"
	if value=="story": story_paintings.present(story_clip.size.y,39,STORY_SPEED,story_clip.size.y)
	transition_to="";transition_elapsed=0;fade_cover.color.a=0
	art.modulate.a=0;wide_art.modulate.a=0;progress.modulate.a=0
	discard_setup_delta=value in ["logo","loading"]
	complete_elapsed=0
	if value=="loading": progress.value=0
	hint.text="";hint.hide()
	progress.visible=value=="loading";story_clip.visible=value=="story"
	wide_art.visible=value=="loading";art.visible=value!="loading"
	art.position=Vector2(0,(canvas.size.y-560)*.5) if value=="logo" else Vector2.ZERO
	art.size=Vector2(832,560) if value=="logo" else canvas.size
	if value=="logo":
		art.texture=load("res://assets/startup/ambrosia_hd.png")
	elif value=="loading":
		art.texture=load("res://assets/startup/loading_hd.png")
	elif value=="arrival":
		art.texture=load("res://assets/startup/levo_arrival_hd.png")
		music.stream=load("res://audio/intro_transition.wav");music.play()
	else:
		art.texture=null
		story.position.y=story_clip.size.y
		music.stop();music.stream=load("res://audio/intro_drums.wav");music.play()

func next_drum() -> void:
	if phase!="story": return
	var loop: AudioStreamWAV=load("res://audio/intro_drum_loop.wav").duplicate()
	loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin=0;loop.loop_end=roundi(loop.get_length()*loop.mix_rate)
	music.stream=loop;music.set_meta("original_resource",30002);music.play()

func _process(dt: float) -> void:
	if not is_instance_valid(canvas): return
	if discard_setup_delta:
		discard_setup_delta=false;dt=0
	if phase=="game_reveal":
		transition_elapsed+=dt
		fade_cover.color.a=1-clampf(transition_elapsed/STORY_FADE_SECONDS,0,1)
		if transition_elapsed>=STORY_FADE_SECONDS:
			set_process(false);story_revealed.emit()
		return
	if not transition_to.is_empty():
		transition_elapsed+=dt
		var duration: float=STORY_FADE_SECONDS if transition_to=="flight" else FADE_SECONDS
		fade_cover.color.a=clampf(transition_elapsed/duration,0,1)
		if transition_elapsed>=duration+BLACK_HOLD_SECONDS:
			if transition_to=="flight":
				finished=true;music.stop();transition_to="";transition_elapsed=0;phase="game_reveal"
				for child in get_children():
					if child is CanvasItem and child!=fade_cover: child.hide()
				story_finished.emit();return
			if transition_to=="menu": finish()
			else: show_phase(transition_to)
		return
	elapsed+=dt
	if loading_error:
		hint.text="Unable to load the game. Press Esc to quit.";hint.show();return
	art.modulate.a=clampf(elapsed/FADE_SECONDS,0,1)
	wide_art.modulate.a=art.modulate.a
	progress.modulate.a=art.modulate.a
	if phase=="logo" and scene!=null and elapsed>=LOGO_HOLD_SECONDS: transition_to="loading";transition_elapsed=0
	elif phase=="loading":
		# Fast, visible incremental presentation even when resources are cached.
		# Never show completion or enter the menu before the scene is ready.
		var ceiling: float=100 if scene!=null else 96
		progress.value=minf(ceiling,floorf(elapsed/LOADING_SECONDS*25.0)*4.0)
		if progress.value>=100: complete_elapsed+=minf(dt,maxf(0,elapsed-LOADING_SECONDS))
		if complete_elapsed>=COMPLETE_HOLD_SECONDS: transition_to="menu";transition_elapsed=0
	elif phase=="arrival" and elapsed>=ARRIVAL_SECONDS: show_phase("story")
	elif phase=="story":
		story.position.y=story_clip.size.y-elapsed*STORY_SPEED
		story_paintings.present(story.position.y,39,STORY_SPEED,story_clip.size.y)
		if story.position.y+story.size.y<0: finish()

func finish() -> void:
	if finished or transition_to=="flight": return
	if story_only:
		transition_to="flight";transition_elapsed=0;return
	finished=true
	if replay_only:
		opening_finished.emit()
	elif story_only:
		music.stop();story_finished.emit()
	elif scene!=null:
		music.reparent(get_tree().root)
		get_tree().change_scene_to_packed(scene)

func _input(event: InputEvent) -> void:
	var pressed=(event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A,JOY_BUTTON_START]) or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE,KEY_ENTER,KEY_ESCAPE]) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)
	if not pressed: return
	get_viewport().set_input_as_handled()
	if loading_error:
		if event is InputEventKey and event.physical_keycode==KEY_ESCAPE: get_tree().quit()
	elif phase=="arrival": show_phase("story")
	elif phase=="story": finish()
