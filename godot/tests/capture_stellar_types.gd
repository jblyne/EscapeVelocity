extends SceneTree
var game

func _initialize() -> void:
	call_deferred("capture")

func save_image(label: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/stellar-%s.png" % label))

func capture() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/qa-stellar-types.json")
	game.muted=true
	root.add_child(game)
	game.set_physics_process(false);game.set_process(false);game.hud.set_process(false)
	game.pilot.system_id=129
	game.pilot.position=Vector2(-150,250)
	game.load_system()
	game.camera.position=game.v3(game.pilot.position,1200)
	game.hud._process(0)
	await save_image("sol")
	game.hud.root.hide()
	game.world.free()
	game.world=Node3D.new();game.add_child(game.world)
	game.camera.position=Vector3(0,1200,0)
	game.camera.size=900
	var labels=CanvasLayer.new();game.add_child(labels)
	var types=[24,25,26,27,28,20,0,6,13,16,23,29]
	for i in types.size():
		var info=game.catalog.stellar_type(types[i])
		var pos=Vector2((i%4-1.5)*310,(floori(i/4.0)-1)*275)
		var node=game.StellarModels.create(game.world,pos,info,132 if types[i]==28 else 128+types[i])
		var label=Label.new();labels.add_child(label)
		label.text=("Luna" if types[i]==28 else ("Stardock Alpha" if types[i]==26 else info.label))
		label.add_theme_font_size_override("font_size",17)
		label.position=game.camera.unproject_position(game.v3(pos+Vector2(-100,120)))
	await save_image("types")
	game.free()
	await process_frame
	print("Stellar model visual capture complete.")
	quit()
