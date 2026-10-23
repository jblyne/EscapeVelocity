extends SceneTree
var failures: int=0
var checks: int=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate();game.controls.path="/tmp/ev254-title-prefs.json";DirAccess.remove_absolute(game.controls.path)
 game.traffic.enabled=false;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.hud.set_process(false);game.controls.controller.set_process(false)
 game.set_mode("title")
 var menu=game.hud.modal_root.get_child(0)
 for i in 4:await process_frame
 if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
 menu.animation_time=10.0;menu.completed_rows=3;menu.motion_finished=true;menu.set_process(false)
 game.muted=false;game.controls.intro_music=true;game.start_title_audio();game.audio.menu_hum.stop()
 await create_timer(.1).timeout
 var position=game.audio.menu_music.get_playback_position()
 game.open_controls()
 var prefs=game.hud.modal_root.get_child(0)
 check(game.audio.menu_music.playing,"Opening preferences keeps menu music playing")
 check(game.hud.saved_title_menu==menu and menu.is_inside_tree(),"Original title remains behind preferences")
 await create_timer(.1).timeout
 check(game.audio.menu_music.get_playback_position()>=position,"Song continues without resetting")
 prefs.close(true)
 check(game.hud.modal_root.get_child(0)==menu and menu.animation_time==10.0 and menu.completed_rows==3 and menu.motion_finished,"Closing preferences retains exact title presentation")
 check(game.audio.menu_music.playing and not game.audio.menu_hum.playing,"Closing preferences preserves music without entrance hum")
 game.open_controls();prefs=game.hud.modal_root.get_child(0)
 prefs.music_toggle.button_pressed=false
 check(not game.audio.menu_music.playing,"Intro Music setting stops music intentionally")
 prefs.close(false)
 check(game.audio.menu_music.playing and game.controls.intro_music,"Cancel restores music preference and playback")
 game.open_controls();game.set_mode("flight")
 check(game.hud.saved_title_menu==null and not game.audio.menu_music.playing,"Leaving title context cleans up retained menu and music")
 print("Preferences title state: %d checks, %d failures"%[checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
