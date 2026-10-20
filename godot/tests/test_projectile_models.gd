extends SceneTree
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-projectile-models.json";game.controls.path="/tmp/ev-projectile-model-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.set_mode("flight");game.target_index=-1;game.environment_hazards.rocks=[]
	for id in [131,132,139,140,150]:
		check(game.arsenal.fire(id,Vector2(10000,10000),0),"updated projectile fires through actual arsenal: %d" % id)
		var shot=game.shots.back()
		check(shot.node.get_meta("projectile_model",-1)==id and shot.node.get_child_count()>0,"actual shot uses distinct reference model: %d" % id)
		var start: Vector2=shot.position;var life: float=shot.life;var velocity: Vector2=shot.velocity
		game.update_shots(.1)
		check(shot.position.is_equal_approx(start+velocity*.1) and is_equal_approx(shot.life,life-.1),"model preserves projectile speed and lifetime: %d" % id)
		var clock: float=shot.visual_age
		game.set_mode("pause");game._physics_process(.2)
		check(shot.visual_age==clock,"projectile animation pauses with flight: %d" % id)
		game.set_mode("flight");shot.life=.001;game.update_shots(.01)
		check(shot not in game.shots and shot.node.is_queued_for_deletion(),"updated projectile cleans up on expiry: %d" % id)
	game.free();await process_frame
	print("PROJECTILE MODELS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
