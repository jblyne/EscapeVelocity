extends SceneTree
var game
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func mouse(point: Vector2,down: bool=true,button: int=MOUSE_BUTTON_LEFT) -> void:
 var event=InputEventMouseButton.new();event.position=point;event.global_position=point;event.pressed=down;event.button_index=button
 event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
 root.push_input(event,true)
func click(point: Vector2) -> void:
 mouse(point);mouse(point,false)
func run() -> void:
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev253-dialog-guard-pilot.json";game.controls.path="/tmp/ev253-dialog-guard-preferences.json";game.traffic.enabled=false
 root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 game.muted=false;game.pilot_ready=true;game.set_mode("title")
 var menu=game.hud.modal_root.get_child(0);menu.set_process(false);menu.animation_time=5
 menu.open_pilot();menu.update_presentation()
 for i in 3:await process_frame
 var sound: AudioStreamPlayer=game.audio.modal_alert
 check(sound.stream is AudioStreamWAV and absf(sound.stream.get_length()-.24)<.001 and sound.max_polyphony==1,"Recovered Simple Beep is a bounded 240 ms alert")
 click(menu.canvas.get_node("AboutEV").get_global_rect().get_center())
 check(sound.playing and game.mode=="title" and menu.dialog.visible and menu.naming_stage=="open","Outside click beeps and cannot open the menu behind Open Pilot")
 sound.stop();click(menu.dialog.get_global_rect().position+Vector2(18,18))
 check(not sound.playing and menu.dialog.visible,"Click inside the dialog does not play rejection alert")
 var cancel=menu.screen.find_child("CancelOpenPilot",true,false)
 mouse(Vector2(2,2));mouse(cancel.get_global_rect().get_center(),false)
 check(menu.dialog.visible,"Outside press followed by release over Cancel cannot activate it")
 game.muted=true;sound.stop();click(Vector2(2,2))
 check(not sound.playing and menu.dialog.visible,"Mute suppresses alert while modal still blocks the click")
 game.muted=false
 click(cancel.get_global_rect().get_center())
 check(not menu.dialog.visible,"Actual Cancel click remains usable")
 sound.stop();menu.new_pilot()
 for i in 3:await process_frame
 click(menu.canvas.get_node("OpenPilot").get_global_rect().get_center())
 check(sound.playing and menu.naming_stage=="pilot","New Pilot shares outside-click protection")
 game.open_controls();var prefs=game.hud.modal_root.get_child(0)
 for i in 3:await process_frame
 sound.stop();click(Vector2(2,2))
 check(sound.playing and game.mode=="controls","Preferences shares the original outside-click beep")
 prefs.show_speed()
 for i in 3:await process_frame
 sound.stop();click(prefs.tabs.controller.get_global_rect().get_center())
 check(sound.playing and is_instance_valid(prefs.speed_panel) and prefs.selected_tab=="keyboard","Frontmost Game Speed popover blocks the preferences tabs behind it")
 sound.stop();click(prefs.speed_panel.get_global_rect().position+Vector2(24,24))
 check(not sound.playing,"Nested popover accepts its own interior without double alert")
 if "--visual" in OS.get_cmdline_user_args():
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/validation/modal-guard-0.1.253.png"))
 game.free();await process_frame
 print("CLASSIC MODAL GUARD: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
