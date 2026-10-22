extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(1200,900)
 var world=Node3D.new();root.add_child(world)
 var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("202b38");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.8;env.environment=e;world.add_child(env)
 var light=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=2
 var model=load("res://scripts/ship_models.gd").build(128,Color("a8b5c0"));world.add_child(model)
 var camera=Camera3D.new();world.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.4;camera.position=Vector3(2,3,-3);camera.look_at(Vector3.ZERO);camera.current=true
 for frame in 6: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/shuttle-model-reference.png"))
 world.free();quit()
