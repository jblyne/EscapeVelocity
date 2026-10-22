extends SceneTree
var game
var failures=0
func check(ok: bool,message: String):
 if not ok: failures+=1;push_error(message)
func button(id: int,down: bool=true):
 var event=InputEventJoypadButton.new();event.button_index=id;event.pressed=down;game.controls.controller._input(event);Input.flush_buffered_events()
func axis(id: int,value: float):
 var event=InputEventJoypadMotion.new();event.axis=id;event.axis_value=value;game.controls.controller._input(event);Input.flush_buffered_events()
func _initialize(): call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();game.controls.path="/tmp/ev234-pad-bindings.json"
 DirAccess.remove_absolute(game.controls.path)
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 var pad=game.controls.controller;pad.set_process(false);pad.set_process_input(false)
 game.controls_return_mode="title";game.set_mode("controls");pad.last_mode="controls"
 var ui=game.hud.modal_root.get_child(0)
 ui.pad_buttons.fire.pressed.emit()
 check(game.controls.capture_action=="fire","Controller row waits for controller input")
 button(JOY_BUTTON_X)
 check(game.controls.capture_action.is_empty() and game.controls.pad_bindings.fire=="b2" and game.controls.pad_bindings.board=="a5","Capturing Square swaps Fire and Board without losing either action")
 check(ui.pad_buttons.fire.text=="Square / X","Binding caption refreshes immediately")
 var saved=preload("res://scripts/control_settings.gd").new();saved.path=game.controls.path;saved.load_settings()
 check(saved.pad_bindings==game.controls.pad_bindings,"Controller bindings persist across reloads")
 ui.pad_buttons.jump.pressed.emit();button(JOY_BUTTON_START)
 check(game.controls.capture_action.is_empty() and game.mode=="controls" and game.controls.pad_bindings.jump=="b11","Options cancels capture without closing preferences")
 game.set_mode("flight");pad._process(0)
 button(JOY_BUTTON_X);check(game.controls.pressed("fire"),"Remapped Square holds weapon fire")
 button(JOY_BUTTON_X,false);check(not game.controls.pressed("fire"),"Remapped fire releases normally")
 game.set_mode("pause");pad._process(0);button(JOY_BUTTON_B);await process_frame
 check(game.mode=="flight","Circle retains menu Back regardless of flight mapping")
 check(game.controls.bind_pad("land","b6").length()>0,"Options cannot be rebound away from pause")
 game.controls.reset_pad();check(game.controls.pad_bindings==game.controls.PAD_DEFAULTS,"Controller defaults restore independently")
 game.free();await process_frame
 print("CONTROLLER BINDINGS: %d failures" % failures);quit(1 if failures else 0)
