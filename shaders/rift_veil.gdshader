// Màn rạn không gian mờ ảo: mép tan dần, gợn sóng chậm theo thời gian, không có viền cứng.
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec3 glow_color : source_color = vec3(0.35, 0.8, 0.75);
uniform float intensity : hint_range(0.0, 2.0) = 0.55;
uniform float edge_softness : hint_range(0.05, 1.0) = 0.45;
uniform float ripple_speed = 0.4;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	// Hình bầu dục, mép mờ dần.
	float shape = 1.0 - smoothstep(1.0 - edge_softness, 1.0, length(p * vec2(1.0, 0.85)));
	// Vân gợn chạy dọc, mảnh dần ra ngoài.
	float ripple = 0.65 + 0.35 * sin(p.y * 7.0 - TIME * ripple_speed * 6.0 + sin(p.x * 3.0 + TIME * ripple_speed) * 1.5);
	float core = 1.0 - smoothstep(0.0, 0.8, abs(p.x));
	ALBEDO = glow_color * intensity * shape * ripple * (0.5 + 0.5 * core);
}
