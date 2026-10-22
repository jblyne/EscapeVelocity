extends RefCounted
const Bribery=preload("res://scripts/bribery.gd")
const State=preload("res://scripts/campaign_state.gd")
const HUNTER_TRIBUTE_STEP=5000
const HUNTER_DEFEAT_LIMIT=5
const HUNTER_DELAY_DAYS=2
var hunter_celebration: Dictionary={}
var hunter_alert: String=""
var hunter_alert_seconds: float=0.0
var game
var siege: Dictionary={}
var return_mode="flight"
var contact_id=-1
var response=""
var landing_bribes: Dictionary={}
var landing_officers: Dictionary={}
var landing_officer_owner: RefCounted
var rng=RandomNumberGenerator.new()

static func fresh(day: int=0) -> Dictionary:
	return {"day":day,"events":[],"seen":[],"dominated":[],"hunters":{}}
static func valid(value: Variant,catalog,day: int) -> bool:
	if not value is Dictionary: return false
	if not State.integer(value.get("day"),maxi(0,day-3650),day): return false
	for key in ["events","seen","dominated"]:
		if not value.get(key) is Array: return false
	if value.events.size()>catalog.data.events.size() or value.seen.size()>catalog.data.events.size() or value.dominated.size()>catalog.data.objects.size(): return false
	var ids: Array=[]
	for e in value.events:
		if not e is Dictionary or not State.integer(e.get("id"),128,32767) or not State.integer(e.get("until"),0,1000000000): return false
		if catalog.record("events",int(e.id)).is_empty() or int(e.id) in ids: return false
		ids.append(int(e.id))
	for id in value.seen:
		if not State.integer(id,128,32767) or catalog.record("events",int(id)).is_empty(): return false
	ids=[]
	for id in value.dominated:
		if not State.integer(id,128,32767) or catalog.record("objects",int(id)).is_empty() or int(id) in ids: return false
		var f: Dictionary=catalog.record("objects",int(id)).fields
		if not int(f.Flags)&1 or int(f.Flags)&32: return false
		ids.append(int(id))
	var hunters=value.get("hunters",{})
	if not hunters is Dictionary or hunters.size()>catalog.data.objects.size(): return false
	for key in hunters:
		if not key is String or key!=str(int(key)) or catalog.record("objects",int(key)).is_empty(): return false
		var h=hunters[key]
		if not h is Dictionary: return false
		if not State.integer(h.get("sent"),0,1000000) or not State.integer(h.get("defeated"),0,HUNTER_DEFEAT_LIMIT): return false
		if not State.integer(h.get("active"),0,int(h.sent)) or not State.integer(h.get("next_day"),0,1000000000): return false
		if int(h.defeated)>int(h.sent) or (int(h.active)>0 and int(h.active)!=int(h.sent)): return false
		if int(h.defeated)>=HUNTER_DEFEAT_LIMIT and int(h.active)>0: return false
	return true
static func normalized(value: Dictionary) -> Dictionary:
	var result=fresh(int(value.day))
	for e in value.events: result.events.append({"id":int(e.id),"until":int(e.until)})
	for key in ["seen","dominated"]:
		for id in value[key]:
			if int(id) not in result[key]: result[key].append(int(id))
	for key in value.get("hunters",{}):
		var h: Dictionary=value.hunters[key]
		result.hunters[key]={"sent":int(h.sent),"defeated":int(h.defeated),"active":int(h.active),"next_day":int(h.next_day)}
	return result
func state() -> Dictionary: return game.pilot.world_state
func tribute(port: int) -> int:
	var defeated: int=int(state().get("hunters",{}).get(str(port),{}).get("defeated",0))
	return maxi(1,int(game.catalog.field("objects",port,"TechLevel")))*1000+defeated*HUNTER_TRIBUTE_STEP

