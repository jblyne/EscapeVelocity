extends RefCounted

const Models = preload("res://scripts/models.gd")
static var ring_material: StandardMaterial3D

static func radius(info: Dictionary) -> float:
	# Preserve the remake's 100-unit planets and the original sprite proportions:
	# planet 80 px, station 48 px, moon 24 px.
	return float(info.sprite.width) * 1.25

static func create(parent: Node3D, at: Vector2, info: Dictionary, seed_value: int) -> Node3D:
	var size = radius(info)
	var node: Node3D
	if info.kind == "station":
		node = station(parent,Vector3(at.x,-35,at.y),size,int(info.id)-24)
	else:
		node = Models.planet(parent,Vector3(at.x,-size-35,at.y),size,seed_value,surface(info,seed_value))
		var rng = RandomNumberGenerator.new()
		rng.seed = seed_value * 3571
		# One turn takes roughly 9–20 minutes, with moons rotating more slowly.
		var degrees_per_second = rng.randf_range(0.3,0.5) if info.kind == "moon" else rng.randf_range(0.45,0.7)
		node.set_meta("spin_rate",deg_to_rad(degrees_per_second))
		if int(info.id)==23:
			add_rings(node,size)
			# The shader's poles lie on local Z; align them with the ring normal.
			node.get_node("Surface").rotation.x = 1.1-PI/2
	node.set_meta("stellar_kind",info.kind)
	node.set_meta("stellar_type",int(info.id))
	return node

static func advance_rotation(node: Node3D, dt: float) -> void:
	if not node.has_meta("spin_rate"): return
	# Turn the textured globe about its polar axis, leaving the world position,
	# atmosphere and rings fixed. Lighting continues to come from the world sun.
	var globe: Node3D = node.get_node("Surface")
	globe.rotate_object_local(Vector3.BACK,float(node.get_meta("spin_rate"))*dt)

static func surface(info: Dictionary, seed_value: int) -> Dictionary:
	var result = {"ocean_color":Color("082b49"),"land_color":Color("527566"),"land_level":0.48,
		"surface_style":0,"cloud_amount":1.0,"ice_amount":1.0,"crater_strength":0.0,"atmosphere":true}
	match int(info.id):
		2,4,31:
			result.land_level=0.4;result.land_color=Color("747755");result.cloud_amount=0.35
		5,6,7,8,32:
			result.land_level=0.65;result.land_color=Color("66885a");result.cloud_amount=0.65
		9:
			result.ocean_color=Color("302b54");result.land_color=Color("a47d46");result.cloud_amount=0.25
		10,11:
			result.surface_style=1;result.land_color=Color("b0925a");result.crater_strength=0.15;result.atmosphere=false
		12,13:
			result.ocean_color=Color("3e729e");result.land_color=Color("c9dce2");result.land_level=0.38;result.cloud_amount=0.3;result.ice_amount=1.15
		14,15:
			result.surface_style=2;result.land_color=Color("678e38") if int(info.id)==14 else Color("a483a3");result.ocean_color=Color("214c36") if int(info.id)==14 else Color("497c57")
		16,17,18:
			result.surface_style=2
			result.land_color=[Color("a64735"),Color("75a352"),Color("465dba")][int(info.id)-16]
			result.ocean_color=[Color("5f281c"),Color("34523b"),Color("1e2859")][int(info.id)-16]
		19,20,33:
			result.surface_style=1;result.land_color=Color("b85d36");result.crater_strength=0.55;result.atmosphere=false
		21,22,28:
			result.surface_style=1;result.land_color=Color("939496");result.crater_strength=1.0;result.atmosphere=false
		23:
			result.land_color=Color("738553");result.cloud_amount=0.4
	if result.surface_style==2: result.atmosphere_color=result.land_color.lightened(0.25)
	if result.surface_style==1:
		var rng=RandomNumberGenerator.new();rng.seed=seed_value*7919
		var craters=PackedVector4Array()
		for i in 32:
			# Equal-area distribution of impact centers over the entire sphere.
			var y=rng.randf_range(-1,1);var angle=rng.randf_range(0,TAU)
			var r=sqrt(1-y*y)
			craters.append(Vector4(r*cos(angle),y,r*sin(angle),rng.randf_range(0.055,0.22)))
		result.craters=craters
	return result

