extends RefCounted
# Original 1.0.5 resources interpreted using Matt Burch's 1996 EV Bible.
var game
var approach: Dictionary={}
var approach_port: int=-1
var approached: Array[int]=[]
var bar_port: int=-1
var bar_rolls: Dictionary={}
var bar_queue: Array[int]=[]
var bar_ticks: float=0
var bar_idle: int=0
# Original null-event counter, represented at the remake's nominal 60 Hz.
const BAR_EVENT_HZ: float=60.0
var selected: Dictionary = {}
var selected_courier: bool=false
var tracked_id: int=-1 # -2 is the introductory courier contract.
var return_mode: String = "dock"
var channel: int = 0
var arrival_delays: Dictionary={}
var auxiliary_delays: Dictionary={}
# Source counter: 70 + Random(70) encounter updates (PPC 0x541e0).
# Convert at nominal 60 updates/s; original wall-clock cadence is unverified.
const ENCOUNTER_TICKS_PER_SECOND: float=60.0
const ARRIVAL_DELAY: float=3.0
const SCAN_INTERVAL: float=5.0 # Remake cadence; original AI scan-acquisition timing remains under comparison.
const SCAN_AXIS_RANGE: float=300.0 # Original PPC 0x2f4–0x340.
var scan_clock: float = 0
var last_report: String = ""
var flight_alert: String=""
var flight_alert_seconds: float=0
var landing_reports: Array[Dictionary] = []
var active_landing_report: Dictionary = {}

func state() -> Dictionary:
	return game.pilot.campaign

func bit_matches(code: int) -> bool:
	if code<0: return true
	return (code-1000 not in state().bits) if code>=1000 else code in state().bits

func apply_bit(code: int) -> void:
	if code>=1000: state().bits.erase(code-1000)
	elif code>=0 and code not in state().bits: state().bits.append(code)

func system_of(port: int) -> int:
	var object: Dictionary=game.catalog.record("objects",port)
	return int(object.fields.System) if not object.is_empty() else -1

func govt_matches(code: int, govt: int) -> bool:
	var target: int=code%5000+128
	if code==9999: target=-1
	if code>=25000: return game.Factions.enemies(game.catalog,govt,target)
	if code>=20000: return govt!=target
	if code>=15000: return game.Factions.allied(game.catalog,govt,target)
	return govt==target

func port_matches(code: int, port: int) -> bool:
	if game.world_killer.destroyed(port): return false
	var obj: Dictionary=game.catalog.record("objects",port)
	if obj.is_empty() or not int(obj.fields.Flags)&1: return false
	if code in [-1,-2]: return not int(obj.fields.Flags)&32
	if code==-3: return bool(int(obj.fields.Flags)&32)
	if code>=9999: return govt_matches(code,int(obj.fields.Govt))
	if code>=5000: return system_of(port) in game.catalog.system(code-5000+128).get("links",[])
	return code==port

func roll(id: int, port: int) -> int:
	return absi(hash("%d:%d:%d" % [id,port,state().visit]))%100

func eligibility(id: int, port: int, use_chance: bool = true, encounter_system: int = -1) -> bool:
	var record: Dictionary=game.catalog.record("missions",id)
	if record.is_empty(): return false
	var f: Dictionary=record.fields
	for destination_code in [int(f.TravelStel),int(f.ReturnStel)]:
		if game.world_killer.destroyed(choose_port(destination_code,port,id)): return false
	if not port_matches(int(f.AvailStel),port) or not bit_matches(int(f.AvailBitSet)): return false
	if int(f.AvailBitClr)>=0 and int(f.AvailBitClr) in state().bits: return false
	for active in state().active:
		if int(active.id)==id: return false
	var govt: int=int(game.catalog.field("objects",port,"Govt"))
	if encounter_system>=0: govt=int(game.catalog.system(encounter_system).fields.Govt)
	var gov: Dictionary=game.catalog.record("governments",govt)
	var rep: int=int(game.pilot.reputation.get(str(govt),gov.get("fields",{}).get("InitialRec",0)))
	if govt==-1: rep=int(game.pilot.local_records.get(str(encounter_system if encounter_system>=0 else system_of(port)),0))
	var required_record: int=0 if id in [171,172] else int(f.AvailRecord)
	if f.AvailRecord>0 and rep<required_record: return false
	if f.AvailRecord<0 and rep>f.AvailRecord: return false
	if int(state().rating)<int(f.AvailRating): return false
	return not use_chance or id in [171,172] or roll(id,port)<int(f.AvailRandom)

func eligibility_reason(id: int, port: int) -> String:
	var record: Dictionary=game.catalog.record("missions",id)
	if record.is_empty(): return "Unknown assignment."
	var f: Dictionary=record.fields
	if not port_matches(int(f.AvailStel),port): return "Find this contact at the appropriate port."
	if state().active.any(func(m):return int(m.id)==id): return "Already accepted; see your mission journal."
	if int(f.AvailBitClr)>=0 and int(f.AvailBitClr) in state().bits: return "This story step is already completed or closed."
	if not bit_matches(int(f.AvailBitSet)):
		var predecessors: Array[String]=[]
		if int(f.AvailBitSet)<1000:
			for previous in game.catalog.data.missions.values():
				if int(f.AvailBitSet) in [int(previous.fields.CompBitSet),int(previous.fields.CompBitSet2)]: predecessors.append(title(offer(int(previous.id),port)))
		return "Complete earlier story work: "+", ".join(predecessors)+"." if not predecessors.is_empty() else "Further story progress is required."
	var gov: int=int(game.catalog.field("objects",port,"Govt"))
	var government: Dictionary=game.catalog.record("governments",gov)
	var standing: int=int(game.pilot.local_records.get(str(system_of(port)),0)) if gov<0 else int(game.pilot.reputation.get(str(gov),government.get("fields",{}).get("InitialRec",0)))
	var required: int=0 if id in [171,172] else int(f.AvailRecord)
	var faction: String=str(government.get("name","local"))
	var requirements: PackedStringArray=[]
	if int(f.AvailRecord)>0 and standing<required: requirements.append("Improve %s standing to %d (currently %d)." % [faction,required,standing])
	if int(f.AvailRecord)<0 and standing>int(f.AvailRecord): requirements.append("%s standing must be %d or lower (currently %d)." % [faction,int(f.AvailRecord),standing])
	if int(state().rating)<int(f.AvailRating): requirements.append("Build combat rating to %d (currently %d)." % [int(f.AvailRating),int(state().rating)])
	if not requirements.is_empty(): return " ".join(requirements)
	for code in [int(f.TravelStel),int(f.ReturnStel)]:
		if game.world_killer.destroyed(choose_port(code,port,id)): return "A required mission destination has been destroyed."
	return ""

