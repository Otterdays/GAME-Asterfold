shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 dirt_shadow : source_color = vec4(0.32, 0.22, 0.13, 1.0);
uniform vec4 dirt_base : source_color = vec4(0.58, 0.43, 0.25, 1.0);
uniform vec4 dirt_light : source_color = vec4(0.71, 0.56, 0.34, 1.0);
uniform vec4 pebble_color : source_color = vec4(0.42, 0.38, 0.31, 1.0);
uniform float broad_scale : hint_range(0.05, 0.5) = 0.16;
uniform float detail_scale : hint_range(0.25, 4.0) = 1.2;

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


void vertex() {
	local_position = VERTEX;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	vec2 surface_position = world_position.xz;
	float broad_value = value_noise(surface_position * broad_scale);
	float worn_value = value_noise(surface_position * detail_scale + 19.0);
	vec2 edge_distance = vec2(0.5) - abs(local_position.xz);
	float nearest_edge = min(edge_distance.x, edge_distance.y);
	float painted_edge = 1.0 - smoothstep(0.015, 0.10, nearest_edge + (broad_value - 0.5) * 0.025);
	float pebble = smoothstep(0.94, 0.985, hash_2d(floor(surface_position * 2.4)));

	vec3 painted_color = mix(dirt_shadow.rgb, dirt_base.rgb, smoothstep(0.10, 0.76, broad_value));
	painted_color = mix(painted_color, dirt_light.rgb, smoothstep(0.58, 0.90, worn_value) * 0.24);
	painted_color = mix(painted_color, dirt_shadow.rgb, painted_edge * 0.30);
	painted_color = mix(painted_color, pebble_color.rgb, pebble * 0.42);

	ALBEDO = painted_color;
	ROUGHNESS = 0.91 + painted_edge * 0.05;
	SPECULAR = 0.08;
}
