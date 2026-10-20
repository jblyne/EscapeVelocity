extends "res://scripts/classic_service.gd"
var waiting: String=""
var status: Label
var buttons: Dictionary={}
func _ready():
 super._ready()
 game.controls.load_settings()
 var heading=Label.new();heading.text="Keyboard & game speed";content.add_child(heading)
 status=Label.new();status.text="Select an action, then press a key. Escape cancels a change.";content.add_child(status)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(scroll)
 var grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(grid)
 for action in game.controls.DEFAULTS:
  var title=Label.new();title.text=str(action).replace("_"," ").capitalize();title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(title)
  var button=Button.new();button.text=game.controls.caption(action);grid.add_child(button);buttons[action]=button
  button.pressed.connect(func():waiting=action;status.text="Press a key for "+str(action).replace("_"," ")+"…")
 var row=HBoxContainer.new();content.add_child(row)
 for classic in [false,true]:
  var button=Button.new();button.text="Classic flight preset" if classic else "Restore remake defaults";row.add_child(button)
  button.pressed.connect(func():game.controls.preset(classic);refresh())
 var speed=HSlider.new();speed.min_value=.5;speed.max_value=2;speed.step=.1;speed.value=game.controls.speed;content.add_child(speed)
 speed.tooltip_text="Simulation speed (0.5×–2×); menus are unaffected"
 speed.value_changed.connect(func(value):game.controls.speed=value;game.controls.save_settings();status.text="Game speed: %.1f×" % value)
 var done=Button.new();done.text="Done";content.add_child(done);done.pressed.connect(func():game.set_mode(game.controls_return_mode))
 restyle(content)
func refresh():
 waiting=""
 for action in buttons: buttons[action].text=game.controls.caption(action)
 status.text="Bindings saved."
func _input(event):
 if waiting.is_empty() or not event is InputEventKey or not event.pressed or event.echo: return
 get_viewport().set_input_as_handled()
 if event.physical_keycode==KEY_ESCAPE: refresh();return
 var error=game.controls.bind(waiting,event.physical_keycode)
 if error.is_empty(): refresh()
 else: status.text=error
