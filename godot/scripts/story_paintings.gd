extends Control
# Each side holds its current painting until its own next story topic arrives.
const CUES=[
	{"line":0,"image":"frontier","side":0,"half":0},
	{"line":8,"image":"alien_attack","side":1,"half":-1},
	{"line":12,"image":"alien_war","side":0,"half":0},
	{"line":18,"image":"confed_rule","side":0,"half":-1},
	{"line":27,"image":"oppression","side":1,"half":-1},
	{"line":34,"image":"confederation","side":0,"half":0},
	{"line":42,"image":"rebel_uprising","side":1,"half":-1},
	{"line":52,"image":"civil_war","side":0,"half":-1},
	{"line":56,"image":"frontier","side":1,"half":1},
	{"line":62,"image":"freighter_years","side":0,"half":-1},
	{"line":65,"image":"first_ship","side":1,"half":-1},
	{"line":69,"image":"levo_journey","side":0,"half":-1},
	{"line":74,"image":"good_luck","side":1,"half":-1}]
const FADE=2.5
var panels: Array[TextureRect]=[]
var active_cue: int=-1
var current_opacity: float=0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for cue in CUES:
		var image=TextureRect.new()
		image.anchor_left=0 if cue.side==0 else .5;image.anchor_right=.5 if cue.side==0 else 1.0;image.anchor_bottom=1
		image.mouse_filter=Control.MOUSE_FILTER_IGNORE
		image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var texture: Texture2D=load("res://assets/story/%s.png" % cue.image)
		image.texture=texture
		if int(cue.half)>=0: image.stretch_mode=TextureRect.STRETCH_SCALE
		var material=ShaderMaterial.new();material.shader=load("res://scripts/story_paintings.gdshader")
		material.set_shader_parameter("source_half",float(cue.half))
		material.set_shader_parameter("side",float(cue.side));image.material=material
		image.hide();add_child(image);panels.append(image)
func present(scroll_y: float,line_height: float,speed: float,clip_height: float) -> void:
	active_cue=-1;current_opacity=0
	var current_line: float=(clip_height*.5-scroll_y)/line_height
	for i in CUES.size():
		var age: float=(current_line-float(CUES[i].line))*line_height/speed
		var has_previous: bool=false
		for previous in range(i):
			if CUES[previous].side==CUES[i].side: has_previous=true
		var opacity: float=smoothstep(FADE*.5 if has_previous else 0.0,FADE,age) if age>=0 else 0.0
		for next in range(i+1,CUES.size()):
			if CUES[next].side==CUES[i].side:
				var replacement_age: float=(current_line-float(CUES[next].line))*line_height/speed
				opacity*=1-smoothstep(0,FADE*.5,replacement_age);break
		# Both final pictures linger through the send-off, then dissolve as it exits.
		opacity*=1-smoothstep(83,88,current_line)
		panels[i].visible=opacity>0;panels[i].modulate.a=opacity

		if opacity>0: active_cue=i;current_opacity=opacity
