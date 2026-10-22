extends Control

# Reconstructed from the original six-button bridge console. All artwork is
# fitted to the window from a fixed design canvas; raster art stays registered.
const MacDialog=preload("res://scripts/mac_dialog_theme.gd")
const Lettering=preload("res://scripts/menu_lettering.gd")
const PanelMotion=preload("res://scripts/menu_panel_motion.gd")
const FADE_SECONDS: float=16.0/60.0
const PANEL_STOP_SECONDS: float=12.0/15.0
const GREEN=Color("80ed73")
const FRAME_RATE: float=15.0
const OPENING_DURATION: float=17.0/FRAME_RATE
const MOTION_DURATION: float=11.0/FRAME_RATE
# Registered against PICT 8000's actual asymmetrical button/rail locations.
const LEFT_ORIGINS=[Vector2(96,316),Vector2(96,387),Vector2(96,455)]
const RIGHT_ORIGINS=[Vector2(499,313),Vector2(499,384),Vector2(499,452)]
var fade_cover: ColorRect
var bridge: Texture2D
var backdrop: Control
var motion_finished: bool=false
var game
var canvas: Control
var screen: VBoxContainer

var presentation_started: bool=false
var discard_setup_delta: bool=false
var animation_time: float = 0.0
var dialog: PanelContainer
var pilot_readout: Label
var pilot_picker: ItemList

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black=ColorRect.new()
	black.color=Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	canvas=Control.new()
	canvas.size=Vector2(832,624)
	add_child(canvas)
	backdrop=load("res://scripts/title_bridge.gd").new()
	backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(backdrop);move_child(backdrop,1)
	backdrop.hide_static_panels=true
	var atlas=AtlasTexture.new()
	var hd: Texture2D=load("res://assets/menu/bridge_hd.png")
	atlas.atlas=hd
	atlas.region=Rect2(hd.get_width()*.125,0,hd.get_width()*.75,hd.get_height())
	bridge=atlas
	var animated=Control.new()
	animated.name="OriginalAnimation"
	animated.mouse_filter=Control.MOUSE_FILTER_IGNORE
	animated.draw.connect(draw_animation.bind(animated))
	canvas.add_child(animated)
	resized.connect(fit)
	fit()
	for i in 3:
		var left_button=menu_button(["New Pilot","Open Pilot","Quit EV"][i],face_rect(i,0).position,[new_pilot,open_pilot,quit_game][i])
		left_button.size=face_rect(i,0).size
		var b=menu_button(["Enter Ship","Set Prefs","About EV"][i],face_rect(i,1).position,[enter_ship,preferences,about][i])
		b.size=face_rect(i,1).size
		if i==0: b.disabled=not game.pilot_ready
		for side in 2:
			var label=Lettering.new()
			label.name="Ink%d%d" % [i,side];label.row=i;label.side=side
			label.disabled_ink=side==1 and i==0 and not game.pilot_ready
			var placement: Rect2=Lettering.bounds(i,side)
			label.position=placement.position;label.size=placement.size
			canvas.add_child(label)
	pilot_readout=Label.new()
	pilot_readout.position=Vector2(365,350)
	pilot_readout.size=Vector2(104,150)
	pilot_readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	pilot_readout.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	pilot_readout.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	# EV 1.0.5 readout: TextFont(3 / Geneva), TextSize(9), at 0x4d024.
	# The HD design canvas scales the original 640 x 480 coordinates by 1.3.
	var readout_font=SystemFont.new()
	readout_font.font_names=PackedStringArray(["Geneva"])
	readout_font.hinting=TextServer.HINTING_NORMAL
	readout_font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
	pilot_readout.add_theme_font_override("font",readout_font)
	pilot_readout.add_theme_font_size_override("font_size",12)
	pilot_readout.add_theme_color_override("font_color",GREEN)
	canvas.add_child(pilot_readout)
	dialog=PanelContainer.new()
	dialog.position=Vector2(236,290)
	dialog.size=Vector2(360,290)
	dialog.theme=MacDialog.make()
	MacDialog.frame(dialog)
	canvas.add_child(dialog)
	screen=VBoxContainer.new()
	screen.add_theme_constant_override("separation",12)
	dialog.add_child(screen)
	var logo=Control.new();logo.position=Vector2(140,55);logo.size=Vector2(550,220)
	logo.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and event.alt_pressed: original_credits(true))
	canvas.add_child(logo)
	pilot_info()
	fade_cover=ColorRect.new();fade_cover.name="OpeningFade";fade_cover.color=Color.BLACK
	fade_cover.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fade_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(fade_cover)
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
	if dialog.visible:
		dialog.size=Vector2(520,dialog.get_combined_minimum_size().y)
		dialog.position=(canvas.size-dialog.size)*.5
	update_presentation()

