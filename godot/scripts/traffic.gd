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
	if npc not in game.npcs or npc.disabled or npc.has("fleet_uid") or npc.get("player_ally",false) or npc.get("mission_escort",false): return false
	if npc.get("fighter",false) or npc.id==191 or float(npc.get("fuel",0))<100: return false
	if npc.has("departure"): return true
	var departure=preload("res://scripts/ship_departure.gd").new()
	departure.setup(game,npc.model,npc.model,npc.position,npc.velocity,npc.heading,game.catalog.record("ships",int(npc.id)).fields)
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
	var result: Dictionary = {}
	var distance: float = pow(game.persons.aggression_range(npc),2)
	if npc.hostile and not game.cloak.active:
		var d: float = npc.position.distance_squared_to(game.pilot.position)
		if d<distance:
			distance=d
			result={"position":game.pilot.position,"model":game.player_model,"player":true}
	for other in game.npcs:
		if other==npc or other.id==191 or other.disabled or other.get("hector",false): continue
		var provoked: bool = is_instance_valid(npc.nemesis) and other.model==npc.nemesis
		var attacks_fleet: bool=(other.has("fleet_uid") or other.get("player_ally",false)) and npc.hostile
		var pirate_raid: bool = npc.faction==130 and other.ai<=2 and other.faction!=130
		if not attacks_fleet and not provoked and (npc.ai<3 or not (pirate_raid or Factions.enemies(game.catalog,npc.faction,other.faction))): continue
		var d: float = npc.position.distance_squared_to(other.position)
		if d<distance:
			distance=d;result=other
	return result

func can_hit(shot: Dictionary, npc: Dictionary) -> bool:
	if npc.get("hector",false) and shot.get("npc_shot",false): return false
	if not shot.get("npc_shot",false): return not npc.has("fleet_uid") and not npc.get("player_ally",false)
	var source: Dictionary = shot.source
	if source.model==npc.model or npc.id==191: return false
	if source.has("fleet_uid") or source.get("player_ally",false):
		return not npc.has("fleet_uid") and not npc.get("player_ally",false) and (npc.hostile or game.fleet_service.attack_target==npc.model)
	if npc.has("fleet_uid") or npc.get("player_ally",false): return source.hostile
	return (is_instance_valid(source.nemesis) and source.nemesis==npc.model) or Factions.enemies(game.catalog,source.faction,npc.faction) or (source.faction==130 and npc.ai<=2 and npc.faction!=130)

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
					game.persons.maybe_spawn()
	for npc in game.npcs.duplicate():
		if npc not in game.npcs: continue
		npc.age+=dt
		if npc.get("maverick",false): maverick.update(game,npc,dt)
		game.Combat.regenerate(npc,game.catalog.record("ships",npc.id).fields,dt)
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
		var target=opponent(npc)
		var goal: Vector2=game.fleet_service.goal(npc) if npc.has("fleet_uid") or npc.get("player_ally",false) else game.pilot.position+Vector2(150,180) if npc.get("mission_escort",false) else npc.goal
		var behavior: String="Patrol" if npc.ai>=3 else "Transit"
		if not target.is_empty():
			var separation: Vector2=npc.position-target.position
			if npc.ai==1 or npc.id==191:
				goal=npc.position+separation.normalized()*900;behavior="Evading"
			else:
				goal=target.position+separation.normalized()*180;behavior="Engaging"
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
		var turn_rate: float=maxf(0,float(fields.Maneuver)*Flight.TURN_SCALE)
		npc.heading=rotate_toward(npc.heading,Flight.facing(offset),dt*turn_rate)
		var forward=Vector2(sin(npc.heading),-cos(npc.heading))
		var speed: float=float(fields.Speed)*(.65 if target.is_empty() else 1.0)
		if (npc.has("fleet_uid") or npc.get("player_ally",false)) and target.is_empty(): speed=minf(speed,offset.length()*2)
		npc.velocity=npc.velocity.move_toward(forward*speed,dt*float(fields.Accel)*Flight.ACCEL_SCALE)
		npc.position+=npc.velocity*dt
		npc.behavior="Escape pod" if npc.id==191 else behavior
		npc.model.position=game.v3(npc.position);npc.model.rotation.y=-npc.heading
		game.Models.set_thrust(npc.model,.65,game.time+npc.phase)
		for weapon in npc.weapons:
			weapon.cooldown=maxf(0,weapon.cooldown-dt)
			if target.is_empty() or weapon.cooldown>0 or weapon.ammo==0 or game.shots.size()>=160: continue
			var delta: Vector2=target.position-npc.position
			var type: String=game.arsenal.kind(weapon.id)
			var turret: bool=weapon.id in [133,134,143]
			if delta.length()> (1400 if type=="bay" else 950): continue
			if not turret and type not in ["bay","seeker"] and forward.dot(delta.normalized())<.92: continue
			if game.arsenal.fire(weapon.id,npc.position,npc.heading,target.get("player",false),npc,target):
				if weapon.ammo>0: weapon.ammo-=1
				weapon.cooldown=maxf(.12,float(game.catalog.field("weapons",weapon.id,"Reload"))*Flight.WEAPON_TICK_SECONDS/minf(weapon.count,4))

func launch_fighter(source: Dictionary, ship_id: int) -> bool:
	var count: int=0
	for npc in game.npcs:
		if npc.fighter and npc.carrier==source.model: count+=1
	if count>=4 or game.npcs.size()>=MAX_CONTACTS: return false
	var fighter=spawn(ship_id,source.faction,3,source.position+Vector2(100,80).rotated(source.heading))
	if fighter.is_empty(): return false
	fighter.player_ally=source.has("fleet_uid") or source.get("player_ally",false)
	if fighter.player_ally: fighter.truce=true;fighter.hostile=false
	fighter.fighter=true;fighter.carrier=source.model;fighter.provoked=source.provoked;fighter.nemesis=source.nemesis
	return true
