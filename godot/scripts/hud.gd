extends CanvasLayer

const OutfitArt=preload("res://scripts/outfit_art.gd")
const MapView=preload("res://scripts/map_view.gd")
const ClassicFlightPanel=preload("res://scripts/classic_flight_panel.gd")
const Instruments=preload("res://scripts/instruments.gd")
const TargetPanel=preload("res://scripts/target_panel.gd")
const TitleMenu=preload("res://scripts/title_menu.gd")
const INK=Color("dddddd")
const MUTED=Color("aaaaaa")
const ACCENT=Color("dddddd")
var game
var autopilot_indicator: PanelContainer
var autopilot_route: Label
var achievement_toast: Control
var achievement_tween: Tween
var port_page: String="landing"
var market_good: int=0
var hector_banner: Label
var outfitter_scroll: int = 0
var selected_outfit: int = 128
var root: Control
var modal_root: Control
var modal_tween: Tween
var modal_outgoing: Control
var modal_mode: String=""
var modal_generation: int=0
var system_label: Label
var territory: Label
var ship_status: Label
var stats: Label
var destination_label: Label
var log_label: Label
var mission_label: Label
var shields: ProgressBar
var armor: ProgressBar
var fuel: ProgressBar
var jump_button: Button
var jump_status: Label
var landing_status: Label
var weapon_status: Label
var cheat_status: Label
var weapons_toggle: CheckBox
var fuel_toggle: CheckBox
var invincibility_toggle: CheckBox
var deflection_toggle: CheckBox
var weapon_picker: OptionButton
var compact_target: Label
var flight_panel: Control
var mission_failure_label: Label
var combat_return_label: Label
var hunter_announcement: Control
var hunter_tribute_label: Label
var flight_messages: VBoxContainer
var target_panel

func _ready() -> void:
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme=Theme.new()
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
	theme.default_font=font
	theme.default_font_size=15
	for button_type in ["Button","OptionButton","CheckBox","CheckButton"]:
		theme.set_font("font",button_type,preload("res://assets/fonts/EVOriginal.ttf"))
	theme.set_color("font_color","Label",INK)
	root.theme=theme
	# Detailed backing readouts are shared by the information screen and tests.
	var hidden=VBoxContainer.new();hidden.hide();root.add_child(hidden)
	system_label=label(hidden,"",22)
	territory=label(hidden,"",10)
	ship_status=label(hidden,"",12)
	shields=meter(hidden,"Shield",ACCENT)
	armor=meter(hidden,"Armor",ACCENT)
	fuel=meter(hidden,"Fuel",ACCENT)
	destination_label=label(hidden,"",17)
	jump_button=button(hidden,"Jump",game.start_jump)
	jump_status=label(hidden,"",11)
	weapon_status=label(hidden,"",13)
	compact_target=label(hidden,"",12)
	stats=label(hidden,"",13,MUTED)
	cheat_status=label(hidden,"",11,Color("e7c993"))
	mission_label=label(hidden,"",16,Color("e7c993"))
	flight_messages=VBoxContainer.new()
	var message_theme=Theme.new()
	message_theme.default_font=preload("res://assets/fonts/ChicagoFLFRegular.ttf")
	flight_messages.theme=message_theme
	flight_messages.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	flight_messages.offset_left=16;flight_messages.offset_right=-300
	flight_messages.offset_top=-64;flight_messages.offset_bottom=-14
	root.add_child(flight_messages)
	hunter_tribute_label=label(flight_messages,"",15,Color("a7ef80"));hunter_tribute_label.name="HunterTributeAlert"
	hunter_tribute_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mission_failure_label=label(flight_messages,"",15,Color("ffb174"));mission_failure_label.name="MissionFailureAlert"
	mission_failure_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	combat_return_label=label(flight_messages,"",15,Color("e4d89a"));combat_return_label.name="CombatReturnStatus"
	combat_return_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	landing_status=label(flight_messages,"",13,Color("b7bcb5"))
	landing_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	log_label=label(flight_messages,"",13,Color("b7bcb5"))
	log_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	autopilot_indicator=PanelContainer.new();autopilot_indicator.name="AutopilotIndicator"
	autopilot_indicator.position=Vector2(16,16);autopilot_indicator.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var indicator_style=StyleBoxFlat.new();indicator_style.bg_color=Color.TRANSPARENT;indicator_style.set_border_width_all(0)
	indicator_style.set_content_margin_all(10);autopilot_indicator.add_theme_stylebox_override("panel",indicator_style)
	add_child(autopilot_indicator)
	var activity=VBoxContainer.new();activity.mouse_filter=Control.MOUSE_FILTER_IGNORE;activity.add_theme_constant_override("separation",4);autopilot_indicator.add_child(activity)
	label(activity,"● AUTOPILOT ON · A cancels",13,Color("8ed47c"))
	autopilot_route=label(activity,"",16);autopilot_route.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	autopilot_indicator.hide()
	var instruments=Instruments.new();instruments.game=game;root.add_child(instruments)
	target_panel=TargetPanel.new();target_panel.game=game;root.add_child(target_panel)
	target_panel.hide()
	flight_panel=ClassicFlightPanel.new();flight_panel.game=game;root.add_child(flight_panel)
	hunter_announcement=preload("res://scripts/hunter_announcement.gd").new();hunter_announcement.game=game;root.add_child(hunter_announcement)
	var lock_overlay=preload("res://scripts/maverick_lock_overlay.gd").new();lock_overlay.game=game;root.add_child(lock_overlay)
	hector_banner=Label.new()
	hector_banner.name="HectorBroadcast"
	hector_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hector_banner.offset_left=-300
	hector_banner.offset_right=300
	hector_banner.offset_top=106
	hector_banner.offset_bottom=180
	hector_banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hector_banner.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hector_banner.add_theme_font_size_override("font_size",19)
	hector_banner.add_theme_color_override("font_color",Color("ffd084"))
	hector_banner.add_theme_color_override("font_outline_color",Color("071018"))
	hector_banner.add_theme_constant_override("outline_size",6)
	hector_banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hector_banner.text="CAP'N HECTOR · INCOMING TRANSMISSION\n"+game.Hector.REMINDER
	hector_banner.hide()
	root.add_child(hector_banner)
	var live_appeal=preload("res://scripts/live_appeal.gd").new();live_appeal.game=game;flight_messages.add_child(live_appeal)
	modal_root=Control.new()
	modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(modal_root)

