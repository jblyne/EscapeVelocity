extends "res://scripts/classic_port.gd"
const LAYOUT=Vector2(960,620)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=SystemFont.new();font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
	canvas=Control.new();canvas.size=LAYOUT;add_child(canvas);panel(Rect2(Vector2.ZERO,LAYOUT))
	label_at("PauseHeading","Flight Paused",Rect2(22,15,500,36),26)
	label_at("OverallProgress","Overall progress: %.1f%%" % (game.achievements.progress().overall*100),Rect2(564,18,372,30),19)
	label_at("ControlsHeading","Flight controls",Rect2(24,61,450,26),20)
	panel(Rect2(20,94,520,458))
	var reference=RichTextLabel.new();reference.name="FlightControls";reference.position=Vector2(32,104);reference.size=Vector2(496,436)
	reference.add_theme_font_override("normal_font",font);reference.add_theme_font_size_override("normal_font_size",17)
	reference.add_theme_color_override("default_color",Color("dddddd"));reference.bbcode_enabled=true;reference.scroll_active=true
	reference.text="[table=2]"
	for action in game.controls.bindings:
		reference.text+="[cell]"+game.controls.caption(action)+"    [/cell][cell]"+str(action).capitalize()+"[/cell]"
	for row in [["1–4 / F1–F4","Select landing target"],["Double-tap "+game.controls.caption("land"),"Auto land"],["Shift+X","Escape pod"],["F5 / F9","Save / load pilot"],["Caps Lock","Toggle 2× time"]]:
		reference.text+="[cell]"+row[0]+"    [/cell][cell]"+row[1]+"[/cell]"
	reference.text+="[/table]";canvas.add_child(reference)
	var actions: Array=[
		["ResumeFlight","Resume Flight",func():game.set_mode("flight")],
		["MainMenu","Main Menu",return_to_main_menu],
		["ShipInformation","Ship & Target Information",func():game.set_mode("info")],
		["MissionJournal","Mission Journal",func():game.set_mode("flight");game.missions.open()],
		["ManageFleet","Manage Fleet",game.toggle_fleet_menu],
		["ToggleCloak","Cloaking Device",func():game.set_mode("flight");game.cloak.toggle()],
		["KeyboardControls","Keyboard & Controller",game.open_controls],
		["Fullscreen","Toggle Fullscreen",func():DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)],
		["ToggleSound","Sound: Off" if game.muted else "Sound: On",func():game.toggle_audio();game.hud.rebuild_modal()]]
	for i in actions.size():
		var action=actions[i]
		var b=button_at(action[0],action[1],Rect2(564,62+i*45,372,35),action[2]);b.add_theme_font_size_override("font_size",19)
	button_at("SavePilot","Save Pilot",Rect2(564,475,178,35),game.save_game).add_theme_font_size_override("font_size",19)
	button_at("LoadPilot","Load Pilot",Rect2(758,475,178,35),game.load_game).add_theme_font_size_override("font_size",19)
	button_at("CheatMenu","Cheat Menu",Rect2(564,526,178,35),game.toggle_cheat_menu).add_theme_font_size_override("font_size",19)
	button_at("QuitGame","Quit",Rect2(758,526,178,35),func():game.save_game(false);get_tree().quit()).add_theme_font_size_override("font_size",19)
	button_at("DebugRefuel","Free Fuel Refill",Rect2(24,569,240,32),game.debug_refuel).add_theme_font_size_override("font_size",17)
	button_at("OpenAchievements","Achievements",Rect2(284,569,256,32),game.open_achievements).add_theme_font_size_override("font_size",17)
	label_at("ResumeHint","Esc resumes flight",Rect2(564,575,372,28),17)
	resized.connect(fit);fit()
func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5

func return_to_main_menu() -> void:
	var error: String=game.preserve_current_pilot()
	if not error.is_empty():
		var hint=canvas.get_node("ResumeHint")
		hint.text="Save failed — still paused.";hint.tooltip_text=error
		return
	game.set_mode("title")
