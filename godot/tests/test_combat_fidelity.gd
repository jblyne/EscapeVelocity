extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func clear_shots():
 for shot in game.shots: shot.node.free()
 game.shots.clear()
func volley_count(npc,target,frames: int) -> int:
 clear_shots();npc.weapons=[{"id":128,"count":3,"ammo":-1,"cooldown":0.0}]
 for i in frames: game.traffic.advance_weapons(npc,target,1.0/frames)
 return game.shots.size()
func run():
 game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-combat-fidelity.json";game.controls.path="/tmp/ev-combat-fidelity-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 game.pilot.position=Vector2(10000,10000)
 for npc in game.npcs.duplicate(): game.traffic.retire(npc)
 var npc=game.traffic.spawn(133,128,3,Vector2.ZERO);npc.heading=0
 var victim=game.traffic.spawn(138,129,3,Vector2(0,-200))
 var target={"position":victim.position,"velocity":Vector2.ZERO,"model":victim.model}
 check(is_equal_approx(game.arsenal.projectile_lifetime(128),.5),"Laser lifetime follows its recovered Count of 30")
 check(is_equal_approx(game.arsenal.weapon_reach(128),437.5),"Laser reach follows speed times lifetime")
 check(game.arsenal.fire(128,Vector2.ZERO,0),"Laser projectile can be emitted")
 check(is_equal_approx(game.shots.back().life,.5),"Live projectile uses the same range model as AI")
 clear_shots()
 game.target_index=-1
 check(not game.arsenal.fire(133,Vector2.ZERO,0),"Player turret refuses to fire without a selected target")
 check(game.shots.is_empty(),"No target means no phantom turret projectile")
 game.target_index=game.npcs.find(victim)
 check(game.arsenal.fire(133,Vector2.ZERO,0),"Targeted player turret fires normally")
 check(not game.arsenal.fire(143,Vector2.ZERO,0),"Rear turret does not fire at a forward target outside its arc")
 victim.position=Vector2(0,200)
 check(game.arsenal.fire(143,Vector2.ZERO,0),"Rear turret fires at a selected target aft")
 victim.position=Vector2(0,-200)
 game.target_index=-1
 check(not game.arsenal.fire(133,Vector2.ZERO,0,false,npc),"NPC turret also requires a designated opponent")
 check(game.arsenal.fire(133,Vector2.ZERO,0,false,npc,target),"NPC turret accepts its AI-designated opponent")
 clear_shots()
 npc.weapons=[{"id":128,"count":3,"ammo":-1,"cooldown":0.0}]
 game.traffic.advance_weapons(npc,target,0)
 check(game.shots.size()==3,"Three gun mounts produce three shots in one volley")
 check(is_equal_approx(npc.weapons[0].cooldown,20.0/60),"Mount count does not divide the weapon reload period")
 game.traffic.advance_weapons(npc,target,.1)
 check(game.shots.size()==3,"Extra mounts do not grant additional early firing cycles")
 game.traffic.advance_weapons(npc,target,20.0/60-.1)
 check(game.shots.size()==6,"All mounts reload together at the recovered period")
 var at30=volley_count(npc,target,30);var at120=volley_count(npc,target,120)
 check(at30==at120 and at30==12,"30 and 120 updates per second preserve volley count and fractional timing")
 clear_shots();npc.weapons=[{"id":128,"count":3,"ammo":-1,"cooldown":0.0}]
 game.traffic.advance_weapons(npc,{"position":Vector2(0,-800),"model":victim.model},1)
 check(game.shots.is_empty(),"AI does not waste short-range laser fire at the old fixed 950-unit distance")
 game.traffic.advance_weapons(npc,target,0)
 check(game.shots.size()==3,"Entering range fires one volley without banking offscreen cooldown debt")
 clear_shots();npc.weapons=[{"id":131,"count":3,"ammo":2,"cooldown":0.0}]
 game.traffic.advance_weapons(npc,target,0)
 check(game.shots.size()==2 and npc.weapons[0].ammo==0,"Finite ammunition is spent per emitted projectile, including multi-mount launchers")
 game.traffic.advance_weapons(npc,target,5)
 check(game.shots.size()==2,"Empty launchers stop firing")
 npc.weapons=[{"id":128,"count":1,"ammo":-1,"cooldown":10.0}]
 var stationary_goal=game.traffic.attack_goal(npc,target)
 target.velocity=Vector2(100,0)
 check(game.traffic.attack_goal(npc,target).x>stationary_goal.x,"Pursuit accounts for a moving opponent")
 npc.position=Vector2.ZERO;npc.velocity=Vector2(10,0);npc.heading=0;npc.goal=Vector2(0,-1000);npc.truce=true;npc.weapons=[]
 game.traffic.retire(victim)
 var before=npc.velocity
 game.traffic.update(.01)
 check(is_equal_approx(npc.velocity.x,before.x),"Turning and forward thrust preserve lateral momentum instead of steering velocity directly")
 check(npc.velocity.y<0,"Aligned NPC main engines add thrust along the hull")
 var clock: float=4.0/60
 for frame in 4: clock=game.Flight.reload_remaining(clock,1.0/60)
 check(clock==0,"Four-tick reload ends on the fourth tick without a floating-point extra frame")
 game.set_mode("pause");var position=npc.position;game.traffic.update(1)
 check(npc.position==position,"Paused menus freeze AI motion and weapon timing")
 game.free();await process_frame
 print("COMBAT FIDELITY: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
