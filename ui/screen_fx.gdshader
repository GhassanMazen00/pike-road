shader_type canvas_item;
// Subtle film grain and vignette. Turned on/off from the pause menu (or F2).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float grain_strength : hint_range(0.0, 0.2) = 0.03;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p.yx + 19.19);
	return fract((p.x + p.y) * p.x);
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	// Grain changes 24 times a second, like film, and stays faint in deep black.
	float frame = floor(TIME * 24.0);
	float n = hash(FRAGCOORD.xy + frame * 17.31) - 0.5;
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col += n * grain_strength * (0.3 + luma);

	vec2 uv = SCREEN_UV - 0.5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float v = 1.0 - smoothstep(0.38, 0.95, length(uv));
	col *= mix(1.0 - vignette_strength, 1.0, v);

	COLOR = vec4(col, 1.0);
}
