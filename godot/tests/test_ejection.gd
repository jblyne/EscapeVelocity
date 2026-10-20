extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
	else: print("PASS: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-ejection-test.json";game.traffic.enabled=false;game.muted=true;game.breakup_chance=0
	root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.restart()
	game.pilot.credits=100000
	for port in game.catalog.data.objects.values():
		if int(port.fields.TechLevel)>=2 and int(port.fields.Flags)&4:
			game.docked_id=int(port.id);break
	game.set_mode("outfitter")
	check(game.outfitter.trade(154,true) and game.outfitter.trade(181,true),"Both safety systems can be purchased and installed")
	game.restart()
	check(not game.ejection.begin(),"No manual ejection without a pod")
	game.pilot.outfits={"181":1};game.pilot.shield=0;game.pilot.armor=1;game.damage_player(10)
	check(game.mode=="dead","Auto-eject without pod cannot save pilot")
	game.restart();game.pilot.outfits={"154":1};game.pilot.shield=0;game.pilot.armor=1;game.damage_player(10)
	check(game.mode=="dead","Pod alone requires manual ejection")
	game.restart();game.pilot.outfits={"154":1,"181":1};game.pilot.campaign.bits=[44];game.pilot.campaign.completed=[172]
	game.pilot.cargo=[1,2,0,0,0,0];game.pilot.credits=98765
	var m: Dictionary=game.missions.offer(178,128);game.pilot.campaign.active.append(m)
	check(game.save_game(false),"Equipment saves before combat")
	var saved: String=FileAccess.get_file_as_string(game.save_path)
	var p=game.Pilot.new();check(p.restore(JSON.parse_string(saved),game.catalog),"Pod and auto-ejection restore")
	game.pilot.shield=0;game.pilot.armor=1;game.damage_player(10)
	check(game.mode=="ejecting" and is_instance_valid(game.ejection.pod),"Lethal hit launches visible pod")
	check(not game.save_game(false) and saved==FileAccess.get_file_as_string(game.save_path),"Ejection cannot overwrite living save")
	game.toggle_cheat_menu();check(game.mode=="ejecting","Cheats cannot interrupt ejection or bypass save protection")
	game.ejection.advance(4)
	check(game.mode=="rescue","Ejection transitions to rescue")
	var day: int=int(game.pilot.campaign.day)
	game.world_killer.state().destroyed.append(133)
	check(game.ejection.rescue_port()!=133,"Destroyed Levo redirects rescue to a surviving inhabited world")
	game.world_killer.state().destroyed.erase(133)
	game.pilot.reputation={"128":-500,"129":500};game.pilot.local_records={"128":-100}
	preload("res://scripts/interaction_history.gd").record(game.pilot,"world:128","threatened")
	var history: Dictionary=game.pilot.interaction_history.duplicate(true)
	game.pilot.fleet=[{"id":131,"hired":true,"wage":1800,"paid_day":day}]
	game.ejection.recover()
	check(game.mode=="dock" and game.pilot.ship_id==128 and game.pilot.armor>0,"Rescue supplies living shuttle at port")
	check(game.pilot.cargo_used()==0 and game.pilot.campaign.active.is_empty(),"Lost cargo fails active missions")
	check(game.pilot.outfit_count(154)==0 and game.pilot.outfit_count(181)==0,"Lost ship consumes safety equipment")
	check(game.pilot.credits==98765 and 44 in game.pilot.campaign.bits and 172 in game.pilot.campaign.completed,"Rescue retains credits and completed story")
	check(game.pilot.campaign.day==day+30 and game.docked_id==133,"Original rescue advances thirty days and returns to Levo")
	check(game.pilot.fleet.is_empty(),"Original rescue clears escort fleet without charging thirty days of phantom wages")
	check(game.pilot.local_records.is_empty() and game.pilot.reputation["128"]==int(game.catalog.field("governments",128,"InitialRec")),"Rescue erases criminal records to original starting values")
	check(game.pilot.interaction_history==history,"Legal reset preserves persistent interaction history")
	game.load_game();check(game.pilot.ship_id==128 and game.pilot.campaign.active.is_empty(),"Recovered pilot reloads")
	game.pilot.outfits={"154":1};game.ejection.request()
	check(game.mode=="eject_confirm","Manual shortcut requests deliberate confirmation")
	check(game.ejection.begin(),"Confirmed manual ejection works without auto system")
	game.load_game();check(game.mode=="flight" and not is_instance_valid(game.ejection.pod),"Loading cancels rescue animation")
	game.free();await process_frame
	print("EJECTION: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
