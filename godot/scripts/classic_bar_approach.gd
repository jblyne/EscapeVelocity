extends "res://scripts/classic_port.gd"
const LAYOUT=Vector2(800,400)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=SystemFont.new();font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
	canvas=Control.new();canvas.size=LAYOUT;add_child(canvas);panel(Rect2(Vector2.ZERO,LAYOUT))
	label_at("ApproachHeading","You are approached in the spaceport bar…",Rect2(22,18,756,34),23)
	var offer: Dictionary=game.missions.approach
	var body=RichTextLabel.new();body.name="ApproachNarrative";body.position=Vector2(22,68);body.size=Vector2(756,246)
	body.add_theme_font_override("normal_font",font);body.add_theme_font_size_override("normal_font_size",20)
	body.add_theme_color_override("default_color",Color("dddddd"));body.bbcode_enabled=false;body.scroll_active=true
	body.text=game.missions.text_for(offer,"offer")
	if body.text.is_empty(): body.text=game.missions.text_for(offer,"QuickBrief")
	canvas.add_child(body)
	var decline=button_at("DeclineApproach","Decline",Rect2(372,338,190,40),func():game.missions.resolve_approach(false))
	decline.disabled=bool(int(game.catalog.field("missions",int(offer.id),"Flags"))&4)
	if decline.disabled: decline.tooltip_text="This original mission cannot be refused."
	button_at("AcceptApproach","Accept",Rect2(580,338,198,40),func():game.missions.resolve_approach(true))
	resized.connect(fit);fit()
func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5
