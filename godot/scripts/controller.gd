extends Control
# SDL/Godot standard gamepad mapping; PlayStation names are shown in the help.
const DEADZONE=.22
const BUTTON_ACTIONS={JOY_BUTTON_A:"land",JOY_BUTTON_X:"board",JOY_BUTTON_Y:"next_target",JOY_BUTTON_B:"cloak",JOY_BUTTON_LEFT_SHOULDER:"previous_weapon",JOY_BUTTON_RIGHT_SHOULDER:"next_weapon",JOY_BUTTON_DPAD_UP:"jump",JOY_BUTTON_DPAD_RIGHT:"map",JOY_BUTTON_DPAD_LEFT:"hail_ship",JOY_BUTTON_BACK:"fleet",JOY_BUTTON_TOUCHPAD:"journal"}
const HELP="CONTROLLER (PS5 / standard gamepad)\nLeft stick: turn; up thrusts; down faces against drift (thrust to brake).\nR2: fire selected weapon · L2: secondary fire · L3: afterburner · R3: face target\nCross: tap to land / launch; double-tap to auto-land.\nHold Cross + flick left stick left/right: cycle landing targets; release without landing.\nSquare: board (double-tap to auto-board)\nTriangle: next target · Circle: cloak · L1 / R1: previous / next weapon\nD-pad up: jump / cancel · right: map · left: hail ship · down: select next world\nCreate: fleet · Touchpad: mission journal · Options: pause / back\nHold R3 + D-pad: up next destination, right autopilot, left hail world, down info.\nHold R3 + Circle: arm / safe secondary weapons.\nMENUS: stick moves pointer; Cross clicks; Circle / Options goes back.\nD-pad moves in the pressed direction; hold to repeat and scroll into view.\nRight stick up/down scrolls the focused or pointed list.\nMap: left stick points; right stick pans; Cross selects; Square adds route.\nL1 / R1 zoom; Triangle cycles destination; Circle returns to flight.\nPilot names can be entered with the keyboard."
var game
var device: int=-1
var buttons: Dictionary={}
var axes: Dictionary={}
var cursor=Vector2.ZERO
var using_pad=false
var last_mode=""
var land_pending=false
var land_cycled=false
var land_flick_ready=true
const DPAD_DELAY=.35
const DPAD_INTERVAL=.10
const DPAD_BUTTONS=[JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]
var repeat_button: int=-1
var repeat_remaining: float=0
var focus_history: Array=[]
var selected: Control
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);z_index=4090
 Input.joy_connection_changed.connect(connection_changed)
func reset():
 repeat_button=-1;repeat_remaining=0
 buttons.clear();axes.clear();selected=null;land_pending=false;land_cycled=false;land_flick_ready=true;queue_redraw()
func connection_changed(id: int,connected: bool):
 if not connected and device==id:
  device=-1;using_pad=false;reset()
 elif connected and is_instance_valid(game.hud): game.notify("Controller connected: "+Input.get_joy_name(id))
func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  reset();using_pad=false
func analog(axis: int) -> float:
 var value: float=float(axes.get(axis,0))
 return signf(value)*maxf(0,(absf(value)-DEADZONE)/(1-DEADZONE))
func pressed(action: String) -> bool:
 if game.mode!="flight" or last_mode!=game.mode: return false
 if land_pending and action in ["thrust","retrograde","left","right"]: return false
 match action:
  "thrust": return analog(JOY_AXIS_LEFT_Y)<0
  "retrograde": return analog(JOY_AXIS_LEFT_Y)>0
  "left": return analog(JOY_AXIS_LEFT_X)<0
  "right": return analog(JOY_AXIS_LEFT_X)>0
  "fire": return float(axes.get(JOY_AXIS_TRIGGER_RIGHT,0))>.25
  "secondary_fire": return float(axes.get(JOY_AXIS_TRIGGER_LEFT,0))>.25
  "afterburner": return buttons.get(JOY_BUTTON_LEFT_STICK,false)
  "face_target": return buttons.get(JOY_BUTTON_RIGHT_STICK,false)
 return false
func send_key(key: int):
 var event=InputEventKey.new();event.keycode=key;event.physical_keycode=key;event.pressed=true
 # Use the configured key so controller shortcuts survive keyboard rebinding.
 Input.parse_input_event(event)
 event=event.duplicate();event.pressed=false;Input.parse_input_event(event)
