shader_type spatial;
render_mode specular_disabled;

uniform vec4 rock_tint : source_color = vec4(0.4,0.37,0.32,1.0);
uniform float seed_offset=0.0;
uniform float ember_heat=0.0;
uniform float charred=0.0;
varying vec3 rock_position;

float hash(vec3 p) {
	p=fract(p*0.3183099+vec3(0.11,0.37,0.73));
	p*=17.0;
	return fract(p.x*p.y*p.z*(p.x+p.y+p.z));
}
float noise(vec3 p) {
	vec3 cell=floor(p), f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(mix(hash(cell),hash(cell+vec3(1,0,0)),f.x),mix(hash(cell+vec3(0,1,0)),hash(cell+vec3(1,1,0)),f.x),f.y),
		mix(mix(hash(cell+vec3(0,0,1)),hash(cell+vec3(1,0,1)),f.x),mix(hash(cell+vec3(0,1,1)),hash(cell+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { rock_position=VERTEX; }
void fragment() {
	vec3 p=rock_position+vec3(seed_offset);
	float broad=noise(p*4.0);
	float grain=noise(p*42.0);
	float grit=noise(p*115.0);
	float veins=smoothstep(0.47,0.52,noise(p*13.0));
	ALBEDO=rock_tint.rgb*(0.42+broad*0.48+grain*0.13+grit*0.06)*mix(0.86,1.0,veins);
	ALBEDO*=mix(1.0,.45,charred);
	float fracture_noise=noise(p*4.0);
	float fracture_aa=max(fwidth(fracture_noise),.005);
	float fissure=1.0-smoothstep(.02-fracture_aa,.065+fracture_aa,abs(fracture_noise-.5));
	EMISSION=vec3(1.0,.18,.015)*fissure*ember_heat;
	ROUGHNESS=0.98;
	METALLIC=0.0;
	// Screen-space surface gradient adds fine pits under the scene's actual light.
	float height=(grain*0.72+grit*0.28)*0.04;
	vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);
	vec3 rx=cross(dy,NORMAL),ry=cross(NORMAL,dx);
	float determinant=dot(dx,rx);
	NORMAL=normalize(abs(determinant)*NORMAL-sign(determinant)*(dFdx(height)*rx+dFdy(height)*ry));
}
