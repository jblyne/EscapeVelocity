extends Node3D

const Models=preload("res://scripts/models.gd")
const RADIUS: float=65.0
const JumpVisuals=preload("res://scripts/jump_visuals.gd")
const Hyperspace=preload("res://scripts/hyperspace.gd")
const WARP_SECONDS: float=JumpVisuals.SNAP_SECONDS
const STANDOFF_GAP: float=200.0
const FEED_STAGGER: float=.22
const FEED_TRAVEL: float=.18
const TURN_SECONDS: float=2.0
const RETREAT_SECONDS: float=12.0
const RETREAT_SPEED: float=20.0
var game
var target_name: String=""
func reckoning_title() -> String:
	return "The Reckoning of "+target_name if not target_name.is_empty() else "The Reckoning"
var jump_visuals=JumpVisuals.new()
var idle_drive=Hyperspace.new()
const STOP_REMAINING: float=20.0
const CHARGE_REMAINING: float=15.0
const FIRE_REMAINING: float=4.0
const AXIS=Vector3(0,.74,-.673)
var hull: Node3D
var counter: Label3D
var emitters: Array=[]
var feeds: Array=[]
var feed_halos: Array=[]
var packets: Array=[]
var focus_spikes: Array=[]
var focus_halo: MeshInstance3D
var feed_fractions: Array=[]
var main_beams: Array=[]
var charge_ball: MeshInstance3D
var impact: MeshInstance3D
var dish_material: StandardMaterial3D
var energy: StandardMaterial3D
var halo: StandardMaterial3D
var departure_origin=Vector3.ZERO
var departure_direction=Vector3.ZERO
var departure_rotation: float=0
var departure_heading: float=0
var departure_audio: AudioStreamPlayer
var departure=preload("res://scripts/ship_departure.gd").new()
var departure_started: bool=false
var target: Vector3
var last_remaining: float=120
var departing: bool=false
var departure_age: float=0
var departure_scale=Vector3.ONE
var beam_fraction: float=0
var feed_count: int=0
static var retained_materials: Array=[]

func setup() -> void:
	name="DeathStar"
	hull=Node3D.new();hull.name="BattleStation";add_child(hull)
	var steel=ShaderMaterial.new();steel.shader=preload("res://shaders/death_star.gdshader")
	Models.sphere(hull,Vector3.ZERO,RADIUS,steel).name="ArmoredSphere"
	dish_material=Models.material(Color("354149"),.6)
	energy=Models.material(Color("e2ffdf"),0,3.2)
	halo=Models.material(Color("24f232"),0,1.2);halo.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;halo.albedo_color.a=.24;halo.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	build_dish()
	charge_ball=Models.sphere(hull,AXIS*(RADIUS+65),3,energy);charge_ball.name="Convergence"
	focus_halo=Models.sphere(hull,AXIS*(RADIUS+65),5,halo)
	for direction in [Vector3.RIGHT,Vector3.UP,Vector3.FORWARD,Vector3(1,0,1).normalized()]:
		focus_spikes.append({"node":beam(hull,energy,.35),"direction":direction})
	for i in 2:
		main_beams.append(beam(hull,halo if i==0 else energy,5.0 if i==0 else 1.6))
	impact=Models.sphere(self,Vector3.ZERO,8,energy);impact.name="PlanetImpact"
	counter=Label3D.new();counter.billboard=BaseMaterial3D.BILLBOARD_ENABLED;counter.no_depth_test=true
	counter.font_size=28;counter.pixel_size=.35;counter.modulate=Color("c1e8b8");add_child(counter);counter.set_as_top_level(true)
	if retained_materials.is_empty(): retained_materials=[steel,dish_material,energy,halo]
	update_sequence(120,Vector3.ZERO)

func dish_point(angle: float,radial: float,depth: float) -> Vector3:
	var right=Vector3.RIGHT
	var up: Vector3=AXIS.cross(right).normalized()
	return AXIS*depth+(right*cos(angle)+up*sin(angle))*radial

