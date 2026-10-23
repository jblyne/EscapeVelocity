extends Control
# PICT 8001: the original four illuminated globe rotation frames.
const Motion=preload("res://scripts/menu_panel_motion.gd")
const SPRITES=preload("res://assets/classic/8001.png")
var row: int=0
var side: int=0
var active: bool=false
var at: float=0.0

static func bounds(row_index: int,side_index: int) -> Rect2:
	var top: float=[499.0,611.0,724.0][row_index]
	var left: float=495.0 if side_index==0 else 1135.0
	var start=Motion.design(Vector2(left,top))
	return Rect2(start,Motion.design(Vector2(left+42.0,top+42.0))-start)

static func rotation_frame(seconds: float) -> int:
	return posmod(int(floor(seconds*10.0)),4)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var glow=ShaderMaterial.new()
	glow.shader=preload("res://shaders/menu_globe.gdshader")
	material=glow

func _draw() -> void:
	if not active: return
	draw_texture_rect_region(SPRITES,Rect2(Vector2.ZERO,size),Rect2(rotation_frame(at)*25,0,25,25))
