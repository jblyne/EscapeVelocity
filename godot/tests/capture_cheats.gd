extends SceneTree
var game

func _initialize() -> void:
	call_deferred("capture")

func screenshot(name: String) -> void:
	game.player_model.position=game.v3(game.pilot.position)
	game.player_model.rotation.y=-game.pilot.heading
	game.camera.position=game.v3(game.pilot.position,1200)
	game._process(0)
	game.hud._process(0)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/cheats-%s.png" % name))

func capture() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-cheats-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.toggle_cheat_menu()
	await screenshot("off")
	game.hud.weapons_toggle.button_pressed=true
	game.hud.fuel_toggle.button_pressed=true
	game.hud.invincibility_toggle.button_pressed=true
	game.hud.deflection_toggle.button_pressed=true
	game.select_weapon(132)
	await screenshot("on")
	game.hud.weapon_picker.show_popup()
	await screenshot("weapon-list")
	game.hud.weapon_picker.get_popup().hide()
	root.size=Vector2i(1100,740)
	await screenshot("minimum-window")
	root.size=Vector2i(1440,900)
	game.toggle_cheat_menu()
	game.pilot.position=Vector2(12000,12000)
	game.pilot.heading=0
	game.spawn_npc(true,game.pilot.position+Vector2(0,-300))
	game.target_index=game.npcs.size()-1
	game.npcs[-1].health=10000
	game.npcs[-1].max_health=10000
	game.select_weapon(142)
	game.fire_player()
	await screenshot("beam")
	game.update_shots(0.1)
	game.select_weapon(132)
	game.cooldown=0;game.fire_player()
	game.update_shots(0.15)
	await screenshot("missile")
	game.select_weapon(146)
	for i in 4:
		game.cooldown=0;game.fire_player()
		game.arsenal.update_escorts(0.2)
	await screenshot("escorts")
	game.set_mode("pause")
	await screenshot("pause")
	game.free()
	await process_frame
	print("Cheat menu and weapons visual capture complete.")
	quit()
