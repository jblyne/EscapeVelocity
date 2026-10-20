extends Node3D
# Ballistic remains: no drag or settling. The system's normal scene cleanup
# removes this bounded set of shards when the player leaves.
const Models=preload("res://scripts/models.gd")
const Rocks=preload("res://scripts/asteroid_models.gd")
var age: float=0
var shards: Array=[]
var hot_materials: Array=[]

func torn_plate(offset: Vector3,rng: RandomNumberGenerator,metal: Material,hot: Material) -> Node3D:
	var root=Node3D.new();root.position=offset;add_child(root)
	var points: Array[Vector3]=[]
	for i in 6:
		var angle: float=float(i)*TAU/6
		points.append(Vector3(cos(angle)*rng.randf_range(5,12),rng.randf_range(-1,1),sin(angle)*rng.randf_range(5,14)))
	var top=SurfaceTool.new();top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges=SurfaceTool.new();edges.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var a: Vector3=points[i];var b: Vector3=points[(i+1)%6]
		for point in [Vector3.ZERO,b,a]: top.add_vertex(point)
		for point in [Vector3(0,-1.6,0),a-Vector3.UP*1.6,b-Vector3.UP*1.6]: top.add_vertex(point)
		for point in [a,b,a-Vector3.UP*1.6,b,b-Vector3.UP*1.6,a-Vector3.UP*1.6]: edges.add_vertex(point)
	for item in [[top,metal],[edges,hot]]:
		item[0].generate_normals()
		var mesh=MeshInstance3D.new();mesh.mesh=item[0].commit();mesh.material_override=item[1];root.add_child(mesh)
	if rng.randf()<.4:
		Models.box(root,Vector3(0,1,0),Vector3(1.2,1.4,rng.randf_range(12,22)),metal)
	return root
func setup(origin: Vector3,radius: float,seed_value: int,metallic: bool=false) -> void:
	position=origin
	var rng=RandomNumberGenerator.new();rng.seed=seed_value*571
	var rock=Models.material(Color("4b5358"),.65);rock.roughness=.85;rock.cull_mode=BaseMaterial3D.CULL_DISABLED
	var hot=Models.material(Color("8e3318"),.2);hot.emission_enabled=true;hot.emission=Color("ff5b12");hot.emission_energy_multiplier=.8;hot.cull_mode=BaseMaterial3D.CULL_DISABLED
	if metallic: hot_materials.append(hot)
	for i in 28:
		var angle: float=rng.randf_range(0,TAU)
		var direction=Vector3(cos(angle),rng.randf_range(-.25,.25),sin(angle)).normalized()
		var offset: Vector3=direction*radius*rng.randf_range(.65,1.0)
		var node: Node3D
		if metallic: node=torn_plate(offset,rng,rock,hot)
		else:
			node=Rocks.create(self,offset,rng.randf_range(3,12),i+seed_value)
			var material: ShaderMaterial=node.material_override.duplicate()
			material.set_shader_parameter("charred",1.0);material.set_shader_parameter("ember_heat",.65)
			node.material_override=material;hot_materials.append(material)
			node.scale*=Vector3(1,.6,rng.randf_range(.8,1.8))
		node.rotation=Vector3(rng.randf(),rng.randf(),rng.randf())*TAU
		var spin=Vector3(rng.randf_range(-.8,.8),rng.randf_range(-1.2,1.2),rng.randf_range(-.8,.8))
		shards.append({"node":node,"origin":offset,"velocity":direction*radius*rng.randf_range(.65,1.3),"spin":spin,"rotation":node.rotation})
func advance(dt: float) -> void:
	age+=dt
	for shard in shards:
		shard.node.position=shard.origin+shard.velocity*age
		shard.node.rotation=shard.rotation+shard.spin*age
	for material in hot_materials:
		if material is ShaderMaterial: material.set_shader_parameter("ember_heat",.65*exp(-age*.10))
		else: material.emission_energy_multiplier=.8*exp(-age*.10)
