class_name EVTraffic
extends RefCounted

const Factions = preload("res://scripts/factions.gd")
const Flight = preload("res://scripts/flight.gd")
const ShipModels = preload("res://scripts/ship_models.gd")
const MAX_CONTACTS = 32
var game
var rng = RandomNumberGenerator.new()
var timer: float = 10
var enabled: bool = true
# Approach distance, retreat threshold and re-entry timing are remake tuning.
const INSPECTION_ACQUIRE_RANGE=1400.0
const RETREAT_SHIELD_FRACTION=0.25
var maverick=preload("res://scripts/maverick.gd").new()

func _init() -> void:
	rng.randomize()

func options(system_id: int) -> Array:
	var result: Array = []
	var fields: Dictionary = game.catalog.system(system_id).fields
	for slot in fields.DudeTypes.size():
		var encounter = game.catalog.record("encounters", int(fields.DudeTypes[slot]))
		if encounter.is_empty() or fields["% Prob"][slot] <= 0: continue
		var e: Dictionary = encounter.fields
		var total: float = 0
		for weight in e["% Prob"]: total += maxf(0,weight)
		if total <= 0: continue
		for i in e.ShipTypes.size():
			var ship_id = int(e.ShipTypes[i])
			if e["% Prob"][i] <= 0 or game.catalog.record("ships",ship_id).is_empty(): continue
			result.append({"ship":ship_id,"faction":int(e.Govt),"ai":int(e.AIType),"encounter":int(encounter.id),
				"weight":float(fields["% Prob"][slot])*float(e["% Prob"][i])/total})
	return result

func choose(pool: Array) -> Dictionary:
	var total: float = 0
	for option in pool: total += option.weight
	if total <= 0: return {}
	var roll = rng.randf()*total
	for option in pool:
		roll -= option.weight
		if roll <= 0: return option
	return pool[-1]

func refresh_after_landing() -> void:
	# Docking advances the encounter: old contacts and combat effects have departed.
	game.hector.banner_time = 0
	game.interactions.reset()
	game.fleet_service.sync()
	for npc in game.npcs.duplicate():
		if not npc.has("fleet_uid"): retire(npc)
	game.target_index = -1
	game.arsenal.ship_weapons.clear()
	game.arsenal.available_ids()
	for shot in game.shots: shot.node.queue_free()
	game.shots.clear()
	for spark in game.sparks: spark.node.queue_free()
	game.sparks.clear()
	for effect in game.explosions: effect.queue_free()
	game.explosions.clear()
	for effect in game.shield_hits:
		if is_instance_valid(effect): effect.advance(effect.DURATION)
	game.missions.arrival_delays.clear()
	game.missions.auxiliary_delays.clear()
	game.missions.scan_clock=0
	populate()

func populate() -> void:
	timer = rng.randf_range(7,12)
	if not enabled: return
	var pool = options(game.pilot.system_id)
	var remaining = pool.duplicate()
	var count: int = clampi(int(game.catalog.system(game.pilot.system_id).fields.AvgShips),0,12)
	for i in count:
		if remaining.is_empty(): remaining=pool.duplicate()
		var option = choose(remaining)
		if option.is_empty(): break
		# A varied initial sample; subsequent arrivals use the full source weights.
		remaining = remaining.filter(func(o):return o.ship != option.ship)
		var angle = -PI*.85+float(i)/maxi(count,1)*TAU
		var position: Vector2 = game.pilot.position+Vector2.from_angle(angle)*rng.randf_range(350,650)
		var npc = spawn(option.ship,option.faction,option.ai,position)
		if npc.is_empty(): break
		npc.encounter=option.encounter
		npc.ambient=true
		game.persons.maybe_spawn()

