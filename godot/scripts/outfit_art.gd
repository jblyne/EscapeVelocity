extends RefCounted
const Models = preload("res://scripts/models.gd")

static func category(fields: Dictionary) -> String:
	if int(fields.ModType)==1: return "WEAPONS"
	if int(fields.ModType)==3: return "AMMUNITION"
	return "SYSTEMS"

static func picture(parent: Node, catalog, id: int, dimensions: Vector2, background: Color=Color("09141f")) -> TextureRect:
	var viewport=SubViewport.new()
	viewport.size=Vector2i(dimensions*2)
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	viewport.msaa_3d=Viewport.MSAA_4X
	parent.add_child(viewport)
	var environment=WorldEnvironment.new()
	var env=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=background
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("b6d8f0")
	env.ambient_light_energy=.65
	environment.environment=env
	viewport.add_child(environment)
	var light=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-40,-35,0)
	light.light_energy=1.8
	viewport.add_child(light)
	var rim=DirectionalLight3D.new()
	rim.rotation_degrees=Vector3(30,145,0)
	rim.light_color=Color("67cfe4")
	rim.light_energy=1.3
	viewport.add_child(rim)
	var model=build(catalog,id)
	viewport.add_child(model)
	var camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=2.6
	camera.position=Vector3(3,2.5,4)
	viewport.add_child(camera)
	camera.look_at(Vector3.ZERO)
	var image=TextureRect.new()
	image.name="OutfitPicture%d" % id
	image.texture=viewport.get_texture()
	image.custom_minimum_size=dimensions
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

static func cylinder(root: Node3D, pos: Vector3, radius: float, length: float, mat: Material, tip: float = -1) -> void:
	var node=MeshInstance3D.new()
	var mesh=CylinderMesh.new()
	mesh.top_radius=radius if tip<0 else tip
	mesh.bottom_radius=radius
	mesh.height=length
	mesh.radial_segments=32
	node.mesh=mesh
	node.material_override=mat
	node.rotation.x=PI/2
	node.position=pos
	root.add_child(node)

static func build(catalog, id: int) -> Node3D:
	if id==902:
		var missile=preload("res://scripts/projectile_models.gd").create(901);missile.scale=Vector3.ONE*.06
		for part in missile.get_children():
			if str(part.name).begins_with("Flame"): part.hide()
		return missile
	var f: Dictionary=catalog.record("outfits",id).fields
	var type: int=int(f.ModType)
	var root=Node3D.new()
	var steel=Models.material(Color("a8baca"),.55)
	var dark=Models.material(Color("263746"),.6)
	var accent=Models.material(Color.from_hsv(float(id%11)/28.0+.43,.55,.8),.35)
	var glow=Models.material(Color("70efff"),0,1.5)
	if id in [139,141,142,143]:
		var weapon: Dictionary=catalog.record("weapons",int(f.ModVal))
		var fighter=preload("res://scripts/ship_models.gd").create(catalog,int(weapon.fields.AmmoType),-1)
		fighter.scale=Vector3.ONE
		Models.set_thrust(fighter,0,0)
		root.add_child(fighter)
	elif type==1:
		var barrels: int=2 if int(f.Flags)&2 else (3 if id in [133,138,163,174] else 1)
		Models.box(root,Vector3(0,-.25,0),Vector3(1.0,.35,1.1),dark)
		Models.box(root,Vector3(0,0,.35),Vector3(.95,.5,.85),steel)
		for i in barrels:
			var x: float=(i-(barrels-1)*.5)*.29
			cylinder(root,Vector3(x,.12,-.6),.12,1.5,steel)
			cylinder(root,Vector3(x,.12,-1.33),.15,.18,dark)
			cylinder(root,Vector3(x,.12,-1.43),.09,.02,glow)
		for i in 4: Models.box(root,Vector3(0,.28,.05+i*.18),Vector3(.78,.06,.055),accent)
	elif type==3:
		var radius: float=.20 if id in [132,160,162] else .13
		for i in 3:
			var x: float=(i-1)*.48
			cylinder(root,Vector3(x,0,0),radius,1.55,steel)
			cylinder(root,Vector3(x,0,-.96),radius,.4,accent,0)
			cylinder(root,Vector3(x,0,.5),radius*1.08,.16,accent)
			Models.box(root,Vector3(x,0,.65),Vector3(radius*3,.06,.4),dark)
	elif type==6:
		for i in 3:
			Models.box(root,Vector3(i*.1,i*.15-.2,0),Vector3(1.45,.13,1.8),steel if i!=1 else dark)
		for x in [-.5,.5]:
			for z in [-.6,.6]: Models.box(root,Vector3(x,.22,z),Vector3(.12,.08,.12),accent)
	elif type==2:
		Models.box(root,Vector3.ZERO,Vector3(1.3,.9,1.6),dark)
		for x in [-.6,.6]: Models.box(root,Vector3(x,0,0),Vector3(.12,1.0,1.75),steel)
		for z in [-.6,-.2,.2,.6]: Models.box(root,Vector3(0,.47,z),Vector3(1.1,.08,.1),accent)
	elif type in [7,8,9,15,18]:
		cylinder(root,Vector3.ZERO,.5,1.5,steel)
		for z in [-.6,-.3,0,.3,.6]: cylinder(root,Vector3(0,0,z),.55,.10,dark)
		cylinder(root,Vector3(0,0,.83),.43,.22,accent)
		cylinder(root,Vector3(0,0,.96),.30,.02,glow)
		for x in [-.65,.65]: Models.box(root,Vector3(x,0,0),Vector3(.18,.3,1.1),accent)
	elif type==12:
		for x in [-.36,.36]:
			cylinder(root,Vector3(x,0,0),.29,1.6,steel)
			for z in [-.5,.5]: cylinder(root,Vector3(x,0,z),.32,.15,accent)
	else:
		Models.box(root,Vector3(0,-.25,0),Vector3(1.45,.25,1.4),dark)
		for x in [-.45,0,.45]:
			cylinder(root,Vector3(x,.12,0),.17,1.0,accent)
			for z in [-.3,0,.3]: cylinder(root,Vector3(x,.12,z),.19,.09,glow)
		Models.box(root,Vector3(0,.42,0),Vector3(1.4,.1,.2),steel)
	return root
