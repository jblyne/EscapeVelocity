extends RefCounted

# An intentional remake feature. Its countdown uses flight time, including
# flight in other systems; every menu pauses it with the rest of the simulation.
const State=preload("res://scripts/campaign_state.gd")
const Rupture=preload("res://scripts/planet_rupture.gd")
const COUNTDOWN: float=120.0
const PLEA_AFTER: float=12.0
const MAX_BRIBE: int=1000000000
var negotiation_rng=RandomNumberGenerator.new()

const DeathStar=preload("res://scripts/death_star.gd")
const APPROACH_DISTANCE: float=400.0
var game
var station: Node3D
var audio_phase: String=""
var warning_shell: MeshInstance3D
var effects: Array=[]
var remnants: Array=[]
var plea_pending: bool=false
var launch_preview: bool=false
var shake: float=0
var live_message: String=""
var broadcast_slot: int=-1
var evacuation_slot: int=-1
var personality: int=0
var previous_phrase: String=""
var last_spared_id: int=-1

func _init() -> void:
	negotiation_rng.randomize()

static func fresh() -> Dictionary:
	return {"destroyed":[],"threatened":[],"active":{}}

static func valid(value: Variant,catalog) -> bool:
	if not value is Dictionary: return false
	for key in ["destroyed","threatened"]:
		if not value.get(key) is Array or value[key].size()>catalog.data.objects.size(): return false
		var seen: Array=[]
		for id in value[key]:
			if not State.integer(id,128,32767) or catalog.record("objects",int(id)).is_empty() or int(id) in seen: return false
			var obj: Dictionary=catalog.record("objects",int(id))
			seen.append(int(id))
	if not value.get("active") is Dictionary: return false
	var bomb: Dictionary=value.active
	if bomb.is_empty(): return true
	if not State.integer(bomb.get("id"),128,32767): return false
	var obj: Dictionary=catalog.record("objects",int(bomb.id))
	if obj.is_empty() or int(bomb.id) in value.destroyed or int(bomb.id) not in value.threatened: return false
	if not State.integer(bomb.get("system"),128,32767) or int(bomb.system)!=int(obj.fields.System): return false
	if not State.integer(bomb.get("sequence",1),1,3): return false
	var sequence: int=int(bomb.get("sequence",1))
	if sequence not in [1,2,3]: return false
	if sequence==1 and bomb.get("phase") not in ["flight","armed"]: return false
	if sequence>=2 and bomb.get("phase") not in ["warping","approach","holding","charging","firing"]: return false
	var fields: Array=["x","y","anchor_x","anchor_y","heading","remaining","elapsed"]
	if sequence>=2: fields.append_array(["start_x","start_y"])
	for key in fields:
		var v=bomb.get(key)
		if not (v is int or v is float) or not is_finite(float(v)) or absf(float(v))>10000000: return false
	if bomb.remaining<=0 or bomb.remaining>COUNTDOWN or bomb.elapsed<0: return false
	var center=Vector2(obj.fields.xPos,obj.fields.yPos)
	var radius: float=float(catalog.stellar_type(int(obj.fields.Type)).sprite.width)*1.25
	var anchor=Vector2(bomb.anchor_x,bomb.anchor_y)
	if sequence==1:
		if bomb.phase=="flight" and not is_equal_approx(float(bomb.remaining),COUNTDOWN): return false
		if absf(center.distance_to(anchor)-radius-38.0)>1.0: return false
		if bomb.phase=="armed" and Vector2(bomb.x,bomb.y).distance_to(anchor)>1.0: return false
	else:
		var gap: float=45.0 if sequence==2 else DeathStar.STANDOFF_GAP
		if absf(center.distance_to(anchor)-radius-DeathStar.RADIUS-gap)>1.0: return false
		var start=Vector2(bomb.start_x,bomb.start_y)
		var expected: Vector2=anchor+(anchor-center).normalized()*APPROACH_DISTANCE
		if start.distance_to(expected)>1.0: return false
		if not is_equal_approx(float(bomb.elapsed),COUNTDOWN-float(bomb.remaining)): return false
		if bomb.phase!=phase_for(float(bomb.remaining),sequence): return false
		if Vector2(bomb.x,bomb.y).distance_to(sequence_position(bomb))>1.0: return false
	for key in ["plea_sent","denied"]:
		if not bomb.get(key) is bool: return false
	if bomb.has("voice") and not State.integer(bomb.voice,0,3): return false
	if not State.integer(bomb.get("money_demands",0),0,120): return false
	if not State.integer(bomb.get("under_fire_hits",0),0,1000000): return false
	var pressure=bomb.get("pressure_next",0)
	if not (pressure is int or pressure is float) or not is_finite(float(pressure)) or pressure<0 or pressure>COUNTDOWN: return false
	if not State.integer(bomb.get("demand_result",-1),-1,1): return false
	for key in ["countdown_rate","demand_next"]:
		var number=bomb.get(key,1.0 if key=="countdown_rate" else 0.0)
		if not (number is int or number is float) or not is_finite(float(number)): return false
		if key=="countdown_rate" and (number<1 or number>3): return false
		if key=="demand_next" and (number<0 or number>COUNTDOWN): return false
	var bribe_keys: Array=["bribe_offer","bribe_round","bribe_next"]
	var has_bribe: bool=bribe_keys.any(func(key):return bomb.has(key))
	if has_bribe:
		if not bribe_keys.all(func(key):return bomb.has(key)): return false
		if not State.integer(bomb.bribe_offer,0,MAX_BRIBE) or not State.integer(bomb.bribe_round,0,120): return false
		var next=bomb.bribe_next
		if not (next is int or next is float) or not is_finite(float(next)) or (next!=-1 and (next<0 or next>COUNTDOWN)): return false
		if int(bomb.bribe_round)==0 and (int(bomb.bribe_offer)!=0 or next!=-1): return false
		if int(bomb.bribe_round)>0 and (int(bomb.bribe_offer)<1000 or not bomb.plea_sent): return false
	return true

