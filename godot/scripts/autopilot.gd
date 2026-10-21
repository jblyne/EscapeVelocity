extends RefCounted
const Flight=preload("res://scripts/flight.gd")
const Travel=preload("res://scripts/travel_rules.gd")
var game
var job: Dictionary={}
var return_mode: String="flight"
var status: String=""
var steering: bool=false
var waypoint: Vector2=Vector2.ZERO
var clock: float=0
var phase: String="buy"
var trade_cargo: int=0
var cycles: int=0
var fuel_stop: int=-1
func active() -> bool: return not job.is_empty()
func toggle() -> void:
	if active(): cancel("Canceled by pilot.");return
	if game.mode=="autopilot": game.set_mode(return_mode);return
	if game.mode not in ["flight","dock","pause","info","map"]: game.notify("Return to flight or port to choose an autopilot route.");return
	if game.hyperdrive.active() or not game.chain_route.is_empty(): game.notify("Finish or cancel the current jump first.");return
	return_mode=game.map_return_mode if game.mode=="map" else game.mode
	if return_mode=="missions": return_mode=game.missions.return_mode
	game.set_mode("autopilot")
func path(origin: int,target: int) -> Array:
	if origin==target: return []
	var queue: Array=[origin];var previous: Dictionary={origin:-1}
	while not queue.is_empty():
		var here: int=queue.pop_front()
		for neighbor in game.catalog.system(here).get("links",[]):
			if previous.has(int(neighbor)): continue
			previous[int(neighbor)]=here
			if int(neighbor)==target:
				var route: Array=[];var cursor: int=target
				while cursor!=origin: route.push_front(cursor);cursor=int(previous[cursor])
				return route
			queue.append(int(neighbor))
	return []
func mission_options() -> Array:
	var result: Array=[]
	if not game.pilot.mission.is_empty(): result.append({"kind":"mission","courier":true,"id":-1,"name":"Courier delivery"})
	for m in game.pilot.campaign.active:
		var port: int=mission_port(m)
		if port>=0 and game.missions.ship_goal_done(m): result.append({"kind":"mission","courier":false,"id":int(m.id),"name":game.missions.title(m)})
	return result
func mission_port(m: Dictionary) -> int:
	return int(m.dest) if not m.travel_done or int(m.back)<0 else int(m.back)
func trade_routes() -> Array:
	var result: Array=[];var known: Array=game.pilot.visited+game.pilot.surveyed+[game.pilot.system_id]
	for system in game.catalog.data.systems.values():
		if int(system.id) not in known: continue
		for next in system.links:
			if int(next) not in known: continue
			for low in system.objects:
				if not trading_port(int(low)): continue
				for high in game.catalog.system(int(next)).objects:
					if not trading_port(int(high)): continue
					for good in 6:
						if game.catalog.commodity_band(int(low),good)!=1 or game.catalog.commodity_band(int(high),good)!=4: continue
						var buy: int=int(game.world_activity.prices(int(low))[good]);var sell: int=int(game.world_activity.prices(int(high))[good])
						if sell<=buy or buy<0: continue
						result.append({"kind":"trade","low":int(low),"high":int(high),"good":good,"buy":buy,"sell":sell,"margin":sell-buy,"name":game.catalog.data.commodities[good].name})
	result.sort_custom(func(a,b):return a.margin>b.margin if a.margin!=b.margin else a.low<b.low)
	return result
func trading_port(port: int) -> bool:
	var obj: Dictionary=game.catalog.record("objects",port)
	return not obj.is_empty() and int(obj.fields.Flags)&1 and int(obj.fields.Flags)&2 and not int(obj.fields.Flags)&32 and not game.world_killer.destroyed(port) and game.world_activity.landing_reason(port).is_empty()
func mission_target(option: Dictionary) -> int:
	if option.get("courier",false): return int(game.pilot.mission.get("object",-1))
	for m in game.pilot.campaign.active:
		if int(m.id)==int(option.id): return mission_port(m) if game.missions.ship_goal_done(m) else -1
	return -1