func spawn(ship_id: int, faction_id: int, ai: int, position: Vector2) -> Dictionary:
	if game.npcs.size() >= MAX_CONTACTS: return {}
	var ship = game.catalog.record("ships",ship_id)
	if ship.is_empty(): return {}
	var fields: Dictionary = ship.fields
	var model = ShipModels.create(game.catalog,ship_id,faction_id)
	game.world.add_child(model)
	model.position=game.v3(position)
	var strength: float = float(fields.Shield)
	# Original negative shields encode five times their absolute value.
	if strength < 0: strength *= -5
	var health: float = maxf(1,strength+maxf(0,fields.Armor))
	var weapons: Array = []
	for i in fields.WeapType.size():
		var id = int(fields.WeapType[i])
		if int(fields.WeapCount[i]) <= 0 or game.catalog.record("weapons",id).is_empty(): continue
		var limited = int(game.catalog.field("weapons",id,"AmmoType")) >= 0
		weapons.append({"id":id,"slot":i,"count":int(fields.WeapCount[i]),"ammo":int(fields.AmmoLoad[i]) if limited else -1,"cooldown":rng.randf_range(.4,1.4)})
	var npc = {"id":ship_id,"name":ship.name,"faction":faction_id,"ai":ai,"encounter":-1,
		"model":model,"position":position,"heading":rng.randf_range(-PI,PI),"velocity":Vector2.ZERO,
		"hostile":Factions.hostile_to_pilot(game.catalog,game.pilot,faction_id),"provoked":false,"crime_reported":false,
		"shield_capacity":maxf(0,strength),"health":health,"max_health":health,"radius":float(model.get_meta("radius")),"weapons":weapons,
		"cooldown":1.0,"phase":rng.randf()*TAU,"age":0.0,"ambient":false,"nemesis":null,
		"goal":Vector2.ZERO,"behavior":"Patrol" if ai>=3 else "Transit","fighter":false,"carrier":null}
	if not game.planets.is_empty() and rng.randf()<.65:
		npc.goal=game.planets[rng.randi_range(0,game.planets.size()-1)].position
	else:
		npc.goal=Vector2.from_angle(rng.randf()*TAU)*2600
	if ship_id==191: npc.behavior="Escape pod"
	game.interactions.initialize_contact(npc, fields)
	game.npcs.append(npc)
	return npc

func request_departure(npc: Dictionary,escaped: bool=false) -> bool:
	if npc not in game.npcs or npc.disabled or npc.has("fleet_uid") or npc.get("player_ally",false) or npc.get("mission_escort",false) or npc.has("bounty_port"): return false
	if npc.get("fighter",false) or npc.id==191 or float(npc.get("fuel",0))<100: return false
	if npc.has("departure"): return true
	var departure=preload("res://scripts/ship_departure.gd").new()
	departure.setup(game,npc.model,npc.model,npc.position,npc.velocity,npc.heading,game.catalog.record("ships",int(npc.id)).fields)
	departure.fields.Speed=cruise_speed(npc,game.catalog.record("ships",int(npc.id)).fields)
	npc.departure=departure;npc.departure_escape=escaped
	npc.behavior="Departing · "+departure.phase()
	return true

func advance_departure(npc: Dictionary,dt: float) -> bool:
	if not npc.has("departure"): return false
	if npc.disabled or npc.has("fleet_uid") or npc.get("player_ally",false) or npc.get("mission_escort",false):
		npc.departure.cancel();npc.erase("departure");return false
	var departure=npc.departure
	var done: bool=departure.advance(dt)
	npc.position=departure.position;npc.velocity=departure.velocity;npc.heading=departure.heading
	npc.behavior="Hyperspace · "+departure.phase()
	if done:
		npc.fuel=maxf(0,float(npc.fuel)-100)
		if npc.get("departure_escape",false): game.missions.actor_event(npc,"escape")
		retire(npc)
	return true

func set_audio_state(muted: bool,running: bool) -> void:
	if is_instance_valid(maverick.victory):
		if muted: maverick.victory.stop()
		else: maverick.victory.stream_paused=not running
	for npc in game.npcs:
		if npc.has("departure"): npc.departure.set_audio_state(muted,running)

