extends Control
const Mac=preload("res://scripts/mac_dialog_theme.gd")
const LAYOUT=Vector2(1000,750)
const TITLES={"thrust":"Accelerate", "retrograde":"Rev. Course", "right":"Rotate Right", "left":"Rotate Left", "afterburner":"Afterburner", "face_target":"Face Target", "next_destination":"Hyper Select", "jump":"Jump", "fleet":"Manage Fleet", "recall_fighters":"Recall Fighters", "fire":"Fire Primary", "secondary_fire":"Fire Secondary", "previous_weapon":"Previous Weapon", "next_weapon":"Select Weapon", "weapon_safety":"Weap. Safety", "next_target":"Target Select", "land":"Land", "board":"Board", "hail_ship":"Communicate", "hail_world":"Hail World", "info":"Player Info", "journal":"Mission Info", "cloak":"Cloak", "map":"Map", "next_world":"Landing Target"}
var game
var canvas: Control
var content: Control
var pages: Dictionary={}
var tabs: Dictionary={}
var selected_tab: String="keyboard"
var capture_field: Button
var waiting: String=""
var status: Label
var buttons: Dictionary={}
var pad_buttons: Dictionary={}
var original: Dictionary
var original_muted: bool
var original_window_mode: int
var volume_label: Label
var music_toggle: CheckBox
var speed_panel: PanelContainer
var speed_slider: HSlider
var speed_label: Label

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 game.controls.load_settings()
 original={"bindings":game.controls.bindings.duplicate(true),"pad_bindings":game.controls.pad_bindings.duplicate(),"speed":game.controls.speed,"classic_fire":game.controls.classic_fire,"sound_volume":game.controls.sound_volume,"intro_music":game.controls.intro_music}
 original_muted=game.muted;original_window_mode=DisplayServer.window_get_mode()
 if game.controls_return_mode=="title" and not is_instance_valid(game.hud.saved_title_menu):
  var bridge=preload("res://scripts/title_bridge.gd").new();bridge.size=size;bridge.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bridge)
  resized.connect(func():bridge.size=size;bridge.queue_redraw())
 elif game.controls_return_mode!="title":
  var shade=ColorRect.new();shade.color=Color(0,0,0,.75);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 canvas=Control.new();canvas.size=LAYOUT;canvas.theme=Mac.make();canvas.theme.default_font=preload("res://assets/fonts/ChicagoFLFRegular.ttf");add_child(canvas)
 var paper=Panel.new();paper.name="PreferencesPaper";paper.size=LAYOUT;paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 paper.add_theme_stylebox_override("panel",Mac.box(Color.WHITE,Color("4c4c5c"),2,0));canvas.add_child(paper);Mac.frame(paper,game)
 content=Control.new();content.size=LAYOUT;canvas.add_child(content)
 for i in 2:
  var id: String=["keyboard","controller"][i]
  var tab=action_button(content,id.capitalize()+"Tab",id.capitalize(),Rect2(24+i*174,18,164,30),func():select_tab(id))
  tab.toggle_mode=true;tabs[id]=tab
  var page=Control.new();page.name=id.capitalize()+"Settings";page.size=LAYOUT;page.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(page);pages[id]=page
 label(content,"TabHint","L1 / R1 switches tabs",Rect2(682,22,294,22),12)
 build_keyboard();build_controller();build_footer()
 game.controls.pad_binding_changed.connect(controller_changed)
 Input.joy_connection_changed.connect(func(_id,_connected):update_connection())
 resized.connect(fit);fit();select_tab("keyboard")

func fit() -> void:
 var ratio=minf(1.2,minf((size.x-32)/LAYOUT.x,(size.y-32)/LAYOUT.y))
 canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5

func label(parent: Control,id: String,text: String,rect: Rect2,points: int=14) -> Label:
 var value=Label.new();value.name=id;value.text=text;value.position=rect.position;value.size=rect.size;value.mouse_filter=Control.MOUSE_FILTER_IGNORE
 value.add_theme_font_size_override("font_size",points);value.add_theme_color_override("font_color",Color.BLACK);parent.add_child(value);return value

func action_button(parent: Control,id: String,text: String,rect: Rect2,action: Callable,primary: bool=false) -> Button:
 var button=Button.new();button.name=id;button.text=text;button.position=rect.position;button.size=rect.size;button.add_theme_font_size_override("font_size",15);parent.add_child(button)
 for state in ["normal","hover"]:button.add_theme_stylebox_override(state,Mac.box(Color.WHITE,Color.BLACK,1,6,4))
 button.add_theme_stylebox_override("pressed",Mac.box(Color.BLACK,Color.BLACK,1,6,4))
 button.pressed.connect(func():game.sound("menu_click");action.call())
 if primary:
  button.draw.connect(func():button.draw_style_box(Mac.box(Color.TRANSPARENT,Color.BLACK,3,0,7),Rect2(Vector2(-4,-4),button.size+Vector2(8,8))))
 return button

