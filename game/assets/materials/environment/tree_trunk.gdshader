shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Painted bark: broad vertical value bands plus a few analytic scuffs, matching the
// dirt-road language so trunks read at 640x360 without high-frequency normal detail.

uniform vec4 bark_shadow : source_color = vec4(0.16, 0.11, 0.08, 1.0);
uniform vec4 bark_base : source_color = vec4(0.30, 0.20, 0.14, 1.0);
uniform vec4 bark_light : source_color = vec4(0.44, 0.32, 0.21, 1.0);
uniform float band_scale : hint_range(1.0, 24.0) = 9.0;
uniform float scuff_scale : hint_range(0.5, 8.0) = 2.4;
uniform float scuff_strength : hint_range(0.0, 1.0) = 0.35;

varying vec3 local_position;
varying float instance_seed;


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
	local_position = VERTEX;
	vec3 instance_origin = MODEL_MATRIX[3].xyz;
	instance_seed = hash_2d(floor(instance_origin.xz * 4.0)) * 32.0;
}


void fragment() {
	float ring_angle = atan(local_position.z, local_position.x);
	vec2 bark_position = vec2(ring_angle * band_scale, local_position.y * band_scale) + instance_seed;
	float band_value = value_noise(bark_position);
	float scuff_value = value_noise(bark_position * scuff_scale + 5.0);

	vec3 painted_color = mix(bark_shadow.rgb, bark_base.rgb, smoothstep(0.20, 0.75, band_value));
	painted_color = mix(painted_color, bark_light.rgb, smoothstep(0.68, 0.95, scuff_value) * scuff_strength);

	ALBEDO = painted_color;
	ROUGHNESS = 0.96 - band_value * 0.05;
	SPECULAR = 0.08;
}
