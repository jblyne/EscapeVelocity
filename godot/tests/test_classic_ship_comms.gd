extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev-classic-hail-pilot.json";game.controls.path="/tmp/ev-classic-hail-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.set_mode("flight");game.spawn_npc(false,game.pilot.position+Vector2(140,0));game.target_index=game.npcs.size()-1;game.interactions.open_hail()
	var ui=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	check(ui.layout==Vector2(820,374),"Hail dialog uses compact classic dimensions")
	var response=ui.find_child("CommResponse",true,false);var portrait=ui.find_child("CommPortrait",true,false)
	check(response is RichTextLabel and response.position.x<portrait.position.x,"Response at left and portrait at right")
	for name in ["Greetings","RequestAssistance","OfferBribe","AttemptBoard","EndCommunication"]:
		check(ui.find_child(name,true,false) is Button and Rect2(Vector2.ZERO,ui.layout).encloses(ui.find_child(name,true,false).get_rect()),"Classic action retained inside dialog: "+name)
	game.interactions.response="A long transmission. ".repeat(150);game.hud.rebuild_modal()
	ui=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	check(ui.find_child("CommResponse",true,false).scroll_active,"Long transmissions remain scrollable")
	if "--visual" in OS.get_cmdline_user_args():
		game.interactions.response="Channel open.";game.hud.rebuild_modal()
		await create_timer(.3).timeout;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../builds/classic-ship-comms-0.1.69.png"))
	ui=game.hud.modal_root.get_child(game.hud.modal_root.get_child_count()-1)
	ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT);ui.size=Vector2(1000,650);ui.fit()
	check(ui.canvas.position.x>=20 and ui.canvas.position.y>=20 and ui.canvas.size.x*ui.canvas.scale.x<=960,"Classic channel fits smaller windows with margins")
	game.interactions.close();check(game.mode=="flight","Close channel returns to flight")
	game.free();await process_frame
	print("CLASSIC SHIP COMMS: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
