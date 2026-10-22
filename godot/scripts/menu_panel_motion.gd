extends RefCounted
# Green face corners traced from PICT 8300..8312 (right half of each strip).
# Coordinates are in the original 240 x 59 strip, clockwise from hinge/top.
# 8313..8316 only materialize the lettering; the plate has stopped moving.
const POSES=[
	[Vector2(47,24),Vector2(51,24),Vector2(52,30),Vector2(47,30)],
	[Vector2(50,26),Vector2(64,28),Vector2(64,35),Vector2(50,35)],
	[Vector2(62,26),Vector2(91,33),Vector2(90,40),Vector2(58,34)],
	[Vector2(74,20),Vector2(118,37),Vector2(114,44),Vector2(68,36)],
	[Vector2(68,13),Vector2(99,14),Vector2(144,46),Vector2(92,45)],
	[Vector2(75,10),Vector2(125,11),Vector2(165,49),Vector2(100,48)],
	[Vector2(79,7),Vector2(152,8),Vector2(185,51),Vector2(107,50)],
	[Vector2(91,5),Vector2(177,6),Vector2(202,53),Vector2(112,52)],
	[Vector2(101,3),Vector2(198,4),Vector2(216,55),Vector2(116,54)],
	[Vector2(109,2),Vector2(214,2),Vector2(226,57),Vector2(120,56)],
	[Vector2(116,1),Vector2(228,1),Vector2(234,58),Vector2(122,57)],
	[Vector2(122,0),Vector2(236,0),Vector2(239,59),Vector2(123,59)],
	[Vector2(114,0),Vector2(240,0),Vector2(240,59),Vector2(114,59)]
]
static func registered_pose(index: int,corner: int) -> Vector2:
	var point: Vector2=POSES[index][corner]
	if index<12 and corner in [0,3]:
		# Source traces follow the lit bevel; texture coordinates include the
		# nine-pixel dark hinge notch. Register that same notch in EVERY pose,
		# rather than changing reference edges in the final keyframe.
		var opposite: int=1 if corner==0 else 2
		point.x-=9.0*(POSES[index][opposite].x-point.x)/117.0
	return point

static func corners(at: float) -> PackedVector2Array:
	var phase: float=clampf(at*15.0,0,12)
	var first: int=int(phase)
	var result=PackedVector2Array()
	for i in 4:
		var next: int=mini(first+1,12)
		var previous: int=maxi(first-1,0)
		var following: int=mini(first+2,12)
		# Preserve every recovered keyframe; ease to zero velocity only at
		# the opening and final endpoints so no last-frame snap remains.
		if first==0: previous=1
		if first==11: following=11
		result.append(registered_pose(first,i).cubic_interpolate(registered_pose(next,i),registered_pose(previous,i),registered_pose(following,i),phase-first))
	return result

static func design(pixel: Vector2) -> Vector2:
	return Vector2((pixel.x-209.0)*832.0/1254.0,pixel.y*624.0/941.0)

static func interpolate_quad(q: PackedVector2Array,u: float,v: float) -> Vector2:
	return q[0].lerp(q[1],u).lerp(q[3].lerp(q[2],u),v)

static func warp_design(point: Vector2,row: int,side: int,at: float) -> Vector2:
	var pixel=Vector2(point.x*1254.0/832.0+209.0,point.y*941.0/624.0)
	var top: float=[474.0,587.0,701.0][row]
	var bottom: float=[568.0,682.0,798.0][row]
	var inner: float=478 if side==0 else 1199
	var outer: float=699 if side==0 else 973
	var u: float=(pixel.x-inner)/(outer-inner)
	var v: float=(pixel.y-top)/(bottom-top)
	var pose=corners(at)
	var folded: Vector2=interpolate_quad(pose,u,v)
	return design(Vector2(lerpf(inner,outer,(folded.x-114)/126.0),lerpf(top,bottom,folded.y/59.0)))

static func patch(surface: Control,texture: Texture2D,dest: PackedVector2Array,source: PackedVector2Array) -> void:
	# Subdivision keeps the checkerboard/globes attached to the folding plane
	# without the visible diagonal of a single two-triangle sprite.
	for y in 4:
		for x in 12:
			var vertices=PackedVector2Array();var uv=PackedVector2Array()
			for cell in [Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]:
				vertices.append(design(interpolate_quad(dest,cell.x/12.0,cell.y/4.0)))
				uv.append(interpolate_quad(source,cell.x/12.0,cell.y/4.0)/Vector2(1672,941))
			surface.draw_primitive(vertices,PackedColorArray([Color.WHITE]),uv,texture)

static func draw(surface: Control,texture: Texture2D,at: float) -> void:
	var pose=corners(at)
	for row in 3:
		var top: float=[474.0,587.0,701.0][row]
		var bottom: float=[568.0,682.0,798.0][row]
		for side in 2:
			var inner: float=478 if side==0 else 1199
			var outer: float=699 if side==0 else 973
			var anchor: float=399 if side==0 else 1285
			var face=PackedVector2Array()
			for point in pose:
				face.append(Vector2(lerpf(inner,outer,(point.x-114)/126.0),lerpf(top,bottom,point.y/59.0)))
			var source=PackedVector2Array([Vector2(inner,top),Vector2(outer,top),Vector2(outer,bottom),Vector2(inner,bottom)])
			var hinge_top: Vector2=face[0];var hinge_bottom: Vector2=face[3]
			hinge_top.x=maxf(hinge_top.x,anchor+.01) if side==0 else minf(hinge_top.x,anchor-.01)
			hinge_bottom.x=maxf(hinge_bottom.x,anchor+.01) if side==0 else minf(hinge_bottom.x,anchor-.01)
			var joint=PackedVector2Array([Vector2(anchor,top),hinge_top,hinge_bottom,Vector2(anchor,bottom)])
			var joint_source=PackedVector2Array([Vector2(anchor,top),Vector2(inner,top),Vector2(inner,bottom),Vector2(anchor,bottom)])
			patch(surface,texture,joint,joint_source)
			patch(surface,texture,face,source)
