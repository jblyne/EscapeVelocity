extends "res://scripts/classic_port.gd"
# Original manual PICT 2012 (offers) and 2013 (active journal).
const Comparison=preload("res://scripts/mission_comparison.gd")
var nearest_first: bool=false
var original_entries: Array=[]
var comparisons: Array=[]
var nearest: int=-1
var sort_button: Button
var layout=Vector2(1040,412)
var entries: Array=[]
var mission_list: ItemList
var detail: Control
var selected_index: int=-1
var journal: bool=false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
	font=preload("res://scripts/classic_text.gd").body()
	journal=game.missions.channel==2 or game.missions.return_mode=="flight"
	if journal: game.missions.channel=2;layout=Vector2(904,316)
	canvas=Control.new();canvas.size=layout;add_child(canvas);panel(Rect2(Vector2.ZERO,layout))
	var heading: String="Currently active missions:" if journal else "Eligible jobs at this spaceport bar:" if game.missions.channel==1 else "The following missions are available here:"
	label_at("MissionHeading",heading,Rect2(20,14,700,28),18)
	if journal: label_at("MissionDate","Day %d" % game.pilot.campaign.day,Rect2(758,14,128,28),16,Color("999999"))
	entries=game.pilot.campaign.active.duplicate() if journal else game.missions.offers(game.docked_id,game.missions.channel)
	if journal and not game.pilot.mission.is_empty(): entries.append({"courier":true})
	elif not journal and game.missions.channel==0 and game.pilot.mission.is_empty() and not game.courier_destination().is_empty(): entries.append({"courier":true})
	original_entries=entries.duplicate()
	if not journal:
		sort_button=button_at("SortNearest","Sort: nearest",Rect2(802,12,216,32),sort_nearest)
	mission_list=ItemList.new();mission_list.name="MissionList";mission_list.position=Vector2(18,48 if journal else 58)
	mission_list.size=Vector2(352,172) if journal else Vector2(384,292);mission_list.allow_reselect=true
	mission_list.add_theme_font_override("font",font);mission_list.add_theme_font_size_override("font_size",18 if journal else 16)
	var normal=StyleBoxFlat.new();normal.bg_color=Color.BLACK;normal.border_color=Color("777777");normal.set_border_width_all(1)
	mission_list.add_theme_stylebox_override("panel",normal)
	var green=StyleBoxFlat.new();green.bg_color=Color("087600")
	for state in ["selected","selected_focus"]: mission_list.add_theme_stylebox_override(state,green)
	mission_list.add_theme_color_override("font_selected_color",Color.WHITE);mission_list.add_theme_color_override("font_color",Color.WHITE)
	fill_list()
	canvas.add_child(mission_list)
	mission_list.item_selected.connect(func(index):game.sound("ui_select");select_entry(index))
	if selected_index<0 and not entries.is_empty() and (journal or game.missions.last_report.is_empty()): selected_index=0
	if selected_index>=0:
		mission_list.select(selected_index);mission_list.ensure_current_is_visible();select_entry(selected_index,false)
	else: show_details()
	resized.connect(fit);fit()

func fill_list() -> void:
	comparisons.clear();nearest=-1
	for entry in entries:
		var info: Dictionary=Comparison.info(game,entry,journal)
		comparisons.append(info)
		if info.jumps>=0 and (nearest<0 or info.jumps<nearest): nearest=info.jumps
	mission_list.clear();selected_index=-1
	for i in entries.size():
		var entry: Dictionary=entries[i];var info: Dictionary=comparisons[i]
		var name_text: String=courier_title() if entry.get("courier",false) else game.missions.title(entry)
		var closest: bool=not journal and nearest>=0 and info.jumps==nearest
		var row: String=name_text
		if not journal: row=("★ " if closest else "")+Comparison.distance_text(info)+" · "+name_text
		if journal and not entry.get("courier",false) and not game.missions.return_for_payment(entry).is_empty(): row=("RETURN FOR PAYMENT · " if int(game.catalog.field("missions",int(entry.id),"PayVal"))>0 else "RETURN TO REPORT · ")+row
		mission_list.add_item(row)
		mission_list.set_item_tooltip(i,name_text+"\nNext objective: "+info.location+" · "+Comparison.distance_text(info)+"\n"+Comparison.terms(info))
		if closest: mission_list.set_item_custom_fg_color(i,Color("e4d89a"))
		if (entry.get("courier",false) and game.missions.selected_courier) or (not entry.get("courier",false) and entry==game.missions.selected) or (journal and ((entry.get("courier",false) and game.missions.tracked_id==-2) or (not entry.get("courier",false) and int(entry.id)==game.missions.tracked_id))): selected_index=i

