extends SceneTree

const Pilot=preload("res://scripts/pilot.gd")
const Catalog=preload("res://scripts/catalog.gd")
var count: int=0
var failures: int=0
var game

func check(ok: bool, message: String) -> void:
	count+=1
	if ok: print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)

func _initialize() -> void:
	call_deferred("run")

func reset_space() -> void:
	for fighter in game.escorts.duplicate():
		if not fighter.get("captured",false): fighter.model.queue_free();game.escorts.erase(fighter)
	game.pilot.fighter_sorties=[]
	game.load_system()
	game.set_mode("flight")
	game.pilot.position=Vector2.ZERO
	game.pilot.heading=0
	game.velocity=Vector2.ZERO
	game.cooldown=0
	for npc in game.npcs: npc.model.free()
	game.npcs.clear()
	game.target_index=-1

func add_target(pos: Vector2, health: float=10000) -> Dictionary:
	game.spawn_npc(true,pos)
	var npc=game.npcs[-1]
	npc.health=health
	npc.max_health=health
	game.target_index=game.npcs.size()-1
	return npc

func run() -> void:
	var catalog=Catalog.new()
	var pilot=Pilot.new()
	pilot.fuel=0
	pilot.cheat_infinite_fuel=true
	check(pilot.jump(136,catalog.system(128).links) and pilot.fuel==0,"infinite fuel allows an empty-tank jump without altering the stored tank")
	pilot.cheat_infinite_fuel=false
	check(not pilot.jump(128,catalog.system(136).links),"turning infinite fuel off restores empty-tank restrictions")
	pilot.fuel=200
	check(pilot.jump(128,catalog.system(136).links) and pilot.fuel==100,"normal fuel use resumes when the cheat is off")
	pilot.cheat_infinite_fuel=true
	check(not pilot.jump(9999,catalog.system(128).links),"infinite fuel does not bypass route connectivity")
	pilot.cheat_all_weapons=true
	pilot.selected_weapon=191
	var restored=Pilot.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(pilot.snapshot())),catalog) and restored.cheat_all_weapons and restored.cheat_infinite_fuel and restored.selected_weapon==191,"both toggles and selected weapon survive a save roundtrip")
	var legacy=pilot.snapshot();legacy.erase("cheats")
	check(restored.restore(legacy,catalog) and not restored.cheat_all_weapons and not restored.cheat_infinite_fuel and not restored.cheat_invincibility and not restored.cheat_deflection and restored.selected_weapon==128,"legacy saves default safely to normal weapons and fuel")
	for bad in [{"all_weapons":"true"},{"infinite_fuel":1},{"invincibility":1},{"deflection":"true"},{"weapon":9999},{"weapon":128.5}]:
		var snapshot=pilot.snapshot();snapshot.cheats=bad
		var previous=restored.snapshot()
		check(not restored.restore(snapshot,catalog) and restored.snapshot()==previous,"invalid cheat state rejected atomically: "+str(bad))
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-cheats-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted=true
	game.traffic.enabled = false # Isolate this feature from independently tested ambient traffic.
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.pilot.credits=12345
	game.pilot.lasers=3
	game.pilot.cargo[0]=2
	var reserve: float=game.pilot.fuel
	var event=InputEventKey.new();event.physical_keycode=KEY_C;event.pressed=true
	game._unhandled_key_input(event)
	check(game.mode=="cheats" and not game.hud.weapons_toggle.button_pressed and game.hud.weapon_picker.disabled,"C opens the cheat menu with accurate off states")
	game.hud.weapons_toggle.button_pressed=true
	check(not game.hud.invincibility_toggle.button_pressed,"invincibility defaults off")
	game.hud.invincibility_toggle.button_pressed=true
	game.hud.fuel_toggle.button_pressed=true
	check(game.pilot.cheat_all_weapons and game.pilot.cheat_infinite_fuel and not game.hud.weapon_picker.disabled and game.hud.weapon_picker.item_count==game.arsenal.available_ids().size(),"actual menu toggles grant all catalog weapons and infinite fuel")
	var before=game.pilot.position
	game._physics_process(5)
	check(game.pilot.position==before and not game.fire_player(),"cheat menu pauses flight and blocks firing")
	game.select_weapon(132)
	game.load_game()
	check(game.pilot.cheat_all_weapons and game.pilot.cheat_infinite_fuel and game.pilot.selected_weapon==132,"cheat choices restore from the actual saved pilot file")
	check(game.pilot.cheat_invincibility,"invincibility survives actual save and reload")
	game.set_mode("flight")
	game.pilot.shield=80
	game.pilot.armor=50
	game.damage_clock=5
	game.damage_player(10000)
	check(game.pilot.shield==80 and game.pilot.armor==50 and game.damage_clock==5,"invincibility prevents shield damage and damage side effects")
	game.pilot.shield=0
	game.damage_player(10000)
	check(game.pilot.armor==50 and game.mode=="flight","invincibility prevents lethal damage with no shields")
	game.hud._process(0)
	check("INVINCIBLE" in game.hud.cheat_status.text,"HUD reports active invincibility")
	game.toggle_cheat_menu()
	check(game.hud.invincibility_toggle.button_pressed,"menu reflects enabled invincibility")
	game.hud.invincibility_toggle.button_pressed=false
	game.toggle_cheat_menu()
	game.damage_player(10)
	check(game.pilot.armor==40,"turning invincibility off restores armor damage")
	game.pilot.shield=80
	game.damage_player(10)
	check(game.pilot.shield==70,"turning invincibility off restores shield damage")
	game.load_game()
	check(not game.pilot.cheat_invincibility,"disabled invincibility persists after reload")
	game.pilot.shield=180
	game.pilot.armor=100
	game.set_mode("pause");game.toggle_cheat_menu();game.toggle_cheat_menu()
	check(game.mode=="pause","closing cheats opened from pause returns to pause")
	game.set_mode("flight")
	game.pilot.position=game.planets[0].position;game.land();game.land()
	game.toggle_cheat_menu();game.toggle_cheat_menu()
	check(game.mode=="dock" and game.docked_id==game.planets[0].id,"closing cheats opened in port preserves docking")
	game.launch()
	game.pilot.fuel=0
	game.pilot.position=Vector2(12000,12000)
	game.start_jump()
	check(game.hyperdrive.active(),"game-level jump check accepts empty fuel when infinite fuel is enabled")
	var start_system: int=game.pilot.system_id
	for frame in 1200:
		game._physics_process(1.0/60)
		if game.pilot.system_id!=start_system: break
	check(game.pilot.system_id!=start_system and game.pilot.fuel==0,"actual hyperspace transition consumes no fuel while the toggle is on")
	check(game.service_cost()==0,"port service does not charge for fuel under the cheat")
	game.service()
	check(game.pilot.fuel==0 and game.pilot.credits==12345,"service under infinite fuel preserves stored fuel and credits")
	game.hud._process(0)
	check(game.hud.fuel.value==100 and "∞ jumps" in game.hud.stats.text,"HUD clearly reports infinite fuel")
	game.set_fuel_cheat(false)
	game.cycle_destination()
	check("Insufficient fuel" in game.jump_block_reason(),"turning the toggle off immediately restores normal jump requirements")
	game.set_fuel_cheat(true)
	reset_space()
	check(game.arsenal.ids().size()==game.catalog.data.weapons.size(),"arsenal includes every imported weapon, including hidden equipment")
	var every_weapon: bool=true
	for id in game.arsenal.available_ids():
		reset_space()
		game.select_weapon(id)
		if id in [133,134,143]: add_target(Vector2(0,200) if id==143 else Vector2(0,-200))
		var initial=game.pilot.snapshot()
		var shot_count: int=game.shots.size()
		var escort_count: int=game.escorts.size()
		var fired: bool=game.fire_player()
		if not fired or (game.shots.size()<=shot_count and game.escorts.size()<=escort_count) or game.pilot.snapshot()!=initial: every_weapon=false
		check(fired and (game.shots.size()>shot_count or game.escorts.size()>escort_count),"usable weapon: "+game.catalog.record("weapons",id).name)
	check(every_weapon,"all weapons fire or launch without consuming ammo, fuel, credits, cargo, or purchased lasers")
	reset_space();game.select_weapon(132)
	var stored=game.pilot.snapshot()
	for shot in 50:
		game.cooldown=0
		game.fire_player()
	check(game.shots.size()==50 and game.pilot.snapshot()==stored,"repeated missile launches have unlimited ammunition and no inventory cost")
	check(not game.fire_player(),"unlimited ammo preserves weapon reload timing")
	game.cycle_weapon(1)
	check(game.pilot.selected_weapon==133,"Default E cycles through all selected weapons, including primary turrets")
	game.cycle_weapon(-1)
	check(game.pilot.selected_weapon==132,"Q cycles back to the previous weapon")
	reset_space();game.select_weapon(132)
	var target=add_target(Vector2(250,-250))
	game.fire_player()
	var heading_before: Vector2=game.shots[-1].velocity
	game.update_shots(0.1)
	check(game.shots[-1].velocity.x>heading_before.x,"guided missiles turn toward the selected contact")
	reset_space();game.select_weapon(133)
	target=add_target(Vector2(300,0))
	game.fire_player()
	check(game.shots[-1].velocity.x>800 and absf(game.shots[-1].velocity.y)<0.01,"turret aims at a contact off the bow")
	reset_space();game.select_weapon(142)
	target=add_target(Vector2(0,-300))
	game.fire_player()
	check(target.health<10000 and game.shots[-1].kind=="beam_visual","particle beam hits across its visible beam immediately")
	reset_space();game.select_weapon(149)
	target=add_target(Vector2(0,-300))
	game.fire_player()
	check(target.position.y>-300 and target.health==10000,"tractor beam pulls a selected target without dealing damage")
	reset_space();game.select_weapon(140)
	var first=add_target(Vector2(0,50));var second=add_target(Vector2(60,50))
	game.fire_player();game.update_shots(0.01)
	check(first.health<10000 and second.health<10000,"space-bomb explosion damages multiple nearby contacts")
	reset_space();game.select_weapon(150)
	game.fire_player()
	game.shots[-1].position=Vector2(250,-100);game.shots[-1].node.position=game.v3(game.shots[-1].position,6)
	game.fire(Vector2(0,-300),PI,true,132)
	game.update_shots(0.1)
	check(game.shots[-1].velocity.x>0,"decoy flares divert incoming homing weapons")
	reset_space();game.select_weapon(146)
	target=add_target(Vector2(0,-300))
	game.fire_player()
	for frame in 60: game.arsenal.update_escorts(1.0/60)
	check(game.escorts.size()==1 and not game.shots.is_empty(),"fighter-bay escort launches and fires at the selected contact")
	for n in 16:
		game.cooldown=0;game.fire_player()
	check(game.escorts.size()==12,"unlimited fighter stock keeps active escort count bounded")
	game.set_weapon_cheat(false)
	check(game.pilot.selected_weapon==128 and game.escorts.is_empty() and game.pilot.lasers==3 and game.pilot.credits==12345 and game.pilot.cargo[0]==2,"turning weapons off removes escorts and restores the purchased loadout without altering progression")
	game.select_weapon(191)
	check(game.pilot.selected_weapon==128,"disabled cheat cannot select a hidden weapon")
	reset_space();game.cooldown=0;game.fire_player()
	check(game.shots[-1].weapon==128,"Space returns to the normal laser after disabling the cheat")
	reset_space()
	game.toggle_cheat_menu()
	check(not game.hud.deflection_toggle.button_pressed,"deflection defaults off")
	game.hud.deflection_toggle.button_pressed=true
	game.load_game()
	check(game.pilot.cheat_deflection and not game.pilot.cheat_invincibility,"deflection persists independently of invincibility")
	game.set_mode("flight")
	for weapon in [128,132,139,140,142,147,152,149]:
		reset_space()
		var sender=add_target(Vector2(0,-200))
		var shield_before: float=game.pilot.shield
		var armor_before: float=game.pilot.armor
		game.arsenal.fire(weapon,sender.position,PI,true,sender)
		if game.arsenal.kind(weapon) not in ["beam","tractor"]:
			# Place the actual incoming projectile at the interception boundary.
			var incoming=game.shots[-1]
			incoming.position=Vector2(0,-20)
			game.update_shots(0.001)
			check(incoming.get("reflected",false) and not incoming.enemy and incoming.target==sender.model and incoming.velocity.y<0,"projectile redirects to its sender: "+str(weapon))
			for frame in 600:
				game.update_shots(1.0/60)
				if sender.health<10000: break
		check(sender.position.y < -200 if weapon==149 else sender.health<10000,"reflected weapon affects sender: "+str(weapon))
		check(game.pilot.shield==shield_before and game.pilot.armor==armor_before,"deflection protects player: "+str(weapon))
	game.hud._process(0)
	check("DEFLECTION" in game.hud.cheat_status.text,"HUD reports deflection")
	reset_space()
	game.toggle_cheat_menu()
	game.hud.deflection_toggle.button_pressed=false
	game.toggle_cheat_menu()
	var sender=add_target(Vector2(0,-200))
	game.pilot.shield=180
	game.arsenal.fire(142,sender.position,PI,true,sender)
	check(game.pilot.shield<180 and sender.health==10000,"disabling deflection restores normal beam hits")
	game.pilot.shield=180
	game.arsenal.fire(128,sender.position,PI,true,sender)
	game.shots[-1].position=Vector2(0,-20)
	game.update_shots(0.001)
	check(game.pilot.shield<180,"disabling deflection restores projectile damage")
	game.load_game()
	check(not game.pilot.cheat_deflection,"disabled deflection persists")
	game.pilot.fuel=reserve
	game.save_game(false)
	game.load_game()
	check(not game.pilot.cheat_all_weapons and game.pilot.cheat_infinite_fuel and game.pilot.selected_weapon==128,"independent off/on toggle choices persist across reloads")
	game.free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://../builds/test-cheats-pilot.json"))
	print("CHEAT RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
