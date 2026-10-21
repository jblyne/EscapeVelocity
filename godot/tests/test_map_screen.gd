extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
	else: print("PASS: "+message)
func _initialize() -> void: call_deferred("run")
func screen(): return game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
func capture(name: String) -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/map-"+name+".png"))
func key(code: int) -> void:
	var event=InputEventKey.new();event.physical_keycode=code;event.pressed=true
	screen()._unhandled_key_input(event)
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-map-screen-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game);game.set_physics_process(false);game.set_process(false)
	game.set_mode("flight");game.set_mode("map")
	await process_frame
	var market: Dictionary=screen().details().market
	check(not market.is_empty(),"Known current system shows commodity prices")
	var correct: bool=true
	for i in game.catalog.data.commodities.size():
		var good: String=game.catalog.data.commodities[i].name
		for quote in market.get(good,[]):
			if int(quote.price)!=int(game.world_activity.prices(int(quote.port))[i]): correct=false
	check(correct,"Map quotes match the actual exchange prices")
	var map=screen().chart
	map.rebuild_locations()
	check(game.map_selected==game.pilot.system_id,"Map opens with current system selected")
	check(map.locations[game.pilot.system_id].distance_to(map.size*.5)<.01,"Chart centers on current system")
	check(game.map_zoom==4.6,"Default zoom shows local neighborhood instead of fitting entire galaxy")
	check(screen().chart.size==Vector2(596,596),"Original square chart sits beside system details")
	for id in ["ZoomIn","ZoomOut","ClearRoute","MapDone"]: check(screen().find_child(id,true,false) is Button,"Original control available: "+id)
	var z: float=game.map_zoom
	screen().find_child("ZoomIn",true,false).pressed.emit();check(game.map_zoom>z,"Plus button zooms in")
	screen().find_child("ZoomOut",true,false).pressed.emit();check(absf(game.map_zoom-z)<.001,"Minus reverses zoom")
	var event=InputEventKey.new();event.physical_keycode=KEY_TAB;event.pressed=true
	root.push_input(event);await process_frame
	check(game.destination>=0 and game.map_selected==game.destination,"Real Tab input cycles chart destinations")
	var initial: Vector2=game.map_center
	var down=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=Vector2(1,1);map._gui_input(down)
	var motion=InputEventMouseMotion.new();motion.relative=Vector2(80,-45);map._gui_input(motion)
	check(game.map_center!=initial,"Dragging empty chart pans view")
	down.pressed=false;map._gui_input(down)
	event.physical_keycode=KEY_C;root.push_input(event);await process_frame
	check(game.map_center==initial and game.mode=="map","Real C input recenters without opening cheats")
	var neighbor: int=game.catalog.system(game.pilot.system_id).links[0]
	map.select_system(neighbor);check(game.destination==neighbor and game.map_selected==neighbor,"Adjacent selection sets next jump and details")
	# A remote accepted mission is visible even outside the explored neighborhood.
	var remote: int=200
	game.pilot.mission={"system":remote,"object":128,"reward":1200}
	check(game.missions.map_markers().has(remote),"Introductory courier has a red mission marker")
	check(remote in map.known_systems(),"Mission destination is included in known chart")
	map.rebuild_locations()
	var arrow: Dictionary=map.marker_geometry(remote)
	check(Rect2(Vector2.ZERO,map.size).has_point(arrow.tip),"Distant mission arrow stays visible at chart edge")
	var sample: Dictionary={}
	for record in game.catalog.data.missions.values():
		if not int(record.fields.Flags)&2:
			sample=game.missions.offer(int(record.id),128);break
	sample.dest=128;sample.travel_done=false;sample.ship_system=-1
	sample.deadline=int(game.pilot.campaign.day)+3
	game.pilot.campaign.active=[sample]
	var rush_system: int=game.missions.target_system(sample)
	check(game.missions.rush_markers()[rush_system].days==3,"Timed mission arrow reports remaining game days")
	check(map.rush_text(game.missions.rush_markers()[rush_system])=="RUSH · 3d","Rush label clearly names urgency and remaining time")
	var second: Dictionary=sample.duplicate(true);second.deadline=int(game.pilot.campaign.day)
	game.pilot.campaign.active.append(second)
	check(map.rush_text(game.missions.rush_markers()[rush_system])=="RUSH ×2 · TODAY","Shared destinations show rush count and earliest deadline")
	sample.deadline=-1;game.pilot.campaign.active=[sample]
	check(game.missions.rush_markers().is_empty(),"Untimed missions do not receive rush labels")
	game.pilot.campaign.active=[]
	var navigation: int=game.destination
	map.select_system(remote);check(game.map_selected==remote and game.destination==navigation,"Remote inspection preserves valid next jump")
	check(not screen().details().explored,"Unexplored mission target does not reveal services")
	check(screen().details().market.is_empty(),"Unexplored mission target does not leak commodity prices")
	game.map_route.clear();map.select_system(neighbor,true)
	var next: int=-1
	for id in game.catalog.system(neighbor).links:
		if id!=game.pilot.system_id: next=id;break
	game.plan_map_stop(next)
	check(game.map_route==[neighbor,next] and game.destination==neighbor,"Shift-click plans successive connected hops")
	game.plan_map_stop(220);check(game.map_route==[neighbor,next],"Disconnected route stop rejected")
	var origin: int=game.pilot.system_id;game.pilot.system_id=neighbor;game.finish_map_hop()
	check(game.map_route==[next] and game.destination==next,"Arrival selects planned next hop without automatically jumping")
	game.pilot.system_id=origin
	screen().find_child("ClearRoute",true,false).pressed.emit()
	check(game.map_route.is_empty() and game.destination==-1,"Clear Route clears plan and next jump")
	game.missions.selected=game.missions.offer(128,133)
	var entry: Dictionary=game.missions.selected
	game.missions.return_mode="dock";game.missions.channel=0;game.set_mode("missions")
	var nav_before: int=game.destination
	game.open_mission_map(entry,true);await process_frame
	check(game.map_preview_system==game.missions.target_system(entry),"Prospective mission gets green destination arrow")
	check(game.destination==nav_before,"Offer preview preserves navigation")
	check(game.map_return_mode=="missions","Mission map returns to briefing")
	screen().find_child("MapDone",true,false).pressed.emit()
	check(game.mode=="missions" and game.missions.selected==entry,"Done restores selected mission briefing")
	game.pilot.cheat_chain_jump=true;game.set_mode("map");await process_frame
	game.map_center=Vector2(game.catalog.system(origin).fields.xPos,game.catalog.system(origin).fields.yPos)
	game.pilot.visited=[128,129,136,137,165,164]
	screen().chart.queue_redraw()
	await capture("classic")
	game.open_mission_map(entry,true);await process_frame;await capture("offer")
	if "--visual" in OS.get_cmdline_user_args():
		DisplayServer.window_set_size(Vector2i(1000,650));await process_frame;await capture("small")
	var destroyed_before: Array=game.world_killer.state().destroyed.duplicate()
	game.world_killer.state().destroyed.append(193)
	game.map_selected=163;game.set_mode("map");await process_frame
	var chart=screen().chart
	check(chart.shattered_worlds(163)==["New Bavaria"],"shattered-system marker uses saved destroyed worlds")
	check(chart.shattered_worlds(128).is_empty(),"intact systems have no shattered marker")
	check(screen().details().shattered==["New Bavaria"],"system details name the shattered planet")
	game.pilot.cheat_chain_jump=false
	check(163 in chart.known_systems(),"known destruction remains visible without chart cheat")
	var f: Dictionary=game.catalog.system(163).fields
	game.map_center=Vector2(f.xPos,f.yPos);chart.queue_redraw();screen().refresh_details()
	await capture("shattered")
	game.world_killer.state().destroyed=destroyed_before
	# Exercise the actual player arrival rather than only queue bookkeeping.
	game.pilot.cheat_chain_jump=false;game.pilot.system_id=origin;game.load_system();game.set_mode("flight")
	game.map_route=[neighbor,next];game.destination=neighbor;game.pilot.fuel=game.pilot.fuel_capacity()
	game.pilot.position=Vector2(0,10000);game.velocity=Vector2.ZERO
	game.start_jump();check(game.hyperdrive.active(),"Planned route starts a normal fueled jump")
	for i in 12000:
		game._physics_process(1.0/60)
		if game.pilot.system_id!=origin: break
	check(game.pilot.system_id==neighbor and game.destination==next and game.map_route==[next],"Real arrival preserves route and sets next destination")
	check(not game.hyperdrive.active() and game.chain_route.is_empty(),"Planned route waits for player's next J press")
	print("MAP SCREEN: %d checks; %d failures" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
