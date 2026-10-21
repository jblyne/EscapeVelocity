extends Control

# Reconstructed from the original six-button bridge console. All artwork is
# fitted to the window from a fixed design canvas; raster art stays registered.
const GREEN=Color("80ed73")
const FRAME_RATE: float=15.0
const OPENING_DURATION: float=17.0/FRAME_RATE
const MOTION_DURATION: float=11.0/FRAME_RATE
# Registered against PICT 8000's actual asymmetrical button/rail locations.
const LEFT_ORIGINS=[Vector2(96,316),Vector2(96,387),Vector2(96,455)]
const RIGHT_ORIGINS=[Vector2(499,313),Vector2(499,384),Vector2(499,452)]
var bridge: Texture2D
var motion_finished: bool=false
var game
var canvas: Control
var screen: VBoxContainer

var presentation_started: bool=false
var discard_setup_delta: bool=false
var animation_time: float = 0.0
var animation_frames: Array[Texture2D] = []
var globe: Texture2D
var dialog: PanelContainer
var pilot_readout: Label
var pilot_picker: FileDialog

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black=ColorRect.new()
	black.color=Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	canvas=Control.new()
	canvas.size=Vector2(832,624)
	add_child(canvas)
	var art=TextureRect.new()
	bridge=load("res://assets/classic/8000.png")
	art.texture=bridge
	art.size=canvas.size
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(art)
	var animated=Control.new()
	animated.name="OriginalAnimation"
	animated.mouse_filter=Control.MOUSE_FILTER_IGNORE
	animated.draw.connect(draw_animation.bind(animated))
	canvas.add_child(animated)
	for frame in range(8300,8317): animation_frames.append(load("res://assets/classic/%d.png" % frame))
	globe=load("res://assets/classic/8001.png")
	resized.connect(fit)
	fit()
	for i in 3:
		menu_button(["New Pilot","Open Pilot","Quit EV"][i],LEFT_ORIGINS[i]+Vector2(115,0),[new_pilot,open_pilot,quit_game][i])
		var b=menu_button(["Enter Ship","Set Prefs","About EV"][i],RIGHT_ORIGINS[i],[enter_ship,preferences,about][i])
		if i==0: b.disabled=not game.pilot_ready
	pilot_readout=Label.new()
	pilot_readout.position=Vector2(365,350)
	pilot_readout.size=Vector2(104,150)
	pilot_readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	pilot_readout.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	pilot_readout.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	pilot_readout.add_theme_font_size_override("font_size",12)
	pilot_readout.add_theme_color_override("font_color",GREEN)
	canvas.add_child(pilot_readout)
	dialog=PanelContainer.new()
	dialog.position=Vector2(236,290)
	dialog.size=Vector2(360,290)
	dialog.add_theme_stylebox_override("panel",style(Color("041008"),Color("46544a"),18))
	canvas.add_child(dialog)
	screen=VBoxContainer.new()
	screen.add_theme_constant_override("separation",12)
	dialog.add_child(screen)
	var logo=Control.new();logo.position=Vector2(140,55);logo.size=Vector2(550,220)
	logo.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and event.alt_pressed: original_credits(true))
	canvas.add_child(logo)
	pilot_info()
	# Do not play panel machinery while the compositor still displays startup.
	if DisplayServer.get_name()=="headless": get_tree().process_frame.connect(begin_presentation,CONNECT_ONE_SHOT)
	else: RenderingServer.frame_post_draw.connect(begin_presentation,CONNECT_ONE_SHOT)

func begin_presentation() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or game.mode!="title": return
	presentation_started=true;discard_setup_delta=true
	game.start_title_audio()

func _process(dt: float) -> void:
	if not presentation_started: return
	# The first delta can include all synchronous scene setup/shader warming.
	if discard_setup_delta:
		discard_setup_delta=false;dt=0
	if is_instance_valid(credits_scroll):
		credits_position+=dt*20
		credits_scroll.scroll_vertical=int(credits_position)
	animation_time+=dt
	if not motion_finished and animation_time>=MOTION_DURATION:
		motion_finished=true
		game.finish_title_motion()
	canvas.get_node("OriginalAnimation").queue_redraw()

