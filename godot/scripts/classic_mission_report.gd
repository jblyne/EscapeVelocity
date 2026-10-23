extends "res://scripts/classic_port.gd"
# Original manual PICT 2019: plain narrative and a bottom-right Okay button.
var layout=Vector2(730,410)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/classic_text.gd").body()
	canvas=Control.new();canvas.size=layout;add_child(canvas)
	panel(Rect2(Vector2.ZERO,layout))
	var report: Dictionary=game.missions.active_landing_report
	var heading=Label.new();heading.name="MissionReportHeading"
	heading.position=Vector2(16,12);heading.size=Vector2(698,26)
	heading.text=str(report.get("heading","MISSION REPORT"))+" · "+str(report.get("mission",""))
	heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.add_theme_font_override("font",font);heading.add_theme_font_size_override("font_size",17)
	heading.add_theme_color_override("font_color",Color("a9db93") if report.get("heading","")=="MISSION COMPLETE" else Color("f1b28b") if report.get("heading","")=="MISSION FAILED" else Color("dddddd"))
	canvas.add_child(heading)
	var status=Label.new();status.name="MissionReportStatus"
	status.position=Vector2(16,42);status.size=Vector2(698,44)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.text=str(report.get("status",""));status.add_theme_font_size_override("font_size",14)
	status.add_theme_font_override("font",font);status.add_theme_color_override("font_color",Color("bbbbbb"))
	canvas.add_child(status)
	var body=RichTextLabel.new();body.name="MissionReportNarrative"
	body.position=Vector2(16,96);body.size=Vector2(698,240)
	body.bbcode_enabled=false;body.fit_content=false
	body.add_theme_font_override("normal_font",font)
	body.add_theme_font_size_override("normal_font_size",20)
	body.add_theme_color_override("default_color",Color("dddddd"))
	body.text=report.get("body","")
	canvas.add_child(body)
	var okay=button_at("DismissMissionReport","Okay",Rect2(560,354,152,40),game.missions.dismiss_landing_report)
	okay.tooltip_text=report.get("status","")
	resized.connect(fit);fit()

func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/layout.x,(size.y-40)/layout.y))
	canvas.scale=Vector2.ONE*ratio
	canvas.position=(size-layout*ratio)*.5