static func phase_for(remaining: float,sequence: int=3) -> String:
	var warp: float=3.0 if sequence==2 else DeathStar.WARP_SECONDS
	if remaining>COUNTDOWN-warp: return "warping"
	if remaining>DeathStar.STOP_REMAINING: return "approach"
	if remaining>DeathStar.CHARGE_REMAINING: return "holding"
	if remaining>DeathStar.FIRE_REMAINING: return "charging"
	return "firing"

static func sequence_position(b: Dictionary) -> Vector2:
	var warp: float=3.0 if int(b.get("sequence",3))==2 else DeathStar.WARP_SECONDS
	var progress: float=clampf((COUNTDOWN-float(b.remaining)-warp)/(COUNTDOWN-DeathStar.STOP_REMAINING-warp),0,1)
	return Vector2(b.start_x,b.start_y).lerp(Vector2(b.anchor_x,b.anchor_y),smoothstep(0,1,progress))

static func normalized(value: Dictionary,catalog) -> Dictionary:
	var result=fresh()
	for key in ["destroyed","threatened"]:
		for id in value[key]: result[key].append(int(id))
	result.active=value.active.duplicate(true)
	if not result.active.is_empty():
		var b: Dictionary=result.active
		b.id=int(b.id);b.system=int(b.system)
		for key in ["bribe_offer","bribe_round","bribe_next"]: b[key]=b.get(key,-1 if key=="bribe_next" else 0)
		if b.plea_sent and int(b.bribe_offer)==0:
			# Stable migration: reopening an older save cannot reroll its offer.
			var tech: int=clampi(int(catalog.field("objects",int(b.id),"TechLevel")),0,10)
			b.bribe_offer=25000+tech*5000+(int(b.id)%35)*1000;b.bribe_round=1
			var elapsed: float=COUNTDOWN-float(b.remaining)
			if b.denied and elapsed+12<COUNTDOWN-1: b.bribe_next=elapsed+12
		if int(b.get("sequence",1))<3:
			# Upgrade deployed missiles in existing pilots, keeping their remaining
			# time and mercy/refusal state rather than resetting the ultimatum.
			var f: Dictionary=catalog.record("objects",int(b.id)).fields
			var center=Vector2(f.xPos,f.yPos)
			var away: Vector2=(Vector2(b.anchor_x,b.anchor_y)-center).normalized()
			var radius: float=float(catalog.stellar_type(int(f.Type)).sprite.width)*1.25
			var anchor: Vector2=center+away*(radius+DeathStar.RADIUS+DeathStar.STANDOFF_GAP)
			var start: Vector2=anchor+away*APPROACH_DISTANCE
			b.sequence=3;b.anchor_x=anchor.x;b.anchor_y=anchor.y;b.start_x=start.x;b.start_y=start.y
			b.elapsed=COUNTDOWN-float(b.remaining);b.phase=phase_for(b.remaining)
			var pos: Vector2=sequence_position(b);b.x=pos.x;b.y=pos.y
			b.heading=atan2((center-anchor).x,-(center-anchor).y)
	return result

func state() -> Dictionary: return game.pilot.world_killer
func destroyed(id: int) -> bool: return id in state().destroyed
func bomb() -> Dictionary: return state().active
func target_position(id: int) -> Vector2:
	var f: Dictionary=game.catalog.record("objects",id).fields
	return Vector2(f.xPos,f.yPos)
