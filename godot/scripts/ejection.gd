extends RefCounted
# Original pod/auto-eject equipment, with an explicit rescue flow for the remake.
var game
var pod: Node3D
var remaining: float=0
var motion: Vector3

func request() -> void:
	if game.mode not in ["flight","info","pause"]: return
	if game.pilot.outfit_count(154)==0:
		game.notify("No escape pod installed.");return
	game.set_mode("eject_confirm")

func begin(automatic: bool=false) -> bool:
	if game.mode not in ["flight","eject_confirm"] or game.pilot.outfit_count(154)==0: return false
	if automatic and game.pilot.outfit_count(181)==0: return false
	game.cancel_jump(false);game.chain_route.clear();game.cloak.set_active(false)
	game.ship_explosion(game.player_model,game.pilot.position,game.velocity)
	game.player_model.hide()
	pod=game.ShipModels.create(game.catalog,191,-1)
	game.world.add_child(pod);pod.position=game.v3(game.pilot.position)
	pod.rotation.y=-game.pilot.heading
	motion=game.v3(Vector2.UP.rotated(game.pilot.heading)*75)
	remaining=3.0
	game.set_mode("ejecting")
	game.notify("Automatic ejection!" if automatic else "Escape pod launched.")
	return true

func reset() -> void:
	if is_instance_valid(pod): pod.queue_free()
	pod=null;remaining=0

func advance(dt: float) -> void:
	if game.mode!="ejecting": return
	if is_instance_valid(pod): pod.position+=motion*dt
	remaining=maxf(0,remaining-dt)
	if remaining==0: game.set_mode("rescue")

func rescue_port() -> int:
	# Original rescue resets the ship to Levo. Accommodate the remake's destroyed worlds.
	if not game.world_killer.destroyed(133): return 133
	var queue: Array=[game.pilot.system_id]
	var visited: Array=[]
	while not queue.is_empty():
		var system: int=queue.pop_front()
		if system in visited: continue
		visited.append(system)
		for object in game.catalog.data.objects.values():
			if not game.world_killer.destroyed(int(object.id)) and int(object.fields.System)==system and int(object.fields.Flags)&1 and not int(object.fields.Flags)&32: return int(object.id)
		queue.append_array(game.catalog.system(system).links)
	return 128

func recover() -> void:
	if game.mode!="rescue": return
	var port: int=rescue_port()
	# Block intermediate mission-failure saves until the replacement is complete.
	for mission in game.pilot.campaign.active.duplicate(): game.missions.finish(mission,false,false,false,"Your ship and its mission cargo were lost during escape-pod rescue.")
	game.pilot.mission.clear();game.pilot.cargo=[0,0,0,0,0,0]
	# The original reinitializes its ship/escort slots during rescue (0x31f7c).
	game.pilot.fleet.clear()
	game.pilot.ship_id=128
	game.pilot.ship_fields=game.catalog.record("ships",128).fields.duplicate(true)
	game.pilot.outfits=game.Shipyard.stock_outfits(game.catalog,128)
	game.pilot.lasers=int(game.pilot.outfits.get("128",0));game.pilot.outfits.erase("128")
	game.pilot.shield=game.pilot.max_shield();game.pilot.armor=game.pilot.max_armor();game.pilot.fuel=game.pilot.fuel_capacity()
	game.pilot.selected_weapon=128
	game.pilot.system_id=game.missions.system_of(port)
	if game.pilot.system_id not in game.pilot.visited: game.pilot.visited.append(game.pilot.system_id)
	game.pilot.campaign.day+=30;game.pilot.campaign.visit+=1
	game.pilot.reputation.clear();game.pilot.local_records.clear()
	for government in game.catalog.data.governments.values():
		game.pilot.reputation[str(int(government.id))]=int(government.fields.InitialRec)
	game.fleet_service.sync();game.fleet_service.payroll()
	game.missions.landing_reports.clear();game.missions.active_landing_report.clear()
	game.load_system();game.docked_id=port
	for planet in game.planets:
		if int(planet.id)==port: game.pilot.position=planet.position+Vector2(0,planet.radius*.8)
	game.velocity=Vector2.ZERO
	game.world_activity.sync();game.set_mode("dock")
	game.notify("Rescued at %s after 30 days. Legal records reset; replacement shuttle supplied. Ship, equipment and cargo lost; active contracts failed." % game.catalog.record("objects",port).name)
	game.save_game(false)
