extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func land_at(port: int) -> void:
	game.pilot.system_id=game.missions.system_of(port);game.load_system();game.set_mode("flight")
	for body in game.planets:
		if int(body.id)==port: game.pilot.position=body.position
	game.landing_target=port;game.landing_clearance=port;game.velocity=Vector2.ZERO;game.land()
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-port-trigger-pilot.json";game.controls.path="/tmp/ev-port-trigger-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.pilot.local_records[str(game.missions.system_of(176))]=100
	var before_visit: int=int(game.pilot.campaign.visit)
	land_at(176)
	check(game.mode=="dock" and game.pilot.campaign.visit==before_visit,"Physical landing does not reroll original bar encounter chance")
	for attempt in 1000:
		if game.missions.eligibility(152,176): break
		game.pilot.campaign.visit+=1
	var page=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	page.find_child("OpenSpaceportBar",true,false).pressed.emit()
	check(game.mode=="dock" and game.missions.approach.is_empty(),"Bar entry displays the bar before any approach")
	var rolls: Dictionary=game.missions.bar_rolls.duplicate()
	for i in 180:
		game.missions.advance_bar(1.0/60)
		if game.mode=="mission_offer": break
	check(game.mode=="mission_offer" and int(game.missions.approach.get("id",-1))==152,"Entering actual bar triggers the eligible environmental story approach")
	var narrative=game.hud.modal_root.find_child("ApproachNarrative",true,false)
	check(narrative!=null and narrative.text.begins_with(game.missions.text_for(game.missions.approach,"offer")),"Approach displays original offer prose")
	var money: int=game.pilot.credits
	game.missions.resolve_approach(false)
	check(game.mode=="dock" and game.hud.port_page=="bar" and game.pilot.campaign.active.is_empty() and game.pilot.credits==money,"Declining returns to bar without starting or paying a mission")
	game.missions.begin_bar_approach()
	check(game.missions.bar_rolls==rolls,"Re-entering the same bar retains its original encounter chance rolls")
	for i in 180:
		game.missions.advance_bar(1.0/60)
		if game.mode=="mission_offer": break
	check(game.missions.approach.is_empty() or int(game.missions.approach.id)!=152,"Same contact does not repeatedly approach during one landing visit")
	game.missions.approach={};game.set_mode("dock");game.missions.begin_port_visit()
	check(game.missions.bar_rolls==rolls,"Landing again retains same-port bar encounter rolls")
	land_at(128);game.hud.port_page="bar";game.missions.begin_bar_approach()
	check(game.missions.bar_port==128,"Visiting another bar selects a new encounter pool")
	land_at(176);game.hud.port_page="bar"
	for attempt in 1000:
		if game.missions.eligibility(152,176): break
		game.pilot.campaign.visit+=1
	game.missions.begin_bar_approach()
	game.hud.port_page="landing";game.missions.advance_bar(30)
	check(game.mode=="dock" and game.missions.approach.is_empty(),"Idle approaches cannot trigger outside the bar")
	game.hud.port_page="bar"
	for i in 180:
		game.missions.advance_bar(1.0/60)
		if game.mode=="mission_offer": break
	var expected: String=game.missions.text_for(game.missions.approach,"BriefText")
	game.hud.modal_root.find_child("AcceptApproach",true,false).pressed.emit()
	check(game.pilot.campaign.active.any(func(m):return int(m.id)==152),"Accept starts the original story mission through the real dialog")
	check(game.mode=="mission_report" and game.missions.active_landing_report.body==expected,"Acceptance shows the original mission briefing")
	game.missions.dismiss_landing_report()
	check(game.mode=="dock" and game.hud.port_page=="bar","Briefing returns to the bar")
	# Complete an actual delivery using the real landing command, then drain reports.
	game.pilot.campaign.active=[];game.missions.approached.clear();game.missions.approach={}
	land_at(128)
	for attempt in 1000:
		if game.missions.eligibility(130,128): break
		game.pilot.campaign.visit+=1
	game.missions.channel=0;game.missions.open()
	game.missions.accept(game.missions.offer(130,128))
	var mission: Dictionary=game.pilot.campaign.active.back()
	var completion: String=game.missions.text_for(mission,"CompText")
	land_at(int(mission.dest))
	check(game.mode=="mission_report" and game.missions.active_landing_report.body==completion,"Landing triggers the original delivery completion narrative")
	check(130 in game.pilot.campaign.completed and not game.pilot.campaign.active.has(mission),"Landing completes the contract and records progression")
	game.missions.dismiss_landing_report()
	check(game.mode=="dock","Landing report returns to the destination port")
	# Prerequisites, chance, capacity and active duplicates must still gate approaches.
	game.pilot.campaign.active=[];game.missions.begin_port_visit();game.hud.port_page="bar"
	game.pilot.campaign.active.resize(8)
	for i in 8: game.pilot.campaign.active[i]={"id":-100-i}
	game.missions.begin_bar_approach()
	check(game.mode=="dock" and game.missions.approach.is_empty(),"Full mission journal suppresses new bar approaches")
	game.pilot.campaign.active=[]
	game.free();await process_frame
	print("PORT MISSION TRIGGERS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
