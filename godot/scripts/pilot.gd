class_name EVPilot
extends RefCounted

const Shipyard = preload("res://scripts/shipyard.gd")
var ship_fields: Dictionary={"Holds":20,"Shield":180,"Armor":100,"Fuel":400}
const CampaignState = preload("res://scripts/campaign_state.gd")
const WorldKiller=preload("res://scripts/world_killer.gd")
var world_killer: Dictionary=WorldKiller.fresh()
const WorldState=preload("res://scripts/world_activity.gd")
var world_state: Dictionary=WorldState.fresh()
var persons: Dictionary={"gone":[],"grudges":[]}
var secrets: Dictionary={"forklift":false,"satellite":false}
var campaign: Dictionary = CampaignState.fresh()
const AchievementState=preload("res://scripts/achievements.gd")
var achievements: Dictionary=AchievementState.fresh()
const SAVE_VERSION = 1
const FUEL_CAPACITY: float = 400.0
const LEGACY_TEST_FUEL: float = 100000.0
var system_id: int = 128
var ship_id: int = 128
var pilot_name: String="Captain"
var strict: bool=false
var strict_dead: bool=false
var credits: int = 10000
var fuel: float = FUEL_CAPACITY
var shield: float = 180.0
var armor: float = 100.0
var lasers: int = 1
var cargo: Array = [0, 0, 0, 0, 0, 0]
var mission: Dictionary = {}
var visited: Array = [128]
var surveyed: Array = []
var position: Vector2 = Vector2(0, 330)
var heading: float = 0.0
var cheat_world_killer: bool = false
var cheat_cloak: bool = false
var cheat_all_weapons: bool = false
var cheat_infinite_fuel: bool = false
var cheat_chain_jump: bool = false
var cheat_invincibility: bool = false
var cheat_deflection: bool = false
var selected_weapon: int = 128
var reputation: Dictionary = {}
const History=preload("res://scripts/interaction_history.gd")
var interaction_history: Dictionary=History.fresh()
var local_records: Dictionary = {}
var fighter_sorties: Array=[]
var fleet: Array = []
var outfits: Dictionary = {}
var maverick_afterburner_granted: bool=false
var maverick_equipment_granted: bool=false

func outfit_count(id: int) -> int:
	return int(outfits.get(str(id),0))

func cargo_capacity() -> int:
	return int(ship_fields.Holds) + 10*outfit_count(135)-15*outfit_count(140)

func max_shield() -> float:
	var base: float=float(ship_fields.Shield)
	if base<0: base*=-5
	return base+15*outfit_count(145)

func max_armor() -> float:
	return float(ship_fields.Armor)+100*outfit_count(147)+250*outfit_count(148)+500*outfit_count(149)

func shield_recharge() -> float:
	return maxf(1,float(ship_fields.get("ShieldRe",36))-2*outfit_count(146))

func fuel_capacity() -> float:
	return float(ship_fields.get("Fuel",400))+100*outfit_count(153)

func flight_fields(base: Dictionary) -> Dictionary:
	var result = base.duplicate()
	if base.get("custom_flight",false):
		# Preserve the requested Maverick handling and upgrade behavior.
		if outfit_count(150): result.Accel *= 1.5
		if outfit_count(151): result.Speed *= 1.5
	else:
		# Original ModType 7/8 are additive, before the player's speed multiplier.
		result.Accel += 150*outfit_count(150)
		result.Speed = (float(result.Speed)+150*outfit_count(151))*preload("res://scripts/flight.gd").PLAYER_SPEED_MULTIPLIER
	result.Maneuver += outfit_count(152)
	return result


func cargo_used() -> int:
	var result: int = 0
	for n in cargo:
		result += int(n)
	for active in campaign.active:
		if not active.delivered: result+=int(active.qty)
	return result + (5 if not mission.is_empty() else 0)

