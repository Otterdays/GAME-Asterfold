shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled, depth_prepass_alpha, shadows_disabled;

// One painted card shared by both footfall surfaces. `blade_shape` squashes the soft
// dust puff into an upright grass sliver, so dirt and grass stay one shader family
// with two authored materials instead of two near-identical shaders.

uniform vec4 mote_core : source_color = vec4(0.72, 0.62, 0.47, 1.0);
uniform vec4 mote_edge : source_color = vec4(0.52, 0.44, 0.33, 1.0);
uniform float mote_opacity : hint_range(0.0, 1.0) = 0.55;
uniform float blade_shape : hint_range(0.0, 1.0) = 0.0;
// Motes fade out across this height band so a stride leaves no hard-edged residue.
uniform float settle_height_m : hint_range(0.05, 3.0) = 0.55;

varying float mote_height_m;


void vertex() {
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	mote_height_m = world_origin.y;
	float card_scale = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * card_scale,
		INV_VIEW_MATRIX[1] * card_scale,
		INV_VIEW_MATRIX[2] * card_scale,
		MODEL_MATRIX[3]
	);
	VERTEX.x *= mix(1.0, 0.22, blade_shape);
	VERTEX.y *= mix(1.0, 1.65, blade_shape);
}


void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float radial = length(centered);
	if (radial > 1.0) {
		discard;
	}
	vec3 painted_color = mix(mote_core.rgb, mote_edge.rgb, smoothstep(0.1, 1.0, radial));

	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = painted_color;
	ALPHA = mote_opacity * smoothstep(1.0, 0.35, radial) * smoothstep(settle_height_m, 0.0, mote_height_m);
	ROUGHNESS = 1.0;
}
