extends Control

# Original manual PICT 2008: 440 x 396, rebuilt at twice its design size.
const DESIGN=Vector2(880,792)
const Intel=preload("res://scripts/system_intel.gd")
const Chart=preload("res://scripts/map_view.gd")
var game
var canvas: Control
var chart
var font: Font
var intel_open: bool=false
var intel_section: String="leads"
var intel_tabs: Array[Button]=[]
var intel_body: RichTextLabel
var intel_button: Button
var clear_button: Button
var readouts: Dictionary={}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	font=SystemFont.new();font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
	canvas=Control.new();canvas.size=DESIGN;add_child(canvas)
	for rect in [Rect2(1,1,878,790),Rect2(18,16,600,600),Rect2(628,16,238,600),Rect2(18,624,848,88)]:
		var panel=Panel.new();panel.position=rect.position;panel.size=rect.size;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var style=StyleBoxFlat.new();style.bg_color=Color.BLACK;style.border_color=Color("888888");style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel",style);canvas.add_child(panel)
	chart=Chart.new();chart.game=game;chart.position=Vector2(20,18);chart.size=Vector2(596,596);canvas.add_child(chart)
	chart.changed.connect(refresh_details)
	make_button("ZoomOut","−",Rect2(78,730,52,44),func():chart.change_zoom(1.0/1.35)).tooltip_text="Zoom out · −"
	make_button("ZoomIn","+",Rect2(140,730,52,44),func():chart.change_zoom(1.35)).tooltip_text="Zoom in · +"
	clear_button=make_button("ClearRoute","Clear Route",Rect2(218,730,196,44),func():game.map_route.clear();game.destination=-1;chart.queue_redraw();refresh_details())
	make_button("MapDone","Done",Rect2(674,730,148,44),func():game.set_mode(game.map_return_mode))
	intel_button=make_button("SystemIntel","Leads & Unlocks",Rect2(438,730,210,44),func():intel_open=not intel_open;refresh_details())
	intel_button.add_theme_font_size_override("font_size",19)
	intel_body=RichTextLabel.new();intel_body.name="SystemIntelText";intel_body.position=Vector2(642,138);intel_body.size=Vector2(214,462)
	intel_body.add_theme_font_override("normal_font",font);intel_body.add_theme_font_size_override("normal_font_size",15)
	intel_body.add_theme_color_override("default_color",Color("dddddd"));intel_body.bbcode_enabled=false;intel_body.scroll_active=true
	canvas.add_child(intel_body)
	intel_tabs.append(make_button("IntelLeads","Leads",Rect2(642,94,102,32),func():intel_section="leads";refresh_details()))
	intel_tabs.append(make_button("IntelStock","Stock",Rect2(752,94,102,32),func():intel_section="stock";refresh_details()))
	for tab in intel_tabs: tab.add_theme_font_size_override("font_size",16)
	resized.connect(fit);fit();refresh_details()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,.8))

func fit() -> void:
	var ratio=minf((size.x-32)/DESIGN.x,(size.y-32)/DESIGN.y)
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-DESIGN*ratio)*.5

func make_button(id: String,text: String,rect: Rect2,action: Callable) -> Button:
	var b=Button.new();b.name=id;b.text=text;b.position=rect.position;b.size=rect.size;b.focus_mode=Control.FOCUS_NONE
	b.add_theme_font_override("font",preload("res://assets/fonts/EVOriginal.ttf"));b.add_theme_font_size_override("font_size",22)
	for state in ["normal","hover","pressed","disabled"]:
		var style=StyleBoxFlat.new();style.bg_color=Color("777777") if state!="pressed" else Color("444444")
		style.set_border_width_all(4);style.border_color=Color("444444");style.border_color=Color("999999") if state=="hover" else style.border_color
		style.shadow_color=Color("222222");style.shadow_size=2
		b.add_theme_stylebox_override(state,style)
	b.pressed.connect(func():game.sound("menu_click");action.call());canvas.add_child(b);return b