func trade(index: int, buying: bool, price: int, capacity: int) -> bool:
	if index < 0 or index >= cargo.size() or price < 0:
		return false
	if buying:
		if credits < price or cargo_used() >= capacity:
			return false
		credits -= price
		cargo[index] += 1
	else:
		if cargo[index] <= 0:
			return false
		credits += price
		cargo[index] -= 1
	return true

func jump(destination: int, links: Array) -> bool:
	if destination not in links or (fuel < 100 and not cheat_infinite_fuel):
		return false
	if not cheat_infinite_fuel: fuel -= 100
	system_id = destination
	if destination not in visited:
		visited.append(destination)
	return true

func accept_job(destination_system: int, destination_object: int, capacity: int) -> bool:
	if not mission.is_empty() or cargo_used() + 5 > capacity:
		return false
	# This introductory contract is authored for the prototype, not an original campaign mission.
	mission = {"system": destination_system, "object": destination_object, "reward": 1200}
	return true

func deliver(object_id: int) -> int:
	if mission.is_empty() or int(mission.object) != object_id or int(mission.system) != system_id:
		return 0
	var reward: int = int(mission.reward)
	credits += reward
	achievements.courier_deliveries+=1
	achievements.contracts_completed+=1
	mission = {}
	return reward

func snapshot() -> Dictionary:
	return {"version": SAVE_VERSION, "fuel_rules":2, "system_id": system_id, "ship_id": ship_id,
		"maverick_equipment_granted":maverick_equipment_granted,"maverick_afterburner_granted":maverick_afterburner_granted,"pilot_name":pilot_name,"strict":strict,"strict_dead":strict_dead,"credits": credits, "fuel": fuel, "shield": shield, "armor": armor,
		"lasers": lasers, "cargo": cargo.duplicate(), "mission": mission.duplicate(),
		"visited": visited.duplicate(), "position": [position.x, position.y], "heading": heading,
		"cheats": {"world_killer":cheat_world_killer,"cloak": cheat_cloak, "chain_jump": cheat_chain_jump, "all_weapons": cheat_all_weapons, "infinite_fuel": cheat_infinite_fuel, "invincibility": cheat_invincibility, "deflection": cheat_deflection, "weapon": selected_weapon if selected_weapon < 10000 else 128},
		"achievements":achievements.duplicate(true), "interaction_history":interaction_history.duplicate(true), "world_killer":world_killer.duplicate(true), "local_records":local_records.duplicate(), "world":world_state.duplicate(true), "surveyed":surveyed.duplicate(), "persons":persons.duplicate(true), "secrets":secrets.duplicate(), "campaign": campaign.duplicate(true), "reputation": reputation.duplicate(), "fighter_sorties":fighter_sorties.duplicate(true), "fleet": fleet.duplicate(true), "outfits": outfits.duplicate()}

