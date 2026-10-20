extends SceneTree
var game
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/chain-"+name+".png"))
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-chain-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	var target: int = -1
	var route: Array = []
	for id in game.catalog.data.systems:
		var candidate: Array = game.route_to(int(id))
		if candidate.size()>route.size():
			route=candidate
			target=int(id)
	check(route.size()>2,"finds a multi-hop route")
	var previous: int=game.pilot.system_id
	var connected=true
	for id in route:
		connected=connected and id in game.catalog.system(previous).links
		previous=id
	check(connected and route.back()==target,"route follows actual links to selected final system")
	var old_destination: int=game.destination
	game.select_destination(target)
	check(game.destination==old_destination,"ordinary navigation rejects remote systems")
	game.toggle_cheat_menu()
	var toggle=game.hud.modal_root.find_child("ChainJumpToggle",true,false)
	check(toggle is CheckBox,"cheat menu exposes chain jump toggle")
	toggle.set_pressed(true)
	check(game.pilot.cheat_chain_jump,"toggle enables chain jumping")
	await capture("cheats")
	game.set_mode("map")
	game.select_destination(target)
	check(game.destination==target,"cheat selects remote destination")
	await capture("map")
	game.set_mode("flight")
	game.pilot.fuel=0
	game.pilot.position=game.planets[0].position
	game.pilot.fleet=[{"id":130}]
	check(game.jump_block_reason().is_empty(),"cheat bypasses fuel and gravity restrictions")
	game.velocity = Vector2(100,40)
	var departure_system: int = game.pilot.system_id
	game.start_jump()
	check(game.pilot.system_id==departure_system and game.hyperdrive.phase=="stopping","first hop starts full departure sequence")
	var phases: Array = []
	for i in 6000:
		if game.hyperdrive.phase not in phases: phases.append(game.hyperdrive.phase)
		game._physics_process(1.0/60.0)
		if game.pilot.system_id != departure_system: break
	check(["stopping","aligning","spooling","accelerating"].all(func(phase):return phase in phases),"initial jump stops, aligns, spools and accelerates")
	check(game.pilot.system_id==route[0] and game.chain_route.size()==route.size()-1,"full departure arrives at the first intermediate system")
	check(is_equal_approx(game.velocity.length(),275*game.Hyperspace.DEPARTURE_SPEED_MULTIPLIER) and game.previous_player_velocity==game.velocity,"chain arrival retains full departure speed and interpolation")
	game.hud._process(0)
	check(not game.hud.jump_button.disabled and game.hud.jump_button.text=="Cancel  J","HUD offers cancellation during chain")
	var flyby_start: Vector2 = game.pilot.position
	var flyby_velocity: Vector2 = game.velocity
	game._physics_process(.5)
	check(game.pilot.position.is_equal_approx(flyby_start+flyby_velocity*.5),"ship keeps moving through intermediate system")
	check(game.pilot.system_id==route[0],"intermediate system stays visible for one second")
	game.set_mode("pause")
	game._physics_process(5)
	check(game.chain_timer==.5,"pausing suspends chain countdown")
	game.set_mode("flight")
	game._physics_process(.5)
	check(game.pilot.system_id==route[1],"second hop happens after one second")
	check(not game.hyperdrive.active() and game.velocity.length()>0,"subsequent hops skip departure sequence and retain movement")
	check(is_equal_approx(game.velocity.length(),flyby_velocity.length()),"successive hop preserves hyperspace speed")
	var early_victim = game.traffic.spawn(130,128,1,game.pilot.position+game.velocity*.25)
	var early_safe = game.traffic.spawn(130,128,3,game.pilot.position+game.velocity*.25+game.velocity.normalized().orthogonal()*1000)
	early_safe.truce = true
	var wake_reputation: Dictionary = game.pilot.reputation.duplicate()
	game._physics_process(.5)
	check(game.pilot.reputation == wake_reputation and not early_victim.crime_reported,"hyperspace wake applies neither shooting nor killing reputation penalties")
	check(early_safe.truce and not early_safe.provoked,"hyperspace wake does not provoke surviving allied ships")
	check(early_victim not in game.npcs and early_safe in game.npcs and game.chain_stretch_strength()==0,"swept flyby wake destroys ships passed before jump stretch, not distant ships")
	game._physics_process(.25)
	check(game.chain_stretch_strength()==0,"quick stretch begins only in final quarter second")
	var nearby = game.traffic.spawn(130,-1,1,game.pilot.position+game.velocity*.125)
	var distant = game.traffic.spawn(130,-1,1,game.pilot.position+game.velocity*.125+game.velocity.normalized().orthogonal()*1000)
	game._physics_process(.125)
	check(nearby not in game.npcs and distant in game.npcs and game.explosions.size()>0,"jump wake explodes nearby ships while leaving distant ships alone")
	check(game.escorts.size()==1,"departure blast preserves player's captured fleet")
	game.update_player_render(1.0)
	game.update_jump_visuals(0)
	check(game.player_model.scale.z > game.player_base_scale.z*1.5 and game.space_material.get_shader_parameter("warp_stretch")>0,"quick departure visibly stretches ship and starfield")
	if "--visual" in OS.get_cmdline_user_args():
		game.camera.position = game.v3(game.pilot.position,1200)
		game.space_material.set_shader_parameter("drift",game.pilot.position)
		game.space_material.set_shader_parameter("ship_velocity",game.velocity)
		game.update_explosions(.05)
		game.hud._process(0)
	await capture("rapid-departure")
	game._physics_process(.125)
	check(game.pilot.system_id==route[2] and is_equal_approx(game.velocity.length(),flyby_velocity.length()),"rapid stretch ends in instant hop without slowing down")
	for i in range(3,route.size()): game._physics_process(1.0)
	check(game.pilot.system_id==target and game.chain_route.is_empty() and game.destination==-1,"chain stops at final destination")
	check(is_equal_approx(game.velocity.length(),float(game.pilot.flight_fields(game.catalog.record("ships",game.pilot.ship_id).fields).Speed)),"final chain arrival returns to normal cruise speed")
	check(game.previous_player_velocity == game.velocity and game.rendered_player_velocity == game.velocity,"final arrival interpolation also uses cruise speed")
	var approach_direction=Vector2(sin(game.pilot.heading),-cos(game.pilot.heading))
	if not game.planets.is_empty():
		var to_world: Vector2=game.planets[0].position-game.pilot.position
		check(to_world.dot(approach_direction)>float(game.planets[0].radius)+260,"final chain jump arrives before the planet along travel direction")
		var expected=game.Hyperspace.arrival(game.pilot.heading,game.catalog.record("ships",game.pilot.ship_id).fields,game.planets)
		check(game.pilot.position.is_equal_approx(expected.position),"chain jump preserves normal directional arrival point")
	var final_victim = game.traffic.spawn(130,-1,1,game.pilot.position+game.velocity*.01)
	game._physics_process(.01)
	check(final_victim in game.npcs,"final cruise-speed arrival no longer destroys nearby ships")
	game.velocity = Vector2.ZERO
	var slow_neighbor = game.traffic.spawn(130,-1,1,game.pilot.position+Vector2(100,0))
	game._physics_process(.01)
	check(slow_neighbor in game.npcs,"nearby ships survive at ordinary flight speed")
	game.velocity = flyby_velocity
	game.pilot.cheat_chain_jump = false
	game._physics_process(.01)
	check(slow_neighbor in game.npcs,"disabling chain cheat disables destructive wake")
	game.pilot.cheat_chain_jump = true

	check(game.pilot.fuel==0 and game.escorts.size()==1,"chain uses no fuel and preserves fleet")
	check(route.all(func(id):return id in game.pilot.visited),"all intermediate systems are visited")
	var restored=game.Pilot.new()
	var saved=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(restored.restore(saved,game.catalog) and restored.system_id==target and restored.cheat_chain_jump,"final position and toggle persist")
	game.select_destination(128)
	game.start_jump()
	game.start_jump()
	var stopped: int=game.pilot.system_id
	game._physics_process(2)
	check(game.chain_route.is_empty() and game.pilot.system_id==stopped,"J cancels at current system")
	game.select_destination(target)
	game.start_jump()
	game.set_chain_jump_cheat(false)
	check(game.chain_route.is_empty() and not game.pilot.cheat_chain_jump,"disabling cheat stops chain")
	game.set_chain_jump_cheat(true)
	game.select_destination(128)
	game.start_jump()
	game.load_system()
	check(game.chain_route.is_empty(),"loading a system clears transient chain state")
	game.free()
	await process_frame
	print("CHAIN RESULT: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
