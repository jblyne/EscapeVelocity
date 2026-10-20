class_name EVShipModels
extends RefCounted

const Models = preload("res://scripts/models.gd")
const Details = preload("res://scripts/ship_detail.gd")
const Factions = preload("res://scripts/factions.gd")
static var templates: Dictionary = {}

static func create(catalog, ship_id: int, faction_id: int = -1) -> Node3D:
	var key = Vector2i(ship_id, faction_id)
	if not templates.has(key):
		var prototype = build(ship_id, Factions.color_of(faction_id))
		for child in prototype.get_children(): child.owner = prototype
		var scene = PackedScene.new()
		scene.pack(prototype)
		templates[key] = scene
		prototype.free()
	var model: Node3D = templates[key].instantiate()
	var size: float = float(catalog.data.ship_graphics[str(ship_id)].width) * 0.72
	model.scale = Vector3.ONE * size
	model.set_meta("ship_id", ship_id)
	model.set_meta("hull_mass",float(catalog.record("ships",ship_id).fields.Mass))
	model.set_meta("faction_id", faction_id)
	model.set_meta("radius", size * 1.22)
	return model

static func outline(root: Node3D, coordinates: Array, height: float, mat: Material) -> void:
	var points = PackedVector2Array()
	for xy in coordinates: points.append(Vector2(xy[0],xy[1]))
	Details.hull(root, points, height, mat)