func retire(npc: Dictionary) -> void:
	if npc not in game.npcs: return
	if npc.has("departure"): npc.departure.cancel()
	game.arsenal.stop_panic_for(npc)
	var selected: Dictionary = game.selected_contact()
	npc.model.queue_free()
	game.npcs.erase(npc)
	game.target_index = game.npcs.find(selected) if selected != npc else -1

func opponent(npc: Dictionary) -> Dictionary:
	if npc.has("fleet_uid") or npc.get("player_ally",false): return game.fleet_service.target(npc)
	var result: Dictionary={}
	var distance: float=pow(game.persons.aggression_range(npc),2)
	if npc.hostile and not game.cloak.active:
		var d: float=npc.position.distance_squared_to(game.pilot.position)
		if d<distance:
			distance=d;result={"position":game.pilot.position,"model":game.player_model,"velocity":game.velocity,"player":true}
	if npc.hostile:
		for fighter in game.escorts:
			if fighter.get("captured",false) or not fighter.model.visible: continue
			var d: float=npc.position.distance_squared_to(fighter.position)
			if d<distance: distance=d;result=fighter
	for other in game.npcs:
		if other==npc or other.id==191 or other.disabled or other.get("hector",false) or other.has("departure"): continue
		var provoked: bool=is_instance_valid(npc.nemesis) and other.model==npc.nemesis
		var attacks_fleet: bool=(other.has("fleet_uid") or other.get("player_ally",false)) and npc.hostile
		var pirate_raid: bool=npc.faction==130 and other.ai<=2 and other.faction!=130
		var threatens_civilian: bool=npc.ai<=2 and ((other.faction==130 and npc.faction!=130) or (is_instance_valid(other.nemesis) and other.nemesis==npc.model))
		var enemy: bool=Factions.enemies(game.catalog,npc.faction,other.faction)
		if not (attacks_fleet or provoked or threatens_civilian or (npc.ai>=3 and (pirate_raid or enemy))): continue
		var d: float=npc.position.distance_squared_to(other.position)
		if d<distance: distance=d;result=other
	return result

func ordinary_retreat(npc: Dictionary,target: Dictionary) -> bool:
	if target.is_empty() or not npc.get("ambient",false) or npc.disabled: return false
	if npc.has("fleet_uid") or npc.get("player_ally",false) or npc.has("person_id") or npc.has("mission_id") or npc.has("bounty_port") or npc.get("fighter",false): return false
	# Wimpy merchants evade immediately. Armed merchants and raiders break off
	# once badly damaged; mission actors retain their scripted escape conditions.
	var armor_capacity: float=maxf(0,float(npc.max_health)-float(npc.shield_capacity))
	var low: bool=float(npc.health)<=armor_capacity+float(npc.shield_capacity)*RETREAT_SHIELD_FRACTION if float(npc.shield_capacity)>0 else float(npc.health)<float(npc.max_health)*.8
	return int(npc.ai)==1 or ((int(npc.ai)==2 or int(npc.faction)==130) and low)

func inspection_target(npc: Dictionary) -> bool:
	if npc.hostile or game.cloak.active or npc.get("ambient_retreat",false): return false
	if npc.position.distance_to(game.pilot.position)>INSPECTION_ACQUIRE_RANGE: return false
	for m in game.missions.state().active:
		if not m.picked or m.delivered or npc.get("scanned_mission_%d" % m.id,false): continue
		var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
		if game.missions.scanner_eligible(npc,f): return true
	return false

func cruise_speed(npc: Dictionary,fields: Dictionary) -> float:
	if fields.get("custom_flight",false): return float(fields.Speed)
	# Original helper 0x62644: follow slot 0 (player escort) uses base speed;
	# ordinary/non-player followers use the recovered 1.25 multiplier.
	return float(fields.Speed)*(1.0 if npc.has("fleet_uid") or npc.get("player_ally",false) or npc.get("mission_escort",false) else 1.25)

