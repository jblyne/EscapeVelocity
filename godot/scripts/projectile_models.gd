extends RefCounted
const Models=preload("res://scripts/models.gd")
const GLOW=preload("res://shaders/projectile_glow.gdshader")
const IDS=[131,132,139,140,150]

static func tube(parent: Node3D,z: float,length: float,radius: float,material: Material,tip: float=-1) -> MeshInstance3D:
	var node=MeshInstance3D.new();var mesh=CylinderMesh.new()
	mesh.top_radius=radius if tip<0 else tip;mesh.bottom_radius=radius;mesh.height=length;mesh.radial_segments=16
	node.mesh=mesh;node.material_override=material;node.position.z=z;node.rotation.x=-PI/2
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node);return node

static func create(id: int) -> Node3D:
	var root=Node3D.new();root.set_meta("projectile_model",id)
	if id in [131,150]:
		root.name="Torpedo" if id==131 else "DecoyFlare"
		var glow=MeshInstance3D.new();var plane=PlaneMesh.new()
		plane.size=Vector2(17,27) if id==131 else Vector2(20,20)
		glow.mesh=plane;glow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material=ShaderMaterial.new();material.shader=GLOW
		material.set_shader_parameter("flare",id==150)
		glow.material_override=material;root.add_child(glow)
		return root
	var silver=Models.material(Color("a3adb4"),.6);silver.roughness=.48
	var dark=Models.material(Color("313a40"),.6)
	var paint=Models.material(Color("328a29") if id==139 else Color("c73529"),.15)
	var bomb: bool=id==140
	var heavy: bool=id==139
	root.name="SpaceBomb" if bomb else "HeavyRocket" if heavy else "Missile"
	var length: float=12 if bomb else 25 if heavy else 19
	var radius: float=3.3 if bomb else 2.1 if heavy else 1.7
	tube(root,0,length,radius,silver)
	tube(root,-length*.5-2.5,5,radius,silver,0)
	tube(root,length*.5+1,2,radius*.85,dark)
	if not bomb:
		for z in ([length*.3] if heavy else [-length*.3,length*.3]): tube(root,z,1.2,radius*1.04,paint)
	var fin_material=silver if bomb else paint
	var span: float=5 if bomb else 7 if heavy else 4.8
	for side in [-1,1]:
		Models.hull(root,PackedVector2Array([Vector2(side*radius,length*.12),Vector2(side*span,length*.46),Vector2(side*span,length*.62),Vector2(side*radius,length*.48)]),.45,fin_material)
	if not bomb:
		Models.add_exhaust(root,Vector3(0,0,length*.5+2),0)
		var plume=root.get_child(root.get_child_count()-1)
		plume.scale=Vector3(11 if heavy else 8,1,12 if heavy else 9)
		plume.position=Vector3(0,0,length*.5+2+(.7*plume.scale.z))
	return root

static func advance(node: Node3D,clock: float) -> void:
	if not node.has_meta("projectile_model"): return
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override is ShaderMaterial:
			child.material_override.set_shader_parameter("clock",clock)