static func build(id: int, paint: Color) -> Node3D:
	var root = Node3D.new()
	var steel = Models.material(Color("8d9da9"),0.65)
	steel.roughness=.62
	var dark = Models.material(Color("17232e"),0.55)
	var trim = Models.material(paint,0.35)
	trim.roughness=.58
	var glass = Models.material(Color("277b9e"),0.55)
	glass.roughness=.18
	glass.emission_enabled=true;glass.emission=Color("2d96bd");glass.emission_energy_multiplier=.35
	var glow = Models.material(Color("65ceff"),0,2)
	var engine_x: float = 0.28
	var engine_z: float = 0.8
	match id:
		128: # The original shuttle is a compact rounded cabin.
			outline(root,[[-0.38,-0.95],[0.38,-0.95],[0.48,-0.65],[0.48,0.7],[0.3,0.95],[-0.3,0.95],[-0.48,0.7],[-0.48,-0.65]],0.28,steel)
			Details.panel(root,Vector3(0,.29,.3),Vector3(.62,.06,.65),trim)
		129: # Long segmented light freighter.
			Details.panel(root,Vector3(0,.05,0),Vector3(.32,.22,2.25),dark)
			for z in [-.78,-.3,.18,.66]: Details.panel(root,Vector3(0,.16,z),Vector3(.48,.28,.4),steel)
			Details.panel(root,Vector3(0,.33,-.93),Vector3(.3,.05,.15),glass)
			engine_x=.31;engine_z=.98
		130,153: # Original bulk freighter and carrier share a twin-rail hull.
			engine_x=.39;engine_z=1.02
			for x in [-.39,.39]:
				Details.panel(root,Vector3(x,.08,0),Vector3(.24,.25,2.4),steel)
				for z in [-.85,-.3,.3,.85]:
					Details.panel(root,Vector3(x,.25,z),Vector3(.26,.08,.38),trim)
			for z in [-.8,-.25,.3,.86]: Details.panel(root,Vector3(0,.07,z),Vector3(.85,.16,.12),dark)
			if id==153:
				Details.panel(root,Vector3(0,.16,.12),Vector3(.42,.19,1.25),dark)
				for x in [-.16,.16]: Details.panel(root,Vector3(x,.27,.12),Vector3(.035,.02,1.13),glow)
		131:
			outline(root,[[0,-1.18],[.22,-.72],[.2,.7],[-.2,.7],[-.22,-.72]],.23,steel)
			Details.panel(root,Vector3(0,.09,.32),Vector3(1.5,.12,.18),dark)
			engine_x=.62;engine_z=.82
			for x in [-.62,.62]: Details.panel(root,Vector3(x,.15,.38),Vector3(.28,.25,1.0),steel)
		132:
			outline(root,[[0,-1.23],[.23,-.65],[.27,.63],[.65,1.0],[.12,.94],[-.12,.94],[-.65,1.0],[-.27,.63],[-.23,-.65]],.27,steel)
			for z in [-.6,-.05,.5]: Details.panel(root,Vector3(0,.3,z),Vector3(.35,.07,.2),trim)
			engine_x=.42;engine_z=.95
		133,134: # Confederation's long spine and broad aft engine pods.
			var width: float = .39 if id==133 else .25
			outline(root,[[0,-1.23],[width,-.52],[width,.7],[-width,.7],[-width,-.52]],.29,steel)
			outline(root,[[-.23,.15],[-.83,.48],[-.74,1.0],[.74,1.0],[.83,.48],[.23,.15]],.14,dark)
			engine_x=.62;engine_z=.91
			for x in [-.62,.62]:
				Details.panel(root,Vector3(x,.14,.58),Vector3(.3,.3,.6),steel)
				Details.panel(root,Vector3(x,.3,.6),Vector3(.2,.07,.3),trim)
			if id==134:
				for z in [-.58,-.05,.5]: Details.panel(root,Vector3(0,.32,z),Vector3(.35,.11,.24),dark)
		135,147:
			outline(root,[[0,-1.25],[.17,-.38],[.2,.85],[-.2,.85],[-.17,-.38]],.18,steel)
			Details.panel(root,Vector3(0,.06,.55),Vector3(1.05,.12,.18),trim)
			engine_x=.44;engine_z=.68
			if id==147: Details.panel(root,Vector3(.3,.11,.06),Vector3(.18,.2,.7),steel)
		136:
			outline(root,[[0,-1.2],[.22,-.25],[.82,.82],[.25,.9],[0,.55],[-.25,.9],[-.82,.82],[-.22,-.25]],.17,steel)
			engine_x=.46
		137:
			outline(root,[[0,-1.15],[.18,-.28],[.65,.33],[.83,.88],[.22,.7],[0,.2],[-.22,.7],[-.83,.88],[-.65,.33],[-.18,-.28]],.18,steel)
			engine_x=.51;engine_z=.7
		138:
			outline(root,[[0,-.8],[.16,-.15],[.43,-1.0],[.54,.7],[0,1.0],[-.54,.7],[-.43,-1.0],[-.16,-.15]],.16,steel)
			for x in [-.36,.36]: Details.panel(root,Vector3(x,.18,.03),Vector3(.12,.05,1.0),trim)
			engine_x=.32
		139:
			outline(root,[[0,-1.25],[.14,-.63],[.16,.64],[.67,.93],[.56,1.08],[0,.78],[-.56,1.08],[-.67,.93],[-.16,.64],[-.14,-.63]],.16,steel)
			engine_x=.41;engine_z=.89
		140:
			outline(root,[[0,-1.22],[.31,-.68],[.4,.45],[.23,1.0],[-.23,1.0],[-.4,.45],[-.31,-.68]],.33,steel)
			for x in [-.28,.28]:
				for z in [-.5,-.2,.1,.4,.7]: Details.panel(root,Vector3(x,.35,z),Vector3(.09,.04,.07),glass)
			Details.panel(root,Vector3(0,.34,.08),Vector3(.2,.06,1.4),trim)
		141:
			outline(root,[[0,-1.22],[.21,-.7],[.17,-.1],[.31,.45],[.59,.92],[.12,.8],[-.12,.8],[-.59,.92],[-.31,.45],[-.17,-.1],[-.21,-.7]],.27,steel)
			engine_x=.4;engine_z=.88
		142:
			outline(root,[[0,-1.22],[.18,-.68],[.27,.03],[.51,.6],[.47,1.0],[-.47,1.0],[-.51,.6],[-.27,.03],[-.18,-.68]],.3,dark)
			Details.panel(root,Vector3(0,.32,.48),Vector3(.62,.09,.36),steel)
			engine_x=.4;engine_z=.93
			for x in [-.33,.33]: Details.panel(root,Vector3(x,.18,.26),Vector3(.14,.25,1.0),trim)
		143,152:
			outline(root,[[0,-1.25],[.13,-.23],[.16,.53],[.85,.64],[.32,1.0],[0,.71],[-.32,1.0],[-.85,.64],[-.16,.53],[-.13,-.23]],.23,dark)
			Details.panel(root,Vector3(0,.25,.01),Vector3(.12,.06,1.1),steel)
			engine_x=.53;engine_z=.75
		144:
			outline(root,[[0,-1.02],[.88,.68],[.32,.56],[0,.76],[-.32,.56],[-.88,.68]],.17,steel)
			engine_x=.4;engine_z=.53
		145:
			outline(root,[[0,-1.22],[.16,-.28],[.4,.71],[.18,.94],[-.18,.94],[-.4,.71],[-.16,-.28]],.19,steel)
			Details.panel(root,Vector3(.35,.08,.27),Vector3(.43,.1,.14),trim)
			engine_x=.23
		146:
			outline(root,[[0,-1.18],[.26,-.4],[.3,.88],[.08,.67],[-.08,.67],[-.3,.88],[-.26,-.4]],.32,steel)
			for z in [-.55,-.15,.3,.68]: Details.panel(root,Vector3(0,.34,z),Vector3(.35,.1,.15),trim)
			engine_x=.24;engine_z=.9
		148:
			outline(root,[[0,-1.12],[.2,-.18],[.82,-.34],[.58,.42],[.19,.65],[.35,.97],[0,.8],[-.35,.97],[-.19,.65],[-.58,.42],[-.82,-.34],[-.2,-.18]],.2,steel)
			engine_x=.36;engine_z=.55
		149,150:
			steel=Models.material(Color("652631"),.65)
			glass=Models.material(Color("ff786e"),0,1)
			glow=Models.material(Color("ff443d"),0,2)
			if id==149:
				outline(root,[[0,-1.12],[.38,-.25],[.89,.1],[.36,.48],[0,1.0],[-.36,.48],[-.89,.1],[-.38,-.25]],.23,steel)
			else:
				outline(root,[[0,-1.23],[.3,-.88],[.39,-.2],[.64,.68],[.32,1.03],[-.32,1.03],[-.64,.68],[-.39,-.2],[-.3,-.88]],.4,steel)
			for z in [-.6,-.2,.2,.6]:
				Details.panel(root,Vector3(0,.42,z),Vector3(.13,.08,.19),glass)
			engine_x=.3
		151:
			outline(root,[[0,-1.18],[.2,-.2],[.8,.67],[.33,.61],[.23,.97],[0,.64],[-.23,.97],[-.33,.61],[-.8,.67],[-.2,-.2]],.23,steel)
			engine_x=.4;engine_z=.73
		191:
			Details.panel(root,Vector3(0,.12,0),Vector3(.65,.4,1.6),steel)
			Details.panel(root,Vector3(0,.33,-.5),Vector3(.5,.04,.35),glass)
			Details.panel(root,Vector3(0,.34,.24),Vector3(.63,.03,.4),trim)
			engine_x=.2;engine_z=.76
	Details.dress(root,id,engine_x,engine_z,steel,dark,trim,glass,glow)
	for side in [-1,1]:
		Models.add_exhaust(root,Vector3(side*engine_x,.1,engine_z+.20),side)
	# Keep hull, canopy and nozzle culling consistent across the entire fleet.
	# Otherwise a gun's luminous sight creates a new debris shader at the first
	# cruiser explosion, even though the shuttle's exhaust was already warmed.
	for mat in [steel,dark,trim,glass,glow]: mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	Details.batch_static_parts(root)
	return root
