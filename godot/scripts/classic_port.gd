extends Control
const Intel=preload("res://scripts/system_intel.gd")
const Art=preload("res://scripts/landing_art.gd")
const DESIGN=Vector2(1200,632)
const BUTTON_FONT=preload("res://assets/fonts/EVOriginal.ttf")
var game
var canvas: Control
var font: Font
var scenery: TextureRect
var compact_service: bool=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/classic_text.gd").body()
	compact_service=game.hud.port_page in ["exchange","bar","intel","gambling"]
	canvas=Control.new();canvas.size=DESIGN;add_child(canvas)
	panel(Rect2(Vector2.ZERO,DESIGN))
	match game.hud.port_page:
		"exchange": build_exchange()
		"bar": build_bar()
		"gambling": pass
		"intel": build_intel()
		_: build_landing()
	resized.connect(fit);fit()

func _draw() -> void: draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,.8))
func fit() -> void:
	var layout=Vector2(1000,530) if compact_service else DESIGN
	var ratio=minf((size.x-40)/layout.x,(size.y-40)/layout.y)
	if compact_service: ratio=minf(1.0,ratio)
	canvas.scale=layout/DESIGN*ratio;canvas.position=(size-layout*ratio)*.5
func panel(rect: Rect2) -> void:
	var p=Panel.new();p.position=rect.position;p.size=rect.size;p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style=StyleBoxFlat.new();style.bg_color=Color.BLACK;style.border_color=Color("888888");style.set_border_width_all(2)
	p.add_theme_stylebox_override("panel",style);canvas.add_child(p)
func label_at(id: String,value: String,rect: Rect2,font_size: int=20,color: Color=Color("dddddd")) -> Label:
	var n=Label.new();n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;n.name=id;n.text=value;n.position=rect.position;n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	n.add_theme_font_override("font",font);n.add_theme_font_size_override("font_size",font_size);n.add_theme_color_override("font_color",color)
	n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;n.size=rect.size;canvas.add_child(n);return n
func button_at(id: String,value: String,rect: Rect2,action: Callable) -> Button:
	var b=Button.new();b.name=id;b.text=value;b.position=rect.position;b.size=rect.size;b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_override("font",font);b.add_theme_font_size_override("font_size",22)
	style_classic_button(b)
	b.pressed.connect(func():game.sound("menu_click");game.missions.bar_activity();action.call());canvas.add_child(b);return b

static func style_classic_button(b: Button) -> void:
	b.add_theme_font_override("font",BUTTON_FONT)
	for state in ["normal","hover","pressed","disabled"]:
		var style=StyleBoxFlat.new();style.bg_color=Color("777777") if state!="pressed" else Color("444444")
		style.border_color=Color("999999") if state=="hover" else Color("444444");style.set_border_width_all(4)
		style.shadow_color=Color("222222");style.shadow_size=2;b.add_theme_stylebox_override(state,style)
	b.add_theme_color_override("font_color",Color.WHITE)
func page(value: String) -> void:
	game.hud.port_page=value;game.hud.rebuild_modal()
	if value=="bar": game.missions.begin_bar_approach()
func mission_computer(channel: int) -> void:
	game.missions.channel=channel;game.missions.open()

func build_landing() -> void:
	var port: Dictionary=game.catalog.record("objects",game.docked_id)
	scenery=TextureRect.new();scenery.name="LandingScenery";scenery.position=Vector2(16,16);scenery.size=Vector2(666,542)
	scenery.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;scenery.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scenery.texture=Art.texture(game.catalog,game.docked_id,game.world_killer.reconstruction(game.docked_id));scenery.tooltip_text=port.name;canvas.add_child(scenery)
	var description: String=str(game.catalog.data.descriptions.get(str(game.docked_id),""))
	var body=RichTextLabel.new();body.name="PortDescription";body.position=Vector2(696,20);body.size=Vector2(488,226)
	body.bbcode_enabled=false;body.fit_content=false;body.scroll_active=true;body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("normal_font",font);body.add_theme_font_size_override("normal_font_size",20)
	body.add_theme_color_override("default_color",Color("dddddd"));body.text=description
	var rebuilding: String=game.world_killer.reconstruction_text(game.docked_id)
	if not rebuilding.is_empty(): body.text=rebuilding+"\n\n"+body.text
	canvas.add_child(body)
	var actions: Array=[
		["RefuelShip","Refuel Ship",game.refuel_ship],
		["OpenExchange","Commodity Exchange",func():page("exchange")],
		["OpenOutfitter","Outfit Ship",func():game.set_mode("outfitter")]]
	if int(port.fields.Flags)&8: actions.append(["OpenShipyard","Visit Shipyard",func():game.set_mode("shipyard")])
	actions.append(["LocalLeads","Local Leads",func():page("intel")])
	actions.append(["OpenSpaceportBar","Spaceport Bar",func():page("bar")])
	var y: float=548-actions.size()*48
	for action in actions:
		var b=button_at(action[0],action[1],Rect2(752,y,396,38),action[2])
		if action[0]=="OpenExchange": b.disabled=not int(port.fields.Flags)&2
		if action[0]=="OpenOutfitter": b.disabled=not int(port.fields.Flags)&4
		if action[0]=="RefuelShip":
			b.tooltip_text="Refuel · %s cr for a full tank" % game.hud.commas(game.refuel_cost())
			b.disabled=game.pilot.fuel>=game.pilot.fuel_capacity() or bool(int(port.fields.Flags)&32) or (game.refuel_cost()>0 and game.pilot.credits<=0)
			if game.pilot.fuel>=game.pilot.fuel_capacity(): b.tooltip_text="Fuel tank full."
		y+=48
	button_at("OpenMissions","Mission Computer",Rect2(186,572,320,44),func():mission_computer(0))
	button_at("LeavePort","Leave",Rect2(752,572,396,44),game.launch).tooltip_text="Launch · L"