func target_radius(id: int) -> float:
	return game.StellarModels.radius(game.catalog.stellar_type(int(game.catalog.field("objects",id,"Type"))))
func world_name(id: int) -> String: return game.catalog.record("objects",id).name

func reset_visuals() -> void:
	if is_instance_valid(station): station.queue_free()
	station=null;stop_audio()
	clear_warning_shell()
	effects.clear();remnants.clear();shake=0;launch_preview=false;plea_pending=false;broadcast_slot=-1;evacuation_slot=-1

func restore_visuals() -> void:
	reset_visuals()
	if not bomb().is_empty():
		personality=int(bomb().get("voice",int(bomb().id)%4))
		if is_instance_valid(game.hud): broadcast()
		plea_pending=bool(bomb().plea_sent) and not bool(bomb().denied)
		if int(bomb().system)==game.pilot.system_id: create_station()
	for id in state().destroyed:
		if int(game.catalog.field("objects",int(id),"System"))==game.pilot.system_id:
			create_remnant(int(id),true)

func is_space_station(id: int) -> bool:
	return game.catalog.stellar_type(int(game.catalog.field("objects",id,"Type"))).kind=="station"

func reason(id: int) -> String:
	if not game.pilot.cheat_world_killer: return "Enable Death Star in the cheat menu first."
	var obj: Dictionary=game.catalog.record("objects",id)
	if obj.is_empty(): return "No target selected."
	if destroyed(id): return "Only a debris field remains."
	if int(obj.fields.System)!=game.pilot.system_id: return "Travel to this world before deploying a weapon."
	if not int(obj.fields.Flags)&1 or int(obj.fields.Flags)&32: return "No local authority answers your threat."
	if not bomb().is_empty(): return "A world-killer is already deployed. Resolve that countdown first."
	if game.hyperdrive.active() or not game.chain_route.is_empty(): return "Cancel hyperspace before deploying."
	return ""

func greeting(id: int) -> String:
	var text=base_greeting(id)
	var memory: String=game.pilot.History.recollection(game.pilot,"world:%d" % id)
	if not memory.is_empty() and bomb().is_empty() and not destroyed(id): text+="\n\n"+memory
	return text

func base_greeting(id: int) -> String:
	if destroyed(id): return "Dead channel. This world's signal has gone silent."
	if not bomb().is_empty() and int(bomb().id)==id:
		if bomb().plea_sent and int(bomb().get("bribe_offer",0))>0: return bribe_message()
		if bomb().denied: return "You refused our appeal. Our evacuation channels are overwhelmed. Please reconsider."
		if bomb().phase in ["charging","firing"]: return "That station is charging its superlaser! Please, captain. There are people down here."
		return "That is no moon! Recall that battle station immediately!"
	var obj: Dictionary=game.catalog.record("objects",id)
	if not int(obj.fields.Flags)&1 or int(obj.fields.Flags)&32: return "No response. The surface is silent."
	if game.world_activity.fear(id).compliant: return "Control here. We have seen what happened to the other worlds. Your landing clearance is granted, captain. Our port services are at your disposal. Please, spare us."
	if id in state().threatened: return "We remember your threat. Keep that weapon away from our world."
	if not game.world_activity.landing_reason(id).is_empty() or id%3==0:
		return "Oh, another self-important captain. Stop cluttering our comms, you flying scrap heap. State your business or get lost."
	return ("Station control" if is_space_station(id) else "Planetary control")+" here. Welcome, captain. State your business."

func threaten() -> void:
	if game.mode!="world_comms": return
	var id: int=game.world_activity.contact_id
	var blocked: String=reason(id)
	if not blocked.is_empty(): game.world_activity.response=blocked;game.hud.rebuild_modal();return
	game.world_activity.remember("threatened",id)
	if id not in state().threatened: state().threatened.append(id)
	launch_preview=true
	game.world_activity.response="YOU: Apologize, or I deploy a world-killer.\n\n%s: You're bluffing. You wouldn't dare." % ("STATION CONTROL" if is_space_station(id) else "PLANETARY CONTROL")
	game.save_game(false);game.hud.rebuild_modal()

