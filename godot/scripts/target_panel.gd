extends PanelContainer

const Models = preload("res://scripts/models.gd")
const INK = Color("deebf1")
const MUTED = Color("7f9aaa")
const FRIENDLY = Color("73c6ce")
const HOSTILE = Color("e98c78")
var game
var contact_name: Label
var contact_status: Label
var empty_hint: Label
var integrity_text: Label
var integrity: ProgressBar
var distance_text: Label
var speed_text: Label
var faction_text: Label
var role_text: Label
var class_text: Label
var details: VBoxContainer
var preview_texture: TextureRect
var preview_viewport: SubViewport
var preview_model: Node3D
var preview_source_id: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -286
	offset_right = -36
	offset_top = 166
	var style = StyleBoxFlat.new()
	style.bg_color = Color("08151f")
	style.border_color = Color("294653")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	add_theme_stylebox_override("panel",style)
	var col = VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation",6)
	add_child(col)
	make_label(col,"SELECTED SHIP",11,MUTED)
	contact_name = make_label(col,"No ship selected",18,INK)
	contact_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contact_status = make_label(col,"Tab selects a contact",12,MUTED)
	contact_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_texture = TextureRect.new()
	preview_texture.custom_minimum_size = Vector2(218,136)
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(preview_texture)
	empty_hint = make_label(col,"Press Tab to inspect a nearby ship.",13,MUTED)
	empty_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details = VBoxContainer.new()
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_theme_constant_override("separation",8)
	col.add_child(details)
	faction_text = make_label(details,"",13,INK)
	faction_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role_text = make_label(details,"",12,MUTED)
	class_text = make_label(details,"",12,MUTED)
	integrity_text = make_label(details,"",13,INK)
	integrity = ProgressBar.new()
	integrity.custom_minimum_size.y = 5
	integrity.show_percentage = false
	integrity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg = StyleBoxFlat.new(); bg.bg_color = Color("193340")
	var fg = StyleBoxFlat.new(); fg.bg_color = FRIENDLY
	integrity.add_theme_stylebox_override("background",bg)
	integrity.add_theme_stylebox_override("fill",fg)
	details.add_child(integrity)
	distance_text = make_label(details,"",13,MUTED)
	speed_text = make_label(details,"",13,MUTED)
	make_label(details,"TAB  Next ship  ·  Y  Hail  ·  B  Board",11,MUTED)
	setup_preview()
	refresh()

func make_label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var result = Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size",font_size)
	result.add_theme_color_override("font_color",color)
	parent.add_child(result)
	return result

func setup_preview() -> void:
	preview_viewport = SubViewport.new()
	preview_viewport.size = Vector2i(436,272)
	preview_viewport.own_world_3d = true
	preview_viewport.transparent_bg = true
	preview_viewport.gui_disable_input = true
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	preview_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(preview_viewport)
	preview_texture.texture = preview_viewport.get_texture()
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("08151f")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b6d8ef")
	environment.environment.ambient_light_energy = 0.8
	preview_viewport.add_child(environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-25,0)
	light.light_energy = 2.4
	preview_viewport.add_child(light)
	var camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.5
	camera.near = 0.01
	camera.far = 30
	preview_viewport.add_child(camera)
	camera.position = Vector3(0,4.2,3.4)
	camera.look_at(Vector3(0,0,0.1))
	camera.current = true

func clear_preview() -> void:
	if is_instance_valid(preview_model): preview_model.free()
	preview_model = null
	preview_source_id = 0
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

func refresh() -> void:
	var contact: Dictionary = game.selected_contact()
	var selected: bool = not contact.is_empty()
	preview_texture.visible = selected
	details.visible = selected
	empty_hint.visible = not selected
	if not selected:
		contact_name.text = "No ship selected"
		contact_status.text = "%d contacts in system" % game.npcs.size()
		contact_status.add_theme_color_override("font_color",MUTED)
		empty_hint.text = "Press Tab to inspect a ship." if not game.npcs.is_empty() else "No ships detected."
		clear_preview()
		return
	var source: Node3D = contact.model
	if source.get_instance_id() != preview_source_id:
		clear_preview()
		# Show the selected contact's actual geometry and paint, without touching it.
		preview_model = source.duplicate()
		preview_model.position = Vector3.ZERO
		preview_model.scale = Vector3.ONE
		preview_model.rotation = Vector3(0,deg_to_rad(-25),0)
		Models.set_thrust(preview_model,0,0)
		preview_viewport.add_child(preview_model)
		preview_source_id = source.get_instance_id()
		preview_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var color: Color = HOSTILE if contact.hostile else FRIENDLY
	if contact.disabled: color = MUTED
	var ship_name: String = game.catalog.record("ships",contact.id).get("name","Unknown ship")
	contact_name.text = contact.name
	contact_status.text = "HOSTILE" if contact.hostile else ("FRIENDLY" if contact.get("freed",false) else "NEUTRAL")
	if contact.disabled: contact_status.text = "DISABLED · BOARDABLE"
	if ship_name != contact.name: contact_status.text = ship_name + " · " + contact_status.text
	contact_status.add_theme_color_override("font_color",color)
	faction_text.text = game.Factions.name_of(game.catalog,contact.faction)
	faction_text.add_theme_color_override("font_color",game.Factions.color_of(contact.faction))
	role_text.text = contact.behavior
	if game.pilot.reputation.has(str(contact.faction)):
		role_text.text += " · Rep. %d" % int(game.pilot.reputation[str(contact.faction)])
	var fields: Dictionary = game.catalog.record("ships",contact.id).fields
	class_text.text = "Cruise %d   ·   Crew %d" % [fields.Speed,fields.Crew]
	var percent: float = clampf(float(contact.health)/maxf(float(contact.max_health),1)*100,0,100)
	integrity.value = percent
	game.Combat.sync(contact)
	integrity_text.text = "Shields %d · Armor %d · Integrity %d%%" % [roundi(contact.shield),roundi(contact.armor),roundi(percent)]
	integrity.get_theme_stylebox("fill").bg_color = color
	distance_text.text = "Distance   %s km" % game.hud.commas(roundi(game.pilot.position.distance_to(contact.position)))
	speed_text.text = "Speed      %d" % roundi(contact.velocity.length())
