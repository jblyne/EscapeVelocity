extends Control
# Original startup call order and music resources verified in EV 1.0.5 PPC.
# Loading duration depends on hardware; palette fades are mapped to 60 Hz.
const GAME="res://main.tscn"
const STORY=preload("res://data/intro_story.json")
signal story_finished
const FADE_SECONDS=16.0/60.0
const ARRIVAL_SECONDS=480.0/60.0
const STORY_SPEED=30.0*1.3
var story_only: bool=false
var music_muted: bool=false
var music: AudioStreamPlayer
var phase: String="logo"
var elapsed: float=0
var canvas: Control
var art: TextureRect
var progress: ProgressBar
var story_clip: Control
var story: Label
var hint: Label
var scene: PackedScene
var loading_error: bool=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var args=OS.get_cmdline_user_args()
	if not story_only and Array(args).any(func(arg):return arg in ["--skip-intro","--show-menu","--show-map","--show-port","--show-cheats"]):
		get_tree().call_deferred("change_scene_to_file",GAME)
		return
	var black=ColorRect.new();black.color=Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(black)
	canvas=Control.new();canvas.size=Vector2(832,624);add_child(canvas)
	art=TextureRect.new();art.size=canvas.size
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	canvas.add_child(art)
	progress=ProgressBar.new();progress.position=Vector2(150,578);progress.size=Vector2(532,8)
	progress.show_percentage=false;canvas.add_child(progress)
	story_clip=Control.new();story_clip.position=Vector2(150,104);story_clip.size=Vector2(532,416)
	story_clip.clip_contents=true;canvas.add_child(story_clip)
	var shade=ColorRect.new();shade.color=Color.BLACK;shade.size=story_clip.size;story_clip.add_child(shade)
	story=Label.new();story.size=Vector2(532,0);story.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var font=SystemFont.new();font.font_names=PackedStringArray(["Times New Roman","Times","Liberation Serif"])
	story.add_theme_font_override("font",font)
	var font_size: int=31
	var max_width: float=0
	for line in STORY.data: max_width=maxf(max_width,font.get_string_size(str(line),HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
	if max_width>512: font_size=floori(font_size*512/max_width)
	story.add_theme_font_size_override("font_size",font_size)
	story.add_theme_constant_override("line_spacing",roundi(39-font.get_height(font_size)))
	story.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	story.text="\n".join(PackedStringArray(STORY.data))
	story_clip.add_child(story)
	hint=Label.new();hint.position=Vector2(0,598);hint.size.x=832
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",13)
	hint.modulate=Color(.7,.7,.7);canvas.add_child(hint)
	resized.connect(fit);fit()
	music=AudioStreamPlayer.new();music.volume_db=-20;music.max_polyphony=1
	if story_only:
		music.volume_db=-80 if music_muted else -20
		add_child(music);music.finished.connect(next_drum)
		show_phase("arrival")
		return
	music.name="BootTitleMusic"
	add_child(music)
	music.stream=load("res://audio/menu_music.wav");music.play()
	show_phase("logo")
	call_deferred("load_game_scene")

func load_game_scene() -> void:
	# Script shader/texture preloads must resolve on the main thread in exports.
	# Let the logo render first; loading does not instantiate or animate the menu.
	await get_tree().process_frame
	scene=load(GAME)
	loading_error=scene==null
	if not loading_error: progress.value=100

func fit() -> void:
	var factor=minf(size.x/832.0,size.y/624.0)
	canvas.scale=Vector2.ONE*factor;canvas.position=(size-canvas.size*factor)*.5

func show_phase(value: String) -> void:
	phase=value;elapsed=0
	progress.visible=value=="loading";story_clip.visible=value=="story"
	if value=="logo":
		art.texture=load("res://assets/classic/8100.png")
		hint.text="Click or press Space to continue"
	elif value=="loading":
		art.texture=load("res://assets/classic/131.png")
		hint.text="Loading Escape Velocity…"
	elif value=="arrival":
		art.texture=load("res://assets/classic/8200.png")
		hint.text="Click, Space or Esc to continue"
		music.stream=load("res://audio/intro_transition.wav");music.play()
	else:
		art.texture=null
		story.position.y=story_clip.size.y
		hint.text="Click, Space or Esc to skip the introduction"
		music.stop();music.stream=load("res://audio/intro_drums.wav");music.play()

func next_drum() -> void:
	if phase!="story": return
	var loop: AudioStreamWAV=load("res://audio/intro_drum_loop.wav").duplicate()
	loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin=0;loop.loop_end=roundi(loop.get_length()*loop.mix_rate)
	music.stream=loop;music.set_meta("original_resource",30002);music.play()

func _process(dt: float) -> void:
	if not is_instance_valid(canvas): return
	elapsed+=dt
	if loading_error:
		hint.text="Unable to load the game. Press Esc to quit.";return
	art.modulate.a=clampf(elapsed/FADE_SECONDS,0,1)
	if phase=="logo" and scene!=null and elapsed>=FADE_SECONDS: show_phase("loading")
	elif phase=="loading" and scene!=null and elapsed>=FADE_SECONDS: finish()
	elif phase=="arrival" and elapsed>=ARRIVAL_SECONDS: show_phase("story")
	elif phase=="story":
		story.position.y=story_clip.size.y-elapsed*STORY_SPEED
		if story.position.y+story.size.y<0: finish()

func finish() -> void:
	if story_only:
		music.stop();story_finished.emit()
	elif scene!=null:
		music.reparent(get_tree().root)
		get_tree().change_scene_to_packed(scene)

func _input(event: InputEvent) -> void:
	var pressed=(event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE,KEY_ENTER,KEY_ESCAPE]) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)
	if not pressed: return
	get_viewport().set_input_as_handled()
	if loading_error:
		if event is InputEventKey and event.physical_keycode==KEY_ESCAPE: get_tree().quit()
	elif phase=="logo": show_phase("loading")
	elif phase=="arrival": show_phase("story")
	elif phase=="story": finish()
