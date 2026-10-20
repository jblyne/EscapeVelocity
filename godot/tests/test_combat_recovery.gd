extends SceneTree
var checks=0
var failures=0
const Combat=preload("res://scripts/combat.gd")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 check(is_equal_approx(Combat.shield_rate(180,36),60.0/36),"shuttle restores one integrity unit per thirty-six original ticks")
 check(Combat.recover(0,99,180,100,36,.6)==Vector2(0,100),"recovery reaches armor maximum before shields")
 var crossing=Combat.recover(0,99.5,180,100,36,.6)
 check(is_equal_approx(crossing.x,.5) and crossing.y==100,"recovery crossing armor boundary conserves integrity")
 check(Combat.recover(179,100,180,100,36,6)==Vector2(180,100),"recovery clamps full integrity")
 var capital={"health":667.0,"shield":0.0,"armor":667.0,"max_health":9000.0,"shield_capacity":8000.0}
 check(not Combat.is_disabled(capital),"capital remains operational before one third of armor is lost")
 capital.armor=666;capital.health=666
 check(Combat.is_disabled(capital),"capital disables after one third of armor is lost")
 var fighter={"health":1.0,"shield":1.0,"armor":0.0,"max_health":50.0,"shield_capacity":50.0}
 check(not Combat.is_disabled(fighter),"zero-armor fighter does not disable while shields remain")
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-recovery-tests.json";game.controls.path="/tmp/ev-recovery-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.set_mode("flight");game.pilot.shield=100;game.pilot.armor=100;game.damage_clock=0;game._physics_process(.1)
 check(game.pilot.shield>100,"player recovers immediately after damage without four-second delay")
 game.pilot.outfits["146"]=1
 check(game.pilot.shield_recharge()==34,"source Shield Booster subtracts two ticks from shuttle recharge")
 var npc={"health":200.0,"shield":100.0,"armor":100.0,"max_health":280.0,"shield_capacity":180.0,"disabled":false,"damage_clock":0.0}
 Combat.regenerate(npc,game.catalog.record("ships",128).fields,.1)
 check(npc.shield>100,"NPC also recovers without post-hit delay")
 npc.disabled=true;var before=npc.health;Combat.regenerate(npc,game.catalog.record("ships",128).fields,10)
 check(npc.health==before,"disabled contact cannot regenerate itself back into combat")
 game.pilot.shield=100;game.cloak.active=true;before=game.pilot.shield;game._physics_process(.1)
 check(game.pilot.shield<=before,"cloak does not recharge shields")
 game.cloak.active=false;game.pilot.shield=100;game.pilot.armor=20
 var body=game.planets[0];game.pilot.position=body.position;game.velocity=Vector2.ZERO
 game.landing_target=body.id;game.landing_clearance=body.id
 var credits: int=game.pilot.credits;game.land()
 check(game.mode=="dock" and game.pilot.armor==game.pilot.max_armor() and game.pilot.shield==game.pilot.max_shield(),"successful landing restores shield and armor integrity")
 check(game.pilot.credits==credits,"landing integrity restoration charges no invented repair fee")
 game.free();await process_frame
 print("COMBAT RECOVERY: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