func group(parent: Control,title: String,rect: Rect2) -> Control:
 var box=Control.new();box.position=rect.position;box.size=rect.size;box.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(box)
 box.draw.connect(func():
  var lines=[Vector2(0,12),Vector2(box.size.x,12),box.size,Vector2(0,box.size.y),Vector2(0,12)]
  for i in 4:box.draw_dashed_line(lines[i],lines[i+1],Color.BLACK,1.0,1.5))
 var heading=label(box,"GroupHeading",title,Rect2(12,0,rect.size.x-24,24),15)
 var white=ColorRect.new();white.color=Color.WHITE;white.mouse_filter=Control.MOUSE_FILTER_IGNORE;white.position=Vector2(8,0)
 white.size=Vector2(heading.get_theme_font("font").get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+12,24);box.add_child(white);box.move_child(white,heading.get_index())
 return box

func binding_rows(parent: Control,actions: Array,pad: bool=false) -> void:
 for i in actions.size():
  var action: String=actions[i]
  var title=label(parent,"Caption_"+action,str(TITLES[action])+":",Rect2(12,32+i*34,130,30),13)
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  var button=action_button(parent,("BindController_" if pad else "BindKeyboard_")+action,"",Rect2(146,30+i*34,142,30),func():begin_binding(action,pad))
  button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.add_theme_font_size_override("font_size",14 if pad else 17)
  for state in ["normal","hover"]:button.add_theme_stylebox_override(state,Mac.box(Color.WHITE,Color.BLACK,2,6))
  if pad:pad_buttons[action]=button
  else:buttons[action]=button

func fixed_row(parent: Control,title: String,value: String,index: int) -> void:
 var name_label=label(parent,"FixedCaption"+str(index),title+":",Rect2(12,32+index*34,130,30),13);name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var field=Panel.new();field.position=Vector2(146,30+index*34);field.size=Vector2(142,30);field.mouse_filter=Control.MOUSE_FILTER_IGNORE
 field.add_theme_stylebox_override("panel",Mac.box(Color.WHITE,Color.BLACK,2,0));parent.add_child(field)
 label(field,"FixedValue",value,Rect2(7,1,130,28),16)

func build_keyboard() -> void:
 var page: Control=pages.keyboard
 var nav=group(page,"Navigation Controls:",Rect2(24,66,300,350))
 binding_rows(nav,["thrust","retrograde","right","left","afterburner","face_target","next_destination","jump"])
 fixed_row(nav,"Autopilot","A",8)
 var escorts=group(page,"Escort Controls:",Rect2(350,66,300,112));binding_rows(escorts,["fleet","recall_fighters"])
 var weapons=group(page,"Weapon Controls:",Rect2(350,202,300,248));binding_rows(weapons,["fire","secondary_fire","next_weapon","previous_weapon","weapon_safety","next_target"])
 var misc=group(page,"Misc. Controls:",Rect2(676,66,300,488));binding_rows(misc,["hail_ship","land","board","map","info","journal","cloak","hail_world"])
 var fixed_shortcuts=[["Pause","Escape"],["Acknowledge","Return"],["Jettison","⌘ K"],["Eject","Shift X"],["Destruct","⌘ D"]]
 for i in fixed_shortcuts.size():fixed_row(misc,fixed_shortcuts[i][0],fixed_shortcuts[i][1],8+i)
 action_button(page,"RemakeDefaults","Remake Defaults",Rect2(24,448,142,28),func():game.controls.preset(false);refresh())
 action_button(page,"ClassicDefaults","Classic Defaults",Rect2(182,448,142,28),func():game.controls.preset(true);refresh())
 label(page,"KeyboardHelp","Select a key field, then press its replacement.\nFixed shortcuts are shown for reference.",Rect2(24,492,620,42),12)

func build_controller() -> void:
 var page: Control=pages.controller
 var nav=group(page,"Navigation Controls:",Rect2(24,66,300,248));binding_rows(nav,["afterburner","face_target","jump","next_world","map"],true)
 var weapons=group(page,"Weapon Controls:",Rect2(350,66,300,248));binding_rows(weapons,["fire","secondary_fire","next_weapon","previous_weapon","next_target"],true)
 var misc=group(page,"Misc. Controls:",Rect2(676,66,300,248));binding_rows(misc,["land","board","hail_ship","cloak","fleet","journal"],true)
 var help_box=group(page,"Controller Notes:",Rect2(24,340,952,176))
 var help=label(help_box,"ControllerHelp","",Rect2(14,30,924,132),13);help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 update_connection()
 action_button(page,"ControllerDefaults","Restore Controller Defaults",Rect2(24,538,290,28),func():game.controls.reset_pad();refresh())

