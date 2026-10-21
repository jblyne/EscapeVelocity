extends RefCounted
# Source përs records; arrival frequency/steering are remake tuning.
var game
var rng=RandomNumberGenerator.new()
var offered: Dictionary={}
func _init() -> void: rng.randomize()
func eligible(id: int) -> bool:
	var r: Dictionary=game.catalog.record("persons",id)
	if r.is_empty() or id==639 or id in game.pilot.persons.gone: return false
	var f: Dictionary=r.fields
	if not game.missions.bit_matches(int(f.MissionBit)): return false
	if game.catalog.record("ships",int(f.ShipType)).is_empty(): return false
	if game.npcs.any(func(n): return n.get("person_id",n.get("escape_owner",-1))==id): return false
	for m in game.pilot.campaign.active:
		if m.actors.any(func(a): return int(a.get("person_id",-1))==id and not a.dead): return false
	var link: int=int(f.LinkSyst)
	if link==-32000: return game.pilot.reputation.values().any(func(score): return int(score)<=-100)
	if link==-1: return true
	if link>=9999: return game.missions.govt_matches(link,int(game.catalog.system(game.pilot.system_id).fields.Govt))
	return link==game.pilot.system_id
func maybe_spawn() -> void:
	if rng.randf()>=.05 or game.npcs.filter(func(n): return n.has("person_id")).size()>=2: return
	var candidates: Array=[]
	for id in game.catalog.data.persons:
		if eligible(int(id)): candidates.append(int(id))
	if not candidates.is_empty(): spawn(candidates[rng.randi_range(0,candidates.size()-1)])
func spawn(id: int) -> Dictionary:
	if id==639:
		if game.hector.spawn(): return game.npcs.back()
		return {}
	if not eligible(id): return {}
	var r: Dictionary=game.catalog.record("persons",id)
	var f: Dictionary=r.fields
	var npc: Dictionary=game.traffic.spawn(int(f.ShipType),int(f.Govt),int(f.AIType),game.pilot.position+Vector2.from_angle(rng.randf()*TAU)*1000)
	if npc.is_empty(): return {}
	configure(npc,id)
	if int(f.Flags)&512: # Board-triggered derelict encounters.
		npc.disabled=true;npc.health=maxf(1,npc.max_health*.1);npc.weapons=[]
	npc.provoked=id==638 or id in game.pilot.persons.grudges
	npc.hostile=npc.provoked or game.Factions.hostile_to_pilot(game.catalog,game.pilot,int(npc.faction))
	broadcast(npc)
	return npc

func configure(npc: Dictionary,id: int) -> void:
	var r: Dictionary=game.catalog.record("persons",id)
	var f: Dictionary=r.fields
	npc.person_id=id;npc.person_flags=int(f.Flags);npc.name=r.name;npc.ambient=true
	npc.invulnerable=float(f.ShieldMod)<0
	npc.shield_capacity*=maxf(0,float(f.ShieldMod))/100.0
	npc.health=maxf(1,npc.shield_capacity+maxf(0,game.catalog.field("ships",int(npc.id),"Armor")))
	npc.max_health=npc.health
	npc.credits=roundi(float(f.Credits)*rng.randf_range(.75,1.25))
	for i in f.WeapType.size():
		var weapon: int=int(f.WeapType[i]);var amount: int=int(f.WeapCount[i])
		if weapon<128 or amount==0: continue
		var existing: Dictionary={}
		for w in npc.weapons:
			if int(w.id)==weapon: existing=w;break
		if existing.is_empty() and amount>0:
			existing={"id":weapon,"count":0,"ammo":0 if game.catalog.field("weapons",weapon,"AmmoType")>=0 else -1,"cooldown":1.0}
			npc.weapons.append(existing)
		if not existing.is_empty():
			existing.count=maxi(0,int(existing.count)+amount)
			if existing.ammo>=0: existing.ammo+=maxi(0,int(f.AmmoLoad[i]))
		npc.weapons=npc.weapons.filter(func(w): return w.count>0)
	npc.radio_timer=0.0;npc.radio_spoken=false;npc.person_retreat=false;npc.retreat_time=0.0
	npc.person_offer={};npc.was_attacking_player=false

func quote(npc: Dictionary, hail: bool=false) -> String:
	if not npc.has("person_id"): return ""
	var f: Dictionary=game.catalog.record("persons",int(npc.person_id)).fields
	var index: int=int(f.HailQuote if hail else f.CommQuote)
	var lines: Array=game.catalog.data.strings.get("7101" if hail else "7100",[])
	if index<=0 or index>lines.size(): return ""
	return str(lines[index-1]).replace("<PN>","Captain").replace("<OSN>",str(npc.name)).replace("<PSN>",str(game.catalog.record("ships",game.pilot.ship_id).name)).replace("\r","\n")
