extends Control
var game
var generation=-1
var age=20.0
var heading: Label
var reward: Label
var detail: Label
var footer: Label
func text_label(font_size: int,color: Color) -> Label:
 var label=Label.new();label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color);label.add_theme_constant_override("outline_size",5);label.add_theme_color_override("font_outline_color",Color(0,0,0,.9));add_child(label);return label
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 heading=text_label(24,Color("f4de9a"));reward=text_label(42,Color("b9ff8c"));detail=text_label(18,Color("eeeeee"));footer=text_label(20,Color("f4de9a"))
func _process(dt):
 var data: Dictionary=game.world_activity.hunter_celebration
 if int(data.get("generation",0))!=generation:
  generation=int(data.get("generation",0));age=0 if not data.is_empty() else 20
 if game.mode=="flight": age+=dt
 visible=game.mode=="flight" and age<9
 if not visible: return
 var available: float=game.hud.root.size.x-game.hud.flight_panel.panel_width()
 size=Vector2(minf(900,available-32),175);position=Vector2((available-size.x)*.5,140-18*(1-smoothstep(0,.4,age)))
 modulate.a=smoothstep(0,.25,age)*(1-smoothstep(8,9,age))
 heading.text="BOUNTY HUNTER DEFEATED"
 reward.text="+%s CREDITS / DAY" % game.hud.commas(int(round(5000*smoothstep(.1,.8,age))))
 detail.text="Hired by "+str(data.get("sponsor",""))+" · Tribute now "+game.hud.commas(int(data.get("income",0)))+" cr/day"
 footer.text="THEY GIVE UP · No more hunters from this world" if data.get("gave_up",false) else "YOUR TRIBUTE HAS INCREASED"
 var ys=[0,34,91,126];var labels=[heading,reward,detail,footer]
 for i in labels.size():
  labels[i].position=Vector2(0,ys[i]);labels[i].size=Vector2(size.x,42);labels[i].scale=Vector2.ONE*minf(1,(size.x-10)/maxf(1,labels[i].get_minimum_size().x));labels[i].position.x=(size.x-labels[i].size.x*labels[i].scale.x)*.5
 queue_redraw()
func _draw():
 var glow: float=.35+.15*sin(age*4)
 draw_rect(Rect2(0,0,size.x,170),Color(.01,.025,.008,.65))
 draw_line(Vector2(0,0),Vector2(size.x,0),Color(.7,1,.45,glow),2)
 draw_line(Vector2(0,170),Vector2(size.x,170),Color(.7,1,.45,glow),2)
 for i in 16:
  var t: float=fmod(age*.3+i*.061,1)
  var x: float=fmod(i*127.3,size.x)
  draw_circle(Vector2(x,170*(1-t)),1.5,Color(.8,1,.5,sin(t*PI)*.4))
