extends SceneTree
const Rebuilt=preload("res://scripts/rebuilt_world.gd")
var viewport: SubViewport
var stage: Node3D
var camera: Camera3D
var catalog
var manifest: Array=[]
var checks: int=0
func _initialize(): call_deferred("run")
func run():
 catalog=preload("res://scripts/catalog.gd").new()
 viewport=SubViewport.new();viewport.size=Vector2i(960,780);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
 var environment=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("030812");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("8ba3b8");env.ambient_light_energy=.9;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;environment.environment=env;viewport.add_child(environment)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-38,-38,0);sun.light_color=Color("f4e4cc");sun.light_energy=2.8;viewport.add_child(sun)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-12,145,0);fill.light_color=Color("71b7e9");fill.light_energy=1.3;viewport.add_child(fill)
 camera=Camera3D.new();camera.current=true;camera.fov=56;viewport.add_child(camera)
 for folder in ["landing","orbital"]: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/reconstruction/"+folder))
 var ids: Array=catalog.data.objects.keys();ids.sort_custom(func(a,b):return int(a)<int(b))
 var limit: int=ids.size()
 if "--preview" in OS.get_cmdline_user_args(): ids=["128","129"]
 for key in ids:
  var id: int=int(key);var record: Dictionary=catalog.record("objects",id)
  var station: bool=catalog.stellar_type(int(record.fields.Type)).kind=="station"
  for phase in range(1,5):
   stage=Node3D.new();viewport.add_child(stage)
   Rebuilt.landing_scene(stage,id,station,phase)
   camera.position=Vector3(5+float(id%5),14,34);camera.look_at(Vector3(-2+float(id%7),12,-52))
   viewport.size=Vector2i(960,780)
   await capture(id,phase,"landing")
   stage.free();stage=Node3D.new();viewport.add_child(stage)
   Rebuilt.create(stage,Vector3.ZERO,10,id,station,float(phase)/4)
   camera.position=Vector3(16,13,22);camera.look_at(Vector3.ZERO)
   viewport.size=Vector2i(512,512)
   await capture(id,phase,"orbital")
   stage.free()
  print("RECONSTRUCTION ART: ",manifest.size()," images · ",record.name," (",id,") / ",limit)
 var file=FileAccess.open("res://assets/reconstruction/manifest.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"renderer":"rebuilt_world.gd","steel_material":"steel_panels.png","soil_material":"reclaimed_soil.png","prompt_set":"art_direction.json","milestones_days":[20,40,60,80],"images":manifest},"\t"));file.close()
 print("RECONSTRUCTION ART COMPLETE: ",manifest.size()," unique images")
 quit()
func capture(id: int,phase: int,kind: String):
 await process_frame
 await RenderingServer.frame_post_draw
 await process_frame
 await RenderingServer.frame_post_draw
 var path: String="res://assets/reconstruction/%s/%d_%d.webp" % [kind,id,phase]
 var image: Image=viewport.get_texture().get_image()
 var error: int=image.save_webp(ProjectSettings.globalize_path(path),true,.88)
 if error!=OK: push_error("Cannot save "+path);quit(1);return
 manifest.append({"world":id,"phase":phase,"view":kind,"file":path,"width":image.get_width(),"height":image.get_height()})
