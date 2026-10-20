shader_type spatial;
varying vec3 local_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void vertex(){local_pos=VERTEX;}
void fragment(){
 vec3 p=normalize(local_pos);
 vec3 dish_axis=normalize(vec3(0.0,.74,-.673));
 if(dot(p,dish_axis)>.9525) discard;
 float latitude=asin(p.y);
 float longitude=atan(p.x,p.z);
 // A periodic longitude grid avoids a mismatched seam at the back of the hull.
 vec2 grid=vec2((longitude/6.28318530718+.5)*88.0,(latitude/3.14159265359+.5)*54.0);
 vec2 footprint=max(fwidth(grid),vec2(.001));
 float detail=1.0-smoothstep(.20,.85,max(footprint.x,footprint.y));
 vec2 cell=floor(grid);
 vec2 edges=min(fract(grid),1.0-fract(grid));
 // Filter subpixel grooves rather than letting them shimmer into wavy bands.
 vec2 grooves=1.0-smoothstep(vec2(.028)-footprint*.5,vec2(.028)+footprint*.5,edges);
 float seams=max(grooves.x,grooves.y)*detail;
 // Use a planar polar cap where longitude cells converge, retaining armor
 // detail without a singular fan of subpixel lines or a blank circular patch.
 vec2 cap_grid=p.xz*16.0;
 vec2 cap_footprint=max(fwidth(cap_grid),vec2(.001));
 float cap_detail=1.0-smoothstep(.25,.9,max(cap_footprint.x,cap_footprint.y));
 vec2 cap_edges=min(fract(cap_grid),1.0-fract(cap_grid));
 vec2 cap_grooves=1.0-smoothstep(vec2(.028)-cap_footprint*.5,vec2(.028)+cap_footprint*.5,cap_edges);
 seams+=max(cap_grooves.x,cap_grooves.y)*cap_detail*(1.0-detail);
 float fine=step(.83,hash(floor(grid*2.0)))*.018*(1.0-smoothstep(.15,.6,max(footprint.x,footprint.y)*2.0));
 float panel=.385+mix((hash(floor(cap_grid))-.5)*cap_detail,hash(cell)-.5,detail)*.15;
 vec3 color=vec3(panel*.94,panel*.98,panel)+fine;
 color*=1.0-seams*.52;
 // Tilt the equatorial trench so it remains readable in the overhead view.
 float equator=abs(dot(p,normalize(vec3(.08,.30,.95))));
 float trench_aa=max(fwidth(equator),.001);
 color=mix(color,vec3(.035,.043,.048),1.0-smoothstep(.022-trench_aa,.038+trench_aa,equator));
 float windows=step(.992,hash(floor(grid*3.0)))*step(.045,equator)*(1.0-smoothstep(.15,.6,max(footprint.x,footprint.y)*3.0));
 ALBEDO=color;
 EMISSION=vec3(.43,.65,.65)*windows*.35;
 METALLIC=.5;ROUGHNESS=.73;
}