func animation_sample(at: float) -> Dictionary:
	var phase: float=clampf(at*FRAME_RATE,0,16)
	var first: int=int(floor(phase))
	return {"first":first,"next":mini(first+1,16),"blend":phase-first,
		"motion":clampf(at/PANEL_STOP_SECONDS,0,1),
		"faces":1.0 if Lettering.phase(at)>=0 else 0.0,
		"ink_phase":Lettering.phase(at)}

func panel_rect(row: int,side: int) -> Rect2:
	return Rect2(LEFT_ORIGINS[row] if side==0 else RIGHT_ORIGINS[row],Vector2(240,59))

func face_rect(row: int,side: int) -> Rect2:
	var top: float=[474.0,587.0,701.0][row]
	var bottom: float=[568.0,682.0,798.0][row]
	var start=PanelMotion.design(Vector2(478 if side==0 else 973,top))
	var finish=PanelMotion.design(Vector2(699 if side==0 else 1199,bottom))
	return Rect2(start,finish-start)

func update_presentation() -> void:
	fade_cover.color.a=1.0-clampf(animation_time/FADE_SECONDS,0,1)
	var sample: Dictionary=animation_sample(animation_time)
	for button in canvas.get_children():
		if button is Button: button.modulate.a=1.0
		elif button is Lettering:
			button.at=animation_time
			if button.side==1 and button.row==0:
				button.material.set_shader_parameter("brightness",.35 if canvas.get_node("EnterShip").disabled else 1.0)
			button.queue_redraw()
	canvas.get_node("OriginalAnimation").queue_redraw()

func draw_animation(surface: Control) -> void:
	PanelMotion.draw(surface,bridge.atlas,animation_time)

func fit() -> void:
	if not is_instance_valid(canvas): return
	var ratio=minf(size.x/832.0,size.y/624.0)
	canvas.scale=Vector2.ONE*ratio
	canvas.position=(size-canvas.size*ratio)/2
	backdrop.size=size;backdrop.queue_redraw()

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
	b.modulate.a=1
	b.tooltip_text=caption
	b.text=""
	b.alignment=HORIZONTAL_ALIGNMENT_RIGHT if pos.x<400 else HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size",19)
	b.add_theme_color_override("font_color",Color("a0ff63"))
	b.add_theme_color_override("font_disabled_color",Color("345c2a"))
	b.position=pos;b.size=Vector2(125,59)
	var clear=StyleBoxEmpty.new()
	clear.content_margin_left=12;clear.content_margin_right=12
	b.add_theme_stylebox_override("normal",clear)
	b.add_theme_stylebox_override("disabled",clear)
	b.add_theme_stylebox_override("hover",style(Color(0.4,1,0.2,0.12),GREEN,12))
	b.add_theme_stylebox_override("pressed",style(Color(0,0,0,0.45),GREEN,12))
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
	dialog.size=Vector2(520,340);dialog.position=(canvas.size-dialog.size)*.5
	dialog.show()
	for child in screen.get_children():
		screen.remove_child(child);child.queue_free()

