extends SceneTree
var game

func _initialize() -> void: call_deferred("run")

func capture(label: String) -> void:
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/ship-detail-%s.png" % label))

func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-ship-detail.json")
	game.muted=true;game.traffic.enabled=false;root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	for frame in 6: await process_frame
	game.pilot.system_id=129;game.pilot.position=Vector2(-400,450);game.load_system()
	game.camera.position=game.v3(game.pilot.position,1200)
	for i in 4:
		game.traffic.spawn([134,141,130,136][i],[128,129,-1,128][i],1,game.pilot.position+Vector2(-330+i*200,-180))
	game.target_index=0;game.hud._process(0)
	await capture("flight")
	game.hud.root.hide();game.planets.clear();game.npcs.clear();game.world.free()
	game.world=Node3D.new();game.add_child(game.world)
	game.camera.position=Vector3(0,1200,0);game.camera.size=660
	var labels=CanvasLayer.new();game.add_child(labels)
	var title=Label.new();labels.add_child(title);title.text="ESCAPE VELOCITY HD   /   FLEET DETAIL"
	title.position=Vector2(34,22);title.add_theme_font_size_override("font_size",22)
	var roster=[128,136,134,130,142,150]
	for i in roster.size():
		var id=roster[i];var record=game.catalog.record("ships",id)
		var pos=Vector2((i%3-1)*320,(floori(i/3.0)-.5)*310)
		var model=game.ShipModels.create(game.catalog,id,int(record.fields.InherentGovt))
		game.world.add_child(model);model.position=game.v3(pos);model.scale=Vector3.ONE*86
		model.rotation=Vector3(.22,-.30,0);game.Models.set_thrust(model,0,0)
		var label=Label.new();labels.add_child(label);label.text=record.name
		label.add_theme_font_size_override("font_size",19)
		label.position=game.camera.unproject_position(game.v3(pos+Vector2(-85,123)))
	await capture("showcase")
	for child in labels.get_children(): child.queue_free()
	for child in game.world.get_children(): child.queue_free()
	await process_frame
	game.camera.size=1000
	var ids=game.catalog.data.ships.keys();ids.sort_custom(func(a,b):return int(a)<int(b))
	var max_parts=0;var max_triangles=0
	for i in ids.size():
		var id=int(ids[i]);var record=game.catalog.record("ships",id)
		var pos=Vector2((i%6-2.5)*235,(floori(i/6.0)-2)*170)
		var model=game.ShipModels.create(game.catalog,id,int(record.fields.InherentGovt))
		game.world.add_child(model);model.position=game.v3(pos);game.Models.set_thrust(model,0,0)
		var count=0
		for mesh in model.get_children():
			var arrays=mesh.mesh.surface_get_arrays(0)
			count+=(arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null and arrays[Mesh.ARRAY_INDEX].size()>0 else arrays[Mesh.ARRAY_VERTEX].size())/3
		max_parts=maxi(max_parts,model.get_child_count());max_triangles=maxi(max_triangles,count)
		var label=Label.new();labels.add_child(label);label.text=record.name
		label.add_theme_font_size_override("font_size",14)
		label.position=game.camera.unproject_position(game.v3(pos+Vector2(-100,77)))
	await capture("roster")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var timings=[]
	for frame in 90:
		await process_frame
		var started=Time.get_ticks_usec();RenderingServer.force_draw(false)
		timings.append((Time.get_ticks_usec()-started)/1000.0)
	timings.sort()
	print("27-ship draw median %.3f ms / p95 %.3f ms; maximum %d parts / %d triangles per ship" % [timings[45],timings[85],max_parts,max_triangles])
	var source=game.ShipModels.create(game.catalog,134,128);game.world.add_child(source)
	await process_frame
	var started=Time.get_ticks_usec();game.ship_explosion(source,Vector2.ZERO,Vector2.ZERO)
	if "--no-light" in OS.get_cmdline_user_args(): game.explosions.back().flash_light.visible=false
	if "--no-debris" in OS.get_cmdline_user_args():
		for fragment in game.explosions.back().fragments: fragment.node.hide()
	print("Explosion creation: %.3f ms, keepers %s" % [(Time.get_ticks_usec()-started)/1000.0,game.Explosion.shader_keepers.keys()])
	source.queue_free();RenderingServer.force_draw(false)
	print("Cruiser first explosion creation + draw: %.3f ms" % ((Time.get_ticks_usec()-started)/1000.0))
	game.update_explosions(.4);await capture("explosion")
	game.free();await process_frame;quit()
