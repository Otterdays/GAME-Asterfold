shader_type canvas_item;
render_mode unshaded, blend_mix;

// Hand-painted woodland diorama for the title. No TIME.
// Matches field grass/crown palettes: value grouping, multi-mass crowns,
// long-lens meadow, dirt path. Fragments hit the title ColorRect directly.


float hash_2d(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453);
}


float value_noise(vec2 value) {
	vec2 cell = floor(value);
	vec2 blend = fract(value);
	blend = blend * blend * (3.0 - 2.0 * blend);
	float south_west = hash_2d(cell);
	float south_east = hash_2d(cell + vec2(1.0, 0.0));
	float north_west = hash_2d(cell + vec2(0.0, 1.0));
	float north_east = hash_2d(cell + vec2(1.0, 1.0));
	return mix(mix(south_west, south_east, blend.x), mix(north_west, north_east, blend.x), blend.y);
}


float fbm(vec2 value) {
	float total = 0.0;
	float amplitude = 0.5;
	total += value_noise(value) * amplitude;
	value = value * 2.07 + 13.1;
	amplitude = 0.25;
	total += value_noise(value) * amplitude;
	value = value * 2.11 + 7.4;
	total += value_noise(value) * 0.125;
	value = value * 2.03 + 3.2;
	total += value_noise(value) * 0.0625;
	return total;
}


float cover(float field, float pixel) {
	return 1.0 - smoothstep(-pixel, pixel, field);
}


float warped_mass(vec2 point, vec2 center, vec2 radius, float seed) {
	vec2 delta = point - center;
	delta += (vec2(fbm(point * 11.0 + seed), fbm(point * 13.0 + seed + 4.0)) - 0.5) * radius * 0.22;
	vec2 scaled = delta / radius;
	scaled.x *= 0.92;
	return length(scaled) - 1.0;
}


void plant_tree(inout vec3 color, vec2 point, vec2 foot, float scale, float fog, float pixel) {
	float seed = hash_2d(floor(foot * 40.0));
	float trunk_top = foot.y - mix(0.10, 0.16, scale) * scale;
	float along = clamp((point.y - trunk_top) / max(foot.y - trunk_top, 0.001), 0.0, 1.0);
	float lean = (seed - 0.5) * 0.018 * scale;
	float half_w = mix(0.0045, 0.011, scale) * mix(0.5, 1.0, along);
	float trunk = cover(abs(point.x - foot.x - lean) - half_w, pixel);
	trunk *= step(trunk_top - pixel, point.y) * (1.0 - step(foot.y + pixel * 2.0, point.y));
	vec2 crown = vec2(foot.x + lean * 0.4, foot.y - mix(0.13, 0.20, scale) * scale);
	float leaves = cover(warped_mass(point, crown, vec2(0.070, 0.078) * scale, seed), pixel);
	leaves = max(leaves, cover(warped_mass(point, crown + vec2(-0.042, 0.010) * scale, vec2(0.048, 0.055) * scale, seed + 1.7), pixel));
	leaves = max(leaves, cover(warped_mass(point, crown + vec2(0.040, 0.006) * scale, vec2(0.046, 0.052) * scale, seed + 3.1), pixel));
	leaves = max(leaves, cover(warped_mass(point, crown + vec2(-0.008, -0.036) * scale, vec2(0.042, 0.040) * scale, seed + 5.4), pixel));
	vec2 blotch_uv = point * mix(28.0, 18.0, scale) + seed * 9.0;
	float blotch = value_noise(blotch_uv) * 0.7 + value_noise(blotch_uv * 2.1 + 9.0) * 0.3;
	vec3 leaf_shadow = vec3(0.11, 0.20, 0.15);
	vec3 leaf_base = vec3(0.20, 0.38, 0.26);
	vec3 leaf_light = vec3(0.42, 0.55, 0.30);
	float sun_side = clamp((point.x - crown.x) / max(scale, 0.001) * 8.0 + 0.35, 0.0, 1.0);
	vec3 leaf_col = mix(leaf_shadow, leaf_base, smoothstep(0.15, 0.70, blotch));
	leaf_col = mix(leaf_col, leaf_light, sun_side * 0.40);
	leaf_col = mix(leaf_col, leaf_light, smoothstep(0.72, 0.96, value_noise(blotch_uv * 2.6 + 3.0)) * 0.18);
	leaf_col = mix(leaf_col, vec3(0.62, 0.66, 0.48), fog);
	vec3 bark = mix(vec3(0.18, 0.11, 0.07), vec3(0.32, 0.20, 0.12), value_noise(vec2(point.x * 90.0, point.y * 22.0)));
	bark = mix(bark, vec3(0.55, 0.50, 0.40), fog * 0.5);
	float shadow = cover(length((point - vec2(foot.x, foot.y + 0.012 * scale)) / vec2(0.055, 0.016) * scale) - 1.0, pixel * 3.0);
	color = mix(color, color * 0.55, shadow * 0.45 * (1.0 - fog));
	color = mix(color, leaf_col, leaves);
	color = mix(color, bark, trunk);
}


