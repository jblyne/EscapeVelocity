extends RefCounted

# All detail is real geometry, shared by the packed ship templates. Static parts
# are combined by material and hull section before a ship enters the game.
static func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for vertex in [a,b,c]: st.add_vertex(vertex)

static func hull(root: Node3D, points: PackedVector2Array, height: float, mat: Material) -> MeshInstance3D:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris=Geometry2D.triangulate_polygon(points)
	var center=Vector2.ZERO
	for point in points: center+=point
	center/=points.size()
	var rings: Array[PackedVector3Array]=[]
	for band in 4:
		var ring=PackedVector3Array()
		var inset: float=[.93,1.0,1.0,.85][band]
		var y: float=[0.0,.2,.64,1.0][band]*height
		for point in points:
			var p=center+(point-center)*inset
			ring.append(Vector3(p.x,y,p.y))
		rings.append(ring)
	for i in range(0,tris.size(),3):
		triangle(st,rings[3][tris[i+2]],rings[3][tris[i+1]],rings[3][tris[i]])
		triangle(st,rings[0][tris[i]],rings[0][tris[i+1]],rings[0][tris[i+2]])
	for band in 3:
		for i in points.size():
			var j=(i+1)%points.size()
			triangle(st,rings[band][i],rings[band+1][i],rings[band+1][j])
			triangle(st,rings[band][i],rings[band+1][j],rings[band][j])
	st.generate_normals()
	var node=MeshInstance3D.new();node.mesh=st.commit();node.material_override=mat
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	root.add_child(node)
	return node

