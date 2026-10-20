extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var catalog=load("res://scripts/catalog.gd").new()
 check(catalog.prices(133)==[120,192,600,-1,144,360],"live original Levo market: food120 industrial192 medical600 luxury unavailable metal144 equipment360")
 # Independent numeric examples from PPC 0x4a914, including strict rounding boundaries.
 for row in [[8500,2,5,7730],[5000,1,5,4400],[99,1,5,99],[100,1,5,88],[10000,5,5,10000],[10001,5,5,10000],[100000,5,5,100000],[100001,5,5,100000],[1234567,100,5,1234000],[5555,5,1,5550]]:
  check(catalog.technology_price(row[0],row[1],row[2])==row[3],"original tech-price example: "+str(row))
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-service-price-tests.json"
 game.controls.path="/tmp/ev-service-price-controls.json";game.traffic.enabled=false;game.muted=true;root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game.pilot.credits=1000000;game.docked_id=128
 game.pilot.outfits["130"]=1
 game.set_mode("outfitter")
 check(game.outfitter.price(130)==7730 and game.outfitter.price(130,false)==6184,"Earth discounts purchases and values existing cannon at eighty percent")
 var initial: int=game.pilot.credits
 check(game.outfitter.trade(130,false) and game.pilot.credits==initial+6184,"sale pays quoted amount")
 check(game.outfitter.trade(130,true),"can replace sold cannon")
 check(game.outfitter.price(130,false)==6184,"replacing existing stock does not create refund credit")
 game.pilot.outfits.erase("130");game.set_mode("dock");game.set_mode("outfitter")
 initial=game.pilot.credits
 check(game.outfitter.trade(130,true),"buy during new visit")
 game.hud.rebuild_modal()
 check(game.outfitter.price(130,false)==7730,"UI rebuild preserves same-visit refund")
 check(game.outfitter.trade(130,false) and game.pilot.credits==initial,"buy/sell round trip cannot generate money")
 game.outfitter.trade(130,true);game.set_mode("dock");game.set_mode("outfitter")
 check(game.outfitter.price(130,false)==6184,"leaving commits purchases to existing equipment")
 var p=game.Pilot.new();check(p.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)),game.catalog),"transaction save restores")
 game.pilot=p;game.set_mode("dock");game.set_mode("outfitter")
 check(game.outfitter.price(130,false)==6184,"reload does not restore full refund")
 check(game.fleet_service.hire_cost(131)==int(game.catalog.equipment_price("ships",131,128)*.1),"hire deposit uses original ten percent hull price")
 check(game.fleet_service.wage(131)==1800 and game.fleet_service.hire_cost(131)==15800,"Courier costs 15800 to hire at Earth and 1800 per day")
 game.pilot.fleet=[{"id":131,"hired":true,"wage":180,"paid_day":int(game.pilot.campaign.day)}]
 game.fleet_service.prepare()
 check(game.pilot.fleet[0].wage==1800 and game.pilot.fleet[0].paid_day==int(game.pilot.campaign.day),"legacy hired wages migrate without double billing past days")
 game.pilot=game.Pilot.new()
 game.pilot.ship_id=128;game.pilot.ship_fields=game.catalog.record("ships",128).fields.duplicate(true);game.pilot.lasers=1;game.pilot.outfits={}
 check(game.shipyard.trade_in()==5610 and game.shipyard.price(131)==152390,"Earth shuttle trade-in includes stock laser and two original tech adjustments")
 game.pilot.outfits["167"]=1
 check(game.shipyard.trade_in()==5610,"transferred mission equipment adds no trade-in value")
 game.pilot.outfits["130"]=1
 check(game.shipyard.trade_in()==11700,"installed equipment retains original ninety-five percent contribution before port adjustments")
 game.pilot.fuel=300;game.pilot.credits=40;game.pilot.armor=20
 check(game.refuel_cost()==100 and game.refuel()==40 and game.pilot.fuel==340 and game.pilot.credits==0,"forty credits buy forty of one hundred missing fuel units")
 check(game.pilot.armor==20 and game.refuel()==0,"refueling preserves armor and cannot spend absent credits")
 game.world_activity.state().dominated.append(128)
 check(game.refuel_cost()==0 and game.refuel()==0 and game.pilot.fuel==400,"dominated port supplies remaining fuel for free")
 game.world_activity.state().dominated.clear();game.docked_id=177;game.pilot.fuel=300;game.pilot.credits=1000
 var flags: int=int(game.catalog.field("objects",177,"Flags"));game.catalog.data.objects["177"].fields.Flags=flags|32
 check(game.refuel()==0 and game.pilot.fuel==300 and game.pilot.credits==1000,"uninhabited world supplies no fuel")
 game.catalog.data.objects["177"].fields.Flags=flags
 var defector: Dictionary=game.missions.offer(228,128)
 check(defector.back==128 and defector.ship_system==game.missions.system_of(128),"mission 228 returns to origin and spawns defector in return system")
 var toxins: Dictionary=game.missions.offer(224,128)
 check(toxins.picked and toxins.dest==177,"mission 224 retains repaired pickup and original toxin destination")
 game.free();await process_frame
 print("ORIGINAL SERVICE PRICES: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
