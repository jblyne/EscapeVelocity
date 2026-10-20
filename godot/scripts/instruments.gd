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
	for planet in game.planets:
		var p: Vector2 = game.camera.unproject_position(game.v3(planet.position))
		var r: float = planet.radius / game.camera.size * size.y
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