func deploy() -> bool:
	if game.mode!="world_comms": return false
	var id: int=game.world_activity.contact_id
	if id not in state().threatened or not reason(id).is_empty(): return false
	var away: Vector2=(game.pilot.position-target_position(id)).normalized()
	if away.length_squared()<.5: away=Vector2.DOWN
	var anchor: Vector2=target_position(id)+away*(target_radius(id)+DeathStar.RADIUS+DeathStar.STANDOFF_GAP)
	var start: Vector2=anchor+away*APPROACH_DISTANCE
	var heading: float=game.Flight.facing(target_position(id)-anchor)
	state().active={"sequence":3,"id":id,"system":game.pilot.system_id,"phase":"warping","x":start.x,"y":start.y,
		"start_x":start.x,"start_y":start.y,"anchor_x":anchor.x,"anchor_y":anchor.y,"heading":heading,
		"remaining":COUNTDOWN,"elapsed":0.0,"plea_sent":false,"denied":false,"bribe_offer":0,"bribe_round":0,"bribe_next":-1}
	launch_preview=false;plea_pending=false
	create_station()
	broadcast_slot=-1;evacuation_slot=-1;personality=negotiation_rng.randi_range(0,3);state().active.voice=personality
	game.set_mode("flight");broadcast();sync_audio()
	game.notify("DEATH STAR arriving at %s. Ultimatum: 02:00. Respond to the live transmission to recall." % world_name(id))
	game.save_game(false);return true

func create_station() -> void:
	if is_instance_valid(station): station.queue_free()
	station=DeathStar.new();station.game=game;game.world.add_child(station);station.setup();pose()

func pose() -> void:
	if bomb().is_empty() or not is_instance_valid(station): return
	var b: Dictionary=bomb()
	station.target_name=world_name(int(b.id))
	station.position=game.v3(Vector2(b.x,b.y),-DeathStar.RADIUS-35);station.rotation.y=-float(b.heading)
	var center: Vector3=game.v3(target_position(int(b.id)),-35 if is_space_station(int(b.id)) else -target_radius(int(b.id))-35)
	var muzzle: Vector3=station.to_global(DeathStar.AXIS*(DeathStar.RADIUS+65))
	var impact: Vector3=center+(muzzle-center).normalized()*target_radius(int(b.id))*.98
	station.update_sequence(float(b.remaining),impact)

func set_audio_state(muted: bool,running: bool) -> void:
	for effect in effects:
		if is_instance_valid(effect) and effect is DeathStar: effect.set_audio_state(muted,running)

func stop_audio() -> void:
	for key in ["death_star_warp","death_star_charge","death_star_fire"]:
		if game.audio.has(key): game.audio[key].stop()
	audio_phase=""

func sync_audio() -> void:
	if bomb().is_empty(): stop_audio();return
	var phase: String=bomb().phase
	if phase==audio_phase: return
	stop_audio();audio_phase=phase
	if game.muted or int(bomb().system)!=game.pilot.system_id: return
	var key: String={"warping":"arrival","charging":"death_star_charge","firing":"death_star_fire"}.get(phase,"")
	if key.is_empty(): return
	var seek: float=0
	if phase=="warping": seek=COUNTDOWN-float(bomb().remaining)
	elif phase=="charging": seek=DeathStar.CHARGE_REMAINING-float(bomb().remaining)
	elif phase=="firing": seek=DeathStar.FIRE_REMAINING-float(bomb().remaining)
	game.audio[key].play(seek)

static func clock(seconds: float) -> String:
	var ticks: int=maxi(0,ceili(seconds))
	return "%02d:%02d" % [ticks/60,ticks%60]

func status() -> String:
	if bomb().is_empty(): return ""
	return "DEATH STAR · %s · %s · %s%s" % [world_name(int(bomb().id)),clock(float(bomb().remaining)),str(bomb().phase).to_upper(), " · INCOMING HAIL" if plea_pending else " · Live transmission"]

func bribe_message() -> String:
	var amount: String=game.hud.commas(int(bomb().get("bribe_offer",0)))
	if int(bomb().get("bribe_round",0))<=1:
		return "Please, captain. Recall the Death Star. Our treasury offers %s credits if you spare our world." % amount
	return "Wait! We have raised more funds. We can offer %s credits. Please accept and recall the Death Star!" % amount

func make_bribe_offer() -> void:
	var b: Dictionary=bomb()
	var previous: int=int(b.get("bribe_offer",0))
	if previous==0:
		var tech: int=maxi(0,int(game.catalog.field("objects",int(b.id),"TechLevel")))
		b.bribe_offer=negotiation_rng.randi_range(20,80)*1000+mini(tech,10)*5000
	else:
		var urgency: float=(COUNTDOWN-float(b.remaining))/COUNTDOWN
		var increase: int=int(ceil((previous*negotiation_rng.randf_range(.18,.6)+negotiation_rng.randi_range(1000,6000)+previous*urgency*.15)/1000.0))*1000
		b.bribe_offer=mini(MAX_BRIBE,previous+increase)
	b.bribe_round=int(b.get("bribe_round",0))+1;b.bribe_next=-1
	b.demand_result=-1
	b.denied=false;b.plea_sent=true;plea_pending=true;broadcast_slot=-1

