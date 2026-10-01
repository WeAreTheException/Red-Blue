shader_type canvas_item;


uniform float hole_radius = 3.0;
uniform float hole_spacing = 9.0;
uniform float edge_smoothstep = 0.15;

instance uniform vec2 size = vec2(100.0, 100.0);
instance uniform vec2 center = vec2(0.0, 0.0);

varying vec2 local_position;


void vertex() {
	local_position = VERTEX;
}


float repeated_distance(
	float coordinate,
	float half_extent,
	float desired_spacing
) {
	float full_size = half_extent * 2.0;

	float segment_count = max(
		1.0,
		floor(full_size / desired_spacing + 0.5)
	);

	float spacing = full_size / segment_count;

	float local_coord =
		coordinate + half_extent;

	float repeated =
		mod(local_coord + spacing * 0.5, spacing)
		- spacing * 0.5;

	return abs(repeated);
}


float get_stamp_shape(vec2 point) {
	vec2 p = point - center;
	vec2 half_size = size * 0.5;

	float edge_distance = min(
		half_size.x - abs(p.x),
		half_size.y - abs(p.y)
	);

	float repeat_x = repeated_distance(
		p.x,
		half_size.x,
		hole_spacing
	);

	float vertical_edge =
		half_size.y - abs(p.y);

	float top_bottom_holes = length(
		vec2(
			repeat_x,
			vertical_edge
		)
	);

	float repeat_y = repeated_distance(
		p.y,
		half_size.y,
		hole_spacing
	);

	float horizontal_edge =
		half_size.x - abs(p.x);

	float left_right_holes = length(
		vec2(
			repeat_y,
			horizontal_edge
		)
	);

	float nearest_hole = min(
		top_bottom_holes,
		left_right_holes
	);

	float rectangle_alpha = smoothstep(
		-edge_smoothstep,
		edge_smoothstep,
		edge_distance
	);

	float holes_alpha = smoothstep(
		hole_radius - edge_smoothstep,
		hole_radius + edge_smoothstep,
		nearest_hole
	);

	return rectangle_alpha * holes_alpha;
}


void fragment() {
	float shape = get_stamp_shape(local_position);

	COLOR.a *= shape;
}