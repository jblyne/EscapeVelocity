extends "res://scripts/classic_port.gd"
# Original manual PICT 2012 (offers) and 2013 (active journal).
var layout=Vector2(1040,412)
var entries: Array=[]
var mission_list: ItemList
var detail: Control
var selected_index: int=-1
var journal: bool=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=SystemFont.new();font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
	journal=game.missions.channel==2 or game.missions.return_mode=="flight"
	if journal: game.missions.channel=2;layout=Vector2(904,316)
	canvas=Control.new();canvas.size=layout;add_child(canvas);panel(Rect2(Vector2.ZERO,layout))
	var heading: String="Currently active missions:" if journal else "The following missions are available here:"
	label_at("MissionHeading",heading,Rect2(20,14,700,28),18)
	if journal: label_at("MissionDate","Day %d" % game.pilot.campaign.day,Rect2(758,14,128,28),16,Color("999999"))
	entries=game.pilot.campaign.active.duplicate() if journal else game.missions.offers(game.docked_id,game.missions.channel)
	if journal and not game.pilot.mission.is_empty(): entries.append({"courier":true})
	elif not journal and game.missions.channel==0 and game.pilot.mission.is_empty() and not game.courier_destination().is_empty(): entries.append({"courier":true})
	mission_list=ItemList.new();mission_list.name="MissionList";mission_list.position=Vector2(18,48 if journal else 58)
	mission_list.size=Vector2(352,172) if journal else Vector2(384,292);mission_list.allow_reselect=true
	mission_list.add_theme_font_override("font",font);mission_list.add_theme_font_size_override("font_size",18)
	var normal=StyleBoxFlat.new();normal.bg_color=Color.BLACK;normal.border_color=Color("777777");normal.set_border_width_all(1)
	mission_list.add_theme_stylebox_override("panel",normal)
	var green=StyleBoxFlat.new();green.bg_color=Color("087600")
	for state in ["selected","selected_focus"]: mission_list.add_theme_stylebox_override(state,green)
	mission_list.add_theme_color_override("font_selected_color",Color.WHITE);mission_list.add_theme_color_override("font_color",Color.WHITE)
	for i in entries.size():
		var entry: Dictionary=entries[i]
		mission_list.add_item(courier_title() if entry.get("courier",false) else game.missions.title(entry))
		if (entry.get("courier",false) and game.missions.selected_courier) or (not entry.get("courier",false) and entry==game.missions.selected): selected_index=i
	canvas.add_child(mission_list)
	mission_list.item_selected.connect(select_entry)
	if selected_index<0 and not entries.is_empty() and (journal or game.missions.last_report.is_empty()): selected_index=0
	if selected_index>=0:
		mission_list.select(selected_index);mission_list.ensure_current_is_visible();select_entry(selected_index,false)
	else: show_details()
	resized.connect(fit);fit()

func fit() -> void:
	var ratio=minf(1.0,minf((size.x-40)/layout.x,(size.y-40)/layout.y))
	canvas.scale=Vector2.ONE*ratio;canvas.position=(size-layout*ratio)*.5

func courier_title() -> String:
	var target: Dictionary=game.pilot.mission if journal else game.courier_destination()
	return "Courier to "+game.catalog.system(int(target.system)).name

func select_entry(index: int,clear_report: bool=true) -> void:
	if index<0 or index>=entries.size(): return
	selected_index=index
	var entry: Dictionary=entries[index]
	game.missions.selected_courier=entry.get("courier",false)
	game.missions.selected={} if game.missions.selected_courier else entry
	if clear_report: game.missions.last_report=""
	show_details()

func show_details() -> void:
	if is_instance_valid(detail): canvas.remove_child(detail);detail.queue_free()
	detail=Control.new();detail.size=layout;detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(detail)
	# Helpers draw directly in the detail node; the list remains intact when selecting.
	var base: Control=canvas;canvas=detail
	var entry: Dictionary=entries[selected_index] if selected_index>=0 else {}
	var title: String="";var briefing: String=""
	if not entry.is_empty():
		if entry.get("courier",false):
			title=courier_title();briefing="Deliver five tonnes of parcels to %s. Payment is 1,200 credits. No deadline." % title.trim_prefix("Courier to ")
		else:
			title=game.missions.title(entry)
			briefing=game.missions.text_for(entry,"QuickBrief" if journal else "offer")
			if briefing.is_empty(): briefing=game.missions.text_for(entry,"QuickBrief")
			if int(entry.deadline)>=0: briefing+="\n\nDeadline: day %d." % int(entry.deadline)
	elif not game.missions.last_report.is_empty(): title="Mission report";briefing=game.missions.last_report
	else: briefing="No active missions." if journal else "No missions are available here today."
	if not journal:
		var name_label=label_at("MissionTitle",title,Rect2(420,58,598,44),28)
		var serif=SystemFont.new();serif.font_names=PackedStringArray(["Times New Roman","Times","serif"]);name_label.add_theme_font_override("font",serif)
	var body=RichTextLabel.new();body.name="MissionBriefing";body.position=Vector2(390,52) if journal else Vector2(420,118)
	body.size=Vector2(494,174) if journal else Vector2(598,202);body.bbcode_enabled=false;body.fit_content=false
	body.add_theme_font_override("normal_font",font);body.add_theme_font_size_override("normal_font_size",18);body.text=briefing;detail.add_child(body)
	button_at("CloseMissions","Done" if journal else "Leave",Rect2(514,252,236,44) if journal else Rect2(460,344,236,44),func():game.set_mode(game.missions.return_mode))
	var action: Button
	if journal:
		action=button_at("AbortCourier" if entry.get("courier",false) else "AbortMission%d" % int(entry.get("id",-1)),"Abort Mission",Rect2(72,252,236,44),func():
			if entry.get("courier",false): game.pilot.mission={};game.missions.selected_courier=false;game.save_game(false);game.hud.rebuild_modal()
			else: game.missions.abort(entry))
		action.disabled=entry.is_empty()
	else:
		action=button_at("AcceptCourier" if entry.get("courier",false) else "AcceptMission%d" % int(entry.get("id",-1)),"Accept Mission",Rect2(712,344,236,44),func():
			if entry.get("courier",false): game.accept_job()
			else: game.missions.accept(entry))
		var cargo: int=5 if entry.get("courier",false) else int(entry.get("qty",0))
		action.disabled=entry.is_empty() or game.pilot.cargo_used()+cargo>game.pilot.cargo_capacity() or (not entry.get("courier",false) and game.pilot.campaign.active.size()>=8)
		if action.disabled and not entry.is_empty(): action.tooltip_text="Not enough cargo space or mission slots."
	mission_list.tooltip_text="Select a mission to read its briefing. %s shows its destination on the map." % game.controls.caption("map")
	canvas=base

func open_map() -> void:
	if selected_index<0: return
	var entry: Dictionary=entries[selected_index]
	if not entry.get("courier",false): game.open_mission_map(entry,not journal);return
	var target: Dictionary=game.pilot.mission if journal else game.courier_destination()
	var id: int=int(target.system);game.set_mode("map");game.map_selected=id;game.map_preview_system=-1 if journal else id
	var f: Dictionary=game.catalog.system(id).fields;game.map_center=Vector2(f.xPos,f.yPos);game.hud.rebuild_modal()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and game.controls.remapped(event).physical_keycode==KEY_M:
		open_map();get_viewport().set_input_as_handled()
