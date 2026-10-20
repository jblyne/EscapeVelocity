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
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/target-%s.png" % name))

func tab() -> void:
	var event=InputEventKey.new();event.pressed=true;event.physical_keycode=KEY_TAB
	game._unhandled_key_input(event)

func capture() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-target-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.pilot.cheat_all_weapons=true
	game.pilot.cheat_infinite_fuel=true
	await screenshot("none")
	tab()
	game.npcs[0].velocity=Vector2(30,40)
	await screenshot("freighter")
	tab()
	await screenshot("courier")
	game.combat_drill()
	game.damage_npc(game.selected_contact(),25)
	await screenshot("hostile")
	root.size=Vector2i(1100,740)
	await screenshot("minimum-window")
	root.size=Vector2i(1440,900)
	game.damage_npc(game.selected_contact(),1000)
	await screenshot("destroyed")
	game.free()
	await process_frame
	print("Target panel visual capture complete.")
	quit()
