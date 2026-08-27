shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 grass_shadow : source_color = vec4(0.16, 0.25, 0.16, 1.0);
uniform vec4 grass_base : source_color = vec4(0.27, 0.38, 0.22, 1.0);
uniform vec4 grass_light : source_color = vec4(0.39, 0.49, 0.27, 1.0);
uniform float broad_scale : hint_range(0.05, 0.5) = 0.13;
uniform float detail_scale : hint_range(0.25, 3.0) = 0.85;

varying vec3 world_position;


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


float layered_noise(vec2 value) {
	return value_noise(value) * 0.65 + value_noise(value * 2.07 + 13.4) * 0.35;
}


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec2 surface_position = world_position.xz;
	float broad_value = layered_noise(surface_position * broad_scale);
	float tuft_value = value_noise(surface_position * detail_scale + 7.0);
	float sparse_blade = smoothstep(0.86, 0.97, hash_2d(floor(surface_position * 2.0)));

	vec3 painted_color = mix(grass_shadow.rgb, grass_base.rgb, smoothstep(0.18, 0.72, broad_value));
	painted_color = mix(painted_color, grass_light.rgb, smoothstep(0.60, 0.92, tuft_value) * 0.30);
	painted_color = mix(painted_color, grass_light.rgb, sparse_blade * 0.16);

	ALBEDO = painted_color;
	ROUGHNESS = 0.94 - broad_value * 0.04;
	SPECULAR = 0.10;
}
