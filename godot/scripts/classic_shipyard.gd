extends "res://scripts/classic_service.gd"
var ships: Array=[]
var ship_list: ItemList
var details: Control
var satellite: bool=false

func _ready() -> void:
	super._ready()
	content.hide()
	label_at("ShipyardHeading","Ships available:",Rect2(20,16,340,30),20)
	ship_list=ItemList.new();ship_list.name="ShipyardList";ship_list.position=Vector2(20,54);ship_list.size=Vector2(340,396)
	ship_list.add_theme_font_override("font",font);ship_list.add_theme_font_size_override("font_size",20)
	var black=StyleBoxFlat.new();black.bg_color=Color.BLACK;black.border_color=Color("777777");black.set_border_width_all(1)
	ship_list.add_theme_stylebox_override("panel",black)
	var green=StyleBoxFlat.new();green.bg_color=Color("087600")
	for state in ["selected","selected_focus"]: ship_list.add_theme_stylebox_override(state,green)
	ship_list.add_theme_color_override("font_selected_color",Color.WHITE)
	ships=game.shipyard.ships()
	for id in ships: ship_list.add_item(game.catalog.record("ships",id).name)
	canvas.add_child(ship_list);ship_list.item_selected.connect(select_ship)
	var index=maxi(0,ships.find(game.shipyard.selected));ship_list.select(index);ship_list.ensure_current_is_visible();select_ship(index)
	if game.pilot.secrets.get("satellite",false):
		button_at("SatelliteSecret","Satellite of Love",Rect2(260,472,220,40),show_satellite)
	button_at("LeaveShipyard","Leave",Rect2(20,472,220,40),func():game.set_mode("dock"))

func select_ship(index: int) -> void:
	var id: int=int(ships[index]);game.shipyard.selected=id
	if is_instance_valid(details): canvas.remove_child(details);details.queue_free()
	details=Control.new();details.position=Vector2(390,16);details.size=Vector2(590,498);canvas.add_child(details)
	var base=canvas;canvas=details
	var ship: Dictionary=game.catalog.record("ships",id);var f: Dictionary=ship.fields
	label_at("ShipyardName",ship.name,Rect2(0,0,570,36),26)
	label_at("ShipyardBalance","Credits: "+game.hud.commas(game.pilot.credits),Rect2(0,38,570,28),18)
	var viewport=SubViewport.new();viewport.size=Vector2i(560,280);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;details.add_child(viewport)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.7;viewport.add_child(env)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=1.5;viewport.add_child(light)
	var model=game.ShipModels.create(game.catalog,id,-1);viewport.add_child(model)
	var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=float(model.get_meta("radius"))*3.4;camera.position=Vector3(0,250,160);viewport.add_child(camera);camera.look_at(Vector3.ZERO)
	var image=TextureRect.new();image.name="ShipyardPreview";image.position=Vector2(0,76);image.size=Vector2(570,170);image.texture=viewport.get_texture();image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;details.add_child(image)
	label_at("ShipyardStats","Cargo: %d t     Equipment: %d t\nShields: %d     Armor: %d" % [f.Holds,f.FreeMass,f.Shield,f.Armor],Rect2(0,258,570,60),20)
	label_at("ShipyardPrice","Trade-in price: %s credits" % game.hud.commas(game.shipyard.price(id)),Rect2(0,324,570,30),20)
	var reason: String=game.shipyard.reason(id)
	label_at("ShipyardRestriction",reason,Rect2(0,360,570,42),16)
	label_at("ShipyardTerms","Stock weapons included. Your trade-in: %s cr. Mission equipment transfers." % game.hud.commas(game.shipyard.trade_in()),Rect2(0,408,570,44),15)
	var buy=button_at("BuyShip%d" % id,"Buy Ship",Rect2(350,456,220,40),game.shipyard.buy.bind(id));buy.disabled=not reason.is_empty();buy.tooltip_text=reason
	canvas=base

func show_satellite() -> void:
	if not is_instance_valid(details): return
	# Original 1.0.5 code uses desc 2900 / PICT 5200 as a shipyard easter egg.
	# Keep the actual selected hull explicit instead of inventing ship statistics.
	for child in details.get_children():
		if child.name in ["ShipyardName","ShipyardPreview"]: child.hide()
	var picture=details.get_node_or_null("SatellitePicture")
	if picture==null:
		picture=TextureRect.new();picture.name="SatellitePicture";picture.position=Vector2(120,76);picture.size=Vector2(320,170)
		picture.texture=load("res://assets/classic/5200.png");picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;details.add_child(picture)
		var text=RichTextLabel.new();text.name="SatelliteStory";text.position=Vector2(0,258);text.size=Vector2(570,190);text.text=str(game.catalog.data.descriptions.get("2900",""));text.add_theme_font_override("normal_font",font);text.add_theme_font_size_override("normal_font_size",16);details.add_child(text)
		for id in ["ShipyardStats","ShipyardPrice","ShipyardRestriction","ShipyardTerms"]: details.get_node(id).hide()
		var base=canvas;canvas=details
		label_at("SatelliteTitle","Satellite of Love",Rect2(0,0,570,36),26)
		canvas=base
		for child in details.get_children():
			if child is Button: child.hide()
		satellite=true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and Input.is_physical_key_pressed(KEY_S) and Input.is_physical_key_pressed(KEY_O) and Input.is_physical_key_pressed(KEY_L):
		game.pilot.secrets.satellite=true;game.save_game(false);show_satellite();get_viewport().set_input_as_handled()
