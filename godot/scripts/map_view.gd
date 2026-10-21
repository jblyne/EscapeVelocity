extends Control
signal changed
var game
var locations: Dictionary={}
var font=ThemeDB.fallback_font
var picked: int=-1
var dragging: bool=false

func _ready() -> void:
	clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
	if game.map_selected<0: game.map_selected=game.pilot.system_id
	if not game.map_center.is_finite(): recenter()
	resized.connect(queue_redraw)

func recenter() -> void:
	var f: Dictionary=game.catalog.system(game.pilot.system_id).fields
	game.map_center=Vector2(f.xPos,f.yPos);queue_redraw();changed.emit()

func change_zoom(factor: float) -> void:
	game.map_zoom=clampf(game.map_zoom*factor,1.0,12.0);queue_redraw();changed.emit()

func rebuild_locations() -> void:
	locations.clear()
	for id in known_systems():
		var f: Dictionary=game.catalog.system(int(id)).fields
		locations[int(id)]=size*.5+(Vector2(f.xPos,f.yPos)-game.map_center)*game.map_zoom

func system_color(id: int) -> Color:
	if id not in game.pilot.visited and id not in game.pilot.surveyed and id!=game.pilot.system_id: return Color("505050")
	var inhabited: bool=false
	for port in game.catalog.system(id).objects:
		if int(game.catalog.field("objects",port,"Flags"))&1 and not game.world_killer.destroyed(port): inhabited=true
	if not inhabited: return Color("cccccc")
	return Color("ff3030") if game.Factions.hostile_to_pilot(game.catalog,game.pilot,int(game.catalog.system(id).fields.Govt)) else Color("4080ff")

func shattered_worlds(id: int) -> Array:
	var names: Array=[]
	for port in game.catalog.system(id).objects:
		if game.world_killer.destroyed(int(port)): names.append(game.catalog.record("objects",int(port)).name)
	return names

func draw_shattered_marker(p: Vector2) -> void:
	var orange=Color("ffad60")
	for i in 3:
		var angle: float=float(i)*TAU/3.0
		draw_arc(p,14,angle+0.18,angle+1.55,12,orange,2,true)
		var shard=p+Vector2.from_angle(angle+1.85)*17
		draw_line(shard,shard+Vector2.from_angle(angle+1.5)*4,orange,2,true)

func marker_geometry(id: int) -> Dictionary:
	var p: Vector2=locations[id]
	var bounds=Rect2(Vector2(16,16),size-Vector2(32,32))
	if bounds.has_point(p):
		var direction=Vector2.ONE.normalized()
		return {"tip":p-Vector2(10,10),"direction":direction}
	# The original chart keeps distant mission arrows on its edge.
	var delta: Vector2=p-size*.5
	var half: Vector2=size*.5-Vector2(16,16)
	var divisor: float=maxf(absf(delta.x)/half.x,absf(delta.y)/half.y)
	return {"tip":size*.5+delta/maxf(1,divisor),"direction":delta.normalized()}

func marker(id: int,color: Color) -> void:
	if not locations.has(id): return
	var geometry=marker_geometry(id)
	var tip: Vector2=geometry.tip
	var direction: Vector2=geometry.direction
	draw_line(tip-direction*36,tip-direction*10,color,3,true)
	draw_colored_polygon(PackedVector2Array([tip,tip-direction.rotated(PI*.25)*15,tip-direction.rotated(-PI*.25)*15]),color)

func rush_text(info: Dictionary) -> String:
	var count: String=" ×%d" % int(info.count) if int(info.count)>1 else ""
	var deadline: String="%dd" % int(info.days) if int(info.days)>0 else ("TODAY" if int(info.days)==0 else "OVERDUE")
	return "RUSH%s · %s" % [count,deadline]

