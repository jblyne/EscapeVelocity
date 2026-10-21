class_name EVArsenal
extends RefCounted

# Uses the recovered names, rates and damage fields. Guidance, beam ranges and
# escort AI are prototype implementations, not a port of the original engine.
const Flight = preload("res://scripts/flight.gd")
const Forklift=preload("res://scripts/forklift.gd")
const ProjectileModels=preload("res://scripts/projectile_models.gd")
const MAX_ESCORTS = 12
const WEAPON_SOUND_KEYS=["weapon_200","weapon_201","weapon_202","weapon_203","weapon_204","weapon_205","weapon_206","weapon_207","weapon_208","weapon_209","weapon_210","weapon_211","weapon_212","weapon_213","weapon_214","weapon_215","weapon_216","weapon_223"]
const PANIC_KEYS=[
	"panic_cmd_civilian_1", "panic_cmd_civilian_2", "panic_cmd_civilian_3", "panic_cmd_civilian_4", "panic_cmd_civilian_5", "panic_cmd_civilian_6",
	"panic_cmd_rebel_1", "panic_cmd_rebel_2", "panic_cmd_rebel_3", "panic_cmd_rebel_4", "panic_cmd_rebel_5", "panic_cmd_rebel_6",
	"panic_cmd_confed_1", "panic_cmd_confed_2", "panic_cmd_confed_3", "panic_cmd_confed_4", "panic_cmd_confed_5", "panic_cmd_confed_6",
	"panic_cmd_pirate_1", "panic_cmd_pirate_2", "panic_cmd_pirate_3", "panic_cmd_pirate_4", "panic_cmd_pirate_5", "panic_cmd_pirate_6",
	"panic_alien_1", "panic_alien_2"]
const PANIC_POOLS={
	"civilian":["panic_cmd_civilian_1", "panic_cmd_civilian_2", "panic_cmd_civilian_3", "panic_cmd_civilian_4", "panic_cmd_civilian_5", "panic_cmd_civilian_6", "panic_cmd_rebel_1", "panic_cmd_rebel_2"],
	"rebel":["panic_cmd_rebel_1", "panic_cmd_rebel_2", "panic_cmd_rebel_3", "panic_cmd_rebel_4", "panic_cmd_rebel_5", "panic_cmd_rebel_6", "panic_cmd_civilian_1", "panic_cmd_civilian_2"],
	"confed":["panic_cmd_confed_1", "panic_cmd_confed_2", "panic_cmd_confed_3", "panic_cmd_confed_4", "panic_cmd_confed_5", "panic_cmd_confed_6", "panic_cmd_rebel_3", "panic_cmd_rebel_4"],
	"pirate":["panic_cmd_pirate_1", "panic_cmd_pirate_2", "panic_cmd_pirate_3", "panic_cmd_pirate_4", "panic_cmd_pirate_5", "panic_cmd_pirate_6", "panic_cmd_rebel_1", "panic_cmd_rebel_2"],
	"alien":["panic_alien_1", "panic_alien_2"]}
const PANIC_LEAD_SECONDS=3.0
const DEATH_POOLS={
	"human_single": [
		"death_cry_1",
		"death_cry_2",
		"death_cry_3",
		"death_cry_4",
		"death_cry_5",
		"death_cry_6"
	],
	"alien_single": [
		"death_cry_alien",
		"death_cry_alien_2",
		"death_cry_alien_3"
	],
	"human_crew": [
		"death_cry_human_crew",
		"death_cry_human_crew_2",
		"death_cry_human_crew_3"
	],
	"human_crowd": [
		"death_cry_human_crowd",
		"death_cry_human_crowd_2",
		"death_cry_human_crowd_3"
	],
	"alien_crew": [
		"death_cry_alien_crew",
		"death_cry_alien_crew_2",
		"death_cry_alien_crew_3"
	],
	"alien_crowd": [
		"death_cry_alien_crowd",
		"death_cry_alien_crowd_2",
		"death_cry_alien_crowd_3"
	]
}
const DEATH_KEYS=["death_cry_1", "death_cry_2", "death_cry_3", "death_cry_4", "death_cry_5", "death_cry_6", "death_cry_alien", "death_cry_alien_2", "death_cry_alien_3", "death_cry_human_crew", "death_cry_human_crew_2", "death_cry_human_crew_3", "death_cry_human_crowd", "death_cry_human_crowd_2", "death_cry_human_crowd_3", "death_cry_alien_crew", "death_cry_alien_crew_2", "death_cry_alien_crew_3", "death_cry_alien_crowd", "death_cry_alien_crowd_2", "death_cry_alien_crowd_3"]
var death_bags: Dictionary={}
var last_deaths: Dictionary={}
var last_death_key: String=""
var panic_bags: Dictionary={}
var last_panics: Dictionary={}
var panic_owner: Node3D
var panic_key: String=""
var game
var gun_audio_hold: float=0.0
var ship_weapons: Dictionary = {}
var next_ship_weapon: int = 10000

