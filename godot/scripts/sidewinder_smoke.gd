extends Node3D
const LIMIT=1536
const LIFETIME=1.6
var lifetime: float=LIFETIME
var puffs: Array=[]
var instances: MultiMesh
func _ready() -> void:
	var mesh=PlaneMesh.new();mesh.size=Vector2.ONE
	instances=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D;instances.use_custom_data=true;instances.mesh=mesh;instances.instance_count=LIMIT;instances.visible_instance_count=0
	var batch=MultiMeshInstance3D.new();batch.multimesh=instances;batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader=Shader.new()
	shader.code="""shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
varying vec4 puff;
void vertex(){puff=INSTANCE_CUSTOM;}
void fragment(){
 vec2 p=UV*2.0-1.0;
 float wobble=sin(p.x*9.0+puff.y*17.0)*sin(p.y*8.0+puff.y*11.0)*0.09;
 float cloud=1.0-smoothstep(0.25,1.0,length(p)+wobble);
 ALBEDO=vec3(0.54,0.57,0.60);
 ALPHA=cloud*puff.x*0.42;
}
"""
	var material=ShaderMaterial.new();material.shader=shader;batch.material_override=material;add_child(batch)
func emit_segment(shot: Dictionary,start: Vector2,finish: Vector2) -> void:
	if float(shot.get("boost_age",0))<.15: return
	var distance: float=start.distance_to(finish)
	var carried: float=float(shot.get("smoke_distance",0))
	var next: float=4-carried
	var direction: Vector2=(finish-start).normalized()
	while next<=distance:
		if puffs.size()<LIMIT:
			var at=start+direction*next-direction*10
			puffs.append({"position":at,"age":0.0,"seed":randf(),"drift":Vector2(randf_range(-3,3),randf_range(-3,3))})
		next+=4
	shot.smoke_distance=fmod(carried+distance,4)
func advance(dt: float) -> void:
	for i in range(puffs.size()-1,-1,-1):
		puffs[i].age+=dt
		if puffs[i].age>=lifetime: puffs.remove_at(i)
	instances.visible_instance_count=puffs.size()
	for i in puffs.size():
		var puff: Dictionary=puffs[i];var age: float=puff.age
		var radius: float=lerpf(10,24,age/lifetime)
		var at: Vector2=puff.position+puff.drift*age
		instances.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3(radius,1,radius)),Vector3(at.x,4,at.y)))
		instances.set_instance_custom_data(i,Color(pow(1-age/lifetime,1.4),puff.seed,0,0))
