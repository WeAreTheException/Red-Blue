shader_type canvas_item;

uniform vec2 rect_size = vec2(8.0, 8.0);
uniform float border_size = 1.0;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base_color = COLOR;

	vec2 border_uv = vec2(
		border_size / rect_size.x,
		border_size / rect_size.y
	);

	bool is_border =
		UV.x < border_uv.x ||
		UV.x > 1.0 - border_uv.x ||
		UV.y < border_uv.y ||
		UV.y > 1.0 - border_uv.y;

	if (is_border) {
		COLOR = border_color;
	} else {
		COLOR = base_color;
	}
}