func line(value: String, font_size: int=16) -> Label:
	var l=Label.new();l.text=value
	l.add_theme_color_override("font_color",Color.BLACK)
	l.add_theme_font_size_override("font_size",font_size)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	screen.add_child(l)
	return l

func small_button(value: String, action: Callable) -> void:
	var b=Button.new();b.text=value;b.custom_minimum_size=Vector2(180,32);b.size_flags_horizontal=Control.SIZE_SHRINK_END;b.pressed.connect(func():game.sound("menu_click");action.call());screen.add_child(b)
	if value in ["Begin new flight","Done","Open Pilot"]:
		b.draw.connect(func():b.draw_style_box(MacDialog.box(Color.TRANSPARENT,Color.BLACK,3,0,7),Rect2(Vector2(-4,-4),b.size+Vector2(8,8))))
		b.resized.connect(b.queue_redraw)

func pilot_info() -> void:
	clear_screen()
	dialog.position=Vector2(236,290);dialog.size=Vector2(360,290)
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
	var primary=screen.get_child(screen.get_child_count()-2)
	var cancel=screen.get_child(screen.get_child_count()-1)
	screen.remove_child(primary);screen.remove_child(cancel)
	var actions=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation",16);screen.add_child(actions)
	actions.add_child(cancel);actions.add_child(primary)

func saved_pilots() -> Array:
	var result: Array=[]
	var directory: String=ProjectSettings.globalize_path(game.save_path).get_base_dir()
	for filename in DirAccess.get_files_at(directory):
		if filename.get_extension().to_lower()!="json": continue
		var path: String=directory.path_join(filename)
		var saved=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not saved is Dictionary: continue
		var candidate: Dictionary=saved.duplicate(true)
		candidate.strict_dead=false
		var pilot=preload("res://scripts/pilot.gd").new()
		if not pilot.restore(candidate,game.catalog): continue
		result.append({"path":path,"name":pilot.pilot_name,"ship":game.catalog.record("ships",pilot.ship_id).name,"system":game.catalog.system(pilot.system_id).name,"strict":pilot.strict,"dead":saved.get("strict_dead",false)})
	result.sort_custom(func(a,b):return a.name.naturalnocasecmp_to(b.name)<0 if a.name!=b.name else a.path<b.path)
	return result

func open_pilot() -> void:
	clear_screen()
	line("OPEN PILOT",20)
	line("Choose a pilot to continue their journey.")
	pilot_picker=ItemList.new();pilot_picker.name="PilotList"
	pilot_picker.custom_minimum_size=Vector2(460,190)
	pilot_picker.add_theme_constant_override("v_separation",10)
	pilot_picker.auto_height=false;pilot_picker.allow_reselect=true
	screen.add_child(pilot_picker)
	var entries: Array=saved_pilots()
	var current: int=0
	for entry in entries:
		var index: int=pilot_picker.add_item(entry.name+" · "+entry.ship+" · "+entry.system+" ("+("Deceased" if entry.dead else "Strict" if entry.strict else "Normal")+")")
		pilot_picker.set_item_metadata(index,entry.path)
		if ProjectSettings.globalize_path(entry.path)==ProjectSettings.globalize_path(game.save_path): current=index
	if entries.is_empty():
		pilot_picker.hide();line("No saved pilots yet. Choose New Pilot to begin.")
	else: pilot_picker.select(current)
	small_button("Open Pilot",open_selected_pilot)
	var open: Button=screen.get_child(screen.get_child_count()-1);open.name="ConfirmOpenPilot";open.disabled=entries.is_empty()
	small_button("Cancel",pilot_info)
	var cancel=screen.get_child(screen.get_child_count()-1)
	screen.remove_child(open);screen.remove_child(cancel)
	var actions=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_END;actions.add_theme_constant_override("separation",16);screen.add_child(actions)
	actions.add_child(cancel);actions.add_child(open)
	pilot_picker.item_activated.connect(func(_index):open_selected_pilot())
	if not entries.is_empty():
		pilot_picker.grab_focus()
		var pad=game.controls.controller
		pad.selected=pilot_picker;pad.reveal.call_deferred(pilot_picker)

