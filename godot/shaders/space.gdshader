shader_type canvas_item;
uniform vec2 drift = vec2(0.0);
uniform float view_height = 900.0;
uniform vec2 ship_velocity = vec2(0.0);
uniform float warp_stretch : hint_range(0.0,1.0) = 0.0;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}

vec3 star_sample(vec2 world, vec2 cell, float pixels_per_world, float spacing,
                 float seed, float brightness, vec2 tail) {
 float variation = hash(cell + seed);
 vec2 center = (vec2(0.18) + vec2(hash(cell + seed + 13.1), hash(cell + seed + 47.7)) * 0.64) * spacing;
 vec2 offset = (world - cell * spacing - center) * pixels_per_world;
 float radius = 0.65 + variation * 0.65;
 float core = 1.0 - smoothstep(max(0.0, radius - 0.65), radius + 0.65, length(offset));
 float glow = exp(-dot(offset, offset) * 0.20) * 0.02;

 float along = clamp(dot(offset, tail) / max(dot(tail, tail), 0.001), 0.0, 1.0);
 vec2 trail_offset = offset - tail * along;
 float trail = exp(-dot(trail_offset, trail_offset) * 1.7) * (1.0 - along);
 trail *= smoothstep(0.5, 5.0, length(tail)) * mix(0.4,1.05,warp_stretch);
 vec3 tint = mix(vec3(0.58, 0.74, 0.92), vec3(0.95, 0.91, 0.78), variation * 0.55);
 tint = mix(tint,vec3(0.72,0.87,1.0),warp_stretch*0.5);
 return tint * (core + glow + trail) * brightness * step(0.22, variation);
}

// The same stars lengthen along actual travel, retaining their positions and
// parallax. Nearby cells supply trail ends so lines don't clip at grid borders.
vec3 star_layer(vec2 world_view, float pixels_per_world, float spacing,
                float parallax, float seed, float brightness) {
 vec2 world = world_view + drift * parallax;
 vec2 cell = floor(world / spacing);
 vec2 tail = ship_velocity * parallax * pixels_per_world * 0.035;
 tail *= min(1.0,10.0/max(length(tail),0.001));
 float long_tail = min(240.0,spacing*pixels_per_world*0.86)*(0.55+parallax*0.45);
 vec2 direction = ship_velocity/max(length(ship_velocity),0.001);
 tail = direction*mix(length(tail),max(length(tail),long_tail),warp_stretch);
 vec3 stars = star_sample(world,cell,pixels_per_world,spacing,seed,brightness,tail);
 if (warp_stretch > 0.0) {
  vec2 side = vec2(tail.x >= 0.0 ? -1.0 : 1.0,tail.y >= 0.0 ? -1.0 : 1.0);
  stars += star_sample(world,cell+vec2(side.x,0.0),pixels_per_world,spacing,seed,brightness,tail);
  stars += star_sample(world,cell+vec2(0.0,side.y),pixels_per_world,spacing,seed,brightness,tail);
  stars += star_sample(world,cell+side,pixels_per_world,spacing,seed,brightness,tail);
 }
 return stars;
}

void fragment(){
 vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;
 float aspect = viewport_size.x / viewport_size.y;
 vec3 col=vec3(0.0);
 vec2 world_view = (UV - 0.5) * vec2(aspect, 1.0) * view_height;
 float pixels_per_world = viewport_size.y / view_height;
 col += star_layer(world_view, pixels_per_world, 160.0, 0.12, 11.0, 0.32);
 col += star_layer(world_view, pixels_per_world, 190.0, 0.42, 53.0, 0.52);
 col += star_layer(world_view, pixels_per_world, 240.0, 0.95, 97.0, 0.70);
 COLOR=vec4(col,1.0);
}