func shot_intersection(start: Vector2,end: Vector2,shot: Dictionary) -> Dictionary:
	var b=bomb()
	if game.mode!="flight" or b.is_empty() or int(b.system)!=game.pilot.system_id: return {}
	if shot.get("enemy",false) or shot.get("npc_shot",false) or not shot.get("source",{}).is_empty(): return {}
	if shot.get("kind","") in ["flare","beam_visual","tractor"] or int(shot.get("weapon",-1))==149 or float(shot.get("damage",1))<=0: return {}
	var center=target_position(int(b.id));var radius=target_radius(int(b.id))
	var delta=end-start;var length=delta.length()
	if length<.0001: return {}
	var direction=delta/length;var projection=(center-start).dot(direction)
	var perpendicular=absf((center-start).cross(direction))
	if perpendicular>radius: return {}
	var distance=maxf(0,projection-sqrt(maxf(0,radius*radius-perpendicular*perpendicular)))
	if start.distance_to(center)>radius and projection<0: return {}
	if distance>length: return {}
	return {"position":start+direction*distance,"distance":distance}

func hit_target(at: Vector2) -> void:
	if bomb().is_empty(): return
	var b=bomb()
	game.burst(at,Color("ffb46d"),18);game.sound("impact")
	b.under_fire_hits=mini(1000000,int(b.get("under_fire_hits",0))+1)
	if float(b.elapsed)>=float(b.get("pressure_next",0)):
		b.pressure_next=minf(COUNTDOWN,float(b.elapsed)+6)
		make_bribe_offer()
		broadcast_slot=-1;broadcast()
		game.world_activity.remember("fired_upon",int(b.id))
		game.save_game(false)
	elif int(b.under_fire_hits)==3:
		broadcast_slot=-1;broadcast();game.save_game(false)

func can_demand_more() -> bool:
	var b=bomb()
	return game.mode=="flight" and not b.is_empty() and b.plea_sent and not b.denied and int(b.get("bribe_offer",0))>0 and int(b.bribe_offer)<MAX_BRIBE and float(b.elapsed)>=float(b.get("demand_next",0)) and int(b.get("money_demands",0))<120

func demand_more() -> bool:
	if not can_demand_more(): return false
	var b=bomb()
	game.world_activity.remember("bribe_demanded",int(b.id))
	b.money_demands=int(b.get("money_demands",0))+1
	b.demand_next=minf(COUNTDOWN,float(b.elapsed)+8)
	if negotiation_rng.randf()<.6:
		make_bribe_offer()
		b.demand_result=1
	else:
		b.demand_result=0
		b.countdown_rate=minf(3,float(b.get("countdown_rate",1))+.5)
	broadcast_slot=-1;broadcast()
	game.save_game(false)
	return true

func accept_bribe() -> bool:
	if game.mode not in ["flight","world_comms"] or bomb().is_empty() or (game.mode=="world_comms" and int(bomb().id)!=game.world_activity.contact_id): return false
	var amount: int=int(bomb().get("bribe_offer",0))
	if not bomb().plea_sent or bomb().denied or amount<=0: return false
	# Clear the active ultimatum through the same recall path before paying.
	# A stale/double button activation therefore cannot collect twice.
	if not spare(false): return false
	game.world_activity.remember("bribe_received",game.world_activity.contact_id if game.mode=="world_comms" else last_spared_id)
	game.pilot.credits+=amount
	game.world_activity.response="BRIBE ACCEPTED · %s credits transferred.\n\nPLANETARY CONTROL: Payment confirmed. Thank you for recalling the Death Star. Our world is spared." % game.hud.commas(amount)
	game.notify("Bribe received: %s cr. Death Star recalled." % game.hud.commas(amount))
	if game.mode=="world_comms": game.set_mode("flight")
	game.save_game(false);game.hud.rebuild_modal();return true

func open_active() -> void:
	if bomb().is_empty() or game.mode not in ["flight","world_comms"]: return
	game.world_activity.contact_id=int(bomb().id)
	if bomb().plea_sent and int(bomb().get("bribe_offer",0))==0: make_bribe_offer();game.save_game(false)
	game.world_activity.response=bribe_message() if int(bomb().get("bribe_offer",0))>0 else "Please, captain. We were wrong. Recall the Death Star. Don't destroy our home."
	launch_preview=false;game.set_mode("world_comms")

