extends SceneTree
var game
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/test-release-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled = false
	game.muted = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.pilot.fleet = [{"id":130},{"id":130},{"id":131}]
	game.arsenal.restore_captured_fleet()
	var released: Dictionary = game.escorts[1]
	var hull = released.model
	game.toggle_fleet_menu()
	check(game.mode == "fleet", "fleet menu opens")
	var button = game.hud.modal_root.find_child("ReleaseShip1",true,false)
	check(button is Button, "each captured ship has a release button")
	if button is Button: button.pressed.emit()
	check(game.pilot.fleet.map(func(m):return int(m.id)) == [130,131] and game.escorts.size() == 2, "releases exactly one duplicate hull")
	var freed: Dictionary = released
	check(freed.model == hull and not freed.hostile and freed.truce, "actual hull becomes a friendly independent contact")
	check(not game.release_ship(released), "stale release cannot remove another ship")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	var restored = game.Pilot.new()
	check(restored.restore(saved,game.catalog) and restored.fleet.map(func(m):return int(m.id)) == game.pilot.fleet.map(func(m):return int(m.id)), "fleet removal persists in valid save")
	game.toggle_fleet_menu()
	var before: Vector2 = freed.position
	game.traffic.update(.1)
	check(not freed.hostile and not game.traffic.opponent(freed).get("player",false), "independent AI remains friendly")
	check(freed.position != before, "released ship resumes independent flight")
	game.target_index = game.npcs.find(freed)
	game.hud._process(0)
	check(game.hud.target_panel.contact_status.text == "FRIENDLY", "target panel identifies released friend")
	game.interactions.open_hail()
	game.interactions.greetings()
	check(game.interactions.response.contains("freedom"), "released captain acknowledges freedom")
	game.interactions.close()
	game.toggle_fleet_menu()
	while game.npcs.size() < game.traffic.MAX_CONTACTS:
		game.traffic.spawn(129,-1,1,Vector2(3000,3000))
	check(game.release_ship(game.escorts[0]) and game.pilot.fleet.size() == 1, "Release at full traffic detaches existing contact without spawning another")
	game.toggle_fleet_menu()
	game.load_system()
	check(game.escorts.size() == 1 and game.pilot.fleet.size() == 1, "released ship does not rejoin after a jump")
	game.toggle_fleet_menu()
	for escort in game.escorts.duplicate(): game.release_ship(escort)
	check(game.pilot.fleet.is_empty() and game.escorts.is_empty(), "all ships can be released safely")
	game.toggle_fleet_menu()
	check(game.mode == "flight", "fleet menu returns to flight")
	game.free()
	await process_frame
	print("RELEASE RESULT: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
