extends SceneTree
var game

func _initialize() -> void:
	call_deferred("capture")

func screenshot(name: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/fleet-%s.png" % name))

func capture() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-fleet-capture.json")
	game.muted=true;game.traffic.enabled=false
	root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	game.pilot.system_id=129;game.pilot.position=Vector2(-400,450);game.load_system()
	game.camera.position=game.v3(game.pilot.position,1200)
	var roster=[134,135,139,130,133]
	for i in roster.size():
		game.traffic.spawn(roster[i],128,int(game.catalog.field("ships",roster[i],"InherentAI")),game.pilot.position+Vector2(-440+i*160,-190-(i%2)*120))
	game.target_index=0;game.hud._process(0)
	await screenshot("sol")
	game.set_mode("cheats")
	await screenshot("cheats")
	root.size=Vector2i(1100,740)
	await screenshot("cheats-minimum")
	game.set_mode("flight");game.hud._process(0)
	await screenshot("panel-minimum")
	root.size=Vector2i(1440,900)
	game.hud.root.hide()
	game.world.free();game.world=Node3D.new();game.add_child(game.world)
	game.npcs.clear();game.planets.clear();game.target_index=-1
	game.camera.position=Vector3(0,1200,0);game.camera.size=1000
	var labels=CanvasLayer.new();game.add_child(labels)
	var title=Label.new();labels.add_child(title)
	title.text="ORIGINAL ESCAPE VELOCITY SHIP ROSTER  ·  27 RECORDS"
	title.position=Vector2(34,20);title.add_theme_font_size_override("font_size",24)
	var ids=game.catalog.data.ships.keys();ids.sort_custom(func(a,b):return int(a)<int(b))
	for i in ids.size():
		var ship=game.catalog.record("ships",int(ids[i]))
		var pos=Vector2((i%6-2.5)*235,(floori(i/6.0)-2)*170)
		var faction=int(ship.fields.InherentGovt)
		var model=game.ShipModels.create(game.catalog,int(ids[i]),faction)
		game.world.add_child(model);model.position=game.v3(pos)
		game.Models.set_thrust(model,0,0)
		var label=Label.new();labels.add_child(label)
		label.text=ship.name+(" (alternate)" if int(ids[i])==152 else "")
		label.add_theme_font_size_override("font_size",14)
		label.position=game.camera.unproject_position(game.v3(pos+Vector2(-100,77)))
	await screenshot("roster")
	# Explicit draws capture the first explosion frame and a busy fleet's CPU cost.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var source=game.ShipModels.create(game.catalog,134,128)
	game.world.add_child(source)
	await screenshot("before-explosion")
	var started=Time.get_ticks_usec()
	game.ship_explosion(source,Vector2.ZERO,Vector2.ZERO);source.queue_free()
	RenderingServer.force_draw(false)
	print("FLEET first explosion creation+draw: %.3f ms" % ((Time.get_ticks_usec()-started)/1000.0))
	for i in 30:
		game.update_explosions(1.0/60)
		await process_frame
		RenderingServer.force_draw(false)
	game.free();await process_frame
	print("Fleet visual captures complete")
	quit()
