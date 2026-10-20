extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func port() -> void:
	game.pilot.system_id=128;game.load_system();game.docked_id=128
	game.set_mode("dock");game.toggle_fleet_menu()
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-fleet-management.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;game.breakup_chance=0
	root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.restart();game.pilot.credits=1000000;port()
	var service=game.fleet_service
	check(not service.offers().is_empty(),"Port supplies local nonhostile hire offers")
	var id: int=service.offers()[0]
	var credits: int=game.pilot.credits
	check(service.hire(id) and game.pilot.credits==credits-service.hire_cost(id),"Hire charges displayed contract once")
	check(game.escorts.size()==1 and game.escorts[0] in game.npcs,"Hired escort participates in ship combat")
	var npc: Dictionary=game.escorts[0]
	check(not service.takeover_reason(npc).is_empty(),"Hired captain cannot be stolen through flagship transfer")
	credits=game.pilot.credits;game.pilot.campaign.day+=3;service.payroll()
	check(game.pilot.credits==credits-3*service.wage(id),"Wages charge elapsed game days")
	credits=game.pilot.credits;service.payroll();check(game.pilot.credits==credits,"Payroll is idempotent")
	check(game.save_game(false),"Fleet saves with payroll and combat extension")
	game.load_game();check(game.escorts.size()==1 and service.record(game.escorts[0]).hired,"Hired escort survives disk reload")
	game.pilot.credits=0;game.pilot.campaign.day+=1;service.payroll()
	check(game.pilot.fleet.is_empty() and game.escorts.is_empty(),"Unpaid captain departs instead of granting free service")
	game.restart();game.pilot.credits=1000000
	game.pilot.fleet=[{"id":146},{"id":146}];game.load_system()
	check(game.escorts.size()==2 and game.escorts[0].fleet_uid!=game.escorts[1].fleet_uid,"Legacy identical hulls get distinct fleet identities")
	npc=game.escorts[0]
	check(npc.weapons.size()>1,"Captured corvette has original multiple weapon systems")
	var hostile: Dictionary=game.traffic.spawn(132,130,3,npc.position+Vector2(0,-300))
	check(game.traffic.can_hit({"npc_shot":true,"source":hostile},npc),"Hostile fire can damage escorts")
	check(not game.traffic.can_hit({"npc_shot":false},npc),"Player fire does not accidentally hit escorts")
	game.target_index=game.npcs.find(hostile);game.toggle_fleet_menu();service.order("attack")
	check(game.traffic.opponent(npc)==hostile,"Attack order selects intended ship")
	service.order("recall");check(game.traffic.opponent(npc).is_empty(),"Recall suppresses attacks")
	service.order("hold");var held: Vector2=service.goal(npc);game.pilot.position+=Vector2(500,500)
	check(service.goal(npc)==held,"Hold position stays independent of player motion")
	service.order("defend");check(game.traffic.opponent(npc)==hostile,"Defend acquires nearby hostile")
	game.set_mode("flight");npc.heading=0
	for w in npc.weapons: w.cooldown=0
	game.traffic.update(.01)
	check(game.shots.any(func(s):return s.get("source",{})==npc),"Escort fires its actual loadout")
	var oldhealth: float=npc.health;game.damage_npc(npc,20,hostile)
	check(npc.health<oldhealth,"Escort damage changes real survivability")
	for w in npc.weapons:
		if w.ammo>=0: w.ammo=0
	game.save_game(false);game.load_game();npc=game.escorts[0]
	check(npc.health<oldhealth and npc.weapons.all(func(w):return w.ammo<=0),"Damage and empty magazines persist through reload")
	game.docked_id=128;game.set_mode("dock");game.toggle_fleet_menu()
	credits=game.pilot.credits;var cost: int=service.service_cost()
	check(cost>0 and service.service() and game.pilot.credits==credits-cost,"Port repairs and ammunition are charged")
	check(npc.health==npc.max_health and npc.weapons.any(func(w):return w.ammo>0),"Service repairs and rearms ship")
	game.pilot.cargo[0]=game.pilot.cargo_capacity();npc.id=138
	check(not service.takeover_reason(npc).is_empty(),"Flagship transfer rejects undersized cargo hold")
	npc.id=146;game.pilot.cargo=[1,0,0,0,0,0]
	credits=game.pilot.credits
	check(service.takeover(npc),"Captured ship can become flagship")
	check(game.pilot.ship_id==146 and game.pilot.fleet.size()==1 and game.pilot.cargo[0]==1 and game.pilot.credits==credits,"Transfer retains cargo/cash and consumes only selected prize")
	game.load_game();check(game.pilot.ship_id==146,"Transferred flagship persists")
	npc=game.escorts[0];game.damage_npc(npc,npc.health+1)
	check(game.pilot.fleet.is_empty() and game.escorts.is_empty(),"Destroyed escort removed from persistent roster")
	game.save_game(false);game.load_game();check(game.escorts.is_empty(),"Lost escort never respawns on reload")
	var p=game.Pilot.new();var data: Dictionary=p.snapshot();data.erase("fuel_rules");data.fuel=100000
	check(p.restore(data,game.catalog) and p.fuel==400,"Old testing fuel save migrates to original tank")
	data=p.snapshot();data.fuel=100000;check(not p.restore(data,game.catalog),"Modern saves reject oversized fuel")
	var damage: Vector2=game.Combat.powers(game.catalog.record("weapons",142).fields)
	check(damage==Vector2(10,10),"Classic particle beam uses EV damage conversion rather than Nova rules")
	var result: Vector2=game.Combat.hit(5,100,10,20)
	check(result==Vector2(0,90),"Damage crosses shield boundary without disappearing")
	game.set_mode("flight");game.pilot.shield=5;game.pilot.armor=100;game.damage_player(10,Vector2.UP,20)
	check(game.pilot.shield==0 and game.pilot.armor==90,"Player uses same shield/armor damage rule")
	var layers: Dictionary={"health":15.0,"shield":5.0,"armor":10.0,"max_health":280.0,"shield_capacity":180.0,"disabled":false,"damage_clock":5.0}
	game.Combat.regenerate(layers,game.catalog.record("ships",128).fields,1)
	game.Combat.sync(layers)
	check(layers.shield==5 and layers.armor>10,"Original integrity recovery repairs armor before replenishing shields")
	game.restart();game.pilot.fleet=[{"id":146}];game.load_system();npc=game.escorts[0]
	game.pilot.cheat_chain_jump=true;game.velocity=Vector2(0,-10000)
	game.apply_hyperspace_wake(npc.position,npc.position+Vector2(1,0))
	check(npc in game.npcs,"Chain-jump wake continues to spare the persistent fleet")
	game.free();await process_frame
	print("FLEET MANAGEMENT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
