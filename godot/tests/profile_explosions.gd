extends SceneTree

var game
var report: Dictionary = {"cases":[]}
var output_path: String
var component: String = "full"
var retained_materials: Array = []

func _initialize() -> void:
	call_deferred("run")

func sample_frames(count: int, advance_effect: bool) -> Array:
	var frames: Array = []
	for frame in count:
		var start: int = Time.get_ticks_usec()
		if advance_effect: game.update_explosions(1.0/60.0)
		await process_frame
		# Explicit rendering prevents the benchmark from waiting indefinitely when
		# macOS stops drawing an occluded window after the animation has expired.
		RenderingServer.force_draw(false,1.0/60.0)
		frames.append({"wall_ms":(Time.get_ticks_usec()-start)/1000.0,
			"cpu_ms":RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()),
			"gpu_ms":RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()),
			"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)})
	return frames

func run() -> void:
	output_path = ProjectSettings.globalize_path("res://../builds/explosion-profile.json")
	var args = OS.get_cmdline_user_args()
	for i in args.size():
		if args[i]=="--report" and i+1<args.size(): output_path=args[i+1]
		if args[i]=="--component" and i+1<args.size(): component=args[i+1]
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-explosion-profile.json")
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.set_process(false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	game.camera.position=game.v3(game.pilot.position,1200)
	report.viewport=var_to_str(root.size)
	report.adapter=RenderingServer.get_video_adapter_name()
	report.engine=Engine.get_version_info().string
	report.component=component
	await sample_frames(45,false)
	report.warmup_cleaned_up = game.get_node_or_null("ExplosionWarmup")==null
	report.startup_has_no_live_explosions = game.explosions.is_empty()
	report.baseline=await sample_frames(90,false)
	for trial in 3:
		for size in [24.0,31.0,60.0]:
			var source=game.Models.ship(Color("66a7ad"),size,true)
			if component=="no-debris":
				for child in source.get_children(): child.free()
			game.world.add_child(source)
			source.position=game.v3(game.pilot.position+Vector2(130,-130))
			await sample_frames(5,false)
			var begin: int=Time.get_ticks_usec()
			game.ship_explosion(source,game.pilot.position+Vector2(130,-130),Vector2(35,10))
			if component=="no-light": game.explosions.back().flash_light.visible=false
			if component=="retain-materials" and retained_materials.is_empty():
				for fragment in game.explosions.back().fragments:
					retained_materials.append(fragment.material)
			var creation_ms: float=(Time.get_ticks_usec()-begin)/1000.0
			source.queue_free()
			var frames=await sample_frames(220,true)
			var entry={"trial":trial,"ship_size":size,"creation_ms":creation_ms,"frames":frames}
			report.cases.append(entry)
			print("PROFILE trial=%d size=%.0f creation=%.3f ms first_render=%.3f ms" % [trial,size,creation_ms,frames[0].wall_ms])
			await sample_frames(15,false)
	# Exercise the flash-light variant used when several ships die together.
	var batch_begin: int=Time.get_ticks_usec()
	for i in 8:
		game.ship_explosion(game.player_model,game.pilot.position+Vector2((i%4)*75-110,(i/4)*75-100),Vector2.ZERO)
	var batch_creation: float=(Time.get_ticks_usec()-batch_begin)/1000.0
	var batch_frames=await sample_frames(220,true)
	report.batch={"count":8,"creation_ms":batch_creation,"frames":batch_frames}
	print("PROFILE batch=8 creation=%.3f ms first_render=%.3f ms" % [batch_creation,batch_frames[0].wall_ms])
	# Clearing the world must not evict the warmed material/shader variants.
	game.load_system()
	await sample_frames(15,false)
	var reload_begin: int=Time.get_ticks_usec()
	game.ship_explosion(game.player_model,game.pilot.position+Vector2(130,-130),Vector2.ZERO)
	var reload_creation: float=(Time.get_ticks_usec()-reload_begin)/1000.0
	var reload_frames=await sample_frames(220,true)
	report.after_reload={"creation_ms":reload_creation,"frames":reload_frames}
	print("PROFILE after_reload creation=%.3f ms first_render=%.3f ms" % [reload_creation,reload_frames[0].wall_ms])
	var f=FileAccess.open(output_path,FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	f.close()
	game.free()
	await process_frame
	print("Profile saved: ",output_path)
	quit()
