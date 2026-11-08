shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform float greyscale_amount : hint_range(0.0, 1.0) = 0.0;
uniform float stun_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 stun_color : source_color = vec3(0.35, 0.6, 1.0);
uniform float stun_strength : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	float luminance = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(luminance), greyscale_amount);
	COLOR.rgb = mix(COLOR.rgb, stun_color, stun_amount * stun_strength);
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash_amount);
}