func hunter_record(port: int) -> Dictionary:
	if not state().has("hunters"): state().hunters={}
	if not state().hunters.has(str(port)):
		state().hunters[str(port)]={"sent":0,"defeated":0,"active":0,"next_day":int(game.pilot.campaign.day)+1}
	return state().hunters[str(port)]

func sponsor(port: int) -> String:
	return "%s (%s system)" % [game.catalog.record("objects",port).name,game.catalog.system(game.missions.system_of(port)).name]

func hunter_notice(text: String) -> void:
	hunter_alert=text;hunter_alert_seconds=16.0
	game.notify(text)

func tribute_summary(system: int) -> Dictionary:
	var result={"income":0,"sent":0,"defeated":0,"gave_up":0,"worlds":0,"lines":[]}
	for port in game.catalog.system(system).objects:
		if port not in state().dominated or game.world_killer.destroyed(int(port)): continue
		var h: Dictionary=state().get("hunters",{}).get(str(port),{})
		var sent: int=int(h.get("sent",0));var defeated: int=int(h.get("defeated",0))
		result.income+=tribute(int(port));result.sent+=sent;result.defeated+=defeated;result.worlds+=1
		if defeated>=HUNTER_DEFEAT_LIMIT: result.gave_up+=1
		result.lines.append("%s: %s cr/day · Hunters sent: %d · Defeated: %d%s" % [game.catalog.record("objects",int(port)).name,game.hud.commas(tribute(int(port))),sent,defeated," · Gave up" if defeated>=HUNTER_DEFEAT_LIMIT else ""])
	return result

func advance_hunters() -> void:
	if game.mode!="flight" or not game.traffic.enabled or game.hyperdrive.active() or not game.chain_route.is_empty(): return
	var changed: bool=false
	if not state().has("hunters"): state().hunters={}
	for port in state().dominated:
		if game.world_killer.destroyed(int(port)): continue
		if not state().hunters.has(str(port)): hunter_record(int(port));changed=true
	if changed: game.save_game(false)
	# One mercenary on screen at a time; contracts follow the pilot between visits.
	for npc in game.npcs.duplicate():
		if not npc.has("bounty_port"): continue
		var port: int=int(npc.bounty_port)
		if port not in state().dominated or game.world_killer.destroyed(port):
			game.traffic.retire(npc);continue
		if npc.has("fleet_uid") or npc.get("player_ally",false):
			var h: Dictionary=hunter_record(port)
			h.active=0;h.next_day=int(game.pilot.campaign.day)+HUNTER_DELAY_DAYS
			npc.erase("bounty_port");npc.erase("bounty_contract");game.save_game(false)
			continue
		if not game.cloak.active: npc.goal=game.pilot.position
		return
	if game.npcs.size()>=game.traffic.MAX_CONTACTS: return
	for port in state().dominated:
		if game.world_killer.destroyed(int(port)): continue
		var h: Dictionary=hunter_record(int(port))
		if int(h.defeated)>=HUNTER_DEFEAT_LIMIT: continue
		if int(h.active)==0 and int(game.pilot.campaign.day)<int(h.next_day): continue
		var npc: Dictionary=game.traffic.spawn(148,136,4,game.pilot.position+Vector2.from_angle(rng.randf()*TAU)*1000)
		if npc.is_empty(): return
		var resumed: bool=int(h.active)>0
		if not resumed: h.sent+=1;h.active=int(h.sent)
		npc.bounty_port=int(port);npc.bounty_contract=int(h.active)
		npc.name="Bounty hunter · "+sponsor(int(port));npc.provoked=true;npc.hostile=true;npc.ambient=false
		npc.goal=game.pilot.position
		hunter_notice("BOUNTY HUNTER · Hired by %s · Contract #%d%s" % [sponsor(int(port)),int(h.active)," · Still pursuing you" if resumed else ""])
		game.save_game(false);return