func panel_style(color: Color=Color.BLACK) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=color
	s.border_color=Color("888888")
	s.set_border_width_all(2)
	s.set_corner_radius_all(0)
	s.content_margin_left=24;s.content_margin_right=24
	s.content_margin_top=18;s.content_margin_bottom=18
	return s

func label(parent: Node, text: String, font_size: int=15, color: Color=INK) -> Label:
	var n=Label.new()
	n.text=text
	n.add_theme_font_size_override("font_size",font_size)
	n.add_theme_color_override("font_color",color)
	parent.add_child(n)
	return n

func button(parent: Node, text: String, action: Callable) -> Button:
	var b=Button.new()
	b.text=text
	b.focus_mode=Control.FOCUS_NONE
	b.custom_minimum_size=Vector2(0,36)
	preload("res://scripts/classic_port.gd").style_classic_button(b)
	b.add_theme_color_override("font_disabled_color",Color("aaaaaa"))
	b.pressed.connect(func():game.sound("menu_click");action.call())
	parent.add_child(b)
	return b

func spacer(parent: Node, height: float) -> void:
	var n=Control.new();n.custom_minimum_size.y=height;parent.add_child(n)

func meter(parent: Node, text: String, color: Color) -> ProgressBar:
	label(parent,text,10,MUTED)
	var b=ProgressBar.new()
	b.custom_minimum_size=Vector2(190,5)
	b.show_percentage=false
	var bg=StyleBoxFlat.new();bg.bg_color=Color("333333")
	var fg=StyleBoxFlat.new();fg.bg_color=color
	b.add_theme_stylebox_override("background",bg)
	b.add_theme_stylebox_override("fill",fg)
	parent.add_child(b)
	spacer(parent,9)
	return b

func refresh_autopilot_indicator() -> void:
	autopilot_indicator.visible=game.autopilot.active() and game.mode not in ["title","intro","dead","rescue","ejecting","autopilot"]
	if not autopilot_indicator.visible: return
	var job: Dictionary=game.autopilot.job
	var caption: String=str(job.name)
	if job.kind=="trade":
		caption+=" · %s ↔ %s" % [game.catalog.record("objects",int(job.low)).name,game.catalog.record("objects",int(job.high)).name]
	else:
		var target: int=game.autopilot.mission_target(job)
		if target>=0: caption+=" → "+str(game.catalog.record("objects",target).get("name","Unknown"))
	var width: float=maxf(220,minf(560,root.size.x-flight_panel.panel_width()-48))
	autopilot_indicator.size.x=width
	autopilot_route.custom_minimum_size.x=width-20
	autopilot_route.text=caption
	autopilot_indicator.reset_size()

