extends SceneTree
var failures=0
var checked=0
func _initialize() -> void: call_deferred("run")
func audit(node: Node) -> void:
	if node is Button:
		var style=node.get_theme_stylebox("normal")
		if style is StyleBoxFlat and style.bg_color.is_equal_approx(Color("777777")):
			checked+=1
			if node.get_theme_font("font").resource_path!="res://assets/fonts/EVOriginal.ttf":
				failures+=1;push_error("Gray button has wrong font: "+str(node.get_path()))
	for child in node.get_children(): audit(child)
func run() -> void:
	var game=load("res://main.tscn").instantiate();game.save_path="/tmp/ev208-font-pilot.json";game.controls.path="/tmp/ev208-controls.json"
	game.muted=true;game.traffic.enabled=false;root.add_child(game);game.set_process(false);game.set_physics_process(false)
	game.docked_id=128;game.missions.return_mode="flight";game.missions.channel=0
	for mode in ["pause","info","map","fleet","missions","outfitter","shipyard","achievements","cheats","dock"]:
		game.set_mode(mode);await process_frame;audit(game.hud.modal_root)
	game.controls_return_mode="flight";game.set_mode("controls");await process_frame;audit(game.hud.modal_root)
	game.autopilot.return_mode="flight";game.set_mode("autopilot");await process_frame;audit(game.hud.modal_root)
	for type in ["Button","OptionButton","CheckBox","CheckButton"]:
		if game.hud.root.theme.get_font("font",type).resource_path!="res://assets/fonts/EVOriginal.ttf": failures+=1
	game.free();await process_frame
	print("MENU BUTTON FONTS: %d buttons checked; %d failures" % [checked,failures]);quit(1 if failures else 0)