func action_key(action: String): send_key(int(game.controls.bindings[action][0]))
func _input(event):
 if event is InputEventMouseMotion and event.relative.length()>0:
  using_pad=false;repeat_button=-1;queue_redraw();return
 if not event is InputEventJoypadButton and not event is InputEventJoypadMotion: return
 if not game.controls.capture_action.is_empty():
  if event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START:
   game.controls.capture_action="";game.controls.pad_binding_changed.emit("")
  elif (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and event.axis_value>.6):
   var token: String=("b"+str(event.button_index)) if event is InputEventJoypadButton else "a"+str(event.axis)
   var error: String=game.controls.bind_pad(game.controls.capture_action,token)
   if error.is_empty(): game.controls.capture_action=""
   game.controls.pad_binding_changed.emit(error)
  get_viewport().set_input_as_handled();return
 if game.mode=="intro": return # The story/startup owns its own skip action.
 if game.mode=="flight" and not (event is InputEventJoypadButton and event.button_index==JOY_BUTTON_START):
  var token: String=""
  if event is InputEventJoypadButton: token="b"+str(event.button_index)
  elif event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]: token="a"+str(event.axis)
  if not token.is_empty():
   var action=game.controls.pad_bindings.find_key(token)
   if action==null: get_viewport().set_input_as_handled();return
   var target: String=game.controls.PAD_DEFAULTS[action]
   var strength: float=float(event.pressed) if event is InputEventJoypadButton else event.axis_value
   if target.begins_with("b"):
    var mapped=InputEventJoypadButton.new();mapped.device=event.device;mapped.button_index=int(target.substr(1));mapped.pressed=strength>.25
    if event is InputEventJoypadMotion and mapped.pressed==bool(buttons.get(mapped.button_index,false)): get_viewport().set_input_as_handled();return
    event=mapped
   else:
    var mapped=InputEventJoypadMotion.new();mapped.device=event.device;mapped.axis=int(target.substr(1));mapped.axis_value=strength;event=mapped

 if device>=0 and device!=event.device and Input.get_connected_joypads().has(device): return
 if last_mode!=game.mode: reset();last_mode=game.mode
 device=event.device;using_pad=true
 if cursor==Vector2.ZERO: cursor=get_viewport_rect().size*.5
 if event is InputEventJoypadMotion:
  axes[event.axis]=event.axis_value
  if game.mode=="flight" and land_pending and event.axis==JOY_AXIS_LEFT_X:
   if absf(event.axis_value)<.25: land_flick_ready=true
   elif absf(event.axis_value)>.65 and land_flick_ready:
    cycle_landing_target(1 if event.axis_value>0 else -1)
    land_cycled=true;land_flick_ready=false;game.last_land_tap=-1000

 else:
  buttons[event.button_index]=event.pressed
  if event.button_index in DPAD_BUTTONS:
   if event.pressed and game.mode not in ["flight","intro"]:
    repeat_button=event.button_index;repeat_remaining=DPAD_DELAY
   elif not event.pressed and repeat_button==event.button_index: repeat_button=-1
  if event.button_index==JOY_BUTTON_A and game.mode=="flight":
   if event.pressed:
    land_pending=true;land_cycled=false;land_flick_ready=absf(float(axes.get(JOY_AXIS_LEFT_X,0)))<.25
   else:
    var should_land: bool=land_pending and not land_cycled
    land_pending=false
    if should_land: action_key("land")
   get_viewport().set_input_as_handled();return
  if event.pressed:
   if event.button_index==JOY_BUTTON_START: send_key(KEY_ESCAPE)
   elif game.mode=="flight":
    if buttons.get(JOY_BUTTON_RIGHT_STICK,false):
     var extra: Dictionary={JOY_BUTTON_DPAD_UP:"next_destination",JOY_BUTTON_DPAD_LEFT:"hail_world",JOY_BUTTON_DPAD_DOWN:"info",JOY_BUTTON_B:"weapon_safety"}
     if event.button_index==JOY_BUTTON_DPAD_RIGHT: send_key(KEY_A);get_viewport().set_input_as_handled();return
     if extra.has(event.button_index): action_key(extra[event.button_index]);get_viewport().set_input_as_handled();return
    if event.button_index==JOY_BUTTON_DPAD_DOWN:
     cycle_landing_target(1)
    elif BUTTON_ACTIONS.has(event.button_index): action_key(BUTTON_ACTIONS[event.button_index])
   else: menu_button(event.button_index)
 get_viewport().set_input_as_handled();queue_redraw()