func rush_label(id: int, info: Dictionary) -> void:
	if not locations.has(id): return
	var geometry: Dictionary=marker_geometry(id)
	var text: String=rush_text(info)
	var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	var at: Vector2=geometry.tip-geometry.direction*39+Vector2(0,-10)
	at.x=clampf(at.x-width*.5,5,maxf(5,size.x-width-5))
	at.y=clampf(at.y,16,size.y-8)
	var color=Color("ffb447") if int(info.days)>1 else Color("ff6262")
	draw_string_outline(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,4,Color.BLACK)
	draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color.BLACK)
	rebuild_locations()
	for id in locations:
		for link in game.catalog.system(id).links:
			if locations.has(link) and link>id: draw_line(locations[id],locations[link],Color("646464"),1,true)
	var route: Array=game.map_route.duplicate()
	if route.is_empty() and game.destination>=0:
		route=game.route_to(game.destination) if game.pilot.cheat_chain_jump else [game.destination]
	var previous: int=game.pilot.system_id
	for stop in route:
		if locations.has(previous) and locations.has(stop): draw_line(locations[previous],locations[stop],Color("22ff22"),2,true)
		previous=stop
	var markers: Dictionary=game.missions.map_markers()
	for id in locations:
		var p: Vector2=locations[id]
		var color=system_color(id)
		draw_arc(p,6,0,TAU,24,color,1.3,true)
		if not shattered_worlds(id).is_empty(): draw_shattered_marker(p)
		if id==game.pilot.system_id: draw_circle(p,3,Color("3070ff"))
		if id==game.map_selected:
			for sign_x in [-1,1]:
				for sign_y in [-1,1]:
					var corner=p+Vector2(sign_x,sign_y)*10
					draw_line(corner,corner-Vector2(sign_x*6,0),Color.GREEN,2)
					draw_line(corner,corner-Vector2(0,sign_y*6),Color.GREEN,2)
		if id in game.pilot.visited or id in game.pilot.surveyed or id==game.map_selected or markers.has(id) or id==game.map_preview_system:
			draw_string(font,p+Vector2(23 if not shattered_worlds(id).is_empty() else 11,7),game.catalog.system(id).name,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("eeeeee"))
	for id in markers: marker(id,Color("ff2929"))
	var rush: Dictionary=game.missions.rush_markers()
	for id in rush: rush_label(id,rush[id])
	if game.map_preview_system>=0: marker(game.map_preview_system,Color("22ff22"))

func select_system(id: int,append_route: bool=false) -> void:
	picked=id;game.map_selected=id
	# Inspection is independent of navigation: remote systems remain inspectable.
	if append_route:
		game.plan_map_stop(id)
	elif id!=game.pilot.system_id and (game.pilot.cheat_chain_jump or id in game.catalog.system(game.pilot.system_id).links):
		game.map_route.clear();game.select_destination(id)
	queue_redraw();changed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			change_zoom(1.2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.2);accept_event();return
		if event.button_index==MOUSE_BUTTON_LEFT:
			dragging=false
			if event.pressed:
				var best: int=-1;var distance: float=18
				for id in locations:
					var d: float=locations[id].distance_to(event.position)
					if d<distance: best=id;distance=d
				if best>=0: select_system(best,event.shift_pressed)
				else: dragging=true;mouse_default_cursor_shape=Control.CURSOR_DRAG
			else: mouse_default_cursor_shape=Control.CURSOR_ARROW
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		game.map_center-=event.relative/game.map_zoom;queue_redraw();changed.emit();accept_event()

func known_systems() -> Array:
	if game.pilot.cheat_chain_jump: return game.catalog.data.systems.keys().map(func(id):return int(id))
	var known: Array=game.pilot.visited.duplicate()
	for id in game.pilot.surveyed+game.missions.map_markers().keys()+game.world_killer.state().destroyed.map(func(port):return game.missions.system_of(int(port)))+[game.pilot.system_id,game.map_preview_system]:
		if id>=0 and id not in known: known.append(id)
	for visited in game.pilot.visited+[game.pilot.system_id]:
		for id in game.catalog.system(visited).links:
			if id not in known: known.append(id)
	return known.filter(func(id):return game.missions.bit_matches(int(game.catalog.system(id).fields.VisBit)))
