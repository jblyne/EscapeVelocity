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
		var card=Button.new();card.name="Badge_"+str(item.id);card.custom_minimum_size=Vector2(302,140)
		card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		card.disabled=float(item.fraction)>=1;card.tooltip_text="Click for your next steps" if not card.disabled else "Badge complete"
		card.pressed.connect(func():show_badge_steps(item))
		var style=StyleBoxFlat.new();style.bg_color=Color("13110a") if item.earned else Color("090909");style.border_color=Color("bda365") if item.earned else Color("444444");style.set_border_width_all(1);
		for state in ["normal","hover","pressed","disabled","focus"]: card.add_theme_stylebox_override(state,style)
		grid.add_child(card)
		var badge=preload("res://scripts/achievement_badge.gd").new();badge.position=Vector2(8,7);badge.size=Vector2(48,48);badge.unlocked=item.earned;badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(badge)
		var title=Label.new();title.position=Vector2(64,10);title.size=Vector2(228,44);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.text=item.name;title.add_theme_font_override("font",font);title.add_theme_font_size_override("font_size",17);title.add_theme_color_override("font_color",Color("e4bd68") if item.earned else Color("bbbbbb"));card.add_child(title)
		var body=Label.new();body.position=Vector2(12,60);body.size=Vector2(278,46);body.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.text=item.description;body.add_theme_font_override("font",font);body.add_theme_font_size_override("font_size",15);card.add_child(body)
		var status=Label.new();status.position=Vector2(12,111);status.size=Vector2(278,24);status.mouse_filter=Control.MOUSE_FILTER_IGNORE;status.add_theme_font_size_override("font_size",14)
		status.text="Earned · day %d" % int(item.day) if item.earned else "%d%% · Click for next steps" % roundi(float(item.fraction)*100);card.add_child(status)
	button_at("AchievementsBack","Back",Rect2(776,598,200,34),func():game.set_mode(game.achievements_return_mode))
	resized.connect(fit);fit()
func meter_at(at: Vector2,width: float,value: float) -> void:
	var meter=ColorRect.new();meter.position=at;meter.size=Vector2(width,8);meter.color=Color("252525");meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(meter)
	var fill=ColorRect.new();fill.size=Vector2(width*clampf(value,0,1),8);fill.color=Color("bb9d51");fill.mouse_filter=Control.MOUSE_FILTER_IGNORE;meter.add_child(fill)

func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5

func show_badge_steps(item: Dictionary) -> void:
	game.sound("menu_click")
	canvas.get_node("BadgeCollection").hide()
	var detail=Control.new();detail.name="BadgeDetails";canvas.add_child(detail)
	var heading=Label.new();heading.name="BadgeDetailTitle";heading.position=Vector2(344,104);heading.size=Vector2(620,52);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;heading.text=item.name
	heading.add_theme_font_override("font",font);heading.add_theme_font_size_override("font_size",24);heading.add_theme_color_override("font_color",Color("e4bd68"));detail.add_child(heading)
	var guidance: Dictionary=game.achievements.guidance(str(item.id))
	var body=RichTextLabel.new();body.name="BadgeNextSteps";body.position=Vector2(344,164);body.size=Vector2(620,354);body.bbcode_enabled=false;body.text="%d%% complete · NEXT STEPS\n\n" % roundi(float(item.fraction)*100)+str(guidance.text);body.add_theme_font_override("normal_font",font);body.add_theme_font_size_override("normal_font_size",19);detail.add_child(body)
	var back=Button.new();back.name="BadgeDetailsBack";back.text="Back to badges";back.position=Vector2(344,538);back.size=Vector2(240,36);back.add_theme_font_override("font",font);back.add_theme_font_size_override("font_size",21);style_classic_button(back);detail.add_child(back)
	back.pressed.connect(func():game.sound("menu_click");canvas.get_node("BadgeCollection").show();detail.queue_free())

	# Keep destinations structured so localized prose and prerequisites cannot select the wrong system.
	var index: int=0
	for system in guidance.destinations:
		var target: int=int(system)
		var jump=Button.new();jump.name="BadgeJump_"+str(target)
		var system_name: String=game.catalog.system(target).name
		var hops: int=game.autopilot.path(game.pilot.system_id,target).size()
		jump.text=("Return to flight · "+system_name) if target==game.pilot.system_id else ("Jump to " if hops==1 or game.pilot.cheat_chain_jump else "Jump toward ")+system_name
		jump.tooltip_text="Return to flight and start the normal jump. Route: %d hop(s). Normal jump restrictions apply." % hops
		jump.position=Vector2(600,538-index*44);jump.size=Vector2(364,36);jump.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		jump.add_theme_font_override("font",font);jump.add_theme_font_size_override("font_size",18);style_classic_button(jump);detail.add_child(jump)
		jump.pressed.connect(func():game.achievements.jump_to_guidance(target))
		index+=1
	if index>1: body.size.y-=44*(index-1)
