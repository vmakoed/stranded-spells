shader_type canvas_item;
render_mode unshaded;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(tint.rgb, alpha * tint.a);
}
