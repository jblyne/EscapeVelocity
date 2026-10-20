shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform bool flare=false;
uniform float clock=0.0;
void fragment() {
	vec2 p=UV*2.0-1.0;
	float pulse=.82+.18*sin(clock*(flare?31.0:19.0));
	float core;
	vec3 color;
	if (flare) {
		float cross_shape=exp(-abs(p.x)*22.0-abs(p.y)*4.2)+exp(-abs(p.y)*22.0-abs(p.x)*4.2);
		core=exp(-length(p)*7.0)+cross_shape*.75;
		color=mix(vec3(1.0,.015,.005),vec3(1.0,.55,.20),exp(-length(p)*18.0));
	} else {
		float taper=mix(.30,.06,smoothstep(-.35,.9,p.y));
		float body=exp(-pow(p.x/taper,2.0)*2.0)*(1.0-smoothstep(.5,1.0,abs(p.y)));
		float shimmer=.96+.04*sin(p.y*14.0-clock*26.0);
		core=body*shimmer+exp(-length(p*vec2(2.8,1.0))*5.5)*.35;
		color=mix(vec3(1.0,.65,.005),vec3(1.0,1.0,.30),body);
	}
	ALBEDO=color;
	ALPHA=clamp(core*pulse,0.0,1.0);
}