func cycle_landing_target(direction: int):
 if game.planets.is_empty(): return
 var index: int=-1
 for i in game.planets.size():
  if int(game.planets[i].id)==game.landing_target: index=i;break
 game.select_landing_target(posmod(index+direction,game.planets.size()) if index>=0 else 0)
func menu_scope() -> Node:
 var scope: Node=game.hud.modal_root if is_instance_valid(game.hud.modal_root) else game
 if game.mode=="title":
  for child in scope.get_children():
   if child.get_script()==preload("res://scripts/title_menu.gd"):
    if is_instance_valid(child.extras_panel): return child.extras_panel
    if child.dialog.visible: return child.dialog
 return scope
func collect_buttons(node: Node,result: Array):
 if node is Control and not node.is_visible_in_tree(): return
 if node is BaseButton and not node.disabled and node.size.x>0: result.append(node)
 elif node is ItemList and node.item_count>0: result.append(node)
 elif node is RichTextLabel and node.scroll_active and node.get_v_scroll_bar().max_value>node.get_v_scroll_bar().page: result.append(node)
 for child in node.get_children(): collect_buttons(child,result)
func map_chart():
 if game.mode!="map": return null
 for child in game.hud.modal_root.get_children():
  if child.get_script()==preload("res://scripts/map_screen.gd"): return child.chart
 return null
func pick_map_system(chart) -> bool:
 chart.rebuild_locations()
 var local: Vector2=chart.get_global_transform().affine_inverse()*cursor
 if not Rect2(Vector2.ZERO,chart.size).has_point(local): return false
 var target: int=-1;var distance: float=28
 for id in chart.locations:
  var gap: float=Vector2(chart.locations[id]).distance_to(local)
  if gap<distance: target=int(id);distance=gap
 if target>=0:
  # Inspect without clearing the route already being built.
  chart.picked=target;game.map_selected=target;chart.queue_redraw();chart.changed.emit()
 return true
func append_map_route(chart):
 if game.hyperdrive.active() or not game.chain_route.is_empty(): return
 var target: int=game.map_selected
 if game.catalog.system(target).is_empty(): return
 var origin: int=game.pilot.system_id if game.map_route.is_empty() else int(game.map_route.back())
 var path: Array=game.autopilot.path(origin,target)
 if path.is_empty(): return
 game.map_route.append_array(path)
 game.destination=int(game.map_route.back()) if game.pilot.cheat_chain_jump else int(game.map_route.front())
 game.sound("ui_select");chart.queue_redraw();chart.changed.emit()
func menu_button(button: int):
 if game.mode=="controls" and button in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
  var preferences=game.hud.modal_root.get_child(0)
  if not is_instance_valid(preferences.speed_panel):preferences.select_tab("controller" if preferences.selected_tab=="keyboard" else "keyboard")
  return
 if button==JOY_BUTTON_B:
  send_key(KEY_ESCAPE);return
 if game.mode=="map":
  var chart=map_chart()
  if is_instance_valid(chart):
   if button==JOY_BUTTON_X: append_map_route(chart);return
   if button==JOY_BUTTON_A and not is_instance_valid(selected) and pick_map_system(chart): return
  if button==JOY_BUTTON_LEFT_SHOULDER: send_key(KEY_MINUS);return
  if button==JOY_BUTTON_RIGHT_SHOULDER: send_key(KEY_EQUAL);return
  if button==JOY_BUTTON_Y: action_key("next_destination");return
 if button in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
  navigate_menu(button);return
 if button==JOY_BUTTON_A:
  if is_instance_valid(selected) and selected.is_visible_in_tree():
   if selected is BaseButton and not selected.disabled:
    if selected.toggle_mode: selected.button_pressed=not selected.button_pressed
    remember_focus(selected)
    var activated: BaseButton=selected
    activated.pressed.emit()
    # A newly opened screen may explicitly focus its primary list.
    if selected==activated: selected=null
    restore_focus()
    restore_focus.call_deferred()
   elif selected is ItemList and not selected.get_selected_items().is_empty(): selected.item_activated.emit(selected.get_selected_items()[0])
  else: click_mouse(MOUSE_BUTTON_LEFT)