func build_exchange() -> void:
	panel(Rect2(20,20,846,498))
	label_at("ExchangeHeading","Commodity:",Rect2(36,28,330,28),20)
	label_at("FleetHeading","In Fleet:",Rect2(432,28,170,28),20)
	label_at("PriceHeading","Price:",Rect2(622,28,220,28),20)
	var prices: Array=game.world_activity.prices(game.docked_id)
	for good in game.catalog.data.commodities:
		var id: int=int(good.id);var y: float=70+id*52
		var chosen: bool=id==game.hud.market_good
		var b=button_at("Commodity%d" % id,good.name,Rect2(28,y,826,42),func():game.hud.market_good=id;game.hud.rebuild_modal())
		var style=StyleBoxFlat.new();style.bg_color=Color("126600") if chosen else Color.BLACK
		for state in ["normal","hover","pressed"]: b.add_theme_stylebox_override(state,style)
		b.add_theme_font_override("font",font)
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		label_at("Quantity%d" % id,str(game.fleet_service.commodity_count(id))+" t",Rect2(432,y+6,130,32),22)
		var base: float=float(good.base_price);var cost: int=int(prices[id])
		var rating: String="Unavailable" if cost<0 else "Low" if cost<base*.9 else "High" if cost>base*1.1 else "Med"
		label_at("Price%d" % id,rating if cost<0 else "%s   %d" % [rating,cost],Rect2(622,y+6,220,32),22)
	var selected: int=game.hud.market_good
	var buy=button_at("BuyCommodity","Buy",Rect2(902,24,264,44),func():trade(true))
	buy.disabled=int(prices[selected])<0 or game.pilot.credits<int(prices[selected]) or game.fleet_service.total_cargo_used()>=game.fleet_service.cargo_capacity()
	buy.tooltip_text="Buy up to 10 tonnes"
	var sell=button_at("SellCommodity","Sell",Rect2(902,88,264,44),func():trade(false))
	sell.disabled=int(prices[selected])<0 or game.fleet_service.commodity_count(selected)==0;sell.tooltip_text="Sell up to 10 tonnes"
	label_at("OtherCargo","Other cargo: "+("parcels" if game.pilot.cargo_used()>game.pilot.cargo.reduce(func(a,b):return a+b,0) else "None"),Rect2(36,430,812,48),20)
	label_at("HoldSpace","Fleet holds: %d / %d t · %s credits" % [game.fleet_service.total_cargo_used(),game.fleet_service.cargo_capacity(),game.hud.commas(game.pilot.credits)],Rect2(36,532,830,52),20)
	var headlines: Array=game.world_activity.headlines(game.docked_id)
	var news: String=str(headlines[0]) if not headlines.is_empty() else ""
	label_at("MarketNews",news,Rect2(36,578,830,36),16)
	button_at("LeaveExchange","Leave",Rect2(902,568,264,44),func():page("landing"))

func trade(buying: bool) -> void:
	if game.mode!="dock" or game.hud.port_page!="exchange": return
	var index: int=game.hud.market_good
	var price: int=int(game.world_activity.prices(game.docked_id)[index])
	var amount: int=0
	for i in 10:
		if not game.fleet_service.trade(index,buying,price): break
		amount+=1
	if amount>0: game.save_game(false)
	game.hud.rebuild_modal()

func build_bar() -> void:
	label_at("BarTitle","Spaceport Bar",Rect2(32,28,700,44),28,Color("55ee33"))
	label_at("BarWorld",game.catalog.record("objects",game.docked_id).name,Rect2(32,90,700,38),22)
	label_at("BarDescription","Captains and travelers trade news and look for work. Check the bar's offers, watch the news, or hire captains for your fleet.",Rect2(32,152,700,168),22)
	button_at("BarOffers","Bar Offers",Rect2(800,270,360,44),func():mission_computer(1))
	button_at("OpenNews","Watch Holo-Vid",Rect2(800,332,360,44),game.world_activity.open_news)
	button_at("HireEscorts","Hire an Escort",Rect2(800,394,360,44),game.toggle_fleet_menu)
	button_at("Gamble","Gamble",Rect2(800,456,360,44),func():page("gambling"))
	button_at("LeaveBar","Leave",Rect2(800,568,360,44),func():page("landing"))

func build_intel() -> void:
	label_at("LocalIntelHeading","Local Leads — "+str(game.catalog.record("objects",game.docked_id).name),Rect2(24,18,1140,40),24)
	panel(Rect2(20,72,1160,486))
	var body=RichTextLabel.new();body.name="LocalIntelText";body.position=Vector2(36,86);body.size=Vector2(1128,456)
	body.add_theme_font_override("normal_font",font);body.add_theme_font_size_override("normal_font_size",21)
	body.add_theme_color_override("default_color",Color("dddddd"));body.bbcode_enabled=false;body.scroll_active=true
	body.text=Intel.text(Intel.report(game,game.pilot.system_id,game.docked_id));canvas.add_child(body)
	button_at("IntelBack","Back to Spaceport",Rect2(776,576,380,38),func():page("landing"))

func _input(event: InputEvent) -> void:
	if game.mode=="dock" and game.hud.port_page=="bar" and event is InputEventMouseButton and event.pressed: game.missions.bar_activity()
