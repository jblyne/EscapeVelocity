shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform int kind = 0; // Fire, smoke, shockwave, flash, ember.
uniform float age = 0.0;
uniform float life = 1.0;
uniform float seed_value = 0.0;
uniform int blast_style = 0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

float turbulence(vec2 p) {
	float result = 0.0;
	float weight = 0.55;
	for (int i = 0; i < 4; i++) {
		result += noise(p) * weight;
		p = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6)) * p + 5.1;
		weight *= 0.5;
	}
	return result;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float progress = clamp(age / life, 0.0, 1.0);
	float fade = 1.0 - smoothstep(0.35, 1.0, progress);
	float n = turbulence(p * 3.8 + vec2(seed_value, age * 0.8));
	float edge = 1.0 - smoothstep(0.68, 1.0, radius);
	float density = clamp((0.85 - radius) * 2.8 + (n - 0.5) * 1.9, 0.0, 1.0) * edge;
	vec3 color;
	float opacity;
	if (kind == 0) {
		float heat = clamp(density * 0.75 + n * 0.65 - progress * 0.7, 0.0, 1.0);
		color = mix(vec3(0.42, 0.025, 0.003), vec3(1.0, 0.26, 0.015), smoothstep(0.0, 0.45, heat));
		color = mix(color, vec3(1.0, 0.77, 0.22), smoothstep(0.4, 0.75, heat));
		color = mix(color, vec3(1.0, 0.98, 0.79), smoothstep(0.72, 0.95, heat));
		opacity = density * fade;
	} else if (kind == 1) {
		color = mix(vec3(0.025, 0.032, 0.045), vec3(0.19, 0.16, 0.14), n);
		color += vec3(0.38, 0.09, 0.015) * pow(n, 3.0) * exp(-age * 2.4);
		opacity = density * fade * 0.66 * smoothstep(0.0, 0.25, age);
	} else if (kind == 2) {
		float ring = exp(-pow((radius - 0.78) * 37.0, 2.0));
		color = mix(vec3(0.85, 0.94, 1.0), vec3(1.0, 0.37, 0.08), progress);
		opacity = (ring * (0.7 + n * 0.3) + exp(-radius * 5.0) * 0.1) * pow(1.0 - progress, 1.6);
	} else if (kind == 3) {
		color = vec3(1.0, 0.91, 0.65);
		float star = exp(-abs(p.x) * 70.0) * exp(-abs(p.y) * 3.0)
			+ exp(-abs(p.y) * 70.0) * exp(-abs(p.x) * 3.0);
		opacity = clamp(exp(-radius * 7.0) * 2.0 + star * 0.6, 0.0, 1.0) * fade * edge;
	} else {
		color = mix(vec3(1.0, 0.82, 0.28), vec3(1.0, 0.17, 0.015), progress);
		opacity = pow(max(0.0, 1.0 - radius), 1.5) * fade;
	}
	if (blast_style == 1 && kind != 1) {
		float brightness=max(color.r,max(color.g,color.b));
		color=mix(vec3(0.025,0.18,0.8),vec3(0.8,0.96,1.0),smoothstep(0.3,1.0,brightness))*brightness;
	} else if (blast_style == 3 && kind == 0) {
		color*=vec3(1.0,0.65,0.48);
	}
	ALBEDO = color;
	ALPHA = clamp(opacity, 0.0, 1.0);
}