func broadcast(npc: Dictionary, attacking_player: bool=false) -> bool:
	var flags: int=int(npc.person_flags)
	if float(npc.get("radio_timer",0))>0 or (flags&128 and npc.get("radio_spoken",false)): return false
	# These two conditions are alternatives: original Rebel captains use both.
	if flags&12 and not ((flags&4 and npc.provoked) or (flags&8 and not npc.hostile)): return false
	if flags&16 and not attacking_player: return false
	if flags&32 and not npc.disabled: return false
	if flags&1024 and linked_offer(npc,bool(flags&512)).is_empty(): return false
	var text: String=quote(npc,true)
	if text.is_empty(): return false
	game.notify(text);npc.radio_spoken=true;npc.radio_timer=30.0
	return true
func attacked(npc: Dictionary) -> void:
	if not npc.has("person_id"): return
	if int(npc.person_flags)&1 and int(npc.person_id) not in game.pilot.persons.grudges:
		game.pilot.persons.grudges.append(int(npc.person_id));game.save_game(false)
func destroyed(npc: Dictionary) -> void:
	if npc.has("escape_owner"):
		deactivate(int(npc.escape_owner));return
	if not npc.has("person_id"): return
	if not int(npc.person_flags)&2:
		if int(npc.person_id) not in game.pilot.persons.gone: game.pilot.persons.gone.append(int(npc.person_id))
	else:
		var pod: Dictionary=game.traffic.spawn(191,-1,1,npc.position)
		if not pod.is_empty(): pod.name=npc.name+" · Escape pod";pod.ambient=true;pod.escape_owner=int(npc.person_id);pod.escape_boost=true;pod.goal=npc.position+(npc.position-game.pilot.position).normalized()*4000
	game.save_game(false)
func mission_origin() -> int:
	# Linked contracts need a real origin port for destination expansion.
	var queue: Array=[game.pilot.system_id];var visited: Array=[]
	while not queue.is_empty():
		var sys: int=queue.pop_front()
		if sys in visited: continue
		visited.append(sys)
		for id in game.catalog.system(sys).objects:
			if int(game.catalog.field("objects",id,"Flags"))&1: return int(id)
		queue.append_array(game.catalog.system(sys).links.filter(func(id): return id not in visited))
	return -1
func linked_offer(npc: Dictionary, boarded: bool) -> Dictionary:
	if not npc.has("person_id") or npc.get("person_mission_accepted",false): return {}
	var f: Dictionary=game.catalog.record("persons",int(npc.person_id)).fields
	var id: int=int(f.LinkMission);var flags: int=int(f.Flags)
	if id<0 or bool(flags&512)!=boarded: return {}
	var ai: int=int(game.catalog.field("ships",game.pilot.ship_id,"InherentAI"))
	if ai in [1,2,3] and flags&(1<<(11+ai)): return {}
	var origin: int=mission_origin()
	if origin<0 or not game.missions.eligibility(id,origin,true,game.pilot.system_id): return {}
	if not npc.get("person_offer",{}).is_empty(): return npc.person_offer
	npc.person_offer=game.missions.offer(id,origin)
	# Ship-origin ambushes must arrive here, even in a system without a port.
	if int(game.catalog.record("missions",id).fields.ShipSyst) in [-1,-6]: npc.person_offer.ship_system=game.pilot.system_id
	return npc.person_offer
func show_offer(npc: Dictionary, boarded: bool) -> bool:
	var offer: Dictionary=linked_offer(npc,boarded)
	if offer.is_empty(): return false
	offered={"npc":npc,"mission":offer,"boarded":boarded}
	game.interactions.reply((quote(npc)+"\n\n" if not quote(npc).is_empty() else "")+game.missions.text_for(offer,"offer"),"person_mission")
	return true
func accept_offer() -> void:
	if offered.is_empty(): return
	var npc: Dictionary=offered.npc
	if not game.interactions.live(npc) or game.interactions.contact!=npc or game.mode not in ["comms","boarding"]: offered={};return
	var m: Dictionary=linked_offer(npc,bool(offered.boarded))
	if m.is_empty(): return
	if game.pilot.campaign.active.size()>=8 or game.pilot.cargo_used()+int(m.qty)>game.pilot.cargo_capacity():
		game.interactions.reply("No room for this contract or its cargo.");return
	game.pilot.campaign.active.append(m)
	npc.person_mission_accepted=true
	var flags: int=int(npc.person_flags)
	if flags&256 and int(npc.person_id) not in game.pilot.persons.gone: game.pilot.persons.gone.append(int(npc.person_id))
	game.missions.last_report=game.missions.text_for(m,"BriefText")
	if game.missions.last_report.is_empty(): game.missions.last_report=game.missions.text_for(m,"QuickBrief")
	game.interactions.close()
	game.missions.enter_system()
	# The named courier itself becomes the escort objective, not a second ship.
	if flags&64 and m.actors.size()==1:
		for actor in game.npcs.duplicate():
			if actor.get("mission_id",-1)==int(m.id) and not actor.get("mission_aux",false): game.traffic.retire(actor)
		m.actors[0].ship=int(npc.id);m.actors[0].health=npc.health;m.actors[0].person_id=int(npc.person_id)
		npc.mission_id=int(m.id);npc.mission_slot=0;npc.mission_aux=false;npc.mission_escort=true;npc.ambient=false;npc.truce=true;npc.hostile=false
	elif flags&2048: npc.person_departing=true;npc.ambient=false
	game.notify("Ambush! The distress call was a trap." if int(game.catalog.record("missions",int(m.id)).fields.Flags)&1 else "Accepted: "+game.missions.title(m))
	game.save_game(false)
	offered={}

