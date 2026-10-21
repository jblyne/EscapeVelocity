extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev-firework-slots.json";game.controls.path="/tmp/ev-firework-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.pilot.cheat_world_killer=true
 game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
 var k=game.world_killer
 game.pilot.system_id=game.missions.system_of(128);game.load_system();game.set_mode("flight")
 game.landing_target=128;game.pilot.position=k.target_position(128)+Vector2(k.target_radius(128)+150,0)
 game.world_activity.open_contact();k.threaten();k.deploy()
 k.launch_fireworks("WE'RE SORRY")
 var first=k.effects.back()
 k.launch_fireworks("WE LOVE YOU!")
 var second=k.effects.back()
 var center=game.v3(k.target_position(128),150)
 check(first!=second and first.message_side==-1 and second.message_side==1,"Second firework message takes the bottom slot")
 check(first.position.z<center.z-k.target_radius(128) and second.position.z>center.z+k.target_radius(128),"Both messages clear the planet surface")
 var count=k.effects.size();k.launch_fireworks("MERCY!")
 check(k.effects.size()==count,"A third simultaneous message cannot overlap the occupied slots")
 first.advance(7)
 k.launch_fireworks("PLEASE SPARE US")
 check(k.effects.size()==count+1 and k.effects.back().message_side==-1,"Expired top message releases its slot")
 var top=k.effects.back();second.advance(7)
 k.launch_fireworks("MERCY!")
 check(k.effects.back().message_side==1 and k.effects.back()!=top,"Expired bottom slot can also be reused")
 game.free();await process_frame
 print("FIREWORK SLOTS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
