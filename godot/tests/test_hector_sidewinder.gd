extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-hector-sidewinder.json";game.controls.path="/tmp/ev-hector-sidewinder-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 game.pilot.position=Vector2(20000,20000);game.npcs.clear();game.hector.spawn()
 var target=game.npcs.back();var health=target.health
 game.damage_npc(target,100000)
 check(target.health==health,"Hector retains protection against other weapons")
 target.position=game.pilot.position+Vector2(0,-200);target.model.position=game.v3(target.position)
 target.health=100000;target.max_health=100000;target.shield_capacity=50000
 game.target_index=game.npcs.find(target)
 game.arsenal.fire(901,game.pilot.position,0,false)
 var missile=game.shots.back();missile.position=game.pilot.position;missile.boost_age=1
 game.update_shots(.3)
 check(target not in game.npcs,"One Sidewinder impact destroys Hector even above normal missile damage")
 check(game.selected_contact().is_empty(),"Hector's selected target clears after destruction")
 check(game.hector.banner_time==0,"Hector reminder clears when he is destroyed")
 game.free();await process_frame
 print("HECTOR SIDEWINDER: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
