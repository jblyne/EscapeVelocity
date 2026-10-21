extends SceneTree

const Travel = preload("res://scripts/travel_rules.gd")
const Flight = preload("res://scripts/flight.gd")
var game
var count: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	count += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func prepare(target: int, position: Vector2) -> void:
	game.pilot.system_id = 129
	game.pilot.position = position
	game.pilot.fuel = 1000
	game.load_system()
	game.select_destination(target)
	var source: Dictionary = game.catalog.system(129).fields
	var destination: Dictionary = game.catalog.system(target).fields
	game.pilot.heading = Flight.facing(Vector2(destination.xPos-source.xPos, destination.yPos-source.yPos))

func departure(target: int, fps: int, position: Vector2, label: String) -> void:
	prepare(target, position)
	game.start_jump()
	check(game.hyperdrive.active(), label + ": starts outside all exclusion zones")
	var crossed_zone: bool = false
	for frame in fps * 20:
		var phase: String = game.hyperdrive.phase
		game._physics_process(1.0 / fps)
		if phase == "accelerating" and game.pilot.system_id == 129:
			crossed_zone = crossed_zone or not Travel.hyperspace_obstacle(game.pilot.position, game.planets).is_empty()
		if not game.hyperdrive.active(): break
	if game.pilot.system_id == 129:
		print("Departure stopped at %s; latest message: %s" % [game.pilot.position, game.messages[0]])
	check(crossed_zone and game.pilot.system_id == target, label + ": crosses the gravity zone during the burn and reaches its destination")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(game.save_path)) if FileAccess.file_exists(game.save_path) else {}
	check(game.pilot.system_id == target and game.pilot.fuel == 900 and absf(game.velocity.length()-float(game.pilot.flight_fields(game.catalog.record("ships",game.pilot.ship_id).fields).Speed))<.01 and game.destination == -1 and int(saved.get("system_id", -1)) == target and saved.get("fuel", -1) == 900,
		label + ": arrives at cruise speed, spends fuel once, clears the route, and saves the destination")

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/test-hyperspace-departure-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted = true
	game.traffic.enabled = false # Isolate this feature from independently tested ambient traffic.
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	# The reported pilot was west of Sol, facing the Eridani connection.
	departure(132, 60, Vector2(-1775.78515625, -371.617431640625), "Sol to Eridani regression")
	await process_frame
	for fps in [30, 60, 120]:
		for target in game.catalog.system(129).links:
			var source: Dictionary = game.catalog.system(129).fields
			var destination: Dictionary = game.catalog.system(target).fields
			var direction = Vector2(destination.xPos-source.xPos, destination.yPos-source.yPos).normalized()
			departure(target, fps, -direction * 900, "Sol to %s at %d Hz" % [game.catalog.system(target).name, fps])
			await process_frame
	# Enter Earth's exclusion zone near the end of the burn, including its final tick.
	var eridani_direction = Vector2(39,11).normalized()
	departure(132, 60, -eridani_direction * 4000, "Late-burn gravity crossing")
	await process_frame
	# Clearance is still mandatory until acceleration actually starts.
	prepare(132, Vector2.ZERO)
	game.start_jump()
	check(not game.hyperdrive.active() and game.pilot.system_id == 129 and game.pilot.fuel == 1000,
		"starting inside Earth's exclusion zone is still blocked without fuel loss")
	for stage in ["stopping", "aligning", "spooling"]:
		prepare(132, Vector2(-1800, 0))
		game.start_jump()
		for frame in 120:
			if game.hyperdrive.phase == stage: break
			game._physics_process(1.0 / 60)
		check(game.hyperdrive.phase == stage, "clear departure reaches " + stage)
		game.pilot.position = Vector2.ZERO
		# Exercise the spooling → acceleration boundary too.
		if stage == "spooling": game.hyperdrive.remaining = 1.0 / 120
		game._physics_process(1.0 / 60)
		check(not game.hyperdrive.active() and game.pilot.system_id == 129 and game.pilot.fuel == 1000,
			"lost clearance during %s cancels before the burn, without fuel loss" % stage)
		await process_frame
	game.free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://../builds/test-hyperspace-departure-pilot.json"))
	print("HYPERSPACE DEPARTURE RESULT: %d checks; %d failures" % [count, failures])
	quit(1 if failures else 0)
