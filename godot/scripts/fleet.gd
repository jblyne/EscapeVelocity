extends RefCounted
var game
var attack_target: Node3D
var takeover_candidate: Dictionary={}
const LIMIT=8
const ORDERS=["defend","attack","hold","recall"]

func prepare() -> void:
	var next: int=1
	for member in game.pilot.fleet: next=maxi(next,int(member.get("uid",0))+1)
	var used: Array=[]
	for member in game.pilot.fleet:
		if int(member.get("uid",0))<=0 or int(member.uid) in used: member.uid=next;next+=1
		used.append(int(member.uid))
		if not member.has("command"): member.command="defend"
		if member.get("hired",false): member.wage=wage(int(member.id))

func record(npc: Dictionary) -> Dictionary:
	for member in game.pilot.fleet:
		if int(member.get("uid",-2))==int(npc.get("fleet_uid",-1)): return member
	return {}

func spawn(member: Dictionary, pos: Vector2, heading: float) -> void:
	var npc: Dictionary=game.traffic.spawn(int(member.id),-1,3,pos)
	if npc.is_empty(): return
	npc.fleet_uid=int(member.uid);npc.captured=true;npc.name=game.catalog.record("ships",int(member.id)).name
	npc.truce=true;npc.hostile=false;npc.heading=heading;npc.model.rotation.y=-heading
	npc.health=minf(npc.max_health,float(member.get("health",npc.max_health)))
	if member.has("shield") and member.has("armor"):
		npc.shield=float(member.shield);npc.armor=float(member.armor)
	npc.disabled=game.Combat.is_disabled(npc)
	var ammo: Array=member.get("ammo",[])
	for i in mini(ammo.size(),npc.weapons.size()):
		if npc.weapons[i].ammo>=0: npc.weapons[i].ammo=mini(int(npc.weapons[i].ammo),maxi(0,int(ammo[i])))
	game.Combat.sync(npc)
	game.escorts.append(npc)

func spawn_last(_ship_id: int,pos: Vector2,heading: float) -> void:
	prepare()
	if not game.pilot.fleet.is_empty(): spawn(game.pilot.fleet.back(),pos,heading)

func restore() -> void:
	prepare();attack_target=null;takeover_candidate={}
	for i in game.pilot.fleet.size():
		spawn(game.pilot.fleet[i],game.pilot.position+Vector2(100,120).rotated(i*.7),game.pilot.heading)

func sync() -> void:
	for npc in game.escorts:
		var member: Dictionary=record(npc)
		if member.is_empty() or not is_instance_valid(npc.model): continue
		game.Combat.sync(npc)
		member.health=maxf(.001,npc.health);member.shield=npc.shield;member.armor=npc.armor;member.ammo=[]
		for weapon in npc.weapons: member.ammo.append(int(weapon.ammo))

func destroyed(npc: Dictionary) -> void:
	var member: Dictionary=record(npc)
	if member.is_empty(): return
	game.pilot.fleet.erase(member);game.escorts.erase(npc)
	game.notify("Escort lost: "+npc.name)

func offers() -> Array:
	var result: Array=[]
	if game.mode!="fleet" or game.fleet_return_mode!="dock": return result
	for option in game.traffic.options(game.pilot.system_id):
		var f: Dictionary=game.catalog.record("ships",int(option.ship)).fields
		if int(option.ship) in result or f.Cost<=0 or f.TechLevel>=9999 or int(option.ship)==191: continue
		if game.Factions.hostile_to_pilot(game.catalog,game.pilot,int(option.faction)): continue
		result.append(int(option.ship))
	result.sort();return result

func wage(id: int) -> int: return int(int(game.catalog.field("ships",id,"Cost"))*.01)
func hire_cost(id: int) -> int: return int(game.catalog.equipment_price("ships",id,game.docked_id)*.1)
func hire(id: int) -> bool:
	if id not in offers() or game.pilot.fleet.size()>=LIMIT or game.pilot.credits<hire_cost(id) or game.npcs.size()>=game.traffic.MAX_CONTACTS: return false
	game.pilot.credits-=hire_cost(id)
	game.pilot.fleet.append({"id":id,"hired":true,"wage":wage(id),"paid_day":int(game.pilot.campaign.day),"command":"defend"})
	spawn_last(id,game.pilot.position+Vector2(100,100),game.pilot.heading)
	game.save_game(false);game.hud.rebuild_modal();return true

