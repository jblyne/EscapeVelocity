shader_type spatial;
render_mode unshaded, cull_front, blend_add, depth_draw_never;
uniform vec3 atmosphere_color : source_color = vec3(0.12,0.43,0.75);
void fragment(){
 float rim=pow(1.0-clamp(abs(dot(normalize(NORMAL),normalize(VIEW))),0.0,1.0),3.0);
 ALBEDO=atmosphere_color;
 ALPHA=rim*0.36;
}
