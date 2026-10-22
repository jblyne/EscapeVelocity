extends Control
# Preserve the original central 4:3 console geometry at every aspect ratio.
# Only its new outer metalwork stretches into the remaining widescreen space.
var hide_static_panels: bool=false
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

	if hide_static_panels:
		# Cover the baked-in open plates before drawing the animated machinery.
		# Use the same central-console registration as the animation, independent
		# of texture-region UVs or canvas shader state when returning from flight.
		for row in 3:
			var top: float=[474.0,587.0,701.0][row]
			var bottom: float=[568.0,682.0,798.0][row]
			for span in [Vector2(399,699),Vector2(973,1285)]:
				var start=Vector2((span.x-210.0)/1254.0,(top-1.0)/941.0)*center_size+origin
				var finish=Vector2((span.y-208.0)/1254.0,(bottom+1.0)/941.0)*center_size+origin
				draw_rect(Rect2(start,finish-start),Color.BLACK)
