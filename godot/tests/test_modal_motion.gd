extends SceneTree
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	game.save_path="/tmp/ev-modal-motion.json";game.controls.path="/tmp/ev-modal-motion-controls.json"
	game.traffic.enabled=false;game.muted=true;root.add_child(game)
	game.set_process(false);game.set_physics_process(false);game.hud.set_process(false)
	game.docked_id=128
	game.set_mode("outfitter")
	check(game.hud.modal_root.modulate.a==0 and game.hud.modal_root.scale.x<1,"window starts with subtle fade and scale")
	await create_timer(.25).timeout
	check(is_equal_approx(game.hud.modal_root.modulate.a,1) and game.hud.modal_root.scale.is_equal_approx(Vector2.ONE),"window settles at exact original size and opacity")
	game.hud.rebuild_modal()
	check(game.hud.modal_root.modulate.a==1 and game.hud.modal_root.scale==Vector2.ONE,"same-window refresh does not replay animation")
	game.set_mode("flight")
	check(game.hud.modal_root.get_child_count()==0 and is_instance_valid(game.hud.modal_outgoing),"closing window remains briefly visible outside active modal tree")
	var outgoing: Control=game.hud.modal_outgoing
	var button=outgoing.find_child("SelectOutfit128",true,false)
	check(button!=null and button.mouse_filter==Control.MOUSE_FILTER_IGNORE and button.focus_mode==Control.FOCUS_NONE,"closing controls cannot capture clicks or keyboard focus")
	await create_timer(.2).timeout
	check(not is_instance_valid(outgoing),"closing visual cleans up after fade")
	game.set_mode("dock");game.set_mode("outfitter");game.set_mode("shipyard")
	await create_timer(.3).timeout
	check(game.mode=="shipyard" and game.hud.modal_root.scale==Vector2.ONE and game.hud.modal_root.modulate.a==1,"rapid window switches settle cleanly")
	check(game.hud.root.find_children("ClosingWindow","",false,false).is_empty(),"rapid switches leave no outgoing windows")
	game.set_mode("flight")
	await create_timer(.2).timeout
	game.free();await process_frame
	print("MODAL MOTION: %d checks; %d failures" % [checks,failures]);quit(1 if failures else 0)
