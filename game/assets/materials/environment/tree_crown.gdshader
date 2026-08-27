shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, depth_prepass_alpha, cull_back;

// Painted crown shells. Value grouping carries the silhouette; `opacity` lets a hero
// crown fade when it blocks the camera without introducing a second material family.
// `sway_strength_m` is authored per grove and is driven to zero by reduced-motion.

uniform vec4 leaf_shadow : source_color = vec4(0.11, 0.20, 0.15, 1.0);
uniform vec4 leaf_base : source_color = vec4(0.20, 0.38, 0.26, 1.0);
uniform vec4 leaf_light : source_color = vec4(0.42, 0.55, 0.30, 1.0);
uniform vec4 accent_color : source_color = vec4(0.47, 0.22, 0.31, 1.0);
uniform float accent_amount : hint_range(0.0, 1.0) = 0.0;
uniform float blotch_scale : hint_range(0.1, 4.0) = 0.9;
uniform float detail_scale : hint_range(0.5, 8.0) = 2.6;
uniform float sway_strength_m : hint_range(0.0, 0.6) = 0.09;
uniform float sway_speed : hint_range(0.0, 3.0) = 0.7;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

varying vec3 crown_position;
varying float instance_seed;
varying float height_gradient;


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


void vertex() {
	vec3 instance_origin = MODEL_MATRIX[3].xyz;
	instance_seed = hash_2d(floor(instance_origin.xz * 4.0)) * 24.0;
	crown_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height_gradient = clamp(VERTEX.y * 0.5 + 0.5, 0.0, 1.0);
	float phase = TIME * sway_speed + instance_seed;
	float lean = sin(phase) * 0.65 + sin(phase * 1.7 + 1.3) * 0.35;
	VERTEX.x += lean * sway_strength_m * height_gradient;
	VERTEX.z += cos(phase * 0.9) * sway_strength_m * 0.6 * height_gradient;
}


void fragment() {
	vec2 blotch_position = crown_position.xz * blotch_scale + instance_seed;
	float blotch_value = value_noise(blotch_position) * 0.7 + value_noise(blotch_position * 2.1 + 9.0) * 0.3;
	float detail_value = value_noise(crown_position.xz * detail_scale + 3.0);
	float lit_amount = smoothstep(0.35, 0.95, height_gradient);

	vec3 painted_color = mix(leaf_shadow.rgb, leaf_base.rgb, smoothstep(0.15, 0.70, blotch_value));
	painted_color = mix(painted_color, leaf_light.rgb, lit_amount * 0.45);
	painted_color = mix(painted_color, leaf_light.rgb, smoothstep(0.72, 0.96, detail_value) * 0.20);
	float accent_mask = smoothstep(0.88, 0.99, hash_2d(floor(crown_position.xz * 3.0 + instance_seed)));
	painted_color = mix(painted_color, accent_color.rgb, accent_mask * accent_amount);

	ALBEDO = painted_color;
	ALPHA = opacity;
	ROUGHNESS = 0.95 - blotch_value * 0.05;
	SPECULAR = 0.06;
}