func sort_nearest() -> void:
	nearest_first=not nearest_first
	var selected: Dictionary=entries[selected_index] if selected_index>=0 else {}
	entries=original_entries.duplicate()
	if nearest_first:
		entries.sort_custom(func(a,b):
			var da: int=Comparison.info(game,a,journal).jumps;var db: int=Comparison.info(game,b,journal).jumps
			if da<0: da=2147483647
			if db<0: db=2147483647
			return original_entries.find(a)<original_entries.find(b) if da==db else da<db)
	fill_list();selected_index=entries.find(selected)
	if selected_index>=0: mission_list.select(selected_index);mission_list.ensure_current_is_visible()
	sort_button.text="Sort: original" if nearest_first else "Sort: nearest"
	show_details()

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
	if journal: game.missions.tracked_id=-2 if entry.get("courier",false) else int(entry.id)
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
			briefing+="\n\n"+game.missions.reward_summary(entry)
			var commitments: String=game.missions.commitment_notes(entry)
			if not commitments.is_empty(): briefing+="\n"+commitments
			if journal: briefing="NEXT: "+game.missions.next_objective(entry)+"\n\n"+briefing
			if int(entry.deadline)>=0: briefing+="\n\nDeadline: day %d." % int(entry.deadline)
	elif not game.missions.last_report.is_empty(): title="Mission report";briefing=game.missions.last_report
	else:
		briefing="No active missions." if journal else "No missions are available here today."
		if not journal and game.missions.channel==1:
			briefing="No bar offers match your standing and story progress at this port.\n\nRecruitment starts at neutral standing: visit a Rebel port for Rebel Parcels, or a Confederation port for Confed Documents. Later jobs unlock after completing their introductions.\n\nThis list shows all eligible local jobs. Spontaneous bar approaches still vary between visits."
	if not journal:
		var name_label=label_at("MissionTitle",title,Rect2(420,58,598,44),28)
		var serif=SystemFont.new();serif.font_names=PackedStringArray(["Times New Roman","Times","serif"]);name_label.add_theme_font_override("font",serif)
	if not journal and not entry.is_empty():
		var info: Dictionary=comparisons[selected_index]
		var nearest_note: String=" · CLOSEST" if info.jumps>=0 and info.jumps==nearest else ""
		var distance=label_at("MissionDistance",Comparison.distance_text(info)+" to "+info.location+nearest_note,Rect2(420,110,598,28),16,Color("e4d89a"))
		distance.clip_text=true;distance.tooltip_text="Shortest connected route to the next objective; return trips or later stages can add jumps."
		var terms=label_at("MissionTerms",Comparison.terms(info),Rect2(420,140,598,26),15,Color("bbbbbb"))
		terms.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;terms.tooltip_text=Comparison.terms(info)
		if info.cargo>info.free:
			label_at("MissionCargoWarning","Needs %d t; only %d t free" % [info.cargo,info.free],Rect2(420,166,598,22),14,Color("ff9c83"))
	var body=RichTextLabel.new();body.name="MissionBriefing";body.position=Vector2(390,52) if journal else Vector2(420,194)
	body.size=Vector2(494,174) if journal else Vector2(598,136);body.bbcode_enabled=false;body.fit_content=false
	body.add_theme_font_override("normal_font",font);body.add_theme_font_size_override("normal_font_size",18);body.text=briefing;detail.add_child(body)
	button_at("CloseMissions","Done" if journal else "Leave",Rect2(514,252,236,44) if journal else Rect2(460,344,236,44),func():game.set_mode(game.missions.return_mode))
	var action: Button
	if journal:
		action=button_at("AbortCourier" if entry.get("courier",false) else "AbortMission%d" % int(entry.get("id",-1)),"Abort Mission",Rect2(72,252,236,44),func():
			if entry.get("courier",false): game.pilot.mission={};game.missions.selected_courier=false;game.save_game(false);game.hud.rebuild_modal()
			else: game.missions.abort(entry))
		action.disabled=entry.is_empty() or (not entry.get("courier",false) and not game.missions.abort_reason(entry).is_empty())
		if action.disabled and not entry.is_empty():
			action.text="Cannot Abort";action.tooltip_text=game.missions.abort_reason(entry)
	else:
		action=button_at("AcceptCourier" if entry.get("courier",false) else "AcceptMission%d" % int(entry.get("id",-1)),"Accept Mission",Rect2(712,344,236,44),func():
			if entry.get("courier",false): game.accept_job()
			else: game.missions.accept(entry))
		var cargo: int=5 if entry.get("courier",false) else int(entry.get("qty",0))
		action.disabled=entry.is_empty() or game.pilot.cargo_used()+cargo>game.pilot.cargo_capacity() or (not entry.get("courier",false) and game.pilot.campaign.active.size()>=8)
		if action.disabled and not entry.is_empty(): action.tooltip_text="Not enough cargo space or mission slots."
	mission_list.tooltip_text=("Select an active mission to track its next objective on the flight screen. " if journal else "")+"Jump counts show distance to the next objective; later stages may add travel. %s shows the destination on the map." % game.controls.caption("map")
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
