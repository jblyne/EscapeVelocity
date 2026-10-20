class_name EVModels
extends RefCounted

# Keep the warmed lighting variants resident across empty-system transitions.
const EXHAUST_SHADER = preload("res://shaders/exhaust.gdshader")
const PLANET_SHADER = preload("res://shaders/planet.gdshader")
const ATMOSPHERE_SHADER = preload("res://shaders/atmosphere.gdshader")

static func material(color: Color, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.38 if metal > 0 else 0.8
	if glow > 0:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mat
	n.position = at
	parent.add_child(n)
	return n

static func sphere(parent: Node3D, at: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 48
	mesh.rings = 24
	n.mesh = mesh
	n.material_override = mat
	n.position = at
	parent.add_child(n)
	return n

static func hull(parent: Node3D, points: PackedVector2Array, thickness: float, mat: Material) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris = Geometry2D.triangulate_polygon(points)
	for i in range(0, tris.size(), 3):
		for j in [2, 1, 0]:
			var p = points[tris[i+j]]
			st.add_vertex(Vector3(p.x, thickness, p.y))
		for j in [0, 1, 2]:
			var p = points[tris[i+j]]
			st.add_vertex(Vector3(p.x, 0, p.y))
	for i in points.size():
		var a = points[i]
		var b = points[(i+1) % points.size()]
		for v in [Vector3(a.x,0,a.y), Vector3(a.x,thickness,a.y), Vector3(b.x,thickness,b.y), Vector3(a.x,0,a.y), Vector3(b.x,thickness,b.y), Vector3(b.x,0,b.y)]:
			st.add_vertex(v)
	st.generate_normals()
	var n = MeshInstance3D.new()
	n.mesh = st.commit()
	# Both faces are visible; a silhouette is built from a clockwise 2D outline.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	n.material_override = mat
	parent.add_child(n)
	return n

static func ship(color: Color, scale_size: float = 25.0, heavy: bool = false) -> Node3D:
	var root = Node3D.new()
	var steel = material(Color("718496"), 0.75)
	var dark = material(Color("192a3e"), 0.65)
	var trim = material(color, 0.6)
	var glass = material(Color("57cee7"), 0.3, 0.3)
	var glow = material(Color("81eaff"), 0, 2)
	hull(root, PackedVector2Array([Vector2(0,-1.25), Vector2(0.32,-0.5), Vector2(0.38,0.8), Vector2(-0.38,0.8), Vector2(-0.32,-0.5)]), 0.28, steel)
	hull(root, PackedVector2Array([Vector2(-0.25,-0.45), Vector2(-0.9,0.55), Vector2(-0.9,0.85), Vector2(0.9,0.85), Vector2(0.9,0.55), Vector2(0.25,-0.45)]), 0.1, dark)
	box(root, Vector3(0,0.3,0.1), Vector3(0.35,0.07,0.65), trim)
	box(root, Vector3(0,0.33,-0.48), Vector3(0.26,0.06,0.32), glass)
	for side in [-1, 1]:
		box(root, Vector3(side * 0.62,0.08,0.38), Vector3(0.24,0.24,1.15), steel)
		box(root, Vector3(side * 0.62,0.22,0.5), Vector3(0.13,0.04,0.65), trim)
		box(root, Vector3(side * 0.62,0.06,0.98), Vector3(0.16,0.16,0.08), glow)
		box(root, Vector3(side * 0.78,0.15,-0.1), Vector3(0.06,0.08,0.7), dark)
		for slot in 4:
			box(root, Vector3(side * 0.62,0.255,0.24 + slot*0.16), Vector3(0.16,0.025,0.03), dark)
		add_exhaust(root,Vector3(side*0.62,0.05,1.02),side)
	if heavy:
		box(root, Vector3(0,0.3,0.25), Vector3(0.85,0.3,1.15), steel)
	root.scale = Vector3.ONE * scale_size
	return root

static func add_exhaust(root: Node3D, nozzle: Vector3, side: int) -> void:
	var flame = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(0.48,1.4)
	flame.mesh = plane
	var mat = ShaderMaterial.new()
	mat.shader = EXHAUST_SHADER
	mat.resource_local_to_scene = true
	mat.set_shader_parameter("engine_phase",float(side)*2.71)
	flame.material_override = mat
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.name = "Flame"+str(side)
	flame.set_meta("nozzle",nozzle)
	flame.position = nozzle+Vector3(0,0,0.7)
	root.add_child(flame)

static func set_thrust(model: Node3D, power: float, clock: float, hyperdrive_vibration: bool = false) -> void:
	for n in model.get_children():
		if str(n.name).begins_with("Flame"):
			n.visible = power > 0.02
			var pulse: float = sin(clock*48)*0.15 if hyperdrive_vibration else 0.0
			var length_scale: float = 0.35+power*(0.65+pulse)
			n.scale = Vector3(0.8+power*0.2,1.0,length_scale)
			if n.has_meta("nozzle"):
				n.position = n.get_meta("nozzle")+Vector3(0,0,0.7*length_scale)
			if n.material_override is ShaderMaterial:
				n.material_override.set_shader_parameter("clock",clock)
				n.material_override.set_shader_parameter("power",power)

static func planet(parent: Node3D, at: Vector3, radius: float, seed_value: int, appearance: Dictionary = {}) -> Node3D:
	var root = Node3D.new()
	root.position = at
	parent.add_child(root)
	var mat = ShaderMaterial.new()
	mat.shader = PLANET_SHADER
	mat.set_shader_parameter("seed_value", float(seed_value))
	var earthlike = seed_value % 4 < 2
	mat.set_shader_parameter("ocean_color", Color("082b49") if earthlike else Color("493027"))
	mat.set_shader_parameter("land_color", Color("527566") if earthlike else Color("9e7050"))
	for key in appearance:
		if key not in ["atmosphere","atmosphere_color"]: mat.set_shader_parameter(key,appearance[key])
	var globe = sphere(root, Vector3.ZERO, radius, mat)
	globe.name = "Surface"
	if appearance.get("atmosphere",true):
		var atm = ShaderMaterial.new()
		atm.shader = ATMOSPHERE_SHADER
		if appearance.has("atmosphere_color"): atm.set_shader_parameter("atmosphere_color",appearance.atmosphere_color)
		var atmosphere=sphere(root, Vector3.ZERO, radius * 1.06, atm)
		atmosphere.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root