func animation_sample(at: float) -> Dictionary:
	var phase: float=clampf(at*FRAME_RATE,0,16)
	var first: int=int(floor(phase))
	return {"first":first,"next":mini(first+1,16),"blend":phase-first,
		"faces":smoothstep(16.0/FRAME_RATE,OPENING_DURATION,at)}

func panel_rect(row: int,side: int) -> Rect2:
	return Rect2(LEFT_ORIGINS[row] if side==0 else RIGHT_ORIGINS[row],Vector2(240,59))

func face_rect(row: int,side: int) -> Rect2:
	return Rect2(panel_rect(row,side).position+Vector2(115 if side==0 else 0,0),Vector2(125,59))

func draw_animation(surface: Control) -> void:
	# Keep the final mechanical frame on screen. Previously the strips vanished
	# at the end and exposed misaligned geometry in the background illustration.
	# Blend adjacent original frames for smooth motion at any render frequency.
	var sample: Dictionary=animation_sample(animation_time)
	for row in 3:
		for side in 2:
			var dest: Rect2=panel_rect(row,side)
			var source=Rect2((1-side)*240,0,240,59)
			surface.draw_texture_rect_region(animation_frames[sample.first],dest,source)
			if sample.next!=sample.first:
				surface.draw_texture_rect_region(animation_frames[sample.next],dest,source,Color(1,1,1,sample.blend))
			# Resolve the materializing text into each button's own label, without
			# replacing its piston/rail geometry or shifting its clickable bounds.
			if sample.faces>0:
				var face: Rect2=face_rect(row,side)
				surface.draw_texture_rect_region(bridge,face,face,Color(1,1,1,sample.faces))
	if animation_time>=OPENING_DURATION:
		for row in 3:
			for side in 2:
				var origin: Vector2=face_rect(row,side).position
				var offset=Vector2(9,16) if side==0 else Vector2(91,16)
				surface.draw_texture_rect_region(globe,Rect2(origin+offset,Vector2(25,25)),Rect2((int((animation_time-OPENING_DURATION)*10.0)%4)*25,0,25,25))

func fit() -> void:
	if not is_instance_valid(canvas): return
	var ratio=minf(size.x/832.0,size.y/624.0)
	canvas.scale=Vector2.ONE*ratio
	canvas.position=(size-canvas.size*ratio)/2

func style(fill: Color, border: Color, padding: int=10) -> StyleBoxFlat:
	var box=StyleBoxFlat.new()
	box.bg_color=fill
	box.border_color=border
	box.set_border_width_all(2)
	box.set_corner_radius_all(5)
	box.content_margin_left=padding;box.content_margin_right=padding
	box.content_margin_top=padding;box.content_margin_bottom=padding
	return box

func menu_button(caption: String, pos: Vector2, action: Callable) -> Button:
	var b=Button.new()
	b.name=caption.replace(" ","")
	b.tooltip_text=caption
	b.position=pos;b.size=Vector2(125,59)
	var clear=StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal",clear)
	b.add_theme_stylebox_override("disabled",clear)
	b.add_theme_stylebox_override("hover",style(Color(0.4,1,0.2,0.12),GREEN,0))
	b.add_theme_stylebox_override("pressed",style(Color(0,0,0,0.45),GREEN,0))
	b.pressed.connect(func():game.sound("menu_click");action.call())
	canvas.add_child(b)
	return b

func text_at(value: String, pos: Vector2, dimensions: Vector2, font_size: int, color: Color) -> void:
	var l=Label.new();l.text=value;l.position=pos;l.size=dimensions
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	canvas.add_child(l)

func clear_screen() -> void:
	dialog.show()
	for child in screen.get_children():
		screen.remove_child(child);child.queue_free()

