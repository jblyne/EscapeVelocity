extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-rebel-id.json";game.controls.path="/tmp/ev-rebel-id-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 for r in game.catalog.data.objects.values():
  if r.name=="Privateer's Haven": game.docked_id=int(r.id)
 game.set_mode("outfitter");game.pilot.credits=10000000;game.pilot.reputation["129"]=-100;game.pilot.reputation["128"]=-50
 check(game.outfitter.available_here(903),"Rebel Fake ID is sold at Privateer's Haven")
 var cost=game.outfitter.price(903);var before=game.pilot.credits
 check(game.outfitter.trade(903,true),"Rebel papers can be bought with a negative Rebel record")
 check(game.pilot.reputation["129"]==0 and game.pilot.reputation["128"]==-50,"Rebel papers clear only Rebellion standing")
 check(game.pilot.credits==before-cost and game.outfitter.count(903)==0,"Papers charge their price and are consumed immediately")
 check(not game.outfitter.trade(903,true),"Neutral standing cannot buy unnecessary papers")
 game.pilot.reputation["129"]=20
 check(not game.outfitter.trade(903,true) and game.pilot.reputation["129"]==20,"Positive Rebel standing is preserved")
 game.pilot.reputation["129"]=-10
 check(game.outfitter.trade(903,true) and game.pilot.reputation["129"]==0,"New offenses can be cleared with another purchase")
 check(game.outfitter.trade(180,true) and game.pilot.reputation["128"]==0,"Original Confederation Fake ID still works")
 game.pilot.reputation["129"]=-10;game.pilot.credits=0
 check(not game.outfitter.trade(903,true) and game.pilot.reputation["129"]==-10,"Insufficient funds cannot clear a record")
 game.docked_id=128
 check(not game.outfitter.available_here(903),"Rebel papers retain original Fake ID special stock restrictions")
 game.free();await process_frame
 print("REBEL ID: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
