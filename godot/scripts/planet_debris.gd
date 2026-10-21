extends Node3D
# Fresh blast shards are ballistic. Revisited worlds restore a stable, cold
# remnant field at the original location, with slow tumbling and bounded local drift.
const Models=preload("res://scripts/models.gd")
const Rocks=preload("res://scripts/asteroid_models.gd")
var age: float=0
var settled: bool=false
var shards: Array=[]
var hot_materials: Array=[]

func torn_plate(offset: Vector3,rng: RandomNumberGenerator,metal: Material,hot: Material,kind: int=0) -> Node3D:
	var root=Node3D.new();root.position=offset;add_child(root)
	var dark=Models.material(Color("20282c"),.55);dark.roughness=.9
	if kind%4==1:
		# Broken pressure module with exposed ribs and a ragged open end.
		Models.box(root,Vector3.ZERO,Vector3(11,8,19),dark)
		for side in [-1,1]:
			Models.box(root,Vector3(side*6,2,-2),Vector3(1.2,9,17),metal)
		for z in [-7,-1,5]:
			Models.box(root,Vector3(0,5,z),Vector3(13,1.2,1.4),metal)
		for i in 3:
			var rib=Models.box(root,Vector3(i*4-4,1,11),Vector3(.9,7,rng.randf_range(5,11)),metal)
			rib.rotation.x=rng.randf_range(-.4,.4)
		return root
	if kind%4==2:
		# A curved section of the station's structural ring.
		for i in 5:
			var angle: float=(i-2)*.25
			var at=Vector3(sin(angle)*24,0,cos(angle)*24-22)
			var beam=Models.box(root,at,Vector3(7,4,4),metal);beam.rotation.y=-angle
			var inset=Models.box(root,at+Vector3(0,2.3,0),Vector3(5,.6,2.6),dark);inset.rotation.y=-angle
		return root
	if kind%4==3:
		# Torn equipment/solar panel with its supporting truss still attached.
		Models.box(root,Vector3.ZERO,Vector3(19,1,13),dark)
		for x in [-8,-4,0,4,8]: Models.box(root,Vector3(x,.8,0),Vector3(.6,.8,14),metal)
		for z in [-6,0,6]: Models.box(root,Vector3(0,1,z),Vector3(20,.6,.5),metal)
		var spar=Models.box(root,Vector3(4,-2,4),Vector3(2,3,25),metal);spar.rotation.y=.35
		return root
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
func setup(origin: Vector3,radius: float,seed_value: int,metallic: bool=false,restored: bool=false) -> void:
	settled=restored
	position=origin
	var rng=RandomNumberGenerator.new();rng.seed=seed_value*571
	var rock=Models.material(Color("4b5358"),.65);rock.roughness=.85;rock.cull_mode=BaseMaterial3D.CULL_DISABLED
	var hot=Models.material(Color("503b30"),.2);hot.emission_enabled=true;hot.emission=Color("ff5b12");hot.emission_energy_multiplier=.22;hot.cull_mode=BaseMaterial3D.CULL_DISABLED
	if metallic: hot_materials.append(hot)
	for i in 28:
		var angle: float=rng.randf_range(0,TAU)
		var direction=Vector3(cos(angle),rng.randf_range(-.25,.25),sin(angle)).normalized()
		var offset: Vector3=direction*radius*sqrt(rng.randf_range(.04,1.45))
		var node: Node3D
		if metallic: node=torn_plate(offset,rng,rock,hot,i)
		else:
			node=Rocks.create(self,offset,rng.randf_range(3,12),i+seed_value)
			var material: ShaderMaterial=node.material_override.duplicate()
			material.set_shader_parameter("charred",1.0);material.set_shader_parameter("ember_heat",.65)
			node.material_override=material;hot_materials.append(material)
			node.scale*=Vector3(1,.6,rng.randf_range(.8,1.8))
		node.rotation=Vector3(rng.randf(),rng.randf(),rng.randf())*TAU
		var spin=Vector3(rng.randf_range(-.8,.8),rng.randf_range(-1.2,1.2),rng.randf_range(-.8,.8))
		shards.append({"node":node,"origin":offset,"velocity":direction*radius*rng.randf_range(.65,1.3),"spin":spin,"rotation":node.rotation,
			"drift":Vector3(rng.randf_range(.028,.055),.012,rng.randf_range(.028,.055))*radius,
			"phase":Vector3(rng.randf(),rng.randf(),rng.randf())*TAU,
			"frequency":rng.randf_range(.035,.075)})
		# Leave a small wreckage core from a station even during the live blast.
		if metallic and i%4==0: shards.back().velocity=Vector3.ZERO
	if settled: advance(0)
func advance(dt: float) -> void:
	age+=dt
	for shard in shards:
		var anchored: bool=settled or shard.velocity==Vector3.ZERO
		if anchored:
			var phase: Vector3=shard.phase
			var clock: float=age*shard.frequency
			var drift=Vector3(sin(clock+phase.x)-sin(phase.x),sin(clock*.7+phase.y)-sin(phase.y),cos(clock*.83+phase.z)-cos(phase.z))
			shard.node.position=shard.origin+drift*shard.drift
		else: shard.node.position=shard.origin+shard.velocity*age
		shard.node.rotation=shard.rotation+shard.spin*age*(.16 if anchored else 1.0)
	for material in hot_materials:
		if material is ShaderMaterial: material.set_shader_parameter("ember_heat",0.0 if settled else .65*exp(-age*.10))
		else: material.emission_energy_multiplier=0.0 if settled else .22*exp(-age*.10)
