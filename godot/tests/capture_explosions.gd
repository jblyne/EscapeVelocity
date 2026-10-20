extends SceneTree
var game

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-explosion-pilot.json")
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.camera.position=game.v3(game.pilot.position,1200)
	var contact=game.npcs[1]
	contact.position=game.pilot.position+Vector2(130,-130)
	contact.model.position=game.v3(contact.position)
	contact.velocity=Vector2(35,10)
	game.target_index=1
	game.damage_npc(contact,10000)
	game.hud._process(0)
	var previous: float=0
	for t in [0.04,0.22,0.55,1.1,2.2,3.7]:
		game.update_explosions(t-previous)
		game.update_sparks(t-previous)
		previous=t
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/explosion-%.2f.png" % t))
	game.pilot.shield=0
	game.pilot.armor=1
	game.fire(game.pilot.position,0,true)
	game.shots.back().position=game.pilot.position
	game.shots.back().velocity=Vector2.ZERO
	game.update_shots(0.01)
	for phase in ["player-blast","player-recovery"]:
		game._physics_process(0.45 if phase=="player-blast" else 0.6)
		game.hud._process(0)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/explosion-%s.png" % phase))
	game.free()
	await process_frame
	print("Explosion sequence capture complete.")
	quit()