func build_dish() -> void:
	var mesh=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in 8:
		for segment in 64:
			var points: Array=[]
			for offset in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
				var r: float=(ring+offset.y)/8.0
				var angle: float=(segment+offset.x)*TAU/64
				points.append(dish_point(angle,r*RADIUS*.305,RADIUS*(.79+.163*r*r)))
			for point in points: mesh.add_vertex(point)
	mesh.generate_normals()
	var dish=MeshInstance3D.new();dish.mesh=mesh.commit();dish.material_override=dish_material
	dish_material.cull_mode=BaseMaterial3D.CULL_DISABLED;hull.add_child(dish);dish.name="RecessedSuperlaserDish"
	var rim=Models.material(Color("768187"),.6)
	for i in 64:
		var a: Vector3=dish_point(i*TAU/64,RADIUS*.306,RADIUS*.953)
		var b: Vector3=dish_point((i+1)*TAU/64,RADIUS*.306,RADIUS*.953)
		var segment=beam(hull,rim,1.0);line(segment,a,b,1.0)
	for i in 8:
		var source: Vector3=dish_point(i*TAU/8,RADIUS*.255,RADIUS*.91)
		var emitter=Models.sphere(hull,source,2.4,Models.material(Color("15351c"),.3))
		emitters.append(emitter)
		feeds.append(beam(hull,energy,.65))
		feed_halos.append(beam(hull,halo,1.8))
		packets.append(Models.sphere(hull,source,1.5,energy))
		feed_fractions.append(0.0)
	Models.sphere(hull,AXIS*(RADIUS*.80),4,Models.material(Color("192923"),.4))

func beam(parent: Node3D,material: Material,radius: float) -> MeshInstance3D:
	var node=MeshInstance3D.new();var tube=CylinderMesh.new()
	tube.top_radius=radius;tube.bottom_radius=radius;tube.height=1;tube.radial_segments=10
	node.mesh=tube;node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node);return node

func line(node: MeshInstance3D,a: Vector3,b: Vector3,width: float) -> void:
	var delta: Vector3=b-a
	node.position=(a+b)*.5
	var axis: Vector3=delta.normalized() if delta.length()>.001 else Vector3.UP
	var tangent: Vector3=axis.cross(Vector3.RIGHT).normalized()
	if tangent.length_squared()<.01: tangent=axis.cross(Vector3.FORWARD).normalized()
	node.basis=Basis(tangent,axis,tangent.cross(axis).normalized())
	node.scale=Vector3(width,maxf(.001,delta.length()),width)

func arrival_visual(age: float) -> void:
	# Exactly the normal ship's 0.65-second contraction/squash/rebound.
	# No portal ring, growth animation or prolonged reveal.
	jump_visuals.arrival_age=age if age<JumpVisuals.SNAP_SECONDS else -1.0
	hull.scale=jump_visuals.ship_scale(idle_drive)

