extends Node3D

# A dedicated, explicitly clocked planetary fracture effect. No physics bodies,
# no scene timers, and shared materials keep the 128 crust wedges inexpensive.
const Models=preload("res://scripts/models.gd")
const EFFECT=preload("res://shaders/explosion.gdshader")
const DURATION: float=14.0
var age: float=0
var radius: float=100
var fragments: Array=[]
var layers: Array=[]
var crust: ShaderMaterial
var interior: ShaderMaterial
var core: MeshInstance3D
var core_material: StandardMaterial3D
var light: OmniLight3D
var rng=RandomNumberGenerator.new()
static var plane: PlaneMesh
static var retained_materials: Array=[]

func setup(source: Node3D, size: float, seed_value: int) -> void:
	position=source.position;radius=size;rng.seed=seed_value*7853
	var surface: MeshInstance3D=source.get_node("Surface")
	crust=surface.material_override.duplicate()
	crust.shader=preload("res://shaders/planet_crust.gdshader")
	crust.set_shader_parameter("rupture_heat",1.0)
	interior=ShaderMaterial.new();interior.shader=preload("res://shaders/planet_magma.gdshader")
	# Subdivide an octahedral shell; each triangle becomes a solid crust wedge.
	var top=Vector3.UP;var bottom=Vector3.DOWN
	var equator: Array=[Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD]
	for i in 4:
		subdivide(top,equator[i],equator[(i+1)%4],2)
		subdivide(bottom,equator[(i+1)%4],equator[i],2)
	core_material=Models.material(Color("fff0bd"));core_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.emission_enabled=true;core_material.emission=Color("ff7a22");core_material.emission_energy_multiplier=5
	core_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	core=Models.sphere(self,Vector3.ZERO,size*.30,core_material)
	# Fire, secondary flashes, drifting smoke and two expanding energy fronts.
	layer(3,Vector3.ZERO,size*5.0,0,.65,0)
	layer(0,Vector3.ZERO,size*3.2,.10,3.2,8)
	layer(2,Vector3.ZERO,size*19,.05,6.2,14)
	layer(2,Vector3.ZERO,size*13,.65,7.5,12)
	for i in 18:
		var direction=Vector3(cos(i*TAU/18),rng.randf_range(-.4,.6),sin(i*TAU/18))
		layer(0,direction*size*.45,size*rng.randf_range(.6,1.2),rng.randf_range(.2,1.0),rng.randf_range(2.0,4.8),18,direction*size*rng.randf_range(.4,.9))
		layer(1,direction*size*.5,size*rng.randf_range(1.0,1.8),rng.randf_range(.7,1.6),rng.randf_range(6,10),24,direction*size*.65)
	for i in 28:
		var direction=Vector3(cos(i*TAU/28),0,sin(i*TAU/28))
		layer(4,direction*size*.6,size*.05,0,rng.randf_range(2,5),30,direction*size*rng.randf_range(1.2,2.5))
	light=OmniLight3D.new();light.light_color=Color("ffb46e");light.omni_range=size*14;light.shadow_enabled=false
	light.position.y=size*2;add_child(light)
	if retained_materials.is_empty(): retained_materials=[crust,interior,core_material]
	advance(0)

func subdivide(a: Vector3,b: Vector3,c: Vector3,depth: int) -> void:
	if depth==0: wedge(a,b,c);return
	var ab=(a+b).normalized();var bc=(b+c).normalized();var ca=(c+a).normalized()
	subdivide(a,ab,ca,depth-1);subdivide(ab,b,bc,depth-1)
	subdivide(ca,bc,c,depth-1);subdivide(ab,bc,ca,depth-1)