func payroll() -> void:
	prepare()
	for member in game.pilot.fleet.duplicate():
		if not member.get("hired",false): continue
		var days: int=maxi(0,int(game.pilot.campaign.day)-int(member.get("paid_day",game.pilot.campaign.day)))
		var bill: int=days*int(member.wage)
		if bill<=0: continue
		if game.pilot.credits>=bill:
			game.pilot.credits-=bill;member.paid_day=int(game.pilot.campaign.day)
			game.notify("Escort wages paid: %d cr" % bill)
		else:
			game.notify("Unpaid escort departed: "+game.catalog.record("ships",int(member.id)).name)
			for npc in game.escorts.duplicate():
				if record(npc)==member: detach(npc)
			game.pilot.fleet.erase(member)

func detach(npc: Dictionary) -> void:
	var member: Dictionary=record(npc)
	if not member.is_empty(): npc.cargo=member.get("cargo",[0,0,0,0,0,0]).duplicate()
	game.escorts.erase(npc);npc.erase("fleet_uid");npc.captured=false;npc.freed=true
	npc.truce=true;npc.hostile=false;npc.ai=1;npc.ambient=true
	npc.goal=npc.position+Vector2(0,-2600)

func release(npc: Dictionary) -> bool:
	if game.mode!="fleet" or npc not in game.escorts: return false
	var member: Dictionary=record(npc)
	if member.is_empty(): return false
	detach(npc);game.pilot.fleet.erase(member)
	game.save_game(false);game.hud.rebuild_modal();return true

func order(command: String) -> void:
	if game.mode!="fleet" or command not in ORDERS: return
	if command=="attack":
		var target: Dictionary=game.selected_contact()
		if target.is_empty() or target.has("fleet_uid") or target.disabled:
			game.notify("Select an operational enemy contact before ordering an attack.");return
		attack_target=target.model
	for npc in game.escorts:
		var member: Dictionary=record(npc)
		if member.is_empty(): continue
		member.command=command;npc.hold_position=npc.position
	game.notify("Fleet order: "+command.capitalize());game.save_game(false);game.hud.rebuild_modal()

func target(npc: Dictionary) -> Dictionary:
	var member: Dictionary=record(npc)
	var command: String=str(member.get("command","defend"))
	if command in ["hold","recall"]: return {}
	if command=="attack" and is_instance_valid(attack_target):
		for other in game.npcs:
			if other.model==attack_target and not other.disabled and not other.has("fleet_uid"): return other
	var best: Dictionary={};var distance: float=1400
	for other in game.npcs:
		if other==npc or other.has("fleet_uid") or other.disabled or other.truce or not other.hostile: continue
		var d: float=npc.position.distance_to(other.position)
		if d<distance: distance=d;best=other
	return best

func goal(npc: Dictionary) -> Vector2:
	var member: Dictionary=record(npc)
	if member.get("command","defend")=="hold": return npc.get("hold_position",npc.position)
	return game.pilot.position+Vector2(100,140).rotated(float(game.escorts.find(npc))*.7)

func takeover_reason(npc: Dictionary) -> String:
	var member: Dictionary=record(npc)
	if member.is_empty() or member.get("hired",false): return "Only captured ships can become your flagship."
	if game.pilot.cargo_used()+cargo_used(member)>int(game.catalog.field("ships",npc.id,"Holds")): return "Unload cargo or finish cargo missions before switching to this hull."
	if game.hyperdrive.active() or not game.chain_route.is_empty(): return "Cancel hyperspace before transferring command."
	if npc.disabled: return "Repair this ship at a port before taking command."
	return ""

func takeover(npc: Dictionary) -> bool:
	if game.mode!="fleet" or not takeover_reason(npc).is_empty(): return false
	sync()
	var member: Dictionary=record(npc)
	var port: int=game.docked_id
	var return_mode: String=game.fleet_return_mode
	game.Combat.sync(npc)
	game.pilot.ship_id=int(npc.id);game.pilot.ship_fields=game.catalog.record("ships",int(npc.id)).fields.duplicate(true)
	game.pilot.outfits=game.Shipyard.stock_outfits(game.catalog,int(npc.id))
	game.pilot.lasers=int(game.pilot.outfits.get("128",0));game.pilot.outfits.erase("128")
	# Transfer ammunition actually left aboard, not a free factory reload.
	for weapon in npc.weapons:
		if weapon.ammo<0: continue
		var ammo_id: int=game.outfitter.ammo_id(int(weapon.id))
		if ammo_id>=0:
			if weapon.ammo>0: game.pilot.outfits[str(ammo_id)]=int(weapon.ammo)
			else: game.pilot.outfits.erase(str(ammo_id))
	game.pilot.shield=minf(game.pilot.max_shield(),npc.shield);game.pilot.armor=minf(game.pilot.max_armor(),npc.armor)
	game.pilot.fuel=minf(game.pilot.fuel,game.pilot.fuel_capacity());game.pilot.selected_weapon=128
	for i in 6: game.pilot.cargo[i]+=int(member.get("cargo",[0,0,0,0,0,0])[i])
	game.pilot.fleet.erase(member)
	game.load_system();game.docked_id=port
	game.set_mode("dock" if return_mode=="dock" else "flight")
	game.notify("Command transferred. Your previous hull and its equipment were abandoned; cargo and credits retained.")
	game.arsenal.available_ids();game.save_game(false);return true

