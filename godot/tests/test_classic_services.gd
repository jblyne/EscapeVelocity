extends SceneTree
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
	check(b is Button and not b.disabled,"Usable classic action: "+id)
	if b is Button and not b.disabled: b.pressed.emit()
func choose(index: int) -> void:
	var list=screen().mission_list;list.select(index);list.item_selected.emit(index)
func capture(name: String) -> void:
	if "--visual" not in OS.get_cmdline_user_args(): return
	await create_timer(.3).timeout
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/classic-"+name+".png"))
func run() -> void:
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-classic-services-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.pilot.credits=1000000;game.docked_id=128;game.set_mode("dock");game.missions.channel=0;game.missions.open()
	check(screen().mission_list is ItemList and screen().mission_list.size==Vector2(384,292),"Mission computer uses original left list proportions")
	check(game.hud.modal_root.find_child("MissionChannel0",true,false)==null,"Classic mission dialog has no oversized tabs or header")
	check(screen().entries.size()>1,"Computer lists available offers and courier together")
	check(screen().canvas.scale.x<=1.0,"Classic mission dialog stays compact at large window sizes")
	var index: int=-1
	for i in screen().entries.size():
		var entry: Dictionary=screen().entries[i]
		if not entry.get("courier",false) and int(entry.qty)<=game.pilot.cargo_capacity(): index=i;break
	check(index>=0,"Eligible source mission available for acceptance")
	choose(index)
	var entry: Dictionary=screen().entries[index];var id: int=int(entry.id)
	var brief=game.hud.modal_root.find_child("MissionBriefing",true,false)
	check(brief.text.begins_with(game.missions.text_for(entry,"offer")),"Selecting row immediately shows original offer in right pane")
	check(brief.position.x>screen().mission_list.position.x+screen().mission_list.size.x,"Briefing sits beside list")
	await capture("missions")
	screen().open_map()
	check(game.mode=="map" and game.map_preview_system==game.missions.target_system(entry),"Selected offer still opens green-arrow map preview")
	game.set_mode(game.map_return_mode)
	check(game.mode=="missions" and int(game.missions.selected.id)==id,"Returning from map preserves selected briefing")
	click("AcceptMission%d" % id)
	check(game.pilot.campaign.active.any(func(m):return int(m.id)==id),"Classic Accept Mission uses validated campaign flow")
	check(game.hud.modal_root.find_child("MissionBriefing",true,false).text==game.missions.last_report,"Acceptance report remains readable in right pane")
	game.set_mode("flight")
	var info=InputEventKey.new();info.physical_keycode=KEY_I;info.pressed=true;game._unhandled_key_input(info)
	check(game.mode=="missions" and screen().journal and screen().layout==Vector2(904,316),"I opens original compact active-mission journal")
	choose(0);await capture("journal")
	click("AbortMission%d" % id);check(game.pilot.campaign.active.is_empty(),"Abort Mission removes selected active contract")
	click("CloseMissions");check(game.mode=="flight","Journal Done returns to flight")
	game.set_mode("dock");game.missions.last_report="";game.missions.channel=0;game.missions.open()
	choose(screen().entries.size()-1)
	check(game.missions.selected_courier,"Local courier is a normal selectable list row")
	click("AcceptCourier");check(not game.pilot.mission.is_empty(),"Courier acceptance remains available")
	game.set_mode("flight");game._unhandled_key_input(info)
	choose(screen().entries.size()-1)
	check(game.hud.modal_root.find_child("MissionBriefing",true,false).text.contains("1,200"),"Journal includes accepted courier briefing")
	click("AbortCourier");check(game.pilot.mission.is_empty(),"Courier can be removed through journal")
	game.set_mode("dock");game.missions.channel=1;game.missions.open()
	check(not screen().journal and game.missions.channel==1,"Spaceport bar retains its separate mission offers")
	game.set_mode("outfitter")
	check(screen().grid.columns==4 and screen().cards.size()==game.outfitter.stock().size(),"Outfitter shows compact four-column equipment grid")
	check(game.hud.modal_root.find_child("OutfitFilterALL",true,false)==null,"Outfitter uses original grid layout without large filter tabs")
	var presentation_ok: bool=true
	for outfit_id in screen().cards:
		var card=screen().cards[outfit_id]
		var available: bool=game.outfitter.available_here(int(outfit_id))
		var icon=card.find_child("OutfitPicture%d" % outfit_id,true,false)
		var caption=card.find_child("OutfitName%d" % outfit_id,true,false)
		presentation_ok=presentation_ok and (icon.material==null if available else icon.material is ShaderMaterial) and caption.get_theme_color("default_color")== (Color("dddddd") if available else Color("777777")) and not card.disabled
	check(presentation_ok,"Unavailable equipment is gray while remaining selectable; stocked equipment keeps its normal colors")
	click("SelectOutfit130")
	var description=game.hud.modal_root.find_child("OutfitDescription",true,false)
	check(description.text==game.catalog.data.descriptions["3002"],"Outfitter displays original equipment description")
	var grid_node=screen().grid
	click("SelectOutfit128");check(screen().grid==grid_node,"Changing selection keeps grid and scroll position intact")
	click("SelectOutfit130");await capture("outfitter")
	var money: int=game.pilot.credits;click("BuyOutfit130")
	check(game.outfitter.count(130)==1 and game.pilot.credits==money-7730,"Classic Buy installs selected outfit at original price")
	click("SellOutfit130");check(game.outfitter.count(130)==0,"Classic Sell removes selected equipment")
	game.pilot.credits=0;game.hud.rebuild_modal();check(game.hud.modal_root.find_child("BuyOutfit130",true,false).disabled,"Insufficient funds disable Buy")
	click("CloseOutfitter");check(game.mode=="dock","Outfitter Leave returns to port")
	if "--visual" in OS.get_cmdline_user_args():
		DisplayServer.window_set_size(Vector2i(1000,650));game.pilot.credits=1000000;game.set_mode("outfitter");await capture("outfitter-small")
		game.set_mode("dock");game.missions.last_report="";game.missions.channel=0;game.missions.open();await capture("missions-small")
	print("CLASSIC SERVICES: %d checks; %d failures" % [checks,failures]);game.queue_free();await process_frame;quit(1 if failures else 0)
