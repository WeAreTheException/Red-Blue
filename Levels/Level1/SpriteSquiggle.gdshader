shader_type canvas_item;
render_mode unshaded;


uniform float strength : hint_range(
	0.0,
	4.0,
	1.0
) = 1.0;


uniform float fps : hint_range(
	1.0,
	24.0,
	1.0
) = 6.0;


uniform float squiggle_size : hint_range(
	1.0,
	16.0,
	1.0
) = 4.0;


varying vec4 vertex_color;


void vertex() {
	vertex_color = COLOR;
}


float random_value(
	vec2 position
) {
	return fract(
		sin(
			dot(
				position,
				vec2(
					127.1,
					311.7
				)
			)
		)
		* 43758.5453
	);
}


void fragment() {
	vec2 texture_size = (
		1.0
		/ TEXTURE_PIXEL_SIZE
	);


	vec2 pixel_position = (
		UV
		* texture_size
	);


	float frame = floor(
		TIME
		* fps
	);


	float horizontal_noise = random_value(
		vec2(
			floor(
				pixel_position.y
				/ squiggle_size
			),
			frame * 17.0
		)
	);


	float vertical_noise = random_value(
		vec2(
			floor(
				pixel_position.x
				/ squiggle_size
			),
			frame * 31.0
		)
	);


	vec2 offset = vec2(
		horizontal_noise * 2.0 - 1.0,
		vertical_noise * 2.0 - 1.0
	);


	offset *= strength;


	// Keep movement locked to whole texture pixels.
	offset = round(offset);


	vec2 squiggle_uv = (
		UV
		+ offset
		* TEXTURE_PIXEL_SIZE
	);


	vec4 sprite_color = texture(
		TEXTURE,
		squiggle_uv
	);


	COLOR = (
		sprite_color
		* vertex_color
	);
}