func open_selected_pilot() -> void:
	if not is_instance_valid(pilot_picker) or pilot_picker.get_selected_items().is_empty(): return
	open_pilot_path(str(pilot_picker.get_item_metadata(pilot_picker.get_selected_items()[0])))

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
	small_button("Keyboard & controller",game.open_controls)
	small_button("Done",pilot_info)

func about() -> void:
	about_with_modifiers(Input.is_physical_key_pressed(KEY_ALT),Input.is_physical_key_pressed(KEY_META))

func about_with_modifiers(option: bool,command: bool) -> void:
	if option: original_credits(true);return
	if command: original_credits(false,true);return
	clear_screen();dialog.position=Vector2(236,120);dialog.size=Vector2(360,440);line("ABOUT EV",20)
	line("Escape Velocity\nCreated by Matt Burch\nAmbrosia Software, 1996")
	line("Escape Velocity HD\nA modern recreation in Godot.")
	small_button("Replay opening sequence",game.replay_opening_sequence)
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

func original_credits(parody: bool=false, additional: bool=false) -> void:
	close_extras()
	parody_credits=parody
	extras_panel=PanelContainer.new()
	extras_panel.position=Vector2(100,50);extras_panel.size=Vector2(632,524)
	extras_panel.theme=MacDialog.make();MacDialog.frame(extras_panel)
	canvas.add_child(extras_panel)
	var column=VBoxContainer.new();extras_panel.add_child(column)
	credits_scroll=ScrollContainer.new();credits_scroll.custom_minimum_size=Vector2(580,450)
	column.add_child(credits_scroll)
	credits_label=Label.new();credits_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	credits_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	credits_label.add_theme_font_size_override("font_size",18)
	credits_label.add_theme_color_override("font_color",Color.BLACK)
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/original_extras.json"))
	credits_label.text="\n".join(data["20002" if parody else "20003" if additional else "20001"].strings)
	credits_scroll.add_child(credits_label)
	credits_position=0
	var done=Button.new();done.text="Done";done.pressed.connect(func():game.sound("menu_click");close_extras());column.add_child(done)

func close_extras() -> void:
	if is_instance_valid(extras_panel): extras_panel.queue_free()
	extras_panel=null;credits_scroll=null;credits_label=null;parody_credits=false

func haikus() -> void:
	close_extras()
	extras_panel=PanelContainer.new();extras_panel.position=Vector2(196,90)
	extras_panel.theme=MacDialog.make();MacDialog.frame(extras_panel)
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
	if event.keycode==KEY_ESCAPE and dialog.visible and not is_instance_valid(extras_panel): pilot_info();get_viewport().set_input_as_handled();return
	if event.keycode==KEY_ESCAPE and is_instance_valid(extras_panel): close_extras();get_viewport().set_input_as_handled();return
	if (dialog.visible and not is_instance_valid(extras_panel)) or (is_instance_valid(pilot_picker) and pilot_picker.visible): return
	if event.keycode==KEY_X and not is_instance_valid(extras_panel): haikus();get_viewport().set_input_as_handled();return
	if Input.is_physical_key_pressed(KEY_S) and Input.is_physical_key_pressed(KEY_O) and Input.is_physical_key_pressed(KEY_L):
		game.pilot.secrets.satellite=true;game.save_game(false);clear_screen();line("A familiar satellite may appear at a shipyard…");get_viewport().set_input_as_handled();return
	if not parody_credits or not is_instance_valid(credits_label): return
	if event.keycode==KEY_F and event.ctrl_pressed and event.meta_pressed and event.alt_pressed:
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
		get_viewport().set_input_as_handled();game.sound("menu_click")
		if key==KEY_A: about_with_modifiers(event.alt_pressed,event.meta_pressed)
		else: actions[key].call()
