extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String):
 checks+=1
 if not ok: failures+=1;push_error(message)
func _initialize(): call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-kill-rep.json";game.controls.path="/tmp/ev-kill-rep-controls.json"
 game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.set_mode("flight")
 game.pilot.reputation["128"]=0;game.pilot.reputation["129"]=-50
 var ship=game.traffic.spawn(128,128,1,Vector2(20000,20000))
 game.damage_npc(ship,1)
 check(game.pilot.reputation["129"]==-50,"Damaging a ship alone does not grant rival goodwill")
 game.damage_npc(ship,100000)
 check(game.pilot.reputation["129"]==-47,"Player destroying Confed shuttle improves negative Rebel standing by 3")
 check(game.pilot.reputation["128"]<=-25,"Destroyed faction retains its normal penalty")
 game.damage_npc(ship,100000)
 check(game.pilot.reputation["129"]==-47,"Repeated damage calls cannot reward the same destroyed ship twice")
 ship=game.traffic.spawn(128,129,1,Vector2(20000,20000))
 var before=int(game.pilot.reputation["128"])
 game.damage_npc(ship,100000,{"fleet_uid":1,"position":Vector2(20000,20100)})
 check(game.pilot.reputation["128"]==before+3,"Fleet kill of Rebel ship improves Confederation standing")
 ship=game.traffic.spawn(128,128,1,Vector2(20000,20000));before=game.pilot.reputation["129"]
 game.damage_npc(ship,100000,{},Vector2.ZERO,true)
 check(game.pilot.reputation["129"]==before,"Hyperspace-wake destruction does not farm reputation")
 game.pilot.reputation["129"]=9990;game.Factions.player_kill(game.catalog,game.pilot,143,134)
 check(game.pilot.reputation["129"]==10000,"Confederate patrol variant grants goodwill capped at 10000")
 before=game.pilot.reputation["128"];game.Factions.player_kill(game.catalog,game.pilot,130,128)
 check(game.pilot.reputation["128"]==before,"Unrelated faction kills do not grant this bonus")
 check(game.Factions.kill_goodwill(game.catalog,135)==2,"Small patrol ship earns 2 goodwill")
 check(game.Factions.kill_goodwill(game.catalog,133)==35,"Confederate frigate earns 35 goodwill")
 check(game.Factions.kill_goodwill(game.catalog,134)==100,"Confederate cruiser earns 100 goodwill")
 check(game.Factions.kill_goodwill(game.catalog,141)==24 and game.Factions.kill_goodwill(game.catalog,142)==85,"Rebel destroyer and cruiser scale with their hull mass")
 check(game.Factions.kill_goodwill(game.catalog,191)==0,"Escape pods grant no goodwill")
 game.free();await process_frame
 print("ENEMY KILL REPUTATION: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
