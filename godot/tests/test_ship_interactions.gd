extends SceneTree

var game
var checks: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func key(code: int, shift: bool = false) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.shift_pressed = shift
	game._unhandled_key_input(event)

func click(name: String) -> void:
	var node = game.hud.modal_root.find_child(name, true, false)
	check(node is Button and not node.disabled, "available UI action: " + name)
	if node is Button and not node.disabled: node.pressed.emit()

func pick(npc: Dictionary) -> void:
	game.target_index = game.npcs.find(npc)
	game.hud._process(0)

func safe_roll() -> void:
	for seed_value in 100:
		game.interactions.rng.seed = seed_value
		if game.interactions.rng.randf() > .9:
			game.interactions.rng.seed = seed_value
			return

func capture_screen(name: String) -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/comms-" + name + ".png"))
	var screen = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var inside = true
	for node in game.hud.modal_root.find_children("*", "Button", true, false):
		inside = inside and screen.encloses(node.get_global_rect())
	check(inside, "all modal buttons fit the window: " + name)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/test-communications-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled = false
	game.muted = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	var comm = game.interactions
	key(KEY_Y)
	check(game.mode == "flight" and game.messages[0].contains("No ship selected"), "Y without selection provides guidance")
	var npc = game.traffic.spawn(129, -1, 1, game.pilot.position + Vector2(200, -100))
	key(KEY_TAB)
	key(KEY_Y)
	check(game.mode == "comms" and comm.contact == npc, "Tab then Y opens the selected ship's channel")
	var position: Vector2 = game.pilot.position
	var npc_position: Vector2 = npc.position
	game._physics_process(5)
	check(game.pilot.position == position and npc.position == npc_position, "communications pauses flight and AI")
	key(KEY_TAB)
	check(game.selected_contact() == npc, "Tab cannot change the target behind a communication")
	click("Greetings")
	check(comm.response.contains("Safe travels"), "civilian greetings respond in the channel")
	click("RequestAssistance")
	check(comm.page == "channel" and comm.response.contains("enough fuel"), "assistance checks actual fuel need")
	await capture_screen("channel")
	click("AttemptBoard")
	check(game.mode == "comms" and comm.response.contains("operational"), "live ships refuse boarding with a reason")
	key(KEY_Y)
	check(game.mode == "flight" and comm.contact.is_empty(), "Y closes a channel and clears its contact")
	key(KEY_B)
	check(game.npcs.size() == 1 and game.messages[0].contains("operational"), "B attempts boarding instead of spawning an enemy")
	game.pilot.fuel = 0
	key(KEY_Y)
	click("RequestAssistance")
	check(comm.page == "refuel", "a friendly ship offers a paid rescue when stranded")
	await capture_screen("refuel")
	var credits: int = game.pilot.credits
	click("AcceptRefuel")
	check(game.mode == "flight" and not npc.refuel_order.is_empty() and game.pilot.credits == credits, "accepting sends a rescue without charging before arrival")
	for i in 1500:
		game.traffic.update(1.0 / 60)
		if npc.refuel_order.is_empty(): break
	check(game.pilot.fuel == 100 and game.pilot.credits == credits - 500 and npc.fuel == 200, "actual AI rendezvous transfers one jump of fuel and takes the quoted payment once")
	for i in 60: game.traffic.update(1.0 / 60)
	check(game.pilot.fuel == 100 and game.pilot.credits == credits - 500, "finished assistance cannot transfer or charge twice")
	game.pilot.fuel = 0
	key(KEY_Y); comm.request_assistance()
	game.pilot.credits = 0
	check(not comm.accept_refuel() and npc.refuel_order.is_empty(), "unaffordable rescue does not start or create debt")
	game.pilot.credits = credits
	comm.request_assistance(); comm.accept_refuel()
	npc.refuel_order.time = 91
	game.traffic.update(.01)
	check(npc.refuel_order.is_empty() and game.pilot.credits == credits and game.pilot.fuel == 0, "timed-out rendezvous cancels without charging")
	var pirate = game.traffic.spawn(131, 130, 3, game.pilot.position + Vector2(500, 200))
	game.arsenal.fire(128, pirate.position, pirate.heading, true, pirate, {"model":game.player_model, "position":game.pilot.position, "player":true})
	pick(pirate); key(KEY_Y)
	click("OfferBribe")
	check(comm.page == "bribe", "hostile captain quotes a bribe before money changes hands")
	var price: int = comm.bribe_price(pirate)
	var reputation: Dictionary = game.pilot.reputation.duplicate()
	click("PayBribe")
	check(game.shots.is_empty(), "ceasefire recalls that captain's attacks already in flight at the player")
	check(game.pilot.credits == credits - price and not pirate.hostile and pirate.truce and game.pilot.reputation == reputation, "bribe buys only this contact's ceasefire, preserving government reputation")
	check(not comm.pay_bribe() and game.pilot.credits == credits - price, "a paid quote cannot be submitted twice")
	key(KEY_ESCAPE)
	game.traffic.update(.1)
	check(not pirate.hostile, "faction AI respects the purchased ceasefire")
	game.damage_npc(pirate, 1)
	check(pirate.hostile and not pirate.truce, "firing on a bribed contact breaks the ceasefire")
	game.damage_npc(pirate, pirate.health - pirate.max_health * .1)
	check(pirate.disabled and pirate.health > 0, "nonlethal damage can disable an enemy without destroying it")
	game.hud._process(0)
	check(game.hud.target_panel.contact_status.text.contains("DISABLED"), "target panel distinguishes disabled contacts")
	game.arsenal.launch_escort(135, pirate.position + Vector2(0, 165), 0)
	game.escorts[0].cooldown = 0
	var before_escort_shots: int = game.shots.size()
	game.arsenal.update_escorts(.01)
	check(game.shots.size() == before_escort_shots, "debug escorts stop firing at the selected disabled ship so it can be boarded")
	game.arsenal.remove_cheat_weapons()
	var shot_count: int = game.shots.size()
	var heading: float = pirate.heading
	for i in 600: game.traffic.update(1.0 / 60)
	check(pirate.velocity == Vector2.ZERO and pirate.heading == heading and pirate.behavior == "Disabled" and game.shots.size() == shot_count, "disabled ships stop drifting, retain heading, and do not fire")
	game.pilot.position = pirate.position + Vector2(pirate.radius + 1, 0)
	game.velocity = Vector2.ZERO
	game.pilot.heading = pirate.heading
	key(KEY_B)
	check(game.mode == "flight" and game.messages[0].contains("Move over"), "boarding rejects a distant disabled target")
	game.pilot.position = pirate.position
	game.velocity = Vector2(26, 0)
	check(comm.boarding_reason(pirate).contains("relative speed"), "boarding rejects excessive relative speed")
	game.velocity = Vector2.ZERO
	game.pilot.heading = pirate.heading + PI
	check(comm.boarding_reason(pirate).contains("heading"), "boarding requires matching the target's heading")
	game.pilot.heading = pirate.heading
	pirate.credits = 777
	pirate.fuel = 200
	pirate.cargo = [7, 0, 9, 0, 0, 0]
	game.pilot.cargo = [0, 0, 0, 0, 0, 0]
	game.pilot.accept_job(129, 130, 20) # Protected 5-tonne mission allocation.
	var rep_before: int = game.pilot.reputation.get("130", 0)
	key(KEY_B)
	check(game.mode == "boarding" and pirate.boarded and game.pilot.reputation["130"] == rep_before - int(game.catalog.field("governments", 130, "BoardPenalty")), "boarding opens the plunder panel and applies the source government's penalty")
	await capture_screen("boarding")
	credits = game.pilot.credits
	safe_roll(); click("LootCredits")
	check(game.pilot.credits == credits + 777 and pirate.credits == 0, "credits move from target to pilot")
	check(not comm.plunder("credits") and game.pilot.credits == credits + 777, "empty credits cannot be plundered twice")
	safe_roll(); click("LootCargo")
	check(game.pilot.cargo_used() == 20 and comm.cargo_total(pirate) == 1 and game.pilot.mission.size() > 0, "cargo respects capacity and preserves mission cargo")
	check(not comm.plunder("cargo"), "full cargo prevents another transfer")
	game.pilot.fuel = game.Pilot.FUEL_CAPACITY - 50
	safe_roll(); click("LootFuel")
	check(game.pilot.fuel == game.Pilot.FUEL_CAPACITY and pirate.fuel == 150, "fuel transfer respects capacity and leaves the excess aboard")
	check(not comm.plunder("fuel") and pirate.plunder_count == 3, "failed transfers do not consume loot or advance self-destruct risk")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(saved.credits == game.pilot.credits and saved.fuel == game.pilot.fuel and saved.cargo.map(func(value): return int(value)) == game.pilot.cargo, "completed transfers are persisted in the pilot save")
	var restored = game.Pilot.new()
	check(restored.restore(saved, game.catalog), "boarding rewards still form a valid loadable pilot save")
	key(KEY_ESCAPE)
	rep_before = game.pilot.reputation["130"]
	key(KEY_B)
	check(game.pilot.reputation["130"] == rep_before, "reboarding the same wreck does not repeat the boarding penalty")
	key(KEY_ESCAPE)
	key(KEY_Y)
	game.traffic.retire(pirate)
	check(not comm.board() and game.mode == "flight", "stale boarding target cannot transfer into a different contact")
	comm.greetings()
	check(game.mode == "flight" and comm.contact.is_empty(), "lost communication closes safely")
	pick(npc); key(KEY_Y)
	game.load_system()
	check(game.mode == "flight" and comm.contact.is_empty(), "system load drops the dialog and stale contact references")
	var prize = game.traffic.spawn(130, 130, 1, game.pilot.position + Vector2(0, -180))
	game.damage_npc(prize, prize.health - prize.max_health * .1)
	game.pilot.position = prize.position
	game.pilot.heading = prize.heading
	game.velocity = prize.velocity
	pick(prize); key(KEY_B)
	var chance: float = comm.capture_chance(prize)
	for seed_value in 1000:
		comm.rng.seed = seed_value
		if comm.rng.randf() <= chance:
			comm.rng.seed = seed_value
			break
	click("CaptureShip")
	check(game.mode == "flight" and prize not in game.npcs and game.pilot.fleet.size()==1 and game.pilot.fleet[0].id==130, "a successful boarding capture removes the disabled contact and records its hull in the pilot fleet")
	check(game.escorts.size() == 1 and game.escorts[0].captured and game.escorts[0].id == 130, "a captured ship immediately becomes a flight escort")
	var follower_position: Vector2 = game.escorts[0].position
	game.pilot.position += Vector2(500, 0)
	for i in 120: game.traffic.update(1.0 / 60)
	check(game.escorts[0].position != follower_position, "captured ships fly after the player in formation")
	game.arsenal.remove_cheat_weapons()
	check(game.escorts.size() == 1 and game.escorts[0].captured, "turning off cheat weapons does not dismiss captured fleet ships")
	var fleet_save = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	var fleet_pilot = game.Pilot.new()
	check(fleet_pilot.restore(fleet_save, game.catalog) and fleet_pilot.fleet.size()==1 and fleet_pilot.fleet[0].id==130, "captured fleet membership survives a pilot save roundtrip")
	game.load_system(0.0)
	check(game.escorts.size() == 1 and game.escorts[0].captured and game.escorts[0].id == 130, "captured ships rejoin the player after a system transition")
	var resistor = game.traffic.spawn(130, 130, 1, game.pilot.position)
	game.damage_npc(resistor, resistor.health-resistor.max_health*.1)
	game.pilot.heading = resistor.heading
	game.velocity = Vector2.ZERO
	pick(resistor); key(KEY_B)
	safe_roll()
	check(not comm.capture_ship(), "resisted capture fails")
	var weapons: Array = game.arsenal.available_ids()
	var ram_id: int = weapons.back()
	check(ram_id >= 10000 and weapons.size() == 2, "resistance adds a hull weapon without cheats")
	check(not comm.capture_ship() and game.arsenal.available_ids().size() == 2, "repeat capture cannot duplicate hull ammunition")
	key(KEY_ESCAPE)
	check(game.pilot.selected_weapon == ram_id, "resisted ship is automatically selected and stays selected after withdrawing")
	check(not game.fire_player() and resistor in game.npcs, "launch refuses its own hull as target without consuming ammo")
	var victim = game.traffic.spawn(131, 130, 3, resistor.position+Vector2(600,0))
	pick(victim)
	check(game.fire_player() and resistor not in game.npcs, "launch moves actual resisting hull out of traffic")
	check(game.shots.back().node == resistor.model and ram_id not in game.arsenal.available_ids(), "hull is single-use and preserves actual ship model")
	game.arsenal.remove_cheat_weapons()
	check(game.shots.size() == 1, "cheat cleanup preserves launched hull")
	game.update_shots(1.0)
	check(victim not in game.npcs and game.shots.is_empty(), "swept collision destroys target and projectile even across a large frame step")
	check(game.explosions.size() >= 2 and game.explosions[-2].blast_scale >= 2.275, "impact includes an oversized hull explosion")
	var leftover = game.traffic.spawn(130, 130, 1, game.pilot.position)
	game.arsenal.arm_resisting_ship(leftover)
	game.select_weapon(game.arsenal.available_ids().back())
	game.traffic.retire(leftover)
	check(game.arsenal.available_ids() == [128] and game.pilot.selected_weapon == 128, "destroyed or retired ammunition clears selection safely")
	game.set_mode("pause"); key(KEY_Y); key(KEY_B)
	check(game.mode == "pause", "ship interaction shortcuts respect the pause screen")
	game.set_mode("flight")
	key(KEY_B, true)
	check(game.npcs.filter(func(n):return n.hostile).size()==1, "Shift+B preserves the combat drill")
	game.hyperdrive.phase = "accelerating"
	key(KEY_Y); key(KEY_B)
	check(game.mode == "flight" and comm.contact.is_empty(), "communications and boarding cannot interrupt an active jump")
	game.hyperdrive.reset()
	var doomed = game.traffic.spawn(130,130,1,game.pilot.position) # Armored hull; zero-armor drill fighters cannot be disabled.
	game.damage_npc(doomed, doomed.health-maxf(1,(doomed.max_health-doomed.shield_capacity)*.5))
	game.pilot.position = doomed.position
	game.pilot.heading = doomed.heading
	game.velocity = doomed.velocity
	doomed.credits = 1
	pick(doomed); key(KEY_B)
	for seed_value in 10000:
		comm.rng.seed = seed_value
		if comm.rng.randf() < .03:
			comm.rng.seed = seed_value
			break
	comm.plunder("credits")
	check(game.mode == "flight" and doomed not in game.npcs and game.explosions.size() > 0, "self-destruction ends boarding, removes the wreck and plays its explosion")
	await process_frame
	game.free()
	await process_frame
	print("COMMUNICATIONS RESULT: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
