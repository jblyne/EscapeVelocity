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
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-hector-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	var cameo=game.hector
	check(cameo.remaining>=180 and cameo.remaining<=360,"first appearance waits several minutes")
	cameo.remaining=1
	game.set_mode("pause")
	cameo.advance(10)
	check(cameo.remaining==1,"pause does not advance encounter timer")
	game.set_mode("flight")
	game.hyperdrive.phase="spooling"
	cameo.advance(10)
	check(cameo.remaining==1,"hyperspace defers Hector encounter")
	game.hyperdrive.reset()
	cameo.advance(.5)
	check(game.npcs.is_empty(),"Hector does not appear early")
	cameo.advance(.5)
	var hector: Dictionary=game.npcs[0]
	check(hector.id==136 and hector.name=="Cap'n Hector" and hector.hector,"original character appears in a Rapier")
	check(cameo.remaining>=360 and cameo.remaining<=600,"next visit has a long randomized cooldown")
	game.hud._process(0)
	check(game.hud.hector_banner.visible and game.hud.hector_banner.text.contains("shareware fee"),"shareware reminder appears on main game screen")
	check(not cameo.spawn() and game.npcs.size()==1,"Hector cannot spawn duplicates")
	var before: Vector2=hector.position
	game.traffic.update(.1)
	check(hector.position!=before and not hector.hostile and game.shots.is_empty(),"Hector flies visibly without attacking")
	var reputation: Dictionary=game.pilot.reputation.duplicate()
	game.damage_npc(hector,100000)
	check(hector in game.npcs and hector.health==hector.max_health and game.pilot.reputation==reputation,"cameo survives attacks without reputation penalties")
	game.target_index=game.npcs.find(hector)
	game.interactions.open_hail()
	check(game.interactions.response.contains("shareware fee"),"hailing Hector gets the shareware reminder")
	game.interactions.close()
	if "--visual" in OS.get_cmdline_user_args():
		game.camera.position=game.v3(game.pilot.position+Vector2(100,-40),1200)
		game.camera.size=700
		game.hud._process(0)
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/hector-cameo.png"))
	cameo.advance(10)
	game.hud._process(0)
	check(not game.hud.hector_banner.visible,"broadcast clears after ten seconds")
	hector.age=31
	game.traffic.update(.01)
	check(hector in game.npcs and hector.has("departure"),"Hector begins a real departure after brief visit")
	for tick in 9000:
		if hector not in game.npcs: break
		game.traffic.update(1.0/60)
	check(hector not in game.npcs,"Hector leaves after completing his hyperdrive sequence")
	var cooldown: float=cameo.remaining
	game.load_system()
	check(cameo.remaining==cooldown,"changing systems does not reset rarity timer")
	while game.npcs.size()<game.traffic.MAX_CONTACTS:
		game.traffic.spawn(128,-1,1,Vector2(3000,3000))
	cameo.remaining=0
	cameo.advance(.1)
	check(cameo.remaining==15 and not game.npcs.any(func(npc):return npc.get("hector",false)),"full traffic safely postpones appearance")
	game.free()
	await process_frame
	print("HECTOR RESULT: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
