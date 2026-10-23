extends RefCounted
# Green face corners traced from PICT 8300..8312 (right half of each strip).
# Coordinates are in the original 240 x 59 strip, clockwise from hinge/top.
# 8313..8316 only materialize the lettering; the plate has stopped moving.
const FRAME_RATE=24.0
const ROW_SECONDS=17.0/FRAME_RATE
static func row_time(at: float,row: int) -> float:
	return at-row*ROW_SECONDS

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
	# Live original capture confirms that the lower edge leads inward.
	var source_corner: int=corner
	var point: Vector2=POSES[index][source_corner]
	if index<12 and source_corner in [0,3]:
		# Source traces follow the lit bevel; texture coordinates include the
		# nine-pixel dark hinge notch. Register that same notch in EVERY pose,
		# rather than changing reference edges in the final keyframe.
		var opposite: int=1 if source_corner==0 else 2
		point.x-=9.0*(POSES[index][opposite].x-point.x)/117.0
	return point

static func corners(at: float) -> PackedVector2Array:
	var phase: float=clampf(at*FRAME_RATE,0,12)
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

static func face_quad(pose: PackedVector2Array,top: float,bottom: float,inner: float,outer: float) -> PackedVector2Array:
	# Preserve the original rotation/shear in a uniform coordinate scale.
	# Mapping the whole pose through the HD plate's wider aspect ratio
	# flattened its edges and changed the apparent swing angle.
	var scale: float=(bottom-top)/59.0
	var result=PackedVector2Array()
	var spread: float=clampf(((pose[1].x-pose[0].x)+(pose[2].x-pose[3].x))/(2.0*126.0),0,1)
	var facing: float=1.0 if outer>inner else -1.0
	var extra: float=absf(outer-inner)-126.0*scale
	for i in 4:
		var rest_x: float=114.0 if i in [0,3] else 240.0
		var rest_dest: float=inner if i in [0,3] else inner+facing*(126.0*scale+extra*spread)
		result.append(Vector2(rest_dest+(pose[i].x-rest_x)*scale*facing,top+pose[i].y*scale))
	return result

static func warp_design(point: Vector2,row: int,side: int,at: float) -> Vector2:
	var pixel=Vector2(point.x*1254.0/832.0+209.0,point.y*941.0/624.0)
	var top: float=[474.0,587.0,701.0][row]
	var bottom: float=[568.0,682.0,798.0][row]
	var inner: float=478 if side==0 else 1199
	var outer: float=699 if side==0 else 973
	var u: float=(pixel.x-inner)/(outer-inner)
	var v: float=(pixel.y-top)/(bottom-top)
	var pose=corners(at)
	return design(interpolate_quad(face_quad(pose,top,bottom,inner,outer),u,v))

static func patch(surface: Control,texture: Texture2D,dest: PackedVector2Array,source: PackedVector2Array,opacity: float=1.0) -> void:
	# Subdivision keeps the checkerboard/globes attached to the folding plane
	# without the visible diagonal of a single two-triangle sprite.
	for y in 4:
		for x in 12:
			var vertices=PackedVector2Array();var uv=PackedVector2Array()
			for cell in [Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]:
				vertices.append(design(interpolate_quad(dest,cell.x/12.0,cell.y/4.0)))
				uv.append(interpolate_quad(source,cell.x/12.0,cell.y/4.0)/Vector2(1672,941))
			surface.draw_primitive(vertices,PackedColorArray([Color(1,1,1,opacity)]),uv,texture)

# Use the original rotating assembly views. A flat warp of the settled HD
# connector cannot reproduce the changing front/back surfaces of its hinge.
static var animation_frames: Array[Texture2D]=[]
static func draw(surface: Control,texture: Texture2D,at: float) -> void:
	if animation_frames.is_empty():
		for index in 13:
			animation_frames.append(load("res://assets/classic/%d.png" % (8300+index)))
	for row in 3:
		var local_time: float=row_time(at,row)
		var tick: float=clampf(local_time*FRAME_RATE,0,13)
		var original: Texture2D=animation_frames[mini(int(tick),12)]
		var next_frame: Texture2D=animation_frames[mini(int(tick)+1,12)]
		var blend: float=tick-floorf(tick)
		# Complete the change of artwork WHILE the plate is still closing.
		# Both the face and its connector follow the closing pose; after tick
		# 12 the exact same HD geometry is drawn forever, with no late offset.
		var hd_alpha: float=smoothstep(8.0,12.0,tick)
		var top: float=[474.0,587.0,701.0][row]
		var bottom: float=[568.0,682.0,798.0][row]
		for side in 2:
			var inner: float=478 if side==0 else 1199
			var outer: float=699 if side==0 else 973
			var origin: float=inner+( -114.0 if side==0 else 114.0)*(bottom-top)/59.0
			var source_origin: float=240 if side==0 else 0
			var source_split: float=354 if side==0 else 126
			# Register the mechanism and face separately at their common bevel.
			# Keep the HD fixed rail; only the rotating assembly comes from
			# the animation strip (its first/last 18 pixels contain the rail).
			var rail_end: float=origin+(18.0 if side==0 else -18.0)*(bottom-top)/59.0
			if hd_alpha<1.0:
				var spans=[Vector2(rail_end,inner),Vector2(inner,outer)] if side==0 else [Vector2(outer,inner),Vector2(inner,rail_end)]
				var sources=[Vector2(source_origin+18,source_split),Vector2(source_split,source_origin+240)] if side==0 else [Vector2(source_origin,source_split),Vector2(source_split,source_origin+222)]
				for part in 2:
					var start=design(Vector2(spans[part].x,top))
					var finish=design(Vector2(spans[part].y,bottom))
					surface.draw_texture_rect_region(original,Rect2(start,finish-start),Rect2(sources[part].x,0,sources[part].y-sources[part].x,59))
					if blend>0 and tick<12:
						surface.draw_texture_rect_region(next_frame,Rect2(start,finish-start),Rect2(sources[part].x,0,sources[part].y-sources[part].x,59),Color(1,1,1,blend))
			if hd_alpha>0.0:
				var face=face_quad(corners(local_time),top,bottom,inner,outer)
				var face_source=PackedVector2Array([Vector2(inner,top),Vector2(outer,top),Vector2(outer,bottom),Vector2(inner,bottom)])
				var joint=PackedVector2Array([Vector2(rail_end,top),face[0],face[3],Vector2(rail_end,bottom)])
				var joint_source=PackedVector2Array([Vector2(rail_end,top),Vector2(inner,top),Vector2(inner,bottom),Vector2(rail_end,bottom)])
				patch(surface,texture,joint,joint_source,hd_alpha)
				patch(surface,texture,face,face_source,hd_alpha)
