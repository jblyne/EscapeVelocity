extends SceneTree

const Pilot=preload("res://scripts/pilot.gd")
var game
var count: int=0
var failures: int=0

func check(ok: bool, message: String) -> void:
	count+=1
	if ok: print("PASS: "+message)
	else:
		failures+=1;push_error("FAIL: "+message)

func _initialize() -> void:
	call_deferred("run")

func clear_space() -> void:
	for npc in game.npcs: npc.model.free()
	game.npcs.clear();game.target_index=-1
	for shot in game.shots: shot.node.free()
	game.shots.clear()
	game.pilot.position=Vector2(10000,10000)
	game.pilot.shield=180;game.pilot.armor=100
	game.pilot.reputation={}
	game.set_mode("flight")

func geometry_summary(model: Node3D) -> Dictionary:
	var count_vertices=0
	var bounds=AABB()
	for node in model.get_children():
		if str(node.name).begins_with("Flame"): continue
		var arrays=node.mesh.surface_get_arrays(0)
		var indices=arrays[Mesh.ARRAY_INDEX]
		var vertices=arrays[Mesh.ARRAY_VERTEX]
		for index in (indices if indices!=null and not indices.is_empty() else range(vertices.size())):
			var vertex: Vector3=node.transform*vertices[index]
			if count_vertices==0: bounds=AABB(vertex,Vector3.ZERO)
			else: bounds=bounds.expand(vertex)
			count_vertices+=1
	return {"vertices":count_vertices,"bounds":bounds}

func check_mesh_batching() -> void:
	var details=game.ShipModels.Details
	var fixture=Node3D.new()
	var mat=game.Models.material(Color.WHITE)
	details.panel(fixture,Vector3(-.2,.1,0),Vector3(.4,.2,.4),mat)
	var cylinder=details.cylinder(fixture,Vector3(.2,.1,0),.12,.3,mat)
	cylinder.rotation=Vector3(.3,.2,.1);cylinder.scale=Vector3(1,.7,1.2)
	var flame=game.Models.box(fixture,Vector3(0,0,1),Vector3(.1,.1,.4),mat)
	flame.name="FlameTest"
	var flame_transform=flame.transform
	var before=geometry_summary(fixture)
	details.batch_static_parts(fixture)
	var after=geometry_summary(fixture)
	check(before.vertices==after.vertices and before.bounds.position.distance_to(after.bounds.position)<.0001 and before.bounds.end.distance_to(after.bounds.end)<.0001,"batching indexed engines with unindexed armor preserves every triangle and its transformed bounds")
	check(fixture.get_child_count()==2 and fixture.get_node("FlameTest")==flame and flame.transform==flame_transform,"static detail combines into one draw while animated exhaust remains independent")
	fixture.free()