func line(value: String, font_size: int=16) -> Label:
	var l=Label.new();l.text=value
	l.add_theme_color_override("font_color",GREEN)
	l.add_theme_font_size_override("font_size",font_size)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	screen.add_child(l)
	return l

func small_button(value: String, action: Callable) -> void:
	var b=Button.new();b.text=value;b.pressed.connect(func():game.sound("menu_click");action.call());screen.add_child(b)

func pilot_info() -> void:
	clear_screen()
	dialog.hide()
	pilot_readout.text="NO PILOT\n\nNew Pilot\nto begin" if not game.pilot_ready else (game.pilot.pilot_name+"\n"+("STRICT" if game.pilot.strict else "NORMAL")+"\n\n")+str(game.catalog.system(game.pilot.system_id).name)+"\n\nEnter Ship"

func new_pilot() -> void:
	clear_screen()
	line("NEW PILOT",20)
	line("Your current pilot will be saved. The new pilot gets a separate file.")
	var name=LineEdit.new();name.placeholder_text="Captain's name";name.max_length=64;screen.add_child(name)
	name.grab_focus()
	var strict=CheckBox.new();strict.text="Strict play — permanent death";screen.add_child(strict)
	line("Strict pilots cannot reload after death. An escape pod can still save you.")
	small_button("Begin new flight",func():
		if not game.create_pilot(name.text,strict.button_pressed):
			clear_screen();line("PILOT NOT CREATED",20);line(game.pilot_file_error);small_button("Back",new_pilot);small_button("Cancel",pilot_info))
	small_button("Cancel",pilot_info)

func open_pilot() -> void:
	if is_instance_valid(pilot_picker):
		pilot_picker.popup_centered(Vector2i(760,480));return
	pilot_picker=FileDialog.new();pilot_picker.name="OpenPilotDialog"
	pilot_picker.title="Open Pilot";pilot_picker.file_mode=FileDialog.FILE_MODE_OPEN_FILE
	pilot_picker.access=FileDialog.ACCESS_FILESYSTEM
	pilot_picker.filters=PackedStringArray(["*.json ; Escape Velocity HD pilots"])
	pilot_picker.use_native_dialog=DisplayServer.get_name()!="headless"
	var current: String=ProjectSettings.globalize_path(game.save_path)
	pilot_picker.current_dir=current.get_base_dir()
	if FileAccess.file_exists(current): pilot_picker.current_file=current.get_file()
	add_child(pilot_picker)
	pilot_picker.file_selected.connect(open_pilot_path)
	pilot_picker.popup_centered(Vector2i(760,480))

func open_pilot_path(path: String) -> void:
	if is_instance_valid(pilot_picker): pilot_picker.hide()
	var error: String=game.open_pilot_file(path)
	if not error.is_empty():
		clear_screen();line("UNABLE TO OPEN PILOT",20);line(error)
		small_button("Choose another pilot",open_pilot)
		small_button("Cancel",pilot_info)
		return
	pilot_info()
	canvas.get_node("EnterShip").disabled=false

func enter_ship() -> void:
	if game.pilot_ready: game.enter_ship_with_intro()

