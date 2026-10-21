extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func dock(port: int) -> void:
	game.pilot.system_id=game.missions.system_of(port)
	game.load_system()
	game.docked_id=port
	game.set_mode("dock")
func accept(id: int, port: int) -> Dictionary:
	dock(port)
	for i in 1000:
		if game.missions.eligibility(id,port): break
		game.pilot.campaign.visit+=1
	game.missions.open()
	var m: Dictionary=game.missions.offer(id,port)
	check(game.missions.accept(m),"accept original mission %d" % id)
	return game.pilot.campaign.active.back() if not game.pilot.campaign.active.is_empty() else {}
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-mission-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	var service=game.missions
	check(game.catalog.data.missions.size()==116,"all original mission records imported")
	for record in game.catalog.data.missions.values():
		var port: int=128
		for obj in game.catalog.data.objects.values():
			if service.port_matches(int(record.fields.AvailStel),int(obj.id)): port=int(obj.id);break
		var m: Dictionary=service.offer(int(record.id),port)
		check((m.dest<0 or not game.catalog.record("objects",int(m.dest)).is_empty()) and (m.back<0 or not game.catalog.record("objects",int(m.back)).is_empty()) and (record.fields.ShipCount<=0 or not game.catalog.system(int(m.ship_system)).is_empty()),"resolved destinations: %d" % record.id)
	check(service.port_matches(10000,128) and not service.port_matches(10001,128),"faction-specific offer locations")
	check(not service.bit_matches(44) and service.bit_matches(1044),"set and clear prerequisite bits")
	service.apply_bit(44);check(service.bit_matches(44) and not service.bit_matches(1044),"progress unlocks and excludes opposing missions")
	service.apply_bit(1044)
	game.pilot.campaign.rating=20000
	game.pilot.reputation={"128":1500,"129":1500}
	var m: Dictionary=accept(172,161)
	var back: int=int(m.back)
	service.landed(back)
	check(44 in game.pilot.campaign.bits and game.pilot.credits==15000,"rebel introduction pays and unlocks membership")
	check(not service.eligibility(171,128,false),"opposing faction introduction excluded")
	m=accept(163,161)
	service.landed(161)
	check(35 in game.pilot.campaign.bits,"special ops prerequisite completed")
	m=accept(164,161)
	check(game.pilot.outfit_count(167)==1 and m.prepaid,"cloak granted at acceptance")
	game.set_mode("flight")
	check(game.cloak.toggle(),"installed cloak engages")
	var shield: float=game.pilot.shield
	var fuel: float=game.pilot.fuel
	game.cloak.advance(1)
	check(game.pilot.shield==shield-8 and game.pilot.fuel==fuel-2,"cloak consumes shield power and fuel")
	game.cooldown=0
	game.pilot.cheat_cloak=false
	check(not game.fire_player() and game.cooldown==0 and game.cloak.active,"mission cloak blocks firing without consuming reload")
	game.pilot.cheat_cloak=true
	check(game.fire_player() and game.cloak.active,"cloak cheat allows firing with installed mission device")
	check(not game.fire_player() and game.cloak.active,"cloaked weapons retain reload timing")
	game.cooldown=0
	game.pilot.cheat_cloak=false
	check(not game.fire_player() and game.cloak.active,"disabling cloak cheat immediately restores weapon restriction")
	var npc: Dictionary=game.traffic.spawn(134,128,4,game.pilot.position+Vector2(100,0))
	npc.provoked=true;npc.hostile=true
	check(not game.traffic.opponent(npc).get("player",false),"cloaked player cannot be targeted")
	service.abort(m)
	check(m in service.state().active,"Original non-abortable flag protects the insertion assignment")
	service.finish(m,false,false,false,"Mission cargo was discovered.")
	check(game.pilot.outfit_count(167)==0 and not game.cloak.active and 36 not in game.pilot.campaign.bits,"Failure removes loaned cloak without awarding progress")
	m=accept(164,161)
	service.landed(130)
	check(36 not in game.pilot.campaign.bits,"cannot skip insertion destination")
	service.landed(132);service.landed(130)
	check(36 in game.pilot.campaign.bits and game.pilot.outfit_count(167)==1,"successful insertion retains cloak")
	var saved: Dictionary=game.pilot.snapshot()
	var restored=game.Pilot.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(saved)),game.catalog) and 36 in restored.campaign.bits and restored.outfit_count(167)==1,"mission bits and cloak survive JSON save roundtrip")
	var invalid: Dictionary=saved.duplicate(true);invalid.campaign.bits=[999]
	check(not restored.restore(invalid,game.catalog) and 36 in restored.campaign.bits,"corrupt campaign rejected atomically")
	game.pilot.campaign.bits=[41]
	m=accept(170,167)
	check(service.target_system(m)==int(m.ship_system),"mission arrow prioritizes an unfinished ship objective")
	game.pilot.system_id=int(m.ship_system);game.load_system();game.set_mode("flight");game.missions.advance(3.1)
	var target: Dictionary={}
	for contact in game.npcs:
		if contact.get("mission_id",-1)==170 and not contact.mission_aux: target=contact
	check(not target.is_empty(),"mission freighter spawned in original target system")
	service.landed(139)
	check(game.pilot.outfit_count(166)==0,"reward withheld until stolen beam recovered")
	target.disabled=true;target.heading=game.pilot.heading;game.velocity=Vector2.ZERO;target.velocity=Vector2.ZERO;target.position=game.pilot.position+Vector2(20,0)
	game.target_index=game.npcs.find(target)
	check(game.interactions.board(),"real boarding action recovers mission cargo")
	check(service.target_system(m)==service.system_of(int(m.back)),"mission arrow advances to the return system after boarding")
	service.landed(139)
	check(game.pilot.outfit_count(166)==1 and 142 in game.arsenal.available_ids() and 42 in game.pilot.campaign.bits,"particle beam reward becomes usable weapon")
	var credits: int=game.pilot.credits
	service.landed(139)
	check(game.pilot.credits==credits and game.pilot.outfit_count(166)==1,"completion reward cannot repeat")
	game.pilot.campaign.bits=[60]
	m=accept(189,161)
	game.pilot.system_id=int(m.ship_system);game.load_system();game.set_mode("flight");game.missions.advance(3.1)
	for contact in game.npcs.duplicate():
		if contact.get("mission_id",-1)==189 and not contact.mission_aux: game.damage_npc(contact,contact.health+1)
	service.landed(161)
	check(61 in game.pilot.campaign.bits and game.pilot.credits==credits+10000000,"alien cruiser victory pays and unlocks military equipment")
	game.docked_id=161
	check(game.outfitter.available_here(144),"mass driver available at cleared Rebel port")
	game.docked_id=128
	check(not game.outfitter.available_here(144),"mission clearance does not bypass local technology")
	game.pilot.campaign.bits=[106]
	m=accept(235,161)
	game.pilot.system_id=int(m.ship_system);game.load_system();game.set_mode("flight");game.missions.advance(3.1)
	for contact in game.npcs:
		if contact.get("mission_id",-1)==235 and not contact.mission_aux: service.actor_event(contact,"board")
	service.landed(161)
	check(game.pilot.outfit_count(173)==1 and 149 in game.arsenal.available_ids(),"Astrodyne mission grants functional tractor beam")
	m=accept(135,128)
	game.pilot.campaign.day=int(m.deadline)
	service.jumped()
	check(m not in game.pilot.campaign.active,"expired deadline fails mission")
	m=accept(130,128)
	check(service.target_system(m)==service.system_of(int(m.dest)),"accepted travel mission points to its destination system")
	check(service.map_markers().get(service.target_system(m),0)==1,"accepted mission creates one galaxy-map arrow")
	saved=game.pilot.snapshot()
	check(restored.restore(JSON.parse_string(JSON.stringify(saved)),game.catalog) and restored.campaign.active.size()==1,"active mission destinations and stage persist")

	# Exercise every source objective combination, including random deliveries that
	# finish at TravelStel when ReturnStel is absent. Eligibility is tested above.
	for record in game.catalog.data.missions.values():
		game.pilot.campaign=game.Pilot.CampaignState.fresh()
		game.pilot.outfits.clear()
		var origin: int=128
		for obj in game.catalog.data.objects.values():
			if service.port_matches(int(record.fields.AvailStel),int(obj.id)): origin=int(obj.id);break
		var task: Dictionary=service.offer(int(record.id),origin)
		game.pilot.campaign.active.append(task)
		game.pilot.system_id=int(task.ship_system) if task.ship_system>=0 else service.system_of(origin)
		game.load_system();game.set_mode("flight");game.missions.advance(3.1)
		for contact in game.npcs.duplicate():
			if contact.get("mission_id",-1)!=int(task.id) or contact.get("mission_aux",false): continue
			match int(record.fields.ShipGoal):
				0,6: game.damage_npc(contact,contact.health+1)
				1: service.actor_event(contact,"disable")
				2,5: service.actor_event(contact,"board")
		if task.dest>=0: service.landed(int(task.dest))
		service.landed(int(task.back) if task.back>=0 else (int(task.dest) if task.dest>=0 else origin))
		check(task not in game.pilot.campaign.active,"objective lifecycle: %d" % record.id)
	game.pilot.campaign=game.Pilot.CampaignState.fresh()
	m=accept(130,128)
	var expected_text: String=service.text_for(m,"CompText")
	game.pilot.system_id=service.system_of(int(m.dest))
	game.load_system();game.set_mode("flight");game.missions.advance(3.1)
	for planet in game.planets:
		if int(planet.id)==int(m.dest):
			game.pilot.position=planet.position
			game.landing_target=int(planet.id);game.landing_clearance=int(planet.id)
	game.velocity=Vector2.ZERO
	game.land()
	check(game.mode=="mission_report","landing at mission destination immediately opens report")
	check(service.active_landing_report.get("body","")==expected_text,"arrival report uses original completion narrative")
	var dismiss=game.hud.modal_root.find_child("DismissMissionReport",true,false)
	check(dismiss!=null,"arrival report provides Okay button")
	check(dismiss is Button and dismiss.text=="Okay","report uses original Okay caption")
	var narrative=game.hud.modal_root.find_child("MissionReportNarrative",true,false)
	check(narrative is RichTextLabel and narrative.text==expected_text,"classic dialog retains full original narrative")
	check(narrative is RichTextLabel and not narrative.fit_content,"long reports remain scrollable within dialog")
	if "--visual" in OS.get_cmdline_user_args():
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/mission-popup.png"))
	if dismiss!=null: dismiss.pressed.emit()
	check(game.mode=="dock","Okay opens destination spaceport")
	game.free();await process_frame
	print("MISSIONS RESULT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
