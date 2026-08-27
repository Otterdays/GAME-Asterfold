shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.50, 0.24, 0.31, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = 0.9;
	ALPHA = opacity;
	ALPHA_HASH_SCALE = 1.0;
}
