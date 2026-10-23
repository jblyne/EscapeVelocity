shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform float clock = 0.0;
uniform float power = 1.0;
uniform float engine_phase = 0.0;
uniform float afterburner_heat = 0.0;
uniform float ignition_flare = 0.0;
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
	// Ignition rolls outward from the nozzle rather than recoloring the whole jet.
	float heat = smoothstep(t-0.1,t+0.1,afterburner_heat*1.4-0.2);
	float ignition_ring = exp(-pow((t-(afterburner_heat*1.4-0.2))*16.0,2.0))*ignition_flare;
	diamonds *= 1.0+heat*0.55;
	vec3 hot_core = mix(vec3(0.82,0.95,1.0),vec3(1.0,0.91,0.48),heat);
	ALBEDO = mix(mix(blue,orange,heat),hot_core,clamp(core+diamonds*0.45,0.0,1.0));
	ALBEDO = mix(ALBEDO,vec3(0.9,0.96,1.0),clamp(ignition_ring*0.8+core*ignition_flare*0.4,0.0,0.9));
	ALPHA = clamp((glow*(0.58+ignition_flare*0.15)+core*0.6+diamonds*envelope*0.18+ignition_ring*envelope*0.15)*(0.65+power*0.35),0.0,0.95);
}
