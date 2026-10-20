extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func buy(id: int) -> bool:
	for port in game.catalog.data.objects:
		game.docked_id=int(port)
		if game.outfitter.available_here(id): return game.outfitter.trade(id,true)
	return false
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-utility-outfits-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game);game.set_physics_process(false);game.set_process(false)
	game.pilot.credits=10000000;game.docked_id=128;game.set_mode("outfitter")
	for id in [155,156,158,169]: check(buy(id),"Purchase utility outfit %d at valid source port" % id)
	var map=load("res://scripts/map_view.gd").new();map.game=game
	var before: Array=map.known_systems()
	var visited: Array=game.pilot.visited.duplicate()
	var expected: Array=[128]
	for id in game.catalog.system(128).links:
		if id not in expected: expected.append(id)
		for second in game.catalog.system(id).links:
			if second not in expected: expected.append(second)
	check(buy(165),"Buy two-jump regional map")
	check(game.pilot.visited==visited,"Map does not fake exploration")
	check(game.outfitter.count(165)==0,"Map is consumed, not resellable equipment")
	check(map.known_systems().size()>before.size(),"Map reveals additional systems")
	for id in expected: check(id in map.known_systems(),"Regional map reveals system %d" % id)
	check(not buy(165),"Already-mapped region cannot charge again")
	game.pilot.reputation["128"]=-500;game.pilot.reputation["129"]=-200
	check(buy(180),"Buy fake IDs at original special-tech port")
	check(game.pilot.reputation["128"]==0 and game.pilot.reputation["129"]==-200,"Fake IDs clear only Confederation record")
	check(game.outfitter.count(180)==0 and not buy(180),"Fake IDs consumed and unnecessary purchase blocked")
	game.Factions.penalize(game.catalog,game.pilot,128,"ShootPenalty")
	check(game.pilot.reputation["128"]<0,"Subsequent crimes still affect legal standing")
	game.pilot.fuel=game.pilot.fuel_capacity()-200;game.pilot.armor=20
	var credits: int=game.pilot.credits
	check(game.outfitter.auto_refuel()==200,"Automatic fuel uses normal fuel price")
	check(game.pilot.credits==credits-200 and game.pilot.fuel==game.pilot.fuel_capacity() and game.pilot.armor==20,"Fuel-only service preserves armor")
	check(game.outfitter.auto_refuel()==0,"Full tank cannot be charged again")
	game.pilot.fuel-=200;game.pilot.credits=99
	check(game.outfitter.auto_refuel()==99 and game.pilot.credits==0 and game.pilot.fuel==game.pilot.fuel_capacity()-101,"Low funds purchase an affordable partial refill")
	game.pilot.cheat_infinite_fuel=true
	check(game.outfitter.auto_refuel()==0,"Infinite-fuel cheat never charges")
	game.pilot.cheat_infinite_fuel=false
	game.arsenal.fire(132,game.pilot.position+Vector2(500,0),0,true)
	var missile: Dictionary=game.shots.back()
	var start: Vector2=missile.velocity
	game.arsenal.steer(missile,.1)
	var jammed: Vector2=missile.velocity
	missile.velocity=start;game.pilot.outfits.erase("158")
	game.arsenal.steer(missile,.1)
	check(absf(start.angle_to(jammed))<absf(start.angle_to(missile.velocity)),"Actual missile turns less toward player while jammed")
	game.pilot.outfits["158"]=1
	check(game.arsenal.guidance_rate({"enemy":true,"weapon":132})<2.4,"Jammer weakens incoming missile steering")
	check(game.arsenal.guidance_rate({"enemy":true,"weapon":131})==2.4,"Torpedoes unaffected")
	check(game.arsenal.guidance_rate({"enemy":false,"weapon":132})==2.4,"Player missiles unaffected")
	check(game.outfitter.radar_size({"id":134})>game.outfitter.radar_size({"id":128}),"Density scanner distinguishes heavy hulls")
	check(game.outfitter.radar_color(true)!=game.outfitter.radar_color(false),"IFF differentiates hostile contacts")
	check(game.pilot.restore(game.pilot.snapshot(),game.catalog),"All new equipment and mapped systems survive save")
	check(game.pilot.surveyed.size()>0 and game.pilot.outfit_count(158)==1,"Loaded map and jammer remain installed")
	game.pilot.outfits.erase("155");game.pilot.outfits.erase("156");game.pilot.outfits.erase("158")
	check(game.outfitter.radar_size({"id":134})==game.outfitter.radar_size({"id":128}),"Removing density scanner restores uniform blips")
	check(game.outfitter.radar_color(true)==game.outfitter.radar_color(false),"Removing IFF restores monochrome radar")
	check(game.arsenal.guidance_rate({"enemy":true,"weapon":132})==2.4,"Removing jammer restores normal guidance")
	var invalid: Dictionary=game.pilot.snapshot();invalid.surveyed=[99999]
	check(not game.pilot.restore(invalid,game.catalog),"Invalid mapped-system save rejected")
	var legacy: Dictionary=game.pilot.snapshot();legacy.erase("surveyed")
	check(game.pilot.restore(legacy,game.catalog),"Older saves load without map extension")
	game.pilot.cheat_chain_jump=true
	check(map.known_systems().size()==game.catalog.data.systems.size(),"Chain-jump cheat retains full galaxy map")
	if "--visual" in OS.get_cmdline_user_args():
		game.pilot.cheat_chain_jump=false;game.pilot.surveyed=expected.duplicate()
		game.set_mode("map")
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/utility-regional-map.png"))
		game.pilot.outfits["155"]=1;game.pilot.outfits["156"]=1
		game.traffic.spawn(134,128,3,game.pilot.position+Vector2(400,-200))
		game.traffic.spawn(128,130,1,game.pilot.position+Vector2(-200,-250))
		game.set_mode("flight");game.hud._process(0)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/utility-radar.png"))
	map.free();game.queue_free();await process_frame
	print("UTILITY OUTFITS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