func spare(persist: bool=true) -> bool:
	if game.mode not in ["flight","world_comms"] or bomb().is_empty() or (game.mode=="world_comms" and int(bomb().id)!=game.world_activity.contact_id): return false
	var id: int=int(bomb().id)
	last_spared_id=id
	if persist: game.world_activity.remember("spared",id)
	state().active={};plea_pending=false;launch_preview=false;clear_warning_shell()
	if is_instance_valid(station): station.begin_departure(false);effects.append(station)
	station=null;stop_audio();game.sound("cloak_off")
	game.world_activity.response="WORLD-KILLER DISARMED.\n\nPLANETARY CONTROL: Signal confirmed. Thank you, captain. We'll never forget that you spared our world."
	game.notify("%s spared. World-killer safely disarmed." % world_name(id))
	if persist: game.save_game(false);game.hud.rebuild_modal()
	return true

func deny() -> bool:
	if game.mode not in ["flight","world_comms"] or bomb().is_empty() or (game.mode=="world_comms" and int(bomb().id)!=game.world_activity.contact_id): return false
	if bomb().denied: return false
	game.world_activity.remember("appeal_denied",int(bomb().id))
	if int(bomb().get("bribe_offer",0))==0: make_bribe_offer()
	bomb().denied=true;bomb().plea_sent=true;plea_pending=false
	var next: float=float(bomb().elapsed)+negotiation_rng.randf_range(8,18)
	bomb().bribe_next=next if next<COUNTDOWN-1 and int(bomb().bribe_offer)<MAX_BRIBE else -1
	broadcast_slot=-1;broadcast()
	game.set_mode("flight");game.notify("Appeal denied. %s countdown continues: %s." % [world_name(int(bomb().id)),clock(bomb().remaining)])
	game.save_game(false);return true

func advance(dt: float) -> void:
	if game.mode!="flight": return
	for remnant in remnants:
		if is_instance_valid(remnant): remnant.advance(dt)
	for effect in effects.duplicate():
		if not is_instance_valid(effect) or effect.advance(dt):
			effects.erase(effect)
			if is_instance_valid(effect): effect.queue_free()
	shake=maxf(0,shake-dt)
	if bomb().is_empty(): return
	var b: Dictionary=bomb()
	var before: float=float(b.remaining)
	b.remaining=maxf(0,before-dt*float(b.get("countdown_rate",1)))
	if float(b.remaining)<.0000001: b.remaining=0.0
	b.elapsed=COUNTDOWN-float(b.remaining)
	b.phase=phase_for(float(b.remaining))
	var pos: Vector2=sequence_position(b);b.x=pos.x;b.y=pos.y
	pose();sync_audio()
	if before>DeathStar.STOP_REMAINING and b.remaining<=DeathStar.STOP_REMAINING:
		game.notify("DEATH STAR in position. Holding beside %s. 00:20 remaining." % world_name(int(b.id)))
	if before>DeathStar.CHARGE_REMAINING and b.remaining<=DeathStar.CHARGE_REMAINING:
		game.notify("DEATH STAR: superlaser charging. Convergence sequence initiated.")
	if before>DeathStar.FIRE_REMAINING and b.remaining<=DeathStar.FIRE_REMAINING:
		game.notify("DEATH STAR: superlaser firing!")
	if b.remaining<=0:
		detonate();return
	if not b.plea_sent and b.remaining<=COUNTDOWN-PLEA_AFTER:
		make_bribe_offer()
		game.notify("INCOMING HAIL · %s is pleading for its survival." % world_name(int(b.id)))
		game.save_game(false)
	elif float(b.get("bribe_next",-1))>=0 and b.elapsed>=float(b.bribe_next):
		make_bribe_offer()
		game.notify("INCOMING HAIL · %s raises its bribe to %s cr. Respond to the live transmission." % [world_name(int(b.id)),game.hud.commas(int(b.bribe_offer))])
		game.save_game(false)
	broadcast()
	evacuate()
	if b.phase=="firing" and int(b.system)==game.pilot.system_id:
		if not is_instance_valid(warning_shell):
			for body in game.planets:
				if int(body.id)!=int(b.id) or is_space_station(int(b.id)): continue
				var surface: MeshInstance3D=body.node.get_node("Surface")
				warning_shell=MeshInstance3D.new();warning_shell.mesh=surface.mesh;warning_shell.scale=Vector3.ONE*1.006
				var mat: ShaderMaterial=surface.material_override.duplicate();mat.shader=preload("res://shaders/planet_crust.gdshader")
				mat.set_shader_parameter("rupture_fade",.65);warning_shell.material_override=mat;surface.add_child(warning_shell)
		if is_instance_valid(warning_shell): warning_shell.material_override.set_shader_parameter("rupture_heat",1.0-float(b.remaining)/DeathStar.FIRE_REMAINING)

