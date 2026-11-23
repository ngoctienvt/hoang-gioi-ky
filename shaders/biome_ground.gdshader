shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec2 biome_centers[6];
uniform vec3 biome_colors[6];
uniform vec3 biome_accents[6];
uniform float warp_phase = 0.0;
uniform float blend_width = 12.0;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		v += amp * value_noise(p);
		p = rot * p * 2.03 + vec2(17.1, 31.7);
		amp *= 0.5;
	}
	return v;
}

vec2 warp_xz(vec2 xz, float phase) {
	float wx = xz.x + sin(xz.y * 0.045 + phase) * 14.0 + cos((xz.x + xz.y) * 0.028 - phase * 1.7) * 8.0 + sin(xz.y * 0.11 + xz.x * 0.07) * 3.5;
	float wz = xz.y + cos(xz.x * 0.045 - phase * 1.3) * 14.0 + sin((xz.x - xz.y) * 0.028 + phase * 0.9) * 8.0 + cos(xz.x * 0.11 - xz.y * 0.07) * 3.5;
	return vec2(wx, wz);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = warp_xz(world_pos.xz, warp_phase);

	float d1 = 1e9;
	float d2 = 1e9;
	vec3 c1 = biome_colors[0];
	vec3 c2 = biome_colors[0];
	vec3 a1 = biome_accents[0];

	for (int i = 0; i < 6; i++) {
		float d = distance(w, biome_centers[i]);
		if (d < d1) {
			d2 = d1;
			c2 = c1;
			d1 = d;
			c1 = biome_colors[i];
			a1 = biome_accents[i];
		} else if (d < d2) {
			d2 = d;
			c2 = biome_colors[i];
		}
	}

	float mottle = fbm(world_pos.xz * 0.08);
	float patch_n = fbm(world_pos.xz * 0.22);
	float fine = fbm(world_pos.xz * 1.15);
	float edge = (d2 - d1) + (patch_n - 0.5) * 6.0 + (fine - 0.5) * 1.5;
	float blend_t = smoothstep(0.0, blend_width, edge);

	vec3 base = mix(c2, c1, 0.5 + 0.5 * blend_t);
	base = mix(base, a1, mottle * 0.24 + patch_n * 0.10);
	base *= 0.94 + (fine - 0.5) * 0.16;

	float eps = 0.08;
	float h0 = patch_n * 0.55 + fine * 0.45;
	float hx = fbm((world_pos.xz + vec2(eps, 0.0)) * 0.22) * 0.55 + fbm((world_pos.xz + vec2(eps, 0.0)) * 1.15) * 0.45;
	float hz = fbm((world_pos.xz + vec2(0.0, eps)) * 0.22) * 0.55 + fbm((world_pos.xz + vec2(0.0, eps)) * 1.15) * 0.45;
	vec3 world_n = normalize(vec3((h0 - hx) * 0.22, 1.0, (h0 - hz) * 0.22));
	NORMAL = normalize((VIEW_MATRIX * vec4(world_n, 0.0)).xyz);

	ALBEDO = base;
	ROUGHNESS = 0.88 + fine * 0.10;
	METALLIC = 0.0;
}
