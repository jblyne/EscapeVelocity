extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 check(root.content_scale_aspect==Window.CONTENT_SCALE_ASPECT_EXPAND,"Window expands the game view instead of pillarboxing")
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev-widescreen.json";game.controls.path="/tmp/ev-widescreen-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 for dimensions in [Vector2i(1920,1080),Vector2i(2560,1080),Vector2i(3440,1440),Vector2i(5120,1440)]:
  root.size=dimensions
  await process_frame;await process_frame
  var visible=root.get_visible_rect().size
  check(absf(visible.x/visible.y-float(dimensions.x)/dimensions.y)<.01,"Game fills %s aspect ratio" % dimensions)
  var panel=game.hud.flight_panel
  check(absf(panel.canvas.position.x+panel.panel_width()-visible.x)<1,"HUD stays at right edge for %s" % dimensions)
  check(game.camera.keep_aspect==Camera3D.KEEP_HEIGHT,"Camera preserves vertical scale at %s" % dimensions)
 game.free();await process_frame
 print("WIDESCREEN: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
