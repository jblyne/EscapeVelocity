extends RefCounted
var game
var active: bool = false
var amount: float = 0.0
const FADE_SECONDS=1.25
var materials: Array=[]
var shadows: Array=[]
var visual_model: Node3D
# Retain shader variants between toggles and system changes.
var material_cache: Dictionary={}

func available() -> bool:
	return game.pilot.outfit_count(167)>0 or game.pilot.cheat_cloak

func toggle() -> bool:
	if game.mode != "flight": return false
	if not active and not available():
		game.notify("No cloaking device installed. Earn it through Rebel missions, or enable Cloaking device in C · Cheats.")
		return false
	if not active and ((game.pilot.fuel<1 and not game.pilot.cheat_infinite_fuel) or game.pilot.shield<1):
		game.notify("Cloaking requires shield power and fuel.")
		return false
	set_active(not active,true)
	game.notify(("Cloaking device engaged · weapons ready · K to decloak." if game.pilot.cheat_cloak else "Cloaking device engaged · weapons offline · K to decloak.") if active else "Cloaking device disengaged.")
	return true

func set_active(value: bool, animate: bool=false) -> void:
	var changed=value!=active
	active=value
	if changed and animate:
		game.audio["cloak_off" if active else "cloak_on"].stop()
		game.sound("cloak_on" if active else "cloak_off")
	if not animate:
		amount=1.0 if active else 0.0
		if not active:
			restore_materials()
			return
	if active: prepare_materials()
	apply_visual()

func prepare_materials() -> void:
	if visual_model==game.player_model and not materials.is_empty(): return
	restore_materials()
	if not is_instance_valid(game.player_model): return
	visual_model=game.player_model
	for node in visual_model.find_children("*","MeshInstance3D",true,false):
		if str(node.name).begins_with("Flame"): continue
		shadows.append({"node":node,"cast":node.cast_shadow})
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if node.material_override is StandardMaterial3D:
			copy_material(node,-1,node.material_override)
		elif node.material_override==null and node.mesh!=null:
			for surface in node.mesh.get_surface_count():
				var original=node.get_active_material(surface)
				if original is StandardMaterial3D: copy_material(node,surface,original)

func copy_material(node: MeshInstance3D, surface: int, original: StandardMaterial3D) -> void:
	var copy: StandardMaterial3D=fade_material(original)
	var previous=node.material_override if surface<0 else node.get_surface_override_material(surface)
	materials.append({"node":node,"surface":surface,"original":previous,"copy":copy,"color":original.albedo_color,"energy":original.emission_energy_multiplier})
	if surface<0: node.material_override=copy
	else: node.set_surface_override_material(surface,copy)

func fade_material(original: StandardMaterial3D) -> StandardMaterial3D:
	var key=original.get_instance_id()
	if not material_cache.has(key):
		var copy: StandardMaterial3D=original.duplicate()
		copy.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material_cache[key]=copy
	return material_cache[key]

func warm_model(model: Node3D) -> void:
	# Render the retained transparent variants in the startup warm-up viewport,
	# so engaging cloak doesn't compile shaders in the middle of flight.
	for node in model.find_children("*","MeshInstance3D",true,false):
		if node.material_override is StandardMaterial3D:
			var copy=fade_material(node.material_override)
			var color=copy.albedo_color;color.a=.5;copy.albedo_color=color
			node.material_override=copy

func visibility_factor() -> float:
	return 1.0-smoothstep(0.0,1.0,amount)

func rebind_model() -> void:
	# Called before the destination's first rendered frame; retain an in-flight
	# transition as well as a fully engaged cloak, without replaying its sound.
	if active or amount>0:
		prepare_materials()
		apply_visual()

func apply_visual() -> void:
	# Material alpha works with the project's Compatibility renderer; the old
	# GeometryInstance3D.transparency property did not. Alpha fading leaves
	# a faint local silhouette while sensors treat the ship as concealed.
	var eased=smoothstep(0.0,1.0,amount)
	for item in materials:
		var color: Color=item.color
		color.a*=lerpf(1.0,0.12,eased)
		item.copy.albedo_color=color
		item.copy.emission_energy_multiplier=item.energy*(1.0-eased)

func update_visual(dt: float) -> void:
	amount=move_toward(amount,1.0 if active else 0.0,dt/FADE_SECONDS)
	if not active and amount<=0:
		restore_materials()
		return
	if active: prepare_materials()
	apply_visual()

func restore_materials() -> void:
	for item in materials:
		if not is_instance_valid(item.node): continue
		if item.surface<0: item.node.material_override=item.original
		else: item.node.set_surface_override_material(item.surface,item.original)
	for item in shadows:
		if is_instance_valid(item.node): item.node.cast_shadow=item.cast
	materials.clear();shadows.clear();visual_model=null

func advance(dt: float) -> void:
	if not active: return
	game.pilot.shield=maxf(0,game.pilot.shield-8*dt)
	if not game.pilot.cheat_infinite_fuel: game.pilot.fuel=maxf(0,game.pilot.fuel-2*dt)
	var reason=""
	if not available(): reason="device unavailable"
	elif game.pilot.shield<=0: reason="shield power depleted"
	elif game.pilot.fuel<=0 and not game.pilot.cheat_infinite_fuel: reason="fuel depleted"
	if not reason.is_empty():
		set_active(false,true)
		game.notify("Cloaking device disengaged: "+reason+".")
