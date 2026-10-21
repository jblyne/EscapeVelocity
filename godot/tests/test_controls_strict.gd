extends SceneTree
const Controls=preload("res://scripts/control_settings.gd")
var checks=0
var failures=0
func check(ok,message):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var c=Controls.new();c.path="/tmp/ev-keybind-tests.json";c.preset()
 check(c.bind("map",KEY_Z).is_empty(),"bind new key")
 check(not c.bind("jump",KEY_Z).is_empty(),"reject conflicting key")
 check(not c.bind("jump",KEY_ESCAPE).is_empty(),"reserve menu keys")
 var copy=Controls.new();copy.path=c.path;copy.load_settings()
 check(copy.bindings==c.bindings,"bindings survive restart")
 c.preset(true);copy.load_settings()
 check(copy.bindings.afterburner==[KEY_2] and copy.bindings.cloak==[KEY_U],"classic flight preset survives reload")
 check(not c.bind("left",KEY_A).is_empty(),"A is reserved for autopilot")
 var legacy=c.bindings.duplicate(true);legacy.left=[KEY_A,KEY_LEFT];legacy.map=[KEY_Z]
 var prefs=FileAccess.open(c.path,FileAccess.WRITE);prefs.store_string(JSON.stringify({"bindings":legacy,"speed":1.5}));prefs.close()
 copy.load_settings()
 check(copy.bindings.left==[KEY_LEFT] and copy.bindings.map==[KEY_Z] and copy.speed==1.5,"Old A steering migrates without losing custom bindings or speed")
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-strict-tests.json"
 game.controls.path="/tmp/ev-keybind-tests.json";game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.controls.preset()
 game.controls.bind("map",KEY_Z)
 var event=InputEventKey.new();event.physical_keycode=KEY_Z;event.pressed=true
 game.set_mode("flight");game._unhandled_key_input(event)
 check(game.mode=="map","real key event uses rebound map action")
 game.set_mode("flight");event.physical_keycode=KEY_M;game._unhandled_key_input(event)
 check(game.mode=="flight","replaced key no longer fires old action")
 event.physical_keycode=KEY_F2;game._unhandled_key_input(event)
 check(game.landing_target!=-1 or game.planets.size()<2,"F-key stellar aliases accepted")
 game.create_pilot("Strict Test",true)
 check(game.pilot.strict and game.pilot.pilot_name=="Strict Test","creation chooses strict rules and name")
 var p=game.Pilot.new()
 check(p.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)),game.catalog) and p.strict,"strict setting persists")
 game.damage_player(100000)
 var saved=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
 check(game.mode=="dead" and saved.strict_dead,"strict death atomically marks save deceased")
 check(not p.restore(saved,game.catalog),"dead strict pilot cannot restore")
 game.load_game();check(game.mode=="dead","F9 cannot resurrect strict pilot")
 game.create_pilot("Normal Test",false);var before=FileAccess.get_file_as_string(game.save_path);game.damage_player(100000)
 check(FileAccess.get_file_as_string(game.save_path)==before,"normal death preserves living save")
 game.load_game();check(game.mode=="flight" and not game.pilot.strict,"normal pilot can reload")
 game.create_pilot("Pod Test",true);game.pilot.outfits["154"]=1;game.pilot.outfits["181"]=1;game.damage_player(100000)
 check(game.mode=="ejecting" and not game.pilot.strict_dead,"escape pod saves strict pilot before death")
 if "--visual" in OS.get_cmdline_user_args():
  game.restart();game.set_mode("pause");game.open_controls()
  await create_timer(.5).timeout;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("/tmp/ev-control-preferences.png")
 game.free();await process_frame
 print("CONTROLS & STRICT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