func screen_key() -> String:
 return game.mode+":"+(str(game.hud.port_page) if game.mode=="dock" else "")
func remember_focus(control: Control):
 var token: Dictionary={"screen":screen_key(),"name":str(control.name),"text":control.text if control is BaseButton else ""}
 focus_history.append(token)
 if focus_history.size()>24: focus_history.pop_front()
func restore_focus():
 if last_mode!=game.mode: reset();last_mode=game.mode
 if not using_pad or game.mode in ["flight","intro"]: return
 var choices: Array=[];collect_buttons(menu_scope(),choices)
 if is_instance_valid(selected) and selected in choices: return
 for index in range(focus_history.size()-1,-1,-1):
  var token: Dictionary=focus_history[index]
  if token.screen!=screen_key(): continue
  for choice in choices:
   var matches: bool=str(choice.name)==str(token.name) if not str(token.name).begins_with("@") else choice is BaseButton and choice.text==str(token.text)
   if not matches: continue
   selected=choice;selected.focus_mode=Control.FOCUS_ALL;selected.grab_focus();reveal(selected);reveal.call_deferred(selected)
   focus_history.resize(index)
   queue_redraw();return
func scroll_parent(node: Node):
 var parent=node.get_parent()
 while parent!=null:
  if parent is ScrollContainer: return parent
  parent=parent.get_parent()
 return null
func visible_rect(control: Control) -> Rect2:
 if not is_instance_valid(control): return Rect2()
 var rect: Rect2=control.get_global_rect().intersection(get_viewport_rect())
 var parent=control.get_parent()
 while parent!=null:
  if parent is Control and parent.clip_contents: rect=rect.intersection(parent.get_global_rect())
  parent=parent.get_parent()
 return rect
func reveal(control: Control):
 if not is_instance_valid(control) or not control.is_inside_tree(): return
 if control is ItemList: control.ensure_current_is_visible()
 var parent=control.get_parent()
 while parent!=null:
  if parent is ScrollContainer:
   parent.follow_focus=true;parent.ensure_control_visible(control)
  parent=parent.get_parent()
func navigate_menu(button: int):
 restore_focus()
 if is_instance_valid(selected) and selected.is_visible_in_tree() and button in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN]:
  var step: int=-1 if button==JOY_BUTTON_DPAD_UP else 1
  if selected is ItemList:
   var items: PackedInt32Array=selected.get_selected_items()
   var current: int=int(items[0]) if not items.is_empty() else -1
   var index: int=current+step
   if index>=0 and index<selected.item_count:
    selected.select(index);selected.ensure_current_is_visible();selected.item_selected.emit(index);reveal(selected);return
  elif selected is RichTextLabel:
   var bar=selected.get_v_scroll_bar();var previous: float=bar.value
   bar.value+=step*60
   if not is_equal_approx(previous,bar.value): return
 var choices: Array=[];collect_buttons(menu_scope(),choices)
 if choices.is_empty(): return
 var next: Control
 if not is_instance_valid(selected) or selected not in choices:
  var visible: Array=choices.filter(func(c):return visible_rect(c).has_area())
  if visible.is_empty(): visible=choices
  visible.sort_custom(func(a,b):return a.get_global_rect().position.y<b.get_global_rect().position.y if absf(a.get_global_rect().position.y-b.get_global_rect().position.y)>8 else a.get_global_rect().position.x<b.get_global_rect().position.x)
  next=visible[0]
 else:
  var direction: Vector2=Vector2.LEFT if button==JOY_BUTTON_DPAD_LEFT else Vector2.RIGHT if button==JOY_BUTTON_DPAD_RIGHT else Vector2.UP if button==JOY_BUTTON_DPAD_UP else Vector2.DOWN
  var origin: Rect2=selected.get_global_rect();var origin_scroll=scroll_parent(selected)
  var best: float=INF;var best_group: int=3
  for candidate in choices:
   if candidate==selected: continue
   var rect: Rect2=candidate.get_global_rect()
   var delta: Vector2=rect.get_center()-origin.get_center()
   var forward: float=delta.dot(direction)
   if forward<=2: continue
   var sideways: float=absf(delta.dot(direction.orthogonal()))
   var aligned: bool=rect.position.y<origin.end.y-2 and rect.end.y>origin.position.y+2 if direction.x!=0 else rect.position.x<origin.end.x-2 and rect.end.x>origin.position.x+2
   var group: int=0 if origin_scroll!=null and scroll_parent(candidate)==origin_scroll else 1
   var score: float=forward+sideways*3+(0 if aligned else 10000)
   if group<best_group or (group==best_group and score<best):
    next=candidate;best=score;best_group=group
 if not is_instance_valid(next): return # No wrap to an unrelated row or screen edge.
 selected=next;selected.focus_mode=Control.FOCUS_ALL;selected.grab_focus()
 reveal(selected);reveal.call_deferred(selected)
 var rect=visible_rect(selected)
 if rect.has_area(): cursor=rect.get_center()
