shader_type canvas_item;

uniform sampler2D circle_texture : filter_nearest, repeat_disable;

uniform vec4 dot_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float tile_size = 8.0;

uniform vec2 offset = vec2(0.0, 0.0);

varying vec2 local_pixel_position;


void vertex()
{
	local_pixel_position = VERTEX;
}


void fragment()
{
	vec4 base_color = COLOR;

	vec2 tile_position =
		(local_pixel_position + offset) / tile_size;

	vec2 circle_uv = fract(tile_position);

	float circle_mask =
		texture(circle_texture, circle_uv).a;

	COLOR = mix(
		base_color,
		vec4(dot_color.rgb, base_color.a * dot_color.a),
		circle_mask * dot_color.a
	);
}