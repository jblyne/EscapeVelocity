extends Node3D

const EFFECT_SHADER = preload("res://shaders/explosion.gdshader")
const Models = preload("res://scripts/models.gd")
const DURATION: float = 7.2
const DEBRIS_FADE_START: float = 3.6
enum BlastStyle { THERMAL, REACTOR, AMMUNITION, FUEL }
const STYLE_NAMES=["Thermal fireball","Reactor rupture","Ammunition chain reaction","Fuel bloom"]
var blast_style: int=BlastStyle.THERMAL
static var shared_plane: PlaneMesh
# Procedural ships use three combinations of shading/culling. Keep one material
# for each alive: releasing the last one evicts Godot's generated debris shader
# and caused a measured ~240 ms compilation stall on the next explosion.
static var shader_keepers: Dictionary = {}
var age: float = 0
var drift: Vector3
var origin: Vector3
var blast_scale: float = 1
var layers: Array[Dictionary] = []
var fragments: Array[Dictionary] = []
var people: Array[Dictionary] = []
var flash_light: OmniLight3D
var rng = RandomNumberGenerator.new()

# The game advances this clock explicitly, so every layer pauses together and
# the player's last explosion can finish while the death screen is displayed.
func setup(source: Node3D, ship_velocity: Vector2, seed_value: int = -1, size_multiplier: float = 1.0, style_override: int = -1) -> void:
	if seed_value < 0: rng.randomize()
	else: rng.seed = seed_value
	blast_style=clampi(style_override,0,3) if style_override>=0 else rng.randi_range(0,3)
	origin = position
	drift = Vector3(ship_velocity.x, 0, ship_velocity.y) * 0.65
	blast_scale = clampf(source.scale.x / 24.0, 0.65, 2.5) * size_multiplier
	var fuel: bool=blast_style==BlastStyle.FUEL
	var ammunition: bool=blast_style==BlastStyle.AMMUNITION
	for i in 9:
		var direction = Vector3(cos(float(i)*TAU/9), 0, sin(float(i)*TAU/9))
		layer(1, direction * rng.randf_range(15, 38), direction * rng.randf_range(13, 25), rng.randf_range(50, 78)*(1.3 if fuel else 1.0), rng.randf_range(0.03, 0.24), rng.randf_range(2.6, 3.3)*(1.25 if fuel else 1.0), 10+i*0.15)
	for i in 13:
		var direction = Vector3(cos(float(i)*TAU/13), 0, sin(float(i)*TAU/13))
		layer(0, direction * rng.randf_range(3, 18), direction * rng.randf_range(30, 66)*(0.65 if fuel else 1.0), rng.randf_range(28, 48)*(1.5 if fuel else .65 if ammunition else 1.0), rng.randf_range(0, 0.22)+(float(i)*.12 if ammunition else 0), rng.randf_range(0.65, 1.3)*(1.7 if fuel else .6 if ammunition else 1.0), 16+i*0.15)
	layer(0, Vector3.ZERO, Vector3.ZERO, 65, 0, 0.8, 20)
	layer(2, Vector3.ZERO, Vector3.ZERO, 200, 0, 0.85, 24)
	layer(3, Vector3.ZERO, Vector3.ZERO, 145, 0, 0.24, 28)
	if blast_style==BlastStyle.REACTOR:
		for i in 2: layer(2,Vector3.ZERO,Vector3.ZERO,260+i*55,.18+i*.18,.9,25+i)
		var jet_axis: float=rng.randf_range(0,TAU)
		for i in 4:
			var angle: float=jet_axis+float(i)*TAU/4+rng.randf_range(-.24,.24)
			var direction=Vector3(cos(angle),0,sin(angle))
			var jet=layer(0,direction*12,direction*145,22,.06,.9,23)
			jet.streak=rng.randf_range(2.8,4.2);jet.node.rotation.y=-angle
	if ammunition:
		for i in 6:
			var offset=Vector3(rng.randf_range(-40,40),0,rng.randf_range(-40,40))
			layer(3,offset,Vector3.ZERO,48,.3+i*.22,.18,29)
			layer(2,offset,Vector3.ZERO,75,.3+i*.22,.4,24)
	for i in (48 if ammunition else 18 if fuel else 32):
		var heading = rng.randf_range(0, TAU)
		var direction = Vector3(cos(heading), 0, sin(heading))
		var ember = layer(4, Vector3.ZERO, direction * rng.randf_range(110, 270), rng.randf_range(2, 4), 0, rng.randf_range(0.75, 1.85), 22)
		ember.node.rotation.y = -heading
		ember.streak = rng.randf_range(3, 8)
	# Reuse actual hull geometry/materials, without keeping any live ship nodes.
	var hull_parts: Array = []
	for original in source.get_children():
		if not original is MeshInstance3D or str(original.name).begins_with("Flame"): continue
		if hull_parts.size() >= 14: break
		hull_parts.append(original)
	# Two tumbling pieces per hull part; share meshes while varying chip size.
	for index in hull_parts.size()*2:
		var original: MeshInstance3D = hull_parts[index % hull_parts.size()]
		var piece = MeshInstance3D.new()
		piece.mesh = original.mesh
		piece.basis = source.basis * original.basis
		if original.mesh is ArrayMesh: piece.scale *= 0.4
		if index >= hull_parts.size(): piece.scale *= rng.randf_range(0.55,0.85)
		var material = original.material_override.duplicate() as StandardMaterial3D
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.emission_enabled = true
		material.emission = Color("58bfff") if blast_style==BlastStyle.REACTOR else Color("ff601a")
		material.emission_energy_multiplier = 1.6
		var shader_key = Vector2i(material.shading_mode,material.cull_mode)
		if not shader_keepers.has(shader_key): shader_keepers[shader_key] = material
		piece.material_override = material
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(piece)
		var offset: Vector3 = source.basis * original.position
		var direction = (offset + Vector3(rng.randf_range(-24,24),0,rng.randf_range(-24,24))).normalized()
		fragments.append({"node":piece,"offset":offset,"velocity":direction*rng.randf_range(65,160)*blast_scale,
			"spin":Vector3(rng.randf_range(-3,3),rng.randf_range(-4,4),rng.randf_range(-3,3)),"basis":piece.basis,"material":material})
	# A small ship ejects one visible crew member; broad, capital-size hulls eject
	# two. These are stylized suited figures rather than graphic casualties.
	var person_count: int = 2 if float(source.get_meta("radius",0)) >= 34 else 1
	for i in person_count: add_person(i, person_count)
	flash_light = OmniLight3D.new()
	flash_light.position.y = 60
	flash_light.light_color = Color("80ccff") if blast_style==BlastStyle.REACTOR else Color("ffb75c")
	flash_light.omni_range = 250*blast_scale
	flash_light.shadow_enabled = false
	add_child(flash_light)
	advance(0)

