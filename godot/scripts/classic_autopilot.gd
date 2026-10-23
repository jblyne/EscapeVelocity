extends "res://scripts/classic_port.gd"
const LAYOUT=Vector2(1000,620)
var list: VBoxContainer
var trades: bool=false
var choices: Array=[]
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/classic_text.gd").body()
	canvas=Control.new();canvas.size=LAYOUT;add_child(canvas);panel(Rect2(Vector2.ZERO,LAYOUT))
	label_at("AutopilotHeading","Autopilot",Rect2(24,16,900,38),26)
	label_at("AutopilotInstructions","Choose a row to engage. A cancels at any time.",Rect2(24,60,940,30),18)
	button_at("AutopilotMissions","Active Missions",Rect2(24,104,280,36),func():trades=false;fill())
	button_at("AutopilotTradeRoutes","Trading Loops",Rect2(318,104,280,36),func():trades=true;fill())
	var scroll=ScrollContainer.new();scroll.position=Vector2(24,156);scroll.size=Vector2(952,350);canvas.add_child(scroll)
	list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",10);scroll.add_child(list)
	label_at("AutopilotLimits","Normal travel, cargo and fuel costs apply. Story reports wait for Okay. Combat / boarding missions require manual objectives first. Trade loops use discovered adjacent systems with low / high prices; fuel reduces the quoted spread.",Rect2(24,520,700,78),16,Color("aaaaaa"))
	button_at("AutopilotBack","Back",Rect2(776,560,200,36),func():game.set_mode(game.autopilot.return_mode))
	fill();resized.connect(fit);fit()
func fill() -> void:
	for child in list.get_children(): list.remove_child(child);child.queue_free()
	choices=game.autopilot.trade_routes() if trades else game.autopilot.mission_options()
	if choices.is_empty():
		var empty=Label.new();empty.name="NoAutopilotRoutes";empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;empty.custom_minimum_size=Vector2(900,90);empty.text="No known adjacent low/high trading pairs. Visit or survey neighboring systems to reveal routes." if trades else "No active transport mission ready for autopilot. Accept a delivery or finish its manual combat / boarding objective first."
		empty.add_theme_font_size_override("font_size",19);list.add_child(empty)
	for i in choices.size():
		var option: Dictionary=choices[i]
		var caption: String=str(option.name)
		if trades:
			var low: Dictionary=game.catalog.record("objects",int(option.low));var high: Dictionary=game.catalog.record("objects",int(option.high))
			caption+=" · "+low.name+" → "+high.name+" · 1 jump each way\nBuy %d · Sell %d · Spread +%d cr/t (before fuel)" % [option.buy,option.sell,option.margin]
			var aboard: int=game.fleet_service.commodity_count(int(option.good))
			if aboard>0: caption+=" · Sell %d t aboard at %s first" % [aboard,high.name]
		else:
			var target: int=game.autopilot.mission_target(option)
			caption+="\n"+str(game.catalog.record("objects",target).get("name","Unknown"))+" · "+str(game.catalog.system(game.missions.system_of(target)).get("name","Unknown"))+" · %d jump(s)" % game.autopilot.path(game.pilot.system_id,game.missions.system_of(target)).size()
		var button=Button.new();button.name="EngageAutopilot%d" % i;button.text=caption;button.custom_minimum_size=Vector2(916,66);button.clip_text=true;button.focus_mode=Control.FOCUS_NONE
		style_classic_button(button);button.add_theme_font_size_override("font_size",18)
		button.tooltip_text=caption;button.pressed.connect(func():game.sound("menu_click");game.autopilot.start(option));list.add_child(button)
func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5