func choose_port(code: int, origin: int, id: int) -> int:
	if code==-4: return origin
	# Original port resolver 0x51e40 initializes to origin; unhandled -5 retains it.
	if code==-5: return origin
	if code==-1: return -1
	if code>=128 and code<5000: return code
	var pool: Array=[]
	for key in game.catalog.data.objects:
		var port: int=int(key)
		if port!=origin and port_matches(code,port): pool.append(port)
	pool.sort()
	return int(pool[absi(hash("%d:%d:%d:%d" % [id,origin,code,state().visit]))%pool.size()]) if not pool.is_empty() else -1

func offer(id: int, origin: int) -> Dictionary:
	var f: Dictionary=game.catalog.record("missions",id).fields
	var dest: int=choose_port(int(f.TravelStel),origin,id)
	var back: int=choose_port(int(f.ReturnStel),origin,id)
	var qty: int=maxi(0,int(f.CargoQty))
	if f.CargoQty < -1: qty=maxi(1,roundi(absf(f.CargoQty)*(.5+float(roll(id+1000,origin))/100)))
	var mission: Dictionary={"id":id,"origin":origin,"dest":dest,"back":back,"qty":qty,"picked":int(f.PickupMode) in [0,5],"delivered":false,"travel_done":dest<0,"deadline":int(state().day)+int(f.TimeLimit) if f.TimeLimit>0 else -1,"actors":[],"aux":[],"ship_system":-1,"met":false,"prepaid":false}
	var sys: int=int(f.ShipSyst)
	match sys:
		-1,-6: sys=system_of(origin)
		-3: sys=system_of(dest)
		-4: sys=system_of(back)
		-5:
			var links: Array=game.catalog.system(system_of(origin)).links
			sys=int(links[roll(id,origin)%links.size()]) if not links.is_empty() else system_of(origin)
		-2: sys=int(game.catalog.data.systems.keys()[roll(id,origin)%game.catalog.data.systems.size()])
	if sys>=9999:
		var options: Array=[]
		for s in game.catalog.data.systems.values():
			if govt_matches(sys,int(s.fields.Govt)): options.append(int(s.id))
		sys=options[roll(id,origin)%options.size()] if not options.is_empty() else system_of(origin)
	mission.ship_system=sys
	return mission

func offers(port: int, location: int) -> Array:
	var result: Array=[]
	for record in game.catalog.data.missions.values():
		if int(record.fields.AvailLoc) != location: continue
		if eligibility(int(record.id),port,location!=1): result.append(offer(int(record.id),port))
	result.sort_custom(func(a,b):
		var fa: Dictionary=game.catalog.record("missions",int(a.id)).fields
		var fb: Dictionary=game.catalog.record("missions",int(b.id)).fields
		return (int(fa.Flags)&4096)>(int(fb.Flags)&4096) if (int(fa.Flags)&4096)!=(int(fb.Flags)&4096) else a.id<b.id)
	return result

func text_for(m: Dictionary, field: String) -> String:
	var r: Dictionary=game.catalog.record("missions",int(m.id))
	var desc: int=int(r.fields.get(field,-1))
	if field=="offer": desc=4000+int(m.id)-128
	return expand(str(game.catalog.data.descriptions.get(str(desc),"")),m)

func expand(text: String, m: Dictionary) -> String:
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	var dst: Dictionary=game.catalog.record("objects",int(m.dest))
	var rst: Dictionary=game.catalog.record("objects",int(m.back if m.back>=0 else m.dest))
	var values: Dictionary={"<DST>":dst.get("name","destination"),"<DSY>":game.catalog.system(system_of(int(m.dest))).get("name","destination"),"<RST>":rst.get("name","destination"),"<RSY>":game.catalog.system(system_of(int(m.back if m.back>=0 else m.dest))).get("name","destination"),"<CQ>":str(m.qty),"<CT>":"mission cargo","<DL>":"day %d" % m.deadline,"<PN>":"Captain","<PSN>":game.catalog.record("ships",game.pilot.ship_id).name,"<SN>":ship_name(m),"<OSN>":ship_name(m)}
	if int(f.CargoType) in range(6): values["<CT>"]=game.catalog.data.commodities[int(f.CargoType)].name
	for token in values: text=text.replace(token,str(values[token]))
	return text.replace("\r","\n")

func ship_name(m: Dictionary, index: int=0) -> String:
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	var names: Array=game.catalog.data.strings.get(str(int(f.ShipNameID)),[])
	if names.is_empty(): return "mission target"
	return str(names[(absi(hash("%d:%d" % [int(m.id),int(m.origin)]))+index)%names.size()])

func title(m: Dictionary) -> String:
	return expand(game.catalog.record("missions",int(m.id)).name,m)

func return_for_payment(m: Dictionary) -> String:
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	if int(f.ShipCount)<=0 or int(f.ShipGoal) not in [0,6] or not m.travel_done or not ship_goal_done(m) or int(m.back)<0: return ""
	var port: Dictionary=game.catalog.record("objects",int(m.back))
	var objective: String="Defense objective complete" if int(f.ShipGoal)==6 else "Target destroyed"
	return "%s — return to %s (%s) %s. No more targets required." % [objective,port.name,game.catalog.system(system_of(int(m.back))).name,"for payment" if int(f.PayVal)>0 else "to report in"]

