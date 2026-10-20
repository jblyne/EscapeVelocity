extends SceneTree
var game
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.save_path = ProjectSettings.globalize_path("res://../builds/test-shields-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled = false
	game.muted = true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	game.pilot.shield = 30
	game.damage_player(5,Vector2.RIGHT)
	var shield = game.player_model.get_node("ShieldHit")
	check(shield.visible and game.pilot.shield == 25, "player hit flashes shield without changing damage")
	game.update_shields(.2)
	game.damage_player(5,Vector2.LEFT)
	check(game.shield_hits.size() == 1 and shield.age == 0, "repeated hits refresh one envelope")
	game.set_mode("pause")
	game._physics_process(.2)
	check(shield.age == 0, "shield ripple pauses with combat")
	game.set_mode("flight")
	game.update_shields(.5)
	check(not shield.visible, "shield disappears after half a second")
	game.pilot.shield = 0
	game.damage_player(5)
	check(not shield.visible, "armor-only damage does not flash shields")
	var npc = game.traffic.spawn(130,130,3,game.pilot.position+Vector2(170,-80))
	game.damage_npc(npc,1,{},Vector2.LEFT)
	var other = npc.model.get_node("ShieldHit")
	check(other.visible, "NPC shield flashes while shield energy remains")
	game.update_shields(.5)
	npc.health = npc.max_health-npc.shield_capacity
	if npc.health > 1:
		game.damage_npc(npc,1)
		check(not other.visible, "depleted NPC shields stay hidden")
	game.pilot.shield = 30
	game.arsenal.fire(128,game.pilot.position,0,true)
	game.shots.back().position = game.pilot.position
	game.shots.back().velocity = Vector2(0,100)
	game.update_shots(.01)
	check(shield.visible, "projectile collision triggers shield envelope")
	game.update_shields(.5)
	game.pilot.shield = 180
	game.arsenal.fire_beam(142,game.pilot.position+Vector2(0,100),Vector2.UP,{}, {},true)
	check(shield.visible, "beam collision triggers shield envelope")
	game.update_shields(.5)
	game.pilot.cheat_invincibility = true
	game.pilot.shield = 30
	var armor_before: float = game.pilot.armor
	game.arsenal.fire(128,game.pilot.position,0,true)
	game.shots.back().position = game.pilot.position
	game.shots.back().velocity = Vector2(0,100)
	game.update_shots(.01)
	check(shield.visible and game.pilot.shield == 30 and game.pilot.armor == armor_before,"invincible projectile hit flashes shield without damage")
	game.update_shields(.5)
	game.arsenal.fire_beam(142,game.pilot.position+Vector2(0,100),Vector2.UP,{}, {},true)
	check(shield.visible and game.pilot.shield == 30 and game.pilot.armor == armor_before,"invincible beam hit flashes shield without damage")
	game.update_shields(.5)
	game.pilot.shield = 0
	game.damage_player(999,Vector2.LEFT)
	check(shield.visible and game.pilot.shield == 0 and game.pilot.armor == armor_before,"invincibility flashes shield even if enabled after shields were depleted")
	game.pilot.cheat_invincibility = false
	game.player_model.rotation.y = -PI/2
	shield.flash(Vector2.RIGHT)
	var local_hit: Vector3 = shield.material.get_shader_parameter("impact_direction")
	check(local_hit.z < -.98 and absf(local_hit.x) < .01,"world-space nose hit maps to front of rotated ship")
	shield.flash(Vector2.RIGHT*1000)
	check(local_hit.is_equal_approx(shield.material.get_shader_parameter("impact_direction")),"impact region is independent of attacker distance")
	game.player_model.rotation.y = 0
	shield.flash(Vector2.UP)
	if "--visual" in OS.get_cmdline_user_args():
		npc.health = npc.max_health
		npc.model.rotation.y = 0
		game.damage_npc(npc,1,{},Vector2.UP)
		game.camera.position = game.v3(game.pilot.position+Vector2(70,-40),1200)
		game.camera.size = 500
		game.hud._process(0)
		game.update_shields(.08)
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/shield-localized.png"))
	game.traffic.retire(npc)
	await process_frame
	game.update_shields(.1)
	check(game.shield_hits.size() == 1, "destroyed hull effects are cleaned safely")
	game.load_system()
	check(game.shield_hits.is_empty(), "system transition clears shield references")
	game.free()
	await process_frame
	print("SHIELD RESULT: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