func available_ids() -> Array:
	var result: Array = ids() if game.pilot.cheat_all_weapons else game.outfitter.weapon_ids()
	if game.pilot.secrets.forklift and 191 not in result: result.append(191)
	for id in ship_weapons.keys():
		if ship_weapons[id] in game.npcs: result.append(id)
		else: ship_weapons.erase(id)
	if game.pilot.selected_weapon not in result: game.pilot.selected_weapon = int(result[0]) if not result.is_empty() else 128
	return result

func weapon_name(id: int) -> String:
	if ship_weapons.has(id): return "%s · ship launcher (1)" % ship_weapons[id].name
	return game.catalog.record("weapons",id).get("name","Laser")

func arm_resisting_ship(npc: Dictionary) -> void:
	ship_weapons[next_ship_weapon] = npc
	game.select_weapon(next_ship_weapon)
	next_ship_weapon += 1

func fire_ship(id: int) -> bool:
	var hull: Dictionary = ship_weapons[id]
	var victim: Dictionary = game.selected_contact()
	if hull not in game.npcs: return false
	if victim.is_empty() or victim == hull:
		game.notify("Select another ship with Tab before launching this hull.")
		return false
	var direction: Vector2 = (victim.position-hull.position).normalized()
	game.npcs.erase(hull)
	game.target_index = game.npcs.find(victim)
	game.shots.append({"node":hull.model,"weapon":id,"kind":"ship_ram",
		"position":hull.position,"velocity":direction*1100,"speed":1100.0,
		"enemy":false,"source":{},"npc_shot":false,"target":victim.model,"victim":victim,"life":30.0,"radius":hull.radius})
	ship_weapons.erase(id)
	game.pilot.selected_weapon = 128
	game.notify("Ship launched at %s!" % victim.name)
	return true

func update_ship_ram(shot: Dictionary, dt: float) -> bool:
	var victim: Dictionary = shot.victim
	var previous: Vector2 = shot.position
	if victim in game.npcs:
		shot.velocity = (victim.position-previous).normalized()*shot.speed
	shot.position += shot.velocity*dt
	shot.node.position = game.v3(shot.position)
	shot.node.rotation.y = -Flight.facing(shot.velocity)
	shot.life -= dt
	if victim in game.npcs and game.segment_distance(victim.position,previous,shot.position) <= victim.radius+shot.radius:
		shot.position = Geometry2D.get_closest_point_to_segment(victim.position,previous,shot.position)
		game.ship_explosion(shot.node,shot.position,Vector2.ZERO,3.5)
		game.damage_npc(victim,victim.health+1)
		shot.node.queue_free()
		return true
	if shot.life <= 0 or victim not in game.npcs:
		game.ship_explosion(shot.node,shot.position,Vector2.ZERO)
		shot.node.queue_free()
		return true
	return false

func ids() -> Array:
	var result: Array = []
	for id in game.catalog.data.weapons: result.append(int(id))
	result.sort()
	return result

func kind(id: int) -> String:
	if int(game.catalog.field("weapons",id,"Guidance")) == 99: return "bay"
	if id == 149: return "tractor"
	if id == 150: return "flare"
	if id in [142,147,152]: return "beam"
	if id == 140: return "bomb"
	if id in [131,132,148,191,901]: return "seeker"
	return "bolt"

