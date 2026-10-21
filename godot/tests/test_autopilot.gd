extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if FileAccess.file_exists("/tmp/ev-autopilot-pilot.json"): DirAccess.remove_absolute("/tmp/ev-autopilot-pilot.json")
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-autopilot-pilot.json";game.controls.path="/tmp/ev-autopilot-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.set_mode("flight");game.pilot.credits=100000
	check(is_instance_valid(game.hud.autopilot_indicator) and not game.hud.autopilot_indicator.visible,"Autopilot indicator stays hidden when inactive")
	game.autopilot.toggle();check(game.mode=="autopilot","Autopilot opens its route and mission picker")
	check(game.autopilot.mission_options().is_empty(),"No inactive missions are advertised")
	game.autopilot.toggle();check(game.mode=="flight","Second press closes idle picker")
	var destination: Dictionary=game.courier_destination()
	game.pilot.accept_job(int(destination.system),int(destination.object),game.pilot.cargo_capacity())
	game.autopilot.toggle();var choice: Dictionary=game.autopilot.mission_options()[0]
	check(game.autopilot.start(choice),"Selecting an active courier engages autopilot")
	var jumped: bool=false;var old_system: int=game.pilot.system_id
	for frame in 60000:
		game._physics_process(1.0/30)
		if game.pilot.system_id!=old_system: jumped=true
		if not game.autopilot.active(): break
	check(jumped and game.pilot.system_id==int(destination.system),"Autopilot physically leaves gravity and hyperjumps to the mission system")
	check(game.mode=="dock" and game.docked_id==int(destination.object) and game.pilot.mission.is_empty(),"Autopilot flies, brakes and completes the courier at the correct world")
	check(is_equal_approx(game.pilot.fuel,game.pilot.fuel_capacity()),"Mission arrival refuels using normal port service")
	check(not game.autopilot.active(),"Completed mission stops autopilot")
	game.pilot.system_id=128;game.load_system();game.set_mode("flight")
	var story: Dictionary=game.missions.offer(130,128);game.pilot.campaign.active.append(story)
	game.autopilot.toggle();game.autopilot.start(game.autopilot.mission_options()[0])
	for frame in 60000:
		game._physics_process(1.0/30)
		if game.mode=="mission_report" or not game.autopilot.active(): break
	check(game.mode=="mission_report" and game.autopilot.active(),"Original mission completion report pauses automation for the player's Okay")
	game._physics_process(5)
	check(game.mode=="mission_report","Autopilot never skips story report text")
	if game.mode=="mission_report": game.missions.dismiss_landing_report()
	game.autopilot.tick(1)
	check(not game.autopilot.active() and 130 in game.pilot.campaign.completed,"Acknowledging the report completes the original mission route")
	# Discover the universe for this route-discovery fixture; no gameplay cheat is enabled.
	game.pilot.visited=game.catalog.data.systems.keys().map(func(id):return int(id))
	var routes: Array=game.autopilot.trade_routes()
	check(not routes.is_empty(),"Known adjacent low/high commodity pairs populate the picker")
	check(routes.all(func(r):return game.catalog.commodity_band(int(r.low),int(r.good))==1 and game.catalog.commodity_band(int(r.high),int(r.good))==4 and game.missions.system_of(int(r.high)) in game.catalog.system(game.missions.system_of(int(r.low))).links),"Every trading loop is low-to-high between directly adjacent systems")
	var luxury: Array=routes.filter(func(r):return int(r.good)==3)
	check(not luxury.is_empty(),"Luxury-goods low/high adjacent loops are available")
	var route: Dictionary=luxury[0] if not luxury.is_empty() else routes[0]
	game.pilot.system_id=game.missions.system_of(int(route.low));game.load_system();game.docked_id=int(route.low);game.set_mode("dock")
	game.pilot.credits=100000;game.pilot.fuel=game.pilot.fuel_capacity();game.pilot.cargo=[0,0,0,0,0,0];game.pilot.cargo[int(route.good)]=2
	var money: int=game.pilot.credits
	game.autopilot.toggle();check(game.autopilot.start(route),"Selecting a trading loop recognizes existing cargo")
	game.hud.refresh_autopilot_indicator()
	check(game.hud.autopilot_indicator.visible and game.catalog.record("objects",int(route.low)).name in game.hud.autopilot_route.text and game.catalog.record("objects",int(route.high)).name in game.hud.autopilot_route.text,"Active indicator names both trading stops")
	check(game.autopilot.phase=="sell" and game.autopilot.trade_cargo==2 and game.autopilot.target_port()==int(route.high),"Existing route goods go directly to the high-price stop first")
	var unrelated: int=(int(route.good)+1)%6;game.pilot.cargo[unrelated]=1
	for frame in 90000:
		game._physics_process(1.0/30)
		if game.autopilot.cycles>=1 or not game.autopilot.active(): break
	check(game.autopilot.cycles>=1 and game.autopilot.active(),"Trading autopilot completes a real buy, jump, landing and sale")
	check(game.pilot.credits>money,"One completed loop earns credits after fuel costs")
	check(game.fleet_service.commodity_count(int(route.good))==0,"Existing route goods are sold before buying more")
	check(game.fleet_service.commodity_count(unrelated)==1,"Unrelated cargo remains untouched")
	check(game.autopilot.phase=="buy" and game.autopilot.trade_cargo==0,"After selling, autopilot is set to return to the low-price port")
	for frame in 90000:
		game._physics_process(1.0/30)
		if game.autopilot.cycles>=2 or not game.autopilot.active(): break
	check(game.autopilot.cycles>=2,"Trading route repeats its return leg and another buy/sell cycle")
	game.autopilot.toggle()
	check(not game.autopilot.active() and not game.auto_landing and not game.hyperdrive.active(),"Autopilot button immediately cancels steering, landing and hyperspace")
	var credits: int=game.pilot.credits
	game.autopilot.tick(100)
	check(game.pilot.credits==credits,"Canceled automation cannot continue trading")
	game.autopilot.toggle();check(game.mode=="autopilot","Pressing again after cancellation reopens the picker")
	game.pilot.system_id=game.missions.system_of(int(route.low));game.load_system();game.docked_id=int(route.low);game.set_mode("dock")
	game.autopilot.toggle();game.autopilot.start(route)
	game.world_killer.state().destroyed.append(int(route.high));game.autopilot.tick(1)
	check(not game.autopilot.active(),"Destroyed destination stops a running trade route")
	game.world_killer.state().destroyed.erase(int(route.high))
	game.set_mode("flight");game.pilot.mission={"system":game.missions.system_of(int(route.high)),"object":int(route.high),"reward":1200};game.pilot.fuel=0;game.pilot.credits=0
	game.autopilot.toggle();game.autopilot.start(game.autopilot.mission_options()[0])
	game.set_mode("dock");game.autopilot.tick(1)
	check(not game.autopilot.active(),"Fuel shortage without enough credits stops automation instead of granting fuel")
	game.set_mode("flight");game.pilot.fuel=game.pilot.fuel_capacity();game.pilot.credits=10000;game.pilot.position=Vector2(20000,20000)
	game.autopilot.toggle();game.autopilot.start(game.autopilot.mission_options()[0]);game.autopilot.tick(1)
	check(game.hyperdrive.active(),"Autopilot starts normal hyperspace when clear and fueled")
	var event=InputEventKey.new();event.physical_keycode=KEY_A;event.pressed=true;game._unhandled_key_input(event)
	check(not game.autopilot.active() and not game.hyperdrive.active(),"A cancels an in-progress automated jump immediately")
	game._unhandled_key_input(event)
	check(game.mode=="autopilot","Next A opens route selection after cancellation")
	game.autopilot.start(game.autopilot.mission_options()[0])
	game.map_route=[int(route.high)]
	game.chain_route=[game.pilot.system_id]
	game.chain_timer=10
	var steer=InputEventKey.new();steer.physical_keycode=KEY_LEFT;steer.pressed=true
	Input.parse_input_event(steer);Input.flush_buffered_events()
	game._physics_process(.016)
	var release=steer.duplicate();release.pressed=false;Input.parse_input_event(release);Input.flush_buffered_events()
	game.hud.refresh_autopilot_indicator()
	check(not game.hud.autopilot_indicator.visible,"Manual control hides the autopilot indicator")
	check(not game.autopilot.active() and game.chain_route.is_empty() and game.map_route.is_empty(),"Manual steering cancels even during a chain hop and clears automated navigation")
	game._unhandled_key_input(event)
	check(game.mode=="autopilot","A reopens the picker after a manual steering interruption")
	check(game.autopilot.start(game.autopilot.mission_options()[0]),"A new mission run can start after manual interruption")
	game.autopilot.toggle()
	check(KEY_A not in game.controls.bindings.left and KEY_LEFT in game.controls.bindings.left,"Autopilot A does not double as left steering")
	game.pilot.visited=[game.pilot.system_id];game.pilot.surveyed=[]
	check(game.autopilot.trade_routes().is_empty(),"Undiscovered neighbors do not leak trade prices or routes")
	game.free();await process_frame
	print("AUTOPILOT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
