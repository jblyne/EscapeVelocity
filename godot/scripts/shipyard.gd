extends RefCounted
var game
var selected: int=131

static func stock_outfits(catalog, ship: int) -> Dictionary:
	if ship==128: return {"128":1}
	var result: Dictionary={"157":1} if ship==900 else {}
	var f: Dictionary=catalog.record("ships",ship).fields
	for i in f.WeapType.size():
		var weapon: int=int(f.WeapType[i])
		if weapon<128 or f.WeapCount[i]<=0: continue
		for type in [1,3]:
			for outfit in catalog.data.outfits.values():
				if int(outfit.fields.ModType)!=type or int(outfit.fields.ModVal)!=weapon: continue
				var amount: int=int(f.WeapCount[i] if type==1 else maxf(0,f.AmmoLoad[i]))
				if amount>0: result[str(int(outfit.id))]=amount
				break
	return result

static func stock_mass(catalog, ship: int) -> int:
	var amount: int=0
	var stock: Dictionary=stock_outfits(catalog,ship)
	for id in stock: amount+=int(catalog.field("outfits",int(id),"Mass"))*int(stock[id])
	return amount

func ships() -> Array:
	var result: Array=[]
	for record in game.catalog.data.ships.values():
		if record.fields.TechLevel<9999 and record.fields.Cost>0: result.append(int(record.id))
	result.sort()
	return result

func trade_in() -> int:
	# Original 0x662d8: quarter hull value plus 95% of non-mission equipment.
	var value: int=int(int(game.catalog.field("ships",game.pilot.ship_id,"Cost"))*.25)
	for outfit in game.pilot.outfits:
		if int(game.catalog.field("outfits",int(outfit),"Flags"))&4: continue
		value+=int(int(game.pilot.outfits[outfit])*int(game.catalog.field("outfits",int(outfit),"Cost"))*.95)
	value+=int(game.pilot.lasers*int(game.catalog.field("outfits",128,"Cost"))*.95)
	var port: Dictionary=game.catalog.record("objects",game.docked_id)
	var tech: int=int(game.catalog.field("ships",game.pilot.ship_id,"TechLevel"))
	var port_tech: int=int(port.fields.TechLevel) if not port.is_empty() else tech
	# Both calls are present in the original shipyard (0x45b38, 0x45b84).
	for step in 2: value=game.catalog.technology_price(value,tech,port_tech)
	return value

func price(id: int) -> int:
	return maxi(0,game.catalog.equipment_price("ships",id,game.docked_id)-trade_in())

func reason(id: int) -> String:
	if game.mode!="shipyard" or id not in ships(): return "Visit a shipyard."
	var port: Dictionary=game.catalog.record("objects",game.docked_id)
	if port.is_empty() or not int(port.fields.Flags)&8: return "No shipyard at this port."
	var f: Dictionary=game.catalog.record("ships",id).fields
	if not game.missions.bit_matches(int(f.MissionBit)): return "Requires mission clearance."
	if f.TechLevel>port.fields.TechLevel and int(f.TechLevel) not in [int(port.fields.SpecialTech1),int(port.fields.SpecialTech2),int(port.fields.SpecialTech3)]: return "Not built at this shipyard."
	if id==game.pilot.ship_id: return "You already fly this ship."
	if game.pilot.cargo_used()>f.Holds: return "Unload cargo or finish cargo missions first."
	if game.pilot.credits<price(id): return "Insufficient credits."
	return ""

func buy(id: int) -> bool:
	if not reason(id).is_empty(): return false
	game.pilot.credits-=price(id)
	var retained: Dictionary={}
	for outfit in game.pilot.outfits:
		if int(game.catalog.field("outfits",int(outfit),"Flags"))&4: retained[outfit]=game.pilot.outfits[outfit]
	if id==900: game.pilot.maverick_afterburner_granted=true
	game.pilot.ship_id=id
	game.pilot.ship_fields=game.catalog.record("ships",id).fields.duplicate(true)
	game.pilot.outfits=stock_outfits(game.catalog,id)
	game.pilot.lasers=int(game.pilot.outfits.get("128",0));game.pilot.outfits.erase("128")
	game.pilot.outfits.merge(retained,true)
	game.pilot.shield=game.pilot.max_shield();game.pilot.armor=game.pilot.max_armor();game.pilot.fuel=game.pilot.fuel_capacity()
	game.fleet_service.sync()
	var port: int=game.docked_id
	game.load_system();game.docked_id=port
	game.arsenal.available_ids()
	game.notify("New ship commissioned: "+game.catalog.record("ships",id).name)
	game.save_game(false);game.hud.rebuild_modal()
	return true
