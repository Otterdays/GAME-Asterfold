shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 dirt_shadow : source_color = vec4(0.32, 0.22, 0.13, 1.0);
uniform vec4 dirt_base : source_color = vec4(0.58, 0.43, 0.25, 1.0);
uniform vec4 dirt_light : source_color = vec4(0.71, 0.56, 0.34, 1.0);
uniform vec4 pebble_color : source_color = vec4(0.42, 0.38, 0.31, 1.0);
uniform vec4 dry_stone_color : source_color = vec4(0.66, 0.58, 0.43, 1.0);
uniform float broad_scale : hint_range(0.05, 0.5) = 0.16;
uniform float detail_scale : hint_range(0.25, 4.0) = 1.2;
uniform int patch_count : hint_range(0, 16) = 0;
uniform vec4 road_patches[16];
uniform float corner_radii_m[16];
uniform float join_softness_m : hint_range(0.05, 2.0) = 0.55;

varying vec3 world_position;
varying vec3 local_position;


float hash_2d(vec2 value) {
	return fract(sin(dot(value, vec2(41.3, 289.1))) * 45758.5453);
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


float rounded_box_distance(vec2 point, vec4 patch, float radius) {
	vec2 offset = abs(point - patch.xy) - patch.zw + vec2(radius);
	return min(max(offset.x, offset.y), 0.0) + length(max(offset, vec2(0.0))) - radius;
}


float smooth_union_distance(float first, float second, float softness) {
	float blend = clamp(0.5 + 0.5 * (second - first) / softness, 0.0, 1.0);
	return mix(second, first, blend) - softness * blend * (1.0 - blend);
}


vec2 road_network_sample(vec2 point) {
	float distance_to_road = 100000.0;
	float nearest_patch_index = 0.0;
	float nearest_patch_distance = 100000.0;
	for (int index = 0; index < 16; index++) {
		if (index >= patch_count) {
			break;
		}
		float patch_distance = rounded_box_distance(point, road_patches[index], corner_radii_m[index]);
		if (patch_distance < nearest_patch_distance) {
			nearest_patch_distance = patch_distance;
			nearest_patch_index = float(index);
		}
		if (index == 0) {
			distance_to_road = patch_distance;
		} else {
			distance_to_road = smooth_union_distance(distance_to_road, patch_distance, join_softness_m);
		}
	}
	return vec2(distance_to_road, nearest_patch_index);
}


float cart_rut_pattern(vec2 point, float road_distance, int nearest_patch_index) {
	vec4 nearest_patch = road_patches[nearest_patch_index];
	if (abs(nearest_patch.z - nearest_patch.w) < 0.75) {
		return 0.0;
	}
	vec2 patch_offset = point - nearest_patch.xy;
	float lateral_position = nearest_patch.z > nearest_patch.w ? patch_offset.y : patch_offset.x;
	float half_width = min(nearest_patch.z, nearest_patch.w);
	float rut_center = half_width * 0.43;
	float twin_tracks = 1.0 - smoothstep(0.055, 0.14, abs(abs(lateral_position) - rut_center));
	float broken_track = 0.62 + value_noise(world_position.xz * 0.34 + 83.0) * 0.38;
	return twin_tracks * broken_track * smoothstep(0.18, 0.52, -road_distance);
}


float directional_scuff(vec2 point, float road_distance, int nearest_patch_index) {
	vec4 nearest_patch = road_patches[nearest_patch_index];
	if (abs(nearest_patch.z - nearest_patch.w) < 0.75) {
		return 0.0;
	}
	vec2 patch_offset = point - nearest_patch.xy;
	vec2 grain_position = nearest_patch.z > nearest_patch.w
		? vec2(patch_offset.x * 0.48, patch_offset.y * 2.8)
		: vec2(patch_offset.y * 0.48, patch_offset.x * 2.8);
	float brushed_noise = value_noise(grain_position + vec2(17.0, 53.0));
	return smoothstep(0.70, 0.82, brushed_noise) * smoothstep(0.16, 0.46, -road_distance);
}


float stone_mask(vec2 point, float density, float seed, float presence_threshold, vec2 radius_range) {
	vec2 grid_position = point * density;
	vec2 cell = floor(grid_position);
	vec2 cell_position = fract(grid_position) - 0.5;
	float cell_sample = hash_2d(cell + vec2(seed, seed * 0.37));
	vec2 stone_offset = vec2(fract(cell_sample * 17.13), fract(cell_sample * 41.71)) - 0.5;
	stone_offset *= 0.56;
	float stone_radius = mix(radius_range.x, radius_range.y, fract(cell_sample * 73.17));
	float stone_distance = length(cell_position - stone_offset);
	float antialias_width = max(fwidth(stone_distance) * 1.35, 0.012);
	float stone_shape = 1.0 - smoothstep(stone_radius - antialias_width, stone_radius + antialias_width, stone_distance);
	float stone_present = step(presence_threshold, fract(cell_sample * 97.31));
	return stone_shape * stone_present;
}


void vertex() {
	local_position = VERTEX;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec2 surface_position = world_position.xz;
	float boundary_wobble = (value_noise(surface_position * 0.52 + 31.0) - 0.5) * 0.18;
	vec2 road_sample = road_network_sample(local_position.xz);
	float road_distance = road_sample.x + boundary_wobble;
	if (road_distance > 0.0) {
		discard;
	}

	float broad_value = value_noise(surface_position * broad_scale);
	float worn_value = value_noise(surface_position * detail_scale + 19.0);
	float painted_edge = 1.0 - smoothstep(0.06, 0.58, -road_distance);
	float traveled_center = smoothstep(0.55, 1.5, -road_distance);
	float detail_clearance = smoothstep(0.12, 0.38, -road_distance);
	float small_pebble = stone_mask(surface_position, 3.4, 13.0, 0.82, vec2(0.075, 0.13)) * detail_clearance;
	float pale_stone = stone_mask(surface_position, 1.55, 47.0, 0.89, vec2(0.10, 0.18)) * detail_clearance;
	float dark_press = smoothstep(0.78, 0.94, value_noise(surface_position * 0.42 + vec2(61.0, 7.0)));
	int nearest_patch_index = int(road_sample.y);
	float cart_ruts = cart_rut_pattern(local_position.xz, road_distance, nearest_patch_index);
	float scuff = directional_scuff(local_position.xz, road_distance, nearest_patch_index);
	float crisp_wear = smoothstep(0.69, 0.81, worn_value) * detail_clearance;

	vec3 painted_color = mix(dirt_shadow.rgb, dirt_base.rgb, smoothstep(0.10, 0.76, broad_value));
	painted_color = mix(painted_color, dirt_light.rgb, crisp_wear * 0.17 + scuff * 0.11);
	painted_color = mix(painted_color, dirt_light.rgb, traveled_center * 0.10);
	painted_color = mix(painted_color, dirt_shadow.rgb, painted_edge * 0.34 + dark_press * 0.08 + cart_ruts * 0.15);
	painted_color = mix(painted_color, pebble_color.rgb, small_pebble * 0.46);
	painted_color = mix(painted_color, dry_stone_color.rgb, pale_stone * 0.46);

	ALBEDO = painted_color;
	ROUGHNESS = 0.91 + painted_edge * 0.05 - cart_ruts * 0.035;
	SPECULAR = 0.08;
}
