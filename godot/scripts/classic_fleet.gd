extends "res://scripts/classic_port.gd"
const LAYOUT=Vector2(1080,650)
var contents: VBoxContainer

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 font=preload("res://scripts/classic_text.gd").body()
 canvas=Control.new();canvas.size=LAYOUT;add_child(canvas);panel(Rect2(Vector2.ZERO,LAYOUT))
 var service=game.fleet_service
 label_at("FleetHeading","YOUR FLEET · %d / %d" % [game.pilot.fleet.size(),service.LIMIT],Rect2(20,16,600,34),24)
 label_at("FleetCredits","Credits: "+game.hud.commas(game.pilot.credits),Rect2(680,18,380,30),18)
 label_at("EscortOrdersHeading","Escort orders",Rect2(20,68,148,32),18)
 for i in service.ORDERS.size():
  var command: String=service.ORDERS[i]
  button_at("FleetOrder"+command.capitalize(),command.capitalize(),Rect2(176+i*220,64,204,38),service.order.bind(command))
 label_at("FighterOrdersHeading","Fighter orders",Rect2(20,116,148,32),18)
 var commands: Array=["defend","attack","formation","hold"]
 for i in commands.size():
  var command: String=commands[i]
  button_at("FighterOrder"+command.capitalize(),command.capitalize(),Rect2(176+i*166,112,152,38),func():game.fighter_wing.order(command);game.set_mode("flight"))
 button_at("RecallFighters","Recall to bays",Rect2(840,112,220,38),func():game.arsenal.recall_fighters();game.set_mode("flight"))
 var deployed: int=game.escorts.filter(func(f):return not f.get("captured",false)).size()
 label_at("FighterCount","Fighters deployed: %d · Dock to refuel, repair and rearm." % deployed,Rect2(20,162,1040,28),17)
 label_at("FleetOrderHelp","Defend: nearby hostiles. Attack: selected contact. Hold: current position. Recall: return without firing.\nJumping resets order targets and hold positions.",Rect2(20,198,1040,44),16,Color("bbbbbb"))
 label_at("FleetListHeading","SHIPS & CAPTAINS" if game.fleet_return_mode=="dock" else "SHIPS IN YOUR FLEET",Rect2(20,248,1040,26),17)
 var scroll=ScrollContainer.new();scroll.name="FleetRosterScroll";scroll.position=Vector2(20,280);scroll.size=Vector2(1040,302);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;canvas.add_child(scroll)
 contents=VBoxContainer.new();contents.name="FleetRoster";contents.size_flags_horizontal=Control.SIZE_EXPAND_FILL;contents.add_theme_constant_override("separation",8);scroll.add_child(contents)
 var candidate: Dictionary=service.takeover_candidate
 if candidate in game.escorts and not service.record(candidate).is_empty():
  var section=card("FleetTransferConfirmation",154);var base=canvas;canvas=section
  label_at("FleetTransferWarning","Take command of %s? Your current hull and installed equipment will be abandoned. Cargo and credits transfer if they fit." % candidate.name,Rect2(12,10,976,76),18,Color("e7c993"))
  var confirm=button_at("ConfirmFlagshipTransfer","Confirm transfer",Rect2(12,104,300,38),func():service.takeover(candidate);service.takeover_candidate={})
  confirm.disabled=not service.takeover_reason(candidate).is_empty();confirm.tooltip_text=service.takeover_reason(candidate)
  button_at("CancelFlagshipTransfer","Cancel",Rect2(330,104,220,38),func():service.takeover_candidate={};game.hud.rebuild_modal());canvas=base
 for fighter in game.escorts:
  if fighter.get("captured",false): continue
  var remaining: int=maxi(0,int(game.fighter_wing.ENDURANCE-float(fighter.sortie_seconds)))
  var missiles: int=0;var guns: int=0
  for w in fighter.weapons:
   if int(w.ammo)>0: missiles+=int(w.ammo)
   if int(w.ammo)<0: guns+=int(w.count)
  var section=card("DeployedFighter%d" % game.escorts.find(fighter),76);var base=canvas;canvas=section
  label_at("FighterName",fighter.name+" · "+("Docking" if fighter.recalling else str(fighter.command).capitalize()),Rect2(12,8,976,28),18)
  label_at("FighterStatus","%d%% shields · %d guns / %d rounds · %d:%02d remaining" % [roundi(100*fighter.shield/maxf(1,fighter.shield_capacity)),guns,missiles,remaining/60,remaining%60],Rect2(12,40,976,26),16,Color("bbbbbb"));canvas=base
 for escort in game.escorts:
  var member: Dictionary=service.record(escort)
  if member.is_empty(): continue
  var index: int=game.escorts.find(escort)
  var section=card("FleetShip%d" % index,94);var base=canvas;canvas=section
  var title=label_at("FleetShipTitle","%s · %d%% · %s" % [escort.name,roundi(100*escort.health/escort.max_health),str(member.command).capitalize()],Rect2(12,10,574,30),19)
  title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.tooltip_text=title.text
  if member.get("hired",false): label_at("FleetShipWage","%s cr/day" % game.hud.commas(int(member.wage)),Rect2(604,14,220,30),17)
  else:
   var take=button_at("TakeCommand%d" % index,"Take command",Rect2(604,8,220,38),func():service.takeover_candidate=escort;game.hud.rebuild_modal())
   take.disabled=not service.takeover_reason(escort).is_empty();take.tooltip_text=service.takeover_reason(escort)
  button_at("ReleaseShip%d" % index,"Release",Rect2(842,8,146,38),game.release_ship.bind(escort))
  label_at("FleetShipFreight","Freight: %d / %d t · Cargo leaves with this ship on release or loss." % [service.cargo_used(member),int(game.catalog.field("ships",int(member.id),"Holds"))],Rect2(12,52,976,30),16,Color("bbbbbb"));canvas=base
 if game.pilot.fleet.is_empty(): section_text("EmptyFleet","No ships in your fleet.")
 if game.fleet_return_mode=="dock":
  section_text("HireCaptainsHeading","CAPTAINS AVAILABLE · Contract paid now; wages charged per game day traveled.")
  for id in service.offers():
   var section=card("HireCaptain%d" % id,82);var base=canvas;canvas=section
   label_at("HireShipName",game.catalog.record("ships",id).name,Rect2(12,8,800,28),19)
   label_at("HireShipPrice","%s cr contract · %s cr/day" % [game.hud.commas(service.hire_cost(id)),game.hud.commas(service.wage(id))],Rect2(12,42,800,28),16,Color("bbbbbb"))
   var hire=button_at("HireShip%d" % id,"Hire",Rect2(842,20,146,38),service.hire.bind(id));hire.disabled=game.pilot.credits<service.hire_cost(id) or game.pilot.fleet.size()>=service.LIMIT;canvas=base
  if service.offers().is_empty(): section_text("NoCaptains","No suitable captains available at this port.")
  var repair=button_at("RepairFleet","Repair & rearm · %s cr" % game.hud.commas(service.service_cost()),Rect2(20,600,570,38),service.service)
  repair.disabled=game.pilot.credits<service.service_cost() or game.pilot.fleet.is_empty()
 else: label_at("FleetPortHint","Land to hire captains or repair and rearm your fleet.",Rect2(20,600,750,38),17,Color("bbbbbb"))
 button_at("FleetDone","Leave",Rect2(840,600,220,38),game.toggle_fleet_menu)
 resized.connect(fit);fit()

func card(id: String,height: float) -> Panel:
 var item=Panel.new();item.name=id;item.custom_minimum_size=Vector2(1000,height)
 var style=StyleBoxFlat.new();style.bg_color=Color.BLACK;style.border_color=Color("444444");style.set_border_width_all(1);item.add_theme_stylebox_override("panel",style);contents.add_child(item)
 return item

func section_text(id: String,value: String) -> void:
 var section=card(id,62);var base=canvas;canvas=section
 label_at(id+"Text",value,Rect2(12,10,976,42),17,Color("bbbbbb"));canvas=base

func fit() -> void:
 var ratio=minf(1.0,minf((size.x-40)/LAYOUT.x,(size.y-40)/LAYOUT.y))
 canvas.scale=Vector2.ONE*ratio;canvas.position=(size-LAYOUT*ratio)*.5
