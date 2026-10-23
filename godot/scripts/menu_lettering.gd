extends Control
# Original lettering and the four actual materialization frames, not an alpha
# fade. Only the ink is composited over the HD plates; geometry never changes.
const Motion=preload("res://scripts/menu_panel_motion.gd")
const CROPS=[
	[Rect2(252,321,78,44),Rect2(253,391,78,44),Rect2(257,459,78,44)],
	[Rect2(507,321,78,44),Rect2(507,391,78,44),Rect2(510,456,78,44)]
]
var at: float=0.0
var disabled_ink: bool=false
var row: int=0
var side: int=0
var final_ink: Texture2D=preload("res://assets/classic/8000.png")
var reveal: Array[Texture2D]=[
	preload("res://assets/classic/8313.png"),preload("res://assets/classic/8314.png"),
	preload("res://assets/classic/8315.png"),preload("res://assets/classic/8316.png")]

static func phase(at_seconds: float) -> int:
	var tick: float=at_seconds*Motion.FRAME_RATE
	# Reveal begins during the last folding poses and remains on the same
	# panel surface. Preserve the original four noise images and resolved ink.
	if tick<10: return -1
	if tick<12: return 0
	if tick<14: return 1
	if tick<16: return 2
	if tick<17: return 3
	return 4

static func bounds(row_index: int,side_index: int) -> Rect2:
	var top: float=[474.0,587.0,701.0][row_index]
	var bottom: float=[568.0,682.0,798.0][row_index]
	var center=Motion.design(Vector2(608.0 if side_index==0 else 1060.0,(top+bottom)*.5))
	center+=Vector2(6.0 if side_index==0 else -6.0,-1.0)
	var dimensions=Vector2(87.36,47.52)
	return Rect2(center-dimensions*.5,dimensions)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var ink=ShaderMaterial.new();ink.shader=preload("res://shaders/menu_lettering.gdshader")
	ink.set_shader_parameter("brightness",.35 if disabled_ink else 1.0)
	material=ink

func _draw() -> void:
	var current: int=phase(at)
	if current<0: return
	material.set_shader_parameter("resolved",current==4)
	var source: Rect2=CROPS[side][row]
	if current==4:
		draw_texture_rect_region(final_ink,Rect2(Vector2.ZERO,size),source)
	else:
		# Animation strips contain the two original first-row faces. Register
		# their ink to the same padded text box as the resolved six captions.
		var strip_origin=Vector2(96,316) if side==0 else Vector2(499,313)
		var first: Rect2=CROPS[side][0]
		first.position-=strip_origin
		first.position.x+=240 if side==0 else 0
		var left: float=354 if side==0 else 0
		var right: float=480 if side==0 else 126
		var top: float=[474.0,587.0,701.0][row]
		var bottom: float=[568.0,682.0,798.0][row]
		var panel_left=Motion.design(Vector2(478 if side==0 else 973,top))-position
		var panel_right=Motion.design(Vector2(699 if side==0 else 1199,bottom))-position
		var sx=[left,first.position.x,first.end.x,right]
		var sy=[0.0,first.position.y,first.end.y,59.0]
		var dx=[panel_left.x,0.0,size.x,panel_right.x]
		var dy=[panel_left.y,0.0,size.y,panel_right.y]
		# Keep the noisy illumination across the whole original display while
		# registering its lettering zone to the corrected padded caption box.
		for y in 3:
			for x in 3:
				var dest=Rect2(dx[x],dy[y],dx[x+1]-dx[x],dy[y+1]-dy[y])
				var src=Rect2(sx[x],sy[y],sx[x+1]-sx[x],sy[y+1]-sy[y])
				var vertices=PackedVector2Array()
				for point in [dest.position,Vector2(dest.end.x,dest.position.y),dest.end,Vector2(dest.position.x,dest.end.y)]:
					vertices.append(Motion.warp_design(position+point,row,side,at)-position)
				var uv=PackedVector2Array([src.position,Vector2(src.end.x,src.position.y),src.end,Vector2(src.position.x,src.end.y)])
				for i in uv.size(): uv[i]/=reveal[current].get_size()
				draw_primitive(vertices,PackedColorArray([Color.WHITE]),uv,reveal[current])
