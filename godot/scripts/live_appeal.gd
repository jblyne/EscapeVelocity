extends VBoxContainer
var game
var message: Label
var accept: Button
var deny: Button
var mercy: Button
var more: Button
var attention: float=0
var pulse_clock: float=0
var last_request: String=""
var urgency: int=0
func _ready():
 name="LiveWorldAppeal"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 message=game.hud.log_label
 var row=HFlowContainer.new();add_child(row)
 accept=Button.new();accept.name="LiveAcceptBribe";row.add_child(accept);accept.pressed.connect(game.world_killer.accept_bribe)
 deny=Button.new();deny.name="LiveDenyBribe";deny.text="Deny";row.add_child(deny);deny.pressed.connect(game.world_killer.deny)
 more=Button.new();more.name="LiveAskMore";more.text="Ask for more";row.add_child(more);more.pressed.connect(game.world_killer.demand_more)
 mercy=Button.new();mercy.text="Spare them";row.add_child(mercy);mercy.pressed.connect(game.world_killer.spare)
 var font=SystemFont.new();font.font_names=PackedStringArray(["Geneva","Helvetica","Arial"])
 for b in [accept,deny,more,mercy]:
  b.focus_mode=Control.FOCUS_NONE;b.custom_minimum_size.y=32
  b.add_theme_font_size_override("font_size",15)
  b.add_theme_font_override("font",font)
  preload("res://scripts/classic_port.gd").style_classic_button(b)
  b.pressed.connect(func():game.sound("menu_click"))
 message.add_theme_color_override("font_outline_color",Color.BLACK)
 message.add_theme_constant_override("outline_size",4)
func _process(dt):
 var k=game.world_killer
 visible=game.mode=="flight" and not k.bomb().is_empty()
 if not visible:
  message.add_theme_color_override("font_color",Color("b7bcb5"))
  attention=0;last_request="";pulse_clock=0
  return
 k.broadcast()
 var lines=k.live_message.split("\n")
 lines[0]="%s · %s" % [k.world_name(int(k.bomb().id)),k.clock(float(k.bomb().remaining))]
 if float(k.bomb().get("countdown_rate",1))>1: lines[0]+=" · %.1f× countdown" % float(k.bomb().countdown_rate)
 message.text=" · ".join(lines)
 urgency=0 if k.bomb().remaining>90 else 1 if k.bomb().remaining>55 else 2 if k.bomb().remaining>20 else 3
 if int(k.bomb().get("under_fire_hits",0))>0: urgency=maxi(urgency,2 if int(k.bomb().under_fire_hits)<3 else 3)
 var request="%s:%s:%s:%d" % [k.previous_phrase,k.bomb().get("bribe_offer",0),k.bomb().denied,urgency]
 if request!=last_request: attention=1;last_request=request
 attention=maxf(0,attention-dt*1.3)
 pulse_clock+=dt
 var colors=[Color("b7bcb5"),Color("ffdc9e"),Color("ffb46d"),Color("ff8d7e")]
 var pulse: float=(sin(pulse_clock*(3.0+urgency*1.2))*.5+.5)*(.04+urgency*.045)
 message.add_theme_color_override("font_color",colors[urgency].lerp(Color.WHITE,minf(.65,attention*.6+pulse)))
 var pending=bool(k.bomb().plea_sent) and not bool(k.bomb().denied) and int(k.bomb().get("bribe_offer",0))>0
 accept.visible=pending;deny.visible=pending
 more.visible=pending;more.disabled=not k.can_demand_more()
 more.tooltip_text="Ask for a higher bribe. A refusal speeds the countdown up by 0.5× (up to 3×)."
 accept.text="Accept %s cr" % game.hud.commas(int(k.bomb().get("bribe_offer",0)))