func description(id: int) -> String:
	if ship_weapons.has(id): return "Launch this resisting ship at your selected contact. Both hulls explode on impact. One use; available in this system. Tab targets, Space launches."
	match kind(id):
		"bay": return "Launches an escort that attacks your selected contact or nearby hostiles. Up to 12 escorts; new launches replace the oldest."
		"tractor": return "Hold Space to pull the selected contact toward your ship. Range: 900."
		"flare": return "Drops a decoy that draws nearby incoming guided weapons away from your ship."
		"beam": return "A rapid beam weapon. Keep your nose pointed at the target and hold Space."
		"bomb": return "Drops a slow bomb that detonates near contacts, damaging ships around the blast."
		"seeker": return "Tracks the selected contact, or the nearest hostile. Tab selects a contact."
	if id in [133,134]: return "Turret aims at your selected contact, or the nearest hostile, in any direction."
	if id == 143: return "Rear turret fires aft and tracks contacts within its rear arc."
	if id == 144: return "Swivel cannon tracks contacts within its forward arc."
	return "Forward-firing weapon. Point your ship at the target and hold Space."

func tint(id: int) -> Color:
	if id==900: return Color("ffe6a3")
	if id in [129,147,152]: return Color("bb7aff")
	if id in [130,134]: return Color("8dff9e")
	if id in [131,132,139,140,141]: return Color("ffc36b")
	if id == 135: return Color("eeeeff")
	if id in [148,149]: return Color("68ffbc")
	if id in [150,191]: return Color("ffdd77")
	return Color("82f8ff")

func target(pos: Vector2, selected: bool = true) -> Dictionary:
	var contact: Dictionary = game.selected_contact()
	if selected and not contact.is_empty(): return contact
	var nearest: Dictionary = {}
	var distance: float = INF
	for npc in game.npcs:
		var d: float = pos.distance_squared_to(npc.position)
		if npc.hostile and d < distance:
			distance = d
			nearest = npc
	return nearest

func weapon_sound_key(id: int) -> String:
	if id==901: return "sidewinder_launch"
	var sound: int=int(game.catalog.field("weapons",id,"Sound"))
	return "weapon_%d" % (200+sound) if sound>=0 else ""

func play_weapon_sound(id: int,pos: Vector2) -> void:
	if game.muted: return
	var key="maverick_gun" if id==900 else weapon_sound_key(id)
	if not game.audio.has(key): return
	var player: AudioStreamPlayer=game.audio[key]
	# Rapid beam ticks sustain the sample rather than restarting it every frame.
	if kind(id) in ["beam","tractor"] and player.playing: return
	var distance: float=pos.distance_to(game.pilot.position)
	if distance>2400: return
	player.volume_db=-10.0-linear_to_db(1.0+distance/350.0)
	if id==900:
		gun_audio_hold=.14
		if player.playing: return
	player.play()

func advance_gun_audio(dt: float) -> void:
	gun_audio_hold=maxf(0,gun_audio_hold-dt)
	if game.mode!="flight" or game.muted: gun_audio_hold=0
	if gun_audio_hold<=0 and game.audio.maverick_gun.playing: game.audio.maverick_gun.stop()

