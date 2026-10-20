extends SceneTree
var game
func _initialize(): call_deferred("run")
func capture(name: String):
	game.hud._process(0)
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/person-"+name+".png"))
func run():
	game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-person-visual.json"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_physics_process(false);game.set_process(false)
	game.set_mode("flight")
	var matt: Dictionary=game.persons.spawn(219);game.target_index=game.npcs.find(matt);game.interactions.open_hail()
	await capture("matt-hail")
	game.interactions.close();game.traffic.retire(matt)
	game.pilot.ship_id=132;game.pilot.ship_fields=game.catalog.record("ships",132).fields.duplicate()
	var courier: Dictionary=game.persons.spawn(278)
	for visit in 50:
		game.pilot.campaign.visit=visit
		if not game.persons.linked_offer(courier,false).is_empty(): break
	game.target_index=game.npcs.find(courier);game.interactions.open_hail();await capture("courier-offer")
	game.interactions.close();game.set_mode("cheats");await capture("cheats")
	game.queue_free();await process_frame;quit()
