extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
	else: print("PASS: "+message)
func _initialize() -> void: call_deferred("run")
func travel(port: int) -> void:
	game.pilot.system_id=game.missions.system_of(port)
	game.load_system();game.set_mode("flight")
	game.landing_target=port
	var body: Dictionary=game.selected_planet()
	game.pilot.position=body.position;game.velocity=Vector2.ZERO
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-world-activity-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game);game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	game.pilot_ready=true
	var world=game.world_activity
	check(game.catalog.data.events.size()==52,"Import all 52 original world event records")
	world.activate(138,0)
	var f: Dictionary=game.catalog.record("events",138).fields
	var port: int=int(f.Stellar)
	var base: Array=game.catalog.prices(port)
	var expected_price: int=(base[0] if base[0]>=0 else int(game.catalog.data.commodities[0].base_price))+100
	check(world.prices(port)[0]==expected_price,"Festival increases affected food price")
	check(world.prices(128)==game.catalog.prices(128),"Other worlds retain base prices")
	game.docked_id=port;game.set_mode("dock")
	var credits: int=game.pilot.credits
	game.trade(0,true)
	check(game.pilot.credits==credits-expected_price and game.pilot.cargo[0]==1,"Actual exchange purchase uses event price")
	game.trade(0,false)
	check(game.pilot.credits==credits,"Buy and sell share the same event price")
	check(world.headlines(port)[0].contains("wing-racing"),"Local economic news appears first")
	game.hud.modal_root.find_child("OpenSpaceportBar",true,false).pressed.emit()
	check(game.hud.modal_root.find_child("OpenNews",true,false)!=null,"Spaceport bar exposes news")
	world.open_news()
	check(game.mode=="news","News opens from port")
	game.pilot.campaign.day=7;world.sync()
	check(not game.pilot.world_state.events.any(func(e):return e.id==138),"Expired event removed on day advance")
	game.pilot.campaign.bits.append(42);world.sync()
	check(game.pilot.world_state.events.any(func(e):return e.id==128),"Mission completion triggers original story news")
	var event_count: int=game.pilot.world_state.events.size();world.sync()
	check(game.pilot.world_state.events.size()==event_count,"News refresh does not reroll events")
	travel(128)
	game.pilot.reputation["128"]=-100
	game.land();game.land()
	check(game.mode=="flight" and game.landing_clearance==-1,"Bad reputation refuses actual landing")
	game.pilot.reputation["128"]=0;game.land()
	check(game.landing_clearance==128,"Restored reputation grants clearance")
	game.pilot.reputation["128"]=-100;game.land()
	check(game.mode=="flight" and game.landing_clearance==-1,"Clearance revoked if reputation worsens during approach")
	game.pilot.reputation["128"]=0;game.land();game.land()
	check(game.mode=="dock","Eligible pilot can land normally")
	check(world.defense_counts(128)==Vector2i(3176,5),"Encoded large defense fleet decoded into bounded waves")
	# Alkaidion has six original defenders in waves of two; use actual damage and boarding states.
	travel(163);world.open_contact()
	check(game.mode=="world_comms" and game.hud.modal_root.find_child("DemandTribute",true,false)!=null,"Hailing a world exposes tribute action")
	world.demand()
	check(game.mode=="flight" and not world.siege.is_empty() and world.siege.pending==2,"Tribute demand launches source defense fleet")
	check(not world.demand_reason(128).is_empty(),"Cannot start overlapping conquest battles")
	var pending: int=world.siege.pending
	game.set_mode("pause");game._physics_process(10)
	check(world.siege.pending==pending,"Pausing freezes defense battle progression")
	game.set_mode("flight")
	check(not world.landing_reason(163).is_empty(),"Active defense battle blocks landing")
	var before: int=game.pilot.credits
	for wave in 3:
		for npc in game.npcs.duplicate():
			if npc.get("defense_port",-1)==163: game.damage_npc(npc,npc.health+1)
		world.advance(4)
	check(163 in game.pilot.world_state.dominated and world.siege.is_empty(),"Defeating fleet conquers world")
	check(game.pilot.credits==before,"Conquest does not immediately pay tribute")
	game.pilot.campaign.day+=1;world.sync()
	check(game.pilot.credits==before+world.tribute(163),"Conquered world pays daily tribute")
	var prior: int=game.pilot.credits
	var day_before: int=game.pilot.campaign.day
	game.missions.jumped()
	check(game.pilot.credits==prior+(int(game.pilot.campaign.day)-day_before)*world.tribute(163),"Actual jump progression pays tribute for elapsed travel days")
	var paid: int=game.pilot.credits;world.sync()
	check(game.pilot.credits==paid,"Repeated sync cannot duplicate tribute")
	var govt: int=int(game.catalog.field("objects",163,"Govt"));game.pilot.reputation[str(govt)]=-999
	check(world.landing_reason(163).is_empty(),"Dominated world allows landing despite poor reputation")
	game.save_game(false)
	check(game.pilot.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)),game.catalog),"World state restores from actual JSON save")
	world.sync();check(game.pilot.credits==paid and 163 in game.pilot.world_state.dominated,"Save/reload preserves conquest without duplicate payment")
	world.open_contact();world.release()
	check(163 not in game.pilot.world_state.dominated,"Release ends tribute obligation")
	game.pilot.campaign.day+=1;world.sync()
	check(game.pilot.credits==paid,"Released world no longer pays")
	world.demand();check(not world.siege.is_empty(),"Released world can be challenged again")
	for wave in 3:
		for npc in game.npcs:
			if npc.get("defense_port",-1)==163: game.interactions.disable(npc,false)
		world.advance(4)
	check(163 in game.pilot.world_state.dominated,"Disabling all defenders also secures tribute")
	world.open_contact();world.release();world.demand()
	game.load_system()
	check(world.siege.is_empty() and 163 not in game.pilot.world_state.dominated,"Leaving/reloading abandons unfinished battle")
	var invalid: Dictionary=game.pilot.snapshot();invalid.world.dominated=[99999]
	check(not game.pilot.restore(invalid,game.catalog),"Invalid conquered-world save rejected")
	invalid=game.pilot.snapshot();invalid.world.events=[{"id":138,"until":"forever"}]
	check(not game.pilot.restore(invalid,game.catalog),"Malformed event duration rejected")
	var legacy: Dictionary=game.pilot.snapshot();legacy.erase("world")
	check(game.pilot.restore(legacy,game.catalog),"Legacy save loads without world extension")
	check(game.pilot.world_state.day==game.pilot.campaign.day,"Legacy save does not retroactively accrue world history")
	game.queue_free();await process_frame
	print("WORLD ACTIVITY: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
