extends SceneTree
var game
var count: int = 0
var failures: int = 0

func check(ok: bool, message: String) -> void:
	count += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-explosion-pilot.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.breakup_chance=0.0 # This suite covers the immediate blast variant.
	game.muted=true
	game.traffic.enabled = false # Isolate this feature from independently tested ambient traffic.
	root.add_child(game)
	game.set_physics_process(false)
	game.set_process(false)
	check(is_equal_approx(game.audio.explosion.stream.get_length(),35840.0/11127.0),"ship explosion uses original sample duration")
	check(is_equal_approx(game.audio.heavy_explosion.stream.get_length(),11360.0/11127.0),"weapon blast uses separate original heavy sample")
	game.hud.set_process(false)
	game.traffic.spawn(134,128,3,game.pilot.position+Vector2(400,-200))
	var contact=game.npcs[0]
	game.target_index=0
	game.damage_npc(contact,1)
	check(game.explosions.is_empty(),"ordinary hits retain impact sparks without a destruction blast")
	contact.velocity=Vector2(100,40)
	game.damage_npc(contact,10000)
	check(game.explosions.size()==1 and contact not in game.npcs and game.selected_contact().is_empty(),"lethal damage creates one explosion and clears the destroyed target")
	var effect=game.explosions[0]
	check(effect.position==game.v3(contact.position) and effect.drift==Vector3(65,0,26),"blast starts at the ship and inherits its motion")
	var parts: int=0
	for node in contact.model.get_children():
		if node is MeshInstance3D and not str(node.name).begins_with("Flame"): parts+=1
	check(effect.blast_scale>1 and effect.fragments.size()==mini(parts,14)*2,"ships supply twice as many real hull fragments")
	check(effect.people.size()==2,"large ships eject two visible crew figures")
	var person=effect.people[0]
	var initial_person_position: Vector3=person.node.position
	var initial_arm_angle: float=person.left_arm.rotation.x
	game.damage_npc(contact,10000)
	check(game.explosions.size()==1,"repeated damage to a destroyed contact cannot duplicate the explosion")
	await process_frame
	check(not is_instance_valid(contact.model) and is_instance_valid(effect.fragments[0].node),"debris survives after the destroyed ship node is freed")
	var fragment=effect.fragments[0]
	var initial_basis: Basis=fragment.node.basis
	var initial_light: float=effect.flash_light.light_energy
	game.update_explosions(0.4)
	check(fragment.node.basis!=initial_basis and fragment.node.position.distance_to(fragment.offset)>10,"hull pieces tumble and travel away from the blast")
	check(person.node.position.distance_to(initial_person_position)>5 and person.left_arm.rotation.x!=initial_arm_angle,"crew figures drift, tumble, and move their limbs")
	check(effect.flash_light.light_energy<initial_light and effect.position!=effect.origin,"the flash decays while the explosion keeps drifting")
	var paused_age: float=effect.age
	game.set_mode("pause")
	game._physics_process(0.4)
	check(effect.age==paused_age,"pause freezes all explosion animation")
	game.set_mode("map")
	game._physics_process(0.4)
	check(effect.age==paused_age,"opening the map also freezes explosions")
	game.set_mode("cheats")
	game._physics_process(0.4)
	check(effect.age==paused_age,"cheat menu freezes explosions")
	game.set_mode("flight")
	game._physics_process(0.1)
	check(effect.age>paused_age,"returning to flight resumes the same explosion")
	game.update_explosions(3.7)
	check(is_instance_valid(effect) and effect.fragments[0].material.albedo_color.a>0.8,"debris remains clearly visible after the old lifetime")
	game.update_explosions(3.1)
	await process_frame
	check(game.explosions.is_empty() and not is_instance_valid(effect),"finished explosions free their complete scene")
	game.ship_explosion(game.player_model,game.pilot.position,Vector2.ZERO)
	game.update_explosions(5.0)
	game.ship_explosion(game.player_model,game.pilot.position,Vector2.ZERO)
	check(game.explosions[0].fragments[0].material.albedo_color.a<0.9 and game.explosions[1].fragments[0].material.albedo_color.a==1.0,"cached shaders preserve independent fading for simultaneous explosions")
	game.update_explosions(7.3)
	var small=game.Explosion.new()
	game.world.add_child(small)
	small.setup(game.player_model,Vector2.ZERO,99)
	check(small.people.size()==1,"small ships eject one visible crew figure")
	small.free()
	# Fixed seeds isolate frame-rate changes from intentional variation.
	var results: Array[Vector3]=[]
	for fps in [30,60,120]:
		var timed=game.Explosion.new()
		game.world.add_child(timed)
		timed.setup(game.player_model,Vector2(100,40),42)
		for frame in fps: timed.advance(1.0/fps)
		results.append(timed.fragments[0].node.position+timed.position)
		timed.free()
	check(results[0].distance_to(results[2])<0.001,"debris position is stable at 30 and 120 FPS")
	for i in game.MAX_EXPLOSIONS+3: game.ship_explosion(game.player_model,game.pilot.position,Vector2.ZERO)
	check(game.explosions.size()==game.MAX_EXPLOSIONS,"simultaneous destruction effects are bounded during heavy combat")
	var old_world=game.world
	game.load_system()
	await process_frame
	check(game.explosions.is_empty() and not is_instance_valid(old_world),"system changes remove active explosions and all their nodes")
	game.pilot.shield=0
	game.pilot.armor=1
	game.save_game(false)
	var living_save=FileAccess.get_file_as_string(game.save_path)
	for i in 2:
		game.fire(game.pilot.position,0,true)
		game.shots.back().position=game.pilot.position
		game.shots.back().velocity=Vector2.ZERO
	game.update_shots(0.01)
	check(game.mode=="dead" and not game.player_model.visible and game.explosions.size()==1,"player death hides the intact ship and triggers one explosion")
	check(game.hud.modal_root.get_child_count()==0,"the first fireball is visible before the recovery panel appears")
	var death_effect=game.explosions[0]
	game._physics_process(0.5)
	check(death_effect.age>0.4,"the player's explosion continues animating behind the death screen")
	game.update_shots(0.01)
	check(game.explosions.size()==1,"additional enemy shots cannot retrigger player destruction")
	check(not game.save_game(false) and FileAccess.get_file_as_string(game.save_path)==living_save,"destruction preserves the last living pilot save")
	game._physics_process(7.3)
	check(game.explosions.is_empty(),"player death effects also expire completely")
	check(game.hud.modal_root.get_child_count()>0,"the recovery panel appears after the initial player explosion")
	game.load_game()
	check(game.mode=="flight" and game.player_model.visible and game.pilot.armor>0,"loading the pilot restores a visible living ship")
	var styles: Dictionary={}
	for seed_value in 16:
		var variant=game.Explosion.new();game.world.add_child(variant)
		variant.setup(game.player_model,Vector2.ZERO,seed_value)
		styles[variant.blast_style]=true
		variant.free()
	check(styles.size()==4,"random destructions cover all four explosion styles")
	for style in 4:
		var positions: Array[Vector3]=[]
		for fps in [30,120]:
			var variant=game.Explosion.new();game.world.add_child(variant)
			variant.setup(game.player_model,Vector2(100,40),42,1.0,style)
			for frame in fps: variant.advance(1.0/fps)
			positions.append(variant.layers[0].node.position+variant.position)
			check(variant.advance(7.3) and variant.layers.all(func(item):return not item.node.visible),"variant expires all delayed layers: %s at %d FPS" % [variant.STYLE_NAMES[style],fps])
			variant.free()
		check(positions[0].distance_to(positions[1])<.001,"variant motion is frame-rate independent: "+game.Explosion.STYLE_NAMES[style])
	game.free()
	await process_frame
	DirAccess.remove_absolute("/tmp/ev-explosion-pilot.json")
	print("EXPLOSION RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
