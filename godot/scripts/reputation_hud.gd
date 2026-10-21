extends Control

const DIM=Color("788477")
const GOLD=Color("d5bd72")
const CELL_WIDTH=72.0
const GOVERNMENTS=[128,129,130]
var game
var cells: Array[Control]=[]

func _ready() -> void:
	position=Vector2(0,464);size=Vector2(288,42)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for i in 4:
		var cell=Control.new();cell.position=Vector2(i*CELL_WIDTH,0);cell.size=Vector2(CELL_WIDTH,42)
		cell.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(cell);cells.append(cell)

func standing(id: int) -> Dictionary:
	var government: Dictionary=game.catalog.record("governments",id)
	var score: int=int(game.pilot.reputation.get(str(id),int(government.get("fields",{}).get("InitialRec",0))))
	return {"name":government.get("name","Independent"),"score":score,"color":Color("ef7970") if score<0 else Color("8ed47c") if score>0 else DIM}

func _process(_dt: float) -> void:
	var rating: int=int(game.pilot.campaign.rating)
	cells[0].tooltip_text="Combat rating: %s\nGold gauge: progress toward 8,000 combat rating." % game.hud.commas(rating)
	for i in GOVERNMENTS.size():
		var rep=standing(GOVERNMENTS[i])
		cells[i+1].tooltip_text="%s reputation: %+d\nLeft of center: negative · Right: positive" % [rep.name,rep.score]
	queue_redraw()

func _draw() -> void:
	# Use the sidebar's shared recessed well and raised bevel, in its design coordinates.
	for x in [72,144,216]:
		draw_line(Vector2(x,5),Vector2(x,37),Color("4c514b"),1)
	# Crossed blades, shield, winged star, skull: combat, Confed, Rebel, Pirate.
	var c=Vector2(36,16)
	for sign_value in [-1,1]:
		var direction=Vector2(sign_value,-1).normalized()
		draw_line(c-direction*10,c+direction*10,GOLD,2,true)
		var h=c-direction*6;var across=Vector2(-direction.y,direction.x)*4
		draw_line(h-across,h+across,GOLD,2,true)
	var shield=PackedVector2Array([Vector2(98,7),Vector2(118,7),Vector2(117,20),Vector2(108,26),Vector2(99,20),Vector2(98,7)])
	draw_polyline(shield,Color("679fff"),2,true)
	draw_line(Vector2(108,9),Vector2(108,22),Color("679fff"),1,true)
	var star=PackedVector2Array()
	for i in 10:
		var angle=-PI/2+i*PI/5;star.append(Vector2(180,16)+Vector2(cos(angle),sin(angle))*(10 if i%2==0 else 4))
	draw_colored_polygon(star,Color("e85c52"))
	for side in [-1,1]: draw_line(Vector2(180+side*12,9),Vector2(180+side*17,23),Color("e85c52"),2,true)
	var bone=Color("ddddce")
	for side in [-1,1]:
		draw_line(Vector2(242,22+side*4),Vector2(262,22-side*4),bone,2,true)
	draw_circle(Vector2(252,12),7,bone)
	draw_rect(Rect2(248,16,8,5),bone)
	for eye in [249,255]: draw_circle(Vector2(eye,11),1.6,Color("001a03"))
	draw_line(Vector2(252,15),Vector2(252,19),Color("001a03"),1)
	var rating: int=int(game.pilot.campaign.rating)
	gauge(0,clampf(float(rating)/8000,0,1),GOLD,false)
	for i in GOVERNMENTS.size():
		var rep=standing(GOVERNMENTS[i]);var score: int=int(rep.score)
		gauge(i+1,float(score)/(absf(float(score))+100),rep.color,true)

func gauge(index: int,value: float,color: Color,signed_value: bool) -> void:
	var x: float=index*CELL_WIDTH+10
	draw_rect(Rect2(x,33,52,3),Color("273427"))
	if signed_value:
		var width=26*absf(value)
		draw_rect(Rect2(x+26-width if value<0 else x+26,33,width,3),color)
		draw_line(Vector2(x+26,31),Vector2(x+26,38),DIM,1)
	else: draw_rect(Rect2(x,33,52*value,3),color)