func start(option: Dictionary) -> bool:
	if game.mode!="autopilot" or option.is_empty(): return false
	var trusted: Dictionary={}
	var options: Array=mission_options() if option.get("kind","")=="mission" else trade_routes()
	for candidate in options:
		if candidate==option: trusted=candidate;break
	if trusted.is_empty(): game.notify("That autopilot option is no longer available.");return false
	job=trusted.duplicate(true);clock=0;phase="buy";trade_cargo=0;cycles=0;fuel_stop=-1;steering=false
	if job.kind=="trade":
		trade_cargo=game.fleet_service.commodity_count(int(job.good))
		if trade_cargo>0: phase="sell"
	game.auto_landing=false;game.map_route.clear();game.hud.port_page="landing"
	game.set_mode("dock" if return_mode=="dock" else "flight")
	status="Starting "+str(job.name);game.notify("Autopilot: "+status+" · A cancels.");return true
func cancel(reason: String="",announce: bool=true) -> void:
	if not active(): return
	job={};steering=false;fuel_stop=-1;clock=0;game.auto_landing=false
	game.map_route.clear()
	if game.hyperdrive.active() or not game.chain_route.is_empty(): game.cancel_jump(false)
	status=reason
	if announce: game.notify("Autopilot stopped: "+reason)
func target_port() -> int:
	if job.kind=="trade": return int(job.low if phase=="buy" else job.high)
	return mission_target(job)
func fuel_port(system: int) -> int:
	for port in game.catalog.system(system).get("objects",[]):
		var obj: Dictionary=game.catalog.record("objects",int(port))
		if not game.world_killer.destroyed(int(port)) and int(obj.fields.Flags)&1 and not int(obj.fields.Flags)&32 and game.world_activity.landing_reason(int(port)).is_empty(): return int(port)
	return -1
func fuel_needed(route: Array) -> float:
	var hops: int=0
	for system in route:
		hops+=1
		if fuel_port(int(system))>=0: break
	return hops*100.0
func tick(dt: float) -> void:
	if not active(): return
	if game.mode in ["dead","title","ejecting","rescue"]: cancel("Flight ended.",false);return
	if game.mode=="mission_report": status="Waiting for mission report · Okay resumes autopilot";return
	if game.mode not in ["flight","dock"]: return
	clock-=dt
	if clock>0: return
	clock=.3
	if game.hyperdrive.active() or not game.chain_route.is_empty(): steering=false;status="Jumping · "+game.hyperdrive.status();return
	var target: int=target_port()
	if target<0:
		var complete: bool=job.get("courier",false) and game.pilot.mission.is_empty() or int(job.get("id",-1)) in game.pilot.campaign.completed
		cancel("Mission complete." if complete else "Mission changed, ended, or requires manual combat/boarding.");return
	if game.world_killer.destroyed(target) or not game.world_activity.landing_reason(target).is_empty(): cancel("Destination is destroyed or landing is refused.");return
	var system: int=game.missions.system_of(target)
	var route: Array=path(game.pilot.system_id,system)
	if system!=game.pilot.system_id and route.is_empty(): cancel("No connected route to the destination.");return
	if game.mode=="dock":
		game.refuel()
		if game.docked_id==target:
			if job.kind=="trade": trade_at_port()
			else:
				game.missions.landed(target,true);game.pilot.deliver(target)
				game.missions.show_next_landing_report();game.save_game(false)
				if game.mode=="dock" and target_port()==target: cancel("Landing objective requires further manual action; check the journal.")
			return
		if not game.pilot.cheat_infinite_fuel and game.pilot.fuel<fuel_needed(route): cancel("Not enough fuel or credits to reach the next refueling stop.");return
		fuel_stop=-1;game.launch();return
	if system!=game.pilot.system_id:
		if not game.pilot.cheat_infinite_fuel and game.pilot.fuel<fuel_needed(route):
			fuel_stop=fuel_port(game.pilot.system_id)
			if fuel_stop<0: cancel("Insufficient fuel and no accessible refueling port here.");return
			approach_port(fuel_stop);return
		game.auto_landing=false
		game.destination=int(route[0])
		if not Travel.hyperspace_obstacle(game.pilot.position,game.planets).is_empty():
			if not steering:
				var focus=Vector2.ZERO
				for body in game.planets: focus+=body.position
				focus/=maxi(1,game.planets.size())
				var radius: float=1000
				for body in game.planets: radius=maxf(radius,focus.distance_to(body.position)+body.radius+Travel.HYPERSPACE_CLEARANCE+400)
				var away: Vector2=(game.pilot.position-focus).normalized()
				if away.length()<.1: away=Vector2.DOWN
				waypoint=focus+away*radius
			steering=true;status="Departing gravity well · next "+game.catalog.system(int(route[0])).name;return
		steering=false;game.start_jump();return
	fuel_stop=-1;approach_port(target)