func collect_scrolls(node: Node,result: Array):
 if node is Control and not node.is_visible_in_tree(): return
 if node is ScrollContainer or (node is RichTextLabel and node.scroll_active) or node is ItemList:
  var bar=node.get_v_scroll_bar()
  if bar.max_value>bar.page: result.append(node)
 for child in node.get_children(): collect_scrolls(child,result)
func scroll_menu(amount: float,dt: float):
 var areas: Array=[];collect_scrolls(menu_scope(),areas)
 if areas.is_empty(): return
 var area
 for candidate in areas:
  if visible_rect(candidate).has_point(cursor): area=candidate
 if area==null and is_instance_valid(selected): area=selected if selected in areas else scroll_parent(selected)
 if area==null: area=areas[0]
 var bar=area.get_v_scroll_bar();bar.value+=amount*650*dt
func click_mouse(button: int):
 dispatch_click.call_deferred(button,cursor)
func dispatch_click(button: int,at: Vector2):
 var motion=InputEventMouseMotion.new();motion.position=at;motion.global_position=at;Input.parse_input_event(motion)
 for down in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=button;event.position=at;event.global_position=at;event.pressed=down;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down and button==MOUSE_BUTTON_LEFT else 0
  Input.parse_input_event(event)
func advance_repeat(dt: float):
 if repeat_button<0 or game.mode in ["flight","intro"]: return
 if not buttons.get(repeat_button,false): repeat_button=-1;return
 repeat_remaining-=minf(dt,.25)
 # Bound catch-up after a stalled frame so one hitch cannot skip a whole list.
 for step in 3:
  if repeat_remaining>0: break
  repeat_remaining+=DPAD_INTERVAL
  navigate_menu(repeat_button)
func _process(dt):
 if last_mode!=game.mode: reset();last_mode=game.mode
 if game.mode in ["flight","intro"]: focus_history.clear()
 if not using_pad or game.mode in ["flight","intro"]: return
 restore_focus()
 advance_repeat(dt)
 if is_instance_valid(selected) and selected.is_visible_in_tree():
  var rect=visible_rect(selected)
  if rect.has_area(): cursor=rect.get_center()
 var movement=Vector2(analog(JOY_AXIS_LEFT_X),analog(JOY_AXIS_LEFT_Y))
 if movement.length()>.01:
  selected=null;cursor=(cursor+movement*700*dt).clamp(Vector2(2,2),get_viewport_rect().size-Vector2(2,2))
  var event=InputEventMouseMotion.new();event.position=cursor;event.global_position=cursor;event.relative=Vector2.ZERO
  Input.parse_input_event(event)
 var pan=Vector2(analog(JOY_AXIS_RIGHT_X),analog(JOY_AXIS_RIGHT_Y))
 var chart=map_chart()
 if is_instance_valid(chart) and pan.length()>.01:
  game.map_center+=pan*450*dt/game.map_zoom
  chart.queue_redraw();chart.changed.emit()
 var scroll: float=analog(JOY_AXIS_RIGHT_Y)
 if game.mode!="map" and absf(scroll)>.1:
  scroll_menu(scroll,dt)
 queue_redraw()
func _draw():
 if not using_pad or game.mode in ["flight","intro"]: return
 if is_instance_valid(selected) and selected.is_visible_in_tree():
  var rect=visible_rect(selected)
  if rect.has_area(): draw_rect(rect,Color("e4bd68"),false,3)
  return # D-pad focus uses an outline; only stick-pointer input shows the crosshair.
 draw_circle(cursor,9,Color(0,0,0,.8));draw_line(cursor-Vector2(12,0),cursor+Vector2(12,0),Color("e4bd68"),2);draw_line(cursor-Vector2(0,12),cursor+Vector2(0,12),Color("e4bd68"),2)