func combat_return_status() -> String:
	var lines: PackedStringArray=[]
	for m in state().active:
		var instruction: String=return_for_payment(m)
		if not instruction.is_empty(): lines.append(title(m)+": "+instruction)
	return "\n".join(lines)

func objective_port(port: int) -> String:
	var record: Dictionary=game.catalog.record("objects",port)
	if record.is_empty(): return "the mission destination"
	return "%s (%s system)" % [record.name,game.catalog.system(system_of(port)).get("name","unknown")]

func next_objective(m: Dictionary) -> String:
	var result: String=objective_action(m)
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	if int(m.deadline)>=int(state().day):
		var days: int=int(m.deadline)-int(state().day)
		result+=" · Due today" if days==0 else " · %d %s left" % [days,"day" if days==1 else "days"]
	if m.picked and not m.delivered and int(f.CargoType)>=0 and int(f.ScanGovt)>=0 and int(f.FailIfScan)!=0:
		result+=" Avoid %s cargo scans." % game.catalog.record("governments",int(f.ScanGovt)).get("name","patrol")
	return result

func objective_action(m: Dictionary) -> String:
	var fields: Dictionary=game.catalog.record("missions",int(m.id)).fields
	if int(m.deadline)>=0 and int(state().day)>int(m.deadline): return "Deadline passed — check your mission journal."
	if not ship_goal_done(m):
		var goal: int=int(fields.ShipGoal)
		var remaining: int=maxi(0,int(fields.ShipCount))
		for actor in m.actors:
			if (goal in [0,6] and actor.dead) or (goal==1 and actor.disabled and not actor.dead) or (goal in [2,5] and actor.boarded) or (goal==4 and actor.observed): remaining-=1
		var action: String="Locate the mission ships"
		match goal:
			0: action="Destroy %d remaining mission target%s" % [remaining,"" if remaining==1 else "s"]
			6: action="Destroy or drive off %d remaining attacker%s" % [remaining,"" if remaining==1 else "s"]
			1: action="Disable %d remaining mission ship%s; do not destroy them" % [remaining,"" if remaining==1 else "s"]
			2,5:
				var disabled: bool=goal==5 or (m.actors.size()==int(fields.ShipCount) and m.actors.all(func(actor):return actor.boarded or actor.disabled))
				action=("Board %d remaining disabled mission ship%s with B" if disabled else "Disable and board %d remaining mission ship%s with B") % [remaining,"" if remaining==1 else "s"]
			3: action="Rendezvous with the ships you must escort"
			4: action="Scout for mission contacts; destroying them is not required"
		var system: String=game.catalog.system(int(m.ship_system)).get("name","the objective")
		return ("In %s: " if int(m.ship_system)==game.pilot.system_id else "Travel to %s, then ") % system+action+"."
	if int(fields.ShipGoal)==4 and m.travel_done and int(m.back)>=0:
		return "Reconnaissance complete — return to %s to report your findings%s. No kills required." % [objective_port(int(m.back))," and collect %d credits" % int(fields.PayVal) if int(fields.PayVal)>0 else ""]
	if int(fields.ShipGoal)==3 and m.met:
		return "Escort the surviving ships to %s. Keep them alive until you land." % objective_port(int(m.dest) if not m.travel_done else int(m.back))
	var return_note: String=return_for_payment(m)
	if not return_note.is_empty(): return return_note
	var cargo_name: String="passengers" if int(fields.CargoType)==6 else "mission cargo"
	var port: int=int(m.dest) if not m.travel_done else int(m.back if int(m.back)>=0 else m.dest)
	var action: String="Land at %s to complete the next mission step." % objective_port(port)
	if not m.travel_done:
		if int(m.id)==164: action="Land on %s to insert the Rebel commandos. Cloak with K before approaching Confed patrols." % objective_port(port)
		elif int(fields.PickupMode)==1 and not m.picked: action="Land at %s to pick up %s." % [objective_port(port),cargo_name]
		elif int(fields.CargoType)>=0 and m.picked: action="Land at %s to deliver %s." % [objective_port(port),cargo_name]
	elif int(m.back)>=0:
		action="Return to %s to deliver %s." % [objective_port(port),cargo_name] if int(fields.CargoType)>=0 and int(fields.DropoffMode)>=0 and not m.delivered else ("Return to %s to report in and collect your reward." if int(fields.PayVal)>0 else "Return to %s to report in.") % objective_port(port)
	return action

func tracked_objective() -> String:
	var current: Dictionary={}
	for m in state().active:
		if int(m.id)==tracked_id: current=m;break
	if current.is_empty() and tracked_id!=-2:
		# Prefer a job that has an objective in the current system.
		for m in state().active:
			if target_system(m)==game.pilot.system_id: current=m;break
		if current.is_empty() and not state().active.is_empty(): current=state().active[0]
	if not current.is_empty():
		var extra: int=state().active.size()-1+(0 if game.pilot.mission.is_empty() else 1)
		return "NEXT · %s · I to choose mission%s\n%s" % [title(current)," · +%d other job(s)" % extra if extra>0 else "",next_objective(current)]
	if not game.pilot.mission.is_empty():
		return "NEXT · Courier delivery · I for journal\nLand at %s to deliver your parcels." % objective_port(int(game.pilot.mission.object))
	# A courier may have just completed while other campaign work remains.
	if tracked_id==-2 and not state().active.is_empty():
		tracked_id=-1;return tracked_objective()
	return ""

func target_system(m: Dictionary) -> int:
	# Combat and boarding objectives take priority. Once they are secure, point
	# through the travel stop and finally to the return port.
	if not ship_goal_done(m) and int(m.ship_system)>=0: return int(m.ship_system)
	if not m.travel_done and int(m.dest)>=0: return system_of(int(m.dest))
	if int(m.back)>=0: return system_of(int(m.back))
	if int(m.dest)>=0: return system_of(int(m.dest))
	return -1

