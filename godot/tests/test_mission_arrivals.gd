extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func setup_mission(id: int) -> Dictionary:
	game.restart()
	var mission: Dictionary=game.missions.offer(id,128)
	game.pilot.campaign.active.append(mission)
	game.pilot.system_id=int(mission.ship_system);game.load_system()
	return mission
func contacts(id: int) -> Array:
	return game.npcs.filter(func(n):return n.get("mission_id",-1)==id and not n.get("mission_aux",false))
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-mission-arrivals.json"
	game.traffic.enabled=false;game.muted=true;game.breakup_chance=0
	root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	var mission: Dictionary=setup_mission(147)
	check(contacts(147).is_empty() and not mission.met,"Delayed defense attackers do not appear instantly")
	game.missions.advance(2)
	check(contacts(147).is_empty(),"Arrival waits for flight time")
	game.missions.advance(1.1)
	check(contacts(147).size()==int(game.catalog.field("missions",147,"ShipCount")),"Attackers jump in after delay")
	var count: int=contacts(147).size();game.missions.advance(10)
	check(contacts(147).size()==count,"Repeated updates cannot duplicate arriving ships")
	for npc in contacts(147):
		npc.health=npc.max_health*.3;npc.position=game.pilot.position+Vector2(1900,0)
	game.traffic.update(9)
	check(not contacts(147).is_empty() and contacts(147).all(func(n):return n.has("departure")),"Chase-off enemies begin real hyperdrive departures instead of disappearing")
	for tick in 9000:
		if contacts(147).is_empty(): break
		game.traffic.update(1.0/60)
	check(contacts(147).is_empty() and game.missions.ship_goal_done(mission),"Wounded chase-off targets flee and satisfy goal")
	game.save_game(false);game.load_game();game.missions.advance(4)
	check(contacts(147).is_empty(),"Escaped objectives remain resolved after reload")
	mission=setup_mission(145);var targets: Array=contacts(145)
	check(not targets.is_empty(),"Normal encounters appear immediately")
	if not targets.is_empty(): game.missions.actor_event(targets[0],"escape")
	check(game.pilot.campaign.active.is_empty() and 145 not in game.pilot.campaign.completed,"Escaping kill target fails rather than awards a kill")
	mission=setup_mission(170);game.missions.advance(4)
	if not contacts(170).is_empty(): game.missions.actor_event(contacts(170)[0],"escape")
	check(game.pilot.campaign.active.is_empty(),"Unboarded target escape fails retrieval")
	mission=setup_mission(151);game.missions.advance(4)
	check(contacts(151).all(func(n):return n.mission_escort and n.truce),"Delayed escorts protect the player")
	mission=setup_mission(145)
	var auxiliaries: Callable=func(): return game.npcs.filter(func(n):return n.get("mission_id",-1)==145 and n.get("mission_aux",false))
	var delay: float=game.missions.auxiliary_delays[145]
	check(delay>=70.0/60 and delay<=139.0/60 and auxiliaries.call().is_empty(),"Auxiliary wave starts with source random counter range")
	game.missions.advance(delay*.5)
	check(auxiliaries.call().is_empty(),"Auxiliaries wait independently of immediate main targets")
	game.missions.advance(delay*.5+.01)
	check(auxiliaries.call().size()==2,"Auxiliary wave arrives after its counter expires")
	game.missions.advance(4)
	check(auxiliaries.call().size()==2,"Repeated updates do not duplicate auxiliary wave")
	var destroyed: Dictionary=auxiliaries.call()[0]
	game.missions.actor_event(destroyed,"kill");game.traffic.retire(destroyed)
	game.save_game(false);game.load_game()
	mission=game.pilot.campaign.active[0]
	check(auxiliaries.call().is_empty(),"Reload starts a fresh arrival window")
	game.missions.advance(3)
	check(auxiliaries.call().size()==1,"Reload preserves destroyed finite auxiliaries")
	game.load_system()
	check(auxiliaries.call().is_empty() and game.missions.auxiliary_delays[145]>0,"New system encounter resets auxiliary delay")
	game.missions.advance(3)
	game.traffic.refresh_after_landing()
	check(game.missions.auxiliary_delays.is_empty(),"Landing traffic refresh clears auxiliary counters")
	game.missions.enter_system()
	game.missions.finish(mission,false)
	check(not game.missions.auxiliary_delays.has(145),"Finished contracts release their encounter counters")
	game.free();await process_frame
	print("MISSION ARRIVALS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