func text(at: Vector2,value: String,color: Color=Color("dddddd"),font_size: int=16) -> void:
	var key: String=str(at)
	if not readouts.has(key):
		var label=preload("res://scripts/reconstruction_readout.gd").new() if at==Vector2(656,130) else Label.new();label.position=at-Vector2(0,font_size+2);label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		label.size=Vector2(210 if at.x>=628 else 810,26);label.clip_text=true
		label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",font_size)
		canvas.add_child(label);readouts[key]=label
	readouts[key].text=value;readouts[key].add_theme_color_override("font_color",color);readouts[key].show()

func details() -> Dictionary:
	var id: int=game.map_selected if game.map_selected>=0 else game.pilot.system_id
	var s: Dictionary=game.catalog.system(id)
	var dominated: Array=chart.dominated_worlds(id)
	var explored: bool=id in game.pilot.visited or id in game.pilot.surveyed or id==game.pilot.system_id or not dominated.is_empty()
	var ports: Array=[];var flags: int=0
	if explored:
		for port in s.objects:
			var obj: Dictionary=game.catalog.record("objects",port)
			if game.world_killer.destroyed(port) or not int(obj.fields.Flags)&1: continue
			ports.append(obj.name);flags|=int(obj.fields.Flags)
	var gov: int=int(s.fields.Govt)
	var legal: String="Unknown"
	if explored: legal="Dominated" if not dominated.is_empty() else ("Hostile" if game.Factions.hostile_to_pilot(game.catalog,game.pilot,gov) else "Clean")
	var services: Array=[]
	if flags&2: services.append("Trading")
	if flags&4: services.append("Outfitting")
	if flags&8: services.append("Shipyard")
	var goods: Array=[];var market: Dictionary={}
	for i in game.catalog.data.commodities.size():
		var quotes: Array=[]
		if explored:
			for port in s.objects:
				var obj: Dictionary=game.catalog.record("objects",int(port))
				if game.world_killer.destroyed(int(port)) or not int(obj.fields.Flags)&1 or not int(obj.fields.Flags)&2: continue
				if game.catalog.commodity_band(int(port),i)<=0: continue
				quotes.append({"port":int(port),"name":obj.name,"price":int(game.world_activity.prices(int(port))[i])})
		if not quotes.is_empty():
			var good: String=game.catalog.data.commodities[i].name
			goods.append(good);market[good]=quotes
	return {"id":id,"name":s.get("name","Unknown"),"explored":explored,"gov":game.catalog.government(id) if explored else "Unknown","legal":legal,"dominated":dominated,"tribute":game.world_activity.tribute_summary(id),"shattered":chart.shattered_worlds(id),"ports":ports,"goods":goods,"market":market,"services":services,"hazards":"Unknown" if not explored else ", ".join((["Asteroids"] if int(s.fields.Asteroids)>0 else [])+(["Scanner interference"] if int(s.fields.Interference)>0 else [])) if int(s.fields.Asteroids)>0 or int(s.fields.Interference)>0 else "None"}

