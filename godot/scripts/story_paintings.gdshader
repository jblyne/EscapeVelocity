shader_type canvas_item;
uniform float side=0.0;
uniform float source_half=-1.0;
uniform float vertical_focus_offset=0.0;
varying vec4 painting_tint;
void vertex(){
	// Fragment COLOR already includes the texture. Preserve only vertex tint so
	// the manually sampled/cropped painting is not multiplied by a second image.
	painting_tint=COLOR;
}
void fragment(){
	vec2 uv=UV;
	uv.y=clamp(uv.y+vertical_focus_offset,0.0,1.0);
	if(source_half>=0.0){
		if(abs(source_half-side)>0.5){uv.x=1.0-uv.x;}
		uv.x=uv.x*0.34+source_half*0.66;
	}
	vec4 art=texture(TEXTURE,uv);
	float outer=abs(SCREEN_UV.x-0.5)*2.0;
	float inner_fade=smoothstep(0.10,0.65,outer);
	float edge_fade=smoothstep(0.0,0.07,SCREEN_UV.y)*(1.0-smoothstep(0.93,1.0,SCREEN_UV.y));
	vec3 lit=pow(art.rgb,vec3(0.88))*0.92;
	COLOR=vec4(lit,art.a*inner_fade*edge_fade)*painting_tint;
}
