extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev-landing-bribes.json";game.controls.path="/tmp/ev-landing-bribe-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.pilot.system_id=game.missions.system_of(128);game.load_system();game.set_mode("flight")
 var service=game.world_activity;service.contact_id=128
 game.pilot.reputation["128"]=-1000;game.pilot.credits=100000
 game.set_mode("world_comms")
 check(service.can_bribe_landing(128),"Denied political clearance permits a landing bribe")
 check(game.hud.modal_root.find_child("BribeLanding",true,false)!=null,"Hailing offers a priced landing-bribe button")
 check(game.hud.modal_root.find_child("ThreatenWorld",true,false)==null,"Death Star option is hidden by default")
 check(not game.world_killer.reason(128).is_empty(),"Death Star service also enforces its cheat toggle")
 service.landing_officer(128).willing=true
 var price=service.landing_bribe_price(128);var before=game.pilot.credits
 game.pilot.credits=price-1
 check(not service.pay_landing_bribe() and not service.landing_reason(128).is_empty(),"Insufficient credits cannot buy clearance")
 game.pilot.credits=before
 check(service.pay_landing_bribe() and game.pilot.credits==before-price,"Landing bribe charges the displayed price once")
 check(service.landing_reason(128).is_empty() and game.landing_clearance==128,"Payment grants working landing clearance")
 check(not service.pay_landing_bribe(),"Already-cleared port cannot charge another bribe")
 service.siege={"port":128}
 check(not service.landing_reason(128).is_empty() and not service.can_bribe_landing(128),"Bribes cannot bypass an active defense battle")
 service.siege={};game.load_system()
 check(not service.landing_reason(128).is_empty(),"Leaving or reloading the system clears temporary bribe clearance")
 game.pilot.cheat_world_killer=true;game.set_mode("world_comms")
 check(game.hud.modal_root.find_child("ThreatenWorld",true,false)!=null,"Enabling cheat reveals Death Star option")
 var restored=game.Pilot.new()
 check(restored.restore(game.pilot.snapshot(),game.catalog) and restored.cheat_world_killer,"Death Star cheat saves with pilot")
 game.free();await process_frame
 print("LANDING BRIBES: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
