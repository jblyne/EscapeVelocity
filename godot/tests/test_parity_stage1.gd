extends SceneTree
var game
var checks: int=0
var failures: int=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func capture_screen(name: String) -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/parity-stage1-"+name+".png"))
	var screen: Rect2=Rect2(Vector2.ZERO,root.get_visible_rect().size)
	check(game.hud.modal_root.find_children("*","Button",true,false).all(func(b):return screen.encloses(b.get_global_rect())),"Modal buttons fit: "+name)

func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-parity-stage1.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.restart();game.pilot.fleet=[{"id":131},{"id":131}];game.load_system()
	var fleet=game.fleet_service
	game.pilot.cargo=[game.pilot.cargo_capacity(),0,0,0,0,0]
	game.docked_id=128;game.set_mode("dock")
	check(fleet.cargo_capacity()>game.pilot.cargo_capacity(),"Escort holds expand commodity capacity")
	var credits: int=game.pilot.credits
	game.trade(1,true)
	check(game.pilot.fleet[0].cargo[1]==1 and game.pilot.cargo[1]==0,"Actual port purchase fills escort after flagship")
	check(game.pilot.credits<credits,"Escort commodity purchase charges credits")
	await capture_screen("trade")
	check(not game.pilot.accept_job(129,129,game.pilot.cargo_capacity()),"Fleet space cannot accept flagship mission cargo")
	check(game.save_game(false),"Loaded escort manifest saves to disk")
	game.load_game()
	check(fleet.commodity_count(1)==1 and game.pilot.fleet[0].cargo[1]==1,"Restored manifest remains on its carrier")
	game.docked_id=128;game.set_mode("dock");game.trade(1,false)
	check(fleet.commodity_count(1)==0,"Port sells commodity directly from escort")
	var room: int=fleet.cargo_capacity()-fleet.total_cargo_used()
	check(fleet.load_commodity(2,room+10)==room,"Bulk salvage stops at combined hold capacity")
	check(fleet.load_commodity(2,1)==0,"Full fleet cannot gain extra goods")
	credits=game.pilot.credits
	check(not fleet.trade(0,true,10) and game.pilot.credits==credits,"Failed purchase never charges credits")
	var saved: Dictionary=game.pilot.snapshot();var copy=game.Pilot.new()
	check(copy.restore(saved,game.catalog),"Full carrier manifests validate")
	var invalid: Dictionary=saved.duplicate(true);invalid.fleet[0].cargo=[-1,0,0,0,0,0]
	check(not copy.restore(invalid,game.catalog),"Negative escort freight rejected")
	invalid=saved.duplicate(true);invalid.fleet[0].cargo=[1000000,0,0,0,0,0]
	check(not copy.restore(invalid,game.catalog),"Overloaded escort freight rejected")
	invalid=saved.duplicate(true);invalid.fleet[0].cargo=[1.5,0,0,0,0,0]
	check(not copy.restore(invalid,game.catalog),"Fractional escort freight rejected")
	var before: int=fleet.commodity_count(2);var lost: int=fleet.cargo_used(game.pilot.fleet[0])
	var escort: Dictionary=game.escorts[0];game.damage_npc(escort,escort.health+1)
	check(fleet.commodity_count(2)==before-lost,"Destroyed carrier loses only its own freight")
	game.toggle_fleet_menu();escort=game.escorts[0];lost=fleet.cargo_used(game.pilot.fleet[0])
	before=fleet.commodity_count(2)
	await capture_screen("fleet")
	check(fleet.release(escort) and fleet.commodity_count(2)==before-lost,"Released carrier takes its manifest")
	check(escort.cargo[2]==lost,"Released independent contact retains its actual freight")
	game.restart();game.pilot.fleet=[{"id":131,"cargo":[0,4,0,0,0,0]}];game.load_system()
	game.pilot.cargo=[10,0,0,0,0,0];game.toggle_fleet_menu();escort=game.escorts[0]
	check(fleet.takeover(escort),"Flagship transfer accepts combined manifests when they fit")
	check(game.pilot.cargo[0]==10 and game.pilot.cargo[1]==4 and game.pilot.fleet.is_empty(),"Taking command preserves the captured carrier's freight")
	check(game.save_game(false) and copy.restore(game.pilot.snapshot(),game.catalog),"Transferred carrier freight forms a valid pilot save")
	game.restart();game.pilot.fleet=[{"id":131,"hired":true,"wage":100,"paid_day":int(game.pilot.campaign.day),"cargo":[0,3,0,0,0,0]}];game.load_system()
	escort=game.escorts[0];game.pilot.credits=0;game.pilot.campaign.day+=1;fleet.payroll()
	check(game.pilot.fleet.is_empty() and escort.cargo[1]==3,"Unpaid captain departs with its own cargo")
	game.restart();game.pilot.credits=1000000;game.docked_id=128;game.set_mode("outfitter")
	check(game.outfitter.trade(133,true),"Install real missile launcher for salvage")
	var npc: Dictionary=game.traffic.spawn(146,130,3,game.pilot.position)
	npc.disabled=true;npc.velocity=Vector2.ZERO;npc.heading=game.pilot.heading;game.velocity=Vector2.ZERO
	npc.weapons=[{"id":132,"ammo":100,"count":1,"cooldown":0}]
	game.target_index=game.npcs.find(npc);game.set_mode("flight")
	check(game.interactions.board(),"Board disabled armed vessel")
	check(game.hud.modal_root.find_child("LootAmmo",true,false) is Button,"Boarding exposes ammunition action")
	await capture_screen("boarding")
	var plan: Array=game.interactions.ammunition_plan(npc)
	check(not plan.is_empty() and plan[0].amount<100,"Salvage plan respects equipment space and installation limit")
	# Pick a safe roll to isolate transfer semantics from the separately tested destruction risk.
	for seed_value in 100:
		game.interactions.rng.seed=seed_value
		if game.interactions.rng.randf()>.9:
			game.interactions.rng.seed=seed_value;break
	check(game.interactions.plunder("ammo"),"Compatible ammunition transfers through boarding action")
	var rounds: int=game.pilot.outfit_count(134)
	check(rounds>0 and int(npc.weapons[0].ammo)+rounds==100,"Rounds are conserved between donor and pilot")
	check(not game.interactions.plunder("ammo") and game.pilot.outfit_count(134)==rounds,"Repeated salvage cannot exceed equipment capacity")
	check(game.save_game(false),"Salvaged loadout saves")
	check(copy.restore(game.pilot.snapshot(),game.catalog) and copy.outfit_count(134)==rounds,"Salvaged ammunition passes loadout validation")
	game.set_mode("flight");game.select_weapon(132);game.cooldown=0
	check(game.fire_player() and game.pilot.outfit_count(134)==rounds-1,"Salvaged rounds fire through ordinary weapon system")
	game.pilot.outfits.erase("133")
	check(game.interactions.ammunition_plan(npc).is_empty(),"No launcher means no ammunition plunder")
	game.pilot.outfits["133"]=1;npc.weapons[0].ammo=-1
	check(game.interactions.ammunition_plan(npc).is_empty(),"Unlimited NPC weapons cannot yield infinite ammunition")
	game.restart();game.set_mode("flight");game.world_activity.open_contact()
	check(game.mode=="world_comms","Existing world hailing remains available")
	game.free();await process_frame
	print("PARITY STAGE 1: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