func _process(_dt: float) -> void:
	refresh_autopilot_indicator()
	target_panel.refresh()
	target_panel.visible=game.mode=="info"
	flight_panel.visible=game.mode!="title"
	flight_messages.visible=game.mode=="flight"
	flight_messages.offset_right=-flight_panel.panel_width()-24
	flight_messages.offset_top=-maxf(64,flight_messages.get_combined_minimum_size().y+14)
	var contact: Dictionary=game.selected_contact()
	compact_target.text="Target: none · Tab" if contact.is_empty() else "Target: "+str(contact.name)

	var pilot=game.pilot
	system_label.text=game.catalog.system(pilot.system_id).name.to_upper()
	territory.text=game.catalog.government(pilot.system_id).to_upper()
	ship_status.text="%03d  /  %d  SPEED" % [game.velocity.length(),int(pilot.flight_fields(game.catalog.record("ships",pilot.ship_id).fields).Speed)]
	if game.hyperdrive.phase=="accelerating" or not game.chain_route.is_empty(): ship_status.text="%04d  HYPER SPEED" % game.velocity.length()
	shields.value=pilot.shield/pilot.max_shield()*100
	armor.value=pilot.armor/maxf(1,pilot.max_armor())*100
	fuel.value=100 if pilot.cheat_infinite_fuel else pilot.fuel/game.pilot.fuel_capacity()*100
	stats.text="%s credits\n%d / %d t cargo\n%d jumps available" % [commas(pilot.credits),pilot.cargo_used(),pilot.cargo_capacity(),int(pilot.fuel/100)]
	if pilot.cheat_infinite_fuel:
		stats.text="%s credits\n%d / %d t cargo\n∞ jumps · infinite fuel" % [commas(pilot.credits),pilot.cargo_used(),pilot.cargo_capacity()]
	weapon_status.text=game.arsenal.weapon_name(pilot.selected_weapon)
	var ammo_id: int = game.outfitter.ammo_id(pilot.selected_weapon)
	if ammo_id >= 0 and not pilot.cheat_all_weapons: weapon_status.text += " · %d rounds" % game.outfitter.count(ammo_id)
	weapon_status.tooltip_text=("%s fires primary guns" if game.controls.classic_fire else "%s fires selected weapon") % game.controls.caption("fire")+" · %s fires secondary · %s safety" % [game.controls.caption("secondary_fire"),game.controls.caption("weapon_safety")]
	var active: Array=[]
	if pilot.cheat_all_weapons: active.append("WEAPONS")
	if pilot.cheat_infinite_fuel: active.append("FUEL")
	if pilot.cheat_chain_jump: active.append("CHAIN JUMP")
	if pilot.cheat_invincibility: active.append("INVINCIBLE")
	if pilot.cheat_deflection: active.append("DEFLECTION")
	cheat_status.text=("CLOAK ACTIVE · weapons ready" if game.pilot.cheat_cloak else "CLOAK ACTIVE · weapons offline") if game.cloak.active else ("CHEATS · "+" + ".join(active) if not active.is_empty() else "")
	destination_label.text=game.catalog.system(game.destination).get("name","No route") if game.destination>=0 else "No route"
	var jump_reason: String=game.jump_block_reason()
	jump_button.text="Cancel  J" if game.hyperdrive.active() or not game.chain_route.is_empty() else "Jump  J"
	jump_button.disabled=game.mode!="flight" or (not game.hyperdrive.active() and game.chain_route.is_empty() and not jump_reason.is_empty())
	jump_status.text=game.hyperdrive.status() if game.hyperdrive.active() else (jump_reason if not jump_reason.is_empty() else "Clear to jump")
	landing_status.text=""
	if game.mode=="flight" and not game.hyperdrive.active() and game.chain_route.is_empty():
		landing_status.tooltip_text=game.landing_guidance()
	if game.hyperdrive.active(): landing_status.text=game.hyperdrive.status()
	hector_banner.visible=game.mode=="flight" and game.hector.banner_time>0
	hunter_tribute_label.text=game.world_activity.hunter_alert
	hunter_tribute_label.visible=game.world_activity.hunter_alert_seconds>0 and not game.world_activity.hunter_alert.begins_with("HUNTER DEFEATED")
	mission_failure_label.text=game.missions.flight_alert
	mission_failure_label.visible=game.missions.flight_alert_seconds>0
	combat_return_label.text=game.missions.tracked_objective()
	combat_return_label.visible=not combat_return_label.text.is_empty()
	log_label.text="\n".join(game.messages.slice(0,1))
	if not game.chain_route.is_empty():
		mission_label.text="CHAIN HYPERJUMP   /   " + game.catalog.system(game.destination).name + " · J cancels"
	elif game.hyperdrive.active():
		mission_label.text="HYPERSPACE   /   " + game.hyperdrive.status().to_upper()
	elif not pilot.mission.is_empty():
		var obj=game.catalog.record("objects",int(pilot.mission.object))
		mission_label.text="COURIER   /   Deliver to %s · %s" % [obj.name,game.catalog.system(int(pilot.mission.system)).name]
	else:
		mission_label.text="%d ACTIVE MISSIONS · I for briefings" % pilot.campaign.active.size() if not pilot.campaign.active.is_empty() else "FREE FLIGHT   /   Visit mission computers and spaceport bars for work."

func commas(value: int) -> String:
	var text=str(value);var result=""
	for i in text.length():
		if i>0 and (text.length()-i)%3==0:result+=","
		result+=text[i]
	return result