func hunter_destroyed(npc: Dictionary, player_credit: bool) -> void:
	var port: int=int(npc.get("bounty_port",-1))
	if port<0: return
	var h: Dictionary=state().get("hunters",{}).get(str(port),{})
	if h.is_empty() or int(h.active)==0 or int(h.active)!=int(npc.get("bounty_contract",-1)): return
	# Clear the serial before rewarding: repeated callbacks cannot raise tribute twice.
	h.active=0;h.next_day=int(game.pilot.campaign.day)+HUNTER_DELAY_DAYS
	if player_credit and port in state().dominated and not game.world_killer.destroyed(port):
		sync() # Settle earlier days at the old tribute rate before raising it.
		h.defeated=mini(HUNTER_DEFEAT_LIMIT,int(h.defeated)+1)
		var message: String="HUNTER DEFEATED · Hired by %s · Tribute +5,000 → %s cr/day" % [sponsor(port),game.hud.commas(tribute(port))]
		if int(h.defeated)>=HUNTER_DEFEAT_LIMIT: message+=" · They give up: further bounty hunters are too expensive."
		hunter_celebration={"generation":int(hunter_celebration.get("generation",0))+1,"sponsor":sponsor(port),"income":tribute(port),"gave_up":int(h.defeated)>=HUNTER_DEFEAT_LIMIT}
		hunter_notice(message)
	game.save_game(false)
func daily_income() -> int:
	var total=0
	for id in state().dominated:
		if not game.world_killer.destroyed(int(id)): total+=tribute(int(id))
	return total
func activate(id: int,day: int) -> void:
	if state().events.any(func(e): return int(e.id)==id): return
	var f: Dictionary=game.catalog.record("events",id).fields
	if game.world_killer.destroyed(int(f.Stellar)): return
	if int(f.Duration)<=0: return
	state().events.append({"id":id,"until":day+int(f.Duration)})
func sync() -> void:
	var today: int=int(game.pilot.campaign.day)
	var earned=0
	while int(state().day)<today:
		state().day+=1
		var day: int=int(state().day)
		state().events=state().events.filter(func(e): return int(e.until)>day)
		for r in game.catalog.data.events.values():
			var f: Dictionary=r.fields
			if int(f.Stellar)<128 or int(f.Freq)<=0 or not game.missions.bit_matches(int(f.MissionBit)): continue
			if absi(hash("event:%d:%d" % [r.id,day]))%100<int(f.Freq): activate(int(r.id),day)
		earned+=daily_income()
	# Story headlines activate once when their mission bits are first observed.
	for r in game.catalog.data.events.values():
		if int(r.fields.MissionBit)<0 or int(r.fields.Stellar)!=-2 or int(r.id) in state().seen: continue
		if game.missions.bit_matches(int(r.fields.MissionBit)):
			state().seen.append(int(r.id));activate(int(r.id),today)
	if earned>0:
		game.pilot.credits+=earned
		game.notify("Tribute received: %d credits." % earned)
func prices(port: int) -> Array:
	var spread: float=1.25
	var gov: int=int(game.catalog.field("objects",port,"Govt"))
	if gov>=0 and int(game.pilot.reputation.get(str(gov),0))<0: spread=1.1
	if port in state().dominated: spread=1.5
	var result: Array=game.catalog.prices(port,spread)
	for e in state().events:
		if int(e.until)<=int(game.pilot.campaign.day): continue
		var f: Dictionary=game.catalog.record("events",int(e.id)).fields
		if int(f.Stellar)==port and int(f.Commodity) in range(result.size()) : result[int(f.Commodity)]=maxi(5,int(game.catalog.data.commodities[int(f.Commodity)].base_price)+int(f.PriceDelta))
	return result
