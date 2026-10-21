extends RefCounted

# The manual establishes the interaction sequence. Distances, refuel prices and
# salvage risk remain remake tuning. Bribe formulas use recovered PPC evidence.
const Bribery=preload("res://scripts/bribery.gd")
const BOARD_SPEED: float = 25.0
const BOARD_ANGLE: float = PI / 6.0
const REFUEL_AMOUNT: float = 100.0
const MAX_CAPTURED_SHIPS: int = 8
var game
var contact: Dictionary = {}
var page: String = "channel"
var response: String = ""
var rng = RandomNumberGenerator.new()

func reset() -> void:
	game.persons.offered={}
	contact = {}
	page = "channel"
	response = ""

func live(npc: Dictionary) -> bool:
	return not npc.is_empty() and npc in game.npcs and is_instance_valid(npc.model) and npc.health > 0

func initialize_contact(npc: Dictionary, fields: Dictionary) -> void:
	npc.disabled = false
	npc.truce = false
	npc.boarded = false
	npc.plunder_count = 0
	npc.capture_attempted = false
	npc.refuel_order = {}
	npc.fuel = maxf(0, fields.Fuel)
	npc.credits = rng.randi_range(100, maxi(100, mini(8000, int(fields.Cost / 100)))) if fields.Crew > 0 else 0
	npc.cargo = [0, 0, 0, 0, 0, 0]
	if npc.ai <= 2 and fields.Holds > 0:
		npc.cargo[rng.randi_range(0, 5)] = rng.randi_range(1, maxi(1, int(fields.Holds * .6)))

func history(action: String,npc: Dictionary={}) -> void:
	var target: Dictionary=contact if npc.is_empty() else npc
	game.pilot.History.record(game.pilot,game.pilot.History.pilot_key(game.pilot,target),action)

func open_hail() -> void:
	if game.mode == "comms":
		close()
		return
	if game.mode != "flight": return
	if game.hyperdrive.active() or not game.chain_route.is_empty():
		game.notify("Cancel hyperspace with J before opening communications.")
		return
	contact = game.selected_contact()
	if not live(contact):
		game.notify("No ship selected. Press Tab, then Y to hail it.")
		return
	page = "channel"
	response = "Channel open."
	if contact.get("hector",false): response = game.Hector.REMINDER
	elif contact.get("maverick",false): response=game.traffic.maverick.quote(game.traffic.rng)
	elif not game.persons.quote(contact).is_empty(): response=game.persons.quote(contact)
	elif contact.disabled: response = "Our engines are down. We're dead in space."
	elif contact.hostile: response = "You've got our attention. Make it quick."
	elif contact.faction in [140, 150]: response = "Unintelligible transmission."
	var memory: String=game.pilot.History.recollection(game.pilot,game.pilot.History.pilot_key(game.pilot,contact))
	if not memory.is_empty() and not contact.get("hector",false) and contact.faction not in [140,150]: response+="\n\n"+memory
	history("hail");game.save_game(false)
	game.set_mode("comms")
	game.persons.on_contact(contact,false)

func close() -> void:
	reset()
	game.set_mode("flight")

func reply(text: String, next_page: String = "channel") -> void:
	response = text
	page = next_page
	game.hud.rebuild_modal()

func connected() -> bool:
	if game.mode != "comms": return false
	if live(contact): return true
	close()
	game.notify("Communication lost: that ship is no longer present.")
	return false

func greetings() -> void:
	if not connected(): return
	if contact.get("hector",false): reply(game.Hector.REMINDER)
	elif contact.get("maverick",false): reply(game.traffic.maverick.quote(game.traffic.rng))
	elif not game.persons.quote(contact).is_empty(): reply(game.persons.quote(contact))
	elif contact.disabled: reply("Engineering is offline. We cannot maneuver or fire.")
	elif contact.hostile: reply("Keep your distance. We aren't here to trade stories.")
	elif contact.get("freed",false): reply("Thank you for our freedom, captain. You will always have friends aboard this ship.")
	elif contact.ai >= 3:
		reply("We're on patrol in %s. Keep your weapons secured and fly safe." % game.catalog.system(game.pilot.system_id).name)
	else:
		reply("Good to see another pilot. We're making a run through %s. Safe travels." % game.catalog.system(game.pilot.system_id).name)

func refuel_price(npc: Dictionary) -> int:
	return 500 if npc.ai < 3 else 250