func transparent_material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var material := Models.material(color,metal)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	return material

func limb(parent: Node3D, name: String, at: Vector3, dimensions: Vector3, material: Material) -> Node3D:
	var joint=Node3D.new()
	joint.name=name
	joint.position=at
	parent.add_child(joint)
	Models.box(joint,Vector3(0,0,-dimensions.z*.42),dimensions,material)
	return joint

func add_person(index: int, count: int) -> void:
	var root=Node3D.new()
	root.name="CrewDebris%d" % index
	root.scale=Vector3.ONE*1.55
	add_child(root)
	var suit=transparent_material(Color("d6dce2"))
	var trim=transparent_material(Color("e58955"))
	var visor=transparent_material(Color("172e3e"),.5)
	Models.box(root,Vector3(0,0,0),Vector3(3.5,2.0,5.5),suit)
	Models.box(root,Vector3(0,1.08,.15),Vector3(3.8,.35,3.2),trim)
	Models.sphere(root,Vector3(0,0,-4.0),1.65,suit)
	var face=Models.sphere(root,Vector3(0,-.25,-4.55),1.25,visor)
	face.scale=Vector3(1,.45,.8)
	var left_arm=limb(root,"LeftArm",Vector3(-2.0,0,-1.2),Vector3(1.2,1.2,4.5),suit)
	var right_arm=limb(root,"RightArm",Vector3(2.0,0,-1.2),Vector3(1.2,1.2,4.5),suit)
	var left_leg=limb(root,"LeftLeg",Vector3(-1.0,0,2.2),Vector3(1.45,1.4,5.2),suit)
	var right_leg=limb(root,"RightLeg",Vector3(1.0,0,2.2),Vector3(1.45,1.4,5.2),suit)
	var angle: float = (float(index)+.5)*TAU/float(count)+rng.randf_range(-.45,.45)
	var direction=Vector3(cos(angle),0,sin(angle))
	var offset=direction*rng.randf_range(5,16)*blast_scale
	root.position=offset
	root.rotation=Vector3(rng.randf_range(-PI,PI),rng.randf_range(-PI,PI),rng.randf_range(-PI,PI))
	people.append({"node":root,"offset":offset,"velocity":direction*rng.randf_range(35,75)*blast_scale,
		"spin":Vector3(rng.randf_range(-.7,.7),rng.randf_range(-1.1,1.1),rng.randf_range(-.7,.7)),
		"basis":root.basis,"phase":rng.randf_range(0,TAU),"left_arm":left_arm,"right_arm":right_arm,
		"left_leg":left_leg,"right_leg":right_leg,"materials":[suit,trim,visor]})

