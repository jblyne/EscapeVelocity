extends SceneTree
var failures: int=0
func check(ok: bool,message: String) -> void:
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev263-journal.json";game.controls.path="/tmp/ev263-controls.json";game.muted=true;game.traffic.enabled=false;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.controls.controller.set_process(false)
 game.set_mode("flight");game.pilot.campaign.active=[];game.pilot.mission={}
 var event=InputEventKey.new();event.physical_keycode=KEY_I;event.pressed=true;game._unhandled_key_input(event);game.hud._process(0)
 check(game.mode=="flight" and game.hud.modal_root.get_child_count()==0 and game.hud.empty_journal_notice.visible,"Empty keyboard journal shows message without pausing flight or building a modal")
 check(game.hud.empty_journal_notice.text=="You have no active missions." and game.flight_welcome_seconds==0,"Original text replaces welcome")
 if "--visual" in OS.get_cmdline_user_args():
  await create_timer(.2).timeout
  for i in 4:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/validation/journal-0.1.263/empty.png"))
 game.docked_id=133;game.set_mode("dock");game.missions.channel=2;game.missions.open();game.hud._process(0)
 check(game.mode=="dock" and game.hud.empty_journal_notice.visible,"Empty docked journal also leaves current screen in place")
 game.pilot.mission={"system":129,"reward":1200};game.missions.open()
 check(game.mode=="missions","Active courier still opens journal")
 game.pilot.mission={};game.pilot.campaign.active=[game.missions.offer(128,133)];game.set_mode("flight");game.missions.open()
 check(game.mode=="missions","Active campaign mission still opens journal")
 game.pilot.campaign.active=[];game.set_mode("dock");game.missions.channel=0;game.missions.open()
 check(game.mode=="missions","Mission computer still opens when no jobs are active")
 print("Empty journal: %d failures"%failures);game.queue_free();await process_frame;quit(1 if failures else 0)
