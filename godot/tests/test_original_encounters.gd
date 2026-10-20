extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-original-encounters-test.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true
	root.add_child(game)
	game.set_physics_process(false);game.set_process(false)
	game.pilot_ready=true
	game.set_mode("flight")
	check(game.catalog.data.persons.size()==220,"220 original encounter records")
	var matt: Dictionary=game.persons.spawn(219)
	check(not matt.is_empty(),"Matt Burch can appear")
	check(matt.name=="Matt Burch" and matt.id==143,"Original name and Kestrel")
	check(not game.persons.quote(matt).is_empty(),"Original dialogue")
	check(game.persons.spawn(219).is_empty(),"No duplicate captain")
	game.persons.attacked(matt)
	check(219 in game.pilot.persons.grudges,"Captain remembers attack")
	var snapshot: Dictionary=game.pilot.snapshot()
	check(game.pilot.restore(snapshot,game.catalog),"Encounter state survives load")
	check(219 in game.pilot.persons.grudges,"Grudge survives load")
	var count=0
	for id in game.catalog.data.persons:
		if game.persons.eligible(int(id)):
			var npc: Dictionary=game.persons.spawn(int(id))
			check(not npc.is_empty(),"Spawn source record "+str(id))
			game.persons.quote(npc);game.persons.linked_offer(npc,bool(int(npc.person_flags)&512))
			game.traffic.retire(npc);count+=1
	check(count>100,"Broad encounter coverage")
	for offer in game.missions.offers(128,0): check(int(game.catalog.record("missions",int(offer.id)).fields.AvailLoc)==0,"No ship-only contracts in computer")
	game.pilot.campaign.rating=20000
	for govt in game.catalog.data.governments: game.pilot.reputation[govt]=3000
	var accepted=false
	for id in game.catalog.data.persons:
		if accepted or not game.persons.eligible(int(id)): continue
		var npc: Dictionary=game.persons.spawn(int(id))
		if npc.is_empty(): continue
		var offer: Dictionary=game.persons.linked_offer(npc,false)
		if not offer.is_empty():
			game.interactions.contact=npc;game.set_mode("comms")
			check(game.persons.show_offer(npc,false),"Hailed captain offers contract")
			game.persons.accept_offer()
			accepted=game.pilot.campaign.active.any(func(m): return int(m.id)==int(offer.id))
		else: game.traffic.retire(npc)
	check(accepted,"Ship-linked contract accepted through communications")
	var legacy: Dictionary=game.pilot.snapshot();legacy.erase("persons");legacy.erase("secrets")
	check(game.pilot.restore(legacy,game.catalog),"Old pilot saves remain compatible")
	var title=load("res://scripts/title_menu.gd").new();title.game=game;root.add_child(title)
	title.original_credits(true)
	check(title.credits_label.text.contains("MCB 4:35"),"Recovered parody credits")
	title.unlock_forklift()
	check(191 in game.arsenal.available_ids(),"Secret grants forklift without all-weapons cheat")
	check(game.pilot.restore(game.pilot.snapshot(),game.catalog) and game.pilot.secrets.forklift,"Unlock persists")
	title.haikus();title.close_extras();title.queue_free()
	print("RESULT: %d checks, %d failures" % [checks,failures])
	game.queue_free();await process_frame
	quit(1 if failures else 0)
