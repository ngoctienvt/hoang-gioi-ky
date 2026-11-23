// Tô màu kiểu tranh vẽ: màu phẳng chuyển sắc theo chiều cao của mesh,
// ánh sáng chia 2 bậc mềm (toon) thay vì PBR chân thực. Xem GDD mục 1.1.
shader_type spatial;

uniform vec3 top_color : source_color = vec3(0.4, 0.7, 0.3);
uniform vec3 bottom_color : source_color = vec3(0.15, 0.35, 0.15);
// Đoạn chuyển sắc tính theo tọa độ Y cục bộ của mesh.
uniform float gradient_start = -1.0;
uniform float gradient_height = 2.0;
// Độ sáng phần khuất sáng (0 = tối hẳn, 1 = không có bóng).
uniform float shade_floor : hint_range(0.0, 1.0) = 0.35;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	float t = clamp((local_y - gradient_start) / max(gradient_height, 0.001), 0.0, 1.0);
	ALBEDO = mix(bottom_color, top_color, t);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// Ánh sáng quấn quanh mềm: mặt khuất vẫn giữ shade_floor; bóng đổ nằm trong ATTENUATION.
	float band = mix(shade_floor, 1.0, smoothstep(-0.1, 0.15, ndl));
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * band / PI;
}
