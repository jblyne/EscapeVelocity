extends Control
# Preserve the original central 4:3 console geometry at every aspect ratio.
# Only its new outer metalwork stretches into the remaining widescreen space.
var artwork: Texture2D=preload("res://assets/menu/bridge_hd.png")
func _draw() -> void:
	var ratio=minf(size.x/832.0,size.y/624.0)
	var center_size=Vector2(832,624)*ratio
	var origin=(size-center_size)/2
	var w: float=artwork.get_width()
	var h: float=artwork.get_height()
	draw_rect(Rect2(Vector2.ZERO,size),Color("020403"))
	draw_texture_rect_region(artwork,Rect2(origin,center_size),Rect2(w*.125,0,w*.75,h))
	if origin.x>0:
		draw_texture_rect_region(artwork,Rect2(0,origin.y,origin.x,center_size.y),Rect2(0,0,w*.125,h))
		draw_texture_rect_region(artwork,Rect2(origin.x+center_size.x,origin.y,origin.x,center_size.y),Rect2(w*.875,0,w*.125,h))
