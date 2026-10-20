extends SceneTree
const Breakup=preload("res://scripts/breakup.gd")
var game
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func launch(split: bool,weapon: int=191,lethal: bool=true) -> Dictionary:
	game.load_system();game.set_mode("flight")
	for npc in game.npcs.duplicate(): game.traffic.retire(npc)
	game.environment_hazards.rocks=[]
	game.breakup_chance=1.0 if split else 0.0
	var victim=game.traffic.spawn(134,128,3,Vector2(140,0))
	game.target_index=game.npcs.find(victim)
	game.arsenal.fire(weapon,Vector2.ZERO,PI/2)
	var shot=game.shots.back()
	shot.velocity=Vector2(800,0);shot.speed=800;shot.life=2
	shot.shield_damage=100000 if lethal else 1
	shot.armor_damage=100000 if lethal else 1
	return {"victim":victim,"shot":shot}
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-forklift-piercing.json";game.controls.path="/tmp/ev-forklift-piercing-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	var hit=launch(true);var shot: Dictionary=hit.shot
	var expected: Vector2=shot.position+shot.velocity*.2
	game.update_shots(.2)
	check(hit.victim not in game.npcs and game.explosions.back() is Breakup,"forklift splits and destroys its victim")
	check(shot in game.shots and not shot.node.is_queued_for_deletion(),"forklift model survives a split-hull impact")
	check(shot.position.is_equal_approx(expected) and shot.velocity.is_equal_approx(Vector2(800,0)),"forklift retains speed and completes its movement through the target")
	check(shot.kind=="bolt" and shot.target==null,"forklift cannot steer back toward the destroyed target")
	var before: Vector2=shot.position;game.update_shots(.2)
	check(shot in game.shots and shot.position.x>before.x,"forklift keeps flying beyond the wreck")
	shot.life=.01;game.update_shots(.02)
	check(shot not in game.shots,"piercing forklift still expires normally")
	hit=launch(false);game.update_shots(.2)
	check(hit.victim not in game.npcs and hit.shot not in game.shots,"immediate explosion still consumes forklift")
	hit=launch(true,128);game.update_shots(.2)
	check(hit.victim not in game.npcs and hit.shot not in game.shots,"other weapons are consumed even when target splits")
	hit=launch(true,191,false);game.update_shots(.2)
	check(hit.victim in game.npcs and hit.shot not in game.shots,"nonlethal hit does not gain piercing")
	game.free();await process_frame
	print("FORKLIFT PIERCING: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