func assistance_reason(npc: Dictionary) -> String:
	if not live(npc): return "Contact lost."
	if npc.disabled: return "Our engines are disabled. We can't reach you."
	if npc.has("departure"): return "Our hyperdrive is engaged. We cannot rendezvous for a fuel transfer."
	if npc.hostile: return "We aren't helping an enemy."
	if not npc.refuel_order.is_empty(): return "We're already on our way. Hold position for fuel transfer."
	if game.pilot.cheat_infinite_fuel or game.pilot.fuel >= REFUEL_AMOUNT:
		return "You have enough fuel to jump. You don't need a rescue."
	if npc.fuel < REFUEL_AMOUNT * 2: return "We don't have enough fuel to spare."
	return ""

func request_assistance() -> void:
	if not connected(): return
	history("assistance_requested");game.save_game(false)
	var reason = assistance_reason(contact)
	if not reason.is_empty():
		reply(reason)
		return
	reply("We can bring you 100 fuel — enough for one jump — for %s credits. Payment is due on transfer. Stop your ship and we'll come alongside." % game.hud.commas(refuel_price(contact)), "refuel")

func accept_refuel() -> bool:
	if not connected() or page != "refuel": return false
	var reason = assistance_reason(contact)
	if not reason.is_empty():
		reply(reason)
		return false
	var price = refuel_price(contact)
	if game.pilot.credits < price:
		reply("You need %s credits for the transfer." % game.hud.commas(price), "refuel")
		return false
	contact.refuel_order = {"price": price, "time": 0.0}
	game.notify("%s is coming to refuel you. Stop and wait alongside." % contact.name)
	close()
	return true

# Voluntary engine repairs: the player brings their own ship alongside.
func offer_assistance() -> void:
	if not connected(): return
	if not contact.disabled:
		reply("Our engines are operational. Thank you for offering, captain.");return
	if contact.get("hector",false) or contact.faction in [140,150]:
		reply("There is no response to your offer of assistance.");return
	contact.rescue_order={"time":0.0}
	var ship: String=contact.name
	var distance: int=ceili(maxf(80,float(contact.radius)+30))
	close()
	game.notify("Assisting %s: approach within %d km and match speed for 3 seconds to repair their engines." % [ship,distance])

func update_rescue(npc: Dictionary,dt: float) -> void:
	if not npc.has("rescue_order"): return
	var nearby: bool=game.pilot.position.distance_to(npc.position)<=maxf(80,float(npc.radius)+30)
	var matched: bool=game.velocity.distance_to(npc.velocity)<=BOARD_SPEED
	if not nearby or not matched:
		npc.rescue_order.time=0.0;return
	npc.rescue_order.time+=dt
	if float(npc.rescue_order.time)<3.0: return
	game.Combat.sync(npc)
	var capacity: float=maxf(0,float(npc.max_health)-float(npc.shield_capacity))
	npc.armor=maxf(float(npc.armor),capacity*.75)
	npc.health=float(npc.shield)+float(npc.armor)
	npc.disabled=false;npc.erase("rescue_order");npc.behavior="Engines repaired"
	history("assisted",npc)
	game.save_game(false)
	game.notify("%s: Engines restored. Thank you for getting us moving again, captain!" % npc.name)

func bribe_terms(npc: Dictionary) -> Dictionary:
	if not npc.has("bribe_terms"):
		var flags: int=int(game.catalog.record("governments",int(npc.faction)).get("fields",{}).get("Flags",0))
		npc.bribe_terms={"price":Bribery.ship_quote(game.pilot.credits,flags,rng),"bargains":rng.randi_range(0,99)<=50,"negotiated":false}
	return npc.bribe_terms

func bribe_price(npc: Dictionary) -> int:
	return int(bribe_terms(npc).price)

func bribe_refusal(npc: Dictionary) -> String:
	if npc.get("hector",false) or npc.get("invulnerable",false): return "Your credits will not buy our silence."
	if npc.faction in [140,150]: return "There is no intelligible response to your offer."
	if npc.has("fleet_uid") or npc.get("player_ally",false): return "This ship is already part of your fleet."
	if npc.ai<3: return "No deal. We will not take your money."
	return ""

