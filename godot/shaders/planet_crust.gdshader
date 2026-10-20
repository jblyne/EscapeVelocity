shader_type spatial;
uniform float rupture_heat = 1.0;
uniform float rupture_fade = 1.0;
uniform vec3 ocean_color : source_color = vec3(0.025,0.13,0.25);
uniform vec3 land_color : source_color = vec3(0.24,0.38,0.28);
uniform float seed_value = 133.0;
uniform int surface_style = 0; // Temperate/ice, airless rock, gas/cloud world.
uniform float land_level = 0.48;
uniform float cloud_amount = 1.0;
uniform float ice_amount = 1.0;
uniform float crater_strength = 0.0;
uniform vec4 craters[32];
varying vec3 local_pos;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
 vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float fbm(vec3 p) { float s=0.0; float a=0.5; for(int i=0;i<5;i++){s+=noise(p)*a;p=p*2.03+vec3(2.1);a*=0.5;}return s; }
void vertex(){ local_pos=VERTEX; }
void fragment(){
 vec3 p=normalize(local_pos);
 float h=fbm(p*4.2+vec3(seed_value*0.21));
 if(surface_style==1){
  float relief=0.0;
  float rims=0.0;
  for(int i=0;i<32;i++){
   float q=2.0*(1.0-dot(p,craters[i].xyz))/max(craters[i].w*craters[i].w,0.0001);
   if(q<1.5){
    float rim=exp(-pow((q-0.92)*8.0,2.0));
    relief+=(-0.03*(1.0-smoothstep(0.12,0.9,q))+0.012*rim)*crater_strength;
    rims+=rim;
   }
  }
  float maria=(1.0-smoothstep(0.40,0.58,h))*0.30*crater_strength;
  vec3 rock=land_color*(0.80+h*0.38-maria+relief*5.0+rims*0.10*crater_strength);
  NORMAL=normalize(NORMAL+vec3(-dFdx(relief)*18.0,-dFdy(relief)*18.0,0.0));
  ALBEDO=rock;
  ROUGHNESS=0.96;
  METALLIC=0.0;
 }else if(surface_style==2){
  float bands=0.5+0.5*sin(p.z*32.0+h*8.0+seed_value);
  float flow=fbm(p*7.0+vec3(h,seed_value*0.4,0.0));
  ALBEDO=mix(ocean_color,land_color,clamp(bands*0.55+flow*0.6,0.0,1.0));
  ROUGHNESS=0.95;
  METALLIC=0.0;
 }else{
  float land=smoothstep(land_level-0.02,land_level+0.07,h);
  vec3 col=mix(ocean_color,land_color*(0.6+h),land);
  float clouds=smoothstep(0.56,0.69,fbm(p*8.0+vec3(TIME*0.006,seed_value,0)));
  col=mix(col,vec3(0.75,0.84,0.88),clouds*0.75*cloud_amount);
  float ice=smoothstep(0.87,0.99,abs(p.z)*ice_amount+h*0.08);
  ALBEDO=mix(col,vec3(0.72,0.83,0.86),ice);
  ROUGHNESS=mix(0.28,0.92,land);
  METALLIC=0.08;
 }
 float cracks=1.0-smoothstep(0.01,0.07,abs(noise(p*15.0+vec3(seed_value))-0.5));
 EMISSION=vec3(1.0,0.17,0.018)*cracks*rupture_heat*4.5;
 ALBEDO=mix(ALBEDO,vec3(0.12,0.035,0.018),rupture_heat*0.45);
 ALPHA=rupture_fade;
}
