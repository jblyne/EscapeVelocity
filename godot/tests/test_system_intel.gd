extends SceneTree
const Intel=preload("res://scripts/system_intel.gd")
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS: "+message)
	else: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-intel-pilot.json";game.controls.path="/tmp/ev-intel-controls.json"
	game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	var unknown: int=-1
	for system in game.catalog.data.systems.values():
		if int(system.id)!=game.pilot.system_id and int(system.id) not in game.pilot.visited and int(system.id) not in game.pilot.surveyed: unknown=int(system.id);break
	var data: Dictionary=Intel.report(game,unknown)
	check(not data.known and data.hints.is_empty() and data.outfits.is_empty() and data.ships.is_empty(),"Unknown systems disclose no leads or local stock")
	var astex: int=game.missions.system_of(176);game.pilot.surveyed.append(astex)
	data=Intel.report(game,astex,176)
	check(data.hints.any(func(h):return str(h).contains("dumping")),"Astex investigation lead appears at its actual origin")
	check(not data.hints.any(func(h):return str(h).contains("Astrodyne")),"Future Astrodyne story is not revealed at an unrelated port")
	var outpost_system: int=game.missions.system_of(161);game.pilot.surveyed.append(outpost_system)
	data=Intel.report(game,outpost_system,161)
	check(not data.hints.any(func(h):return str(h).contains("Astrodyne")),"Astrodyne lead remains hidden before Rebel connections")
	game.pilot.campaign.bits.append(44)
	data=Intel.report(game,outpost_system,161)
	check(data.hints.any(func(h):return str(h).contains("Astrodyne") and str(h).contains("6400")),"Progress reveals the correct outpost lead and combat requirement")
	game.pilot.campaign.bits.erase(44)
	var military: Dictionary={}
	for port in game.catalog.data.objects.values():
		if int(port.fields.Flags)&8 and 5001 in [int(port.fields.SpecialTech1),int(port.fields.SpecialTech2),int(port.fields.SpecialTech3)]: military=port;break
	var military_system: int=game.missions.system_of(int(military.id));game.pilot.surveyed.append(military_system)
	var before: Dictionary=game.pilot.snapshot().duplicate(true);var dock_before: int=game.docked_id
	data=Intel.report(game,military_system,int(military.id))
	check(game.docked_id==dock_before and game.pilot.snapshot()==before,"Reading intelligence never changes pilot state, progression, or docked port")
	check(data.ships.any(func(item):return item.id==134 and item.locked),"Confederate Cruiser is listed locally with its mission lock")
	game.pilot.campaign.bits.append(66)
	data=Intel.report(game,military_system,int(military.id))
	check(data.ships.any(func(item):return item.id==134 and not item.locked),"Earned military clearance updates the listing")
	check(not data.outfits.any(func(item):return item.id in [166,167,173,176]),"Mission rewards and debug weapons are never advertised as local stock")
	var valid: bool=true
	for item in data.outfits:
		var fields: Dictionary=game.catalog.record("outfits",int(item.id)).fields
		valid=valid and int(fields.TechLevel) in [int(military.fields.SpecialTech1),int(military.fields.SpecialTech2),int(military.fields.SpecialTech3)]
	check(valid,"Special outfit listings match original port technology")
	game.world_killer.state().destroyed.append(int(military.id))
	data=Intel.report(game,military_system,int(military.id))
	check(data.ships.is_empty() and data.outfits.is_empty() and data.hints.is_empty(),"Destroyed ports cannot advertise stock or contacts")
	game.world_killer.state().destroyed.erase(int(military.id))
	game.set_mode("map")
	var screen=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	screen.find_child("SystemIntel",true,false).pressed.emit()
	check(screen.intel_body.visible and screen.intel_button.text=="System Details","Map intelligence toggles without replacing navigation")
	screen.find_child("IntelStock",true,false).pressed.emit()
	check(screen.intel_body.text.contains("SPECIAL OUTFITS") and not screen.intel_body.text.contains("LOCAL LEADS"),"Map stock tab exposes equipment and ships directly")
	game.docked_id=176;game.pilot.system_id=astex;game.set_mode("dock")
	var port_ui=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	port_ui.find_child("LocalLeads",true,false).pressed.emit()
	port_ui=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	check(port_ui.find_child("LocalIntelText",true,false)!=null,"Landing leads button opens classic local intelligence screen")
	port_ui.find_child("IntelBack",true,false).pressed.emit()
	check(game.mode=="dock" and game.hud.port_page=="landing","Back returns to landing screen without launching")
	game.free();await process_frame
	print("SYSTEM INTEL: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