func fire(id: int, pos: Vector2, heading: float, enemy: bool = false, source: Dictionary = {}, target_override: Dictionary = {}) -> bool:
	if ship_weapons.has(id) and not enemy and source.is_empty(): return fire_ship(id)
	var weapon = game.catalog.record("weapons",id)
	if weapon.is_empty(): return false
	var fields: Dictionary = weapon.fields
	var type: String = kind(id)
	var npc_shot: bool = not source.is_empty()
	var contact: Dictionary = target_override if npc_shot else ({} if enemy else target(pos))
	if type == "bay":
		if npc_shot:
			var launched: bool=game.traffic.launch_fighter(source,int(fields.AmmoType))
			if launched: play_weapon_sound(id,pos)
			return launched
		launch_escort(int(fields.AmmoType),pos,heading)
		play_weapon_sound(id,pos)
		return true
	play_weapon_sound(id,pos)
	if id in [132,901] and (int(source.id)==900 if npc_shot else game.pilot.ship_id==900) and not game.muted:
		var distance: float=pos.distance_to(game.pilot.position)
		if distance<2400:
			game.audio.maverick_missile.volume_db=-12-linear_to_db(1.0+distance/350.0)
			game.sound("maverick_missile")
	var direction = Vector2(sin(heading),-cos(heading))
	if id == 143: direction = -direction
	if not contact.is_empty() and id in [133,134,143,144,149]:
		var aim: Vector2 = (contact.position-pos).normalized()
		if id in [133,134,149] or direction.dot(aim) > (0.5 if id==144 else 0.0): direction = aim
	if type in ["beam","tractor"]:
		fire_beam(id,pos,direction,contact,source,enemy)
		return true
	var muzzle: float = maxf(35,float(source.get("radius",0))+8)
	var origin = pos + direction * (maxf(48,muzzle) if type in ["bomb","flare"] else muzzle)
	if type in ["bomb","flare"]: origin = pos-direction*45
	if id==901:
		var launcher: Node3D=source.get("model") if npc_shot else game.player_model
		origin=preload("res://scripts/maverick.gd").missile_origin(launcher,pos,heading)
	var color: Color = Color("ff896f") if enemy else tint(id)
	var dimensions = Vector3(2,2,7) if id==900 else Vector3(3,3,22)
	if type == "seeker" or id in [139,141]: dimensions = Vector3(7,5,26)
	if type in ["bomb","flare"]: dimensions = Vector3(12,8,12)
	if id == 191: dimensions = Vector3(22,12,28)
	var node: Node3D
	if id==191:
		node=Forklift.create();game.world.add_child(node);node.position=game.v3(origin,6)
	elif id in ProjectileModels.IDS or id==901:
		node=ProjectileModels.create(132 if id==901 else id);game.world.add_child(node);node.position=game.v3(origin,6)
	else:
		node=game.Models.box(game.world,game.v3(origin,6),dimensions,game.Models.material(color,0,2))
	node.rotation.y = -Flight.facing(direction)
	var lifetime: float = clampf(float(fields.Count)/60.0,0.3,20.0)
	if id == 128: lifetime = 1.5 # Preserve the existing normal laser's range.
	var speed: float = minf(230,float(fields.Speed)) if id==901 else float(fields.Speed)
	var target_node = contact.get("model") if npc_shot else (game.player_model if enemy else contact.get("model"))
	game.shots.append({"node":node,"weapon":id,"kind":type,"position":origin,
		"velocity":direction*speed,"speed":speed,"enemy":enemy,"life":lifetime,
		"damage":maxf(game.Combat.powers(fields).x,game.Combat.powers(fields).y),"shield_damage":game.Combat.powers(fields).x,"armor_damage":game.Combat.powers(fields).y,
		"blast":float(fields.BlastRadius)*2.0,"proximity":float(fields.ProxRadius),
		"target":target_node,"color":color,"source":source,"npc_shot":npc_shot})
	return true