func headlines(local_port: int=-1) -> Array:
	sync()
	var result: Array=[]
	for id in game.pilot.world_killer.destroyed:
		result.append("%s was obliterated. %s" % [game.catalog.record("objects",int(id)).name,game.world_killer.reconstruction_text(int(id))])
	for e in state().events:
		var r: Dictionary=game.catalog.record("events",int(e.id))
		var f: Dictionary=r.fields
		if int(e.until)<=int(game.pilot.campaign.day): continue
		if int(f.Stellar)==-2:
			var story: Array=game.catalog.data.strings.get("8102",[])
			if int(r.id)-128 in range(story.size()): result.append(str(story[int(r.id)-128]))
		elif int(f.Stellar)>=128:
			var port: Dictionary=game.catalog.record("objects",int(f.Stellar))
			if port.is_empty(): continue
			var text="%s: %s. %s prices %s by %d cr/t · %d days remaining." % [port.name,r.name,game.catalog.data.commodities[int(f.Commodity)].name,"rise" if f.PriceDelta>0 else "fall",absi(int(f.PriceDelta)),int(e.until)-int(game.pilot.campaign.day)]
			if int(f.Stellar)==local_port: result.push_front(text)
			else: result.append(text)
	var news: Array=game.catalog.data.strings.get("8101",[])
	for i in mini(3,news.size()): result.append(news[(int(game.pilot.campaign.day)*3+i)%news.size()])
	return result
# Fear derives from permanent destruction history, so reloads cannot reroll it.
func fear(port: int) -> Dictionary:
	var obj: Dictionary=game.catalog.record("objects",port)
	if obj.is_empty(): return {"score":0,"resolve":100,"compliant":false}
	var score: int=0
	for id in game.pilot.world_killer.destroyed:
		var other: Dictionary=game.catalog.record("objects",int(id))
		score+=20 if game.world_killer.is_space_station(int(id)) else 40
		if int(other.fields.System)==int(obj.fields.System): score+=25
		if int(obj.fields.Govt)>=0 and int(other.fields.Govt)==int(obj.fields.Govt): score+=15
	var resolve: int=clampi(40+int(obj.fields.TechLevel)*4,40,80)
	score=mini(100,score)
	return {"score":score,"resolve":resolve,"compliant":score>=resolve and int(obj.fields.Flags)&1 and not int(obj.fields.Flags)&32 and not game.world_killer.destroyed(port)}

func landing_reason(port: int) -> String:
	if game.world_killer.destroyed(port): return "This world has been shattered. Reconstruction begins next game day."
	if game.world_killer.reconstruction(port).get("landable",false): return ""
	var f: Dictionary=game.catalog.record("objects",port).fields
	if not int(f.Flags)&1: return "No landing facilities."
	if not siege.is_empty() and int(siege.port)==port: return "Landing refused while the defense fleet is deployed."
	if game.missions.grants_landing_clearance(port): return ""
	if landing_bribes.has(port): return ""
	if int(f.Flags)&32 or port in state().dominated or game.cloak.active: return ""
	if fear(port).compliant: return ""
	var gov: Dictionary=game.catalog.record("governments",int(f.Govt))
	if gov.is_empty():
		var record: int=int(game.pilot.local_records.get(str(game.missions.system_of(port)),0))
		return "Landing refused: your local legal record is below this port's required standing." if record<int(f.MinCoolness) else ""
	var score: int=int(game.pilot.reputation.get(str(int(f.Govt)),int(gov.fields.InitialRec)))
	return "Landing refused: your reputation with %s is below this port's required standing (%d)." % [gov.name,int(f.MinCoolness)] if score<int(f.MinCoolness) else ""
# Stable for one port/day, so reopening the channel cannot reroll an official.
# Original formulas and government-bit willingness: see PHASE_5_BRIBES_AND_SECRETS.md.
# Keeping each official/quote stable for a port/day is remake anti-reroll behavior.
func landing_officer(port: int) -> Dictionary:
	if landing_officer_owner!=game.pilot:
		landing_officers.clear();landing_officer_owner=game.pilot
	var key: String="%d:%d" % [port,int(game.pilot.campaign.day)]
	if not landing_officers.has(key):
		var roll: int=absi(hash(key))%100
		var govt: int=int(game.catalog.field("objects",port,"Govt"))
		var flags: int=int(game.catalog.record("governments",govt).get("fields",{}).get("Flags",0))
		var quote_rng=RandomNumberGenerator.new();quote_rng.seed=absi(hash("landing_quote:"+key))
		landing_officers[key]={"willing":Bribery.landing_willing(roll,flags,govt),"bargains":absi(hash("bargain:"+key))%100<=50,"negotiated":false,"refused":false,"discount":false,"price":Bribery.landing_quote(game.pilot.credits,flags,quote_rng)}
	return landing_officers[key]

