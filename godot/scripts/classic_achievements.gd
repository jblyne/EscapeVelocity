extends "res://scripts/classic_port.gd"
const LAYOUT=Vector2(1000,650)
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=SystemFont.new();font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
	canvas=Control.new();canvas.size=LAYOUT;add_child(canvas);panel(Rect2(Vector2.ZERO,LAYOUT))
	var progress: Dictionary=game.achievements.progress()
	label_at("AchievementsHeading","Achievements & Progress",Rect2(22,14,940,40),26)
	label_at("OverallCompletion","Overall: %.1f%%" % (progress.overall*100),Rect2(24,63,294,30),23,Color("e4bd68"))
	meter_at(Vector2(24,102),292,float(progress.overall))
	label_at("ExplorationProgress","Exploration: %d / %d systems visited" % [progress.visited,progress.systems],Rect2(24,126,292,44),17)
	label_at("StoryProgress","Story milestones: %.1f%%" % (progress.story*100),Rect2(24,177,292,27),18)
	var y: float=218
	for track in progress.tracks:
		label_at("Track"+str(y),track.name+" · %d%%" % roundi(track.value*100),Rect2(24,y,292,31),16)
		meter_at(Vector2(24,y+34),292,float(track.value));y+=48
	label_at("ProgressRules","40% exploration + 60% story milestones. Your faction path counts; its opposing path is not required. Repeatable jobs are optional.",Rect2(24,560,292,72),14,Color("aaaaaa"))
	var badges: Array=game.achievements.badges();var earned: int=0
	for item in badges:
		if item.earned: earned+=1
	label_at("BadgeCount","Badges: %d / %d" % [earned,badges.size()],Rect2(344,63,620,28),21)
	var scroll=ScrollContainer.new();scroll.name="BadgeCollection";scroll.position=Vector2(340,100);scroll.size=Vector2(636,478);canvas.add_child(scroll)
	var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
	for item in badges:
		var card=Panel.new();card.custom_minimum_size=Vector2(302,140)
		var style=StyleBoxFlat.new();style.bg_color=Color("13110a") if item.earned else Color("090909");style.border_color=Color("bda365") if item.earned else Color("444444");style.set_border_width_all(1);card.add_theme_stylebox_override("panel",style);grid.add_child(card)
		var badge=preload("res://scripts/achievement_badge.gd").new();badge.position=Vector2(8,7);badge.size=Vector2(48,48);badge.unlocked=item.earned;card.add_child(badge)
		var title=Label.new();title.position=Vector2(64,10);title.size=Vector2(228,44);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.text=item.name;title.add_theme_font_override("font",font);title.add_theme_font_size_override("font_size",17);title.add_theme_color_override("font_color",Color("e4bd68") if item.earned else Color("bbbbbb"));card.add_child(title)
		var body=Label.new();body.position=Vector2(12,60);body.size=Vector2(278,46);body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.text=item.description;body.add_theme_font_override("font",font);body.add_theme_font_size_override("font_size",15);card.add_child(body)
		var status=Label.new();status.position=Vector2(12,111);status.size=Vector2(278,24);status.add_theme_font_size_override("font_size",14)
		status.text="Earned · day %d" % int(item.day) if item.earned else "%d%%" % roundi(float(item.fraction)*100);card.add_child(status)
	button_at("AchievementsBack","Back",Rect2(776,598,200,34),func():game.set_mode(game.achievements_return_mode))
	resized.connect(fit);fit()
func meter_at(at: Vector2,width: float,value: float) -> void:
	var meter=ColorRect.new();meter.position=at;meter.size=Vector2(width,8);meter.color=Color("252525");meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(meter)
	var fill=ColorRect.new();fill.size=Vector2(width*clampf(value,0,1),8);fill.color=Color("bb9d51");fill.mouse_filter=Control.MOUSE_FILTER_IGNORE;meter.add_child(fill)

func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5
