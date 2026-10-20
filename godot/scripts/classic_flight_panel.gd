extends Control

# Coordinates follow EV Titles / PICT 128 (144 x 480), at 2x design scale.
# Rebuilt with vector bevels and live readouts for sharp high-DPI rendering.
const DESIGN=Vector2(288,960)
const GREEN=Color("70db52")
const DIM=Color("44883a")
const WELL=Color("001a03")
const SCANNER_RANGE=2000.0
var game
var canvas: Control
var preview: TextureRect
var font: Font
var nav_hit: Button
var info_hit: Button
var menu_hit: Button

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font=SystemFont.new()
	font.font_names=PackedStringArray(["Menlo","Monaco","monospace"])
	canvas=Control.new();canvas.size=DESIGN;canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.draw.connect(draw_panel)
	preview=TextureRect.new()
	preview.position=Vector2(36,574);preview.size=Vector2(216,116)
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(preview)
	var shader=Shader.new()
	shader.code="shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float v=dot(c.rgb,vec3(0.299,0.587,0.114)); COLOR=vec4(vec3(0.32,1.0,0.24)*v,c.a); }"
	var material=ShaderMaterial.new();material.shader=shader;preview.material=material
	hotspot(Rect2(0,0,288,288),"Local radar · click for the galaxy map",func():game.set_mode("map"))
	hotspot(Rect2(0,288,288,84),"Shields, armor and fuel · click for ship information",func():game.set_mode("info"))
	nav_hit=hotspot(Rect2(0,372,288,88),"Navigation · M opens the map · J jumps",func():game.set_mode("map"))
	hotspot(Rect2(0,464,288,50),"Q / E changes weapon · click for next weapon",func():game.cycle_weapon(1))
	info_hit=hotspot(Rect2(0,518,288,408),"Ship and target information · P",func():game.set_mode("info"))
	hotspot(Rect2(8,926,130,28),"Ship information · P",func():game.set_mode("info"))
	menu_hit=hotspot(Rect2(148,926,132,28),"Settings and controls · Esc",func():game.set_mode("pause"))
	resized.connect(fit)
	fit()

func panel_width() -> float:
	return size.y*DESIGN.x/DESIGN.y

func fit() -> void:
	var ratio=size.y/DESIGN.y
	canvas.scale=Vector2.ONE*ratio
	canvas.position=Vector2(size.x-panel_width(),0)

func hotspot(rect: Rect2, hint: String, action: Callable) -> Button:
	var b=Button.new();b.position=rect.position;b.size=rect.size;b.tooltip_text=hint
	b.focus_mode=Control.FOCUS_NONE
	for state in ["normal","hover","pressed","focus"]: b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	b.pressed.connect(func():
		if game.mode=="flight": action.call())
	canvas.add_child(b)
	return b

func _process(_dt: float) -> void:
	visible=game.mode!="title"
	if not visible: return
	var target=game.hud.target_panel
	preview.texture=target.preview_viewport.get_texture()
	preview.visible=not game.selected_contact().is_empty()
	nav_hit.tooltip_text="%s\nM opens map · J jumps / cancels" % game.hud.jump_status.text
	canvas.queue_redraw()

func well(rect: Rect2) -> void:
	canvas.draw_rect(rect,Color("181c18"))
	canvas.draw_rect(rect.grow(-5),WELL)
	# Original square, raised grey frame with a dark inner lip.
	for i in 3:
		var r=rect.grow(-i)
		canvas.draw_line(r.position,Vector2(r.end.x,r.position.y),Color("737970") if i==0 else Color("4c514b"),1)
		canvas.draw_line(r.position,Vector2(r.position.x,r.end.y),Color("737970") if i==0 else Color("4c514b"),1)
		canvas.draw_line(Vector2(r.position.x,r.end.y),r.end,Color("252a24"),1)
		canvas.draw_line(Vector2(r.end.x,r.position.y),r.end,Color("252a24"),1)
	canvas.draw_rect(rect.grow(-4),Color("080d08"),false,1)

func text(value: String, y: float, color: Color=GREEN, point_size: int=20, centered: bool=true) -> void:
	var line=value
	while font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x>260 and line.length()>1:
		line=line.left(line.length()-2)+"…"
	var width=font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x
	canvas.draw_string(font,Vector2((288-width)/2 if centered else 14,y),line,HORIZONTAL_ALIGNMENT_LEFT,260,point_size,color)

