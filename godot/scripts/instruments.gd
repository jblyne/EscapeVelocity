extends Control
const SCANNER_RANGE: float = 2000
var game
var font = ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if game.mode not in ["flight","pause"]: return
	var mission_ports: Dictionary=game.missions.landing_markers()
	for planet in game.planets:
		var p: Vector2 = game.camera.unproject_position(game.v3(planet.position))
		var r: float = planet.radius / game.camera.size * size.y
		if mission_ports.has(int(planet.id)):
			draw_mission_arrow(p,r,str(planet.name))
		if p.x > -100 and p.x < size.x+100 and p.y > -100 and p.y < size.y+100:
			if planet.id == game.landing_target:
				var bracket_color = Color("68bfff") if game.landing_clearance == planet.id else Color("e7c993")
				for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
					var edge: Vector2 = p + corner * (r+8)
					draw_line(edge,edge-Vector2(corner.x*18,0),bracket_color,2,true)
					draw_line(edge,edge-Vector2(0,corner.y*18),bracket_color,2,true)
			if planet.id != game.landing_target: continue
	for id in game.pilot.world_killer.destroyed:
		if int(game.catalog.field("objects",int(id),"System"))!=game.pilot.system_id: continue
		var p: Vector2=game.camera.unproject_position(game.v3(game.world_killer.target_position(int(id))))
		draw_line(p-Vector2(7,7),p+Vector2(7,7),Color("c66d55"),2,true)
		draw_line(p+Vector2(-7,7),p+Vector2(7,-7),Color("c66d55"),2,true)
		draw_string(font,p+Vector2(12,-12),game.world_killer.world_name(int(id))+" · SHATTERED",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c68771"))
	var selected: Dictionary = game.selected_contact()
	if not selected.is_empty():
		var npc=selected
		var p: Vector2=game.camera.unproject_position(game.v3(npc.position))
		var col=Color("e98c78") if npc.hostile else Color("73c6ce")
		if npc.disabled: col=Color("94a0ab")
		var r: float = maxf(20,npc.radius/game.camera.size*size.y)+5
		draw_rect(Rect2(p-Vector2(r,r),Vector2(r*2,r*2)),col,false,1)

func draw_mission_arrow(center: Vector2, radius: float, port_name: String) -> void:
	# Keep directional arrows inside the flight area, clear of the instruments and log.
	var right: float=size.x-size.y*0.3-22.0
	var bounds=Rect2(Vector2(22,42),Vector2(maxf(40,right-22),maxf(40,size.y-150)))
	var wanted: Vector2=center-Vector2(0,radius+22)
	var tip=Vector2(clampf(wanted.x,bounds.position.x,bounds.end.x),clampf(wanted.y,bounds.position.y,bounds.end.y))
	var direction=Vector2.DOWN if bounds.has_point(wanted) else (center-tip).normalized()
	var side=direction.orthogonal()
	var red=Color("ff4545")
	var tail=tip-direction*29
	draw_line(tail,tip-direction*8,Color.BLACK,7,true)
	draw_line(tail,tip-direction*8,red,3,true)
	var points=PackedVector2Array([tip,tip-direction*13+side*7,tip-direction*13-side*7])
	draw_colored_polygon(points,red)
	var text="Mission · "+port_name
	var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	var origin=Vector2(clampf(tail.x-width*.5,24,maxf(24,right-width)),tail.y-10)
	draw_string_outline(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,4,Color.BLACK)
	draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,red)
