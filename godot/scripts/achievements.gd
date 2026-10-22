extends RefCounted
var game
const COMMON=[
	{"id":"environment","name":"Environmental Investigation","missions":[152,153,154,155,156]},
	{"id":"starbound","name":"Starbound Shipping","missions":[173,174,175]},
	{"id":"colony","name":"Colony Assistance","missions":[178,179,180]},
	{"id":"uge","name":"UGE Membership","missions":[209,210]},
	{"id":"hunters","name":"Bounty Hunters","missions":[236,237,238,239,240,241]}]
const CONFED=[171,166,167,168,169,170,190,191,192,193,194]
const REBEL=[172,163,164,165,184,185,186,187,188,189]
const ALIEN_REBEL=[184,185,186,187,188,189]
const ALIEN_CONFED=[190,191,192,193,194]
const ASTRODYNE=[230,231,232,233,234,235]
const CARRIER=[242]
static func fresh() -> Dictionary:
	return {"earned":{},"peak_credits":0,"peak_fleet":0,"courier_deliveries":0,"contracts_completed":0}
static func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("earned",{}) is Dictionary or value.get("earned",{}).size()>100: return false
	for id in value.get("earned",{}):
		var day=value.earned[id]
		if not id is String or id.length()>64 or not (day is int or day is float) or not is_finite(float(day)) or day<0 or day!=int(day): return false
	for key in ["peak_credits","peak_fleet","courier_deliveries","contracts_completed"]:
		var n=value.get(key,0)
		if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>1000000000000 or n!=int(n): return false
	return true
static func normalized(value: Dictionary) -> Dictionary:
	var result=fresh();result.earned=value.get("earned",{}).duplicate()
	for key in ["peak_credits","peak_fleet","courier_deliveries","contracts_completed"]: result[key]=int(value.get(key,0))
	return result
func fraction(ids: Array) -> float:
	var done: int=0
	for id in ids:
		if id in game.pilot.campaign.completed: done+=1
	return float(done)/ids.size()
func progress() -> Dictionary:
	var p=game.pilot
	var branch: String="Confederation" if 43 in p.campaign.bits or 171 in p.campaign.completed else "Rebellion" if 44 in p.campaign.bits or 172 in p.campaign.completed else "Undecided"
	var tracks: Array=[];var total: float=0
	for track in COMMON:
		var value: float=fraction(track.missions);total+=value
		tracks.append({"name":track.name,"value":value})
	var war: float=fraction(CONFED) if branch=="Confederation" else fraction(REBEL) if branch=="Rebellion" else maxf(fraction(CONFED),fraction(REBEL))
	var research: float=fraction(CARRIER) if branch=="Confederation" else fraction(ASTRODYNE) if branch=="Rebellion" else maxf(fraction(CARRIER),fraction(ASTRODYNE))
	tracks.append({"name":"Military Story · "+branch,"value":war})
	tracks.append({"name":"Carrier Operations" if branch=="Confederation" else "Astrodyne Research" if branch=="Rebellion" else "Faction Special Operations","value":research})
	total=(total+war+research)/tracks.size()
	var visited: int=0
	for id in game.catalog.data.systems:
		if int(id) in p.visited: visited+=1
	var exploration: float=float(visited)/game.catalog.data.systems.size()
	return {"overall":exploration*.4+total*.6,"exploration":exploration,"story":total,"visited":visited,"systems":game.catalog.data.systems.size(),"tracks":tracks,"branch":branch}