func meter(y: float, title: String, value: float, color: Color) -> void:
	canvas.draw_string(font,Vector2(15,y+14),title,HORIZONTAL_ALIGNMENT_LEFT,92,18,DIM)
	var rect=Rect2(116,y,154,14)
	canvas.draw_rect(rect,Color("003300"))
	canvas.draw_rect(rect.grow(-2),Color("001000"))
	canvas.draw_rect(Rect2(rect.position+Vector2(2,2),Vector2(150*clampf(value,0,1),10)),color)
	canvas.draw_line(rect.position+Vector2(2,2),rect.position+Vector2(2+150*clampf(value,0,1),2),color.lightened(.2),1)

func draw_panel() -> void:
	for rect in [Rect2(0,0,288,288),Rect2(0,288,288,84),Rect2(0,372,288,88),Rect2(0,464,288,50),Rect2(0,518,288,244),Rect2(0,766,288,194)]: well(rect)
	draw_radar()
	var p=game.pilot
	meter(303,"Shield:",p.shield/maxf(1,p.max_shield()),Color("53ce24"))
	meter(325,"Armor:",p.armor/maxf(1,p.max_armor()),Color("499536"))
	meter(347,"Fuel:",1.0 if p.cheat_infinite_fuel else p.fuel/maxf(1,p.fuel_capacity()),Color("69ec2a"))
	if game.hyperdrive.active() or not game.chain_route.is_empty():
		text("Hyperspace",404)
		text(str(game.catalog.system(game.destination).get("name","")),433)
	elif game.landing_target>=0:
		text("Navigation",404)
		text(str(game.catalog.record("objects",game.landing_target).get("name","")),433)
	elif game.destination>=0:
		text("Hyperspace",404)
		text(str(game.catalog.system(game.destination).get("name","")),433)
	else: text("Nav System Off",425,DIM)
	text(game.arsenal.weapon_name(p.selected_weapon),484 if game.cloak.active else 495,GREEN,16 if game.cloak.active else 18)
	if game.cloak.active: text("Cloaked · weapons ready" if p.cheat_cloak else "Cloaked · weapons offline",505,GREEN,13)
	var contact: Dictionary=game.selected_contact()
	if contact.is_empty(): text("No Target",620,DIM)
	else:
		text(str(contact.name),550,GREEN,19)
		text(game.Factions.name_of(game.catalog,contact.faction),716,DIM,16)
		meter(732,"Hull:",float(contact.health)/maxf(1,contact.max_health),Color("75cb49"))
	text("Free: %d" % (p.cargo_capacity()-p.cargo_used()),797)
	if not p.mission.is_empty() or not p.campaign.active.is_empty(): text("Special Cargo",828,DIM,17)
	text("Credits:",873,DIM)
	text(game.hud.commas(p.credits),902)
	canvas.draw_string(font,Vector2(22,946),"Info · P",HORIZONTAL_ALIGNMENT_LEFT,-1,15,DIM)
	canvas.draw_string(font,Vector2(162,946),"Menu · Esc",HORIZONTAL_ALIGNMENT_LEFT,-1,15,DIM)

func draw_radar() -> void:
	var center=Vector2(144,144)
	var extent=132.0
	for body in game.planets:
		var point: Vector2=(body.position-game.pilot.position)*(extent/SCANNER_RANGE)
		var body_color: Color=game.outfitter.radar_color(game.Factions.hostile_to_pilot(game.catalog,game.pilot,int(game.catalog.field("objects",body.id,"Govt"))))
		if absf(point.x)<extent-6 and absf(point.y)<extent-6:
			if body.get("kind","")=="station": canvas.draw_rect(Rect2(center+point-Vector2(4,4),Vector2(8,8)),body_color,false,1.5)
			else: canvas.draw_arc(center+point,5,0,TAU,20,body_color,1.5,true)
	for ship in game.npcs+game.escorts:
		if not game.environment_hazards.sensor_visible(ship): continue
		var point: Vector2=(ship.position-game.pilot.position)*(extent/SCANNER_RANGE)
		if absf(point.x)<extent-4 and absf(point.y)<extent-4:
			var color: Color=game.outfitter.radar_color(ship.get("hostile",false))
			var diameter: float=game.outfitter.radar_size(ship)
			canvas.draw_rect(Rect2(center+point-Vector2.ONE*diameter*.5,Vector2.ONE*diameter),color)
	canvas.draw_rect(Rect2(center-Vector2(2,2),Vector2(4,4)),Color("98ff58"))