func refresh_details() -> void:
	for label in readouts.values(): label.hide()
	var d=details()
	intel_body.visible=intel_open
	for tab in intel_tabs: tab.visible=intel_open
	intel_button.text="System Details" if intel_open else "Leads & Unlocks"
	text(Vector2(646,40),"Current System:" if int(d.id)==game.pilot.system_id else "Selected System:")
	text(Vector2(656,66),d.name)
	if not d.shattered.is_empty():
		text(Vector2(646,104),"Destroyed targets:",Color("ffad60"))
		text(Vector2(656,130),", ".join(d.shattered),Color("ffad60"))
	var reconstruction_notes: Array[String]=[]
	var reconstruction_ports: Array=[]
	if readouts.has(str(Vector2(656,130))): readouts[str(Vector2(656,130))].ports=[]
	for port in game.catalog.system(int(d.id)).get("objects",[]):
		var note: String=game.world_killer.reconstruction_text(int(port))
		if not note.is_empty():
			reconstruction_notes.append(game.catalog.record("objects",int(port)).name+": "+note)
			reconstruction_ports.append(int(port))
	if d.explored and not reconstruction_notes.is_empty():
		text(Vector2(646,104),"Steel reconstruction",Color("a7cce8"))
		text(Vector2(656,130),"%d restored · %d shattered · hover" % [reconstruction_notes.size()-d.shattered.size(),d.shattered.size()],Color("a7cce8"))
		readouts[str(Vector2(656,130))].game=game
		readouts[str(Vector2(656,130))].ports=reconstruction_ports
		readouts[str(Vector2(656,130))].mouse_filter=Control.MOUSE_FILTER_PASS
		readouts[str(Vector2(656,130))].tooltip_text="\n".join(reconstruction_notes)
	text(Vector2(646,164),"Government:");text(Vector2(656,190),d.gov)
	text(Vector2(646,252),"Legal Status:");text(Vector2(656,278),d.legal,chart.DOMINATED_COLOR if not d.dominated.is_empty() else Color("dddddd"))
	var legal_label: Label=readouts[str(Vector2(656,278))]
	legal_label.mouse_filter=Control.MOUSE_FILTER_PASS
	legal_label.tooltip_text="Tribute-paying worlds: "+", ".join(d.dominated) if not d.dominated.is_empty() else ""
	text(Vector2(646,326),"Goods Traded (cr/t):")
	var y: float=352
	for good in d.goods:
		var low: int=2147483647;var high: int=0;var tooltip: Array[String]=[]
		for quote in d.market[good]:
			low=mini(low,int(quote.price));high=maxi(high,int(quote.price))
			tooltip.append("%s: %d cr/t" % [quote.name,quote.price])
		text(Vector2(646,y),good,Color("dddddd"),14)
		readouts[str(Vector2(646,y))].size.x=108
		text(Vector2(754,y),str(low) if low==high else "%d–%d" % [low,high],Color("dddddd"),14)
		var price_label: Label=readouts[str(Vector2(754,y))]
		price_label.size.x=100;price_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		price_label.mouse_filter=Control.MOUSE_FILTER_PASS
		price_label.tooltip_text="Current exchange price per tonne.\n"+"\n".join(tooltip)
		y+=22
	if d.goods.is_empty(): text(Vector2(656,y),"None" if d.explored else "Unknown")
	text(Vector2(646,502),"Services:");y=528
	for service in d.services: text(Vector2(656,y),service);y+=22
	if d.services.is_empty(): text(Vector2(656,y),"None" if d.explored else "Unknown")
	var names: String=", ".join(d.ports)
	if names.is_empty(): names="None" if d.explored else "Unknown"
	text(Vector2(36,650),"Ports: "+names.left(92))
	if int(d.tribute.worlds)>0:
		var value: String="Tribute: %s cr/day · Hunters sent: %d · Defeated: %d" % [game.hud.commas(int(d.tribute.income)),int(d.tribute.sent),int(d.tribute.defeated)]
		if int(d.tribute.gave_up)==int(d.tribute.worlds): value+=" · They gave up"
		text(Vector2(36,674),value,Color("a7ef80"),14)
		var info: Label=readouts[str(Vector2(36,674))]
		info.tooltip_text="\n".join(d.tribute.lines);info.mouse_filter=Control.MOUSE_FILTER_PASS
	text(Vector2(36,698),"Navigation Hazards: "+d.hazards)
	text(Vector2(702,698),"Day %d" % game.pilot.campaign.day,Color("777777"),14)
	if intel_open:
		for at in readouts:
			if readouts[at].position.x>=628 and readouts[at].position.y>70: readouts[at].hide()
		intel_body.text=Intel.text(Intel.report(game,int(d.id)),intel_section)
		intel_body.scroll_to_line(0)
	clear_button.disabled=(game.map_route.is_empty() and game.destination<0) or game.hyperdrive.active() or not game.chain_route.is_empty()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	event=game.controls.remapped(event)
	match event.physical_keycode:
		KEY_C: chart.recenter()
		KEY_EQUAL,KEY_KP_ADD: chart.change_zoom(1.35)
		KEY_MINUS,KEY_KP_SUBTRACT: chart.change_zoom(1.0/1.35)
		KEY_TAB,KEY_BACKSLASH,KEY_N:
			game.cycle_destination();game.map_selected=game.destination;chart.queue_redraw();refresh_details()
		KEY_ENTER: game.set_mode(game.map_return_mode)
		_: return
	get_viewport().set_input_as_handled()
