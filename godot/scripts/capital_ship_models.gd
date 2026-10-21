extends RefCounted
const Models=preload("res://scripts/models.gd")
const Details=preload("res://scripts/ship_detail.gd")
static func hull(root: Node3D, points: Array, height: float, mat: Material, at: Vector3=Vector3.ZERO) -> void:
	var outline=PackedVector2Array()
	for p in points: outline.append(Vector2(p[0],p[1]))
	Details.hull(root,outline,height,mat).position=at

static func build(root: Node3D,id: int) -> Vector2:
	var silver=Models.material(Color("aab0b4"),.65)
	var edge=Models.material(Color("62696d"),.55)
	var recess=Models.material(Color("20262b"),.35)
	var blue=Models.material(Color("182dc2"),.45)
	var red=Models.material(Color("a51d20"),.45)
	var light=Models.material(Color("83b6c8"),.3,.3)
	var exhaust=Models.material(Color("8bdfff"),0,1.4)
	var confed: bool=id in [133,134]
	var cruiser: bool=id in [134,142]
	var engines=Vector2(.72,.88) if confed else Vector2(.23,1.00)
	if confed:
		# The frigate has a broader bow shoulder; the cruiser has a thin,
		# slightly offset spine and a recessed port-side hangar block.
		var spine: float=.10 if cruiser else 0.0
		var width: float=.115 if cruiser else .145
		hull(root,[[-width,-1.12],[-.07,-1.28],[.07,-1.28],[width,-1.12],[width,1.02],[-width,1.02]],.25,silver,Vector3(spine,0,0))
		if not cruiser:
			hull(root,[[-.13,-.68],[-.40,-.02],[-.32,.19],[.32,.19],[.40,-.02],[.13,-.68]],.13,edge)
		else:
			hull(root,[[-.12,-.12],[-.40,.03],[-.40,.94],[.02,1.03],[.02,-.05]],.17,recess)
			for i in 7:
				Details.panel(root,Vector3(-.23,.19,.12+i*.105),Vector3(.25,.018,.022),edge)
			Details.panel(root,Vector3(.26,.14,.42),Vector3(.15,.27,1.25),silver)
		for side in [-1,1]:
			hull(root,[[side*.11,.56],[side*.55,.67],[side*.92,.36],[side*.91,.77],[side*.72,1.04],[side*.12,1.08]],.12,silver)
			hull(root,[[side*.58,.72],[side*.84,.67],[side*.81,.97],[side*.60,.98]],.075,blue,Vector3(0,.125,0))
			Details.panel(root,Vector3(side*.91,.10,.16),Vector3(.035,.06,.49),edge)
			Details.panel(root,Vector3(side*.91,.14,-.06),Vector3(.026,.025,.07),red)
		Details.panel(root,Vector3(spine,.27,-.13),Vector3(.035,.025,1.71),edge)
		Details.panel(root,Vector3(spine,.29,.64),Vector3(.026,.015,.57),blue)
	else:
		# Original Rebel capitals carry a narrow pointed bow, silver central
		# machinery, red outriggers and a squared, dark aft engine bay.
		var bow: float=-1.43 if cruiser else -1.28
		var width: float=.10 if cruiser else .14
		hull(root,[[0,bow],[width,-.90],[width,-.13],[.23,.37],[.25,.94],[.12,1.09],[-.12,1.09],[-.25,.94],[-.23,.37],[-width,-.13],[-width,-.90]],.26,silver)
		for side in [-1,1]:
			hull(root,[[side*.10,-.20],[side*.17,-.04],[side*.40,.65],[side*.38,.90],[side*.23,.95],[side*.20,.41]],.12,red)
			Details.panel(root,Vector3(side*.16,.12,-.65),Vector3(.07,.12,.48),recess)
			Details.panel(root,Vector3(side*.19,.15,-.55),Vector3(.065,.055,.23),red)
			Details.vent(root,Vector3(side*.29,.15,.58),.10,.30,recess,edge)
		if cruiser:
			Details.panel(root,Vector3(0,.29,.66),Vector3(.49,.15,.18),edge)
			Details.panel(root,Vector3(0,.30,.83),Vector3(.38,.12,.16),recess)
			Details.panel(root,Vector3(0,.32,.97),Vector3(.35,.10,.12),silver)
		else:
			for z in [-.86,-.62,-.38,.15,.40,.67]:
				Details.panel(root,Vector3(0,.28,z),Vector3(.18,.04,.11),edge)
			Details.panel(root,Vector3(0,.33,.25),Vector3(.12,.10,.45),silver)
		Details.panel(root,Vector3(0,.28,-.65),Vector3(.028,.022,.68),edge)
	for z in [-.83,-.45,.02]:
		Details.panel(root,Vector3(.10 if id==134 else 0,.28,z),Vector3(.07,.018,.024),light)
	for side in [-1,1]:
		Details.engine(root,Vector3(side*engines.x,.06,engines.y),silver,recess,blue if confed else red,exhaust)
	return engines