func clear_warning_shell() -> void:
	if is_instance_valid(warning_shell): warning_shell.queue_free()
	warning_shell=null

func detonate() -> void:
	if bomb().is_empty(): return
	var id: int=int(bomb().id)
	var local: bool=int(bomb().system)==game.pilot.system_id
	# Commit the destroyed state before mission-failure handlers can save.
	state().active={};state().destroyed.append(id);plea_pending=false;launch_preview=false;clear_warning_shell()
	if is_instance_valid(station): station.begin_departure(true);effects.append(station)
	station=null;stop_audio()
	game.pilot.world_state.dominated.erase(id)
	game.pilot.world_state.events=game.pilot.world_state.events.filter(func(e):return int(game.catalog.field("events",int(e.id),"Stellar"))!=id)
	if int(game.world_activity.siege.get("port",-1))==id: game.world_activity.abort()
	if game.landing_target==id: game.landing_target=-1
	if game.landing_clearance==id: game.landing_clearance=-1
	if not game.pilot.mission.is_empty() and int(game.pilot.mission.object)==id:
		game.pilot.mission={};game.notify("Courier contract failed: destination destroyed.")
	for m in game.pilot.campaign.active.duplicate():
		if int(m.dest)==id or int(m.back)==id or (not m.picked and int(m.origin)==id): game.missions.finish(m,false,false,false,"A required mission destination was obliterated.")
	var gov: int=int(game.catalog.field("objects",id,"Govt"))
	if not game.catalog.record("governments",gov).is_empty(): game.pilot.reputation[str(gov)]=-10000
	if local:
		for body in game.planets.duplicate():
			if int(body.id)!=id: continue
			var effect: Node3D
			if is_space_station(id):
				effect=preload("res://scripts/explosion.gd").new();game.world.add_child(effect)
				effect.position=body.node.position;effect.setup(body.node,Vector2.ZERO,id,3.0)
				var breakup=preload("res://scripts/breakup.gd").new();game.world.add_child(breakup)
				breakup.position=body.node.position;breakup.setup(body.node,Vector2.ZERO,id,2.0);effects.append(breakup)
			else:
				effect=Rupture.new();game.world.add_child(effect);effect.setup(body.node,float(body.radius),id)
			effects.append(effect);body.node.queue_free();game.planets.erase(body)
		create_remnant(id);shake=3.5
		game.sound("explosion");game.sound("arrival")
	game.notify("%s OBLITERATED. Only a shattered debris field remains." % world_name(id))
	game.save_game(false)

func create_remnant(id: int,restored: bool=false) -> void:
	var debris=preload("res://scripts/planet_debris.gd").new();debris.name="ShatteredWorld%d" % id
	game.world.add_child(debris);debris.setup(game.v3(target_position(id),-35 if is_space_station(id) else -90),target_radius(id),id,is_space_station(id),restored)
	remnants.append(debris)

const APPEAL_VOICES=[
	[
		["You have made your little demonstration. Leave our sky.","Our administration does not negotiate with theatrical captains.","You expect us to fear that oversized moon?"],
		["There appears to have been a diplomatic misunderstanding.","Our treasury can settle this inconvenience. Name your terms.","Perhaps we spoke too hastily. Let us resolve this."],
		["The council has authorized everything in the emergency reserve.","Our evacuation ports are overwhelmed. Please take the money.","We withdraw every insult. There is no honor in killing us."],
		["Please. We are begging you. There are children here.","Forget the council. This is a person asking you to let us live.","We have nothing left to offer except our lives. Mercy!"]
	],
	[
		["Your threats are beneath the dignity of this office.","Our people have endured worse than a boastful pilot.","You will regret this breach of protocol."],
		["We request an immediate cessation of hostilities.","The ambassador is prepared to apologize in person.","We can transfer compensation without further formalities."],
		["All officials have signed the surrender. Please acknowledge.","We cannot get everyone onto the transports. Stop this.","There are no conditions. We will accept your demands."],
		["Please hear us. We surrender. We surrender!","The shelters will not save anyone. Please turn it off.","I cannot tell these families there is no hope. Please."]
	],
	[
		["Do you know what this installation is worth? Move along.","An impressive prop. Send your invoice somewhere else.","You are interrupting profitable business, captain."],
		["Let us discuss a mutually profitable alternative.","A goodwill payment is ready. No hard feelings?","Our shareholders have approved an exceptional settlement."],
		["We sold the reserves. It is all yours. Just recall it.","The accounts are emptying into your offer. Please accept.","We cannot buy more time. We can only beg you for it."],
		["The money means nothing. Please save the people.","Take everything. Leave us alive. Please!","I am broadcasting from a nursery shelter. Have mercy."]
	],
	[
		["Ha! You really brought a moon to an argument?","Our grandparents were scarier than you, stranger.","Nice toy. Try not to scratch the paint on your way out."],
		["All right. That joke went too far. We are sorry.","Can we start again? We have gathered a peace offering.","Look, nobody actually wants trouble. Take the credits."],
		["We put our savings together. Every family contributed.","The last transport is full. Thousands are still waiting.","You win! We were fools! Please make it stop!"],
		["We love you! We are sorry! Please let us live!","Somebody answer! Please! We do not want to die!","My family is down there. I am begging you, captain."]
	]
]
func refresh_live() -> void:
	broadcast()

