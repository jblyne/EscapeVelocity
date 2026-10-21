extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev-projectile-hits.json";game.controls.path="/tmp/ev-projectile-controls.json"
 game.traffic.enabled=false;game.muted=true
 root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.set_mode("flight");game.npcs.clear()
 game.pilot.position=Vector2(20000,20000)
 var far=game.traffic.spawn(130,128,1,Vector2(20000,19600))
 var near=game.traffic.spawn(130,128,1,Vector2(20000,19800))
 game.target_index=game.npcs.find(near)
 # A fast missile crosses both contacts in a single frame. Spawn order is reversed.
 game.arsenal.fire(901,game.pilot.position,0,false)
 var shot=game.shots.back();shot.position=game.pilot.position
 shot.boost_age=1.0
 game.update_shots(.6)
 check(near not in game.npcs,"Sidewinder destroys the nearer bulk freighter")
 check(far.health==far.max_health,"Farther ship cannot steal a hit by appearing first in the contact list")
 check(game.selected_contact().is_empty(),"Destroyed target clears its hull readout")
 game.npcs.clear()
 var tough=game.traffic.spawn(130,128,1,Vector2(20000,19800))
 tough.shield_capacity=5000.0;tough.max_health=5250.0;tough.health=5250.0
 game.target_index=game.npcs.find(tough)
 game.arsenal.fire(901,game.pilot.position,0,false)
 shot=game.shots.back();shot.position=game.pilot.position;shot.boost_age=1.0
 game.update_shots(.3)
 check(game.selected_contact().health<game.selected_contact().max_health,"Surviving selected target exposes reduced integrity to the HUD")
 check(tough.armor==250 and tough.shield<5000,"Shield-only damage also reduces the combined hull meter")
 check(is_inf(game.shot_entry_distance(Vector2(100,100),Vector2.ZERO,Vector2(0,200),10)),"Near miss does not count as a hull hit")
 check(game.shot_entry_distance(Vector2(0,100),Vector2.ZERO,Vector2(0,200),10)==90,"Collision uses the entry surface rather than the center")
 game.free();await process_frame
 print("PROJECTILE HITS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