func layer(kind: int, offset: Vector3, speed: Vector3, radius: float, delay: float, life: float, height: float) -> Dictionary:
	var node = MeshInstance3D.new()
	if shared_plane == null:
		shared_plane = PlaneMesh.new()
		shared_plane.size = Vector2(2,2)
	node.mesh = shared_plane
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material = ShaderMaterial.new()
	material.shader = EFFECT_SHADER
	material.set_shader_parameter("kind",kind)
	material.set_shader_parameter("blast_style",blast_style)
	material.set_shader_parameter("life",life)
	material.set_shader_parameter("seed_value",rng.randf_range(0,100))
	node.material_override = material
	add_child(node)
	var result = {"node":node,"material":material,"kind":kind,"offset":offset*blast_scale,"velocity":speed*blast_scale,
		"radius":radius*blast_scale,"delay":delay,"life":life,"height":height,"streak":1.0}
	layers.append(result)
	return result

func advance(dt: float) -> bool:
	age += dt
	position = origin + drift * age
	for item in layers:
		var t: float = age-item.delay
		item.node.visible = t >= 0 and t < item.life
		if not item.node.visible: continue
		var progress: float = t/item.life
		var growth: float = 0.35 + 0.9*(1-exp(-t*5))
		if item.kind == 1: growth = 0.4 + progress*0.85
		if item.kind == 2: growth = 0.08 + 1.35*(1-exp(-t*3.5))
		if item.kind >= 3: growth = 1.0
		var radius: float = item.radius*growth
		item.node.scale = Vector3(radius*item.streak,1,radius)
		item.node.position = item.offset + item.velocity * ((1-exp(-t*1.6))/1.6)
		item.node.position.y = item.height
		item.material.set_shader_parameter("age",t)
	for fragment in fragments:
		fragment.node.position = fragment.offset + fragment.velocity * ((1-exp(-age*0.9))/0.9)
		fragment.node.position.y += 15
		fragment.node.basis = Basis.from_euler(fragment.spin*age) * fragment.basis
		fragment.material.emission_energy_multiplier = 1.6*exp(-age*2.5)
		fragment.material.albedo_color.a = 1.0-smoothstep(DEBRIS_FADE_START,DURATION,age)
	for person in people:
		person.node.position=person.offset+person.velocity*((1-exp(-age*.45))/.45)
		person.node.position.y=18+sin(age*1.7+person.phase)*2
		person.node.basis=Basis.from_euler(person.spin*age)*person.basis
		# Opposing limb motion gives the silhouettes a slow, readable squirm.
		var squirm: float=sin(age*3.1+person.phase)
		person.left_arm.rotation.x=.65+squirm*.5
		person.right_arm.rotation.x=-.65-squirm*.45
		person.left_leg.rotation.x=-.25-squirm*.3
		person.right_leg.rotation.x=.25+squirm*.35
		var alpha: float=1.0-smoothstep(DEBRIS_FADE_START,DURATION,age)
		for material in person.materials: material.albedo_color.a=alpha
	flash_light.light_energy = 3.5*exp(-age*12)
	return age >= DURATION