func broadcast() -> void:
	if bomb().is_empty(): return
	var b=bomb()
	var slot: int=int(float(b.elapsed)/12.0)
	if slot==broadcast_slot: return
	broadcast_slot=slot
	var stage: int=0 if b.remaining>90 else 1 if b.remaining>55 else 2 if b.remaining>20 else 3
	if int(b.get("under_fire_hits",0))>0: stage=maxi(stage,2 if int(b.under_fire_hits)<3 else 3)
	var pool: Array=APPEAL_VOICES[personality][stage].filter(func(line):return line!=previous_phrase)
	previous_phrase=pool[negotiation_rng.randi_range(0,pool.size()-1)]
	live_message="%s · %s\n%s" % [world_name(int(b.id)),clock(float(b.remaining)),previous_phrase]
	if int(b.get("under_fire_hits",0))>0: live_message+="\nWe are sorry! Please stop firing. There are people here!"
	if b.denied: live_message+="\nYou rejected their offer. The countdown continues."
	if b.plea_sent and not b.denied:
		live_message+="\nOffer: %s credits to cancel the reckoning." % game.hud.commas(int(b.bribe_offer))
	if float(b.elapsed)<float(b.get("demand_next",0))+4:
		if int(b.get("demand_result",-1))==1: live_message+="\nWe found more credits. Please accept the increased offer!"
		elif int(b.get("demand_result",-1))==0: live_message+="\nNo! We cannot pay more. Countdown accelerated to %.1f×." % float(b.get("countdown_rate",1))
	game.notify(live_message.replace("\n"," · "))
	if stage>=2 and int(b.system)==game.pilot.system_id and negotiation_rng.randf()<.45:
		launch_fireworks(["WE'RE SORRY","WE LOVE YOU!","PLEASE SPARE US","MERCY!"][negotiation_rng.randi_range(0,3)])

func launch_fireworks(words: String) -> void:
	if bomb().is_empty() or int(bomb().system)!=game.pilot.system_id: return
	var id: int=int(bomb().id)
	var occupied: Array=[]
	for effect in effects:
		if is_instance_valid(effect) and effect.get_script()==preload("res://scripts/plea_fireworks.gd") and effect.target_id==id and effect.age<7:
			occupied.append(effect.message_side)
	var side: int=-1 if -1 not in occupied else 1
	# Keep both existing messages readable rather than stacking a third on them.
	if side in occupied: return
	var show=preload("res://scripts/plea_fireworks.gd").new();game.world.add_child(show)
	show.target_id=id
	show.setup(game.v3(target_position(id),150),words,side,target_radius(id)+90);effects.append(show)

func evacuate() -> void:
	if bomb().is_empty() or bomb().remaining>45 or int(bomb().system)!=game.pilot.system_id: return
	var slot: int=int((45.0-float(bomb().remaining))/5.0)
	if slot<=evacuation_slot: return
	evacuation_slot=slot
	var id: int=int(bomb().id)
	var direction=Vector2.from_angle(negotiation_rng.randf_range(0,TAU))
	var origin=target_position(id)+direction*(target_radius(id)+35)
	var transport=game.traffic.spawn([128,129,131][negotiation_rng.randi_range(0,2)],-1,0,origin)
	if transport.is_empty(): return
	var passengers: int=negotiation_rng.randi_range(40,400)
	transport.name="Evacuation transport · %d refugees" % passengers
	transport.evacuees=passengers;transport.evacuation_origin=id;transport.truce=true;transport.hostile=false;transport.weapons=[]
	transport.heading=game.Flight.facing(direction);transport.velocity=direction*60
	game.traffic.request_departure(transport)
	game.notify("%s: transport launching with %d evacuees aboard." % [world_name(id),passengers])
