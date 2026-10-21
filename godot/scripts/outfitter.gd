extends RefCounted
var game
var visit_counts: Dictionary={}
const SUPPORTED = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21]

func begin_visit() -> void:
	visit_counts.clear()
	for id in stock(): visit_counts[id]=count(id)

func price(id: int, buying: bool=true) -> int:
	var cost: int=game.catalog.equipment_price("outfits",id,game.docked_id)
	if not buying and count(id)<=int(visit_counts.get(id,count(id))): cost=int(cost*.8)
	return cost

func stock() -> Array:
	var result: Array = []
	for record in game.catalog.data.outfits.values():
		if int(record.fields.ModType) in SUPPORTED and record.fields.Cost > 0 and record.fields.Max > 0 and (record.fields.TechLevel < 9999 or int(record.id) in [166,167,173]):
			result.append(int(record.id))
	result.sort()
	return result

func count(id: int) -> int:
	return game.pilot.lasers if id == 128 else int(game.pilot.outfits.get(str(id),0))

func space_used() -> int:
	var total: int = game.pilot.lasers*5-game.shipyard.stock_mass(game.catalog,game.pilot.ship_id)
	for id in game.pilot.outfits:
		total += int(game.catalog.field("outfits",int(id),"Mass"))*int(game.pilot.outfits[id])
	return total

func available_here(id: int) -> bool:
	var port = game.catalog.record("objects",game.docked_id)
	if port.is_empty() or not int(port.fields.Flags)&4: return false
	var fields: Dictionary=game.catalog.record("outfits",id).fields
	if int(fields.MissionBit)>=0 and not game.missions.bit_matches(int(fields.MissionBit)): return false
	if id in [166,167,173]: return false
	var tech: int = int(fields.TechLevel)
	return tech <= int(port.fields.TechLevel) if tech < 100 else tech in [int(port.fields.SpecialTech1),int(port.fields.SpecialTech2),int(port.fields.SpecialTech3)]

func weapon_ids() -> Array:
	var result: Array = [128] if game.pilot.lasers>0 else []
	for id in game.pilot.outfits:
		var fields: Dictionary = game.catalog.record("outfits",int(id)).fields
		if int(fields.ModType) == 1 and int(fields.ModVal) not in result: result.append(int(fields.ModVal))
	return result

func ammo_id(weapon: int) -> int:
	for id in stock():
		var fields: Dictionary = game.catalog.record("outfits",id).fields
		if int(fields.ModType) == 3 and int(fields.ModVal) == weapon: return id
	return -1

func reason(id: int, buying: bool) -> String:
	if game.mode != "outfitter" or id not in stock(): return "Land and visit the outfitter."
	var f: Dictionary = game.catalog.record("outfits",id).fields
	if buying:
		if id in [166,167,173]: return "Granted by a special mission; not sold at ports."
		if int(f.MissionBit)>=0 and not game.missions.bit_matches(int(f.MissionBit)): return "Requires military mission clearance."
		if not available_here(id): return "Not stocked at this port's tech level."
		if id==165 and map_additions().is_empty(): return "Surrounding systems are already mapped."
		if id==180 and int(game.pilot.reputation.get("128",0))>=0: return "No Confederation criminal record to clear."
		if game.pilot.credits < price(id): return "Insufficient credits."
		if count(id) >= (int(game.catalog.field("ships",game.pilot.ship_id,"MaxGun")) if id == 128 else int(f.Max)): return "Installation limit reached."
		if space_used()+int(f.Mass) > int(game.catalog.field("ships",game.pilot.ship_id,"FreeMass")): return "Not enough equipment space."
		if int(f.ModType) == 3 and int(f.ModVal) not in weapon_ids(): return "Install the matching launcher first."
		if int(f.ModType) == 1:
			var guns: int = game.pilot.lasers
			var turrets: int = 0
			for owned in game.pilot.outfits:
				var other: Dictionary = game.catalog.record("outfits",int(owned)).fields
				if int(other.ModType) == 1:
					if int(other.Flags)&1: guns += int(game.pilot.outfits[owned])
					if int(other.Flags)&2: turrets += int(game.pilot.outfits[owned])
			if int(f.Flags)&1 and guns >= int(game.catalog.field("ships",game.pilot.ship_id,"MaxGun")): return "No free gun mounts."
			if int(f.Flags)&2 and turrets >= int(game.catalog.field("ships",game.pilot.ship_id,"MaxTur")): return "No free turret mounts."
	else:
		if int(f.Flags)&4: return "Mission equipment cannot be sold."
		if count(id) <= (1 if id == 128 and game.pilot.ship_id==128 else 0): return "No removable units installed."
		if space_used()-int(f.Mass) > int(game.catalog.field("ships",game.pilot.ship_id,"FreeMass")): return "Remove equipment before selling mass expansion."
		if int(f.ModType) == 1 and count(id) == 1:
			var ammo: int = ammo_id(int(f.ModVal))
			if ammo >= 0 and count(ammo) > 0: return "Sell the remaining ammunition first."
	var cargo_delta: int = int(f.ModVal)*(1 if buying else -1) if int(f.ModType) == 2 else 0
	if game.pilot.cargo_capacity()+cargo_delta < game.pilot.cargo_used(): return "Unload cargo before reducing hold space."
	return ""

