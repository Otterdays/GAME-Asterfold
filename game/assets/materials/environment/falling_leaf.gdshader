shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled, depth_prepass_alpha;

// Painted leaf card for the drifting-leaf particles. The quad billboards toward the
// camera and spins around its own center so a falling leaf keeps flashing its face,
// then dissolves as it reaches the ground plane instead of popping out of existence.

uniform vec4 leaf_face : source_color = vec4(0.55, 0.51, 0.24, 1.0);
uniform vec4 leaf_edge : source_color = vec4(0.34, 0.30, 0.16, 1.0);
uniform vec4 leaf_vein : source_color = vec4(0.68, 0.62, 0.36, 1.0);
uniform float spin_speed : hint_range(0.0, 8.0) = 2.1;
uniform float leaf_slenderness : hint_range(0.2, 1.0) = 0.46;
// Leaves fade out across this height band above the ground so landings stay soft.
uniform float settle_height_m : hint_range(0.05, 4.0) = 0.9;

varying float leaf_height_m;


float hash_3d(vec3 value) {
	return fract(sin(dot(value, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}


void vertex() {
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	leaf_height_m = world_origin.y;
	float card_scale = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * card_scale,
		INV_VIEW_MATRIX[1] * card_scale,
		INV_VIEW_MATRIX[2] * card_scale,
		MODEL_MATRIX[3]
	);
	float spin = TIME * spin_speed + hash_3d(floor(world_origin * 8.0)) * TAU;
	float spin_sin = sin(spin);
	float spin_cos = cos(spin);
	VERTEX.xy = mat2(vec2(spin_cos, spin_sin), vec2(-spin_sin, spin_cos)) * VERTEX.xy;
	// A leaf turning edge-on should thin out rather than stay a full card.
	VERTEX.x *= mix(0.35, 1.0, abs(spin_cos));
}


void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float blade = length(vec2(centered.x / leaf_slenderness, centered.y));
	if (blade > 1.0) {
		discard;
	}
	float vein = smoothstep(0.16, 0.0, abs(centered.x));
	vec3 painted_color = mix(leaf_face.rgb, leaf_edge.rgb, smoothstep(0.55, 1.0, blade));
	painted_color = mix(painted_color, leaf_vein.rgb, vein * 0.45);

	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = painted_color;
	ALPHA = smoothstep(0.0, settle_height_m, leaf_height_m);
	ROUGHNESS = 0.95;
}
