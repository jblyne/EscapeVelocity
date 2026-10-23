extends Control

# Reconstructed from the original six-button bridge console. All artwork is
# fitted to the window from a fixed design canvas; raster art stays registered.
const MacDialog=preload("res://scripts/mac_dialog_theme.gd")
const Lettering=preload("res://scripts/menu_lettering.gd")
const MenuGlobe=preload("res://scripts/menu_globe.gd")
const PanelMotion=preload("res://scripts/menu_panel_motion.gd")
const FADE_SECONDS: float=16.0/60.0
const PANEL_STOP_SECONDS: float=12.0/PanelMotion.FRAME_RATE
const GREEN=Color("80ed73")
const FRAME_RATE: float=PanelMotion.FRAME_RATE
const OPENING_DURATION: float=17.0/FRAME_RATE
const MOTION_DURATION: float=2.0*PanelMotion.ROW_SECONDS+PANEL_STOP_SECONDS
# Registered against PICT 8000's actual asymmetrical button/rail locations.
const LEFT_ORIGINS=[Vector2(96,316),Vector2(96,387),Vector2(96,455)]
const RIGHT_ORIGINS=[Vector2(499,313),Vector2(499,384),Vector2(499,452)]
var fade_cover: ColorRect
var bridge: Texture2D
var backdrop: Control
var motion_finished: bool=false
var completed_rows: int=0
var game
var canvas: Control
var screen: VBoxContainer