func restore(value: Variant, catalog: EVCatalog) -> bool:
	if not value is Dictionary:
		return false
	var saved_achievements=value.get("achievements",AchievementState.fresh())
	if not AchievementState.valid(saved_achievements): return false
	if not value.get("strict",false) is bool or not value.get("strict_dead",false) is bool or not value.get("pilot_name","Captain") is String: return false
	if value.get("strict_dead",false): return false
	if str(value.get("pilot_name","Captain")).length()>64: return false
	if value.has("fuel_rules") and value.fuel_rules!=2: return false
	var required = ["version", "system_id", "ship_id", "credits", "fuel", "shield", "armor", "lasers", "cargo", "mission", "visited", "position", "heading"]
	for key in required:
		if not value.has(key):
			return false
	for key in ["version", "system_id", "ship_id", "credits", "fuel", "shield", "armor", "lasers", "heading"]:
		if not (value[key] is int or value[key] is float) or not is_finite(float(value[key])):
			return false
	if int(value.version) != SAVE_VERSION or catalog.record("ships",int(value.ship_id)).is_empty() or int(value.ship_id)==191 or catalog.system(int(value.system_id)).is_empty():
		return false
	if not value.cargo is Array or value.cargo.size() != 6 or not value.position is Array or value.position.size() != 2:
		return false
	if not value.mission is Dictionary or not value.visited is Array:
		return false
	var used: int = 0
	for count in value.cargo:
		if not (count is float or count is int) or count < 0 or count != int(count):
			return false
		used += int(count)
	for coord in value.position:
		if not (coord is int or coord is float) or not is_finite(float(coord)) or abs(float(coord)) > 10000000:
			return false
	for id in value.visited:
		if not (id is int or id is float) or catalog.system(int(id)).is_empty():
			return false
	if not value.mission.is_empty():
		for key in ["system", "object", "reward"]:
			if not value.mission.has(key) or not (value.mission[key] is int or value.mission[key] is float):
				return false
		var dest = catalog.system(int(value.mission.system))
		if dest.is_empty() or int(value.mission.object) not in dest.objects or int(value.mission.reward) != 1200:
			return false
		used += 5
	var saved_campaign = value.get("campaign",CampaignState.fresh())
	if not CampaignState.valid(saved_campaign,catalog): return false
	for active in saved_campaign.active:
		if not active.delivered: used+=int(active.qty)
	var saved_outfits = value.get("outfits",{})
	if not saved_outfits is Dictionary: return false
	var candidate = get_script().new()
	candidate.ship_id=int(value.ship_id)
	candidate.ship_fields=catalog.record("ships",candidate.ship_id).fields.duplicate(true)
	var stock: Dictionary=Shipyard.stock_outfits(catalog,candidate.ship_id)
	for id in saved_outfits:
		if not id is String or not id.is_valid_int() or int(id) == 128: return false
		var record: Dictionary = catalog.record("outfits",int(id))
		var quantity = saved_outfits[id]
		if record.is_empty() or int(record.fields.ModType) not in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21]: return false
		if not (quantity is int or quantity is float) or not is_finite(float(quantity)) or quantity != int(quantity) or quantity <= 0 or quantity > maxi(int(record.fields.Max),int(stock.get(id,0))): return false
		candidate.outfits[id] = int(quantity)
	if not value.get("maverick_afterburner_granted",false) is bool: return false
	candidate.maverick_afterburner_granted=value.get("maverick_afterburner_granted",false)
	if candidate.ship_id==900 and not candidate.maverick_afterburner_granted:
		candidate.outfits["157"]=1;candidate.maverick_afterburner_granted=true
	if not value.get("maverick_equipment_granted",false) is bool: return false
	candidate.maverick_equipment_granted=value.get("maverick_equipment_granted",false)
	if candidate.ship_id==900 and not candidate.maverick_equipment_granted:
		candidate.outfits["149"]=1;candidate.outfits["156"]=1
		candidate.maverick_equipment_granted=true
	var mass: int = int(value.lasers)*5-Shipyard.stock_mass(catalog,candidate.ship_id)
	var guns: int = int(value.lasers)
	var turrets: int = 0
	for id in candidate.outfits:
		var f: Dictionary = catalog.record("outfits",int(id)).fields
		mass += int(f.Mass)*int(candidate.outfits[id])
		if int(f.ModType) == 1:
			if int(f.Flags)&1: guns += int(candidate.outfits[id])
			if int(f.Flags)&2: turrets += int(candidate.outfits[id])
	if mass > int(catalog.field("ships",candidate.ship_id,"FreeMass")) or guns > int(catalog.field("ships",candidate.ship_id,"MaxGun")) or turrets > int(catalog.field("ships",candidate.ship_id,"MaxTur")): return false
	if value.lasers != int(value.lasers): return false
	if used > candidate.cargo_capacity() or value.credits < 0 or value.fuel < 0 or value.fuel > (candidate.fuel_capacity() if value.get("fuel_rules",1)==2 else LEGACY_TEST_FUEL+100*candidate.outfit_count(153)) or value.shield < 0 or value.shield > candidate.max_shield() or (value.armor < 0 or (value.armor == 0 and (candidate.max_armor()>0 or value.shield<=0))) or value.armor > candidate.max_armor() or value.lasers < (1 if candidate.ship_id==128 else 0) or value.lasers > int(catalog.field("ships",candidate.ship_id,"MaxGun")):
		return false
	# Optional extension keeps existing version-1 pilots compatible; validate atomically.
	var cheats = value.get("cheats", {})
	if not cheats is Dictionary: return false
	if not cheats.get("world_killer",false) is bool: return false
	if not cheats.get("cloak",false) is bool: return false
	if not cheats.get("chain_jump",false) is bool: return false
	if not cheats.get("deflection",false) is bool: return false
	if not cheats.get("invincibility",false) is bool: return false
	if not cheats.get("all_weapons",false) is bool or not cheats.get("infinite_fuel",false) is bool: return false
	var weapon = cheats.get("weapon",128)
	if not (weapon is int or weapon is float) or not is_finite(float(weapon)) or weapon != int(weapon): return false
	if catalog.record("weapons",int(weapon)).is_empty(): return false
	var records = value.get("reputation", {})
	if not records is Dictionary: return false
	for id in records:
		if not id is String or not id.is_valid_int() or catalog.record("governments",int(id)).is_empty(): return false
		var score = records[id]
		if not (score is int or score is float) or not is_finite(float(score)) or score != int(score) or absf(score)>10000: return false
	var saved_sorties=value.get("fighter_sorties",[])
	if not preload("res://scripts/fighter_wing.gd").valid(saved_sorties,catalog,int(value.ship_id)): return false
	var saved_fleet = value.get("fleet", [])
	if not saved_fleet is Array or saved_fleet.size() > 8: return false
	for member in saved_fleet:
		if not member is Dictionary or not member.has("id"): return false
		for key in member:
			if key not in ["id","uid","hired","wage","paid_day","command","health","shield","armor","ammo","cargo","wings"]: return false
		if not member.get("hired",false) is bool or member.get("command","defend") not in ["defend","attack","hold","recall"]: return false
		for key in ["uid","wage","paid_day"]:
			if not CampaignState.integer(member.get(key,0),0,1000000000): return false
		if not CampaignState.integer(member.get("paid_day",0),0,int(saved_campaign.day)): return false
		if member.has("health") and (not (member.health is int or member.health is float) or not is_finite(member.health) or member.health<=0 or member.health>1000000): return false
		for key in ["shield","armor"]:
			if member.has(key) and (not (member[key] is int or member[key] is float) or not is_finite(member[key]) or member[key]<0 or member[key]>1000000): return false
		if member.has("shield") and member.has("armor") and not is_equal_approx(float(member.shield)+float(member.armor),float(member.get("health",-1))): return false
		if not member.get("ammo",[]) is Array or member.get("ammo",[]).size()>4: return false
		for ammo in member.get("ammo",[]):
			if not CampaignState.integer(ammo,-1,32767): return false
		if not (member.id is int or member.id is float) or member.id != int(member.id): return false
		if catalog.record("ships", int(member.id)).is_empty() or int(member.id) == 191: return false
		if not preload("res://scripts/fighter_wing.gd").valid(member.get("wings",[]),catalog,int(member.id),4): return false
		var freight = member.get("cargo",[0,0,0,0,0,0])
		if not freight is Array or freight.size()!=6: return false
		var freight_total: int=0
		for amount in freight:
			if not CampaignState.integer(amount,0,1000000): return false
			freight_total+=int(amount)
		if freight_total>int(catalog.field("ships",int(member.id),"Holds")): return false
	var saved_local=value.get("local_records",{})
	if not saved_local is Dictionary or saved_local.size()>catalog.data.systems.size(): return false
	for id in saved_local:
		if not id is String or not id.is_valid_int() or catalog.system(int(id)).is_empty() or not CampaignState.integer(saved_local[id],-10000,10000): return false
	var saved_world=value.get("world",WorldState.fresh(int(saved_campaign.day)))
	if not WorldState.valid(saved_world,catalog,int(saved_campaign.day)): return false
	var saved_surveyed=value.get("surveyed",[])
	if not saved_surveyed is Array or saved_surveyed.size()>catalog.data.systems.size(): return false
	for id in saved_surveyed:
		if not CampaignState.integer(id,128,32767) or catalog.system(int(id)).is_empty(): return false
	var saved_persons=value.get("persons",{"gone":[],"grudges":[]})
	if not saved_persons is Dictionary: return false
	for key in ["gone","grudges"]:
		if not saved_persons.get(key) is Array or saved_persons[key].size()>220: return false
		for id in saved_persons[key]:
			if not CampaignState.integer(id,128,639) or catalog.record("persons",int(id)).is_empty(): return false
	var saved_secrets=value.get("secrets",{"forklift":false})
	if not saved_secrets is Dictionary or not saved_secrets.get("forklift",false) is bool or not saved_secrets.get("satellite",false) is bool: return false
	var saved_history=value.get("interaction_history",History.fresh())
	if not History.valid(saved_history): return false
	var saved_killer=value.get("world_killer",WorldKiller.fresh())
	if not WorldKiller.valid(saved_killer,catalog): return false
	interaction_history=History.normalized(saved_history)
	world_killer=WorldKiller.normalized(saved_killer,catalog)
	local_records={}
	for id in saved_local: local_records[id]=int(saved_local[id])
	world_state=WorldState.normalized(saved_world)
	surveyed=[]
	for id in saved_surveyed:
		if int(id) not in surveyed: surveyed.append(int(id))
	persons={"gone":[],"grudges":[]}
	for key in persons:
		for id in saved_persons[key]:
			if int(id) not in persons[key]: persons[key].append(int(id))
	secrets={"forklift":saved_secrets.get("forklift",false),"satellite":saved_secrets.get("satellite",false)}
	ship_id=candidate.ship_id
	ship_fields=candidate.ship_fields
	campaign=CampaignState.normalized(saved_campaign)
	achievements=AchievementState.normalized(saved_achievements)
	system_id = int(value.system_id)
	credits = int(value.credits)
	fuel = minf(float(value.fuel),candidate.fuel_capacity())
	strict=bool(value.get("strict",false));strict_dead=false;pilot_name=str(value.get("pilot_name","Captain"))
	shield = float(value.shield)
	armor = float(value.armor)
	lasers = int(value.lasers)
	cargo = value.cargo.duplicate()
	mission = value.mission.duplicate()
	visited = []
	for id in value.visited:
		visited.append(int(id))
	position = Vector2(value.position[0], value.position[1])
	heading = float(value.heading)
	cheat_world_killer = cheats.get("world_killer",false)
	cheat_cloak = cheats.get("cloak",false)
	cheat_chain_jump = cheats.get("chain_jump",false)
	cheat_all_weapons = cheats.get("all_weapons",false)
	cheat_infinite_fuel = cheats.get("infinite_fuel",false)
	cheat_invincibility = cheats.get("invincibility",false)
	cheat_deflection = cheats.get("deflection",false)
	outfits = candidate.outfits.duplicate()
	maverick_afterburner_granted=candidate.maverick_afterburner_granted
	maverick_equipment_granted=candidate.maverick_equipment_granted
	selected_weapon = int(weapon)
	reputation = {}
	for id in records: reputation[id] = int(records[id])
	fighter_sorties=saved_sorties.duplicate(true)
	fleet = []
	for member in saved_fleet:
		var copy: Dictionary=member.duplicate(true);copy.id=int(copy.id);fleet.append(copy)
	return true
