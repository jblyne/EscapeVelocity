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
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_path = "/tmp/ev-launch-traffic-test.json"
	game.controls.path="/tmp/ev-launch-traffic-controls.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	var originals: Array = game.npcs.duplicate()
	check(not originals.is_empty(),"initial system has traffic")
	game.pilot.fleet = [{"id":130}]
	game.arsenal.restore_captured_fleet()
	var escort: Dictionary = game.escorts.back()
	var player = game.player_model
	var planet = game.planets[0].node
	game.target_index = 0
	game.arsenal.arm_resisting_ship(originals[0])
	game.arsenal.fire(128,game.pilot.position,0,true)
	game.burst(game.pilot.position,Color.WHITE,2)
	game.ship_explosion(originals[0].model,originals[0].position,Vector2.ZERO)
	game.pilot.position = game.planets[0].position
	game.velocity = Vector2.ZERO
	game.land()
	game.land()
	check(game.mode == "dock","land before refreshing traffic")
	var position: Vector2 = game.pilot.position
	var route: int = game.destination
	var credits: int = game.pilot.credits
	game.missions.scan_clock=4.9
	game.launch()
	check(game.missions.scan_clock==0,"launch resets the previous encounter's scan phase")
	var fresh = not game.npcs.is_empty()
	for npc in game.npcs: fresh = fresh and npc not in originals
	check(fresh,"launch replaces every old contact with fresh traffic")
	var ambient: Array=game.npcs.filter(func(n):return n.get("ambient",false) and not n.has("person_id") and not n.has("fleet_uid"))
	check(ambient.size() == clampi(int(game.catalog.system(game.pilot.system_id).fields.AvgShips),0,12),"new ambient traffic respects system density independently of persistent escorts and named characters")
	var valid = true
	var pool: Array = game.traffic.options(game.pilot.system_id)
	for npc in ambient:
		valid = valid and pool.any(func(option): return option.ship == npc.id and option.faction == npc.faction)
	check(valid,"replacement ships follow the current system encounter table")
	check(game.shots.is_empty() and game.sparks.is_empty() and game.explosions.is_empty(),"old combat does not resume after leaving port")
	check(game.target_index == -1 and game.arsenal.ship_weapons.is_empty() and game.pilot.selected_weapon == 128,"old targets and launchable hulls are cleared")
	check(escort in game.escorts and game.pilot.fleet.size()==1 and game.pilot.fleet[0].id==130 and int(escort.fleet_uid)==int(game.pilot.fleet[0].uid),"captured escort and persistent fleet identity survive docking")
	check(game.player_model == player and game.planets[0].node == planet and game.pilot.position == position and game.destination == route and game.pilot.credits == credits,"refresh preserves player location, route, world and credits")
	var current: Array = game.npcs.duplicate()
	game.launch()
	check(game.npcs == current,"launch outside a port cannot reroll traffic")
	game.land()
	game.land()
	game.launch()
	check(game.npcs.filter(func(npc):return not npc.has("fleet_uid")).all(func(npc):return npc not in current),"another landing refreshes contacts while retaining persistent escorts")
	game.free()
	await process_frame
	print("LAUNCH TRAFFIC RESULT: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