func service_cost() -> int:
	var total: int=0
	for npc in game.escorts:
		if record(npc).is_empty(): continue
		total+=ceili(maxf(0,npc.max_health-npc.health)*2)
		var f: Dictionary=game.catalog.record("ships",npc.id).fields
		for i in npc.weapons.size():
			var w: Dictionary=npc.weapons[i]
			if w.ammo>=0:
				var ammo_id: int=game.outfitter.ammo_id(int(w.id))
				if ammo_id>=0: total+=maxi(0,int(f.AmmoLoad[int(npc.weapons[i].get("slot",i))])-int(w.ammo))*int(game.catalog.field("outfits",ammo_id,"Cost"))
	return total

func service() -> bool:
	if game.mode!="fleet" or game.fleet_return_mode!="dock" or game.pilot.credits<service_cost(): return false
	game.pilot.credits-=service_cost()
	for npc in game.escorts:
		if record(npc).is_empty(): continue
		npc.health=npc.max_health;npc.disabled=false;game.Combat.sync(npc)
		var f: Dictionary=game.catalog.record("ships",npc.id).fields
		for i in npc.weapons.size():
			if npc.weapons[i].ammo>=0: npc.weapons[i].ammo=int(f.AmmoLoad[int(npc.weapons[i].get("slot",i))])
	game.save_game(false);game.hud.rebuild_modal();return true

# Commodity manifests belong to their carrier. Mission freight stays on the flagship.
func cargo_used(member: Dictionary) -> int:
	var total: int=0
	for amount in member.get("cargo",[]): total+=int(amount)
	return total

func cargo_capacity() -> int:
	var total: int=game.pilot.cargo_capacity()
	for member in game.pilot.fleet: total+=int(game.catalog.field("ships",int(member.id),"Holds"))
	return total

func total_cargo_used() -> int:
	var total: int=game.pilot.cargo_used()
	for member in game.pilot.fleet: total+=cargo_used(member)
	return total

func commodity_count(index: int) -> int:
	var total: int=int(game.pilot.cargo[index])
	for member in game.pilot.fleet: total+=int(member.get("cargo",[0,0,0,0,0,0])[index])
	return total

func load_commodity(index: int, quantity: int) -> int:
	if index<0 or index>=6 or quantity<=0: return 0
	var moved: int=mini(quantity,maxi(0,game.pilot.cargo_capacity()-game.pilot.cargo_used()))
	game.pilot.cargo[index]+=moved
	for member in game.pilot.fleet:
		if moved>=quantity: break
		var amount: int=mini(quantity-moved,maxi(0,int(game.catalog.field("ships",int(member.id),"Holds"))-cargo_used(member)))
		if amount<=0: continue
		if not member.has("cargo"): member.cargo=[0,0,0,0,0,0]
		member.cargo[index]+=amount;moved+=amount
	return moved

func trade(index: int, buying: bool, price: int) -> bool:
	if game.mode!="dock" or index<0 or index>=6 or price<0: return false
	if int(game.world_activity.prices(game.docked_id)[index])<0: return false
	if buying:
		if game.pilot.credits<price or load_commodity(index,1)!=1: return false
		game.pilot.credits-=price
	else:
		if commodity_count(index)<=0: return false
		# Unload escorts first, leaving the flagship's manifest undisturbed when possible.
		var unloaded: bool=false
		for member in game.pilot.fleet:
			if int(member.get("cargo",[0,0,0,0,0,0])[index])>0:
				member.cargo[index]-=1;unloaded=true;break
		if not unloaded: game.pilot.cargo[index]-=1
		game.pilot.credits+=price
	return true
