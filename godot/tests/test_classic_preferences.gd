extends SceneTree
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func shot(ui,id: String) -> void:
 if "--visual" not in OS.get_cmdline_user_args():return
 for i in 4:await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/validation/preferences-0.1.252/"+id+".png"))
func run() -> void:
 var path="/tmp/ev252-preferences-test.json";DirAccess.remove_absolute(path)
 var game=load("res://main.tscn").instantiate();game.controls.path=path;game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 var pad=game.controls.controller;pad.set_process(false);pad.set_process_input(false)
 game.set_mode("title");game.hud.modal_root.get_child(0).preferences()
 var ui=game.hud.modal_root.get_child(0)
 check(game.mode=="controls" and ui.pages.keyboard.visible and not ui.pages.controller.visible,"Set Prefs opens directly on Keyboard tab")
 check(ui.buttons.size()==game.controls.DEFAULTS.size() and ui.pad_buttons.size()==game.controls.PAD_DEFAULTS.size(),"Every existing binding remains configurable")
 check(ui.canvas.get_node("PreferencesPaper").get_theme_stylebox("panel").bg_color==Color.WHITE,"Preferences use classic white paper")
 await shot(ui,"keyboard")
 ui.buttons.map.grab_focus();ui.buttons.map.pressed.emit()
 await shot(ui,"binding-selected")
 var event=InputEventKey.new();event.pressed=true;event.physical_keycode=KEY_Z;ui._input(event)
 check(game.controls.bindings.map==[KEY_Z] and ui.buttons.map.text=="Z","Keyboard field captures and displays replacement key")
 ui.buttons.jump.pressed.emit();ui.select_tab("controller")
 check(ui.waiting.is_empty() and game.controls.capture_action.is_empty() and ui.pages.controller.visible and not ui.pages.keyboard.visible,"Switching tabs cancels unfinished capture and hides the other page")
 await shot(ui,"controller")
 pad.using_pad=true;pad.last_mode="controls";pad.menu_button(JOY_BUTTON_LEFT_SHOULDER)
 check(ui.selected_tab=="keyboard" and pad.selected==ui.tabs.keyboard,"Controller shoulder switches tabs and retains usable focus")
 pad.menu_button(JOY_BUTTON_RIGHT_SHOULDER)
 ui.pad_buttons.fire.pressed.emit();var press=InputEventJoypadButton.new();press.button_index=JOY_BUTTON_X;press.pressed=true;pad._input(press)
 check(game.controls.pad_bindings.fire=="b2" and pad.selected==ui.pad_buttons.fire,"Controller capture swaps bindings and restores selected field")
 ui.set_volume(.25);ui.music_toggle.button_pressed=false
 ui.show_speed();ui.speed_slider.value=1.3
 event.physical_keycode=KEY_ESCAPE;ui._input(event);await process_frame
 check(game.mode=="controls" and not is_instance_valid(ui.speed_panel) and game.controls.speed==1.3,"Escape closes game-speed popup before preferences")
 ui.close(false)
 check(game.mode=="title" and game.controls.bindings.map==[KEY_M] and game.controls.pad_bindings.fire=="a5" and game.controls.sound_volume==1.0 and game.controls.intro_music and game.controls.speed==1.0,"Cancel restores keyboard, controller, audio and speed settings")
 game.open_controls();ui=game.hud.modal_root.get_child(0)
 game.controls.bind("map",KEY_Z);ui.set_volume(.5);ui.music_toggle.button_pressed=false;ui.close(true)
 var saved=preload("res://scripts/control_settings.gd").new();saved.path=path;saved.load_settings()
 check(saved.bindings.map==[KEY_Z] and saved.sound_volume==.5 and not saved.intro_music,"OK persists bindings, sound volume and intro music")
 if "--visual" in OS.get_cmdline_user_args():
  game.open_controls();ui=game.hud.modal_root.get_child(0);pad.using_pad=false
  for dimensions in [Vector2i(1280,720),Vector2i(1024,768)]:
   root.size=dimensions
   for i in 4:await process_frame
   ui.fit();check(root.get_visible_rect().encloses(Rect2(ui.canvas.position,ui.canvas.size*ui.canvas.scale)),"Preferences fit viewport "+str(dimensions))
   await shot(ui,"keyboard-%dx%d" % [dimensions.x,dimensions.y])
 game.free();await process_frame
 print("CLASSIC PREFERENCES: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