func approach_port(port: int) -> void:
	steering=false
	for body in game.planets:
		if int(body.id)!=port: continue
		game.landing_target=port
		if game.landing_clearance!=port: game.land()
		if game.mode=="flight" and game.landing_clearance==port: game.auto_landing=true
		status=("Refueling at " if port==fuel_stop else "Approaching ")+body.name
		return
	cancel("Destination is no longer present in this system.")
func helm(fields: Dictionary,dt: float) -> Dictionary:
	var offset: Vector2=waypoint-game.pilot.position
	var acceleration: float=maxf(1,Flight.acceleration(fields))
	var speed: float=minf(float(fields.Speed)*.65,sqrt(2*acceleration*offset.length())*.45)
	var correction: Vector2=offset.normalized()*speed-game.velocity
	var heading: float=Flight.facing(correction) if correction.length()>1 else game.pilot.heading
	var aligned: bool=absf(angle_difference(game.pilot.heading,heading))<.12
	return Flight.step(game.pilot.position,game.velocity,game.pilot.heading,Flight.steering(game.pilot.heading,heading,fields,dt),aligned and correction.length()>1,false,fields,dt,minf(1,correction.length()/(acceleration*dt)))
func trade_at_port() -> void:
	var good: int=int(job.good)
	var low: int=int(job.low);var high: int=int(job.high)
	if not trading_port(low) or not trading_port(high) or game.missions.system_of(high) not in game.catalog.system(game.missions.system_of(low)).links: cancel("Trading route is no longer accessible.");return
	var buy: int=int(game.world_activity.prices(low)[good]);var sell: int=int(game.world_activity.prices(high)[good])
	if game.catalog.commodity_band(low,good)!=1 or game.catalog.commodity_band(high,good)!=4 or sell<=buy: cancel("The low/high trading advantage has disappeared.");return
	if phase=="buy":
		trade_cargo=0
		var room: int=maxi(0,game.fleet_service.cargo_capacity()-game.fleet_service.total_cargo_used())
		var quantity: int=mini(room,maxi(0,int((game.pilot.credits-200)/maxi(1,buy))))
		if quantity*(sell-buy)<=200: cancel("Expected cargo profit would not cover the two jump refills.");return
		# Reserve two jump refills so the route cannot spend its fuel money on cargo.
		while game.pilot.credits-buy>=200 and game.fleet_service.trade(good,true,buy): trade_cargo+=1
		if trade_cargo==0: cancel("No cargo space or credits left after the fuel reserve.");return
		phase="sell";status="Bought %d t · heading to %s" % [trade_cargo,game.catalog.record("objects",high).name]
	else:
		var sold: int=0
		while sold<trade_cargo and game.fleet_service.trade(good,false,sell): sold+=1
		if sold<trade_cargo: cancel("Trading cargo was lost or removed.");return
		trade_cargo=0;phase="buy";cycles+=1;status="Trading loop %d complete · returning to buy low" % cycles
	game.notify("Autopilot: "+status);game.save_game(false)
	game.launch()
