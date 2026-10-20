extends SceneTree
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-asteroid-motion.json";game.controls.path="/tmp/ev-asteroid-motion-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.pilot.system_id=128;game.load_system();game.set_mode("flight")
	var field=game.environment_hazards
	check(not field.rocks.is_empty(),"original asteroid system has moving rocks")
	var rock: Dictionary=field.rocks[0];var position: Vector2=rock.position;var rotation: Vector3=rock.node.rotation
	field.advance(1)
	check(rock.position.distance_to(position)>1 and rock.node.rotation.distance_to(rotation)>.1,"asteroid translates and tumbles with stationary pilot")
	check(Vector2(rock.node.position.x,rock.node.position.z).is_equal_approx(rock.position),"weapon obstruction position follows the visible asteroid")
	game.set_mode("pause");position=rock.position;rotation=rock.node.rotation;field.advance(4)
	check(rock.position==position and rock.node.rotation==rotation,"pause freezes drift and spin")
	game.set_mode("flight")
	var positions: Array[Vector2]=[];var rotations: Array[Vector3]=[]
	for fps in [30,60,120]:
		game.load_system()
		for frame in fps*4: field.advance(1.0/fps)
		positions.append(field.rocks[0].position);rotations.append(field.rocks[0].node.rotation)
	check(positions[0].distance_to(positions[2])<.001 and rotations[0].distance_to(rotations[2])<.001,"motion agrees at 30, 60 and 120 FPS")
	game.pilot.position=Vector2(50000,-50000);field.advance(100000)
	check(field.rocks.all(func(item):return absf(item.position.x-game.pilot.position.x)<=3200 and absf(item.position.y-game.pilot.position.y)<=3200),"field recycles offscreen around a travelling pilot")
	game.free();await process_frame
	print("ASTEROID MOTION: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
