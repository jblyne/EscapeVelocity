extends Control
var game
var clock=0.0
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(dt):
 visible=game.mode=="flight" and game.maverick_volley.eligible()
 if visible: clock+=dt;queue_redraw()
func _draw():
 if not visible: return
 var volley=game.maverick_volley
 var color=Color("ffad61")
 for npc in volley.targets:
  if not volley.valid(npc): continue
  var p: Vector2=game.camera.unproject_position(game.v3(npc.position))
  if p.x<0 or p.x>size.x-game.hud.flight_panel.panel_width() or p.y<0 or p.y>size.y: continue
  var r=27.0+sin(clock*5)*2
  for d in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
   var corner=p+d*r
   draw_line(corner,corner-Vector2(d.x*12,0),color,2,true)
   draw_line(corner,corner-Vector2(0,d.y*12),color,2,true)
 if volley.ready:
  var font=ThemeDB.fallback_font
  var text="%d TARGETS LOCKED · PRESS FIRE TO LAUNCH" % volley.targets.size()
  var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x
  draw_string(font,Vector2((size.x-game.hud.flight_panel.panel_width()-width)*.5,size.y-125),text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,color)