func trade(id: int, buying: bool) -> bool:
	var blocked = reason(id,buying)
	if not blocked.is_empty():
		game.sound("ui_error")
		game.notify(blocked)
		return false
	var amount: int = 1 if buying else -1
	var cost: int=price(id,buying)
	if buying and id==165:
		game.pilot.surveyed.append_array(map_additions())
	elif buying and id==180:
		game.pilot.reputation["128"]=0
	elif id == 128: game.pilot.lasers += amount
	else:
		game.pilot.outfits[str(id)] = count(id)+amount
		if game.pilot.outfits[str(id)] == 0: game.pilot.outfits.erase(str(id))
	game.pilot.credits += -cost if buying else cost
	game.pilot.shield = minf(game.pilot.shield,game.pilot.max_shield())
	game.pilot.armor = minf(game.pilot.armor,game.pilot.max_armor())
	game.pilot.fuel = minf(game.pilot.fuel,game.pilot.fuel_capacity())
	game.arsenal.available_ids()
	game.sound("ui_confirm")
	game.save_game(false)
	game.hud.rebuild_modal()
	return true

func description(id: int) -> String:
	var f: Dictionary = game.catalog.record("outfits",id).fields
	match int(f.ModType):
		1: return game.arsenal.description(int(f.ModVal))
		2: return "%+d tonnes of cargo capacity." % int(f.ModVal)
		3: return "One shot for %s." % game.catalog.record("weapons",int(f.ModVal)).name
		4: return "+%d maximum shields." % int(f.ModVal)
		5: return "Faster shield regeneration."
		6: return "+%d maximum armor. Repair service fills the added capacity." % int(f.ModVal)
		7: return "+50% thrust."
		8: return "+50% cruise speed."
		9: return "Faster turning."
		10: return "Disrupts incoming missile guidance. Torpedoes are unaffected."
		11: return "Shift+X opens manual ejection. Abandon ship and cargo; rescue provides a replacement shuttle."
		20: return "Automatically ejects before a fatal explosion. Requires an installed escape pod."
		13: return "Radar blip sizes indicate ship mass."
		14: return "Radar colors distinguish hostile ships and worlds from friendly contacts."
		16: return "Updates your map with systems up to two jumps away. Consumed on purchase."
		19: return "Automatically purchases fuel when you land. Repairs remain a separate service."
		21: return "Clears your Confederation criminal record. Consumed on purchase; later crimes still count."
		12: return "+100 fuel capacity."
		15: return "Hold Shift while thrusting for a fuel-burning speed boost."
		17: return "K toggles cloaking. Conceals your ship from targeting and cargo scans, drains shields and fuel, and disables weapons unless the cloaking-device cheat is enabled."
		18: return "Slowly replenishes fuel during flight."
	return ""

func map_additions() -> Array:
	var found: Array=[game.pilot.system_id]
	var frontier: Array=found.duplicate()
	for step in int(game.catalog.field("outfits",165,"ModVal")):
		var next: Array=[]
		for system in frontier:
			for id in game.catalog.system(system).links:
				if id not in found: found.append(id);next.append(id)
		frontier=next
	return found.filter(func(id): return id not in game.pilot.visited and id not in game.pilot.surveyed)

func auto_refuel() -> int:
	if count(169)==0 or game.pilot.cheat_infinite_fuel: return 0
	var before: float=game.pilot.fuel
	var cost: int=game.refuel()
	if game.pilot.fuel>before: game.notify("Auto-refueller: fuel purchased · %d credits." % cost)
	return cost

func radar_size(ship: Dictionary) -> float:
	if count(155)==0: return 3.0
	var mass: float=game.catalog.field("ships",int(ship.id),"Mass")
	return clampf(2.0+sqrt(maxf(0,mass))*.2,3.0,9.0)

func radar_color(hostile: bool) -> Color:
	if count(156)==0: return Color("4caa35")
	return Color("ed4735") if hostile else Color("4caa35")
