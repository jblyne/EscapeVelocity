extends SceneTree
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev260-first-flight.json";game.controls.path="/tmp/ev260-controls.json";game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.controls.controller.set_process(false)
 game.set_mode("title");game.restart(null,false)
 var levo: Dictionary=game.planets.filter(func(world):return int(world.id)==133)[0]
 check(game.pilot.position.is_equal_approx(levo.position+Vector2.ONE*levo.radius*1.4),"Fresh shuttle starts southeast of Levo at the original relative distance")
 check(game.velocity==Vector2.ZERO and game.pilot.heading==0,"Fresh shuttle starts stationary and facing up")
 check(not game.pilot.flight_welcome_seen and game.flight_welcome_seconds==0,"Naming a pilot does not consume the welcome")
 game.opening_story_seen=true;game.enter_ship_with_intro();game.hud._process(0)
 check(game.pilot.flight_welcome_seen and game.flight_welcome_seconds==30 and game.hud.flight_welcome.visible,"First Enter Ship displays welcome")
 check(game.hud.flight_welcome.text.contains("Welcome to Escape Velocity") and game.hud.flight_welcome.text.contains("Hit 'L'"),"Original welcome uses current landing key")
 game.controls.controller.using_pad=true
 check(game.flight_welcome_text().contains(game.controls.pad_caption("land")),"Controller welcome uses the configured landing button")
 game.flight_welcome_seconds=10;game.set_mode("pause");game.set_mode("flight")
 check(game.flight_welcome_seconds==10,"Returning from a menu does not restart welcome")
 var saved=game.pilot.snapshot();var restored=load("res://scripts/pilot.gd").new()
 check(restored.restore(saved,game.catalog) and restored.flight_welcome_seen and restored.position==game.pilot.position,"Save retains welcome state and actual starting position")
 saved.erase("flight_welcome_seen");saved.position=[789,456]
 check(restored.restore(saved,game.catalog) and restored.flight_welcome_seen and restored.position==Vector2(789,456),"Legacy saves retain their position and do not replay new-pilot welcome")
 game.docked_id=133;game.set_mode("dock")
 check(game.flight_welcome_seconds==0,"Landing dismisses the introduction")
 if "--visual" in OS.get_cmdline_user_args():
  game.set_mode("title");game.restart(null,true);game.hud._process(0)
  await create_timer(.3).timeout
  for i in 5:await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/validation/first-flight-0.1.260/welcome.png"))
 print("First flight: %d checks, %d failures"%[checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
