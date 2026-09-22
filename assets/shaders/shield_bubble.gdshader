shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(0.75, 0.6, 0.95, 0.95);
uniform vec4 fill_color : source_color = vec4(0.12, 0.05, 0.18, 0.3);
uniform float rim_width : hint_range(0.0, 0.5) = 0.1;
uniform float wobble : hint_range(0.0, 0.2) = 0.04;
uniform float speed : hint_range(0.0, 10.0) = 1.6;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float angle = atan(p.y, p.x);
	float r = length(p) / (1.0 - wobble + wobble * sin(angle * 3.0 + TIME * speed));

	float inside = step(r, 1.0);
	float rim = step(1.0 - rim_width, r) * inside;
	float shine_arc = smoothstep(0.55, 1.0, sin(angle * 2.0 - TIME * speed)) * step(1.0 - rim_width * 2.0, r) * inside;
	float shine_dot = step(length(p - vec2(-0.42, -0.42)), 0.16);

	vec4 color = fill_color;
	color = mix(color, rim_color, rim);
	color = mix(color, vec4(1.0, 1.0, 1.0, 0.95), clamp(shine_arc * 0.7 + shine_dot + flash, 0.0, 1.0));
	color.a *= inside;
	COLOR = color;
}