var presentation_started: bool=false
var discard_setup_delta: bool=false
var animation_time: float = 0.0
var dialog: PanelContainer
var pilot_readout: RichTextLabel
const DEFAULT_NAMES=preload("res://data/original_default_names.json")
var naming_stage: String=""
var pending_pilot_name: String=""
var pending_strict: bool=false
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
			var globe=MenuGlobe.new()
			globe.name="Globe%d%d" % [i,side];globe.row=i;globe.side=side
			globe.position=MenuGlobe.bounds(i,side).position;globe.size=MenuGlobe.bounds(i,side).size
			canvas.add_child(globe)
	pilot_readout=RichTextLabel.new()
	pilot_readout.bbcode_enabled=true;pilot_readout.scroll_active=false;pilot_readout.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pilot_readout.position=Vector2(365,350)
	pilot_readout.size=Vector2(104,150)
	pilot_readout.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	# EV 1.0.5 readout: TextFont(3 / Geneva), TextSize(9), at 0x4d024.
	# The HD design canvas scales the original 640 x 480 coordinates by 1.3.
	var readout_font=SystemFont.new()
	readout_font.font_names=PackedStringArray(["Geneva"])
	readout_font.hinting=TextServer.HINTING_NORMAL
	readout_font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
	pilot_readout.add_theme_font_override("normal_font",readout_font)
	pilot_readout.add_theme_font_size_override("normal_font_size",12)
	pilot_readout.add_theme_color_override("default_color",Color("00b800"))
	canvas.add_child(pilot_readout)
	dialog=PanelContainer.new()
	dialog.position=Vector2(236,290)
	dialog.size=Vector2(360,290)
	dialog.theme=MacDialog.make()
	MacDialog.frame(dialog,game)
	canvas.add_child(dialog)
	screen=VBoxContainer.new()
	screen.add_theme_constant_override("separation",12)
	dialog.add_child(screen)
	var logo=Control.new();logo.name="LogoCreditsHotspot";logo.position=Vector2(140,55);logo.size=Vector2(550,220)
	logo.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and event.alt_pressed: original_credits(true))
	canvas.add_child(logo);canvas.move_child(logo,dialog.get_index())
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
	while completed_rows<3 and animation_time>=completed_rows*PanelMotion.ROW_SECONDS+PANEL_STOP_SECONDS:
		completed_rows+=1
		if completed_rows==3:
			motion_finished=true;game.finish_title_motion()
		else: game.sound("menu_slam")
	if dialog.visible and naming_stage.is_empty():
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
			button.at=PanelMotion.row_time(animation_time,button.row)
			if button.side==1 and button.row==0:
				button.material.set_shader_parameter("brightness",.35 if canvas.get_node("EnterShip").disabled else 1.0)
			button.queue_redraw()
	for row in 3:
		for side in 2:
			var button: Button=canvas.get_node((["NewPilot","OpenPilot","QuitEV"] if side==0 else ["EnterShip","SetPrefs","AboutEV"])[row])
			var globe=canvas.get_node("Globe%d%d" % [row,side])
			globe.active=not dialog.visible and not button.disabled and PanelMotion.row_time(animation_time,row)>=OPENING_DURATION and (button.is_hovered() or button.has_focus())
			globe.at=animation_time;globe.queue_redraw()
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
	b.tooltip_text=""
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
	b.add_theme_stylebox_override("hover",clear)
	b.add_theme_stylebox_override("focus",clear)
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
	naming_stage=""
	dialog.remove_theme_stylebox_override("panel")
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
	pilot_readout.position=Vector2(366,337);pilot_readout.size=Vector2(108,199)
	pilot_readout.add_theme_font_override("normal_font",preload("res://scripts/classic_text.gd").body())
	pilot_readout.add_theme_font_size_override("normal_font_size",10)
	pilot_readout.add_theme_constant_override("line_separation",-2)
	if not game.pilot_ready:
		pilot_readout.text="No Pilot File Loaded"
	else:
		var system: Dictionary=game.catalog.system(game.pilot.system_id)
		var faction: int=int(system.fields.Govt)
		var legal: String="Offender" if game.Factions.hostile_to_pilot(game.catalog,game.pilot,faction) else "Clean"
		var rating: String="Harmless" if int(game.pilot.campaign.rating)==0 else str(int(game.pilot.campaign.rating))
		var local_date: Dictionary=Time.get_datetime_dict_from_system(false)
		var date: Dictionary=Time.get_date_dict_from_unix_time(Time.get_unix_time_from_datetime_dict(local_date)+int(game.pilot.campaign.day)*86400)
		var months=["Jan.","Feb.","Mar.","Apr.","May","Jun.","Jul.","Aug.","Sep.","Oct.","Nov.","Dec."]
		var day: int=int(date.day)
		var suffix: String="th" if day in [11,12,13] else "st" if day%10==1 else "nd" if day%10==2 else "rd" if day%10==3 else "th"
		var values=[game.pilot.pilot_name.left(18),game.pilot.ship_name.left(18),game.catalog.record("ships",game.pilot.ship_id).name,legal,rating,"%s %d%s, %d" % [months[int(date.month)-1],day,suffix,int(date.year)+250]]
		var headers=["Pilot Name:","Ship Name:","Ship Type:","Legal status in\n%s system:" % system.name,"Combat Rating:","Current Date:"]
		var sections: PackedStringArray=[]
		for i in headers.size():
			sections.append(headers[i]+"\n[color=#00ff00]  "+str(values[i]).replace("[","[lb]") +"[/color]")
		pilot_readout.text="\n[font_size=6]\n[/font_size]".join(sections)


func naming_panel(stage: String,dimensions: Vector2) -> Control:
	clear_screen();naming_stage=stage
	dialog.add_theme_stylebox_override("panel",MacDialog.box(Color.WHITE,Color("4c4c5c"),2,20))
	var layout=Control.new();layout.custom_minimum_size=dimensions;screen.add_child(layout)
	layout.theme=MacDialog.make();layout.theme.default_font=preload("res://assets/fonts/ChicagoFLFRegular.ttf")
	var icon=TextureRect.new();icon.texture=preload("res://assets/icon/original-32.png");icon.position=Vector2(0,0);icon.size=Vector2(42,42);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;layout.add_child(icon)
	dialog.size=dimensions+Vector2(40,40);dialog.position=(canvas.size-dialog.size)*.5
	return layout

