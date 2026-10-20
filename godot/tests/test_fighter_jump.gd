extends SceneTree
var failures=0
func check(ok: bool, message: String) -> void:
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-fighter-jump.json";game.controls.path="/tmp/ev-fighter-jump-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.set_mode("flight")
	game.arsenal.launch_escort(129,game.pilot.position,0)
	game.arsenal.launch_escort(131,game.pilot.position,0)
	game.load_system(0.0)
	check(game.escorts.size()==2,"both launched fighters survive a jump")
	check(not game.escorts[0].model.visible,"fighters arrive after flagship")
	game.arsenal.update_escorts(.36)
	check(game.escorts[0].model.visible and not game.escorts[1].model.visible,"fighter arrivals are staggered")
	check(game.escorts[0].has("arrival_visual"),"fighters use ship warp arrival visuals")
	game.arsenal.update_escorts(.2)
	check(game.escorts[1].model.visible,"second fighter arrives")
	game.arsenal.update_escorts(.7)
	game.arsenal.update_escorts(.7)
	check(not game.escorts[0].has("arrival_visual") and game.escorts[0].model.scale==Vector3.ONE,"warp settles before normal fighter AI")
	game.load_system(1.0,true)
	check(game.escorts.size()==2,"chain jump retains fighters without duplicates")
	game.load_system()
	check(game.escorts.is_empty(),"fresh load clears transient fighters")
	game.free();await process_frame
	print("FIGHTER JUMP: 8 checks; %d failures" % failures);quit(1 if failures else 0)