void fragment() {
	vec2 uv = UV;
	vec2 p = vec2((uv.x - 0.5) * 1.7777778 + 0.5, uv.y);
	float pixel = max(fwidth(p.x), 0.0009);
	float horizon = 0.545 + (fbm(vec2(uv.x * 3.2, 1.4)) - 0.5) * 0.012;

	vec3 sky_zenith = vec3(0.31, 0.52, 0.72);
	vec3 sky_haze = vec3(0.90, 0.88, 0.78);
	vec3 sun_core = vec3(1.00, 0.94, 0.72);
	vec3 sun_bloom = vec3(0.98, 0.82, 0.52);
	float sky_t = clamp(uv.y / max(horizon, 0.001), 0.0, 1.0);
	vec3 sky = mix(sky_zenith, sky_haze, smoothstep(0.0, 1.0, pow(sky_t, 0.85)));
	float sun_d = distance(uv, vec2(0.72, 0.16));
	sky = mix(sky, sun_bloom, (1.0 - smoothstep(0.04, 0.38, sun_d)) * 0.55);
	sky = mix(sky, sun_core, cover(sun_d - 0.028, pixel * 6.0) * 0.9);
	float cloud = fbm(uv * vec2(3.6, 6.2) + vec2(1.8, 0.3));
	float cloud_mask = smoothstep(0.52, 0.78, cloud) * (1.0 - sky_t) * 0.55;
	cloud_mask *= 1.0 - cover(sun_d - 0.12, 0.08);
	sky = mix(sky, vec3(0.96, 0.95, 0.92), cloud_mask);

	vec3 color = sky;
	float hill = fbm(vec2(uv.x * 4.5, 2.6));
	float hill_line = horizon - 0.055 - hill * 0.045;
	float hill_mask = cover(uv.y - hill_line, pixel * 2.0) * (1.0 - cover(uv.y - horizon, pixel));
	color = mix(color, mix(vec3(0.28, 0.40, 0.32), vec3(0.45, 0.52, 0.38), hill), hill_mask);

	float ground_depth = clamp((uv.y - horizon) / max(1.0 - horizon, 0.001), 0.0, 1.0);
	float ground = cover(horizon - uv.y, pixel * 2.0);
	vec2 grass_uv = vec2(uv.x * mix(22.0, 7.0, ground_depth), ground_depth * 16.0);
	float broad = value_noise(grass_uv * 0.35) * 0.65 + value_noise(grass_uv * 0.72 + 4.0) * 0.35;
	float tuft = value_noise(grass_uv * 3.4 + 8.1);
	vec3 grass = mix(vec3(0.16, 0.25, 0.16), vec3(0.27, 0.38, 0.22), smoothstep(0.2, 0.75, broad));
	grass = mix(grass, vec3(0.39, 0.49, 0.27), (1.0 - ground_depth) * 0.35 + smoothstep(0.7, 0.95, tuft) * 0.12);
	grass = mix(grass, vec3(0.55, 0.58, 0.36), pow(1.0 - ground_depth, 2.0) * 0.2);
	color = mix(color, grass, ground);
	float path_half = mix(0.016, 0.125, pow(ground_depth, 1.35));
	float path_center = 0.50 + (fbm(vec2(ground_depth * 6.0, 2.0)) - 0.5) * 0.03;
	float path_field = abs(uv.x - path_center) - path_half;
	float path = cover(path_field, pixel * 1.6) * ground * smoothstep(0.04, 0.16, ground_depth);
	float edge_wear = cover(abs(path_field) - 0.008, pixel * 2.0) * path;
	float rut = cover(abs(uv.x - path_center - path_half * 0.32) - 0.0045 * (0.4 + ground_depth), pixel);
	rut = max(rut, cover(abs(uv.x - path_center + path_half * 0.30) - 0.0038 * (0.4 + ground_depth), pixel));
	vec3 dirt = mix(vec3(0.36, 0.26, 0.16), vec3(0.50, 0.38, 0.22), value_noise(vec2(uv.x * 30.0, ground_depth * 18.0)));
	dirt = mix(dirt, vec3(0.28, 0.20, 0.13), rut * 0.55);
	color = mix(color, dirt, path * 0.94);
	color = mix(color, mix(dirt, grass, 0.35), edge_wear * 0.35);
	float stone = step(0.93, hash_2d(floor(vec2(uv.x, ground_depth) * vec2(48.0, 22.0))));
	stone *= path * smoothstep(0.2, 0.85, ground_depth);
	color = mix(color, vec3(0.55, 0.50, 0.42), stone * cover(length(fract(vec2(uv.x, ground_depth) * vec2(48.0, 22.0)) - 0.5) - 0.18, pixel * 8.0));

	color = mix(color, sky_haze, (1.0 - cover(uv.y - horizon, 0.04)) * 0.22);

	for (int i = 0; i < 26; i++) {
		float fi = float(i);
		float h = hash_2d(vec2(fi, 4.7));
		float x = mix(-0.02, 1.02, (fi + 0.35) / 26.0);
		vec2 foot = vec2(x, horizon + mix(0.012, 0.028, h));
		float sil = cover(warped_mass(uv, foot + vec2(0.0, -0.038 - h * 0.02), vec2(0.034 + h * 0.02, 0.048 + h * 0.02), h * 6.0), pixel * 1.4);
		color = mix(color, mix(vec3(0.12, 0.20, 0.14), vec3(0.22, 0.30, 0.18), h), sil * 0.92);
	}

	plant_tree(color, p, vec2(0.07, 0.92), 1.45, 0.02, pixel);
	plant_tree(color, p, vec2(0.16, 0.84), 1.18, 0.06, pixel);
	plant_tree(color, p, vec2(0.26, 0.76), 0.92, 0.12, pixel);
	plant_tree(color, p, vec2(0.11, 0.73), 0.78, 0.16, pixel);
	plant_tree(color, p, vec2(0.33, 0.70), 0.70, 0.20, pixel);
	plant_tree(color, p, vec2(0.21, 0.67), 0.58, 0.24, pixel);
	plant_tree(color, p, vec2(0.38, 0.64), 0.48, 0.30, pixel);
	plant_tree(color, p, vec2(0.14, 0.63), 0.42, 0.32, pixel);
	plant_tree(color, p, vec2(0.93, 0.91), 1.40, 0.02, pixel);
	plant_tree(color, p, vec2(0.84, 0.83), 1.12, 0.07, pixel);
	plant_tree(color, p, vec2(0.74, 0.76), 0.90, 0.13, pixel);
	plant_tree(color, p, vec2(0.89, 0.72), 0.76, 0.17, pixel);
	plant_tree(color, p, vec2(0.67, 0.69), 0.66, 0.22, pixel);
	plant_tree(color, p, vec2(0.79, 0.66), 0.54, 0.26, pixel);
	plant_tree(color, p, vec2(0.62, 0.63), 0.46, 0.32, pixel);
	plant_tree(color, p, vec2(0.86, 0.62), 0.40, 0.34, pixel);

	float overhang = cover(warped_mass(p, vec2(-0.02, -0.04), vec2(0.28, 0.18), 2.2), pixel);
	overhang = max(overhang, cover(warped_mass(p, vec2(1.02, -0.05), vec2(0.26, 0.17), 4.8), pixel));
	overhang = max(overhang, cover(warped_mass(p, vec2(0.18, -0.08), vec2(0.16, 0.12), 3.1), pixel) * 0.7);
	overhang = max(overhang, cover(warped_mass(p, vec2(0.82, -0.08), vec2(0.15, 0.11), 6.0), pixel) * 0.7);
	vec3 over_col = mix(vec3(0.08, 0.16, 0.10), vec3(0.18, 0.32, 0.16), value_noise(p * 22.0));
	color = mix(color, over_col, overhang * 0.82);

	float warmth = (1.0 - smoothstep(0.0, 0.7, sun_d)) * 0.08 * (1.0 - ground_depth * 0.5);
	color += sun_bloom * warmth;
	float grain = (hash_2d(floor(FRAGCOORD.xy)) - 0.5) * (1.2 / 255.0);
	color += grain;
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