func negotiate_bribe() -> bool:
	if not connected() or page!="bribe": return false
	if contact.disabled or not contact.hostile or not bribe_refusal(contact).is_empty(): return false
	var terms: Dictionary=bribe_terms(contact)
	if terms.negotiated: return false
	terms.negotiated=true
	if terms.bargains:
		terms.price=Bribery.discount(int(terms.price))
		reply("All right. %s credits, and we'll leave you alone." % game.hud.commas(int(terms.price)),"bribe")
	else:
		terms.price=int(terms.price)+1000
		reply("No discount. The price is now %s credits. Pay it or leave." % game.hud.commas(int(terms.price)),"bribe")
	return bool(terms.bargains)

func offer_bribe() -> void:
	if not connected(): return
	history("bribe_offered");game.save_game(false)
	if contact.disabled:
		reply("Our weapons are offline. There is no need for a bribe.")
	elif not contact.hostile:
		reply("We have no quarrel with you. Keep your credits.")
	elif not bribe_refusal(contact).is_empty():
		reply(bribe_refusal(contact))
	else:
		reply("%s credits buys a ceasefire with this ship for this visit. It won't change your standing with our government. Fire on us again and the deal is off." % game.hud.commas(bribe_price(contact)), "bribe")

func pay_bribe() -> bool:
	if not connected() or page != "bribe": return false
	if contact.disabled or not contact.hostile or not bribe_refusal(contact).is_empty(): return false
	var price = bribe_price(contact)
	if game.pilot.credits < price:
		reply("You don't have enough credits. The price is %s." % game.hud.commas(price), "bribe")
		return false
	history("bribe_paid")
	game.pilot.credits -= price
	contact.truce = true
	contact.provoked = false
	contact.hostile = false
	# Recall this captain's attacks already in flight at the player, so paying
	# during a paused channel cannot immediately resume a lethal missile hit.
	for shot in game.shots.duplicate():
		if shot.enemy and shot.get("source", {}) == contact:
			shot.node.queue_free()
			game.shots.erase(shot)
	game.save_game(false)
	reply("Payment received. We'll leave you alone.")
	return true

func boarding_reason(npc: Dictionary) -> String:
	if npc.has("fleet_uid") or npc.get("player_ally",false): return "Use F to manage your own fleet."
	if not live(npc): return "No ship selected. Press Tab to select a disabled ship."
	if not npc.disabled: return "That ship is still operational. Disable it before boarding."
	var radius: float = maxf(25, npc.radius)
	if game.pilot.position.distance_to(npc.position) > radius:
		return "Move over the disabled ship (within %d km of its center)." % ceili(radius)
	if game.velocity.distance_to(npc.velocity) > BOARD_SPEED:
		return "Match its motion: relative speed must be 25 or less."
	if absf(angle_difference(game.pilot.heading, npc.heading)) > BOARD_ANGLE:
		return "Match its heading: point within 30° of the disabled ship's nose."
	return ""

func board() -> bool:
	if game.mode not in ["flight", "comms"]: return false
	if game.mode == "comms" and not connected(): return false
	if game.hyperdrive.active() or not game.chain_route.is_empty():
		game.notify("Cancel hyperspace with J before boarding.")
		return false
	var npc: Dictionary = contact if game.mode == "comms" else game.selected_contact()
	var reason = boarding_reason(npc)
	if not reason.is_empty():
		if game.mode == "comms": reply(reason)
		else: game.notify(reason)
		return false
	contact = npc
	history("boarded")
	if not npc.boarded:
		game.Factions.penalize(game.catalog, game.pilot, npc.faction, "BoardPenalty")
		npc.boarded = true
	game.missions.actor_event(npc,"board")
	game.save_game(false)
	var mission_report: String=game.missions.boarding_report(npc)
	response = mission_report if not mission_report.is_empty() else "Boarding party aboard. Choose what to transfer."
	game.sound("airlock")
	game.set_mode("boarding")
	game.persons.on_contact(contact,true)
	return true

func cargo_total(npc: Dictionary) -> int:
	var total: int = 0
	for value in npc.cargo: total += int(value)
	return total

func capture_chance(npc: Dictionary) -> float:
	if not live(npc): return 0.0
	var player_crew: float = maxf(1, float(game.catalog.field("ships", game.pilot.ship_id, "Crew")))
	var target_crew: float = maxf(1, float(game.catalog.field("ships", npc.id, "Crew")))
	return clampf(player_crew / (player_crew + target_crew), .10, .85)