func fire_beam(id: int, pos: Vector2, direction: Vector2, contact: Dictionary, source: Dictionary = {}, enemy: bool = false) -> void:
	var reach: float = 900 if id==149 else 1050
	var obstacle: Dictionary=game.environment_hazards.obstruction(pos,pos+direction*reach)
	if not obstacle.is_empty(): reach=float(obstacle.distance)
	var end = pos+direction*reach
	var hit: Dictionary = {}
	var distance: float = reach
	var hits_player: bool = false
	var context = {"source":source,"npc_shot":not source.is_empty()}
	for npc in game.npcs:
		if not game.traffic.can_hit(context,npc): continue
		var projection: float = (npc.position-pos).dot(direction)
		if projection > 0 and projection < distance and game.segment_distance(npc.position,pos,end)<npc.radius:
			hit=npc;distance=projection
	if enemy or (game.pilot.cheat_deflection and not source.is_empty()):
		var projection: float = (game.pilot.position-pos).dot(direction)
		if projection>0 and projection<distance and game.segment_distance(game.pilot.position,pos,end)<22:
			hits_player=true;hit={};distance=projection
	var world_hit: Dictionary=game.world_killer.shot_intersection(pos,pos+direction*distance,{"weapon":id,"source":source,"enemy":enemy,"npc_shot":not source.is_empty()})
	if not world_hit.is_empty() and float(world_hit.distance)<distance:
		distance=float(world_hit.distance);hit={};hits_player=false
		game.world_killer.hit_target(world_hit.position)
	end=pos+direction*distance
	if hits_player:
		var fields: Dictionary=game.catalog.record("weapons",id).fields
		if game.pilot.cheat_deflection:
			var return_end: Vector2 = source.position if source in game.npcs else pos
			var return_delta: Vector2 = return_end-end
			var reflected=game.Models.box(game.world,game.v3((end+return_end)*0.5,8),Vector3(7,5,return_delta.length()),game.Models.material(tint(id),0,3))
			reflected.rotation.y=-Flight.facing(return_delta)
			game.shots.append({"node":reflected,"weapon":id,"kind":"beam_visual","position":(end+return_end)*0.5,
				"velocity":Vector2.ZERO,"enemy":false,"life":0.12,"damage":0.0,"blast":0.0,"proximity":0.0,"color":tint(id),"source":{},"npc_shot":false})
			if source in game.npcs:
				if id==149:
					var push: Vector2 = return_delta.normalized()*18
					source.position += push
					source.velocity += push*4
					source.model.position=game.v3(source.position)
				else:
					game.damage_npc(source,game.Combat.powers(fields).x,{},Vector2.ZERO,false,game.Combat.powers(fields).y)
		else:
			game.damage_player(game.Combat.powers(fields).x,-direction,game.Combat.powers(fields).y)
	if not hit.is_empty():
		if id==149:
			# Only pull the aimed-at contact, avoiding accidental damage or hostility.
			if hit==contact:
				var pull: Vector2 = (pos-hit.position).normalized()*18
				hit.position += pull
				hit.velocity += pull*4
				hit.model.position=game.v3(hit.position)
		else:
			var fields: Dictionary=game.catalog.record("weapons",id).fields
			game.damage_npc(hit,game.Combat.powers(fields).x,source,-direction,false,game.Combat.powers(fields).y)
	var midpoint=(pos+end)*0.5
	var node=game.Models.box(game.world,game.v3(midpoint,7),Vector3(5,4,distance),game.Models.material(tint(id),0,3))
	node.rotation.y=-Flight.facing(direction)
	game.shots.append({"node":node,"weapon":id,"kind":"beam_visual","position":midpoint,
		"velocity":Vector2.ZERO,"enemy":enemy,"life":0.07,"damage":0.0,"blast":0.0,"proximity":0.0,"color":tint(id),"source":source,"npc_shot":not source.is_empty()})

func steer(shot: Dictionary, dt: float) -> void:
	if int(shot.get("weapon",-1))==901:
		shot.boost_age=float(shot.get("boost_age",0))+dt
		var cruise: float=float(game.catalog.field("weapons",901,"Speed"))
		shot.speed=lerpf(minf(230,cruise),cruise,smoothstep(.15,.7,shot.boost_age))
		shot.velocity=shot.velocity.normalized()*shot.speed
	if shot.kind != "seeker" and not shot.get("reflected",false): return
	var destination: Node3D = shot.target if is_instance_valid(shot.target) else null
	if shot.enemy:
		if game.cloak.active: destination=null
		# A live flare can divert an incoming guided weapon.
		for decoy in game.shots:
			if decoy.kind=="flare" and not decoy.enemy and shot.position.distance_to(decoy.position)<500:
				destination=decoy.node
				break
	if destination==null: return
	var target_pos=Vector2(destination.position.x,destination.position.z)
	var turn_rate: float=guidance_rate(shot)
	var angle=rotate_toward(Flight.facing(shot.velocity),Flight.facing(target_pos-shot.position),dt*turn_rate)
	shot.velocity=Vector2(sin(angle),-cos(angle))*shot.speed
	shot.node.rotation.y=-angle

