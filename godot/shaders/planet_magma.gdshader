shader_type spatial;
render_mode cull_disabled;
uniform float heat = 1.0;
uniform float fade = 1.0;
varying vec3 local_pos;
float h(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float n(vec3 p){vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(h(i),h(i+vec3(1,0,0)),f.x),mix(h(i+vec3(0,1,0)),h(i+vec3(1,1,0)),f.x),f.y),mix(mix(h(i+vec3(0,0,1)),h(i+vec3(1,0,1)),f.x),mix(h(i+vec3(0,1,1)),h(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex(){local_pos=VERTEX;}
void fragment(){
 float rock=n(local_pos*.12)+.35*n(local_pos*.32);
 float lava=smoothstep(.48,.83,rock);
 float veins=1.0-smoothstep(.025,.09,abs(n(local_pos*.075)-.5));
 float hot=clamp(lava*.65+veins*.5,0.0,1.0)*heat;
 vec3 basalt=vec3(.045,.025,.025)*(0.5+rock);
 ALBEDO=mix(basalt,vec3(.48,.065,.006),hot);
 EMISSION=mix(vec3(.25,.008,.001),vec3(1.0,.24,.018),hot)*hot*1.5;
 ROUGHNESS=.93;
 ALPHA=fade;
}
