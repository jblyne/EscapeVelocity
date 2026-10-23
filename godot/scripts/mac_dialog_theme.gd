extends RefCounted
const PAPER=Color("e8eeee")
static func box(fill: Color,border: Color,width: int=1,padding: int=8,radius: int=0) -> StyleBoxFlat:
	var s=StyleBoxFlat.new();s.bg_color=fill;s.border_color=border;s.set_border_width_all(width);s.set_corner_radius_all(radius)
	s.content_margin_left=padding;s.content_margin_right=padding;s.content_margin_top=padding;s.content_margin_bottom=padding
	return s
static func check_icon(checked: bool) -> Texture2D:
	var svg='<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"><rect x="2" y="2" width="14" height="14" fill="#f4f6f6" stroke="black" stroke-width="1.5"/>'
	if checked: svg+='<path d="M4 4L14 14M14 4L4 14" stroke="black" stroke-width="2"/>'
	svg+='</svg>'
	var image=Image.new();image.load_svg_from_string(svg,1)
	return ImageTexture.create_from_image(image)
static func make() -> Theme:
	var t=Theme.new();var font=SystemFont.new();font.font_names=PackedStringArray(["Chicago","Charcoal","Geneva"])
	font.font_weight=600;t.default_font=font;t.default_font_size=16
	for type in ["Label","Button","CheckBox","OptionButton","LineEdit","Tree","ItemList","RichTextLabel","TabBar"]:
		t.set_color("font_color",type,Color.BLACK)
		t.set_color("font_hover_color",type,Color.BLACK)
		t.set_color("font_focus_color",type,Color.BLACK)
		t.set_color("font_disabled_color",type,Color("777777"))
	var panel=box(PAPER,Color("4c4c5c"),2,20)
	panel.shadow_color=Color(0,0,0,.7);panel.shadow_size=3;panel.shadow_offset=Vector2(2,2)
	t.set_stylebox("panel","PanelContainer",panel)
	t.set_stylebox("panel","PopupPanel",panel)
	t.set_stylebox("panel","Panel",panel)
	t.set_stylebox("panel","FileDialog",panel)
	t.set_color("folder_icon_color","FileDialog",Color("606060"))
	t.set_color("file_icon_color","FileDialog",Color.BLACK)
	for type in ["Button","OptionButton"]:
		for state in ["normal","hover","disabled"]: t.set_stylebox(state,type,box(PAPER,Color.BLACK,1,8,5))
		t.set_stylebox("pressed",type,box(Color.BLACK,Color.BLACK,1,8,5))
		t.set_color("font_pressed_color",type,Color.WHITE)
		var focus=box(Color(0,0,0,0),Color.BLACK,3,3,7);focus.expand_margin_left=4;focus.expand_margin_right=4;focus.expand_margin_top=4;focus.expand_margin_bottom=4
		t.set_stylebox("focus",type,focus)
	t.set_stylebox("normal","LineEdit",box(Color.BLACK,Color("808888"),2,6))
	t.set_stylebox("focus","LineEdit",box(Color.BLACK,Color.BLACK,2,6))
	for color in ["font_color","font_selected_color","caret_color"]: t.set_color(color,"LineEdit",Color.WHITE)
	t.set_color("font_placeholder_color","LineEdit",Color("b0b8b8"));t.set_color("selection_color","LineEdit",Color("606868"))
	t.set_stylebox("panel","Tree",box(Color.WHITE,Color.BLACK,1,4))
	t.set_stylebox("panel","ItemList",box(Color.WHITE,Color.BLACK,1,4))
	t.set_color("font_hovered_color","ItemList",Color.BLACK)
	t.set_color("font_hovered_selected_color","ItemList",Color.WHITE)
	t.set_stylebox("hovered","ItemList",box(Color("dce4e4"),Color.TRANSPARENT,0,2))
	for state in ["hovered_selected","hovered_selected_focus"]:
		t.set_stylebox(state,"ItemList",box(Color("454b50"),Color.BLACK,1,2))
	for type in ["Tree","ItemList"]:
		t.set_stylebox("selected",type,box(Color("454b50"),Color.BLACK,0,2))
		t.set_stylebox("selected_focus",type,box(Color("454b50"),Color.BLACK,1,2))
		t.set_color("font_selected_color",type,Color.WHITE)
	for state in ["normal","hover","pressed","disabled","focus"]: t.set_stylebox(state,"CheckBox",StyleBoxEmpty.new())
	t.set_icon("checked","CheckBox",check_icon(true));t.set_icon("unchecked","CheckBox",check_icon(false))
	t.set_icon("checked_disabled","CheckBox",check_icon(true));t.set_icon("unchecked_disabled","CheckBox",check_icon(false))
	t.set_color("font_pressed_color","CheckBox",Color.BLACK)
	t.set_stylebox("embedded_border","Window",box(PAPER,Color("4c4c5c"),2,12))
	t.set_stylebox("embedded_unfocused_border","Window",box(PAPER,Color("4c4c5c"),2,12))
	t.set_color("title_color","Window",Color.BLACK);t.set_color("title_outline_modulate","Window",Color.TRANSPARENT)
	t.set_constant("title_height","Window",26)
	return t
static func frame(panel: Control,game: Node=null) -> void:
	if game!=null:
		var guard=preload("res://scripts/classic_modal_guard.gd").new()
		guard.name="ModalOutsideClick";guard.panel=panel;guard.game=game;panel.add_child(guard)
	panel.draw.connect(func():
		var bounds=Rect2(Vector2(3,3),panel.size-Vector2(6,6))
		panel.draw_rect(bounds,Color.WHITE,false,1)
		panel.draw_rect(bounds.grow(-2),Color.BLACK,false,1))
	panel.resized.connect(panel.queue_redraw)

static func classic_scrollbar(bar: ScrollBar) -> void:
	bar.add_theme_stylebox_override("scroll",box(Color.WHITE,Color.BLACK,1,0))
	bar.add_theme_stylebox_override("scroll_focus",StyleBoxEmpty.new())
	for state in ["grabber","grabber_highlight","grabber_pressed"]:
		bar.add_theme_stylebox_override(state,box(Color("dddddd"),Color.BLACK,1,0))
	for direction in ["decrement","increment"]:
		var points: String="8,3 3,8 6,8 6,13 10,13 10,8 13,8" if direction=="decrement" else "6,3 10,3 10,8 13,8 8,13 3,8 6,8"
		var svg='<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><rect x=".5" y=".5" width="15" height="15" fill="white" stroke="black"/><polygon points="%s" fill="#ddd" stroke="#888" stroke-width="1"/></svg>' % points
		var image=Image.new();image.load_svg_from_string(svg)
		var icon=ImageTexture.create_from_image(image)
		for suffix in ["","_highlight","_pressed"]: bar.add_theme_icon_override(direction+suffix,icon)