func naming_label(layout: Control,id: String,value: String,rect: Rect2,points: int=16) -> Label:
	var label=Label.new();label.name=id;label.text=value;label.position=rect.position;label.size=rect.size;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",points);layout.add_child(label);return label

func naming_entry(layout: Control,id: String,value: String,rect: Rect2) -> LineEdit:
	var entry=LineEdit.new();entry.name=id;entry.text=value;entry.max_length=64;entry.position=rect.position;entry.size=rect.size;entry.add_theme_font_size_override("font_size",16);layout.add_child(entry)
	for state in ["normal","focus"]: entry.add_theme_stylebox_override(state,MacDialog.box(Color.BLACK,Color.BLACK,1,6))
	entry.draw.connect(func():entry.draw_rect(Rect2(Vector2(2,2),entry.size-Vector2(4,4)),Color.WHITE,false,1))
	entry.grab_focus();entry.select_all();return entry

func naming_button(layout: Control,id: String,value: String,rect: Rect2,action: Callable,primary: bool=false) -> Button:
	var button=Button.new();button.name=id;button.text=value;button.position=rect.position;button.size=rect.size;layout.add_child(button)
	for state in ["normal","hover"]: button.add_theme_stylebox_override(state,MacDialog.box(Color.WHITE,Color.BLACK,1,4,5))
	button.pressed.connect(func():game.sound("menu_click");action.call())
	if primary:
		button.draw.connect(func():button.draw_style_box(MacDialog.box(Color.TRANSPARENT,Color.BLACK,3,0,7),Rect2(Vector2(-4,-4),button.size+Vector2(8,8))))
		button.resized.connect(button.queue_redraw)
	return button

func new_pilot() -> void:
	var layout=naming_panel("pilot",Vector2(334,168))
	naming_label(layout,"NewPilotPrompt","Enter your name, pilot:",Rect2(60,0,274,26))
	var name=naming_entry(layout,"PilotName",str(DEFAULT_NAMES.data.pilots.pick_random()),Rect2(66,34,268,28))
	var strict=CheckBox.new();strict.name="StrictPlay";strict.text="Strict Play";strict.position=Vector2(64,78);strict.size=Vector2(270,26);layout.add_child(strict)
	naming_label(layout,"StrictHelp","If you check this box, when you're dead,\nyou're dead. No reincarnation allowed.",Rect2(88,104,246,36),11)
	var proceed=func():
		pending_pilot_name=name.text.strip_edges() if not name.text.strip_edges().is_empty() else str(DEFAULT_NAMES.data.pilots.pick_random())
		pending_strict=strict.button_pressed;name_ship()
	naming_button(layout,"CancelNewPilot","Cancel",Rect2(152,146,76,26),pilot_info)
	naming_button(layout,"ConfirmPilotName","OK",Rect2(250,146,80,26),proceed,true)
	name.text_submitted.connect(func(_text):proceed.call())

