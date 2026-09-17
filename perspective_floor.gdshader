shader_type canvas_item;
render_mode unshaded;

uniform float scroll_offset = 0.0;

uniform float horizon_y : hint_range(0.0, 1.0) = 0.50;
uniform float far_factor : hint_range(0.0, 1.0) = 0.08;
uniform float near_factor : hint_range(0.0, 2.0) = 1.0;
uniform float perspective_curve : hint_range(0.1, 4.0) = 1.45;

void fragment() {
	vec2 uv = UV;

	float floor_height = max(
		1.0 - horizon_y,
		0.0001
	);

	float depth = clamp(
		(uv.y - horizon_y) / floor_height,
		0.0,
		1.0
	);

	depth = pow(
		depth,
		perspective_curve
	);

	float perspective_amount = mix(
		far_factor,
		near_factor,
		depth
	);

	uv.x = fract(
		uv.x
		+ scroll_offset * perspective_amount
	);

	COLOR = texture(
		TEXTURE,
		uv
	);
}