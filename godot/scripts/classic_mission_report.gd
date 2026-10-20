extends "res://scripts/classic_port.gd"
# Original manual PICT 2019: plain narrative and a bottom-right Okay button.
var layout=Vector2(730,344)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=SystemFont.new();font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
	canvas=Control.new();canvas.size=layout;add_child(canvas)
	panel(Rect2(Vector2.ZERO,layout))
	var report: Dictionary=game.missions.active_landing_report
	var body=RichTextLabel.new();body.name="MissionReportNarrative"
	body.position=Vector2(16,16);body.size=Vector2(698,246)
	body.bbcode_enabled=false;body.fit_content=false
	body.add_theme_font_override("normal_font",font)
	body.add_theme_font_size_override("normal_font_size",20)
	body.add_theme_color_override("default_color",Color("dddddd"))
	body.text=report.get("body","")
	canvas.add_child(body)
	var okay=button_at("DismissMissionReport","Okay",Rect2(560,280,152,40),game.missions.dismiss_landing_report)
	okay.tooltip_text=report.get("status","")
	resized.connect(fit);fit()

func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/layout.x,(size.y-40)/layout.y))
	canvas.scale=Vector2.ONE*ratio
	canvas.position=(size-layout*ratio)*.5