func grants_landing_clearance(port: int) -> bool:
	if not game.pilot.mission.is_empty() and int(game.pilot.mission.get("object",-1))==port:
		return true
	for m in state().active:
		if int(m.deadline)>=0 and int(state().day)>int(m.deadline): continue
		if not ship_goal_done(m): continue
		var stop: int=int(m.dest) if not m.travel_done or int(m.back)<0 else int(m.back)
		if stop==port: return true
	return false

func landing_markers() -> Dictionary:
	# Mark the next actual landing stop, rather than every port in its system.
	var markers: Dictionary={}
	if not game.pilot.mission.is_empty():
		var port: int=int(game.pilot.mission.get("object",-1))
		if port>=0: markers[port]=1
	for m in state().active:
		if not ship_goal_done(m): continue
		var port: int=int(m.dest) if not m.travel_done or int(m.back)<0 else int(m.back)
		if port>=0: markers[port]=int(markers.get(port,0))+1
	for port in markers.keys():
		if system_of(int(port))!=game.pilot.system_id or game.world_killer.destroyed(int(port)):
			markers.erase(port)
	return markers

func rush_markers() -> Dictionary:
	var markers: Dictionary={}
	for m in state().active:
		if int(m.deadline)<0: continue
		var fields: Dictionary=game.catalog.record("missions",int(m.id)).fields
		if int(fields.Flags)&2: continue
		var system: int=target_system(m)
		if system<0: continue
		var days: int=int(m.deadline)-int(state().day)
		if not markers.has(system): markers[system]={"days":days,"count":0}
		markers[system].days=mini(int(markers[system].days),days)
		markers[system].count+=1
	return markers

func map_markers() -> Dictionary:
	var markers: Dictionary={}
	if not game.pilot.mission.is_empty():
		var courier: int=int(game.pilot.mission.get("system",-1))
		if courier>=0: markers[courier]=1
	for m in state().active:
		var fields: Dictionary=game.catalog.record("missions",int(m.id)).fields
		# Original flag 0x0002 explicitly suppresses red map arrows.
		if int(fields.Flags)&2: continue
		var system: int=target_system(m)
		if system>=0: markers[system]=int(markers.get(system,0))+1
	return markers

func accept(m: Dictionary) -> bool:
	if game.mode not in ["missions","mission_offer"] or return_mode!="dock" or not eligibility(int(m.id),game.docked_id,game.mode!="mission_offer" and channel!=1): return false
	if game.mode=="mission_offer" and (approach.is_empty() or int(m.id)!=int(approach.id) or game.docked_id!=approach_port): return false
	if state().active.size()>=8 or game.pilot.cargo_used()+int(m.qty)>game.pilot.cargo_capacity(): return false
	# Rebuild from trusted catalog and current offer seed, never accept UI-supplied rewards.
	m=offer(int(m.id),game.docked_id)
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	if f.PayVal<=-30128 and f.PayVal>=-30255:
		var id: int=-int(f.PayVal)-30000
		m.prepaid=game.pilot.outfit_count(id)==0
		grant(id)
	game.sound("ui_confirm")
	state().active.append(m)
	tracked_id=int(m.id)
	last_report=text_for(m,"BriefText")
	if last_report.is_empty(): last_report=text_for(m,"QuickBrief")
	selected={}
	game.save_game(false)
	game.hud.rebuild_modal()
	return true

func reset_bar_encounters() -> void:
	tracked_id=-1
	approach={};approach_port=-1;approached.clear();bar_port=-1;bar_rolls.clear();bar_queue.clear();bar_ticks=0

func begin_port_visit() -> void:
	last_report=""
	approach={};approach_port=-1;bar_queue.clear();bar_ticks=0

func begin_bar_approach() -> void:
	# Original 0x987c checks the last bar's port before refreshing chance rolls.
	if game.mode!="dock" or game.hud.port_page!="bar": return
	if bar_port!=game.docked_id:
		bar_port=game.docked_id;bar_rolls.clear();approached.clear()
		for record in game.catalog.data.missions.values():
			if int(record.fields.AvailLoc)==1: bar_rolls[int(record.id)]=roll(int(record.id),bar_port)
	bar_queue.clear()
	for record in game.catalog.data.missions.values():
		var id: int=int(record.id)
		if int(record.fields.AvailLoc)!=1 or id in approached: continue
		if id not in [171,172] and int(bar_rolls.get(id,100))>=int(record.fields.AvailRandom): continue
		if eligibility(id,bar_port,false): bar_queue.append(id)
	bar_queue.sort_custom(func(a,b):
		var fa: int=int(game.catalog.field("missions",a,"Flags"))&4096
		var fb: int=int(game.catalog.field("missions",b,"Flags"))&4096
		return a<b if fa==fb else fa>fb)
	bar_ticks=0;bar_idle=80+randi_range(0,99)

func advance_bar(dt: float) -> void:
	if game.mode!="dock" or game.hud.port_page!="bar" or game.docked_id!=bar_port or not approach.is_empty(): return
	if bar_queue.is_empty() or state().active.size()>=8: return
	if DisplayServer.get_name()!="headless" and is_instance_valid(game.hud.modal_tween) and game.hud.modal_tween.is_running(): return
	bar_ticks=minf(8,bar_ticks+dt*BAR_EVENT_HZ)
	# At most one presentation per frame; don't replay old idle events after load.
	var ticks: int=mini(8,int(bar_ticks));bar_ticks-=ticks
	for tick in ticks:
		bar_idle+=1
		if randi_range(0,149)>=bar_idle: continue
		bar_idle=0
		while not bar_queue.is_empty():
			var id: int=bar_queue.pop_front()
			if not eligibility(id,bar_port,false): continue
			var candidate: Dictionary=offer(id,bar_port)
			if game.pilot.cargo_used()+int(candidate.qty)>game.pilot.cargo_capacity(): continue
			approach=candidate;approach_port=bar_port;approached.append(id)
			return_mode="dock";channel=1;game.set_mode("mission_offer");return