func capture_reason(npc: Dictionary) -> String:
	var reason = boarding_reason(npc)
	if not reason.is_empty(): return reason
	if npc.has("fleet_uid"): return "This ship already belongs to your fleet."
	if npc.id == 191 or int(game.catalog.field("ships", npc.id, "Crew")) <= 0:
		return "That craft cannot be added to your fleet."
	if game.pilot.fleet.size() >= MAX_CAPTURED_SHIPS:
		return "Your fleet is at its eight-ship limit."
	if npc.capture_attempted:
		return "This crew has already resisted a capture attempt."
	return ""

func capture_ship() -> bool:
	if game.mode != "boarding": return false
	var reason = capture_reason(contact)
	if not reason.is_empty():
		response = reason
		game.hud.rebuild_modal()
		return false
	contact.capture_attempted = true
	var chance: float = capture_chance(contact)
	if rng.randf() > chance:
		game.arsenal.arm_resisting_ship(contact)
		response = "The crew resisted! Their ship is now selected as your one-shot weapon. Withdraw, choose another target with Tab, then press Space to launch the whole hull."
		game.hud.rebuild_modal()
		return false
	history("captured")
	var captured_id: int = contact.id
	var captured_name: String = contact.name
	var captured_position: Vector2 = contact.position
	var captured_heading: float = contact.heading
	var captured = contact
	var ammo: Array=[]
	for weapon in captured.weapons: ammo.append(int(weapon.ammo))
	# Prize crew repairs above the original armor-based disable boundary.
	var armor_capacity: float=maxf(0,captured.max_health-captured.shield_capacity)
	var operational: float=armor_capacity*.7 if armor_capacity>0 else captured.max_health*.2
	game.pilot.fleet.append({"id":captured_id,"health":maxf(captured.health,operational),"ammo":ammo,"cargo":captured.cargo.duplicate()})
	game.persons.captured(captured)
	game.world_activity.resolved(captured)
	game.traffic.retire(captured)
	game.arsenal.launch_captured_ship(captured_id, captured_position, captured_heading)
	close()
	game.save_game(false)
	game.notify("%s captured and added to your fleet." % captured_name)
	return true

# Transfer only finite rounds for installed launchers, within outfit/mass limits.
func ammunition_plan(npc: Dictionary) -> Array:
	var result: Array=[]
	var space: int=int(game.catalog.field("ships",game.pilot.ship_id,"FreeMass"))-game.outfitter.space_used()
	var planned: Dictionary={}
	for weapon in npc.get("weapons",[]):
		if int(weapon.ammo)<=0 or int(weapon.id) not in game.outfitter.weapon_ids(): continue
		var id: int=game.outfitter.ammo_id(int(weapon.id))
		if id<0: continue
		var f: Dictionary=game.catalog.record("outfits",id).fields
		var amount: int=mini(int(weapon.ammo),maxi(0,int(f.Max)-game.outfitter.count(id)-int(planned.get(id,0))))
		if int(f.Mass)>0: amount=mini(amount,maxi(0,space/int(f.Mass)))
		if amount<=0: continue
		space-=amount*int(f.Mass);planned[id]=int(planned.get(id,0))+amount
		result.append({"weapon":weapon,"outfit":id,"amount":amount})
	return result

func loot_reason(kind: String) -> String:
	if not live(contact): return "Contact lost."
	match kind:
		"credits": return "No credits remain." if contact.credits <= 0 else ""
		"cargo":
			if cargo_total(contact) == 0: return "The hold is empty."
			return "Your cargo hold is full." if game.fleet_service.total_cargo_used() >= game.fleet_service.cargo_capacity() else ""
		"ammo": return "No compatible rounds fit. Install a matching launcher and leave equipment space." if ammunition_plan(contact).is_empty() else ""
		"fuel":
			if contact.fuel <= 0: return "No fuel remains."
			return "Your fuel tank is full." if game.pilot.fuel >= game.pilot.fuel_capacity() else ""
	return "Unavailable transfer."

