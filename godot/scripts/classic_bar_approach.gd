extends "res://scripts/classic_port.gd"
const LAYOUT=Vector2(800,400)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/classic_text.gd").body()
	canvas=Control.new();canvas.size=LAYOUT;add_child(canvas);panel(Rect2(Vector2.ZERO,LAYOUT))
	label_at("ApproachHeading","You are approached in the spaceport bar…",Rect2(22,18,756,34),23)
	var offer: Dictionary=game.missions.approach
	var body=RichTextLabel.new();body.name="ApproachNarrative";body.position=Vector2(22,68);body.size=Vector2(756,238)
	body.add_theme_font_override("normal_font",font);body.add_theme_font_size_override("normal_font_size",20)
	body.add_theme_color_override("default_color",Color("dddddd"));body.bbcode_enabled=false;body.scroll_active=true
	body.text=game.missions.text_for(offer,"offer")
	if body.text.is_empty(): body.text=game.missions.text_for(offer,"QuickBrief")
	if int(offer.id)==164:
		body.text+="\n\n"+("Cloaking device: already installed. Accept to begin the insertion mission." if game.pilot.outfit_count(167)>0 else "Cloaking device: installation pending. Accept below to install it and begin the mission. After launch, press K to cloak.")
	if int(offer.id)==164: body.text+="\n\nKeep cloaked near Confederation patrols. A cargo scan fails the mission and removes the loaned cloak; you may retry here if you still meet its requirements."
	body.text+="\n\n"+game.missions.reward_summary(offer)
	var commitments: String=game.missions.commitment_notes(offer)
	if not commitments.is_empty(): body.text+="\n"+commitments
	canvas.add_child(body)
	var fields: Dictionary=game.catalog.record("missions",int(offer.id)).fields
	var warnings: PackedStringArray=[]
	if int(fields.CanAbort)==0: warnings.append("Cannot abort after acceptance")
	if int(fields.CargoType)>=0 and int(fields.ScanGovt)>=0 and int(fields.FailIfScan)!=0: warnings.append("Patrol cargo scans can fail this mission")
	if not warnings.is_empty(): label_at("ApproachCommitment"," · ".join(warnings),Rect2(22,310,756,22),14,Color("edbd8f"))
	var decline=button_at("DeclineApproach","Decline",Rect2(286,338,190,40),func():game.missions.resolve_approach(false))
	decline.disabled=bool(int(game.catalog.field("missions",int(offer.id),"Flags"))&4)
	if decline.disabled: decline.tooltip_text="This original mission cannot be refused."
	button_at("AcceptApproach","Accept & install cloak" if int(offer.id)==164 and game.pilot.outfit_count(167)==0 else "Accept",Rect2(490,338,288,40),func():game.missions.resolve_approach(true))
	resized.connect(fit);fit()
func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5