func update_connection() -> void:
 var help=pages.controller.find_child("ControllerHelp",true,false)
 if not is_instance_valid(help):return
 var devices=Input.get_connected_joypads()
 var connection: String="Connected: "+", ".join(devices.map(func(id):return Input.get_joy_name(id))) if not devices.is_empty() else "Connect a controller using Bluetooth or USB."
 help.text=connection+"\nLeft stick steers and accelerates; right stick pans the map and scrolls menus.\nHold the landing button and flick the left stick to cycle planets and stations.\nMenus: D-pad selects, Cross / A confirms, Circle / B returns. Options pauses.\nSelect a field above, then press a controller button or trigger to reassign it."

func build_footer() -> void:
 label(content,"VolumeHeading","Sound Volume:",Rect2(32,580,200,24),17)
 action_button(content,"VolumeDown","−",Rect2(32,612,28,24),func():set_volume(game.controls.sound_volume-.25))
 action_button(content,"VolumeUp","+",Rect2(66,612,28,24),func():set_volume(game.controls.sound_volume+.25))
 volume_label=label(content,"VolumeValue","",Rect2(108,612,170,24),16)
 music_toggle=CheckBox.new();music_toggle.name="IntroMusicToggle";music_toggle.text="Intro Music";music_toggle.position=Vector2(350,580);music_toggle.size=Vector2(280,28);music_toggle.button_pressed=game.controls.intro_music;content.add_child(music_toggle)
 music_toggle.toggled.connect(func(value):game.controls.intro_music=value;game.sync_title_music();game.controls.save_settings())
 var firing=CheckBox.new();firing.name="ClassicFiringToggle";firing.text="Classic firing";firing.position=Vector2(350,614);firing.size=Vector2(280,28);firing.button_pressed=game.controls.classic_fire;content.add_child(firing)
 firing.toggled.connect(func(value):game.controls.classic_fire=value;game.controls.save_settings())
 var sound=CheckBox.new();sound.name="SoundEnabledToggle";sound.text="Sound";sound.position=Vector2(24,648);sound.size=Vector2(130,28);sound.button_pressed=not game.muted;content.add_child(sound)
 sound.toggled.connect(func(_value):game.toggle_audio())
 var full=CheckBox.new();full.name="FullscreenToggle";full.text="Fullscreen";full.position=Vector2(180,648);full.size=Vector2(180,28);full.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;content.add_child(full)
 full.toggled.connect(func(value):DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED))
 status=label(content,"BindingStatus","Select a field to change its binding.",Rect2(350,650,626,30),12);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 action_button(content,"GameSpeed","Game Speed…",Rect2(350,696,220,30),show_speed)
 action_button(content,"CancelPreferences","Cancel",Rect2(752,696,100,30),func():close(false))
 action_button(content,"ConfirmPreferences","OK",Rect2(874,696,100,30),func():close(true),true)
 refresh()

func set_volume(value: float) -> void:
 game.controls.sound_volume=clampf(value,0,1);game.controls.apply_audio();game.controls.save_settings();refresh_volume();game.sound("menu_click")
func refresh_volume() -> void:
 volume_label.text="Off" if game.controls.sound_volume==0 else "%d%%" % roundi(game.controls.sound_volume*100)

func select_tab(id: String) -> void:
 waiting="";game.controls.capture_action="";selected_tab=id
 for key in pages:pages[key].visible=key==id;tabs[key].set_pressed_no_signal(key==id)
 refresh()
 if game.controls.controller.using_pad:
  game.controls.controller.selected=tabs[id];tabs[id].grab_focus()

func begin_binding(action: String,pad: bool) -> void:
 waiting="";game.controls.capture_action=""
 if pad:
  game.controls.capture_action=action;status.text="Press a controller button or trigger. Options / Escape cancels."
 else:
  waiting=action;status.text="Press a key for "+str(TITLES[action])+". Escape cancels."
 var field: Button=pad_buttons[action] if pad else buttons[action]
 capture_field=field
 field.add_theme_stylebox_override("normal",Mac.box(Color.BLACK,Color.BLACK,2,6));field.add_theme_stylebox_override("hover",Mac.box(Color.BLACK,Color.BLACK,2,6))
 field.add_theme_color_override("font_color",Color.WHITE);field.add_theme_color_override("font_hover_color",Color.WHITE);field.add_theme_color_override("font_focus_color",Color.WHITE)
 field.text="Press button…" if pad else "Press key…"