func deactivate(id: int) -> void:
	if id not in game.pilot.persons.gone: game.pilot.persons.gone.append(id)
	game.save_game(false)

func captured(npc: Dictionary) -> void:
	if npc.has("person_id"):
		game.missions.actor_event(npc,"escape")
		deactivate(int(npc.person_id))

func on_contact(npc: Dictionary,boarded: bool) -> void:
	if not npc.has("person_id"): return
	var offer: Dictionary=linked_offer(npc,boarded)
	if not offer.is_empty():
		show_offer(npc,boarded)
		# Source auto-abort missions are encounters, not contracts to decline.
		if int(game.catalog.record("missions",int(offer.id)).fields.Flags)&1: accept_offer()
	elif not boarded and int(npc.person_flags)&32768:
		var news: Array=game.world_activity.headlines()
		game.interactions.reply("%s: Here is the latest news.\n\n%s" % [npc.name,"\n\n".join(news.slice(0,3))])

func aggression_range(npc: Dictionary) -> float:
	if not npc.has("person_id"): return 1600.0
	if npc.provoked or is_instance_valid(npc.nemesis): return 1600.0
	var level: int=int(game.catalog.record("persons",int(npc.person_id)).fields.Aggress)
	return [0.0,400.0,800.0,1200.0,1600.0][clampi(level,0,4)]

func retreating(npc: Dictionary) -> bool:
	if not npc.has("person_id") or npc.disabled or npc.get("mission_escort",false): return false
	var threshold: float=float(game.catalog.record("persons",int(npc.person_id)).fields.Coward)
	var armor: float=maxf(0,float(game.catalog.field("ships",int(npc.id),"Armor")))
	var shields: float=maxf(0,float(npc.health)-armor)
	return threshold>=0 and float(npc.shield_capacity)>0 and shields<=float(npc.shield_capacity)*threshold/100.0

func update(npc: Dictionary,dt: float) -> bool:
	if npc.get("escape_boost",false):
		fly_away(npc,dt,true);return true
	if not npc.has("person_id"): return false
	npc.radio_timer=maxf(0,float(npc.get("radio_timer",0))-dt)
	var attacking: bool=not game.cloak.active and npc.hostile and npc.position.distance_to(game.pilot.position)<aggression_range(npc)
	broadcast(npc,attacking and not npc.get("was_attacking_player",false))
	npc.was_attacking_player=attacking
	if npc.disabled: return false
	if retreating(npc): npc.person_retreat=true
	if npc.get("person_departing",false) or npc.get("person_retreat",false):
		fly_away(npc,dt,bool(int(npc.person_flags)&2));return true
	return false

func fly_away(npc: Dictionary,dt: float,afterburner: bool) -> void:
	var f: Dictionary=game.catalog.record("ships",int(npc.id)).fields
	var away: Vector2=npc.position-game.pilot.position
	if away.length()<1: away=Vector2.UP
	var thrust: bool=afterburner and npc.fuel>0
	if thrust: npc.fuel=maxf(0,npc.fuel-dt*8)
	var speed: float=maxf(150,float(f.Speed))*(1.8 if thrust else 1.0)
	npc.heading=rotate_toward(npc.heading,game.Flight.facing(away),dt*maxf(1,float(f.Maneuver)*game.Flight.TURN_SCALE))
	var forward=Vector2(sin(npc.heading),-cos(npc.heading))
	npc.velocity=npc.velocity.move_toward(forward*speed,dt*maxf(100,game.Flight.acceleration(f)))
	npc.position+=npc.velocity*dt
	npc.behavior="Departing" if npc.get("person_departing",false) else "Retreating · afterburner" if thrust else "Retreating"
	game.interactions.pose(npc,1.0 if thrust else .7)
	npc.retreat_time=float(npc.get("retreat_time",0))+dt
	if npc.retreat_time>8 and away.length()>1800:
		if npc.id==191:
			game.traffic.retire(npc) # Escape pods are rescued/off-screen, not hypercapable.
		else: game.traffic.request_departure(npc,true)
