extends SceneTree
var game
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func click(name: String) -> void:
	if name.begins_with("BuyOutfit") or name.begins_with("SellOutfit"):
		var id: int=int(name.trim_prefix("BuyOutfit").trim_prefix("SellOutfit"))
		var card=game.hud.modal_root.find_child("SelectOutfit%d" % id,true,false)
		if card is Button: card.pressed.emit()
	var button = game.hud.modal_root.find_child(name,true,false)
	check(button is Button and not button.disabled,"available UI action: "+name)
	if button is Button and not button.disabled: button.pressed.emit()
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/test-outfitter-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled = false
	game.muted = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.docked_id = 128 # Earth, technology level 5.
	game.set_mode("dock")
	click("OpenOutfitter")
	check(game.mode == "outfitter","landing menu opens dedicated outfitter")
	click("SelectOutfit130")
	check(game.hud.selected_outfit==130 and game.hud.modal_root.find_child("BuyOutfit130",true,false)!=null,"equipment card opens matching purchase details")
	check(game.hud.modal_root.find_child("EquipmentGrid",true,false).columns==4,"classic outfitter arranges equipment in four compact columns")
	for id in game.outfitter.stock():
		check(game.hud.modal_root.find_child("OutfitPicture%d" % id,true,false) is TextureRect,"equipment has artwork: %d" % id)
	var shop = game.outfitter
	game.pilot.credits = 1000000
	game.hud.rebuild_modal()
	click("BuyOutfit130")
	check(game.pilot.credits == 992270 and shop.count(130) == 1 and 130 in game.arsenal.available_ids(),"purchase installs technology-discounted proton cannon in normal weapon selection")
	check(not shop.trade(129,true),"oversized weapon cannot exceed equipment space")
	click("BuyOutfit128")
	check(not shop.trade(128,true),"gun mount limit includes different installed weapons")
	click("SellOutfit128")
	click("SellOutfit130")
	check(shop.count(130) == 0 and game.pilot.credits == 1000000,"same-visit sales refund purchases and remove equipment")
	check(not shop.trade(134,true),"ammunition requires matching launcher")
	click("BuyOutfit133")
	click("BuyOutfit134")
	check(shop.space_used() == 11,"launcher and ammunition both consume equipment space")
	check(not shop.trade(133,false),"loaded launcher cannot be sold before its ammunition")
	game.set_mode("flight")
	game.select_weapon(132)
	game.cooldown = 0
	check(game.fire_player() and shop.count(134) == 0,"normal firing consumes purchased ammunition")
	game.cooldown = 0
	check(not game.fire_player(),"empty launcher refuses to fire")
	check(not shop.trade(128,true),"outfitting is restricted to port")
	game.set_mode("outfitter")
	shop.trade(133,false)
	game.pilot.cargo = [10,0,0,0,0,0]
	check(not shop.trade(140,true),"mass expansion cannot strand existing cargo")
	game.pilot.cargo = [0,0,0,0,0,0]
	check(shop.trade(140,true) and game.pilot.cargo_capacity() == 5,"mass expansion trades cargo for equipment space")
	check(shop.trade(135,true) and game.pilot.cargo_capacity() == 15,"cargo pod adds usable cargo capacity")
	check(not shop.trade(140,false),"mass expansion cannot be removed while its space is occupied")
	game.pilot.cargo[0] = 6
	check(not shop.trade(135,false),"loaded cargo pod cannot be sold")
	game.pilot.cargo[0] = 0
	shop.trade(135,false)
	shop.trade(140,false)
	check(shop.trade(147,true) and game.pilot.max_armor() == 200,"armor equipment increases actual armor capacity")
	game.set_mode("dock")
	game.service()
	check(game.pilot.armor == 200,"repair service fills upgraded armor")
	game.set_mode("outfitter")
	check(shop.trade(153,true) and game.pilot.fuel_capacity() == 500,"external fuel tank adds actual capacity")
	check(not shop.trade(145,true),"special technology is not sold at ordinary ports")
	var before: int = game.pilot.credits
	game.pilot.credits = 0
	check(not shop.trade(128,true) and shop.count(128) == 1,"insufficient funds cannot install equipment")
	game.pilot.credits = before
	game.save_game(false)
	var restored = game.Pilot.new()
	var save = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(restored.restore(save,game.catalog) and restored.outfits == game.pilot.outfits and restored.armor == 200,"upgraded pilot save roundtrip")
	var invalid = save.duplicate(true)
	invalid.outfits["129"] = 4
	check(not restored.restore(invalid,game.catalog),"invalid over-capacity loadout rejected")
	var legacy = game.Pilot.new().snapshot()
	legacy.erase("outfits")
	check(restored.restore(legacy,game.catalog) and restored.outfits.is_empty(),"legacy pilots remain compatible")
	game.docked_id = 163 # Alkaidion carries shield and engine special technologies.
	check(shop.trade(145,true) and game.pilot.max_shield() == 195,"specialist port sells functional shield capacitors")
	check(shop.trade(146,true),"shield regeneration booster installs at specialist port")
	check(shop.trade(150,true) and shop.trade(151,true) and shop.trade(152,true),"engine upgrades install at specialist port")
	var fields: Dictionary = game.pilot.flight_fields(game.catalog.record("ships",128).fields)
	check(fields.Speed == 412.5 and fields.Accel == 652.5 and fields.Maneuver == 5,"installed engine equipment changes flight parameters")
	game.set_mode("flight")
	game.pilot.shield = 190
	game.damage_clock = 100
	game._physics_process(3.0)
	check(game.pilot.shield == 195,"shield regeneration respects increased maximum")
	game.set_mode("outfitter")
	check(shop.trade(145,false) and game.pilot.shield == 180,"selling capacity upgrade clamps stored shields")
	game.docked_id = 128
	game.pilot.outfits.clear()
	game.pilot.armor = 100
	game.pilot.fuel = game.pilot.fuel_capacity()
	check(shop.trade(130,true),"ordinary weapon installs after removing upgrades")
	game.set_mode("flight")
	game.select_weapon(130)
	var equipped_save = game.pilot.snapshot()
	check(restored.restore(equipped_save,game.catalog) and restored.selected_weapon == 130,"purchased selected weapon survives reload without cheats")
	game.pilot.outfits = {"168":1}
	game.pilot.fuel = 50
	game._physics_process(1.0)
	check(game.pilot.fuel == 51,"ramscoop replenishes fuel during flight")
	game.pilot.outfits = {"130":1}
	game.pilot.fuel = game.pilot.fuel_capacity()
	game.set_mode("outfitter")
	if "--visual" in OS.get_cmdline_user_args():
		game.hud.selected_outfit=128
		game.hud.rebuild_modal()
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/outfitter.png"))
	click("CloseOutfitter")
	check(game.mode == "dock","back returns to port")
	game.free()
	await process_frame
	print("OUTFITTER RESULT: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
