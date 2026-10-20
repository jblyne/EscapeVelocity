extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func travel(system: int) -> void:
	if system<0 or system==game.pilot.system_id: return
	var queue: Array=[game.pilot.system_id]
	var previous: Dictionary={game.pilot.system_id:-1}
	while not queue.is_empty() and not previous.has(system):
		var here: int=queue.pop_front()
		for next in game.catalog.system(here).links:
			if not previous.has(next): previous[next]=here;queue.append(next)
	check(previous.has(system),"reachable campaign system %d" % system)
	if not previous.has(system): return
	var route: Array=[];var at: int=system
	while previous[at]!=-1: route.push_front(at);at=previous[at]
	for next in route:
		game.missions.sync_actors()
		game.pilot.jump(next,game.catalog.system(game.pilot.system_id).links)
		game.missions.jumped();game.load_system();game.set_mode("flight")
func land(port: int) -> void:
	if port<0: return
	travel(game.missions.system_of(port))
	game.docked_id=port;game.set_mode("dock")
	game.missions.landed(port,true)
	while not game.missions.landing_reports.is_empty() or not game.missions.active_landing_report.is_empty():
		game.missions.show_next_landing_report();game.missions.dismiss_landing_report()
func run_chain(ids: Array, label: String, finale: int=61) -> void:
	game.restart();game.pilot.campaign.rating=20000
	game.pilot.ship_id=130;game.pilot.ship_fields=game.catalog.record("ships",130).fields.duplicate(true)
	game.pilot.outfits=game.Shipyard.stock_outfits(game.catalog,130);game.pilot.lasers=int(game.pilot.outfits.get("128",0));game.pilot.outfits.erase("128")
	game.pilot.shield=game.pilot.max_shield();game.pilot.armor=game.pilot.max_armor()
	# A qualified veteran pilot; progression bits/rewards are never injected.
	game.pilot.reputation={"128":3000,"129":3000};game.pilot.cheat_infinite_fuel=true
	for system in game.catalog.data.systems.values(): game.pilot.local_records[str(int(system.id))]=100
	for id in ids:
		var origin: int=-1
		for obj in game.catalog.data.objects.values():
			if game.missions.eligibility(id,int(obj.id),false): origin=int(obj.id);break
		check(origin>=0,label+" naturally unlocks mission %d" % id)
		if origin<0: return
		land(origin)
		for i in 1000:
			if game.missions.eligibility(id,origin): break
			game.pilot.campaign.visit+=1 # deterministic simulation of future offers
		game.missions.open()
		check(game.missions.accept(game.missions.offer(id,origin)),"accept mission %d through service" % id)
		if game.pilot.campaign.active.is_empty(): return
		var m: Dictionary=game.pilot.campaign.active.back()
		game.save_game(false);game.load_game();m=game.pilot.campaign.active.back()
		check(int(m.id)==id,"active mission survives disk reload %d" % id)
		var f: Dictionary=game.catalog.record("missions",id).fields
		if f.ShipCount>0:
			travel(int(m.ship_system));game.missions.enter_system();game.missions.advance(3.1)
			for npc in game.npcs.duplicate():
				if npc.get("mission_id",-1)!=id or npc.get("mission_aux",false): continue
				match int(f.ShipGoal):
					0,6: game.damage_npc(npc,npc.health+1)
					1,2,5:
						if not npc.disabled: game.damage_npc(npc,npc.health-maxf(1,(npc.max_health-npc.shield_capacity)*.5))
						if int(f.ShipGoal) in [2,5]:
							game.pilot.position=npc.position;game.pilot.heading=npc.heading;game.velocity=npc.velocity
							game.target_index=game.npcs.find(npc);game.set_mode("flight")
							check(game.interactions.board(),"board real mission actor %d" % id)
							game.set_mode("flight")
		land(int(m.dest));land(int(m.back) if int(m.back)>=0 else int(m.dest))
		check(id in game.pilot.campaign.completed and game.pilot.campaign.active.is_empty(),"complete campaign step %d" % id)
		if not game.pilot.campaign.active.is_empty(): return
		game.save_game(false);game.load_game()
		check(id in game.pilot.campaign.completed,"completed campaign step persists %d" % id)
	check(finale in game.pilot.campaign.bits,label+" reaches final progression bit")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-campaign-route.json")
	game.traffic.enabled=false;game.muted=true;game.breakup_chance=0.0
	root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	run_chain([172,163,164,165,184,185,186,187,188,189],"Rebel")
	check(game.pilot.outfit_count(167)==1,"Rebel route retains earned cloak")
	run_chain([171,166,167,168,169,170,190,191,192,193,194],"Confederation")
	check(game.pilot.outfit_count(166)==1 and 66 in game.pilot.campaign.bits,"Confederation route retains beam and faction clearance")
	run_chain([152,153,154,155,156],"Environmental investigation",28)
	run_chain([173,174,175,176,177],"Starbound Shipping",47)
	run_chain([178,179,180,181,182,183],"Colony assistance",52)
	run_chain([209,210,211,212,213,214,215,216,217,218,219],"UGE",79)
	check(78 not in game.pilot.campaign.bits,"UGE redemption restores membership")
	run_chain([172,230,231,232,233,234,235],"Astrodyne",107)
	check(game.pilot.outfit_count(173)==1,"Astrodyne awards tractor beam")
	run_chain([236,237,238,239,240,241],"Artemis bounty hunters",113)
	run_chain([171,242,243],"Escort carrier operations",114)
	game.free();await process_frame
	print("CAMPAIGN ROUTES: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
