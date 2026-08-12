shader_type canvas_item;

uniform float PIXEL_SIZE = 3.0;
uniform float OPACITY : hint_range(0.0, 1.0) = 0.12;

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;

	int x = int(UV.x * screen_size.x / PIXEL_SIZE);
	int y = int(UV.y * screen_size.y / PIXEL_SIZE);

	float alpha = 0.0;

	if (x % 3 == 0 || y % 3 == 0) {
		alpha = OPACITY;
	}

	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}