func badges() -> Array:
	var p=game.pilot;var state: Dictionary=p.achievements
	var records: Array=[]
	var jobs: int=maxi(int(state.contracts_completed),p.campaign.completed.size()+int(state.courier_deliveries))
	for tier in [[1,"first_job","First Contract"],[10,"jobs_10","Reliable Captain"],[25,"jobs_25","Veteran Contractor"]]:
		records.append(badge(tier[1],tier[2],"Complete %d contract%s." % [tier[0],"" if tier[0]==1 else "s"],jobs,tier[0]))
	for tier in [[5,"explore_5","Leaving Home"],[25,"explore_25","Pathfinder"],[50,"explore_50","Deep Space Explorer"],[game.catalog.data.systems.size(),"explore_all","Across the Galaxy"]]:
		records.append(badge(tier[1],tier[2],"Visit %d different systems." % tier[0],p.visited.size(),tier[0]))
	for tier in [[100000,"credits_100k","Making a Living"],[1000000,"credits_1m","Millionaire"],[10000000,"credits_10m","Space Tycoon"]]:
		records.append(badge(tier[1],tier[2],"Hold %s credits at once." % str(tier[0]),state.peak_credits,tier[0]))
	for tier in [[300,"combat_300","Proven Pilot"],[1500,"combat_1500","Combat Veteran"],[8000,"combat_8000","Ace Captain"]]:
		records.append(badge(tier[1],tier[2],"Reach combat rating %d." % tier[0],p.campaign.rating,tier[0]))
	for tier in [[1,"fleet_1","Wing Commander"],[3,"fleet_3","Squadron Leader"],[8,"fleet_8","Fleet Admiral"]]:
		records.append(badge(tier[1],tier[2],"Command %d hired or captured escorts." % tier[0],state.peak_fleet,tier[0]))
	for track in COMMON:
		records.append(badge("story_"+track.id,track.name,"Complete this story's main milestones.",roundi(fraction(track.missions)*track.missions.size()),track.missions.size()))
	records.append(badge("war_hero","War Hero","Complete either faction's main military story.",maxf(fraction(CONFED),fraction(REBEL)),1))
	records.append(badge("alien_threat","Alien Threat","Complete either faction's Alien mission chain.",maxf(fraction(ALIEN_CONFED),fraction(ALIEN_REBEL)),1))
	records.append(badge("special_ops","Special Operations","Complete Astrodyne research or the carrier operation.",maxf(fraction(ASTRODYNE),fraction(CARRIER)),1))
	records.append(badge("new_ship","Moving Up","Command a ship other than the starting shuttle.",1 if p.ship_id not in [128,191] else 0,1))
	records.append(badge("experimental","Experimental Technology","Earn a particle beam, cloak, or tractor beam.",1 if p.outfit_count(166)>0 or p.outfit_count(167)>0 or p.outfit_count(173)>0 else 0,1))
	records.append(badge("world_killer","The Reckoning","Obliterate a planet or station.",p.world_killer.destroyed.size(),1))
	return records
func badge(id: String,title: String,description: String,value: float,target: float) -> Dictionary:
	var earned: bool=game.pilot.achievements.earned.has(id)
	return {"id":id,"name":title,"description":description,"value":value,"target":target,"fraction":1.0 if earned else clampf(value/target,0,1),"earned":earned,"day":game.pilot.achievements.earned.get(id,-1)}
func update(announce: bool=true) -> bool:
	var state: Dictionary=game.pilot.achievements
	state.contracts_completed=maxi(int(state.contracts_completed),game.pilot.campaign.completed.size()+int(state.courier_deliveries))
	state.peak_credits=maxi(int(state.peak_credits),game.pilot.credits)
	state.peak_fleet=maxi(int(state.peak_fleet),game.pilot.fleet.size())
	var unlocked: Array=[]
	for entry in badges():
		if not entry.earned and entry.value>=entry.target:
			state.earned[entry.id]=int(game.pilot.campaign.day);unlocked.append(entry)
	if announce and not unlocked.is_empty() and is_instance_valid(game.hud): game.hud.show_achievement(unlocked)
	return not unlocked.is_empty()

func next_steps(id: String) -> String:
	var guide=preload("res://scripts/achievement_guidance.gd").new()
	guide.game=game
	return guide.steps(id)

func guidance(id: String) -> Dictionary:
	var guide=preload("res://scripts/achievement_guidance.gd").new()
	guide.game=game
	var text: String=guide.steps(id)
	return {"text":text,"destinations":guide.destinations.duplicate()}

func jump_to_guidance(system: int) -> void:
	if game.catalog.system(system).is_empty(): return
	if game.hyperdrive.active() or not game.chain_route.is_empty():
		game.set_mode("flight")
		game.notify("Finish or cancel the current jump first.")
		return
	var route: Array=game.autopilot.path(game.pilot.system_id,system)
	if system!=game.pilot.system_id and route.is_empty():
		game.notify("No hyperspace route to this system.")
		return
	if game.autopilot.active(): game.autopilot.cancel("Navigation selected from badge guidance.")
	if game.achievements_return_mode=="dock":
		game.set_mode("dock")
		game.launch()
	else: game.set_mode("flight")
	if system==game.pilot.system_id:
		game.notify("You are already in "+game.catalog.system(system).name+". Follow the badge's local instructions.")
		return
	game.map_route=route
	game.select_destination(system if game.pilot.cheat_chain_jump else int(route.front()))
	game.start_jump()
