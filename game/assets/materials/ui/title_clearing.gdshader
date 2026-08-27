shader_type canvas_item;
render_mode unshaded, blend_mix;

// Static painted clearing for the title shell. No TIME: reduced-motion safe.
// Authored for 640x360 canvas_items stretch: large soft shapes only. High-frequency
// value noise and hard step() edges turn into blocky clusters when nearest-upscaled.


float hash_2d(vec2 value) {
	return fract(sin(dot(value, vec2(127.1, 311.7))) * 43758.5453);
}


float soft_ellipse(vec2 uv, vec2 center, vec2 radius) {
	vec2 delta = (uv - center) / radius;
	return 1.0 - smoothstep(0.72, 1.0, length(delta));
}


float soft_trunk(vec2 uv, float x, float top, float bottom, float half_width) {
	float fade_y = smoothstep(top, top + 0.08, uv.y) * (1.0 - smoothstep(bottom - 0.10, bottom, uv.y));
	float column = 1.0 - smoothstep(half_width * 0.40, half_width, abs(uv.x - x));
	return column * fade_y;
}


void fragment() {
	vec2 uv = UV;
	float from_center = abs(uv.x - 0.5);
	float open_center = 1.0 - smoothstep(0.14, 0.48, from_center);

	vec3 sky_top = vec3(0.58, 0.74, 0.78);
	vec3 sky_open = vec3(0.86, 0.88, 0.76);
	vec3 grass_lit = vec3(0.48, 0.58, 0.32);
	vec3 grass_shade = vec3(0.22, 0.34, 0.20);
	vec3 canopy = vec3(0.12, 0.22, 0.14);
	vec3 canopy_deep = vec3(0.07, 0.13, 0.09);
	vec3 bark = vec3(0.24, 0.18, 0.12);

	float horizon = 0.42;
	float sky_blend = 1.0 - smoothstep(horizon - 0.10, horizon + 0.06, uv.y);
	vec3 color = mix(grass_shade, grass_lit, open_center * (1.0 - smoothstep(horizon, 1.0, uv.y) * 0.35));
	color = mix(color, mix(sky_top, sky_open, clamp(uv.y / horizon, 0.0, 1.0)), sky_blend);

	float sun = 1.0 - smoothstep(0.08, 0.28, distance(uv, vec2(0.50, 0.18)));
	color = mix(color, vec3(0.96, 0.94, 0.80), sun * 0.28 * open_center * sky_blend);

	float grove = 0.0;
	grove = max(grove, soft_ellipse(uv, vec2(0.00, 0.38), vec2(0.28, 0.42)));
	grove = max(grove, soft_ellipse(uv, vec2(0.10, 0.28), vec2(0.22, 0.36)));
	grove = max(grove, soft_ellipse(uv, vec2(0.18, 0.46), vec2(0.16, 0.28)));
	grove = max(grove, soft_ellipse(uv, vec2(1.00, 0.38), vec2(0.28, 0.42)));
	grove = max(grove, soft_ellipse(uv, vec2(0.90, 0.28), vec2(0.22, 0.36)));
	grove = max(grove, soft_ellipse(uv, vec2(0.82, 0.46), vec2(0.16, 0.28)));
	color = mix(color, canopy, grove * 0.88);

	float overhang = 0.0;
	overhang = max(overhang, soft_ellipse(uv, vec2(0.08, -0.04), vec2(0.42, 0.28)));
	overhang = max(overhang, soft_ellipse(uv, vec2(0.92, -0.04), vec2(0.42, 0.28)));
	color = mix(color, canopy_deep, overhang * 0.70);

	float trunks = 0.0;
	trunks = max(trunks, soft_trunk(uv, 0.07, 0.22, 0.82, 0.018));
	trunks = max(trunks, soft_trunk(uv, 0.13, 0.26, 0.74, 0.014));
	trunks = max(trunks, soft_trunk(uv, 0.93, 0.22, 0.80, 0.018));
	trunks = max(trunks, soft_trunk(uv, 0.86, 0.28, 0.72, 0.014));
	color = mix(color, bark, trunks * 0.55);

	float ground_shade = smoothstep(0.22, 0.55, from_center) * smoothstep(0.55, 1.0, uv.y);
	color = mix(color, canopy_deep, ground_shade * 0.22);

	float dither = (hash_2d(floor(FRAGCOORD.xy)) - 0.5) * (1.5 / 255.0);
	color += dither;

	COLOR = vec4(color, 1.0);
}
