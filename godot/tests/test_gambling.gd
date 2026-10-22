extends SceneTree
var failures=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures+=1;push_error(message)
func run() -> void:
	var slots=load("res://scripts/classic_gambling.gd")
	check(slots.payout(1000,[0,0,0])==3000,"Triple payout")
	check(slots.payout(5000,[2,3,2])==6500,"Pair payout")
	check(slots.payout(1000,[1,2,3])==0,"No-match payout")
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev193-gambling.json";game.controls.path="/tmp/ev193-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.pilot.credits=10000;game.hud.port_page="gambling";game.set_mode("dock");await process_frame
	var machine=game.hud.modal_root.get_child(0)
	machine.rng.seed=42;machine.spin(1000)
	var settled: int=game.pilot.credits
	check(settled==9000+machine.winnings,"Single complete transaction")
	var saved=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(int(saved.credits)==settled,"Settled balance persists")
	machine.spin(5000);check(game.pilot.credits==settled,"Cannot bet during spin")
	machine._process(3);check(not machine.spinning,"Animation completes")
	game.pilot.credits=999;machine.spin(1000);check(game.pilot.credits==999 and not machine.spinning,"Insufficient funds")
	machine.spin(-1000);check(game.pilot.credits==999,"Reject invalid wager")
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("/tmp/ev193-gambling.png")
	game.free();print("GAMBLING: %d failures" % failures);quit(1 if failures else 0)
