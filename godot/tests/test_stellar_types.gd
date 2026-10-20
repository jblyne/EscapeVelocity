extends SceneTree
var game
var count=0
var failures=0

func check(ok: bool, message: String) -> void:
	count+=1
	if ok: print("PASS: "+message)
	else:
		failures+=1;push_error("FAIL: "+message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-stellar-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.muted=true;game.traffic.enabled=false;root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	var c=game.catalog
	check(c.data.stellar_types.size()==34,"all 34 original stellar type labels and sprite definitions are imported")
	check(c.stellar_type(26).label=="Type 3 station" and c.stellar_type(26).sprite.id==2030,"Stardock Alpha resolves to its original station type and sprite reference")
	check(c.stellar_type(28).label=="Class D moon" and c.stellar_type(28).sprite.id==2034,"Luna resolves to its original Class D moon and sprite reference")
	var totals={"station":0,"moon":0,"planet":0}
	var all_known=true
	for obj in c.data.objects.values():
		var info=c.stellar_type(int(obj.fields.Type))
		all_known=all_known and info.label!="Unknown stellar object"
		totals[info.kind]+=1
	check(all_known and totals.station==17 and totals.moon==15 and totals.planet==75,"the full 107-object catalog classifies by data rather than names")
	var all_rendered=true
	for i in 34:
		var info=c.stellar_type(i)
		var node=game.StellarModels.create(game.world,Vector2.ZERO,info,i)
		all_rendered=all_rendered and node.get_meta("stellar_kind")==info.kind and node.get_child_count()>0
		node.free()
	check(all_rendered,"every original stellar type builds a valid modern model")
	game.pilot.system_id=129;game.pilot.position=Vector2(-150,250);game.load_system()
	var dock: Dictionary={};var moon: Dictionary={};var earth: Dictionary={};var mars: Dictionary={}
	for body in game.planets:
		match body.id:
			129: dock=body
			132: moon=body
			128: earth=body
			130: mars=body
	check(dock.kind=="station" and dock.radius==60 and dock.node.get_child_count()>10,"Sol contains a mechanical Stardock with the original relative station size")
	check(moon.kind=="moon" and moon.radius==30 and moon.node.get_child_count()==1,"Luna is a small solid moon without a cloud/atmosphere shell")
	var moon_mat=moon.node.get_child(0).material_override
	check(moon_mat.get_shader_parameter("surface_style")==1 and moon_mat.get_shader_parameter("crater_strength")==1.0,"Luna uses gray cratered rock with no oceans or clouds")
	check(earth.kind=="planet" and earth.radius==100 and earth.node.get_child_count()==2,"Earth retains its larger planet body and atmosphere")
	var mars_mat=mars.node.get_child(0).material_override
	check(mars_mat.get_shader_parameter("surface_style")==1 and mars_mat.get_shader_parameter("land_color").r>mars_mat.get_shader_parameter("land_color").b,"Mars uses a red rocky surface")
	game.landing_target=dock.id;game.pilot.position=dock.position;game.velocity=Vector2.ZERO
	game.land();game.land()
	check(game.mode=="dock" and game.docked_id==dock.id,"stardock clearance and docking still work over the station")
	game.launch()
	game.landing_target=moon.id;game.pilot.position=moon.position+Vector2(moon.radius+0.1,0);game.velocity=Vector2.ZERO
	game.land();game.land()
	check(game.mode=="flight","Luna landing is rejected just outside the visible moon")
	game.pilot.position=moon.position;game.velocity=Vector2(0,40);game.land()
	check(game.mode=="flight","Luna still requires slowing down before landing")
	game.velocity=Vector2.ZERO;game.land()
	check(game.mode=="dock" and game.docked_id==moon.id,"Luna clearance and landing work over the smaller moon")
	game.launch();game.save_game(false)
	var before=game.pilot.snapshot()
	game.load_game()
	# JSON roundtrips normalize integer/float variants inside untyped cargo arrays.
	check(JSON.parse_string(JSON.stringify(game.pilot.snapshot()))==JSON.parse_string(JSON.stringify(before)) and game.planets[1].kind=="station","pilot loading preserves progress and rebuilds correct stellar models")
	game.free();await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://../builds/test-stellar-pilot.json"))
	print("STELLAR RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