func launch_escort(ship_id: int, pos: Vector2, heading: float) -> void:
	var temporary_count: int = 0
	for escort in game.escorts:
		if not escort.get("captured",false): temporary_count += 1
	if temporary_count>=MAX_ESCORTS:
		for escort in game.escorts:
			if not escort.get("captured",false):
				escort.model.queue_free()
				game.escorts.erase(escort)
				break
	var model=game.ShipModels.create(game.catalog,ship_id,-1)
	game.world.add_child(model)
	var offset=Vector2(sin(heading),-cos(heading))*65
	model.position=game.v3(pos+offset)
	game.escorts.append({"model":model,"position":pos+offset,"heading":heading,"cooldown":0.3,
		"id":ship_id,"name":game.catalog.record("ships",ship_id).name,"captured":false})

func launch_captured_ship(ship_id: int, pos: Vector2, heading: float) -> void:
	game.fleet_service.spawn_last(ship_id,pos,heading)

func restore_captured_fleet() -> void:
	game.fleet_service.restore()

func update_escorts(dt: float) -> void:
	for escort in game.escorts:
		if escort.get("captured",false): continue
		if escort.has("arrival_delay"):
			escort.arrival_delay-=dt
			if escort.arrival_delay>0: continue
			escort.erase("arrival_delay")
			var forward=Vector2(sin(game.pilot.heading),-cos(game.pilot.heading))
			var side=forward.orthogonal()
			var slot: int=game.escorts.find(escort)
			escort.position=game.pilot.position-forward*(100+slot*18)+side*((slot%2)*2-1)*(45+slot*12)
			escort.heading=game.pilot.heading
			escort.arrival_visual=EVJumpVisuals.new()
			escort.arrival_visual.arrive()
			escort.model.show()
		if escort.has("arrival_visual"):
			var visual=escort.arrival_visual
			escort.position+=game.velocity*dt
			escort.model.position=game.v3(escort.position)
			escort.model.rotation.y=-escort.heading
			escort.model.scale=visual.ship_scale(game.hyperdrive)
			game.Models.set_thrust(escort.model,1.2,game.time)
			visual.advance(dt)
			if visual.arrival_age<0:
				escort.model.scale=Vector3.ONE
				escort.erase("arrival_visual")
			continue
		var contact=target(escort.position)
		if not contact.is_empty() and (contact.disabled or contact.truce): contact = {}
		var goal: Vector2=game.pilot.position+Vector2(100,80).rotated(float(game.escorts.find(escort)))
		if not contact.is_empty(): goal=contact.position
		var offset: Vector2=goal-escort.position
		escort.heading=rotate_toward(escort.heading,Flight.facing(offset),dt*3)
		var direction=Vector2(sin(escort.heading),-cos(escort.heading))
		var speed: float=game.catalog.field("ships",escort.id,"Speed")
		escort.position+=direction*minf(speed,offset.length()*2)*dt
		escort.model.position=game.v3(escort.position)
		escort.model.rotation.y=-escort.heading
		game.Models.set_thrust(escort.model,0.7,game.time)
		escort.cooldown-=dt
		if not contact.is_empty() and escort.cooldown<=0 and offset.length()<700 and direction.dot(offset.normalized())>0.9:
			fire(128,escort.position,escort.heading)
			escort.cooldown=0.45

func remove_cheat_weapons() -> void:
	for i in range(game.shots.size()-1,-1,-1):
		var shot=game.shots[i]
		if shot.kind != "ship_ram" and not shot.enemy and not shot.get("npc_shot",false) and shot.weapon not in game.outfitter.weapon_ids():
			shot.node.queue_free()
			game.shots.remove_at(i)
	for i in range(game.escorts.size()-1,-1,-1):
		if not game.escorts[i].get("captured",false):
			game.escorts[i].model.queue_free()
			game.escorts.remove_at(i)

