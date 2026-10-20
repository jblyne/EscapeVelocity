extends Node3D

const Explosion = preload("res://scripts/explosion.gd")
const HUMAN_LINES: Array[String]=["end","no","fathers","regret","engines","family"]
static var line_bag: Array[String]=[]
static var last_line: String=""
signal secondary_blast
var age: float = 0.0
var blast_scale: float = 1.0
var origin: Vector3
var drift: Vector3
var halves: Array[Dictionary] = []
var rng = RandomNumberGenerator.new()
var duration: float = 0.0

# Clip the actual hull triangles, so even a single-piece hull becomes
# complementary pieces. No live ship, collider, or script is duplicated.
func setup(source: Node3D, motion: Vector2, seed_value: int = -1, size_multiplier: float = 1.0) -> void:
	if seed_value < 0: rng.randomize()
	else: rng.seed = seed_value
	blast_scale=clampf(source.scale.x/24.0,.65,2.5)*size_multiplier
	origin=position
	drift=Vector3(motion.x,0,motion.y)*.65
	var parts: Array[Dictionary]=[]
	var low: float=INF
	var high: float=-INF
	for child in source.get_children():
		if not child is MeshInstance3D or str(child.name).begins_with("Flame"): continue
		if not child.material_override is StandardMaterial3D: continue
		var faces: PackedVector3Array=child.mesh.get_faces()
		for i in faces.size():
			faces[i]=child.transform*faces[i]
			low=minf(low,faces[i].z)
			high=maxf(high,faces[i].z)
		parts.append({"faces":faces,"material":child.material_override})
	var piece_count: int=rng.randi_range(2,3) if float(source.get_meta("hull_mass",0))>=300 else 2
	var first: float=rng.randf_range(2.2,3.2)
	var timers: Array[float]=[first]
	for i in range(1,piece_count): timers.append(timers[-1]+rng.randf_range(1.0,1.7))
	if rng.randf()<.5: timers.reverse()
	for index in piece_count:
		var lower: float=lerpf(low,high,float(index)/piece_count)
		var upper: float=lerpf(low,high,float(index+1)/piece_count)
		var cut: float=upper if index==0 else lower
		var side: float=-1.0 if index==0 else 1.0
		var center=Vector3(0,0,(lower+upper)*.5)
		var planes: Array=[]
		if index>0: planes.append(Vector2(lower,1))
		if index<piece_count-1: planes.append(Vector2(upper,-1))
		var hull=Node3D.new()
		hull.name="BurningHalf%d" % index
		hull.basis=source.basis
		hull.set_meta("radius",float(source.get_meta("radius",24))*.65)
		add_child(hull)
		for part in parts:
			var surface=SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			var cap_sets: Array=[]
			for plane in planes: cap_sets.append([])
			var vertices: int=0
			for i in range(0,part.faces.size(),3):
				var polygon: Array[Vector3]=[]
				for j in 3: polygon.append(part.faces[i+j])
				for p in planes.size():
					polygon=clip_polygon(polygon,planes[p],cap_sets[p])
				for j in range(1,polygon.size()-1):
					for point in [polygon[0],polygon[j],polygon[j+1]]:
						surface.add_vertex(point-center)
						vertices+=1
			if vertices>0:
				surface.generate_normals()
				var material: StandardMaterial3D=part.material.duplicate()
				material.albedo_color.a=1.0
				material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
				add_mesh(hull,surface.commit(),material)
			for caps in cap_sets:
				if caps.size()<3: continue
				var midpoint=Vector3.ZERO
				for point in caps: midpoint+=point
				midpoint/=caps.size()
				caps.sort_custom(func(a: Vector3,b: Vector3): return atan2(a.y-midpoint.y,a.x-midpoint.x)<atan2(b.y-midpoint.y,b.x-midpoint.x))
				var cap=SurfaceTool.new()
				cap.begin(Mesh.PRIMITIVE_TRIANGLES)
				for i in caps.size():
					for point in [midpoint,caps[i],caps[(i+1)%caps.size()]]: cap.add_vertex(point-center)
				cap.generate_normals()
				var hot=Explosion.Models.material(Color("9b3516"),.5,1.5)
				hot.cull_mode=BaseMaterial3D.CULL_DISABLED
				add_mesh(hull,cap.commit(),hot)
		var separation: float=lerpf(-1,1,float(index)/float(piece_count-1))
		var velocity: Vector3=source.basis.orthonormalized()*Vector3(rng.randf_range(-4,4),0,separation*rng.randf_range(18,28))
		var half={"node":hull,"offset":source.basis*center,"velocity":velocity,"basis":source.basis,
			"spin":Vector3(rng.randf_range(-.12,.12),side*rng.randf_range(.12,.3),rng.randf_range(-.1,.1)),
			"seam":Vector3(0,.12,cut)-center,"timer":timers[index],"exploded":false,"blast":null,"fire":[],"size":size_multiplier,"voice":null}
		for i in 4:
			var fire=MeshInstance3D.new()
			var plane=PlaneMesh.new()
			plane.size=Vector2(2,2)
			fire.mesh=plane
			fire.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var shader=ShaderMaterial.new()
			shader.shader=Explosion.EFFECT_SHADER
			shader.set_shader_parameter("kind",1 if i==3 else 0)
			shader.set_shader_parameter("life",1.8)
			shader.set_shader_parameter("seed_value",rng.randf_range(0,100))
			fire.material_override=shader
			add_child(fire)
			half.fire.append(fire)
		halves.append(half)
		duration=maxf(duration,timers[index]+Explosion.DURATION)
	advance(0)

