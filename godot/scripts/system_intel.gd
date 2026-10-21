extends RefCounted
# Hints describe original mission chains; availability and stock come from live data.
const CHAINS=[
	{"ids":[171,166,167,168,169,170,190,191,192,193,194],"hint":"Confederation contacts recruit reliable pilots for increasingly sensitive operations.","unlock":"Long-term service can earn military ship clearance and experimental beam technology."},
	{"ids":[172,163,164,165,184,185,186,187,188,189],"hint":"Rebel couriers can earn the trust needed for special operations.","unlock":"Trusted Rebel pilots can gain military hardware access and covert equipment."},
	{"ids":[152,153,154,155,156],"hint":"Ask about industrial dumping. A local environmental investigation has more behind it than a routine delivery.","unlock":"Follow the investigation by returning to your contact after each assignment."},
	{"ids":[173,174,175,176,177],"hint":"Starbound Shipping needs dependable help. A small delivery can become a continuing relationship.","unlock":"Keep working with the company to uncover its later contracts."},
	{"ids":[178,179,180,181,182,183],"hint":"Engineers and colonists need transport. Helping a young colony can lead to resupply and defense work.","unlock":"Return to the colony as its needs develop."},
	{"ids":[209,210,211,212,213,214,215,216,217,218,219],"hint":"United Galactic Express notices pilots with a solid combat record and room for valuable cargo.","unlock":"Building trust with UGE opens a longer run of company assignments."},
	{"ids":[230,231,232,233,234,235],"hint":"Astrodyne is interested in experienced pilots with strong Rebel connections.","unlock":"Its research assignments can eventually yield tractor-beam technology."},
	{"ids":[236,237,238,239,240,241],"hint":"An unusual passenger may draw a seasoned combat pilot into bounty-hunter business.","unlock":"Follow the contacts you meet rather than treating every passenger job as routine freight."},
	{"ids":[242,243],"hint":"Confederation officers have dangerous carrier operations for proven pilots.","unlock":"Success can lead to further carrier contracts."}]

static func report(game, system: int, only_port: int=-1) -> Dictionary:
	var known: bool=system==game.pilot.system_id or system in game.pilot.visited or system in game.pilot.surveyed
	var result={"known":known,"hints":[],"outfits":[],"ships":[]}
	if not known: return result
	var ports: Array=[]
	for id in game.catalog.system(system).get("objects",[]):
		if only_port>=0 and int(id)!=only_port: continue
		var port: Dictionary=game.catalog.record("objects",int(id))
		if not port.is_empty() and int(port.fields.Flags)&1 and not game.world_killer.destroyed(int(id)): ports.append(port)
	for active in game.pilot.campaign.active:
		if game.missions.target_system(active)!=system: continue
		var target: int=int(active.dest) if not active.travel_done or int(active.back)<0 else int(active.back)
		if only_port>=0 and target!=only_port: continue
		result.hints.append("Active assignment: "+game.missions.title(active)+". Check your mission journal for the current objective here.")
	for chain in CHAINS:
		var added: bool=false
		for id in chain.ids:
			var record: Dictionary=game.catalog.record("missions",int(id));var f: Dictionary=record.fields
			if not game.missions.bit_matches(int(f.AvailBitSet)): continue
			if int(f.AvailBitClr)>=0 and int(f.AvailBitClr) in game.pilot.campaign.bits: continue
			if int(id) in game.pilot.campaign.completed: continue
			if game.pilot.campaign.active.any(func(m):return int(m.id)==int(id)): continue
			for port in ports:
				if not game.missions.port_matches(int(f.AvailStel),int(port.id)): continue
				var ready: bool=game.missions.eligibility(int(id),int(port.id),false)
				var requirements: Array[String]=[]
				if int(f.AvailRating)>int(game.pilot.campaign.rating): requirements.append("build your combat rating to %d" % int(f.AvailRating))
				if not ready and requirements.is_empty(): requirements.append("improve your standing with the local authorities")
				var place: String="spaceport bar" if int(f.AvailLoc)==1 else "mission computer" if int(f.AvailLoc)==0 else "local contacts"
				var line: String="%s — %s %s %s %s" % [port.name,chain.hint,"Ask at the" if ready else "Work toward meeting contacts at the",place+".",chain.unlock]
				if not requirements.is_empty(): line+=" First, "+", ".join(requirements)+"."
				elif int(f.AvailRandom)<100: line+=" Contacts are intermittent; an offer is not guaranteed on every visit."
				result.hints.append(line);added=true;break
			if added: break
	for port in ports:
		var f: Dictionary=port.fields
		var special: Array=[int(f.SpecialTech1),int(f.SpecialTech2),int(f.SpecialTech3)]
		if int(f.Flags)&4:
			for id in game.outfitter.stock():
				var item: Dictionary=game.catalog.record("outfits",id);var tech: int=int(item.fields.TechLevel)
				if tech<100 or tech>=9999 or tech not in special: continue
				result.outfits.append(stock_entry(game,item,port))
		if int(f.Flags)&8:
			for id in game.shipyard.ships():
				var item: Dictionary=game.catalog.record("ships",id);var tech: int=int(item.fields.TechLevel)
				if tech>int(f.TechLevel) and tech not in special: continue
				result.ships.append(stock_entry(game,item,port))
	return result

static func stock_entry(game,item: Dictionary,port: Dictionary) -> Dictionary:
	var unlocked: bool=game.missions.bit_matches(int(item.fields.MissionBit))
	return {"id":int(item.id),"name":item.name,"port":port.name,"locked":not unlocked,"clearance":"Rebel service" if int(item.fields.MissionBit)==61 else "Confederation service" if int(item.fields.MissionBit)==66 else "mission clearance"}

static func text(data: Dictionary, section: String="all") -> String:
	if not data.known: return "Visit or survey this system to discover local contacts, shipyards and special equipment."
	var lines: Array[String]=[]
	if section!="stock":
		lines.append("LOCAL LEADS")
		if data.hints.is_empty(): lines.append("No new story lead is known here at your current progress. Check the bar and mission computer for ordinary work; return to earlier contacts after completing their assignments.")
		else:
			for hint in data.hints: lines.append(str(hint))
		lines.append("Offers depend on reputation, combat experience and chance; a lead does not guarantee a job on every visit.")
	if section!="leads":
		lines.append("SPECIAL OUTFITS")
		if data.outfits.is_empty(): lines.append("No special-tech outfits stocked at surviving local ports.")
		for item in data.outfits: lines.append(stock_text(item))
		lines.append("LOCAL SHIPYARDS")
		if data.ships.is_empty(): lines.append("No ships sold at surviving local ports.")
		for item in data.ships: lines.append(stock_text(item))
		lines.append("Listings describe local stock and clearance. Purchase still requires sufficient credits and a suitable ship.")
	return "\n\n".join(lines)

static func stock_text(item: Dictionary) -> String:
	return "%s — %s%s" % [item.name,item.port," (locked: "+item.clearance+")" if item.locked else ""]