func bar_activity() -> void:
	bar_idle=0;bar_ticks=0

func resolve_approach(take_job: bool) -> void:
	if game.mode!="mission_offer" or approach.is_empty(): return
	var candidate: Dictionary=approach
	if not take_job and int(game.catalog.field("missions",int(candidate.id),"Flags"))&4: return
	if take_job and not accept(candidate):
		game.notify("This offer is no longer available or there is no room for its cargo.");return
	approach={};approach_port=-1;bar_activity()
	game.hud.port_page="bar";game.set_mode("dock")
	if take_job:
		queue_landing_report(candidate,"MISSION ACCEPTED",last_report,"Cloaking Device installed · launch and press K to cloak" if int(candidate.id)==164 and game.pilot.outfit_count(167)>0 else "Mission accepted · see journal for objectives")
		show_next_landing_report()

func grant(id: int) -> void:
	var record: Dictionary=game.catalog.record("outfits",id)
	if record.is_empty(): return
	game.pilot.outfits[str(id)]=mini(int(record.fields.Max),game.pilot.outfit_count(id)+1)
	game.notify("Installed mission equipment: "+record.name)

func queue_landing_report(m: Dictionary, heading: String, body: String, status: String) -> void:
	if body.is_empty(): body=text_for(m,"QuickBrief")
	if body.is_empty(): body="Your mission objective at this port has been updated."
	landing_reports.append({"mission":title(m),"heading":heading,"body":body,"status":status})

func show_next_landing_report() -> void:
	if not active_landing_report.is_empty() or landing_reports.is_empty(): return
	active_landing_report=landing_reports.pop_front()
	game.set_mode("mission_report")

func dismiss_landing_report() -> void:
	active_landing_report={}
	if not landing_reports.is_empty():
		show_next_landing_report()
		game.hud.rebuild_modal()
	else: game.set_mode("dock")

func reward_summary(m: Dictionary, completed: bool=false) -> String:
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	var pay: int=int(f.PayVal)
	var result: String=("%d credits received" if completed else "%d credits") % pay if pay>0 else "No credit payment"
	if pay<=-20128 and pay>=-20255:
		var outfit: Dictionary=game.catalog.record("outfits",-pay-20000)
		result=("Installed: " if completed else "Reward: ")+str(outfit.get("name","mission equipment"))
	elif pay<=-30128 and pay>=-30255:
		result=str(game.catalog.record("outfits",-pay-30000).get("name","mission equipment"))+(" retained" if completed else " provided on acceptance")
	elif pay<=-10128 and pay>=-10255:
		result=str(game.catalog.record("governments",-pay-10000).get("name","Faction"))+(" record cleared" if completed else " record cleared on completion")
	var govt: int=int(f.CompGovt)
	if govt>=0 and govt<128: govt+=128
	var government: Dictionary=game.catalog.record("governments",govt)
	if int(f.CompReward)>0 and not government.is_empty(): result+=" · +%d %s reputation" % [int(f.CompReward),government.name]
	for clearance in [61,66]:
		if clearance in [int(f.CompBitSet),int(f.CompBitSet2)]: result+=" · "+("Rebel" if clearance==61 else "Confederation")+" military clearance "+("unlocked" if completed else "on completion")
	return result

func completion_status(m: Dictionary) -> String:
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	var result: String=reward_summary(m,true)
	if int(m.back)>=0:
		for record in game.catalog.data.missions.values():
			if int(record.fields.AvailLoc)!=1 or int(record.fields.AvailBitSet)<0: continue
			if int(record.fields.AvailBitSet) not in [int(f.CompBitSet),int(f.CompBitSet2)]: continue
			if eligibility(int(record.id),int(m.back),false):
				result+="\nNext: visit the spaceport bar at "+game.catalog.record("objects",int(m.back)).name
				break
	return result

func commitment_notes(m: Dictionary) -> String:
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	var notes: PackedStringArray=[]
	if int(f.CanAbort)==0: notes.append("This assignment cannot be voluntarily aborted.")
	if int(f.Flags)&4: notes.append("This original offer cannot be declined.")
	if int(f.ShipGoal)==3: notes.append("Keep every escorted ship alive until arrival.")
	if int(f.ShipGoal) in [2,5]: notes.append("Required ships must survive until you board them.")
	if int(f.ScanGovt)>=0 and int(f.CargoType)>=0 and int(f.FailIfScan)!=0:
		notes.append("%s cargo scans fail this assignment." % game.catalog.record("governments",int(f.ScanGovt)).get("name","Patrol"))
	if int(f.PayVal)<=-30128 and int(f.PayVal)>=-30255 and int(f.Flags)&32:
		notes.append("If loaned, the %s is removed on failure." % game.catalog.record("outfits",-int(f.PayVal)-30000).get("name","mission equipment"))
	return "\n".join(notes)

func abort_reason(m: Dictionary) -> String:
	if m not in state().active: return "This assignment is no longer active."
	return "This assignment cannot be voluntarily aborted." if int(game.catalog.field("missions",int(m.id),"CanAbort"))==0 else ""

func retry_hint(m: Dictionary) -> String:
	if not eligibility(int(m.id),int(m.origin),false): return ""
	var location: int=int(game.catalog.field("missions",int(m.id),"AvailLoc"))
	if location not in [0,1]: return "Retry: find the mission contact again."
	return "Retry: ask at the %s at %s." % ["spaceport bar" if location==1 else "mission computer",objective_port(int(m.origin))]