func modal(width: int) -> VBoxContainer:
	var shade=ColorRect.new()
	shade.color=Color(0,0,0,.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(shade)
	var center=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_root.add_child(center)
	var panel=PanelContainer.new()
	panel.custom_minimum_size.x=width
	panel.add_theme_stylebox_override("panel",panel_style())
	center.add_child(panel)
	var col=VBoxContainer.new()
	col.add_theme_constant_override("separation",8)
	panel.add_child(col)
	return col

func disable_outgoing_input(node: Node) -> void:
	if node is Control:
		node.mouse_filter=Control.MOUSE_FILTER_IGNORE
		node.focus_mode=Control.FOCUS_NONE
		if node.has_focus(): node.release_focus()
	if node is BaseButton: node.shortcut=null
	for child in node.get_children(): disable_outgoing_input(child)

func begin_modal_motion() -> void:
	modal_generation+=1
	var changed: bool=modal_mode!=game.mode
	var entering: bool=changed or modal_root.get_child_count()==0
	if is_instance_valid(modal_tween): modal_tween.kill()
	if is_instance_valid(modal_outgoing):
		modal_outgoing.hide();modal_outgoing.queue_free()
	if changed and modal_mode not in ["title","intro"] and modal_root.get_child_count()>0:
		var outgoing=Control.new()
		outgoing.name="ClosingWindow"
		outgoing.mouse_filter=Control.MOUSE_FILTER_IGNORE
		root.add_child(outgoing)
		outgoing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		outgoing.pivot_offset=outgoing.size*.5
		outgoing.scale=modal_root.scale
		outgoing.modulate=modal_root.modulate
		for child in modal_root.get_children():
			modal_root.remove_child(child);outgoing.add_child(child)
			child.process_mode=Node.PROCESS_MODE_DISABLED
			disable_outgoing_input(child)
		modal_outgoing=outgoing
		var fade=outgoing.create_tween().set_parallel(true)
		fade.tween_property(outgoing,"modulate:a",0.0,.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade.tween_property(outgoing,"scale",Vector2.ONE*.985,.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade.chain().tween_callback(outgoing.queue_free)
	modal_mode=game.mode
	modal_root.scale=Vector2.ONE
	modal_root.modulate=Color.WHITE
	if entering and game.mode not in ["title","intro","flight","ejecting"]:
		modal_root.pivot_offset=modal_root.size*.5
		modal_root.scale=Vector2.ONE*.985
		modal_root.modulate.a=0
		finish_modal_motion.call_deferred(modal_generation)

func finish_modal_motion(generation: int) -> void:
	if generation!=modal_generation: return
	modal_root.pivot_offset=modal_root.size*.5
	modal_tween=modal_root.create_tween().set_parallel(true)
	modal_tween.tween_property(modal_root,"modulate:a",1.0,.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	modal_tween.tween_property(modal_root,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func rebuild_modal() -> void:
	if target_panel.get_parent()!=root:
		target_panel.reparent(root)
		target_panel.hide()
	var old_scroll = modal_root.find_child("OutfitterScroll",true,false)
	if old_scroll != null: outfitter_scroll = old_scroll.scroll_vertical
	begin_modal_motion()
	for child in modal_root.get_children():
		modal_root.remove_child(child)
		child.queue_free()
	if game.mode in ["flight","intro","ejecting"]: return
	if game.mode in ["eject_confirm","rescue"]:
		var col=modal(580)
		label(col,"ABANDON SHIP" if game.mode=="eject_confirm" else "ESCAPE POD · SIGNAL RECEIVED",24)
		label(col,"Rescue provides a replacement shuttle at Levo if it survives. Your ship, equipment, cargo and escort fleet are lost; active contracts fail. Recovery advances 30 days and resets legal records. Credits and completed story progress are retained.",16,MUTED).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		if game.mode=="eject_confirm":
			button(col,"Launch escape pod",game.ejection.begin).name="ConfirmEjection"
			button(col,"Stay aboard · Esc",func():game.set_mode("flight"))
		else:
			button(col,"Accept rescue",game.ejection.recover).name="AcceptRescue"
		return
	if game.mode=="autopilot":
		var picker=preload("res://scripts/classic_autopilot.gd").new();picker.game=game;modal_root.add_child(picker);return
	if game.mode=="achievements":
		var book=preload("res://scripts/classic_achievements.gd").new();book.game=game;modal_root.add_child(book);return
	if game.mode=="controls":
		var preferences=preload("res://scripts/control_preferences.gd").new();preferences.game=game;modal_root.add_child(preferences);return
	if game.mode=="news":
		build_news();return
	if game.mode=="world_comms":
		build_world_comms();return
	if game.mode=="info":
		build_info()
		return
	if game.mode=="title":
		var menu=TitleMenu.new()
		menu.game=game
		modal_root.add_child(menu)
		return
	if game.mode in ["comms", "boarding"]:
		build_communications()
		return
	if game.mode=="mission_offer":
		var offer_view=preload("res://scripts/classic_bar_approach.gd").new();offer_view.game=game;modal_root.add_child(offer_view);return
	if game.mode=="mission_report":
		build_mission_report()
		return
	if game.mode=="shipyard":
		build_shipyard()
		return
	if game.mode=="missions":
		build_missions()
		return
	if game.mode=="outfitter":
		build_outfitter()
		return
	if game.mode=="fleet":
		build_fleet()
		return
	if game.mode=="cheats":
		build_cheats()
		return
	if game.mode=="map":
		var screen=preload("res://scripts/map_screen.gd").new();screen.game=game;modal_root.add_child(screen)
		return
	if game.mode=="dock":
		build_dock()
		return
	if game.mode=="dead":
		# Let the initial fireball play before covering it with the recovery panel.
		if game.death_reveal_time>0: return
		var recovery=preload("res://scripts/classic_death_dialog.gd").new()
		recovery.game=game;modal_root.add_child(recovery)
		return
	var pause_menu=preload("res://scripts/classic_pause_menu.gd").new()
	pause_menu.game=game;modal_root.add_child(pause_menu)

func build_info() -> void:
	var col=modal(820)
	label(col,"SHIP INFORMATION",12,ACCENT)
	button(col,"Achievements & overall progress",game.open_achievements)
	label(col,str(game.catalog.record("ships",game.pilot.ship_id).name),24)
	label(col,system_label.text+" · "+territory.text+" · "+ship_status.text,13,MUTED)
	label(col,weapon_status.text+" · "+jump_status.text,13,MUTED)
	var recent=label(col,"\n".join(game.messages.slice(0,3)),12,MUTED);recent.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",28);col.add_child(row)
	var details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(details)
	label(details,stats.text,17)
	var status=label(details,cheat_status.text,13,Color("e7c993"));status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var mission=label(details,mission_label.text,15,ACCENT);mission.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var actions=GridContainer.new();actions.columns=2;actions.add_theme_constant_override("h_separation",10);actions.add_theme_constant_override("v_separation",8);details.add_child(actions)
	button(actions,"Mission journal · I",func():game.set_mode("flight");game.missions.open())
	button(actions,"Manage fleet · F",game.toggle_fleet_menu)
	button(actions,"Hail selected world · H",game.world_activity.open_contact)
	button(actions,"Galactic news & tribute",game.world_activity.open_news)
	button(actions,"Cloak · K",func():game.set_mode("flight");game.cloak.toggle())
	button(actions,"Cheats · C",game.toggle_cheat_menu)
	if game.pilot.outfit_count(154)>0: button(actions,"Abandon ship · Shift+X",game.ejection.request)
	button(actions,"Settings & controls",func():game.set_mode("pause"))
	for action in actions.get_children(): action.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	target_panel.reparent(row)
	target_panel.custom_minimum_size.x=270
	target_panel.show()
	button(col,"Return to flight · Esc",func():game.set_mode("flight"))

func build_mission_report() -> void:
	var screen=preload("res://scripts/classic_mission_report.gd").new();screen.game=game;modal_root.add_child(screen)

func classic_service():
	var screen=preload("res://scripts/classic_service.gd").new();screen.game=game;modal_root.add_child(screen)
	return screen

func build_fleet() -> void:
	var screen=preload("res://scripts/classic_fleet.gd").new();screen.game=game;modal_root.add_child(screen)

func build_communications() -> void:
	var comms = game.interactions
	var npc: Dictionary = comms.contact
	if not comms.live(npc):
		comms.close()
		return
	if game.mode=="comms":
		var classic=preload("res://scripts/classic_ship_comms.gd").new()
		classic.game=game;modal_root.add_child(classic)
		return
	var boarding: bool = game.mode == "boarding"
	var col = modal(660)
	label(col, "BOARDING PARTY" if boarding else "SHIP COMMUNICATIONS", 12, ACCENT)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	col.add_child(header)
	var identity = VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity)
	var name_label = label(identity, npc.name, 26)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(identity, game.Factions.name_of(game.catalog, npc.faction), 15, game.Factions.color_of(npc.faction))
	var status: String = "DISABLED" if npc.disabled else ("HOSTILE" if npc.hostile else "CHANNEL OPEN")
	label(identity, "%s  ·  Crew %d" % [status, game.catalog.field("ships", npc.id, "Crew")], 12, MUTED)
	target_panel.refresh()
	var portrait = TextureRect.new()
	portrait.texture = target_panel.preview_texture.texture
	portrait.custom_minimum_size = Vector2(160, 100)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(portrait)
	var message_scroll=ScrollContainer.new()
	message_scroll.custom_minimum_size=Vector2(600,180 if comms.page=="person_mission" else 74)
	col.add_child(message_scroll)
	var transmission = label(message_scroll, comms.response, 17, INK)
	if boarding and not comms.response.is_empty() and comms.response==game.missions.boarding_report(npc): transmission.text="Boarding party aboard. See the mission transfer below."
	transmission.name = "CommResponse"
	transmission.custom_minimum_size = Vector2(600, 74)
	transmission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if comms.page == "person_mission":
		button(col, "Accept contract", game.persons.accept_offer)
		button(col, "Decline", func(): comms.reply("Channel open."))
	elif boarding:
		if not game.persons.linked_offer(npc,true).is_empty(): button(col,"Investigate the vessel",game.persons.show_offer.bind(npc,true))
		label(col, "ABOARD THE TARGET", 11, ACCENT)
		var mission_report: String=game.missions.boarding_report(npc)
		if not mission_report.is_empty():
			var mission_cargo=label(col,mission_report,15,Color("b9ee9b"));mission_cargo.name="BoardingMissionCargo";mission_cargo.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(col, "%s credits   ·   %d t cargo   ·   %d fuel" % [commas(npc.credits), comms.cargo_total(npc), int(npc.fuel)], 16)
		var goods: Array = []
		for i in npc.cargo.size():
			if npc.cargo[i] > 0: goods.append("%s %d t" % [game.catalog.data.commodities[i].name, npc.cargo[i]])
		var manifest = label(col, " · ".join(goods) if not goods.is_empty() else "Cargo hold empty", 13, MUTED)
		manifest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label(col, "Fleet holds: %d / %d t  ·  Next transfer: %d%% self-destruct risk" % [game.fleet_service.total_cargo_used(), game.fleet_service.cargo_capacity(), roundi(comms.salvage_risk(npc.plunder_count) * 100)], 13, Color("e7c993"))
		var capture_reason: String = comms.capture_reason(npc)
		var capture = button(col, "Attempt capture  ·  %d%% chance" % roundi(comms.capture_chance(npc) * 100), comms.capture_ship)
		capture.name = "CaptureShip"
		capture.tooltip_text = capture_reason
		capture.disabled = not capture_reason.is_empty()
		if capture.disabled: label(col, capture_reason, 12, MUTED)
		var row = HBoxContainer.new()
		col.add_child(row)
		for kind in ["cargo", "credits", "fuel", "ammo"]:
			var action = button(row, "Take " + kind.capitalize(), comms.plunder.bind(kind))
			action.name = "Loot" + kind.capitalize()
			action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			action.tooltip_text = comms.loot_reason(kind)
			action.disabled = not action.tooltip_text.is_empty()
		label(col, "Ammunition is unlimited with your weapon cheat." if game.pilot.cheat_all_weapons else "Salvaged rounds require an installed matching launcher and free equipment space.", 13, MUTED)
		button(col, "Leave ship  ·  Esc", comms.close).name = "EndBoarding"
	elif comms.page == "refuel":
		var accept = button(col, "Request rendezvous  ·  %s credits on transfer" % commas(comms.refuel_price(npc)), comms.accept_refuel)
		accept.name = "AcceptRefuel"
		accept.disabled = game.pilot.credits < comms.refuel_price(npc)
		if accept.disabled: label(col, "Insufficient credits for this transfer.", 13, Color("e7c993"))
		button(col, "Back", func(): comms.reply("Channel open."))
	elif comms.page == "bribe":
		var pay = button(col, "Pay %s credits" % commas(comms.bribe_price(npc)), comms.pay_bribe)
		pay.name = "PayBribe"
		pay.disabled = game.pilot.credits < comms.bribe_price(npc)
		if pay.disabled: label(col, "Insufficient credits for this bribe.", 13, Color("e7c993"))
		button(col, "Back", func(): comms.reply("Channel open."))
	else:
		var row = HBoxContainer.new()
		col.add_child(row)
		if not game.persons.linked_offer(npc,false).is_empty(): button(col,"Discuss a contract",game.persons.show_offer.bind(npc,false))
		button(row, "Greetings", comms.greetings).name = "Greetings"
		button(row, "Request Assistance", comms.request_assistance).name = "RequestAssistance"
		button(row, "Offer Bribe", comms.offer_bribe).name = "OfferBribe"
		var board_button = button(col, "Attempt to board  ·  B", comms.board)
		board_button.name = "AttemptBoard"
		var guidance: String = comms.boarding_reason(npc)
		var hint = label(col, guidance if not guidance.is_empty() else "Position and motion matched. Ready to board.", 13, MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not boarding: button(col, "End Communication  ·  Y / Esc", comms.close).name = "EndCommunication"
	label(col, "Flight paused while this channel is open.", 11, MUTED)

func build_cheats() -> void:
	var frame=modal(680)
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size.y=minf(650,get_viewport().get_visible_rect().size.y-140)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	var col=VBoxContainer.new()
	col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",8)
	scroll.add_child(col)
	label(col,"DEBUGGING",12,ACCENT)
	label(col,"Cheat menu",30)
	label(col,"Changes save with your pilot. The game is paused while this menu is open.",14,MUTED)
	spacer(col,10)
	var death_star_toggle=CheckBox.new();death_star_toggle.name="WorldKillerToggle"
	death_star_toggle.text="Death Star · world-killer";death_star_toggle.custom_minimum_size.y=42
	death_star_toggle.button_pressed=game.pilot.cheat_world_killer
	death_star_toggle.toggled.connect(func(enabled):
		game.pilot.cheat_world_killer=enabled
		if not enabled: game.world_killer.launch_preview=false
		game.save_game(false))
	col.add_child(death_star_toggle)
	weapons_toggle=CheckBox.new()
	weapons_toggle.text="All weapons + infinite ammo"
	weapons_toggle.name="AllWeaponsToggle"
	weapons_toggle.custom_minimum_size.y=42
	weapons_toggle.button_pressed=game.pilot.cheat_all_weapons
	weapons_toggle.toggled.connect(game.set_weapon_cheat)
	col.add_child(weapons_toggle)
	label(col,"Unlock all 26 weapons and fighter bays. Off restores your normal lasers.",14,MUTED)
	fuel_toggle=CheckBox.new()
	fuel_toggle.text="Infinite fuel"
	fuel_toggle.name="InfiniteFuelToggle"
	fuel_toggle.custom_minimum_size.y=42
	fuel_toggle.button_pressed=game.pilot.cheat_infinite_fuel
	fuel_toggle.toggled.connect(game.set_fuel_cheat)
	col.add_child(fuel_toggle)
	label(col,"Jump even with an empty tank. Off resumes using your stored fuel.",14,MUTED)
	var chain_toggle = CheckBox.new()
	chain_toggle.name = "ChainJumpToggle"
	chain_toggle.text = "Chain hyperjump · any system · 1 second per stop · no fuel"
	chain_toggle.custom_minimum_size.y = 42
	chain_toggle.button_pressed = game.pilot.cheat_chain_jump
	chain_toggle.toggled.connect(game.set_chain_jump_cheat)
	col.add_child(chain_toggle)
	invincibility_toggle=CheckBox.new()
	invincibility_toggle.text="Invincibility"
	invincibility_toggle.name="InvincibilityToggle"
	invincibility_toggle.custom_minimum_size.y=42
	invincibility_toggle.button_pressed=game.pilot.cheat_invincibility
	invincibility_toggle.toggled.connect(game.set_invincibility_cheat)
	col.add_child(invincibility_toggle)
	label(col,"Prevent all shield and armor damage. Off restores normal damage.",14,MUTED)
	deflection_toggle=CheckBox.new()
	deflection_toggle.text="Deflection"
	deflection_toggle.name="DeflectionToggle"
	deflection_toggle.custom_minimum_size.y=42
	deflection_toggle.button_pressed=game.pilot.cheat_deflection
	deflection_toggle.toggled.connect(game.set_deflection_cheat)
	col.add_child(deflection_toggle)
	label(col,"Reflect incoming fire back at the ship that fired it.",14,MUTED)
	spacer(col,12)
	label(col,"SELECT WEAPON",11,ACCENT)
	weapon_picker=OptionButton.new()
	weapon_picker.name="WeaponPicker"
	weapon_picker.custom_minimum_size=Vector2(0,40)
	weapon_picker.get_popup().max_size=Vector2i(0,420)
	for id in game.arsenal.available_ids():
		weapon_picker.add_item(game.arsenal.weapon_name(id),id)
	weapon_picker.select(weapon_picker.get_item_index(game.pilot.selected_weapon))
	weapon_picker.disabled=game.arsenal.available_ids().size() <= 1
	weapon_picker.item_selected.connect(func(index:int):game.select_weapon(weapon_picker.get_item_id(index)))
	col.add_child(weapon_picker)
	var hint=label(col,game.arsenal.description(game.pilot.selected_weapon),14,MUTED)
	hint.custom_minimum_size=Vector2(620,48)
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label(col,"%s primary · %s secondary · %s safety · Tab target" % [game.controls.caption("fire"),game.controls.caption("secondary_fire"),game.controls.caption("weapon_safety")],14,INK)
	spacer(col,8)
	var cloak_toggle=CheckBox.new()
	cloak_toggle.name="CloakingDeviceToggle"
	cloak_toggle.text="Cloaking device available · K to cloak / decloak"
	cloak_toggle.button_pressed=game.pilot.cheat_cloak
	cloak_toggle.toggled.connect(func(enabled):
		game.pilot.cheat_cloak=enabled
		if not game.cloak.available(): game.cloak.set_active(false,true)
		game.save_game(false))
	col.add_child(cloak_toggle)
	label(col,"Allows cloaking without the mission reward and firing while cloaked. Still consumes shields and fuel.",13,MUTED)
	label(col,"SPAWN A SHIP",11,ACCENT)
	var row=HBoxContainer.new();col.add_child(row)
	var ship_picker=OptionButton.new();ship_picker.name="ShipPicker"
	ship_picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ship_picker.custom_minimum_size.y=36
	ship_picker.get_popup().max_size=Vector2i(0,350)
	var ship_ids=game.catalog.data.ships.keys()
	ship_ids.sort_custom(func(a,b):return int(a)<int(b))
	for id in ship_ids:
		var ship=game.catalog.record("ships",int(id))
		ship_picker.add_item(ship.name+(" (alternate)" if int(id)==152 else ""),int(id))
	row.add_child(ship_picker)
	var faction_picker=OptionButton.new();faction_picker.name="FactionPicker"
	faction_picker.custom_minimum_size.y=36
	faction_picker.get_popup().max_size=Vector2i(0,350)
	faction_picker.add_item("Ship's usual faction",0)
	faction_picker.add_item("Independent",1)
	var factions: Array=[-2,-1]
	var faction_ids=game.catalog.data.governments.keys()
	faction_ids.sort_custom(func(a,b):return int(a)<int(b))
	for id in faction_ids:
		factions.append(int(id))
		faction_picker.add_item(game.Factions.name_of(game.catalog,int(id)))
	row.add_child(faction_picker)
	var spawn_status=label(col,"All 27 ship records, including special encounter ships. Hostile factions can attack.",13,MUTED)
	spawn_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var spawn_button=button(row,"Spawn",func():
		var success=game.debug_spawn_ship(ship_picker.get_selected_id(),factions[faction_picker.selected])
		spawn_status.text=game.messages[0] if success else "Cannot spawn: the system may already have 32 contacts.")
	spawn_button.name="SpawnShip"
	label(col,"ORIGINAL NAMED CHARACTERS",11,ACCENT)
	var named_row=HBoxContainer.new();col.add_child(named_row)
	var named_picker=OptionButton.new();named_picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;named_picker.get_popup().max_size=Vector2i(0,350)
	var people: Array=game.catalog.data.persons.values();people.sort_custom(func(a,b):return a.name.naturalnocasecmp_to(b.name)<0)
	for person in people:
		var allowed: bool=game.persons.eligible(int(person.id)) if int(person.id)!=639 else not game.npcs.any(func(n):return n.get("hector",false))
		named_picker.add_item(person.name+(" · unavailable here" if not allowed else ""),int(person.id))
		named_picker.set_item_disabled(named_picker.item_count-1,not allowed)
	named_row.add_child(named_picker)
	button(named_row,"Spawn captain",func():
		var npc: Dictionary=game.persons.spawn(named_picker.get_selected_id())
		game.notify("This captain is unavailable here, already present, or the system is full." if npc.is_empty() else "Encounter: "+str(npc.name))
		if not npc.is_empty(): game.target_index=game.npcs.find(npc)
		rebuild_modal()).name="SpawnPerson"
	label(col,"Original location and story requirements apply. Spawned captains use their normal behavior.",13,MUTED)
	spacer(col,10)
	button(frame,"Done  ·  C / Esc",game.toggle_cheat_menu)

func build_outfitter() -> void:
	var screen=preload("res://scripts/classic_outfitter.gd").new();screen.game=game;modal_root.add_child(screen)

func build_dock() -> void:
	var port=preload("res://scripts/classic_gambling.gd").new() if port_page=="gambling" else preload("res://scripts/classic_port.gd").new();port.game=game;modal_root.add_child(port)

func build_missions() -> void:
	var screen=preload("res://scripts/classic_missions.gd").new();screen.game=game;modal_root.add_child(screen)

func build_shipyard() -> void:
	var screen=preload("res://scripts/classic_shipyard.gd").new();screen.game=game;modal_root.add_child(screen)

func build_news() -> void:
	var screen=classic_service()
	var col=screen.content
	label(col,"GALACTIC NEWS · DAY %d" % game.pilot.campaign.day,26)
	label(col,"Tribute income: %s credits / day" % commas(game.world_activity.daily_income()),16,ACCENT)
	var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
	var content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",18);scroll.add_child(content)
	for headline in game.world_activity.headlines(game.docked_id if game.world_activity.return_mode=="dock" else -1):
		var item=label(content,str(headline),16);item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if not game.pilot.world_state.dominated.is_empty():
		label(content,"TRIBUTE AGREEMENTS",13,ACCENT)
		for id in game.pilot.world_state.dominated: label(content,"%s · %s cr/day" % [game.catalog.record("objects",int(id)).name,commas(game.world_activity.tribute(int(id)))],15)
	button(col,"Back · Esc",func():game.set_mode(game.world_activity.return_mode))
	screen.restyle(col)

func style_world_comms(screen,col: Control) -> void:
	screen.restyle(screen.content)
	for action in col.find_children("*","Button",true,false):
		action.size_flags_horizontal=Control.SIZE_SHRINK_END
		action.custom_minimum_size.x=320

func build_world_comms() -> void:
	var service=game.world_activity
	var port: Dictionary=game.catalog.record("objects",service.contact_id)
	var screen=classic_service()
	label(screen.content,"Hailing "+port.name,22)
	var scroll=ScrollContainer.new();scroll.name="WorldCommsScroll"
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	screen.content.add_child(scroll)
	var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",12);scroll.add_child(col)
	button(screen.content,"Close channel",func():game.set_mode("flight")).name="CloseWorldChannel"
	var status=label(col,service.response,17);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var refusal: String=service.landing_reason(service.contact_id)
	var landing=label(col,("Mission delivery clearance available." if game.missions.grants_landing_clearance(service.contact_id) else "Landing clearance available.") if refusal.is_empty() else refusal,15,MUTED);landing.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if service.can_bribe_landing(service.contact_id):
		var cost: int=service.landing_bribe_price(service.contact_id)
		var bribe=button(col,"Bribe for landing clearance · %s cr" % commas(cost),service.pay_landing_bribe)
		bribe.name="BribeLanding";bribe.disabled=game.pilot.credits<cost or service.landing_officer(service.contact_id).refused
		bribe.tooltip_text="Clearance lasts for this system visit. Officials may refuse a bribe."
		var negotiate=button(col,"Negotiate a smaller fee",service.negotiate_landing_bribe)
		negotiate.name="NegotiateLandingBribe"
		negotiate.disabled=service.landing_officer(service.contact_id).negotiated or service.landing_officer(service.contact_id).refused
	var fear: Dictionary=service.fear(service.contact_id)
	if int(fear.score)>0:
		label(col,"Fear: %d / 100 · %s" % [fear.score,"Intimidated — landing restrictions waived" if fear.compliant else "Wary — authorities still enforce landing rules"],15).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var killer=game.world_killer
	if not killer.bomb().is_empty() and int(killer.bomb().id)==service.contact_id:
		label(col,"DEATH STAR · "+killer.clock(killer.bomb().remaining)+" · "+str(killer.bomb().phase).to_upper(),22,Color("ffad70"))
		label(col,"The countdown pauses while this channel is open. You can reconsider any time before detonation.",13,MUTED).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button(col,"Spare World",killer.spare).name="SpareWorld"
		if killer.bomb().plea_sent and int(killer.bomb().get("bribe_offer",0))>0:
			button(col,"Accept Bribe · %s cr" % commas(int(killer.bomb().bribe_offer)),killer.accept_bribe).name="AcceptWorldBribe"
		button(col,"Reject Appeal",killer.deny).name="DenyWorldAppeal"
		style_world_comms(screen,col)
		return
	if killer.launch_preview and game.pilot.cheat_world_killer:
		label(col,"EXPERIMENTAL WORLD-KILLER",13,Color("ffad70"))
		label(col,"Summons a Death Star through hyperspace and starts a two-minute countdown. It approaches the planet, stops with 20 seconds left, then charges eight converging beams into a superlaser. Destruction permanently ends this world's services, tribute and contracts.",15,MUTED).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var deploy=button(col,"Deploy world-killer",killer.deploy);deploy.name="DeployWorldKiller"
		deploy.disabled=not killer.reason(service.contact_id).is_empty()
		button(col,"Stand down",func():killer.launch_preview=false;service.response=killer.greeting(service.contact_id);rebuild_modal())
		style_world_comms(screen,col)
		return
	if game.pilot.cheat_world_killer:
		var threat=button(col,"Threaten with world-killer",killer.threaten);threat.name="ThreatenWorld"
		threat.tooltip_text=killer.reason(service.contact_id);threat.disabled=not threat.tooltip_text.is_empty()
		if threat.disabled: label(col,threat.tooltip_text,13,MUTED).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label(col,"Tribute: %s credits per day" % commas(service.tribute(service.contact_id)),17,ACCENT)
	if not service.siege.is_empty() and int(service.siege.port)==service.contact_id:
		label(col,"Defense fleet: %d active · %d awaiting launch" % [service.siege.pending,service.siege.left],16,ACCENT)
	if service.contact_id in game.pilot.world_state.dominated:
		button(col,"Release from tribute",service.release).name="ReleaseTribute"
	else:
		var counts: Vector2i=service.defense_counts(service.contact_id)
		var warning=label(col,"Demanding tribute damages your local reputation and launches the defense fleet (%d ships). Defeat its waves to conquer this world. Leaving the system or landing abandons the battle." % counts.x,15,MUTED);warning.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var demand=button(col,"Demand Tribute",service.demand);demand.name="DemandTribute"
		demand.tooltip_text=service.demand_reason(service.contact_id);demand.disabled=not demand.tooltip_text.is_empty()
		if demand.disabled: label(col,demand.tooltip_text,14,MUTED)
	style_world_comms(screen,col)

func show_achievement(unlocked: Array) -> void:
	if is_instance_valid(achievement_tween): achievement_tween.kill()
	if is_instance_valid(achievement_toast): achievement_toast.queue_free()
	achievement_toast=Panel.new();achievement_toast.name="AchievementToast";achievement_toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	achievement_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	achievement_toast.offset_left=-260;achievement_toast.offset_right=260;achievement_toast.offset_top=26;achievement_toast.offset_bottom=114
	var style=StyleBoxFlat.new();style.bg_color=Color(0,0,0,.94);style.border_color=Color("bda365");style.set_border_width_all(2)
	achievement_toast.add_theme_stylebox_override("panel",style);root.add_child(achievement_toast)
	var badge=preload("res://scripts/achievement_badge.gd").new();badge.position=Vector2(14,12);badge.size=Vector2(62,62);badge.unlocked=true;achievement_toast.add_child(badge)
	var heading=Label.new();heading.text="ACHIEVEMENT UNLOCKED";heading.position=Vector2(90,13);heading.add_theme_font_size_override("font_size",14);heading.add_theme_color_override("font_color",Color("e5c276"));achievement_toast.add_child(heading)
	var title=Label.new();title.text=str(unlocked[0].name)+( " + %d more" % (unlocked.size()-1) if unlocked.size()>1 else "");title.position=Vector2(90,39);title.size=Vector2(412,34);title.clip_text=true;title.add_theme_font_size_override("font_size",21);achievement_toast.add_child(title)
	achievement_toast.modulate.a=0
	achievement_tween=create_tween();achievement_tween.tween_property(achievement_toast,"modulate:a",1.0,.18)
	achievement_tween.tween_interval(3.5);achievement_tween.tween_property(achievement_toast,"modulate:a",0.0,.35)
	achievement_tween.tween_callback(achievement_toast.queue_free)
