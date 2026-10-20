extends SceneTree
var game
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-qa-breakup-pilot.json"
	game.muted=true;game.traffic.enabled=false;game.breakup_chance=1.0
	root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.hud.hide();game.player_model.hide()
	game.camera.position=game.v3(game.pilot.position,1200);game.camera.size=420
	game.traffic.spawn(134,128,3,game.pilot.position)
	var npc=game.npcs[0]
	var effect
	for seed_value in 12:
		effect=game.Breakup.new();game.world.add_child(effect)
		effect.position=game.v3(npc.position)
		effect.setup(npc.model,Vector2.ZERO,seed_value)
		if effect.halves.size()==3: break
		effect.free()
	game.explosions.append(effect)
	npc.model.hide()
	var times: Array=[0.0,1.6]
	var timers: Array=[]
	for piece in effect.halves: timers.append(piece.timer)
	timers.sort()
	for timer in timers: times.append(timer+.18)
	for t in times:
		game.update_explosions(t-effect.age)
		await process_frame;await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/breakup-%.2f.png" % t))
	game.free();await process_frame
	print("Breakup captures complete")
	quit()