func finish(m: Dictionary, success: bool, aborted: bool = false, landing_popup: bool = false, failure_reason: String="") -> void:
	if m not in state().active: return
	arrival_delays.erase(int(m.id))
	auxiliary_delays.erase(int(m.id))
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	if success:
		game.pilot.achievements.contracts_completed+=1
		game.pilot.credits+=maxi(0,int(f.PayVal))
		if f.PayVal<=-20128 and f.PayVal>=-20255: grant(-int(f.PayVal)-20000)
		if f.PayVal<=-10128 and f.PayVal>=-10255: game.pilot.reputation[str(-int(f.PayVal)-10000)]=0
		apply_bit(int(f.CompBitSet));apply_bit(int(f.CompBitSet2))
		if int(m.id) not in state().completed: state().completed.append(int(m.id))
	else:
		apply_bit(int(f.FailBitSet))
		if m.prepaid and int(f.Flags)&32: game.pilot.outfits.erase(str(-int(f.PayVal)-30000));game.cloak.set_active(false)
	var gov: int=int(f.CompGovt)
	if gov>=0 and gov<128: gov+=128
	var record: Dictionary=game.catalog.record("governments",gov)
	if not record.is_empty():
		var reward: int=int(f.CompReward) if success else -absi(int(f.CompReward))/2
		if aborted and int(f.Flags)&64: reward=-absi(int(f.CompReward))*5
		game.pilot.reputation[str(gov)]=clampi(int(game.pilot.reputation.get(str(gov),record.fields.InitialRec))+reward,-10000,10000)
	state().active.erase(m)
	if not success:
		if failure_reason.is_empty(): failure_reason="Assignment aborted." if aborted else "The mission requirements were not met."
		if m.prepaid and int(f.Flags)&32:
			var equipment: String=str(game.catalog.record("outfits",-int(f.PayVal)-30000).get("name","mission equipment"))
			if not equipment.to_lower() in failure_reason.to_lower(): failure_reason+=" Loaned %s removed." % equipment
		var retry: String=retry_hint(m)
		if not retry.is_empty(): failure_reason+=" "+retry
	if not success and game.autopilot.active() and game.autopilot.job.get("kind","")=="mission" and int(game.autopilot.job.get("id",-1))==int(m.id):
		game.autopilot.cancel("Mission failed: "+failure_reason)
	var report_text: String=text_for(m,"CompText" if success else "FailText")
	if not success and not failure_reason.is_empty():
		report_text=failure_reason+("\n\n"+report_text if not report_text.is_empty() else "")
		flight_alert="MISSION FAILED · "+title(m)+" · "+failure_reason
		flight_alert_seconds=25
	last_report=("Mission complete: " if success else "Mission failed: ")+title(m)+"\n\n"+report_text
	if landing_popup:
		var reward: String="No rewards awarded"
		if success: reward=completion_status(m)
		queue_landing_report(m,"MISSION COMPLETE" if success else "MISSION FAILED",report_text,reward)
	game.notify(("Mission complete: " if success else "Mission failed: ")+title(m))
	for npc in game.npcs.duplicate():
		if int(npc.get("mission_id",-1))==int(m.id): game.traffic.retire(npc)
	selected={}
	game.save_game(false)

func abort(m: Dictionary) -> void:
	var reason: String=abort_reason(m)
	if not reason.is_empty(): game.notify(reason);game.sound("ui_error");return
	finish(m,false,true)
	game.hud.rebuild_modal()

func ship_goal_done(m: Dictionary) -> bool:
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	if f.ShipCount<=0 or f.ShipGoal<0: return true
	if m.actors.size()!=int(f.ShipCount): return false
	for a in m.actors:
		match int(f.ShipGoal):
			0,6:
				if not a.dead: return false
			1:
				if not a.disabled or a.dead: return false
			2,5:
				if not a.boarded: return false
			3:
				if a.dead or not m.met: return false
			4:
				if not a.observed: return false
	return true

func landed(port: int, show_popup: bool = false) -> void:
	for m in state().active.duplicate():
		var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
		var was_picked: bool=m.picked
		var was_delivered: bool=m.delivered
		var was_travel_done: bool=m.travel_done
		if port==int(m.dest):
			m.travel_done=true
			if int(f.PickupMode)==1:
				m.picked=true
				last_report=text_for(m,"LoadCargText")
			if int(f.DropoffMode)==0 and m.picked: m.delivered=true
		if int(m.dest)<0 and port==int(m.back) and int(f.DropoffMode)==0 and m.picked: m.delivered=true
		var end_port: int=int(m.back) if int(m.back)>=0 else int(m.dest)
		if (port==end_port or end_port<0) and int(f.DropoffMode)==1 and m.picked: m.delivered=true
		var at_end: bool=port==int(m.back) if int(m.back)>=0 else (port==int(m.dest) if int(m.dest)>=0 else true)
		var cargo_done: bool=int(f.CargoType)<0 or (m.picked and (m.delivered or int(f.DropoffMode)<0))
		if at_end and m.travel_done and cargo_done and ship_goal_done(m):
			finish(m,true,false,show_popup)
		elif show_popup and port==int(m.dest):
			if not was_picked and m.picked:
				queue_landing_report(m,"CARGO RECEIVED",text_for(m,"LoadCargText"),"Mission cargo loaded · %d t" % int(m.qty))
			elif not was_delivered and m.delivered:
				queue_landing_report(m,"CARGO DELIVERED",text_for(m,"DropCargText"),"Proceed to the return destination")
			elif not was_travel_done and m.travel_done:
				queue_landing_report(m,"DESTINATION REACHED",text_for(m,"DropCargText"),"Mission objective updated")

func jumped() -> void:
	state().day+=clampi(1+int(game.catalog.field("ships",game.pilot.ship_id,"Mass"))/100,1,3)
	state().visit+=1
	game.fleet_service.sync();game.fleet_service.payroll()
	game.world_activity.sync()
	for m in state().active.duplicate():
		if int(m.deadline)>=0 and int(state().day)>int(m.deadline): finish(m,false,false,false,"Deadline missed: assignment was due on day %d." % int(m.deadline))