func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-fleet-pilot.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	check_mesh_batching()
	var traffic=game.traffic
	var c=game.catalog
	traffic.rng.seed=142857
	var pool=traffic.options(129)
	var factions: Dictionary={};var hulls: Dictionary={};var total: float=0
	for option in pool:
		factions[option.faction]=true;hulls[option.ship]=true;total+=option.weight
	check(factions.keys()==[128] and hulls.size()==10 and total==120,"Sol's weighted source tables produce Confederate civilian, luxury, and military traffic")
	var reachable: Dictionary={};var valid: bool=true
	for system in c.data.systems.values():
		for option in traffic.options(int(system.id)):
			valid=valid and not c.record("ships",option.ship).is_empty() and (option.faction==-1 or not c.record("governments",option.faction).is_empty()) and option.weight>0
			reachable[option.ship]=true
	check(valid and reachable.size()==21,"all 108 systems resolve valid encounter weights, factions, and the 21 ambient ship records")
	for special in [148,149,150,152,153,191]:
		check(not reachable.has(special),"special ship %s is not injected into ordinary source traffic" % c.record("ships",special).name)
	game.pilot.system_id=129;game.pilot.position=Vector2.ZERO;traffic.enabled=true;game.load_system()
	hulls={}
	var ambient: Array=game.npcs.filter(func(npc):return not npc.has("person_id") and not npc.has("fleet_uid"))
	for npc in ambient: hulls[npc.id]=true
	check(ambient.size()==5 and hulls.size()==5,"Sol uses AvgShips=5 and begins with five different ambient hulls independently of named pilots")
	traffic.enabled=false;clear_space()
	var models_ok: bool=true;var shared_ok: bool=true;var stats_ok: bool=true
	for ship in c.data.ships.values():
		var id=int(ship.id)
		var contact=traffic.spawn(id,int(ship.fields.InherentGovt),int(ship.fields.InherentAI),Vector2.ZERO)
		var clone=game.ShipModels.create(c,id,int(ship.fields.InherentGovt))
		models_ok=models_ok and contact.model.get_meta("ship_id")==id and contact.model.get_child_count()>=7 and contact.radius>0
		shared_ok=shared_ok and contact.model.get_child(0).mesh==clone.get_child(0).mesh
		stats_ok=stats_ok and contact.max_health>=1 and contact.weapons.size()<=4
		clone.free();traffic.retire(contact)
	check(models_ok and c.data.ship_graphics.size()==27,"all 27 ships build their own catalog-selected model and original relative sprite size")
	check(shared_ok,"repeated models reuse packed geometry instead of rebuilding hulls")
	check(stats_ok,"all ship health and loadouts are valid, including escape pod and alien cruiser")
	await process_frame
	var bulk=traffic.spawn(130,128,1,Vector2.ZERO)
	var fighter=traffic.spawn(138,133,3,Vector2(400,0))
	check(bulk.radius>fighter.radius*2 and bulk.max_health==350 and fighter.max_health==100,"freighter and fighter have distinct physical size and source durability")
	bulk.goal=Vector2(0,-10000);bulk.heading=0
	fighter.goal=Vector2(400,-10000);fighter.heading=0
	for frame in 300: traffic.update(1.0/60)
	check(absf(bulk.velocity.length()-52)<.1 and absf(fighter.velocity.length()-325)<.1,"civil traffic cruises using each hull's own Speed and Accel")
	clear_space()
	check(game.Factions.enemies(c,128,129) and game.Factions.enemies(c,131,132) and game.Factions.enemies(c,138,139),"Confederate/Rebel, Cydonian/Lethean, and corporate enemy links come from original governments")
	check(game.Factions.allied(c,128,135) and not game.Factions.enemies(c,128,135),"Astex and Confederation respect the original alliance")
	check(not game.Factions.hostile_to_pilot(c,game.pilot,128) and not game.Factions.hostile_to_pilot(c,game.pilot,129) and game.Factions.hostile_to_pilot(c,game.pilot,130),"a neutral pilot is not automatically at war with either military faction; pirates are hostile")
	var confed=traffic.spawn(133,128,3,Vector2(0,200))
	var rebel=traffic.spawn(141,129,3,Vector2(0,-200))
	check(traffic.opponent(confed)==rebel and traffic.opponent(rebel)==confed,"rival warships select each other independently of the player")
	game.arsenal.fire(134,confed.position,0,false,confed,rebel)
	game.update_shots(.6)
	check(rebel.health<rebel.max_health and not rebel.hostile and not confed.hostile and game.pilot.reputation.is_empty(),"NPC weapon hits damage the enemy fleet without blaming or harming the neutral pilot")
	var ally=traffic.spawn(135,128,3,Vector2(0,0))
	var context={"npc_shot":true,"source":confed}
	check(not traffic.can_hit(context,confed) and not traffic.can_hit(context,ally) and traffic.can_hit(context,rebel),"NPC collision filtering excludes its own hull and faction allies")
	game.damage_npc(confed,1)
	check(confed.hostile and ally.hostile and not rebel.hostile and game.pilot.reputation["128"]==-3,"shooting a Confederate ship provokes its military allies and records the source crime penalty")
	game.damage_npc(confed,1)
	check(game.pilot.reputation["128"]==-3,"sustained fire does not charge the first-attack penalty every frame")
	game.damage_npc(confed,20000)
	check(game.pilot.reputation["128"]==-28,"destroying that ship adds the original government's kill penalty once")
	var snapshot=game.pilot.snapshot();var restored=Pilot.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(snapshot)),c) and restored.reputation["128"]==-28,"faction reputation persists through a pilot save roundtrip")
	var old=snapshot.duplicate(true);old.erase("reputation")
	check(restored.restore(old,c) and restored.reputation.is_empty(),"existing pilots without faction records remain compatible")
	for bad in [{"128":"bad"},{"9999":-10},{"128":INF},{"128":.5}]:
		var invalid=snapshot.duplicate(true);invalid.reputation=bad
		var before=restored.snapshot()
		check(not restored.restore(invalid,c) and restored.snapshot()==before,"invalid reputation is rejected atomically")
	clear_space()
	var carrier=traffic.spawn(134,128,3,Vector2.ZERO)
	check(traffic.launch_fighter(carrier,135) and game.npcs[-1].faction==128 and game.npcs[-1].id==135 and game.npcs[-1].model.get_meta("ship_id")==135,"a carrier launches the correct faction's actual fighter model")
	for i in 3: traffic.launch_fighter(carrier,135)
	check(not traffic.launch_fighter(carrier,135) and game.npcs.size()==5,"carrier wings are bounded to four active fighters")
	clear_space()
	var alien=traffic.spawn(149,140,3,Vector2(0,200))
	var victim=traffic.spawn(138,128,3,Vector2(0,-200))
	game.arsenal.fire(147,alien.position,0,false,alien,victim)
	check(victim.health<victim.max_health and alien.health==alien.max_health and game.pilot.shield==180,"alien beam hits its NPC enemy, not its owner or the pilot")
	clear_space()
	game.pilot.position=Vector2.ZERO
	var pirate=traffic.spawn(137,130,3,Vector2(0,400))
	for weapon in pirate.weapons: weapon.cooldown=0
	traffic.update(.01)
	check(game.shots.any(func(shot):return shot.weapon in [132,139] and shot.enemy and shot.npc_shot),"pirates use their recovered armed loadout and guided weapons target the player")
	var missile_slot: Dictionary={}
	for weapon in pirate.weapons:
		if weapon.id==132: missile_slot=weapon
	check(missile_slot.ammo==3,"NPC missile firing consumes its finite original ammunition")
	clear_space()
	game.pilot.system_id=129;game.pilot.position=Vector2.ZERO
	game.set_mode("flight");traffic.enabled=true;traffic.timer=0;traffic.update(.01)
	check(game.npcs.size()==1 and game.npcs[0].ambient,"traffic replenishes from the current system's source encounters")
	var selected=game.npcs[0];game.target_index=0
	selected.age=101;selected.goal=Vector2(10000,0)
	traffic.update(.01)
	check(selected in game.npcs and selected.has("departure"),"Expired traffic starts a physical warp departure")
	traffic.enabled=false
	for tick in 9000:
		if selected not in game.npcs: break
		traffic.update(1.0/60)
	check(selected not in game.npcs and game.target_index==-1,"Completed warp retires contact and clears selected target")
	traffic.enabled=false;clear_space()
	game.set_mode("cheats")
	var ship_picker=game.hud.modal_root.find_child("ShipPicker",true,false)
	var faction_picker=game.hud.modal_root.find_child("FactionPicker",true,false)
	check(ship_picker.item_count==27 and faction_picker.item_count==27,"cheat menu lists every ship record, every government, independent, and the inherent faction choice")
	ship_picker.select(ship_picker.get_item_index(150))
	game.hud.modal_root.find_child("SpawnShip",true,false).pressed.emit()
	check(game.npcs.size()==1 and game.npcs[-1].id==150 and game.npcs[-1].faction==140,"actual debug controls spawn a special ship using its original inherent faction")
	check(game.debug_spawn_ship(131,138) and game.npcs[-1].faction==138,"debug spawn supports explicit corporate affiliation")
	game.set_mode("flight");game.hud._process(0)
	check(game.hud.target_panel.faction_text.text=="Starbound Shipping" and game.hud.target_panel.class_text.text.contains("250"),"target panel shows the selected ship's faction and original cruise speed")
	var previous_age: float=game.npcs[-1].age
	var previous_timer: float=traffic.timer
	game.set_mode("pause");game._physics_process(20)
	check(game.npcs[-1].age==previous_age and traffic.timer==previous_timer,"menus freeze fleet movement and arrival timers")
	game.set_mode("flight")
	check(not game.debug_spawn_ship(150,140),"debug spawning is confined to the cheat menu")
	game.load_system()
	check(game.npcs.is_empty() and game.shots.is_empty() and game.escorts.is_empty(),"system transitions clear old traffic, projectiles, and fighter wings")
	clear_space()
	for i in 4:
		traffic.spawn(134 if i%2==0 else 133,128,3,Vector2(-450+i*120,350))
		traffic.spawn(142 if i%2==0 else 141,129,3,Vector2(-450+i*120,-350))
	var peak_contacts: int=0;var peak_shots: int=0;var peak_explosions: int=0
	for frame in 2400:
		game._physics_process(1.0/60)
		peak_contacts=maxi(peak_contacts,game.npcs.size())
		peak_shots=maxi(peak_shots,game.shots.size())
		peak_explosions=maxi(peak_explosions,game.explosions.size())
		if frame%60==0: await process_frame
	check(peak_contacts>8 and peak_contacts<=traffic.MAX_CONTACTS and peak_shots>0 and peak_shots<=160 and peak_explosions>0 and peak_explosions<=game.MAX_EXPLOSIONS,
		"40-second carrier battle launches fighters, fires weapons, destroys ships, and keeps entity counts bounded")
	check(game.mode=="flight" and game.pilot.shield==180 and game.pilot.armor==100 and game.pilot.reputation.is_empty(),"autonomous fleet war leaves the distant neutral pilot and reputation intact")
	print("BATTLE peaks: %d contacts, %d shots, %d explosions" % [peak_contacts,peak_shots,peak_explosions])
	game.free();await process_frame
	if FileAccess.file_exists(ProjectSettings.globalize_path("res://../builds/test-fleet-pilot.json")): DirAccess.remove_absolute(ProjectSettings.globalize_path("res://../builds/test-fleet-pilot.json"))
	print("FLEET RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
