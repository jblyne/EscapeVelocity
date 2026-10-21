extends SceneTree
const Debris=preload("res://scripts/planet_debris.gd")
const Rupture=preload("res://scripts/planet_rupture.gd")
var game
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var station=Debris.new();root.add_child(station);station.setup(Vector3.ZERO,100,129,true)
	check(station.shards.any(func(shard):return shard.velocity==Vector3.ZERO) and station.shards.any(func(shard):return shard.velocity.length()>0),"Station blast leaves a wreckage core while other plates fly outward")
	station.free()
	var reference: Vector3
	for rate in [30,60,120]:
		var debris=Debris.new();root.add_child(debris);debris.setup(Vector3.ZERO,100,128)
		check(debris.shards.all(func(s):return s.origin.dot(s.velocity)>0),"All remaining shards launch outward at %d Hz" % rate)
		var scale: Vector3=debris.shards[0].node.scale
		for i in rate*10: debris.advance(1.0/rate)
		var actual: Vector3=debris.shards[0].node.position
		var expected: Vector3=debris.shards[0].origin+debris.shards[0].velocity*10
		check(actual.distance_to(expected)<.001,"Ballistic displacement matches elapsed time at %d Hz" % rate)
		if rate==30: reference=actual
		else: check(actual.distance_to(reference)<.001,"Shard position agrees across frame rates at %d Hz" % rate)
		check(debris.shards[0].node.scale==scale and debris.shards[0].node.rotation.length()>0,"Shards keep their size and tumble at %d Hz" % rate)
		debris.queue_free()
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-planet-debris-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.pilot.system_id=129;game.load_system();game.set_mode("flight");game.landing_target=128
	game.pilot.position=game.world_killer.target_position(128)+Vector2(0,600)
	game.world_activity.open_contact();game.world_killer.threaten();game.world_killer.deploy()
	var killer=game.world_killer;killer.advance(120)
	check(killer.destroyed(128) and killer.remnants.size()==1,"Actual detonation creates moving planetary remains")
	var blast=killer.effects.filter(func(e):return e.get_script()==Rupture)[0]
	killer.advance(2);var p0: Vector3=blast.fragments[0].node.position
	killer.advance(1);var p1: Vector3=blast.fragments[0].node.position
	killer.advance(1);var p2: Vector3=blast.fragments[0].node.position
	check((p2-p1).distance_to(p1-p0)<.001,"Large crust fragments keep constant speed instead of slowing to a stop")
	var debris=killer.remnants[0];p0=debris.shards[0].node.position
	game.set_mode("pause");killer.advance(20)
	check(debris.shards[0].node.position==p0,"Pause freezes planetary debris")
	game.set_mode("flight");killer.advance(30);p1=debris.shards[0].node.position
	check(is_instance_valid(debris) and debris.age>=34,"Remnant motion survives transient explosion cleanup")
	killer.advance(30);p2=debris.shards[0].node.position
	check((p2-p1).distance_to(debris.shards[0].velocity*30)<.01,"Long-lived shards keep flying without a settling radius")
	check(p2.length()>killer.target_radius(128)*35,"Shards disperse far beyond former planet rather than parking nearby")
	game.save_game(false);game.load_game()
	check(killer.destroyed(128) and killer.remnants.size()==1,"Destroyed-world save restores its remnant field")
	debris=killer.remnants[0];p0=debris.shards[0].node.position;killer.advance(60)
	check(debris.shards[0].node.position.distance_to(p0)>0 and debris.shards[0].node.position.distance_to(p0)<killer.target_radius(128)*.2,"Reloaded remains drift gently around the former planet")
	game.pilot.system_id=128;game.load_system()
	game.pilot.system_id=129;game.load_system()
	check(killer.remnants[0].shards[0].node.position==p0,"Returning restores the same seeded planet field")
	for metallic in [false,true]:
		var field=Debris.new();root.add_child(field)
		var center=Vector3(120,0,-340)
		field.setup(center,100,129,metallic,true)
		var positions: Array=[]
		for shard in field.shards: positions.append(shard.node.position)
		field.advance(3600)
		check(field.position==center and field.shards.all(func(shard):return shard.node.position.distance_to(positions[field.shards.find(shard)])<20),"Restored planet/station fragments stay within local drift bounds after an hour: %s" % metallic)
		check(field.shards.any(func(shard):return shard.node.position.distance_to(shard.origin)>.1),"Field fragments move locally: %s" % metallic)
		check(field.shards[0].node.rotation!=field.shards[0].rotation,"Field fragments visibly tumble: %s" % metallic)
		var sample=Debris.new();root.add_child(sample);sample.setup(center,100,129,metallic,true)
		for i in 60: sample.advance(1.0/60)
		var expected=Debris.new();root.add_child(expected);expected.setup(center,100,129,metallic,true);expected.advance(1)
		check(sample.shards[0].node.position.distance_to(expected.shards[0].node.position)<.001,"Local drift is frame rate independent: %s" % metallic)
		sample.free();expected.free();field.free()
	game.pilot.system_id=128;game.load_system()
	check(killer.remnants.is_empty(),"Changing systems clears old debris tracking")
	print("PLANET DEBRIS: %d checks; %d failures" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