func actor_event(npc: Dictionary, event: String) -> void:
	for m in state().active.duplicate():
		if int(npc.get("mission_id",-1))!=int(m.id): continue
		if npc.get("mission_aux",false):
			if event=="kill" and not int(game.catalog.record("missions",int(m.id)).fields.Flags)&16: m.aux[int(npc.mission_slot)].dead=true
			continue
		var was_done: bool=ship_goal_done(m)
		var a: Dictionary=m.actors[int(npc.mission_slot)]
		var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
		if event=="board":
			npc.boarded=true
			a.boarded=true
			if int(f.PickupMode)==2: m.picked=true
			game.notify("Mission boarding objective secured.")
		if event=="disable": a.disabled=true
		if event in ["kill","escape"]:
			a.dead=true
			if (event=="escape" and int(f.ShipGoal)==0) or int(f.ShipGoal) in [1,3] or (int(f.ShipGoal) in [2,5] and not a.boarded):
				var reason: String="The assassination target escaped." if event=="escape" else "A required mission ship was destroyed."
				if int(f.ShipGoal)==3: reason="An escorted ship was destroyed." if event=="kill" else "An escorted ship left before reaching its destination."
				elif int(f.ShipGoal) in [2,5]: reason="The mission ship was destroyed before boarding." if event=="kill" else "The mission ship escaped before boarding."
				finish(m,false,false,false,reason)
		if m in state().active and not was_done:
			var instruction: String=return_for_payment(m)
			if not instruction.is_empty(): game.notify(instruction);game.sound("ui_confirm")

# Only the active, unboarded item carrier needs capture protection; auxiliaries
# and assassination targets retain their normal combat rules.
func needs_boarding(npc: Dictionary) -> bool:
	if npc.get("mission_aux",false) or npc.get("boarded",false): return false
	for m in state().active:
		if int(m.id)!=int(npc.get("mission_id",-1)): continue
		var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
		if int(f.ShipGoal) not in [2,5] and int(f.PickupMode)!=2: return false
		var slot: int=int(npc.get("mission_slot",-1))
		return slot>=0 and slot<m.actors.size() and not m.actors[slot].boarded and not m.actors[slot].dead
	return false

func boarding_report(npc: Dictionary) -> String:
	var id: int=int(npc.get("mission_id",-1))
	if id<0: return ""
	for m in state().active:
		if int(m.id)!=id: continue
		var f: Dictionary=game.catalog.record("missions",id).fields
		if npc.get("mission_aux",false) and int(f.PickupMode)==2:
			return "This is an escort, not the ship carrying the mission item. Board the [MISSION TARGET] ship for %s." % title(m)
		if not npc.get("mission_aux",false) and int(f.PickupMode)==2 and m.picked:
			var recovered: String=text_for(m,"LoadCargText")
			return (recovered+"\n" if not recovered.is_empty() else "Mission item recovered.\n")+"Transferred automatically to your mission cargo; there is nothing to take from ordinary cargo.\nNext: "+objective_action(m)
		if not npc.get("mission_aux",false) and int(f.ShipGoal) in [2,5] and npc.boarded:
			return "Mission boarding recorded. Next: "+objective_action(m)
	return "This ship's mission is no longer active. Check your mission journal for the result and retry instructions."

func actors(m: Dictionary, aux: bool) -> Array:
	return m.aux if aux else m.actors

func spawn_group(m: Dictionary, aux: bool) -> void:
	var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
	var encounter: Dictionary=game.catalog.record("encounters",int(f.AuxShipDude if aux else f.ShipDude))
	var count: int=int(f.AuxShipCount if aux else f.ShipCount)
	if count<=0 or encounter.is_empty(): return
	# SpacePort's original-resource conversion maps behavior 9/10/11 to
	# normal/attack/protect plus a delayed hyperspace arrival (ShipStart=1).
	if not aux and int(f.ShipBehav)>=9:
		if not arrival_delays.has(int(m.id)): arrival_delays[int(m.id)]=ARRIVAL_DELAY
		if float(arrival_delays[int(m.id)])>0: return
	var list: Array=actors(m,aux)
	if list.is_empty():
		var pool: Array=[]
		for i in encounter.fields.ShipTypes.size():
			if encounter.fields["% Prob"][i]>0: pool.append({"ship":int(encounter.fields.ShipTypes[i]),"weight":float(encounter.fields["% Prob"][i])})
		for i in count:
			var choice: Dictionary=game.traffic.choose(pool)
			if choice.is_empty(): return
			list.append({"ship":int(choice.ship),"health":-1.0,"disabled":not aux and int(f.ShipGoal)==5,"boarded":false,"observed":false,"dead":false})
	for i in list.size():
		var a: Dictionary=list[i]
		if a.dead: continue
		var exists: bool=false
		for npc in game.npcs:
			if int(npc.get("mission_id",-1))==int(m.id) and npc.get("mission_aux",false)==aux and int(npc.get("mission_slot",-1))==i: exists=true;break
		if exists: continue
		if game.npcs.size()>=game.traffic.MAX_CONTACTS:
			for npc in game.npcs.duplicate():
				if npc.ambient: game.traffic.retire(npc);break
		var npc: Dictionary=game.traffic.spawn(int(a.ship),int(encounter.fields.Govt),int(encounter.fields.AIType),game.pilot.position+Vector2.from_angle(float(i)*TAU/maxi(count,1))*650)
		if npc.is_empty(): continue
		if not aux and int(f.ShipBehav)>=9:
			game.burst(npc.position,Color("83cfff"),10)
			if i==0: game.sound("arrival")
		npc.mission_id=int(m.id);npc.mission_slot=i;npc.mission_aux=aux
		if not aux and int(f.ShipGoal)==6: npc.mission_can_retreat=true
		if a.has("person_id"):
			game.persons.configure(npc,int(a.person_id));npc.ambient=false
		npc.name=npc.name if a.has("person_id") else ship_name(m,i) if int(f.ShipNameID)>=0 else "%s · %s" % [npc.name,title(m)]
		if not aux and int(f.ShipGoal) in [0,2,5,6]: npc.name="[MISSION TARGET] "+str(npc.name)
		if a.health>=0: npc.health=float(a.health)
		if a.has("shield") and a.has("armor"): npc.shield=float(a.shield);npc.armor=float(a.armor)
		npc.disabled=a.disabled;npc.boarded=a.boarded
		if a.disabled and a.health<0: npc.health=npc.max_health*.1
		if not aux:
			a.observed=true;m.met=true
			if int(f.ShipBehav) in [0,10]: npc.provoked=true;npc.hostile=true
			if int(f.ShipBehav) in [1,11] or int(f.ShipGoal)==3: npc.truce=true;npc.hostile=false;npc.mission_escort=true