func name_ship() -> void:
	var layout=naming_panel("ship",Vector2(434,160))
	naming_label(layout,"NameShipPrompt","Now, please christen your brand-new\nRendelli StarDrive 805R cargo shuttle:",Rect2(60,0,374,46))
	var name=naming_entry(layout,"ShipName",str(DEFAULT_NAMES.data.ships.pick_random()),Rect2(108,74,274,28))
	var proceed=func():
		if not game.create_pilot(pending_pilot_name,pending_strict,name.text,false):
			clear_screen();line("PILOT NOT CREATED",20);line(game.pilot_file_error);small_button("Back",new_pilot);small_button("Cancel",pilot_info);return
		pilot_info();canvas.get_node("EnterShip").disabled=false
	naming_button(layout,"CancelShipName","Cancel",Rect2(260,136,76,26),pilot_info)
	naming_button(layout,"ConfirmShipName","OK",Rect2(358,136,72,26),proceed,true)
	name.text_submitted.connect(func(_text):proceed.call())

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
	var layout=naming_panel("open",Vector2(520,252))
	naming_label(layout,"OpenPilotHeading","Open Pilot",Rect2(60,0,330,24))
	naming_label(layout,"OpenPilotPrompt","Choose a saved pilot.",Rect2(60,26,330,18),11)
	pilot_picker=ItemList.new();pilot_picker.name="PilotList"
	pilot_picker.position=Vector2(0,54);pilot_picker.size=Vector2(380,172)
	pilot_picker.add_theme_constant_override("v_separation",6)
	pilot_picker.auto_height=false;pilot_picker.allow_reselect=true
	# Original Mac selection stays black under both mouse and controller focus.
	for state in ["selected","selected_focus","hovered_selected","hovered_selected_focus"]:
		pilot_picker.add_theme_stylebox_override(state,MacDialog.box(Color.BLACK,Color.BLACK,0,2))
	pilot_picker.add_theme_stylebox_override("hovered",MacDialog.box(Color.WHITE,Color.WHITE,0,2))
	pilot_picker.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	pilot_picker.add_theme_color_override("font_hovered_color",Color.BLACK)
	pilot_picker.add_theme_color_override("font_hovered_selected_color",Color.WHITE)
	layout.add_child(pilot_picker)
	MacDialog.classic_scrollbar(pilot_picker.get_v_scroll_bar())
	var details=naming_label(layout,"PilotDetails","",Rect2(0,234,380,18),11)
	var entries: Array=saved_pilots()
	var current: int=0
	for entry in entries:
		var index: int=pilot_picker.add_item(entry.name)
		pilot_picker.set_item_metadata(index,entry.path)
		pilot_picker.set_item_tooltip_enabled(index,false)
		if ProjectSettings.globalize_path(entry.path)==ProjectSettings.globalize_path(game.save_path): current=index
	var describe=func(index: int):
		var entry: Dictionary=entries[index]
		details.text=entry.ship+" · "+entry.system+" ("+("Deceased" if entry.dead else "Strict" if entry.strict else "Normal")+")"
	pilot_picker.item_selected.connect(describe)
	if entries.is_empty(): details.text="No saved pilots. Choose New Pilot to begin."
	else:
		pilot_picker.select(current);describe.call(current)
	# Same white buttons and heavy default-action border as New Pilot.
	var separator=ColorRect.new();separator.mouse_filter=Control.MOUSE_FILTER_IGNORE;separator.color=Color("999999");separator.position=Vector2(408,134);separator.size=Vector2(110,1);layout.add_child(separator)
	var cancel=naming_button(layout,"CancelOpenPilot","Cancel",Rect2(408,158,110,26),pilot_info)
	var open=naming_button(layout,"ConfirmOpenPilot","Open Pilot",Rect2(408,204,110,28),open_selected_pilot,true)
	open.disabled=entries.is_empty()
	pilot_picker.item_activated.connect(func(_index):open_selected_pilot())
	if not entries.is_empty():
		pilot_picker.grab_focus()
		var pad=game.controls.controller
		pad.selected=pilot_picker;pad.reveal.call_deferred(pilot_picker)
	else:
		cancel.grab_focus();game.controls.controller.selected=cancel

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
	game.open_controls()

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
	extras_panel.theme=MacDialog.make();MacDialog.frame(extras_panel,game)
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
	extras_panel.theme=MacDialog.make();MacDialog.frame(extras_panel,game)
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
	if event.keycode==KEY_ESCAPE and dialog.visible and not is_instance_valid(extras_panel): pilot_info();get_viewport().set_input_as_handled();return
	if event.keycode==KEY_ESCAPE and is_instance_valid(extras_panel): close_extras();get_viewport().set_input_as_handled();return
	if get_viewport().gui_get_focus_owner() is LineEdit: return
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