static func panel(root: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var x=size.x*.5;var z=size.z*.5;var c=minf(x,z)*.35
	var points=PackedVector2Array([Vector2(-x+c,-z),Vector2(x-c,-z),Vector2(x,-z+c),Vector2(x,z-c),Vector2(x-c,z),Vector2(-x+c,z),Vector2(-x,z-c),Vector2(-x,-z+c)])
	var node=hull(root,points,size.y,mat);node.position=at-Vector3(0,size.y*.5,0)
	return node

static func cylinder(root: Node3D, at: Vector3, radius: float, length: float, mat: Material, end_radius: float = -1) -> MeshInstance3D:
	var mesh=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius if end_radius<0 else end_radius
	mesh.height=length;mesh.radial_segments=12;mesh.rings=1
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;node.position=at
	root.add_child(node)
	return node

static func cockpit(root: Node3D, at: Vector3, width: float, length: float, dark: Material, glass: Material, steel: Material) -> void:
	panel(root,at,Vector3(width*1.25,.11,length*1.16),dark)
	var points=PackedVector2Array([Vector2(-width*.28,-length*.5),Vector2(width*.28,-length*.5),Vector2(width*.5,length*.38),Vector2(width*.32,length*.5),Vector2(-width*.32,length*.5),Vector2(-width*.5,length*.38)])
	var canopy=hull(root,points,.10,glass);canopy.position=at+Vector3(0,.035,0)
	panel(root,at+Vector3(0,.142,length*.05),Vector3(width*.065,.015,length*.87),steel)
	panel(root,at+Vector3(0,.135,length*.28),Vector3(width*.83,.018,.022),dark)

static func vent(root: Node3D, at: Vector3, width: float, length: float, dark: Material, steel: Material) -> void:
	panel(root,at,Vector3(width,.028,length),dark)
	for i in 5:
		panel(root,at+Vector3(0,.021,(i-2)*length*.15),Vector3(width*.83,.018,length*.055),steel)

static func gun(root: Node3D, at: Vector3, dark: Material, steel: Material, glow: Material, twin: bool = false) -> void:
	cylinder(root,at,.09,.055,dark)
	panel(root,at+Vector3(0,.06,0),Vector3(.14,.10,.19),steel)
	for side in ([-1,1] if twin else [0]):
		var barrel=cylinder(root,at+Vector3(side*.035,.074,-.16),.021,.24,dark)
		barrel.rotation.x=PI/2
		var collar=cylinder(root,at+Vector3(side*.035,.074,-.27),.026,.035,steel)
		collar.rotation.x=PI/2
	panel(root,at+Vector3(0,.116,.045),Vector3(.034,.012,.026),glow)

static func engine(root: Node3D, at: Vector3, steel: Material, dark: Material, trim: Material, glow: Material) -> void:
	var body=cylinder(root,at+Vector3(0,0,-.13),.12,.44,steel,.095);body.rotation.x=PI/2
	for z in [-.24,-.08,.06]:
		var band=cylinder(root,at+Vector3(0,0,z),.128,.035,dark);band.rotation.x=PI/2
	var throat=cylinder(root,at+Vector3(0,0,.13),.11,.12,dark,.085);throat.rotation.x=PI/2
	var rim=cylinder(root,at+Vector3(0,0,.18),.098,.025,steel);rim.rotation.x=PI/2
	var core=cylinder(root,at+Vector3(0,0,.195),.077,.012,glow);core.rotation.x=PI/2
	panel(root,at+Vector3(0,.12,-.13),Vector3(.055,.025,.29),trim)
	for side in [-1,1]:
		panel(root,at+Vector3(side*.095,.065,.06),Vector3(.025,.045,.2),steel)

static func dress(root: Node3D, id: int, engine_x: float, engine_z: float, steel: Material, dark: Material, trim: Material, glass: Material, glow: Material) -> void:
	var capital=id in [130,133,134,140,141,142,143,146,150,152,153]
	var top: float={132:.27,133:.29,134:.29,135:.18,136:.17,137:.18,138:.16,139:.16,
		140:.33,141:.27,142:.30,144:.17,145:.19,146:.32,147:.18,148:.20}.get(id,.23)
	if id==128:
		cockpit(root,Vector3(0,.32,-.5),.58,.46,dark,glass,steel)
		panel(root,Vector3(0,.34,.32),Vector3(.52,.07,.68),steel)
		for side in [-1,1]:
			panel(root,Vector3(side*.39,.25,.20),Vector3(.16,.17,1.0),trim)
			vent(root,Vector3(side*.37,.345,.28),.11,.40,dark,steel)
		panel(root,Vector3(0,.39,.23),Vector3(.07,.012,.37),trim)
	elif id==191:
		cockpit(root,Vector3(0,.35,-.48),.37,.4,dark,glass,steel)
		for side in [-1,1]: panel(root,Vector3(side*.3,.22,.1),Vector3(.1,.19,.8),trim)
	elif id in [129,130,153]:
		var rails=[0.0] if id==129 else [-.39,.39]
		for x in rails:
			for z in [-.78,-.28,.22,.72]:
				panel(root,Vector3(x,.31,z),Vector3(.40 if id==129 else .20,.10,.34),steel)
				for side in [-1,1]:
					panel(root,Vector3(x+side*(.16 if id==129 else .07),.366,z),Vector3(.035,.016,.30),trim)
				panel(root,Vector3(x,.369,z),Vector3(.10,.02,.14),dark)
		cockpit(root,Vector3(0,.26,-.94),.24,.25,dark,glass,steel)
		if id==153:
			for z in [-.36,-.10,.16,.42]:
				panel(root,Vector3(0,.277,z),Vector3(.28,.012,.025),trim)
	elif id in [149,150]:
		# Segmented carapace and luminous seams give the alien hulls a distinct anatomy.
		for i in 5:
			var z=-.64+i*.30
			var width=(.38 if id==149 else .52)*(1.0-absf(z)*.35)
			for side in [-1,1]:
				var rib=panel(root,Vector3(side*width*.45,.25 if id==149 else .43,z),Vector3(width,.12,.22),steel)
				rib.rotation.y=side*.32
			panel(root,Vector3(0,.38 if id==149 else .56,z),Vector3(.045,.02,.12),glow)
		for side in [-1,1]:
			var blade=hull(root,PackedVector2Array([Vector2(0,-.55),Vector2(side*.24,-.1),Vector2(side*.12,.6),Vector2(0,.8)]),.09,trim)
			blade.position=Vector3(side*.28,.16,.08)
	else:
		var cabin_width: float=.15 if id in [135,137,139,143,145,147,152] else .23
		cockpit(root,Vector3(0,top+.025,-.39),cabin_width*(.8 if capital else 1.0),.28 if capital else .36,dark,glass,steel)
		# Recessed transverse seams and a narrow identification stripe break up
		# the long nose without changing the familiar outline.
		for i in 3:
			panel(root,Vector3(0,top+.004,-.91+i*.12),Vector3(.06+i*.035,.012,.015),dark)
		panel(root,Vector3(0,top+.016,-.74),Vector3(.026,.012,.22),trim)
		panel(root,Vector3(0,top+.025,.25),Vector3(cabin_width*1.05,.045,.57),steel)
		panel(root,Vector3(0,top+.052,.28),Vector3(.045,.012,.45),trim)
		vent(root,Vector3(0,top+.067,.58),cabin_width,.24,dark,steel)
		if capital:
			gun(root,Vector3(0,top+.07,-.02),dark,steel,glow,true)
			if id in [133,134,142]:
				for side in [-1,1]:
					panel(root,Vector3(side*engine_x,.30,.55),Vector3(.23,.075,.47),trim)
					vent(root,Vector3(side*engine_x,.345,.59),.17,.27,dark,steel)
		else:
			for side in [-1,1]:
				var wing=hull(root,PackedVector2Array([Vector2(side*.13,-.15),Vector2(side*engine_x,.32),Vector2(side*engine_x,.6),Vector2(side*.13,.38)]),.035,trim)
				wing.position.y=top+.003
				gun(root,Vector3(side*engine_x,.20,.14),dark,steel,glow)
	if id in [139,140]:
		for side in [-1,1]:
			for i in 6:
				panel(root,Vector3(side*(.22 if id==140 else .12),.36,-.57+i*.20),Vector3(.042,.018,.045),glass)
	# Flush edge lamps and short sensor masts remain legible in the target preview.
	for side in [-1,1]:
		panel(root,Vector3(side*engine_x,.245,engine_z-.30),Vector3(.045,.022,.08),glass)
		engine(root,Vector3(side*engine_x,.1,engine_z),steel,dark,trim,glow)
	if capital and id not in [149,150]:
		cylinder(root,Vector3(.09,top+.16,.40),.017,.23,dark)
		panel(root,Vector3(.09,top+.27,.40),Vector3(.15,.02,.05),steel)

static func batch_static_parts(root: Node3D) -> void:
	# Keep bow/midship/stern separate for recognizable explosion fragments.
	# Only the two exhaust plumes stay independent for thrust animation.
	var groups: Dictionary={}
	var parts: Array=[]
	for node in root.get_children():
		if not node is MeshInstance3D or str(node.name).begins_with("Flame"): continue
		var center: Vector3=node.transform*node.mesh.get_aabb().get_center()
		var section=0 if center.z<-.28 else (2 if center.z>.4 else 1)
		var key=Vector2i(node.material_override.get_instance_id(),section)
		if not groups.has(key):
			var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key]={"tool":tool,"material":node.material_override}
		# Primitive cylinders are indexed; authored hulls are triangle lists.
		# Expand both into one format so adding an indexed part cannot hide the
		# earlier unindexed faces. These untextured materials need only normals.
		var arrays=node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var normal_basis: Basis=node.basis.inverse().transposed()
		for vertex in (indices if not indices.is_empty() else range(vertices.size())):
			groups[key].tool.set_normal((normal_basis*normals[vertex]).normalized())
			groups[key].tool.add_vertex(node.transform*vertices[vertex])
		parts.append(node)
	for node in parts: node.free()
	for key in groups:
		var node=MeshInstance3D.new()
		node.name="HullSection%d_%d" % [key.y,root.get_child_count()]
		var mesh: ArrayMesh=groups[key].tool.commit()
		# Keep each section's origin local to that section so explosion debris
		# starts at the right place and tumbles around its own center.
		var center=mesh.get_aabb().get_center()
		var arrays=mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for i in vertices.size(): vertices[i]-=center
		arrays[Mesh.ARRAY_VERTEX]=vertices
		node.mesh=ArrayMesh.new();node.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		node.position=center;node.material_override=groups[key].material
		root.add_child(node)