func can_hit(shot: Dictionary, npc: Dictionary) -> bool:
	if npc.get("hector",false) and shot.get("npc_shot",false): return false
	if not shot.get("npc_shot",false): return not npc.has("fleet_uid") and not npc.get("player_ally",false)
	var source: Dictionary = shot.source
	if source.model==npc.model or npc.id==191: return false
	if source.has("fleet_uid") or source.get("player_ally",false):
		return not npc.has("fleet_uid") and not npc.get("player_ally",false) and (npc.hostile or game.fleet_service.attack_target==npc.model)
	if npc.has("fleet_uid") or npc.get("player_ally",false): return source.hostile
	return (is_instance_valid(source.nemesis) and source.nemesis==npc.model) or Factions.enemies(game.catalog,source.faction,npc.faction) or (source.faction==130 and npc.ai<=2 and npc.faction!=130) or (int(source.get("ai",-1))==2 and npc.faction==130 and source.faction!=130) or (is_instance_valid(npc.nemesis) and npc.nemesis==source.model)

func update(dt: float) -> void:
	if game.mode!="flight": return
	if enabled:
		game.hector.advance(dt)
		maverick.advance(game,dt)
	if enabled:
		timer-=dt
		if timer<=0:
			timer=rng.randf_range(8,14)
			var ambient_count: int=0
			for npc in game.npcs:
				if npc.ambient: ambient_count+=1
			var desired: int = int(game.catalog.system(game.pilot.system_id).fields.AvgShips)
			if ambient_count<desired and game.npcs.size()<MAX_CONTACTS:
				var option=choose(options(game.pilot.system_id))
				if not option.is_empty():
					var contact=spawn(option.ship,option.faction,option.ai,game.pilot.position+Vector2.from_angle(rng.randf()*TAU)*1150)
					contact.ambient=true;contact.encounter=option.encounter
					# New traffic enters on an inward flight vector rather than materializing stationary.
					contact.heading=Flight.facing(game.pilot.position-contact.position)
					contact.velocity=(game.pilot.position-contact.position).normalized()*cruise_speed(contact,game.catalog.record("ships",int(contact.id)).fields)
					game.persons.maybe_spawn()
	for npc in game.npcs.duplicate():
		if npc not in game.npcs: continue
		if not npc.get("pending_wings",[]).is_empty(): game.fighter_wing.restore_carrier(npc)
		npc.age+=dt
		if npc.get("maverick",false): maverick.update(game,npc,dt)
		game.Combat.regenerate(npc,game.catalog.record("ships",npc.id).fields,dt,game.recovery_window)
		if game.fleet_service.update_jump(npc,dt): continue
		if advance_departure(npc,dt): continue
		if npc.id==900: maverick.advance_wings(npc.model,false,dt)
		if npc.get("hector",false):
			game.hector.fly(npc,dt)
			continue
		npc.hostile=not npc.truce and (npc.provoked or Factions.hostile_to_pilot(game.catalog,game.pilot,npc.faction))
		if game.persons.update(npc,dt): continue
		# Chase-off objectives permit a wounded, still flyable enemy to escape.
		if npc.get("mission_can_retreat",false) and not npc.disabled and (npc.get("mission_retreat",false) or npc.health<npc.max_health*.35):
			npc.mission_retreat=true
			game.persons.fly_away(npc,dt,false);continue
		if game.interactions.update_special(npc, dt): continue
		if game.fighter_wing.update_carrier_fighter(npc,dt): continue
		if npc.has("fleet_uid") and game.fleet_service.record(npc).get("command","defend")=="hold":
			game.fighter_wing.fly(npc,npc.get("hold_position",npc.position),Vector2.ZERO,dt)
			npc.behavior="Holding position";advance_weapons(npc,{},dt);continue
		var target=opponent(npc)
		if ordinary_retreat(npc,target): npc.ambient_retreat=true
		if npc.get("ambient_retreat",false):
			npc.retreat_time=float(npc.get("retreat_time",0))+dt
			if npc.retreat_time>8 and request_departure(npc): advance_departure(npc,dt);continue
		var goal: Vector2=game.fleet_service.goal(npc) if npc.has("fleet_uid") or npc.get("player_ally",false) else game.pilot.position+Vector2(150,180) if npc.get("mission_escort",false) else npc.goal
		var behavior: String="Patrol" if npc.ai>=3 else "Transit"
		if not target.is_empty():
			var separation: Vector2=npc.position-target.position
			if npc.ai==1 or npc.id==191 or npc.get("ambient_retreat",false):
				goal=npc.position+separation.normalized()*900;behavior="Evading"
			else:
				goal=attack_goal(npc,target);behavior="Engaging"
		elif npc.get("ambient_retreat",false):
			goal=npc.position+(npc.position-game.pilot.position).normalized()*900;behavior="Retreating"
		elif inspection_target(npc):
			goal=game.pilot.position;behavior="Inspecting cargo"
		elif npc.position.distance_to(goal)<100 and not npc.has("fleet_uid") and not npc.get("player_ally",false):
			if npc.ambient and npc.age>12 and npc.ai<=2:
				# Contacts actually over a port have landed; other transit exits jump.
				if not preload("res://scripts/travel_rules.gd").landing_body(npc.position,game.planets).is_empty(): retire(npc);continue
				if request_departure(npc): advance_departure(npc,dt);continue
			npc.goal=game.pilot.position+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(500,1700)
			goal=npc.goal
		if npc.ambient and (npc.age>100 or npc.position.distance_to(game.pilot.position)>4500) and target.is_empty():
			if request_departure(npc): advance_departure(npc,dt);continue
			# Pods and carrier fighters lack hyperdrives; off-screen cleanup only.
			if npc.position.distance_to(game.pilot.position)>4500: retire(npc);continue
		var fields: Dictionary=game.catalog.record("ships",npc.id).fields
		var offset: Vector2=goal-npc.position
		if behavior=="Inspecting cargo":
			# Close the relative-motion gap, then hold alongside for inspection.
			var wanted: Vector2=game.velocity+offset.normalized()*minf(cruise_speed(npc,fields),maxf(0,offset.length()-100))
			offset=wanted-npc.velocity
		var flight_fields: Dictionary=fields.duplicate()
		flight_fields.Speed=cruise_speed(npc,fields)
		var turn: float=Flight.steering(npc.heading,Flight.facing(offset),flight_fields,dt)
		# Main engines thrust along the hull. Turning alone cannot redirect drift.
		var aligned: bool=absf(angle_difference(npc.heading,Flight.facing(offset)))<PI/3
		var thrust: bool=aligned and offset.length()>(1.0 if behavior=="Inspecting cargo" else 40.0)
		var step: Dictionary=Flight.step(npc.position,npc.velocity,npc.heading,turn,thrust,false,flight_fields,dt)
		npc.position=step.position;npc.velocity=step.velocity;npc.heading=step.heading
		npc.behavior="Escape pod" if npc.id==191 else behavior
		npc.model.position=game.v3(npc.position);npc.model.rotation.y=-npc.heading
		game.Models.set_thrust(npc.model,.65 if thrust else 0.0,game.time+npc.phase)
		if behavior=="Inspecting cargo": game.missions.scan_missions(npc)
		advance_weapons(npc,{} if npc.ai==1 or npc.id==191 or npc.get("ambient_retreat",false) else target,dt)

