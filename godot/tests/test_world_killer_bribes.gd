extends SceneTree
const BattleStation=preload("res://scripts/death_star.gd")
var game
var killer
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func deploy() -> void:
	game.restart();game.pilot.cheat_world_killer=true;game.pilot.system_id=129;game.load_system();game.set_mode("flight")
	game.landing_target=128;game.pilot.position=killer.target_position(128)+Vector2(0,600)
	game.world_activity.open_contact();killer.threaten();check(killer.deploy(),"Deploy station for negotiation")
func capture() -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/death-star-bribe.png"))
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-bribe-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.pilot.cheat_world_killer=true
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false);killer=game.world_killer
	killer.negotiation_rng.seed=8675309
	deploy();killer.open_active()
	check(not killer.accept_bribe(),"No payout before a bribe has been offered")
	game.set_mode("flight");killer.advance(12)
	var offer: int=killer.bomb().bribe_offer
	check(offer>=20000 and offer<=130000 and killer.bomb().bribe_round==1,"First appeal offers varied planetary treasury funds")
	killer.open_active()
	var accept=game.hud.modal_root.find_child("AcceptWorldBribe",true,false)
	check(accept is Button and accept.text.contains(game.hud.commas(offer)),"Appeal shows exact bribe and recall action")
	check(game.world_activity.response.contains(game.hud.commas(offer)),"Planetary dialogue quotes the same offer")
	var money: int=game.pilot.credits
	var remaining: float=killer.bomb().remaining
	killer.advance(20);check(killer.bomb().remaining==remaining,"Negotiating pauses countdown")
	game.set_mode("flight");killer.open_active()
	check(killer.bomb().bribe_offer==offer,"Reopening channel does not reroll bribe")
	check(game.save_game(false),"Offer saves to disk")
	var previous_pilot=game.pilot
	game.load_game();killer.open_active()
	check(game.pilot!=previous_pilot and killer.bomb().bribe_offer==offer and killer.bomb().bribe_round==1,"Actual disk reload replaces pilot and preserves quoted offer")
	var delays: Array=[];var increases: Array=[]
	for round in 3:
		var old: int=killer.bomb().bribe_offer
		check(killer.deny(),"Refuse offered bribe")
		check(game.mode=="flight" and game.pilot.credits==money,"Refusal resumes flight without payment")
		var delay: float=killer.bomb().bribe_next-killer.bomb().elapsed;delays.append(delay)
		check(delay>=8 and delay<=18,"Next offer uses varied flight-time delay")
		check(not killer.deny(),"Duplicate refusal cannot reschedule next offer")
		game.set_mode("pause");killer.advance(delay+1)
		check(killer.bomb().bribe_offer==old,"Pause freezes negotiation escalation")
		game.set_mode("flight");killer.advance(delay-.1)
		check(killer.bomb().bribe_offer==old,"Bribe stays fixed until scheduled increase")
		if round==0:
			var scheduled: float=killer.bomb().bribe_next;game.save_game(false);game.load_game()
			check(is_equal_approx(float(killer.bomb().bribe_next),scheduled) and killer.bomb().bribe_offer==old,"Reload preserves rejected offer and scheduled counteroffer")
		killer.advance(.11)
		check(killer.bomb().bribe_offer>old and killer.plea_pending,"Rejection leads to a strictly larger incoming offer")
		check(game.mode=="flight" and killer.bomb().remaining<remaining,"Counteroffer never interrupts flight or resets countdown")
		increases.append(int(killer.bomb().bribe_offer)-old)
		killer.open_active()
	check(delays[0]!=delays[1] and increases[0]!=increases[1],"Counteroffer delays and increases vary across rounds")
	await capture()
	var snapshot: Dictionary=game.pilot.snapshot()
	check(killer.valid(snapshot.world_killer,game.catalog),"Negotiation state passes save validation")
	for bad in [-1,1.5,INF,true,1000000001]:
		var invalid: Dictionary=snapshot.world_killer.duplicate(true);invalid.active.bribe_offer=bad
		check(not killer.valid(invalid,game.catalog),"Invalid bribe amount rejected: "+str(bad))
	var incomplete: Dictionary=snapshot.world_killer.duplicate(true);incomplete.active.erase("bribe_next")
	check(not killer.valid(incomplete,game.catalog),"Incomplete negotiation state rejected")
	var legacy: Dictionary=snapshot.world_killer.duplicate(true)
	for key in ["bribe_offer","bribe_round","bribe_next"]: legacy.active.erase(key)
	check(killer.valid(legacy,game.catalog),"Older active ultimatum remains loadable")
	var migrated: Dictionary=killer.normalized(legacy,game.catalog)
	check(migrated.active.bribe_offer>0 and killer.valid(migrated,game.catalog),"Older appeal receives stable valid bribe")
	check(migrated==killer.normalized(legacy,game.catalog),"Legacy migration cannot reroll offer")
	# Accept even during the final laser: use the same recall path as mercy.
	game.set_mode("flight");killer.advance(killer.bomb().remaining-3)
	killer.open_active();offer=int(killer.bomb().bribe_offer)
	game.world_activity.contact_id=133
	check(not killer.accept_bribe() and game.pilot.credits==money,"Wrong planetary channel cannot collect payment")
	game.world_activity.contact_id=128
	check(killer.accept_bribe(),"Accept bribe while superlaser is firing")
	check(game.pilot.credits==money+offer,"Exact quoted amount credited once")
	check(killer.bomb().is_empty() and not killer.destroyed(128) and not is_instance_valid(killer.warning_shell),"Paid recall disarms beam and spares world")
	check(killer.effects.any(func(effect):return effect is BattleStation and effect.departing),"Paid recall starts physical station withdrawal")
	check(not killer.accept_bribe() and game.pilot.credits==money+offer,"Stale accept action cannot pay twice")
	game.load_game();check(game.pilot.credits==money+offer and killer.bomb().is_empty(),"Payout and cancellation persist together on disk")
	deploy();killer.advance(12);money=game.pilot.credits;killer.spare()
	check(game.pilot.credits==money,"Free mercy remains available without taking money")
	var starting: Array=[]
	for i in 6:
		deploy();killer.advance(12);starting.append(int(killer.bomb().bribe_offer))
	check(starting.any(func(v):return v!=starting[0]),"New deployments vary their initial bribes")
	game.set_mode("flight");killer.advance(killer.bomb().remaining)
	game.set_mode("world_comms");money=game.pilot.credits
	check(not killer.accept_bribe() and game.pilot.credits==money,"Destroyed world cannot pay a stale offer")
	print("WORLD KILLER BRIBES: %d checks; %d failures" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