func preferences() -> void:
	clear_screen();line("PREFERENCES",20)
	var sound=CheckBox.new();sound.text="Sound effects";sound.button_pressed=not game.muted
	sound.toggled.connect(func(_enabled):game.toggle_audio();game.sound("menu_click"))
	screen.add_child(sound)
	var full=CheckBox.new();full.text="Fullscreen";full.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
	full.toggled.connect(func(enabled):game.sound("menu_click");DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
	screen.add_child(full)
	small_button("Keyboard & game speed",game.open_controls)
	small_button("Done",pilot_info)

func about() -> void:
	clear_screen();line("ABOUT EV",20)
	line("Escape Velocity\nCreated by Matt Burch\nAmbrosia Software, 1996")
	line("Escape Velocity HD\nA modern recreation in Godot.")
	small_button("Original credits",original_credits)
	small_button("Original haikus",haikus)
	small_button("Done",pilot_info)

func quit_game() -> void:
	if game.pilot_ready: game.save_game(false)
	get_tree().quit()

var extras_panel: PanelContainer
var credits_scroll: ScrollContainer
var credits_label: Label
var parody_credits: bool=false
var credits_position: float=0
var song: AudioStreamPlayer

func original_credits(parody: bool=false) -> void:
	close_extras()
	parody_credits=parody
	extras_panel=PanelContainer.new()
	extras_panel.position=Vector2(100,50);extras_panel.size=Vector2(632,524)
	extras_panel.add_theme_stylebox_override("panel",style(Color("041008"),GREEN,20))
	canvas.add_child(extras_panel)
	var column=VBoxContainer.new();extras_panel.add_child(column)
	credits_scroll=ScrollContainer.new();credits_scroll.custom_minimum_size=Vector2(580,450)
	column.add_child(credits_scroll)
	credits_label=Label.new();credits_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	credits_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	credits_label.add_theme_font_size_override("font_size",18)
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/original_extras.json"))
	credits_label.text="\n".join(data["20002" if parody else "20001"].strings)
	credits_scroll.add_child(credits_label)
	credits_position=0
	var done=Button.new();done.text="Done";done.pressed.connect(func():game.sound("menu_click");close_extras());column.add_child(done)

func close_extras() -> void:
	if is_instance_valid(extras_panel): extras_panel.queue_free()
	extras_panel=null;credits_scroll=null;credits_label=null;parody_credits=false

func haikus() -> void:
	close_extras()
	extras_panel=PanelContainer.new();extras_panel.position=Vector2(196,90)
	canvas.add_child(extras_panel)
	var column=VBoxContainer.new();extras_panel.add_child(column)
	var art=TextureRect.new();art.texture=load("res://assets/classic/8011.png");column.add_child(art)
	var done=Button.new();done.text="Done";done.pressed.connect(func():game.sound("menu_click");close_extras());column.add_child(done)

func unlock_forklift() -> void:
	if not game.pilot_ready: return
	game.pilot.secrets.forklift=true
	game.save_game(false)
	if not is_instance_valid(song): song=AudioStreamPlayer.new();add_child(song)
	song.stream=load("res://audio/forklift_song.wav");song.volume_db=-14 if not game.muted else -80;song.play()
	game.notify("Why not kill them with a forklift? Forklift unlocked for this pilot.")

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if get_viewport().gui_get_focus_owner() is LineEdit: return
	if event.keycode==KEY_X and not is_instance_valid(extras_panel): haikus();get_viewport().set_input_as_handled();return
	if event.keycode==KEY_ESCAPE and is_instance_valid(extras_panel): close_extras();get_viewport().set_input_as_handled();return
	if Input.is_physical_key_pressed(KEY_S) and Input.is_physical_key_pressed(KEY_O) and Input.is_physical_key_pressed(KEY_L):
		game.pilot.secrets.satellite=true;game.save_game(false);clear_screen();line("A familiar satellite may appear at a shipyard…");get_viewport().set_input_as_handled();return
	if not parody_credits or not is_instance_valid(credits_label): return
	if event.keycode==KEY_F and event.ctrl_pressed and event.meta_pressed and event.alt_pressed and event.shift_pressed:
		var lines=credits_label.text.split("\n")
		for i in lines.size():
			if "MCB 4:35" in lines[i]:
				var y=i*credits_label.get_line_height()-credits_scroll.scroll_vertical
				if y>=0 and y<450: unlock_forklift()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if dialog.visible or is_instance_valid(extras_panel) or (is_instance_valid(pilot_picker) and pilot_picker.visible): return
	var key: int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
	var actions: Dictionary={KEY_N:new_pilot,KEY_O:open_pilot,KEY_Q:quit_game,KEY_E:enter_ship,KEY_ENTER:enter_ship,KEY_P:preferences,KEY_A:about}
	if actions.has(key):
		get_viewport().set_input_as_handled();game.sound("menu_click");actions[key].call()
