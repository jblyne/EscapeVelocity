extends "res://scripts/classic_port.gd"
const LAYOUT=Vector2(1000,530)
var content: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/classic_text.gd").body()
	canvas=Control.new();canvas.size=LAYOUT;add_child(canvas)
	panel(Rect2(Vector2.ZERO,LAYOUT))
	content=VBoxContainer.new();content.position=Vector2(20,16);content.size=Vector2(960,498)
	content.add_theme_constant_override("separation",8);canvas.add_child(content)
	resized.connect(fit);fit()

func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5

func restyle(node: Node) -> void:
	if node is Label or node is Button:
		node.add_theme_font_override("font",font)
		node.add_theme_color_override("font_color",Color("dddddd"))
	if node is Label: node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if node is Button:
		node.add_theme_font_override("font",BUTTON_FONT)
		for state in ["normal","hover","pressed","disabled"]:
			var style=StyleBoxFlat.new()
			style.bg_color=Color("444444") if state=="pressed" else Color("777777")
			style.border_color=Color("999999") if state=="hover" else Color("444444")
			style.set_border_width_all(3)
			style.content_margin_left=10;style.content_margin_right=10
			node.add_theme_stylebox_override(state,style)
		if node.text.begins_with("Done") or node.text.begins_with("Back") or node.name=="CloseWorldChannel":
			node.text="Close Channel" if node.name=="CloseWorldChannel" else "Leave";node.size_flags_horizontal=Control.SIZE_SHRINK_END;node.custom_minimum_size.x=220
	for child in node.get_children(): restyle(child)