func triangle(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	var normal: Vector3=(b-a).cross(c-a).normalized()
	for point in [a,b,c]: tool.set_normal(normal);tool.add_vertex(point)

func wedge(a: Vector3,b: Vector3,c: Vector3) -> void:
	a*=radius;b*=radius;c*=radius
	var outer=SurfaceTool.new();outer.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Match Godot's clockwise front faces; enable both sides on the hot cut faces.
	if (b-a).cross(c-a).dot(a)>0: var swap=b;b=c;c=swap
	var ab: Vector3=(a+b).normalized()*radius
	var bc: Vector3=(b+c).normalized()*radius
	var ca: Vector3=(c+a).normalized()*radius
	triangle(outer,a,ab,ca);triangle(outer,ab,b,bc)
	triangle(outer,ca,bc,c);triangle(outer,ab,bc,ca)
	var mesh: ArrayMesh=outer.commit();mesh.surface_set_material(0,crust)
	var cut=SurfaceTool.new();cut.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ai: Vector3=a*.62;var bi: Vector3=b*.62;var ci: Vector3=c*.62
	triangle(cut,a,ai,bi);triangle(cut,a,bi,b)
	triangle(cut,b,bi,ci);triangle(cut,b,ci,c)
	triangle(cut,c,ci,ai);triangle(cut,c,ai,a);triangle(cut,ai,ci,bi)
	cut.commit(mesh);mesh.surface_set_material(1,interior)
	var node=MeshInstance3D.new();node.mesh=mesh;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	var direction: Vector3=(a+b+c).normalized()
	fragments.append({"node":node,"direction":direction,"speed":rng.randf_range(.35,1.5)*radius,
		"spin":Vector3(rng.randf_range(-.8,.8),rng.randf_range(-1.2,1.2),rng.randf_range(-.8,.8)),"delay":rng.randf_range(.08,.65)})

func layer(kind: int,offset: Vector3,size: float,delay: float,life: float,height: float,velocity: Vector3=Vector3.ZERO) -> void:
	if plane==null: plane=PlaneMesh.new();plane.size=Vector2(2,2)
	var node=MeshInstance3D.new();node.mesh=plane
	var material=ShaderMaterial.new();material.shader=EFFECT
	material.set_shader_parameter("kind",kind);material.set_shader_parameter("life",life)
	material.set_shader_parameter("seed_value",rng.randf_range(0,100))
	node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
	layers.append({"node":node,"material":material,"kind":kind,"offset":offset,"radius":size,"delay":delay,"life":life,"height":height,"velocity":velocity})

func advance(dt: float) -> bool:
	age+=dt
	var cooling: float=exp(-maxf(0,age-1)*.3)
	crust.set_shader_parameter("rupture_heat",cooling)
	crust.set_shader_parameter("rupture_fade",1.0-smoothstep(10,14,age))
	interior.set_shader_parameter("heat",cooling);interior.set_shader_parameter("fade",1-smoothstep(10,14,age))
	for part in fragments:
		var t: float=maxf(0,age-float(part.delay))
		var travel: float=t
		part.node.position=part.direction*float(part.speed)*travel
		part.node.rotation=part.spin*t
		part.node.scale=Vector3.ONE*(1.0-.6*smoothstep(6,14,age))
	core.scale=Vector3.ONE*(.6+1.8*(1-exp(-age*1.4)))
	core_material.albedo_color.a=1-smoothstep(.5,3.5,age);core.visible=age<3.5
	light.light_energy=12*exp(-age*1.2)
	for item in layers:
		var t: float=age-float(item.delay)
		item.node.visible=t>=0 and t<float(item.life)
		if not item.node.visible: continue
		var progress: float=t/float(item.life)
		var growth: float=.25+progress*1.3
		if int(item.kind)==2: growth=.02+progress*1.2
		if int(item.kind)==3: growth=1
		if int(item.kind)==4: growth=1
		item.node.scale=Vector3(float(item.radius)*growth,1,float(item.radius)*growth)
		item.node.position=item.offset+item.velocity*((1-exp(-t*.2))/.2)
		# Draw all luminous planes on the camera-facing side of the old globe.
		item.node.position.y=radius+float(item.height)
		item.material.set_shader_parameter("age",t)
	return age>=DURATION