func attack_goal(npc: Dictionary,target: Dictionary) -> Vector2:
	var reach: float=INF
	var speed: float=0
	for weapon in npc.weapons:
		if weapon.ammo==0 or game.arsenal.kind(int(weapon.id)) in ["bay","flare","bomb","tractor"]: continue
		if game.arsenal.is_secondary(int(weapon.id)): continue
		reach=minf(reach,game.arsenal.weapon_reach(int(weapon.id)))
		speed=maxf(speed,float(game.catalog.field("weapons",int(weapon.id),"Speed")))
	if not is_finite(reach): reach=330
	var delta: Vector2=target.position-npc.position
	# A physics-derived intercept estimate; original numerical AI tuning is unverified.
	var lead: float=minf(1.0,delta.length()/speed) if speed>0 else 0.0
	var aim: Vector2=target.position+Vector2(target.get("velocity",Vector2.ZERO))*lead
	return aim-delta.normalized()*clampf(reach*.45,60,420)

func advance_weapons(npc: Dictionary,target: Dictionary,dt: float) -> void:
	for weapon in npc.weapons:
		weapon.cooldown-=dt
		if target.is_empty() or weapon.ammo==0:
			weapon.cooldown=maxf(0,weapon.cooldown);continue
		var delta: Vector2=target.position-npc.position
		var type: String=game.arsenal.kind(int(weapon.id))
		var forward: Vector2=Vector2(sin(npc.heading),-cos(npc.heading))
		var turret: bool=int(weapon.id) in [133,134,143]
		var reach: float=game.arsenal.weapon_reach(int(weapon.id))+float(target.get("radius",22))
		if type not in ["bay","beam","tractor"]: reach+=maxf(35,float(npc.radius)+8)
		if delta.length()>reach or (not turret and type not in ["bay","seeker"] and forward.dot(delta.normalized())<.92):
			weapon.cooldown=maxf(0,weapon.cooldown);continue
		var period: float=maxf(Flight.WEAPON_TICK_SECONDS,float(game.catalog.field("weapons",int(weapon.id),"Reload"))*Flight.WEAPON_TICK_SECONDS)
		var bursts: int=0
		while weapon.cooldown<=.000001 and bursts<8 and game.shots.size()<160 and weapon.ammo!=0:
			var emitted: bool=false
			for mount in maxi(1,int(weapon.count)):
				if weapon.ammo==0 or game.shots.size()>=160: break
				var origin: Vector2=npc.position+forward.orthogonal()*((mount-(int(weapon.count)-1)*.5)*8)
				if game.arsenal.fire(int(weapon.id),origin,npc.heading,target.get("player",false),npc,target):
					emitted=true
					if weapon.ammo>0: weapon.ammo-=1
			if not emitted:
				weapon.cooldown=0;break
			weapon.cooldown+=period;bursts+=1

func launch_fighter(source: Dictionary, ship_id: int, bay_weapon: int=-1) -> bool:
	var count: int=0
	for npc in game.npcs:
		if npc.fighter and npc.carrier==source.model: count+=1
	var capacity: int=0
	var fields: Dictionary=game.catalog.record("ships",int(source.id)).fields
	for i in fields.WeapType.size():
		if game.arsenal.kind(int(fields.WeapType[i]))=="bay": capacity+=int(fields.AmmoLoad[i])
	if count>=maxi(1,capacity) or game.npcs.size()>=MAX_CONTACTS: return false
	var fighter=spawn(ship_id,source.faction,3,source.position+Vector2(100,80).rotated(source.heading))
	if fighter.is_empty(): return false
	fighter.player_ally=source.has("fleet_uid") or source.get("player_ally",false)
	if fighter.player_ally: fighter.truce=true;fighter.hostile=false
	fighter.heading=source.heading;fighter.velocity=source.velocity
	fighter.model.rotation.y=-fighter.heading
	fighter.bay_weapon=bay_weapon;fighter.sortie_seconds=0.0;fighter.recalling=false
	fighter.fighter=true;fighter.carrier=source.model;fighter.provoked=source.provoked;fighter.nemesis=source.nemesis
	return true