# Predict the first direct collision, accounting for the target's drift. This
# is a reaction to a threat, not a guarantee: a ship can still evade afterward.
func lethal_impact_target(shot: Dictionary) -> Dictionary:
	if shot.get("enemy",false) or shot.get("npc_shot",false) or shot.kind in ["flare","beam_visual"]: return {}
	if shot.get("damage",0)<=0: return {}
	var earliest: float=minf(PANIC_LEAD_SECONDS,float(shot.life))
	var victim: Dictionary={}
	for npc in game.npcs:
		if not game.traffic.can_hit(shot,npc): continue
		var offset: Vector2=shot.position-npc.position
		var relative: Vector2=shot.velocity-npc.velocity
		var radius: float=npc.radius+shot.proximity
		var a: float=relative.length_squared()
		var b: float=offset.dot(relative)
		var c: float=offset.length_squared()-radius*radius
		if a<.001 or b>=0: continue
		var discriminant: float=b*b-a*c
		if discriminant<0: continue
		var entry: float=maxf(0,(-b-sqrt(discriminant))/a)
		if entry>earliest: continue
		earliest=entry
		victim=npc
	if victim.is_empty() or victim.get("hector",false) or victim.health<=0: return {}
	game.Combat.sync(victim)
	var remaining: Vector2=game.Combat.hit(victim.shield,victim.armor,float(shot.get("shield_damage",shot.damage)),float(shot.get("armor_damage",shot.damage)))
	if remaining.x+remaining.y>0: return {}
	if shot.position.distance_to(victim.position)>2200 or victim.position.distance_to(game.pilot.position)>2600: return {}
	return victim

func warn_lethal_impact(shot: Dictionary) -> void:
	if game.mode!="flight" or game.muted: return
	var victim=lethal_impact_target(shot)
	if victim.is_empty() or victim.get("panic_called",false): return
	for key in PANIC_KEYS + DEATH_KEYS:
		if game.audio[key].playing: return
	victim.panic_called=true
	panic_key=next_panic(int(victim.faction))
	panic_owner=victim.model
	game.sound(panic_key)

func stop_panic_for(npc: Dictionary) -> void:
	# Match the speaker, not just whichever audio clip happens to be playing.
	if is_instance_valid(panic_owner) and panic_owner==npc.model:
		game.audio[panic_key].stop()
		panic_owner=null
		panic_key=""

func reset_panic() -> void:
	for key in PANIC_KEYS + DEATH_KEYS:
		if game.audio.has(key): game.audio[key].stop()
	panic_owner=null
	panic_key=""

func panic_group(faction: int) -> String:
	match faction:
		128,143,145,149: return "confed"
		129,144,146,153: return "rebel"
		130: return "pirate"
		140,150: return "alien"
	return "civilian"

func next_panic(faction: int=136) -> String:
	var group=panic_group(faction)
	var bag: Array=panic_bags.get(group,[])
	if bag.is_empty():
		bag=PANIC_POOLS[group].duplicate()
		bag.shuffle()
		if bag.back()==last_panics.get(group,""):
			var swap=bag[0]
			bag[0]=bag[-1]
			bag[-1]=swap
	var key: String=bag.pop_back()
	panic_bags[group]=bag
	last_panics[group]=key
	return key

func death_cry(npc: Dictionary) -> bool:
	if game.mode not in ["flight","dead"] or game.muted or npc.health>0: return false
	var fields: Dictionary=game.catalog.record("ships",int(npc.get("id",128))).get("fields",{})
	var crew: int=int(fields.get("Crew",1))
	var mass: float=float(fields.get("Mass",0))
	var family: String="alien" if panic_group(int(npc.faction))=="alien" else "human"
	var size: String="single"
	if crew>=100 or mass>=300:
		size="crowd"
	elif crew>=6:
		size="crew"
	var key: String=next_death(family+"_"+size)
	last_death_key=key
	game.sound(key)
	return true

func next_death(group: String) -> String:
	var bag: Array=death_bags.get(group,[])
	if bag.is_empty():
		bag=DEATH_POOLS[group].duplicate()
		bag.shuffle()
		if bag.back()==last_deaths.get(group,""):
			var swap=bag[0]
			bag[0]=bag[-1]
			bag[-1]=swap
	var key: String=bag.pop_back()
	death_bags[group]=bag
	last_deaths[group]=key
	return key

func guidance_rate(shot: Dictionary) -> float:
	# Original description specifies inaccurate missiles, not immune torpedoes.
	# The reduction is remake tuning; no original numeric value is available.
	if shot.enemy and int(shot.weapon)==132 and game.pilot.outfit_count(158)>0 and not shot.get("reflected",false): return .6
	return 2.4
