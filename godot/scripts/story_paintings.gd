extends Control
# Each side holds its current painting until its own next story topic arrives.
const CUES=[
	{"line":0,"image":"riches_dangers_poster","side":0,"half":-1},
	{"line":8,"image":"alien_attack_poster","side":1,"half":-1},
	{"line":12,"image":"alien_war_poster","side":0,"half":-1},
	{"line":18,"image":"confed_rule_poster","side":0,"half":-1},
	{"line":27,"image":"oppression_poster","side":1,"half":-1},
	{"line":34,"image":"confederation_poster","side":0,"half":-1},
	{"line":42,"image":"rebel_uprising_poster","side":1,"half":-1},
	{"line":52,"image":"civil_war_poster","side":0,"half":-1},
	{"line":56,"image":"frontier_poster","side":1,"half":-1},
	{"line":62,"image":"freighter_years_poster","side":0,"half":-1},
	{"line":65,"image":"first_ship_poster","side":1,"half":-1},
	{"line":69,"image":"levo_journey_poster","side":0,"half":-1},
	{"line":71,"image":"good_luck_poster","side":1,"half":-1}]
const FADE=2.5
const STORY=preload("res://data/intro_story.json")
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
		if cue.image=="alien_attack_poster": material.set_shader_parameter("vertical_focus_offset",-0.12)
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
		# Begin dissolving once the final line has travelled a third of the
		# viewport upward, finishing while it is still on screen.
		var final_y: float=scroll_y+(STORY.data.size()-1)*line_height
		opacity*=smoothstep(clip_height/6.0,clip_height*2.0/3.0,final_y)
		panels[i].visible=opacity>0;panels[i].modulate.a=opacity

		if opacity>0: active_cue=i;current_opacity=opacity
