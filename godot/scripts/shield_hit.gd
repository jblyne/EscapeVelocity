extends Node3D

const SHADER = preload("res://shaders/shield_hit.gdshader")
const DURATION: float = 0.48
var age: float = DURATION
var material: ShaderMaterial

func setup(ship: Node3D) -> void:
	name = "ShieldHit"
	var extent = Vector3(0.4,0.3,0.8)
	for part in ship.get_children():
		if not part is MeshInstance3D or str(part.name).begins_with("Flame"): continue
		var bounds: AABB = part.get_aabb()
		for i in 8:
			var point: Vector3 = part.transform * bounds.get_endpoint(i)
			extent = extent.max(point.abs())
	ship.add_child(self)
	var shell = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 64
	sphere.rings = 32
	shell.mesh = sphere
	shell.scale = extent * 1.35 + Vector3.ONE * 0.12
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material = ShaderMaterial.new()
	material.shader = SHADER
	shell.material_override = material
	add_child(shell)
	hide()

func flash(world_direction: Vector2) -> void:
	var incoming: Vector2 = world_direction.normalized() if not world_direction.is_zero_approx() else Vector2.UP
	var direction = Vector3(incoming.x,0.15,incoming.y)
	var local_direction: Vector3 = get_parent().global_basis.inverse() * direction
	material.set_shader_parameter("impact_direction",local_direction.normalized())
	age = 0.0
	material.set_shader_parameter("age",age)
	show()

func advance(dt: float) -> void:
	age = minf(DURATION,age+dt)
	material.set_shader_parameter("age",age)
	visible = age < DURATION
