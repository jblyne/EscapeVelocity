shader_type canvas_item;
render_mode unshaded;
uniform float brightness : hint_range(0.0,1.0)=1.0;
uniform bool resolved=false;
varying vec4 vertex_tint;
void vertex() { vertex_tint=COLOR; }
float cubic_weight(float distance) {
	float x=abs(distance);
	if (x<1.0) return 1.5*x*x*x-2.5*x*x+1.0;
	if (x<2.0) return -.5*x*x*x+2.5*x*x-4.0*x+2.0;
	return 0.0;
}
float smooth_original_ink(sampler2D source,vec2 uv,vec2 texel) {
	vec2 pixel=uv/texel-.5;
	vec2 origin=floor(pixel);
	vec2 fraction=fract(pixel);
	float coverage=0.0;
	for (int y=-1;y<=2;y++) {
		for (int x=-1;x<=2;x++) {
			vec4 ink=texture(source,(origin+vec2(float(x),float(y))+.5)*texel);
			// PICT 8000's text uses red=102 for solid ink and red=51 for
			// antialiased edges; checkerboard pixels have red=0. Preserve
			// those edges instead of thresholding them out of the strokes.
			float alpha=clamp(ink.r*2.5,0.0,1.0)*(1.0-smoothstep(.2,.4,ink.b));
			coverage+=alpha*cubic_weight(float(x)-fraction.x)*cubic_weight(float(y)-fraction.y);
		}
	}
	return clamp(coverage,0.0,1.0);
}
void fragment() {
	vec4 ink=texture(TEXTURE,UV);
	float coverage;
	if (resolved) {
		coverage=smooth_original_ink(TEXTURE,UV,TEXTURE_PIXEL_SIZE);
	} else {
		// The actual original noisy materialization frames retain their
		// pixel pattern and timing; only the settled lettering is smoothed.
		coverage=smoothstep(.62,.76,ink.g)*step(ink.b,.3)*step(.12,ink.r);
	}
	COLOR=vec4(vec3(.60,1.0,0.0)*brightness,pow(coverage,.85))*vertex_tint;
}
