extends RefCounted
# Graph distance to the next known objective, independent of map/jump cheats.
static func jumps(catalog,origin: int,target: int) -> int:
	if catalog.system(target).is_empty(): return -1
	if origin==target: return 0
	var queue: Array=[origin];var distances: Dictionary={origin:0}
	while not queue.is_empty():
		var current: int=queue.pop_front()
		for neighbor in catalog.system(current).links:
			if distances.has(int(neighbor)): continue
			var count: int=int(distances[current])+1
			if int(neighbor)==target: return count
			distances[int(neighbor)]=count;queue.append(int(neighbor))
	return -1

static func info(game,entry: Dictionary,journal: bool=false) -> Dictionary:
	var courier: bool=entry.get("courier",false)
	var target: int=-1;var cargo: int=5;var pay: int=1200;var deadline: int=-1
	if courier:
		var job: Dictionary=game.pilot.mission if journal else game.courier_destination()
		target=int(job.get("system",-1))
	else:
		target=game.missions.target_system(entry)
		cargo=int(entry.get("qty",0));deadline=int(entry.get("deadline",-1))
		pay=int(game.catalog.field("missions",int(entry.id),"PayVal"))
	var distance: int=jumps(game.catalog,game.pilot.system_id,target)
	var location: String=game.catalog.system(target).get("name","Unknown objective")
	return {"jumps":distance,"target":target,"location":location,"cargo":cargo,"pay":pay,
		"days":deadline-int(game.pilot.campaign.day) if deadline>=0 else -1,"has_deadline":deadline>=0,
		"free":game.pilot.cargo_capacity()-game.pilot.cargo_used()}

static func distance_text(info: Dictionary) -> String:
	if info.target<0: return "Objective location unknown"
	if info.jumps<0: return "No connected route"
	if info.jumps==0: return "Same system"
	return "%d jump%s" % [info.jumps,"" if info.jumps==1 else "s"]

static func terms(info: Dictionary) -> String:
	var pay: String="%s cr" % str(info.pay) if info.pay>0 else "Reward: see briefing"
	var deadline: String=("Deadline passed" if info.days<0 else "%d day%s left" % [info.days,"" if info.days==1 else "s"]) if info.has_deadline else "No deadline"
	return "%s · %d t cargo · %s" % [pay,info.cargo,deadline]
