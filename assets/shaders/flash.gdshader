shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float greyscale_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float luminance = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(luminance), greyscale_amount);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash_amount);
}
