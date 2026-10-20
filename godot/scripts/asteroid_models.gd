extends RefCounted

const ROCK_SHADER=preload("res://shaders/asteroid.gdshader")
const VARIANTS: int=12
static var meshes: Dictionary={}
static var materials: Dictionary={}

static func create(parent: Node3D, at: Vector3, radius: float, variant: int) -> MeshInstance3D:
	variant=posmod(variant,VARIANTS)
	if not meshes.has(variant): build(variant)
	var node=MeshInstance3D.new()
	node.mesh=meshes[variant]
	node.material_override=materials[variant]
	node.position=at
	node.scale=Vector3.ONE*radius
	parent.add_child(node)
	return node

static func build(variant: int) -> void:
	var rng=RandomNumberGenerator.new();rng.seed=variant*7919+481
	var noise=FastNoiseLite.new();noise.seed=variant*331+19;noise.frequency=1.1
	noise.fractal_octaves=2
	var craters: Array=[]
	for i in 9:
		var direction=Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)).normalized()
		craters.append({"direction":direction,"width":rng.randf_range(.16,.42),"depth":rng.randf_range(.07,.18)})
	var sphere=SphereMesh.new();sphere.radius=1;sphere.height=2;sphere.radial_segments=48;sphere.rings=28
	var arrays: Array=sphere.get_mesh_arrays()
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var largest: float=0
	for i in vertices.size():
		var direction: Vector3=vertices[i].normalized()
		var relief: float=1+noise.get_noise_3dv(direction)*.35+noise.get_noise_3dv(direction*3.7)*.055
		for crater in craters:
			var distance: float=direction.distance_to(crater.direction)/crater.width
			# Excavated bowls with a raised, weathered lip.
			relief-=crater.depth*exp(-distance*distance*3.2)
			relief+=.035*exp(-pow((distance-.95)*5,2))
		vertices[i]=direction*relief
		largest=maxf(largest,vertices[i].length())
	for i in vertices.size(): vertices[i]/=largest
	arrays[Mesh.ARRAY_VERTEX]=vertices
	var raw=ArrayMesh.new();raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface=SurfaceTool.new();surface.create_from(raw,0);surface.generate_normals()
	meshes[variant]=surface.commit()
	var material=ShaderMaterial.new();material.shader=ROCK_SHADER
	material.set_shader_parameter("rock_tint",[Color("736a5b"),Color("626365"),Color("81725f"),Color("555650")][variant%4])
	material.set_shader_parameter("seed_offset",float(variant)*13.73)
	materials[variant]=material