static func cylinder(parent: Node3D, at: Vector3, size: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh=CylinderMesh.new()
	mesh.top_radius=size;mesh.bottom_radius=size;mesh.height=height;mesh.radial_segments=32;mesh.rings=1
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;node.position=at
	parent.add_child(node)
	return node

static func ring(parent: Node3D, at: Vector3, inner: float, outer: float, mat: Material) -> MeshInstance3D:
	var mesh=TorusMesh.new();mesh.inner_radius=inner;mesh.outer_radius=outer;mesh.rings=48;mesh.ring_segments=8
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;node.position=at
	parent.add_child(node)
	return node

static func station(parent: Node3D, at: Vector3, size: float, variant: int) -> Node3D:
	var node=Node3D.new();node.position=at;parent.add_child(node)
	var steel=Models.material(Color("9ba7b0"),0.75)
	var dark=Models.material(Color("273849"),0.65)
	var gold=Models.material(Color("b69d62"),0.6)
	var lamps=Models.material(Color("ffcf78"),0,1.3)
	var blue=Models.material(Color("6fe0ed"),0,1.2)
	if variant<=1:
		for level in (2 if variant==1 else 1):
			var offset=Vector3(0,level*10,(level-0.5)*size*0.23 if variant==1 else 0)
			ring(node,offset,size*0.64,size*0.82,steel)
			ring(node,offset+Vector3(0,3,0),size*0.715,size*0.74,gold)
			for i in 4:
				var spoke=Models.box(node,offset,Vector3(size*1.4,4,5),dark);spoke.rotation.y=i*PI/4
			for i in 16:
				var angle=i*TAU/16
				var window=Models.box(node,offset+Vector3(cos(angle)*size*0.76,5,sin(angle)*size*0.76),Vector3(5,2,2),lamps)
				window.rotation.y=-angle+PI/2
		cylinder(node,Vector3(0,8,0),size*0.22,18,dark)
		cylinder(node,Vector3(0,18,0),size*0.13,5,steel)
	elif variant==2:
		# Stardock: central command saucer with four illuminated docking pods.
		cylinder(node,Vector3(0,7,0),size*0.39,13,steel)
		cylinder(node,Vector3(0,15,0),size*0.30,4,dark)
		ring(node,Vector3(0,10,0),size*0.38,size*0.405,gold)
		for i in 4:
			var angle=PI/4+i*TAU/4;var direction=Vector3(cos(angle),0,sin(angle))
			var arm=Models.box(node,direction*size*0.48,Vector3(size*0.64,5,7),dark);arm.rotation.y=-angle
			var center=direction*size*0.72
			cylinder(node,center,size*0.24,7,steel)
			cylinder(node,center+Vector3(0,4.5,0),size*0.175,2,dark)
			var bay=Models.box(node,center+Vector3(0,6,0),Vector3(size*0.24,1,size*0.13),blue);bay.rotation.y=-angle
		for i in 12:
			var angle=i*TAU/12
			var window=Models.box(node,Vector3(cos(angle)*size*0.35,15,sin(angle)*size*0.35),Vector3(5,2,2),lamps)
			window.rotation.y=-angle+PI/2
	else:
		# Refinery: triangular truss and separate storage tanks, matching type 4.
		for i in 3:
			var a=Vector3(cos(i*TAU/3),0,sin(i*TAU/3))*size*0.68
			var b=Vector3(cos((i+1)*TAU/3),0,sin((i+1)*TAU/3))*size*0.68
			var beam=Models.box(node,(a+b)*0.5,Vector3(a.distance_to(b),4,4),steel)
			beam.rotation.y=-atan2((b-a).z,(b-a).x)
			Models.sphere(node,a,size*0.22,steel)
			cylinder(node,a+Vector3(0,size*0.22,0),size*0.09,2,gold)
			var spoke=Models.box(node,a*0.5,Vector3(size*0.7,4,4),dark);spoke.rotation.y=-i*TAU/3
		cylinder(node,Vector3.ZERO,size*0.18,17,dark)
		cylinder(node,Vector3(0,10,0),size*0.12,3,blue)
	Models.box(node,Vector3(0,20,-size*0.2),Vector3(2,22,2),steel)
	Models.box(node,Vector3(0,30,-size*0.2),Vector3(10,2,2),lamps)
	return node

static func add_rings(parent: Node3D, size: float) -> void:
	if ring_material==null:
		ring_material=Models.material(Color("786f5e"),0,0.25)
	var tilt=Node3D.new();parent.add_child(tilt);tilt.rotation.x=1.1
	for band in 3:
		var annulus=ring(tilt,Vector3.ZERO,size*(1.22+band*0.14),size*(1.32+band*0.14),ring_material)
		annulus.scale.y=0.08
