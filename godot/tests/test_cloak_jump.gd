extends SceneTree
var game
var count=0
var failures=0
func _initialize(): call_deferred("run")
func check(ok: bool, message: String):
	count+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func reset():
	game.load_system();game.set_mode("flight")
	game.pilot.cheat_cloak=true;game.pilot.cheat_infinite_fuel=true
	game.pilot.shield=game.pilot.max_shield()
	game.pilot.position=Vector2(12000,12000);game.velocity=Vector2.ZERO
func run():
	game=load("res://main.tscn").instantiate()
	game.save_path=ProjectSettings.globalize_path("res://../builds/test-cloak-jump-pilot.json")
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false)
	reset()
	game.cloak.toggle()
	var first=game.cloak.materials[0].copy
	game.cloak.update_visual(.125)
	var early=first.albedo_color.a
	check(early>.97 and early<1,"fade eases in without an abrupt initial opacity step")
	game.cloak.update_visual(1.0)
	check(first.albedo_color.a>.12 and first.albedo_color.a<.15,"fade eases gently into cloaked silhouette")
	game.cloak.update_visual(.125)
	check(is_equal_approx(game.cloak.visibility_factor(),0),"fully cloaked exhaust remains hidden")
	game.cloak.toggle();game.cloak.update_visual(.125)
	check(game.cloak.visibility_factor()<.04,"decloaking exhaust returns gradually")
	var before=first.albedo_color.a
	game.cloak.toggle()
	check(is_equal_approx(before,first.albedo_color.a),"reversing a fade does not jump opacity")
	game.cloak.update_visual(1.25)
	game.cloak.toggle();game.cloak.update_visual(1.25);game.cloak.toggle()
	check(first==game.cloak.materials[0].copy,"repeated toggles reuse retained material variants")
	game.cloak.update_visual(1.25)
	var start=game.pilot.system_id
	game.start_jump()
	for i in 1800:
		game._physics_process(1.0/60)
		game.cloak.update_visual(1.0/60)
		if game.pilot.system_id!=start: break
	check(game.pilot.system_id!=start,"normal hyperspace jump reaches destination")
	check(game.cloak.active and is_equal_approx(game.cloak.amount,1),"normal hyperspace preserves fully engaged cloak")
	check(game.cloak.visual_model==game.player_model and not game.cloak.materials.is_empty(),"arrival model has cloak materials immediately")
	check(game.cloak.materials[0].copy.albedo_color.a<.2,"arrival has no opaque first-frame flash")
	check(game.fire_player() and game.cloak.active,"weapons fire without decloaking after arrival")
	var npc=game.traffic.spawn(134,128,4,game.pilot.position+Vector2(100,0));npc.hostile=true
	check(not game.traffic.opponent(npc).get("player",false),"destination enemies cannot acquire cloaked arrival")
	game.cloak.toggle();game.cloak.update_visual(.25)
	var partial=game.cloak.amount
	game.load_system(0.0)
	check(not game.cloak.active and is_equal_approx(game.cloak.amount,partial),"arrival preserves a partial decloak without restarting it")
	check(game.cloak.visual_model==game.player_model,"partial arrival transition binds to new model")
	reset();game.cloak.toggle();game.cloak.update_visual(1.25)
	game.pilot.cheat_chain_jump=true
	var route: Array=[]
	for id in game.catalog.data.systems:
		var candidate=game.route_to(int(id))
		if candidate.size()>=3: route=candidate.slice(0,3);break
	game.chain_route=route.duplicate()
	var preserved=true
	for id in route:
		game.chain_hop()
		preserved=preserved and game.cloak.active and game.cloak.visual_model==game.player_model and game.cloak.amount==1
	check(route.size()==3 and preserved,"all three chain-hop arrivals preserve cloak and its appearance")
	game.pilot.shield=.1;game.cloak.advance(1)
	check(not game.cloak.active,"power depletion still ends cloaking normally")
	game.pilot.shield=100;game.cloak.toggle();game.cloak.update_visual(1.25)
	game.load_system()
	check(not game.cloak.active and game.cloak.amount==0,"explicit save/system reload still resets transient cloak state")
	game.free();await process_frame
	print("CLOAK JUMP RESULT: %d checks; %d failures" % [count,failures])
	quit(1 if failures else 0)
