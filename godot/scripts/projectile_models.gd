extends RefCounted
const Models=preload("res://scripts/models.gd")
const GLOW=preload("res://shaders/projectile_glow.gdshader")
const IDS=[131,132,139,140,141,150,901]

static func tube(parent: Node3D,z: float,length: float,radius: float,material: Material,tip: float=-1) -> MeshInstance3D:
	var node=MeshInstance3D.new();var mesh=CylinderMesh.new()
	mesh.top_radius=radius if tip<0 else tip;mesh.bottom_radius=radius;mesh.height=length;mesh.radial_segments=16
	node.mesh=mesh;node.material_override=material;node.position.z=z;node.rotation.x=-PI/2
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(node);return node

static func create(id: int) -> Node3D:
	var root=Node3D.new();root.set_meta("projectile_model",id)
	if id==901:
		sidewinder(root);return root
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
	if id==141:
		root.name="JavelinRocket"
		# Original spïn 208 / PICT 216: short blunt silver body, white
		# motor collar and a narrow blue plume; no broad missile fins.
		tube(root,-1,9,1.8,silver)
		tube(root,-6.5,2,1.8,silver,.9)
		var collar=Models.material(Color("e4edf1"),.35);collar.roughness=.4
		tube(root,4,2,1.95,collar)
		tube(root,5.5,1,1.25,dark)
		Models.add_exhaust(root,Vector3(0,0,6),0)
		var plume=root.get_child(root.get_child_count()-1)
		plume.scale=Vector3(5,1,6)
		plume.position=Vector3(0,0,10.2)
		return root
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

static func sidewinder(root: Node3D) -> void:
	root.name="AIM9Sidewinder"
	var white=Models.material(Color("e8e7df"),.2)
	var metal=Models.material(Color("7b8586"),.6)
	var dark=Models.material(Color("252d2b"),.35)
	var seeker=Models.material(Color("151d19"),.5);seeker.roughness=.18
	var yellow=Models.material(Color("c6a144"),.1)
	var brown=Models.material(Color("79563e"),.1)
	tube(root,0,26,.68,white).name="SlimBody"
	tube(root,-13.7,1.4,.68,dark,.47).name="SeekerHousing"
	var lens=Models.sphere(root,Vector3(0,0,-14.55),.47,seeker);lens.scale.z=.75;lens.name="SeekerDome"
	tube(root,-4.5,.55,.7,yellow).name="WarheadBand"
	tube(root,3,.55,.7,brown).name="MotorBand"
	tube(root,13.3,.65,.6,metal).name="MotorNozzle"
	tube(root,13.7,.25,.43,dark).name="NozzleInterior"
	for i in 4:
		var forward=Models.hull(root,PackedVector2Array([Vector2(.6,-11.3),Vector2(2.05,-9.8),Vector2(1.95,-9.1),Vector2(.6,-7.5)]),.08,metal)
		forward.name="ForwardFin%d" % i;forward.rotation.z=i*PI/2+PI/4
		var tail=Models.hull(root,PackedVector2Array([Vector2(.6,6.7),Vector2(3.2,10),Vector2(3.2,12.8),Vector2(.6,12.5)]),.09,white)
		tail.name="TailFin%d" % i;tail.rotation.z=i*PI/2+PI/4
		var roller=Models.box(root,Vector3(3.0,.03,12.4),Vector3(.35,.18,.55),metal)
		roller.name="TailRoller%d" % i
		roller.position=Basis(Vector3.FORWARD,-(i*PI/2+PI/4))*roller.position
		roller.rotation.z=i*PI/2+PI/4
	Models.add_exhaust(root,Vector3(0,0,13.9),0)
	var plume=root.get_child(root.get_child_count()-1)
	plume.scale=Vector3(2.6,1,9);plume.position=Vector3(0,0,20.2)
	plume.material_override.set_shader_parameter("afterburner_heat",1.0)
	plume.material_override.set_shader_parameter("power",.8)

static func advance(node: Node3D,clock: float) -> void:
	if not node.has_meta("projectile_model"): return
	for child in node.get_children():
		if child is MeshInstance3D and child.material_override is ShaderMaterial:
			child.material_override.set_shader_parameter("clock",clock)
