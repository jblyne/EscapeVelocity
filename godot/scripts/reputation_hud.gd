extends Control

const DIM=Color("788477")
const GOLD=Color("d5bd72")
var game
var cells: Array[Control]=[]

func _ready() -> void:
	position=Vector2(0,464);size=Vector2(288,42)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for i in 3:
		var cell=Control.new();cell.position=Vector2(i*96,0);cell.size=Vector2(96,42)
		cell.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(cell);cells.append(cell)

func standing(id: int) -> Dictionary:
	var government: Dictionary=game.catalog.record("governments",id)
	var score: int=int(game.pilot.reputation.get(str(id),int(government.get("fields",{}).get("InitialRec",0))))
	return {"name":government.get("name","Independent"),"score":score,"color":Color("ef7970") if score<0 else Color("8ed47c") if score>0 else DIM}

func _process(_dt: float) -> void:
	var rating: int=int(game.pilot.campaign.rating)
	cells[0].tooltip_text="Combat rating: %s\nGold gauge: progress toward 8,000 combat rating." % game.hud.commas(rating)
	for i in 2:
		var rep=standing(128+i)
		cells[i+1].tooltip_text="%s reputation: %+d\nLeft of center: negative · Right: positive" % [rep.name,rep.score]
	queue_redraw()

func _draw() -> void:
	# Use the sidebar's shared recessed well and raised bevel, in its design coordinates.
	for x in [96,192]:
		draw_line(Vector2(x,5),Vector2(x,37),Color("4c514b"),1)
	# Crossed blades, a shield, and a winged star identify combat, Confederation, and Rebellion.
	var c=Vector2(48,16)
	for sign_value in [-1,1]:
		var direction=Vector2(sign_value,-1).normalized()
		draw_line(c-direction*10,c+direction*10,GOLD,2,true)
		var h=c-direction*6;var across=Vector2(-direction.y,direction.x)*4
		draw_line(h-across,h+across,GOLD,2,true)
	var shield=PackedVector2Array([Vector2(134,7),Vector2(154,7),Vector2(153,20),Vector2(144,26),Vector2(135,20),Vector2(134,7)])
	draw_polyline(shield,Color("679fff"),2,true)
	draw_line(Vector2(144,9),Vector2(144,22),Color("679fff"),1,true)
	var star=PackedVector2Array()
	for i in 10:
		var angle=-PI/2+i*PI/5;star.append(Vector2(240,16)+Vector2(cos(angle),sin(angle))*(10 if i%2==0 else 4))
	draw_colored_polygon(star,Color("e85c52"))
	for side in [-1,1]: draw_line(Vector2(240+side*12,9),Vector2(240+side*17,23),Color("e85c52"),2,true)
	var rating: int=int(game.pilot.campaign.rating)
	gauge(0,clampf(float(rating)/8000,0,1),GOLD,false)
	for i in 2:
		var rep=standing(128+i);var score: int=int(rep.score)
		gauge(i+1,float(score)/(absf(float(score))+100),rep.color,true)

func gauge(index: int,value: float,color: Color,signed_value: bool) -> void:
	var x: float=index*96+10
	draw_rect(Rect2(x,33,76,3),Color("273427"))
	if signed_value:
		var width=38*absf(value)
		draw_rect(Rect2(x+38-width if value<0 else x+38,33,width,3),color)
		draw_line(Vector2(x+38,31),Vector2(x+38,38),DIM,1)
	else: draw_rect(Rect2(x,33,76*value,3),color)
