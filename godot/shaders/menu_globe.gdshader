shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 disk=vec2(fract(UV.x*4.0),UV.y)*2.0-1.0;
	vec4 globe=texture(TEXTURE,UV);
	// Discard the atlas's checkerboard corners without covering the panel.
	globe.a*=1.0-smoothstep(0.94,1.0,length(disk));
	COLOR=globe;
}
