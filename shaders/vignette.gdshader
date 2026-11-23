// Làm tối dần mép màn hình để tạo cảm giác u ám, thu hẹp tầm nhìn kiểu game sinh tồn.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.04, 0.035, 0.05, 1.0);
// Bán kính bắt đầu tối (0 = tâm, 1 = góc màn hình).
uniform float inner_radius : hint_range(0.0, 1.5) = 0.45;
uniform float outer_radius : hint_range(0.0, 1.5) = 1.05;
uniform float strength : hint_range(0.0, 1.0) = 0.65;

void fragment() {
	vec2 centered = (SCREEN_UV - 0.5) * 2.0;
	float dist = length(centered * vec2(1.0, 0.8));
	float amount = smoothstep(inner_radius, outer_radius, dist) * strength;
	COLOR = vec4(tint.rgb, amount);
}