func plunder(kind: String) -> bool:
	if game.mode != "boarding": return false
	var reason = boarding_reason(contact)
	if not reason.is_empty():
		close()
		game.notify(reason)
		return false
	reason = loot_reason(kind)
	if not reason.is_empty():
		response = reason
		game.hud.rebuild_modal()
		return false
	match kind:
		"credits":
			response = "Transferred %s credits." % game.hud.commas(contact.credits)
			game.pilot.credits += contact.credits
			contact.credits = 0
		"fuel":
			var amount: float = minf(contact.fuel, game.pilot.fuel_capacity() - game.pilot.fuel)
			game.pilot.fuel += amount
			contact.fuel -= amount
			response = "Transferred %d fuel." % int(amount)
		"ammo":
			var moved: int=0
			for transfer in ammunition_plan(contact):
				transfer.weapon.ammo-=int(transfer.amount)
				var id: String=str(transfer.outfit)
				game.pilot.outfits[id]=game.pilot.outfit_count(int(transfer.outfit))+int(transfer.amount)
				moved+=int(transfer.amount)
			response="Transferred %d rounds of compatible ammunition." % moved
		"cargo":
			var moved: int = 0
			for i in contact.cargo.size():
				var amount: int = game.fleet_service.load_commodity(i,int(contact.cargo[i]))
				contact.cargo[i] -= amount
				moved += amount
			response = "Transferred %d tonnes of cargo." % moved
	history("plundered")
	contact.plunder_count += 1
	game.save_game(false)
	# As documented in the original manual, repeated plundering can trigger
	# self-destruction. The remake's probability is shown before each action.
	if rng.randf() < salvage_risk(contact.plunder_count - 1):
		var wreck = contact
		close()
		game.damage_npc(wreck, wreck.health + 1, wreck)
		game.damage_player(35)
		game.notify("The boarded ship self-destructed! Your boarding party withdrew under fire.")
	else:
		game.hud.rebuild_modal()
	return true

func salvage_risk(previous_actions: int) -> float:
	return minf(.30, .03 * (previous_actions + 1))

func disable(npc: Dictionary, player_attack: bool) -> void:
	game.missions.actor_event(npc,"disable")
	if npc.disabled: return
	npc.disabled = true
	npc.refuel_order = {}
	npc.behavior = "Disabled"
	game.Models.set_thrust(npc.model, 0, game.time)
	if player_attack: game.Factions.penalize(game.catalog, game.pilot, npc.faction, "DisabPenalty")
	game.notify("%s disabled. Match its position, heading and motion; B boards, Y hails." % npc.name)

func update_special(npc: Dictionary, dt: float) -> bool:
	if npc.disabled:
		update_rescue(npc,dt)
		# Disabled ships coast gently to a halt, retaining their heading.
		npc.velocity = npc.velocity.move_toward(Vector2.ZERO, 35 * dt)
		npc.position += npc.velocity * dt
		npc.behavior = "Disabled"
		pose(npc, 0)
		return true
	if npc.refuel_order.is_empty(): return false
	npc.refuel_order.time += dt
	if npc.hostile or npc.refuel_order.time > 90 or game.pilot.fuel >= REFUEL_AMOUNT or game.pilot.cheat_infinite_fuel:
		npc.refuel_order = {}
		game.notify("%s canceled the fuel rendezvous. No payment taken." % npc.name)
		return false
	var offset: Vector2 = game.pilot.position - npc.position
	var fields: Dictionary = game.catalog.record("ships", npc.id).fields
	var wanted: Vector2 = (game.velocity + offset * .8).limit_length(float(fields.Speed))
	if wanted.length() > 1:
		npc.heading = rotate_toward(npc.heading, game.Flight.facing(wanted), dt * fields.Maneuver * game.Flight.TURN_SCALE)
	npc.velocity = npc.velocity.move_toward(wanted, dt * game.Flight.acceleration(fields))
	npc.position += npc.velocity * dt
	npc.behavior = "Refueling rendezvous"
	pose(npc, .4)
	if offset.length() <= maxf(40, npc.radius) and game.velocity.distance_to(npc.velocity) <= BOARD_SPEED:
		var price: int = npc.refuel_order.price
		npc.refuel_order = {}
		if game.pilot.credits >= price and npc.fuel >= REFUEL_AMOUNT * 2:
			history("refueled",npc)
			game.pilot.credits -= price
			game.pilot.fuel += REFUEL_AMOUNT
			npc.fuel -= REFUEL_AMOUNT
			game.save_game(false)
			game.notify("%s transferred 100 fuel for %s credits. You're clear for one jump." % [npc.name, game.hud.commas(price)])
		else: game.notify("Fuel transfer canceled: insufficient credits or donor fuel. No payment taken.")
	return true

func pose(npc: Dictionary, thrust: float) -> void:
	npc.model.position = game.v3(npc.position)
	npc.model.rotation.y = -npc.heading
	game.Models.set_thrust(npc.model, thrust, game.time + npc.phase)
