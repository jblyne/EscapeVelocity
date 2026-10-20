extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func clear() -> void:
	game.interactions.close()
	for npc in game.npcs.duplicate(): game.traffic.retire(npc)
	game.pilot.campaign.active=[]
	game.pilot.persons={"gone":[],"grudges":[]}
func eligible_system(id: int) -> bool:
	for system in game.catalog.data.systems:
		game.pilot.system_id=int(system)
		if game.persons.eligible(id): return true
	return false
func hull(id: int) -> void:
	game.pilot.ship_id=id;game.pilot.ship_fields=game.catalog.record("ships",id).fields.duplicate()
	game.pilot.outfits=game.Shipyard.stock_outfits(game.catalog,id)
	game.pilot.lasers=int(game.pilot.outfits.get("128",0));game.pilot.outfits.erase("128")
	game.pilot.shield=game.pilot.max_shield();game.pilot.armor=game.pilot.max_armor()
func hail(npc: Dictionary) -> void:
	game.set_mode("flight");game.target_index=game.npcs.find(npc);game.interactions.open_hail()
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-person-roster-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	game.pilot_ready=true;game.set_mode("flight");game.pilot.cheat_infinite_fuel=true
	game.pilot.campaign.bits=[42,61,114]
	game.pilot.reputation["128"]=-100
	var spawned=0
	for key in game.catalog.data.persons:
		var id: int=int(key)
		if id!=639: check(eligible_system(id),"Eligible location exists for source person %d" % id)
		var npc: Dictionary=game.persons.spawn(id)
		check(not npc.is_empty(),"Instantiate original person %d" % id)
		if npc.is_empty(): continue
		spawned+=1
		check(npc.name==game.catalog.record("persons",id).name,"Original identity %d" % id)
		check(npc.id==int(game.catalog.record("persons",id).fields.ShipType),"Original hull %d" % id)
		game.traffic.retire(npc)
	check(spawned==220,"Every original record including Hector and bounty hunter instantiated")
	clear();eligible_system(128)
	var red: Dictionary=game.persons.spawn(128)
	check(red.weapons.any(func(w):return w.id==134 and w.count==2) and not red.weapons.any(func(w):return w.id==133),"Redbeard has source turret replacement")
	var full: float=red.health
	var armor: float=game.catalog.field("ships",red.id,"Armor")
	red.health=armor+red.shield_capacity*.24
	var position: Vector2=red.position;var fuel: float=red.fuel
	game.traffic.update(.5)
	check(red.person_retreat and red.position!=position and red.fuel<fuel,"Redbeard retreats under shield threshold with afterburner")
	red.health=full;red.person_retreat=false
	game.damage_npc(red,1)
	check(128 in game.pilot.persons.grudges,"Attack creates persistent named grudge")
	game.damage_npc(red,red.health+1)
	var pods: Array=game.npcs.filter(func(n):return n.get("escape_owner",-1)==128)
	check(pods.size()==1 and not game.persons.eligible(128),"Redbeard ejects; live pod prevents duplicate captain")
	game.damage_npc(pods[0],pods[0].health+1)
	check(128 in game.pilot.persons.gone,"Destroying escape pod permanently removes captain")
	clear();eligible_system(219)
	var matt: Dictionary=game.persons.spawn(219)
	check(is_equal_approx(matt.shield_capacity,float(game.catalog.field("ships",143,"Shield"))*100),"Matt Burch retains original extreme shields")
	check(game.persons.quote(matt).contains("three in the morning"),"Matt Burch's original dialogue")
	matt.hostile=true;matt.position=game.pilot.position+Vector2(800,0)
	check(game.traffic.opponent(matt).is_empty(),"Low aggression captain does not acquire distant player")
	matt.position=game.pilot.position+Vector2(200,0)
	check(game.traffic.opponent(matt).get("player",false),"Low aggression captain engages inside his range")
	check(game.persons.broadcast(matt,true),"Attack-triggered original radio taunt")
	check(not game.persons.broadcast(matt,true),"Radio cooldown prevents per-frame spam")
	clear();eligible_system(194)
	var merchant: Dictionary=game.persons.spawn(194)
	merchant.hostile=false;merchant.radio_timer=0;merchant.radio_spoken=false
	check(game.persons.broadcast(merchant),"Friendly merchant greeting")
	merchant.radio_timer=0
	check(not game.persons.broadcast(merchant),"Once-only flag suppresses repeated broadcasts")
	game.world_activity.activate(138,int(game.pilot.campaign.day));hail(merchant)
	check(game.interactions.response.contains("wing-racing"),"News-sharing captain provides active disaster information")
	clear();eligible_system(242)
	var trap: Dictionary=game.persons.spawn(242)
	game.target_index=game.npcs.find(trap);game.pilot.position=trap.position;game.pilot.heading=trap.heading;game.velocity=Vector2.ZERO
	check(game.interactions.board(),"Actually board the distress-call ship")
	game.missions.advance(3.1)
	check(game.mode=="flight" and game.npcs.filter(func(n):return n.get("mission_id",-1)==195).size()==4,"Boarding automatically triggers original pirate ambush")
	check(242 in game.pilot.persons.gone and game.pilot.campaign.active.is_empty(),"One-time trap deactivates without occupying mission slot")
	clear();hull(132);game.pilot.campaign.rating=20000
	# Exercise every distinct linked mission through the real communications/boarding UI.
	var covered: Array=[]
	for mission in [195,196,197,198,199,201,202]:
		clear()
		for govt in game.catalog.data.governments: game.pilot.reputation[govt]=-10 if mission==201 else 3000
		for system in game.catalog.data.systems: game.pilot.local_records[system]=-1 if mission==201 else 0
		var chosen: Dictionary={}
		for id in game.catalog.data.persons:
			if int(game.catalog.data.persons[id].fields.LinkMission)!=mission: continue
			if not eligible_system(int(id)): continue
			var candidate: Dictionary=game.persons.spawn(int(id))
			for visit in 30:
				game.pilot.campaign.visit=visit
				if not game.persons.linked_offer(candidate,bool(int(candidate.person_flags)&512)).is_empty(): chosen=candidate;break
			if not chosen.is_empty(): break
			game.traffic.retire(candidate)
		check(not chosen.is_empty(),"Source-linked mission %d has an eligible captain" % mission)
		if chosen.is_empty(): continue
		game.target_index=game.npcs.find(chosen)
		if int(chosen.person_flags)&512:
			game.pilot.position=chosen.position;game.pilot.heading=chosen.heading;game.velocity=Vector2.ZERO
			game.interactions.board()
		else: hail(chosen)
		if mission==198:
			game.pilot.cargo[0]=game.pilot.cargo_capacity()
			game.persons.accept_offer()
			check(game.pilot.campaign.active.is_empty() and not chosen.get("person_mission_accepted",false),"Full hold rejects named cargo contract without consuming encounter")
			game.pilot.cargo[0]=0
			game.persons.show_offer(chosen,false)
		if game.mode in ["comms","boarding"]: game.persons.accept_offer()
		if int(chosen.person_flags)&2048 and mission not in [195,196]: check(chosen.get("person_departing",false),"Accepted courier departs according to source flag")
		if mission in [195,196]:
			game.missions.advance(3.1)
			check(game.npcs.any(func(n):return n.get("mission_id",-1)==mission),"Boarding trap starts mission actors %d" % mission)
		else:
			check(game.pilot.campaign.active.any(func(m):return int(m.id)==mission),"Accept source contract %d" % mission)
		covered.append(mission)
		if mission==199:
			var identity: int=int(chosen.person_id)
			game.missions.sync_actors();game.save_game(false)
			check(game.pilot.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)),game.catalog),"Named escort persists through real save file")
			game.load_system();game.missions.enter_system()
			var escorts: Array=game.npcs.filter(func(n):return n.get("person_id",-1)==identity)
			check(escorts.size()==1 and escorts[0].name==game.catalog.record("persons",identity).name,"Escort retains identity after system reconstruction")
			check(not game.persons.eligible(identity),"Active named escort cannot spawn a duplicate")
		if mission not in [195,196] and not game.pilot.campaign.active.is_empty():
			var contract: Dictionary=game.pilot.campaign.active[0]
			var dest: int=int(contract.back if contract.back>=0 else contract.dest)
			var route: Array=path_to(game.missions.system_of(dest))
			for system in route:
				check(game.pilot.jump(system,game.catalog.system(game.pilot.system_id).links),"Travel toward named contract destination")
				game.missions.jumped();game.load_system()
			game.set_mode("flight");game.landing_target=dest
			game.pilot.position=game.selected_planet().position;game.velocity=Vector2.ZERO
			game.land();game.land()
			check(game.mode=="dock" or game.mode=="mission_report","Land at named contract destination %d" % mission)
			check(mission in game.pilot.campaign.completed,"Complete named contract %d" % mission)
			if mission==201: check(73 in game.pilot.campaign.bits,"Kestrel parts story grants original alternate-Kestrel unlock")
	check(covered.size()==7,"All seven original ship-linked missions exercised")
	clear();hull(128);eligible_system(278)
	var courier: Dictionary=game.persons.spawn(278)
	check(game.persons.linked_offer(courier,false).is_empty(),"Courier respects original player ship-class exclusion")
	clear();eligible_system(153)
	var rebel: Dictionary=game.persons.spawn(153)
	rebel.hostile=false;rebel.provoked=false;rebel.radio_timer=0;rebel.radio_spoken=false
	check(game.persons.broadcast(rebel),"Combined friendly/grudge flags allow a friendly Rebel's radio call")
	game.persons.captured(rebel)
	check(153 in game.pilot.persons.gone,"Captured special person cannot respawn a duplicate hull")
	game.pilot.local_records[str(game.pilot.system_id)]=-3
	game.pilot.persons.grudges.append(128)
	game.save_game(false)
	check(game.pilot.restore(JSON.parse_string(FileAccess.get_file_as_string(game.save_path)),game.catalog),"Character and local legal state survives disk reload")
	check(153 in game.pilot.persons.gone and 128 in game.pilot.persons.grudges,"Deactivated characters and grudges remain persisted")
	var bad: Dictionary=game.pilot.snapshot();bad.local_records={"99999":-1}
	check(not game.pilot.restore(bad,game.catalog),"Invalid local legal record rejected")
	game.queue_free();await process_frame
	print("PERSON ROSTER: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)

func path_to(destination: int) -> Array:
	var queue: Array=[game.pilot.system_id]
	var previous: Dictionary={game.pilot.system_id:-1}
	while not queue.is_empty():
		var system: int=queue.pop_front()
		if system==destination: break
		for next in game.catalog.system(system).links:
			if not previous.has(next): previous[next]=system;queue.append(next)
	var route: Array=[]
	var current: int=destination
	while current!=game.pilot.system_id and previous.has(current):
		route.push_front(current);current=int(previous[current])
	return route
