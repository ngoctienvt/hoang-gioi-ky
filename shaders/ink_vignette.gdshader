// Viền màn hình nhòe mực khi Đạo Tâm thấp, báo hiệu Tâm Ma.
shader_type canvas_item;

uniform vec4 ink_color : source_color = vec4(0.02, 0.02, 0.03, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 centered = (SCREEN_UV - 0.5) * 2.0;
	float angle = atan(centered.y, centered.x);
	float wave = sin(angle * 7.0 + TIME * 1.8) * 0.04 + cos(angle * 11.0 - TIME * 1.3) * 0.03;
	float dist = length(centered * vec2(1.0, 0.85)) + wave * intensity;
	float edge = smoothstep(1.05 - intensity * 0.55, 1.35 - intensity * 0.35, dist);
	COLOR = vec4(ink_color.rgb, edge * intensity * 0.88);
}
