shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform float clock = 0.0;
uniform float power = 1.0;
uniform float engine_phase = 0.0;
uniform float afterburner_heat = 0.0;
varying vec2 plume_position;

void vertex() {
	plume_position = vec2(VERTEX.x / 0.24, (VERTEX.z + 0.7) / 1.4);
}

void fragment() {
	float t = clamp(plume_position.y,0.0,1.0);
	float motion = clock*9.0 + engine_phase;
	// Turbulence grows downstream; the nozzle and hot core remain steady.
	float wobble = (sin(t*23.0-motion)*0.022 + sin(t*41.0-motion*1.37)*0.012)*t;
	float x = abs(plume_position.x-wobble);
	float width = mix(0.32,0.055,pow(t,0.7));
	float envelope = exp(-pow(x/(width*1.6),2.0)*2.0);
	float core = exp(-pow(x/(width*0.43),2.0)*2.0)*exp(-t*3.0);
	float diamonds = pow(0.5+0.5*cos(t*39.0-0.6*sin(motion)),7.0)*exp(-t*3.2);
	float structure = 0.85+0.15*sin(t*65.0-motion*2.0+x*17.0);
	float tail = pow(1.0-smoothstep(0.20,1.0,t),1.5);
	float glow = envelope*tail*structure;
	vec3 blue = mix(vec3(0.16,0.54,1.0),vec3(0.18,0.23,0.65),t);
	vec3 orange = mix(vec3(1.0,0.38,0.025),vec3(0.9,0.075,0.005),t);
	vec3 hot_core = mix(vec3(0.82,0.95,1.0),vec3(1.0,0.91,0.48),afterburner_heat);
	ALBEDO = mix(mix(blue,orange,afterburner_heat),hot_core,clamp(core+diamonds*0.45,0.0,1.0));
	ALPHA = clamp((glow*0.58+core*0.6+diamonds*envelope*0.18)*(0.65+power*0.35),0.0,0.95);
}
