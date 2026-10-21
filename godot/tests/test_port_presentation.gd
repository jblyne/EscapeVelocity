extends SceneTree
const Art=preload("res://scripts/landing_art.gd")
var game
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func screen(): return game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
func click(id: String) -> void:
	var b=game.hud.modal_root.find_child(id,true,false)
	check(b is Button and not b.disabled,"Usable service: "+id)
	if b is Button and not b.disabled: b.pressed.emit()
func dock(id: int) -> void:
	game.pilot.system_id=game.missions.system_of(id);game.load_system();game.docked_id=id
	game.hud.port_page="landing";game.set_mode("dock")
func capture(name: String) -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	await create_timer(.25).timeout
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/port-"+name+".png"))
func check_service_size() -> void:
	var port=screen()
	var layout=Vector2(1000,530)
	var ratio=minf(1.0,minf((port.size.x-40)/layout.x,(port.size.y-40)/layout.y))
	check((port.canvas.size*port.canvas.scale).is_equal_approx(layout*ratio),"Service matches outfitter dimensions and fit limit")
	check(port.canvas.position.is_equal_approx((port.size-layout*ratio)*.5),"Compact service stays centered")
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-port-presentation-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	if "--station-only" in OS.get_cmdline_user_args():
		dock(129);await create_timer(1).timeout;await capture("station-steady")
		game.queue_free();await process_frame;quit();return
	var dune: int=-1
	for obj in game.catalog.data.objects.values():
		if obj.name=="Dune": dune=int(obj.id)
	dock(dune)
	var port=screen()
	check(port.scenery.texture!=null and port.scenery.size==Vector2(666,542),"Dune uses generated scenery in original 333:271 panel proportions")
	check(Art.picture_id(game.catalog,dune)==10010,"Dune retains its original desert scenery type")
	var body=port.find_child("PortDescription",true,false)
	check(body.text.ends_with(str(game.catalog.data.descriptions[str(dune)])),"Landing shows original world description")
	check(body.position.x>port.scenery.position.x+port.scenery.size.x,"Description sits to right of scenery")
	check(body.size.x==488 and body.get_minimum_size().y<=276,"World text wraps inside the original description column")
	for id in ["RefuelShip","OpenExchange","OpenOutfitter","OpenSpaceportBar","OpenMissions","LeavePort"]:
		check(port.find_child(id,true,false) is Button,"Original landing service present: "+id)
	await capture("dune")
	check(port.find_child("RefuelShip",true,false).disabled,"Full tank disables Refuel Ship")
	var money: int=game.pilot.credits;game.pilot.fuel-=100;game.pilot.armor-=10
	game.hud.rebuild_modal()
	var cost: int=game.refuel_cost();var armor: float=game.pilot.armor;click("RefuelShip")
	check(game.pilot.credits==money-cost and game.pilot.fuel==game.pilot.fuel_capacity() and game.pilot.armor==armor,"Classic Refuel Ship charges for fuel without altering armor")
	check(game.hud.modal_root.find_child("RefuelShip",true,false).disabled,"Refueling immediately disables the full-tank button")
	click("OpenExchange");check(game.mode=="dock" and game.hud.port_page=="exchange","Commodity Exchange opens separate paused port screen")
	var price: int=game.world_activity.prices(dune)[0];money=game.pilot.credits
	click("BuyCommodity")
	check(game.fleet_service.commodity_count(0)==10 and game.pilot.credits==money-price*10,"Buy trades ten tonnes at displayed price")
	click("BuyCommodity")
	check(game.hud.modal_root.find_child("BuyCommodity",true,false).disabled,"Full hold disables further purchases")
	check(game.pilot.cargo_used()==game.pilot.cargo_capacity(),"Repeated bulk purchases stop at hold capacity")
	click("SellCommodity");check(game.fleet_service.commodity_count(0)==10,"Sell removes up to ten tonnes")
	click("Commodity1");check(game.hud.market_good==1,"Exchange commodity selection survives rebuilding")
	check_service_size()
	await capture("exchange")
	click("LeaveExchange");click("OpenSpaceportBar")
	check(game.hud.port_page=="bar","Spaceport Bar has its own screen")
	check_service_size()
	await capture("bar")
	click("OpenNews");check(game.mode=="news","Bar retains news and tribute access")
	game.set_mode("dock");click("HireEscorts");check(game.mode=="fleet","Bar retains fleet hiring and management")
	game.toggle_fleet_menu();click("BarOffers")
	check(game.mode=="missions" and game.missions.channel==1 and game.missions.return_mode=="dock","Bar Offers opens original bar mission channel")
	game.set_mode("dock");game.hud.port_page="landing";game.hud.rebuild_modal();click("OpenMissions")
	check(game.mode=="missions" and game.missions.channel==0,"Mission Computer opens separate mission channel")
	var mission_screen=screen();mission_screen.mission_list.select(mission_screen.entries.size()-1);mission_screen.select_entry(mission_screen.entries.size()-1)
	click("AcceptCourier");check(not game.pilot.mission.is_empty(),"Introductory courier remains available through Mission Computer")
	dock(128);click("OpenOutfitter")
	check(game.mode=="outfitter","Outfit Ship opens equipment shop")
	game.set_mode("dock");game.hud.port_page="exchange";game.hud.rebuild_modal()
	var esc=InputEventKey.new();esc.physical_keycode=KEY_ESCAPE;esc.pressed=true;game._unhandled_key_input(esc)
	check(game.mode=="dock" and game.hud.port_page=="landing","Escape leaves a port service before launching")
	game.hud.port_page="bar";game.hud.rebuild_modal();game.launch()
	check(game.mode=="flight" and game.hud.port_page=="landing","Launching resets service page for next landing")
	if "--assets" in OS.get_cmdline_user_args():
		for obj in game.catalog.data.objects.values():
			if not int(obj.fields.Flags)&1: continue
			check(Art.texture(game.catalog,int(obj.id))!=null,"Generated landing scenery exists for "+obj.name)
			check(not str(game.catalog.data.descriptions.get(str(int(obj.id)),"")).is_empty(),"Original landing text exists for "+obj.name)
		check(Art.picture_id(game.catalog,129)==11000,"Stardock Alpha uses custom orbital scenery")
		check(Art.picture_id(game.catalog,132)==10022,"Luna respects original custom landscape override")
		check(Art.picture_id(game.catalog,192)==11001,"Darkstar uses custom volcanic-planet vista")
		dock(133);await capture("levo")
		dock(129);await capture("stardock")
		click("OpenShipyard");check(game.mode=="shipyard","Visit Shipyard retains ship purchasing")
		dock(163);await process_frame
		var description=screen().find_child("PortDescription",true,false)
		check(description.size==Vector2(488,226) and description.scroll_active,"Longest original world description stays scrollable in its panel")
	if "--visual" in OS.get_cmdline_user_args():
		dock(dune);DisplayServer.window_set_size(Vector2i(1000,650));await process_frame;await capture("small")
	print("PORT PRESENTATION: %d checks; %d failures" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
