shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;

// Painted ambient bird. The mesh is one flat baseline body shared by every species:
// UV.x tags the part (body, head, beak, wing, tail) and UV.y carries the outboard
// fraction, so a variant species is a palette and a few ratios rather than new
// geometry. The wing beat happens in the vertex stage because the body is flat:
// vertices lift with their distance from the spine, so the outer wing swings furthest
// and the span shortens on the downstroke. `flap_strength` is driven to zero by
// reduced camera motion.

uniform vec4 body_color : source_color = vec4(0.24, 0.19, 0.17, 1.0);
uniform vec4 belly_color : source_color = vec4(0.79, 0.68, 0.50, 1.0);
uniform vec4 head_color : source_color = vec4(0.19, 0.15, 0.14, 1.0);
uniform vec4 beak_color : source_color = vec4(0.86, 0.72, 0.35, 1.0);
uniform vec4 wing_color : source_color = vec4(0.42, 0.33, 0.26, 1.0);
uniform vec4 wingtip_color : source_color = vec4(0.20, 0.16, 0.15, 1.0);
uniform vec4 tail_color : source_color = vec4(0.31, 0.25, 0.21, 1.0);
uniform float flap_hz : hint_range(0.0, 12.0) = 4.2;
uniform float flap_strength : hint_range(0.0, 1.2) = 0.55;
uniform float half_span_m : hint_range(0.02, 1.0) = 0.26;

varying float part_tag;
varying float outboard;
varying float spine_factor;


void vertex() {
	// Instance custom data carries the per-bird flap phase so a flock never beats in unison.
	float phase = TIME * flap_hz * TAU + INSTANCE_CUSTOM.x * TAU;
	float beat = sin(phase);
	part_tag = UV.x;
	outboard = clamp(UV.y, 0.0, 1.0);
	spine_factor = clamp(VERTEX.z / half_span_m * 0.5 + 0.5, 0.0, 1.0);
	VERTEX.y += beat * flap_strength * outboard * outboard * half_span_m;
	VERTEX.x *= mix(1.0, 0.82, abs(beat) * flap_strength);
}


void fragment() {
	vec3 painted_color = mix(body_color.rgb, belly_color.rgb, smoothstep(0.35, 0.9, spine_factor));
	if (part_tag > 3.5) {
		painted_color = tail_color.rgb;
	} else if (part_tag > 2.5) {
		painted_color = mix(wing_color.rgb, wingtip_color.rgb, smoothstep(0.45, 1.0, outboard));
	} else if (part_tag > 1.5) {
		painted_color = beak_color.rgb;
	} else if (part_tag > 0.5) {
		painted_color = head_color.rgb;
	}

	// The body is a single flat sheet, so the underside needs a flipped normal to stay lit.
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = painted_color;
	ROUGHNESS = 0.85;
	SPECULAR = 0.05;
}