func enter_system() -> void:
	for m in state().active.duplicate():
		var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
		if int(f.AuxShipCount)>0 and not auxiliary_delays.has(int(m.id)):
			auxiliary_delays[int(m.id)]=float(70+randi_range(0,69))/ENCOUNTER_TICKS_PER_SECOND
		if game.pilot.system_id==int(m.ship_system) or int(f.ShipSyst)==-6 or (m.met and (int(f.ShipGoal)==3 or int(f.ShipBehav) in [1,11])): spawn_group(m,false)
		var loc: int=int(f.AuxShipSyst)
		var matches: bool=loc in [-1,-6] or loc==game.pilot.system_id
		if loc==-2: matches=game.pilot.system_id==system_of(int(m.dest))
		if loc==-3: matches=game.pilot.system_id==system_of(int(m.back))
		if loc>=9999: matches=govt_matches(loc,int(game.catalog.system(game.pilot.system_id).fields.Govt))
		if loc>=5000 and loc<6000: matches=game.pilot.system_id==loc-5000+128 or game.pilot.system_id in game.catalog.system(loc-5000+128).get("links",[])
		if matches and float(auxiliary_delays.get(int(m.id),0))<=0: spawn_group(m,true)
		if int(f.Flags)&1 and game.npcs.any(func(n): return n.get("mission_id",-1)==int(m.id) and not n.get("mission_aux",false)):
			apply_bit(int(f.CompBitSet));apply_bit(int(f.CompBitSet2));state().active.erase(m)

func sync_actors() -> void:
	for npc in game.npcs:
		if not npc.has("mission_id"): continue
		for m in state().active:
			if int(m.id)==int(npc.mission_id):
				var a: Dictionary=actors(m,npc.mission_aux)[int(npc.mission_slot)]
				game.Combat.sync(npc)
				a.health=npc.health;a.shield=npc.shield;a.armor=npc.armor;a.disabled=npc.disabled;a.boarded=a.boarded or npc.boarded

func advance(dt: float) -> void:
	for id in arrival_delays: arrival_delays[id]=maxf(0,float(arrival_delays[id])-dt)
	for id in auxiliary_delays: auxiliary_delays[id]=maxf(0,float(auxiliary_delays[id])-dt)
	enter_system()
	sync_actors()
	scan_clock+=dt
	if scan_clock<SCAN_INTERVAL: return
	scan_clock=fmod(scan_clock,SCAN_INTERVAL)
	scan_missions()

func scanner_eligible(npc: Dictionary,fields: Dictionary) -> bool:
	if int(fields.ScanGovt)<0 or int(fields.CargoType)<0: return false
	if npc.disabled or int(npc.ai) not in [3,4] or npc.get("health",0)<=0: return false
	if npc.has("fleet_uid") or npc.get("player_ally",false) or npc.get("mission_escort",false) or npc.has("departure"): return false
	if int(npc.faction)!=int(fields.ScanGovt): return false
	var government: Dictionary=game.catalog.record("governments",int(npc.faction))
	return not government.is_empty() and int(government.fields.SmugPenalty)>0

func can_scan(npc: Dictionary,fields: Dictionary) -> bool:
	if not scanner_eligible(npc,fields): return false
	var offset: Vector2=npc.position-game.pilot.position
	var motion: Vector2=Vector2(npc.get("velocity",Vector2.ZERO))-game.velocity
	# PPC 0x31a0-0x325c: 180-coordinate inclusive square, then strict
	# 0.35-coordinate/tick per-axis motion gate. Convert both at 5/3 and 60 Hz.
	return absf(offset.x)<=SCAN_AXIS_RANGE and absf(offset.y)<=SCAN_AXIS_RANGE and absf(motion.x)<35.0 and absf(motion.y)<35.0

func scan_missions(scanner: Dictionary={}) -> void:
	if game.mode!="flight" or game.cloak.active: return
	var scanned_contacts: Array=[]
	for m in state().active.duplicate():
		var f: Dictionary=game.catalog.record("missions",int(m.id)).fields
		if f.ScanGovt<0 or not m.picked or m.delivered: continue
		for npc in game.npcs:
			if not scanner.is_empty() and npc!=scanner: continue
			if npc in scanned_contacts: continue
			if not can_scan(npc,f): continue
			if npc.get("scanned_mission_%d" % m.id,false): continue
			npc["scanned_mission_%d" % m.id]=true
			scanned_contacts.append(npc) # Original scan routine returns after its first matching cargo.
			game.Factions.penalize(game.catalog,game.pilot,int(npc.faction),"SmugPenalty")
			game.notify("Cargo scan detected illegal mission cargo.")
			if f.FailIfScan!=0:
				var reason: String="Confederation patrol detected the mission cargo." if int(f.ScanGovt)==128 else "A patrol detected the mission cargo."
				if int(m.id)==164 and m.prepaid: reason+=" Loaned Cloaking Device removed. Return to Palshife to retry; cloak before approaching patrols."
				finish(m,false,false,false,reason)
			break

func open() -> void:
	if game.mode not in ["flight","dock"]: return
	if channel==2 and state().active.is_empty() and game.pilot.mission.is_empty():
		game.flight_welcome_seconds=0.0
		game.empty_journal_seconds=8.0
		return
	game.empty_journal_seconds=0.0
	return_mode=game.mode;selected={};selected_courier=false;last_report=""
	game.set_mode("missions")