func landing_bribe_price(port: int) -> int:
	var officer: Dictionary=landing_officer(port)
	return Bribery.discount(int(officer.price)) if officer.discount else int(officer.price)

func negotiate_landing_bribe() -> bool:
	if game.mode!="world_comms" or not can_bribe_landing(contact_id): return false
	var officer: Dictionary=landing_officer(contact_id)
	if officer.negotiated or officer.refused: return false
	officer.negotiated=true;remember("negotiate_bribe")
	if not officer.willing:
		officer.refused=true;response="Bribing a traffic-control officer? Leave now. Try another day if you must."
	elif officer.bargains:
		officer.discount=true;response="Perhaps we can reduce the fee. %d credits, and you have clearance." % landing_bribe_price(contact_id)
	else:
		officer.refused=true;officer.willing=false;officer.price=int(officer.price)+1000
		response="No deal. This officer will no longer accept a bribe today. Leave and try another day."
	game.hud.rebuild_modal()
	return officer.discount

func can_bribe_landing(port: int) -> bool:
	if game.catalog.record("objects",port).is_empty() or game.world_killer.destroyed(port): return false
	if not int(game.catalog.field("objects",port,"Flags"))&1: return false
	if not siege.is_empty() and int(siege.port)==port: return false
	return not landing_reason(port).is_empty()

func pay_landing_bribe() -> bool:
	if game.mode!="world_comms" or not can_bribe_landing(contact_id): return false
	var cost: int=landing_bribe_price(contact_id)
	var officer: Dictionary=landing_officer(contact_id)
	if not officer.willing or officer.refused:
		officer.refused=true;remember("bribe_refused")
		response="Your money will not buy clearance from this officer. Leave, and try another day."
		game.sound("ui_error");game.hud.rebuild_modal();return false
	if game.pilot.credits<cost:
		response="Insufficient credits for landing clearance.";game.sound("ui_error");game.hud.rebuild_modal();return false
	game.pilot.credits-=cost
	landing_bribes[contact_id]=true
	game.landing_target=contact_id;game.landing_clearance=contact_id
	remember("bribe");remember("landing_bribe")
	response="Payment received. Landing clearance granted for this system visit. Approach slowly and press L to land."
	game.sound("ui_confirm");game.save_game(false);game.hud.rebuild_modal()
	return true

func remember(action: String,port: int=-1) -> void:
	game.pilot.History.record(game.pilot,"world:%d" % (contact_id if port<0 else port),action)

func open_news() -> void:
	return_mode="dock" if game.mode=="dock" else "flight"
	sync();game.save_game(false);game.set_mode("news")
func open_contact() -> void:
	if game.mode!="flight": return
	if game.hyperdrive.active() or not game.chain_route.is_empty(): return
	var body: Dictionary=game.selected_planet()
	if body.is_empty(): body=game.nearest_planet()
	if body.is_empty(): game.notify("No world available to hail.");return
	contact_id=int(body.id);response=game.world_killer.greeting(contact_id)
	remember("hail");game.save_game(false)
	game.world_killer.launch_preview=false
	game.set_mode("world_comms")
func demand_reason(port: int) -> String:
	if game.world_killer.destroyed(port): return "No planetary authority survives."
	var f: Dictionary=game.catalog.record("objects",port).fields
	if not int(f.Flags)&1 or int(f.Flags)&32: return "No inhabited authority to demand tribute from."
	if not siege.is_empty(): return "A defense battle is already in progress."
	if port in state().dominated: return "This world already pays tribute."
	return ""