func add_mesh(parent: Node3D, mesh: Mesh, material: Material) -> void:
	var node=MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=material
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)

func clip_polygon(polygon: Array[Vector3], plane: Vector2, caps: Array) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for j in polygon.size():
		var a: Vector3=polygon[j]
		var b: Vector3=polygon[(j+1)%polygon.size()]
		var da: float=(a.z-plane.x)*plane.y
		var db: float=(b.z-plane.x)*plane.y
		if da>=0: result.append(a)
		if (da>0 and db<0) or (da<0 and db>0):
			var crossing: Vector3=a.lerp(b,da/(da-db))
			result.append(crossing)
			if not caps.any(func(point): return point.distance_squared_to(crossing)<.0000001): caps.append(crossing)
	return result

func place_half(half: Dictionary, t: float) -> void:
	half.node.position=half.offset+half.velocity*t
	half.node.basis=Basis.from_euler(half.spin*t)*half.basis

func advance(dt: float) -> bool:
	age+=dt
	position=origin+drift*age
	# Resolve detonations chronologically, including frames that cross several timers.
	var pending: Array=halves.filter(func(piece): return not piece.exploded and piece.timer<=age)
	pending.sort_custom(func(a,b): return a.timer<b.timer)
	for half in pending:
		for piece in halves:
			if not piece.exploded: place_half(piece,half.timer)
		var blast=Explosion.new()
		add_child(blast)
		blast.position=half.node.position
		blast.setup(half.node,Vector2(half.velocity.x,half.velocity.z),rng.randi(),half.size*.65)
		for person in blast.people: person.node.queue_free()
		blast.people.clear()
		half.blast=blast
		half.exploded=true
		for survivor in halves:
			if survivor.exploded: continue
			var away: Vector3=(survivor.node.position-half.node.position).normalized()
			if away.is_zero_approx(): away=Vector3.FORWARD
			var kick: Vector3=away*maxf(90*blast_scale,90*blast_scale-(survivor.velocity+drift).dot(away))
			# Rebase the analytic trajectory at the impact time: no position snap.
			survivor.offset-=kick*half.timer
			survivor.velocity+=kick
		if is_instance_valid(half.voice): half.voice.stop()
		half.node.hide()
		for fire in half.fire: fire.hide()
		secondary_blast.emit()
	for half in halves:
		if not half.exploded:
			place_half(half,minf(age,half.timer))
			for i in half.fire.size():
				var fire: MeshInstance3D=half.fire[i]
				var phase: float=fmod(age+float(i)*.43,1.8)
				fire.material_override.set_shader_parameter("age",phase)
				fire.position=half.node.transform*(half.seam+Vector3((i-1)*.18,0,0))
				fire.position.y+=12+i*2
				var radius: float=half.node.scale.x*(.30 if i<3 else .7)*(1+phase*.4)
				fire.scale=Vector3(radius,1,radius)
		elif is_instance_valid(half.blast):
			half.blast.advance(maxf(0,age-half.timer-half.blast.age))
	return age>=duration

# Each wreck owns its player: a sibling blast never cuts off the survivor.
static func next_human_line() -> String:
	if line_bag.is_empty():
		line_bag.assign(HUMAN_LINES)
		line_bag.shuffle()
		if line_bag[-1]==last_line:
			var swap: String=line_bag[0]
			line_bag[0]=line_bag[-1];line_bag[-1]=swap
	last_line=line_bag.pop_back()
	return last_line

func start_crew_audio(alien: bool, muted: bool, active: bool) -> void:
	var take: int=rng.randi_range(1,2)
	var used_lines: Array[String]=[]
	for i in halves.size():
		var player=AudioStreamPlayer.new()
		var key: String="wreck_alien_%d" % (1+(i+take)%2)
		if not alien:
			var line: String=next_human_line()
			# A three-piece wreck can straddle a shuffle boundary.
			if line in used_lines:
				for slot in line_bag.size():
					if line_bag[slot] not in used_lines:
						var replacement: String=line_bag[slot]
						line_bag[slot]=line;line=replacement;last_line=line;break
			used_lines.append(line)
			key="wreck_%s_%d" % [line,rng.randi_range(1,2)]
		var stream: AudioStreamWAV=load("res://audio/"+key+".wav").duplicate()
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin=0
		stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
		player.name=key
		player.stream=stream
		player.volume_db=-80 if muted else -10
		add_child(player)
		halves[i].voice=player
		player.play()
		player.stream_paused=not active

func set_audio_state(muted: bool, active: bool) -> void:
	for half in halves:
		if not is_instance_valid(half.voice): continue
		half.voice.volume_db=-80 if muted else -10
		half.voice.stream_paused=not active
