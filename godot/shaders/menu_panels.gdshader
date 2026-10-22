shader_type canvas_item;
render_mode unshaded;
// Remove only the static faceplates/connectors. Their HD textured meshes are
// drawn above this background in the original animation's traced fold poses.
varying vec4 vertex_tint;
void vertex() { vertex_tint=COLOR; }
void fragment() {
	vec4 source=texture(TEXTURE,UV);
	for (int row=0;row<3;row++) {
		float top=row==0 ? 474.0 : (row==1 ? 587.0 : 701.0);
		float bottom=row==0 ? 568.0 : (row==1 ? 682.0 : 798.0);
		bool left=UV.x>=399.0/1672.0 && UV.x<=699.0/1672.0;
		bool right=UV.x>=973.0/1672.0 && UV.x<=1285.0/1672.0;
		if ((left || right) && UV.y>=top/941.0 && UV.y<=bottom/941.0) source=vec4(0.0,0.0,0.0,1.0);
	}
	COLOR=source*vertex_tint;
}