func defense_counts(port: int) -> Vector2i:
	var count: int=maxi(0,int(game.catalog.field("objects",port,"DefCount")))
	return Vector2i(maxi(0,(count-1000)/10),maxi(1,count%10)) if count>1000 else Vector2i(count,maxi(1,count))
func demand() -> void:
	if game.mode!="world_comms": return
	var reason=demand_reason(contact_id)
	if not reason.is_empty(): response=reason;game.hud.rebuild_modal();return
	remember("tribute_demanded")
	var f: Dictionary=game.catalog.record("objects",contact_id).fields
	var counts=defense_counts(contact_id)
	siege={"port":contact_id,"left":counts.x,"wave":mini(counts.y,8),"pending":0,"timer":0.0}
	game.Factions.penalize(game.catalog,game.pilot,int(f.Govt),"BoardPenalty")
	game.landing_clearance=-1
	game.set_mode("flight")
	game.notify("%s deploys its defense fleet. Defeat all waves to secure tribute." % game.catalog.record("objects",contact_id).name)
	advance(0);game.save_game(false)
func resolved(npc: Dictionary) -> void:
	if siege.is_empty() or int(npc.get("defense_port",-1))!=int(siege.port) or npc.get("defense_resolved",false): return
	npc.defense_resolved=true
	siege.pending=maxi(0,int(siege.pending)-1)
func advance(dt: float) -> void:
	advance_hunters()
	if siege.is_empty(): return
	for npc in game.npcs:
		if npc.disabled: resolved(npc)
	if int(siege.pending)>0: return
	if int(siege.left)==0:
		var port: int=int(siege.port)
		if port not in state().dominated: state().dominated.append(port)
		hunter_record(port)
		siege={}
		game.notify("%s agrees to pay %d credits per day in tribute." % [game.catalog.record("objects",port).name,tribute(port)])
		game.save_game(false);return
	siege.timer-=dt
	if siege.timer>0: return
	var f: Dictionary=game.catalog.record("objects",int(siege.port)).fields
	var encounter: Dictionary=game.catalog.record("encounters",int(f.DefDude))
	if encounter.is_empty(): abort();game.notify("No valid defense fleet is available.");return
	var pool: Array=[]
	for i in encounter.fields.ShipTypes.size():
		if encounter.fields["% Prob"][i]>0: pool.append({"ship":int(encounter.fields.ShipTypes[i]),"weight":float(encounter.fields["% Prob"][i])})
	for i in mini(int(siege.wave),int(siege.left)):
		var option: Dictionary=game.traffic.choose(pool)
		if option.is_empty(): break
		if game.npcs.size()>=game.traffic.MAX_CONTACTS:
			for old in game.npcs.duplicate():
				if old.get("defense_resolved",false): game.traffic.retire(old);break
		var origin: Vector2=game.pilot.position
		var radius: float=700
		for body in game.planets:
			if int(body.id)==int(siege.port): origin=body.position;radius=float(body.radius)+80
		var pos=origin+Vector2.from_angle(rng.randf()*TAU)*radius
		var npc: Dictionary=game.traffic.spawn(int(option.ship),int(f.Govt),4,pos)
		if npc.is_empty(): break
		npc.defense_port=int(siege.port);npc.provoked=true;npc.hostile=true;npc.ambient=false
		npc.goal=game.pilot.position
		npc.name+=" · Planetary defense"
		siege.left-=1;siege.pending+=1
	if int(siege.pending)>0: game.notify("Defense wave launched · %d ships remaining." % (int(siege.left)+int(siege.pending)))
	siege.timer=3.0
func abort() -> void: siege={}
func release() -> void:
	if game.mode!="world_comms" or contact_id not in state().dominated: return
	remember("tribute_released")
	state().dominated.erase(contact_id)
	if state().hunters.has(str(contact_id)): state().hunters[str(contact_id)].active=0
	response="You release this world from its tribute obligation."
	game.save_game(false);game.hud.rebuild_modal()
