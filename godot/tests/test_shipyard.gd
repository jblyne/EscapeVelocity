extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-shipyard-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.pilot.credits=1000000000
	game.docked_id=128;game.set_mode("shipyard")
	check(not game.shipyard.reason(134).is_empty(),"military ships require mission clearance")
	check(game.shipyard.price(131)==158000-5610,"original Earth hull price and installed-equipment trade-in")
	check(game.shipyard.buy(131),"purchase courier")
	check(game.pilot.ship_id==131 and game.pilot.cargo_capacity()==50 and 133 in game.arsenal.available_ids(),"new hull has original capacity and stock turret")
	var restored=game.Pilot.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(game.pilot.snapshot())),game.catalog) and restored.ship_id==131 and restored.cargo_capacity()==50,"purchased hull and loadout survive reload")
	game.pilot.outfits["167"]=1
	game.pilot.campaign.bits=[61,66,67,73]
	for id in game.shipyard.ships():
		if id==game.pilot.ship_id: continue
		var port: int=-1
		for obj in game.catalog.data.objects.values():
			game.docked_id=int(obj.id)
			if game.shipyard.reason(id).is_empty(): port=int(obj.id);break
		if port<0: continue
		game.docked_id=port
		check(game.shipyard.buy(id),"buy source hull %d" % id)
		check(game.pilot.outfit_count(167)==1,"mission cloak transfers with hull %d" % id)
		check(restored.restore(JSON.parse_string(JSON.stringify(game.pilot.snapshot())),game.catalog),"valid stock loadout and save for hull %d" % id)
		if game.pilot.max_armor()==0:
			game.set_mode("flight");game.damage_player(1)
			check(game.mode=="flight","unarmored fighter survives shield-only hit")
			game.set_mode("shipyard")
	game.docked_id=128;game.set_mode("shipyard")
	var screen=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	check(screen.canvas.size==Vector2(1000,530),"shipyard matches compact port dimensions")
	check(screen.ship_list.item_count==game.shipyard.ships().size(),"classic ship list retains full catalog")
	screen.ship_list.select(0);screen.select_ship(0)
	check(game.shipyard.selected==int(screen.ships[0]),"ship selection updates preview and retained selection")
	check(screen.find_child("BuyShip%d" % game.shipyard.selected,true,false)!=null,"selected hull has purchase control")
	if "--visual" in OS.get_cmdline_user_args():
		game.docked_id=128;game.set_mode("shipyard")
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/shipyard.png"))
	game.free();await process_frame
	print("SHIPYARD RESULT: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