func update_sequence(remaining: float,planet_center: Vector3) -> void:
	last_remaining=remaining;target=planet_center
	var age: float=120.0-remaining
	arrival_visual(age)
	var charge: float=clampf((CHARGE_REMAINING-remaining)/(CHARGE_REMAINING-FIRE_REMAINING),0,1)
	var firing: bool=remaining<=FIRE_REMAINING
	var pulse: float=1.0+.12*sin(age*23.0)
	var convergence: Vector3=AXIS*(RADIUS+65)
	var charge_age: float=CHARGE_REMAINING-remaining
	feed_count=clampi(1+floori(charge_age/FEED_STAGGER),0,8) if charge_age>=0 else 0
	for i in 8:
		var active: bool=i<feed_count
		feeds[i].visible=active
		feed_halos[i].visible=active;packets[i].visible=active
		emitters[i].material_override=energy if active else dish_material
		var progress: float=clampf((charge_age-i*FEED_STAGGER)/FEED_TRAVEL,0,1) if active else 0.0
		feed_fractions[i]=progress
		if active:
			var flicker: float=.8+.2*sin(charge_age*51.0+i*1.9)
			var endpoint: Vector3=emitters[i].position.lerp(convergence,progress)
			line(feeds[i],emitters[i].position,endpoint,pulse*flicker)
			line(feed_halos[i],emitters[i].position,endpoint,1.1+charge*.5)
			# Rapid energy packets race into the shared focus after each snap-on.
			var flow: float=fposmod(maxf(0,charge_age-i*FEED_STAGGER)*8.0,1.0)*progress
			packets[i].position=emitters[i].position.lerp(convergence,flow)
			packets[i].scale=Vector3.ONE*(.65+charge*.65)*flicker
	charge_ball.visible=charge_age>=0;focus_halo.visible=charge_age>=0
	charge_ball.scale=Vector3.ONE*(.5+charge*1.8)*pulse
	focus_halo.scale=Vector3.ONE*(1.0+charge*2.4)*(.9+.1*sin(charge_age*37))
	for spike in focus_spikes:
		spike.node.visible=charge_age>=0
		var extent: float=(4+charge*12)*(.75+.25*sin(charge_age*43))
		line(spike.node,convergence-spike.direction*extent,convergence+spike.direction*extent,1.0)
	energy.emission_energy_multiplier=2.5+charge*2.5
	beam_fraction=clampf((FIRE_REMAINING-remaining)/.35,0,1) if firing else 0
	var hit: Vector3=to_local(planet_center)
	# The caller supplies the exact near-surface impact point.
	for i in main_beams.size():
		main_beams[i].visible=firing
		if firing: line(main_beams[i],convergence,convergence.lerp(hit,beam_fraction),pulse*(1.7 if i==0 else 1.0))
	impact.visible=firing and beam_fraction>=.99
	impact.position=to_local(planet_center)
	impact.scale=Vector3.ONE*(1.0+sin(age*35.0)*.15)
	counter.position=global_position+Vector3(0,100,RADIUS+30)
	counter.text=reckoning_title()+"\n%02d:%02d" % [maxi(0,ceili(remaining))/60,maxi(0,ceili(remaining))%60]

func begin_departure(_victory: bool) -> void:
	departing=true;departure_age=0;departure_scale=hull.scale
	jump_visuals.reset()
	departure_origin=position;departure_rotation=rotation.y
	departure_direction=(global_position-target).normalized();departure_direction.y=0
	departure_direction=departure_direction.normalized()
	if departure_direction.length_squared()<.5: departure_direction=Vector3.BACK
	departure_heading=-atan2(departure_direction.x,-departure_direction.z)
	counter.text=reckoning_title()+"\nWITHDRAWING"
	for feed in feeds: feed.hide()
	for ray in feed_halos+packets: ray.hide()
	for spike in focus_spikes: spike.node.hide()
	charge_ball.hide();focus_halo.hide();impact.hide()
	for ray in main_beams: ray.hide()

func set_audio_state(muted: bool,running: bool) -> void:
	if departure_started: departure.set_audio_state(muted,running)

# Retain the slow withdrawal, then hand movement and visuals to the SAME
# hyperspace integrator used by the pilot. A 20-speed custom burn used to
# finish at only 150 units/sec and looked parked beside a large planet.
func advance(dt: float) -> bool:
	if not departing: return false
	var previous: float=departure_age
	departure_age+=dt
	var lead: float=TURN_SECONDS+RETREAT_SECONDS
	if not departure_started:
		rotation.y=lerp_angle(departure_rotation,departure_heading,smoothstep(0,TURN_SECONDS,minf(departure_age,lead)))
		var retreat: float=clampf(departure_age-TURN_SECONDS,0,RETREAT_SECONDS)
		position=departure_origin+departure_direction*RETREAT_SPEED*retreat
		hull.scale=Vector3.ONE.lerp(departure_scale,1.0-smoothstep(0,.65,departure_age))
		if departure_age>=lead:
			var ship_fields: Dictionary=game.pilot.flight_fields(game.catalog.record("ships",game.pilot.ship_id).fields)
			departure.setup(game,self,hull,Vector2(position.x,position.z),Vector2(departure_direction.x,departure_direction.z)*RETREAT_SPEED,-rotation.y,ship_fields)
			departure_started=true;departure_audio=departure.audio
	if departure_started:
		var step_dt: float=dt if previous>=lead else maxf(0,departure_age-lead)
		if departure.advance(step_dt): return true
		counter.text=reckoning_title()+"\n"+departure.phase().to_upper()
	counter.position=global_position+Vector3(0,100,RADIUS+30)
	return false
