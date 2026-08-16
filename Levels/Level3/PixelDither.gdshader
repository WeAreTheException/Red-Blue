shader_type canvas_item;
render_mode unshaded;


uniform vec4 dither_color : source_color = vec4(
	0.0,
	0.0,
	0.0,
	1.0
);

uniform float dither_amount : hint_range(
	0.0,
	1.0,
	0.01
) = 0.65;

uniform float darkness_influence : hint_range(
	0.0,
	1.0,
	0.01
) = 1.0;

uniform float base_coverage : hint_range(
	0.0,
	1.0,
	0.01
) = 0.0;

uniform float pixel_size : hint_range(
	1.0,
	16.0,
	1.0
) = 1.0;


varying vec2 local_position;


void vertex() {
	local_position = VERTEX;
}


float bayer_4x4(
	vec2 position
) {
	vec2 cell = mod(
		floor(position),
		4.0
	);

	float x = cell.x;
	float y = cell.y;


	if (y < 1.0) {
		if (x < 1.0) return 0.0 / 16.0;
		if (x < 2.0) return 8.0 / 16.0;
		if (x < 3.0) return 2.0 / 16.0;

		return 10.0 / 16.0;
	}


	if (y < 2.0) {
		if (x < 1.0) return 12.0 / 16.0;
		if (x < 2.0) return 4.0 / 16.0;
		if (x < 3.0) return 14.0 / 16.0;

		return 6.0 / 16.0;
	}


	if (y < 3.0) {
		if (x < 1.0) return 3.0 / 16.0;
		if (x < 2.0) return 11.0 / 16.0;
		if (x < 3.0) return 1.0 / 16.0;

		return 9.0 / 16.0;
	}


	if (x < 1.0) return 15.0 / 16.0;
	if (x < 2.0) return 7.0 / 16.0;
	if (x < 3.0) return 13.0 / 16.0;

	return 5.0 / 16.0;
}


void fragment() {
	vec4 source = COLOR;


	float luminance = dot(
		source.rgb,
		vec3(
			0.299,
			0.587,
			0.114
		)
	);


	float darkness = 1.0 - luminance;


	float coverage = mix(
		base_coverage,
		darkness,
		darkness_influence
	);


	coverage *= dither_amount;


	vec2 pixel_position = floor(
		local_position / pixel_size
	);


	float threshold = bayer_4x4(
		pixel_position
	);


	float dither = step(
		threshold,
		coverage
	);


	vec3 final_color = mix(
		source.rgb,
		dither_color.rgb,
		dither * dither_color.a
	);


	COLOR = vec4(
		final_color,
		source.a
	);
}