func controller_changed(error: String) -> void:
 if error.is_empty():
  refresh()
  if game.controls.controller.using_pad and is_instance_valid(capture_field):
   game.controls.controller.selected=capture_field;capture_field.grab_focus()
 else:status.text=error
func refresh() -> void:
 waiting=""
 for fields in [buttons,pad_buttons]:
  for action in fields:
   var field: Button=fields[action];field.text=game.controls.pad_caption(action) if fields==pad_buttons else game.controls.caption(action)
   field.remove_theme_color_override("font_color");field.remove_theme_color_override("font_hover_color");field.remove_theme_color_override("font_focus_color")
   for state in ["normal","hover"]:field.add_theme_stylebox_override(state,Mac.box(Color.WHITE,Color.BLACK,2,6))
 if is_instance_valid(volume_label):refresh_volume()
 var firing=content.get_node_or_null("ClassicFiringToggle")
 if firing!=null:firing.set_pressed_no_signal(game.controls.classic_fire)
 if is_instance_valid(status):status.text="Select a field to change its binding."

func show_speed() -> void:
 waiting="";game.controls.capture_action="";content.hide()
 speed_panel=PanelContainer.new();speed_panel.name="GameSpeedDialog";speed_panel.position=Vector2(290,270);speed_panel.size=Vector2(420,190);speed_panel.add_theme_stylebox_override("panel",Mac.box(Color.WHITE,Color("4c4c5c"),2,20));canvas.add_child(speed_panel);Mac.frame(speed_panel,game)
 var box=Control.new();box.custom_minimum_size=Vector2(380,150);speed_panel.add_child(box)
 label(box,"SpeedHeading","Game Speed",Rect2(0,0,230,26),17)
 speed_label=label(box,"SpeedValue","",Rect2(280,0,100,26),17)
 speed_slider=HSlider.new();speed_slider.name="SimulationSpeed";speed_slider.position=Vector2(50,56);speed_slider.size=Vector2(280,26);speed_slider.min_value=.5;speed_slider.max_value=2;speed_slider.step=.1;speed_slider.value=game.controls.speed;box.add_child(speed_slider)
 speed_slider.value_changed.connect(func(value):game.controls.speed=value;game.controls.save_settings();speed_label.text="%.1f×" % value)
 var minus=action_button(box,"Slower","−",Rect2(0,52,34,30),func():speed_slider.value-=.1)
 action_button(box,"Faster","+",Rect2(346,52,34,30),func():speed_slider.value+=.1)
 action_button(box,"NormalSpeed","Normal",Rect2(0,112,110,28),func():speed_slider.value=1.0)
 action_button(box,"DoneGameSpeed","Done",Rect2(270,112,110,28),hide_speed,true)
 speed_label.text="%.1f×" % game.controls.speed
 if game.controls.controller.using_pad:game.controls.controller.selected=minus;minus.grab_focus()
func hide_speed() -> void:
 if is_instance_valid(speed_panel):speed_panel.queue_free()
 speed_panel=null;content.show()
 if game.controls.controller.using_pad:game.controls.controller.selected=content.get_node("GameSpeed");content.get_node("GameSpeed").grab_focus()

func close(apply: bool) -> void:
 waiting="";game.controls.capture_action=""
 if not apply:
  for key in original:game.controls.set(key,original[key])
  if game.muted!=original_muted:game.toggle_audio()
  if DisplayServer.window_get_mode()!=original_window_mode:DisplayServer.window_set_mode(original_window_mode)
 game.controls.apply_audio();game.sync_title_music();game.controls.save_settings();game.controls.controller.reset()
 game.set_mode(game.controls_return_mode)
func _exit_tree() -> void:
 game.controls.capture_action=""
func _input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 var key: int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
 if not game.controls.capture_action.is_empty():
  get_viewport().set_input_as_handled()
  if key==KEY_ESCAPE:game.controls.capture_action="";refresh()
  return
 if not waiting.is_empty():
  get_viewport().set_input_as_handled()
  if key==KEY_ESCAPE:refresh();return
  var error: String=game.controls.bind(waiting,key)
  if error.is_empty():refresh()
  else:status.text=error
  return
 if key==KEY_ESCAPE:
  get_viewport().set_input_as_handled()
  if is_instance_valid(speed_panel):hide_speed()
  else:close(false)
