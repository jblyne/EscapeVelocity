shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;

uniform float age = 0.0;
uniform vec3 impact_direction = vec3(0.0,0.0,-1.0);
varying vec3 surface_direction;

void vertex() {
	surface_direction = normalize(VERTEX);
}

void fragment() {
	float progress = clamp(age / 0.48,0.0,1.0);
	float fade = pow(1.0-progress,1.6);
	float rim = pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),2.4);
	float distance_from_hit = acos(clamp(dot(normalize(surface_direction),impact_direction),-1.0,1.0));
	// Keep every component inside a local impact cap, including the rim.
	float impact_mask = 1.0-smoothstep(0.45,0.95,distance_from_hit);
	float wave = exp(-pow((distance_from_hit-age*2.0)*9.0,2.0));
	float hotspot = exp(-distance_from_hit*distance_from_hit*5.0)*exp(-age*10.0);
	float shimmer = 0.85+0.15*sin(distance_from_hit*42.0-age*32.0);
	ALBEDO = mix(vec3(0.12,0.42,1.0),vec3(0.65,0.94,1.0),clamp(wave+hotspot,0.0,1.0));
	ALPHA = clamp((rim*0.65+wave*0.5+hotspot*0.65+0.035)*fade*shimmer*impact_mask,0.0,0.85);
}
