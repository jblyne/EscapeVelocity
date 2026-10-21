class_name EVFactions
extends RefCounted

# Explicit Enemy/Ally links come from gövt. Player crime response is remake tuning;
# undocumented original flag bits are not guessed here.
static func name_of(catalog, id: int) -> String:
	return catalog.record("governments", id).get("name", "Independent")

static func color_of(id: int) -> Color:
	match id:
		128, 143, 145, 149: return Color("679fff")
		129, 144, 146, 153: return Color("e85c52")
		130: return Color("e3974c")
		131: return Color("a887ec")
		132: return Color("6ac5c6")
		133: return Color("74bb8c")
		135, 148: return Color("e6ba59")
		137, 152: return Color("ba9b77")
		138: return Color("71c6e4")
		139, 147: return Color("d388cf")
		140, 150: return Color("e24b64")
		142: return Color("a9c761")
	return Color("87a2ad")

static func allied(catalog, a: int, b: int) -> bool:
	if a < 0 or b < 0: return false
	if a == b: return true
	var ga = catalog.record("governments", a)
	var gb = catalog.record("governments", b)
	return (not ga.is_empty() and int(ga.fields.Ally) == b) or (not gb.is_empty() and int(gb.fields.Ally) == a)

static func enemies(catalog, a: int, b: int) -> bool:
	if a == b or allied(catalog, a, b): return false
	if a in [140,150] or b in [140,150]: return true
	var ga = catalog.record("governments", a)
	var gb = catalog.record("governments", b)
	return (not ga.is_empty() and int(ga.fields.Enemy) >= 0 and int(ga.fields.Enemy) == b) or (not gb.is_empty() and int(gb.fields.Enemy) >= 0 and int(gb.fields.Enemy) == a)

static func hostile_to_pilot(catalog, pilot, id: int) -> bool:
	if id in [130,140,143,146,147,148,150]: return true
	var faction = catalog.record("governments", id)
	if faction.is_empty(): return false
	return int(pilot.reputation.get(str(id), int(faction.fields.InitialRec))) < -maxi(10, int(faction.fields.CrimeTol))

static func penalize(catalog, pilot, faction_id: int, field: String) -> void:
	var faction = catalog.record("governments", faction_id)
	if faction.is_empty(): return
	var key = str(faction_id)
	pilot.reputation[key] = maxi(-10000, int(pilot.reputation.get(key, int(faction.fields.InitialRec))) - maxi(0, int(faction.fields[field])))

	if int(catalog.system(pilot.system_id).fields.Govt)==-1:
		var local=str(pilot.system_id)
		pilot.local_records[local]=maxi(-10000,int(pilot.local_records.get(local,0))-maxi(0,int(faction.fields[field])))

static func kill_goodwill(catalog,ship_id: int) -> int:
	var ship: Dictionary=catalog.record("ships",ship_id)
	if ship.is_empty() or ship_id==191: return 0
	return maxi(1,ceili(float(ship.fields.Mass)/10.0))

static func player_kill(catalog,pilot,faction_id: int,ship_id: int) -> void:
	penalize(catalog,pilot,faction_id,"KillPenalty")
	# Include the scenario's patrol/escort variants, but not Rebel-aligned
	# Confederate traitors or unrelated factions that share an enemy.
	var beneficiary: int=129 if faction_id in [128,143,145] else 128 if faction_id in [129,144,146,153] else -1
	if beneficiary<0: return
	var faction: Dictionary=catalog.record("governments",beneficiary)
	var key: String=str(beneficiary)
	pilot.reputation[key]=mini(10000,int(pilot.reputation.get(key,int(faction.fields.InitialRec)))+kill_goodwill(catalog,ship_id))
