extends SceneTree
var failures=0
var checks=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
	else: print("PASS: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-autoland-pilot.json";game.controls.path="/tmp/ev-autoland-controls.json"
	game.traffic.enabled=false;game.muted=true
	root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.set_mode("flight")
	var port: Dictionary=game.planets[0]
	game.pilot.position=port.position+Vector2(2000,0);game.velocity=Vector2(0,130)
	game.land_pressed()
	check(not game.auto_landing and game.landing_target==port.id,"Single L selects destination and requests clearance")
	game.land_pressed()
	check(game.auto_landing,"Rapid second L starts auto landing")
	game.land_pressed()
	check(not game.auto_landing,"L cancels an active approach")
	game.land_pressed();game.land_pressed()
	check(game.auto_landing,"Approach can be restarted")
	for frame in 36000:
		game._physics_process(1.0/60)
		if game.mode!="flight": break
	check(game.mode in ["dock","mission_report"] and game.docked_id==port.id,"Autopilot turns, brakes and lands at the chosen port from a sideways drift")
	check(game.velocity==Vector2.ZERO and not game.auto_landing,"Landing ends autopilot and stops the ship")
	game.set_mode("flight");game.pilot.position=port.position+Vector2(2000,0)
	game.land_pressed();game.land_pressed()
	game.set_mode("map")
	check(not game.auto_landing,"Opening a menu cancels autopilot")
	game.free();await process_frame
	print("AUTO LANDING: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
