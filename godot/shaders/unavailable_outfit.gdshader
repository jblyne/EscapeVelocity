shader_type canvas_item;
void fragment() {
	vec4 sample_color = texture(TEXTURE, UV);
	float gray = dot(sample_color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray * 0.48), COLOR.a);
}
