extends Control
var unlocked: bool=false
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var center=size*.5;var radius=minf(size.x,size.y)*.44
	var color=Color("e4bd68") if unlocked else Color("626262")
	var points=PackedVector2Array()
	for i in 6: points.append(center+Vector2.from_angle(i*TAU/6-PI/2)*radius)
	draw_colored_polygon(points,Color("493b1c") if unlocked else Color("222222"))
	points.append(points[0]);draw_polyline(points,color,2,true)
	draw_arc(center,radius*.76,0,TAU,40,color,1,true)
	var star=PackedVector2Array()
	for i in 10: star.append(center+Vector2.from_angle(i*TAU/10-PI/2)*radius*(.62 if i%2==0 else .28))
	draw_colored_polygon(star,color)
