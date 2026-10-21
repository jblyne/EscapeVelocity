extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate()
 game.save_path="/tmp/ev-sidewinder-stock.json";game.controls.path="/tmp/ev-sidewinder-stock-controls.json"
 game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
 game.pilot.credits=2000000;game.docked_id=128;game.set_mode("shipyard");game.shipyard.buy(900);game.set_mode("outfitter")
 var count=0
 for record in game.catalog.data.objects.values():
  if not int(record.fields.Flags)&4: continue
  game.docked_id=int(record.id);count+=1
  check(game.outfitter.available_here(902),"Maverick Sidewinders stocked at %s" % record.name)
 check(count>0,"Checked every outfitter port")
 game.docked_id=128
 var fields=game.catalog.record("objects",128).fields
 var old=fields.TechLevel;fields.TechLevel=0
 check(game.outfitter.reason(902,true).is_empty(),"Sidewinder purchase ignores local tech level for Maverick")
 var before=game.outfitter.count(902)
 check(game.outfitter.trade(902,true) and game.outfitter.count(902)==before+1,"Maverick can buy Sidewinders at a tech-zero outfitter")
 fields.TechLevel=old
 game.pilot.ship_id=128
 check(not game.outfitter.available_here(902) and game.outfitter.reason(902,true).contains("only for the F-14 Tomcat"),"Other ships cannot buy Sidewinders even at high-tech ports")
 game.pilot.ship_id=900;game.docked_id=-1
 check(not game.outfitter.available_here(902),"Maverick still needs an actual outfitter")
 game.free();await process_frame
 print("SIDEWINDER STOCK: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
