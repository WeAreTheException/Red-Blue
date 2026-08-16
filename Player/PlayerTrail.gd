extends Node2D
class_name PlayerTrail


@export_group("Trail")

@export var trail_template: Line2D

@export var trail_lifetime: float = 0.25
@export var max_points: int = 20
@export var minimum_point_distance: float = 1.0

@export var trail_color: Color = Color.WHITE


@export_group("Dash Pixels")

@export var pixel_template: Sprite2D

@export_range(
	1,
	20,
	1
)
var pixels_per_dash: int = 5

@export var pixel_lifetime: float = 0.25

@export var pixel_position_randomness: Vector2 = Vector2(
	3.0,
	3.0
)


@export_group("Afterimage")

@export var afterimage_template: ColorRect

@export_range(
	1,
	20,
	1
)
var images_per_dash: int = 4

@export var afterimage_lifetime: float = 0.25


@export_group("Dash End Animation")

@export var dash_end_animation_template: AnimatedSprite2D

@export var dash_end_animation_offset: Vector2 = Vector2.ZERO


var player: PlayerRoot = null

var _emission_offset: Vector2 = Vector2.ZERO
var _last_point: Vector2 = Vector2.ZERO

var _dash_trail_active: bool = false
var _dash_trail_timer: float = 0.0

var _active_line: Line2D = null

var _trail_lines: Array[Line2D] = []
var _trail_ages: Array[Array] = []


var _dash_pixels: Array[Sprite2D] = []
var _dash_pixel_ages: Array[float] = []

var _pixels_emitted_this_dash: int = 0
var _pixel_emit_timer: float = 0.0


var _afterimages: Array[ColorRect] = []
var _afterimage_ages: Array[float] = []

var _images_emitted_this_dash: int = 0
var _afterimage_emit_timer: float = 0.0


func _ready() -> void:
	player = get_parent() as PlayerRoot

	if player == null:
		push_error(
			"PlayerTrail must be a direct child of PlayerRoot."
		)
		return

	if trail_template == null:
		push_error(
			"PlayerTrail has no TrailTemplate assigned."
		)
		return

	_emission_offset = position

	trail_template.visible = false

	if pixel_template != null:
		pixel_template.visible = false

	if dash_end_animation_template != null:
		dash_end_animation_template.visible = false

	set_as_top_level(
		true
	)

	global_position = Vector2.ZERO
	global_rotation = 0.0
	global_scale = Vector2.ONE

	_last_point = (
		player.global_transform
		* _emission_offset
	)

	PlayerEvents.dashed.connect(
		_on_dashed
	)

	PlayerEvents.movement_state_changed.connect(
		_on_movement_state_changed
	)

	PlayerEvents.player_died.connect(
		_on_player_died
	)

	PlayerEvents.player_respawned.connect(
		_on_player_respawned
	)


func _physics_process(
	delta: float
) -> void:
	if player == null:
		return

	_age_trails(
		delta
	)

	_age_dash_pixels(
		delta
	)

	_age_afterimages(
		delta
	)

	if _dash_trail_active:
		_add_active_point()

		_update_dash_pixel_emission(
			delta
		)

		_update_afterimage_emission(
			delta
		)

		_dash_trail_timer -= delta

		if _dash_trail_timer <= 0.0:
			_end_active_dash()

	_remove_expired_points()
	_remove_expired_dash_pixels()
	_remove_expired_afterimages()

	_update_gradients()
	_remove_empty_trails()


func _on_dashed(
	event_player: PlayerRoot
) -> void:
	if event_player != player:
		return

	_end_active_dash()

	if afterimage_template != null:
		afterimage_template.visible = false

	_create_dash_trail()

	_dash_trail_active = true
	_dash_trail_timer = player.DashTime

	_last_point = (
		player.global_transform
		* _emission_offset
	)

	_active_line.add_point(
		_last_point
	)

	var ages: Array = (
		_trail_ages[
			_trail_ages.size() - 1
		]
	)

	ages.append(
		0.0
	)

	_pixels_emitted_this_dash = 0
	_pixel_emit_timer = 0.0

	_images_emitted_this_dash = 0
	_afterimage_emit_timer = 0.0

	_emit_dash_pixel()
	_emit_afterimage()


func _create_dash_trail() -> void:
	var new_line := (
		trail_template.duplicate()
		as Line2D
	)

	if new_line == null:
		return

	new_line.visible = true

	new_line.clear_points()

	add_child(
		new_line
	)

	_trail_lines.append(
		new_line
	)

	_trail_ages.append(
		[]
	)

	_active_line = new_line


func _on_movement_state_changed(
	event_player: PlayerRoot,
	state_name: StringName
) -> void:
	if event_player != player:
		return

	if not _dash_trail_active:
		return

	if state_name == &"DASH":
		return

	_end_active_dash()


func _end_active_dash() -> void:
	var dash_was_active: bool = (
		_dash_trail_active
	)

	_dash_trail_active = false
	_dash_trail_timer = 0.0
	_active_line = null

	_pixel_emit_timer = 0.0
	_afterimage_emit_timer = 0.0

	if dash_was_active:
		if afterimage_template != null:
			afterimage_template.visible = true

		_play_dash_end_animation()


func _play_dash_end_animation() -> void:
	if dash_end_animation_template == null:
		return

	var new_animation := (
		dash_end_animation_template.duplicate()
		as AnimatedSprite2D
	)

	if new_animation == null:
		return

	new_animation.visible = true

	add_child(
		new_animation
	)

	new_animation.position = (
		player.global_transform
		* _emission_offset
	) + dash_end_animation_offset

	new_animation.stop()

	new_animation.animation_finished.connect(
		new_animation.queue_free,
		CONNECT_ONE_SHOT
	)

	new_animation.play()


func _add_active_point() -> void:
	if _active_line == null:
		return

	var current_position: Vector2 = (
		player.global_transform
		* _emission_offset
	)

	if (
		current_position.distance_to(
			_last_point
		)
		< minimum_point_distance
	):
		return

	_active_line.add_point(
		current_position
	)

	var line_index: int = (
		_trail_lines.find(
			_active_line
		)
	)

	if line_index < 0:
		return

	var ages: Array = (
		_trail_ages[
			line_index
		]
	)

	ages.append(
		0.0
	)

	_last_point = current_position

	while (
		_active_line.get_point_count()
		> max_points
	):
		_active_line.remove_point(
			0
		)

		ages.remove_at(
			0
		)


func _update_dash_pixel_emission(
	delta: float
) -> void:
	if pixel_template == null:
		return

	if pixels_per_dash <= 1:
		return

	if _pixels_emitted_this_dash >= pixels_per_dash:
		return

	if player.DashTime <= 0.0:
		return

	var emit_interval: float = (
		player.DashTime
		/ float(
			pixels_per_dash - 1
		)
	)

	_pixel_emit_timer += delta

	while (
		_pixel_emit_timer >= emit_interval
		and _pixels_emitted_this_dash < pixels_per_dash
	):
		_pixel_emit_timer -= emit_interval

		_emit_dash_pixel()


func _emit_dash_pixel() -> void:
	if pixel_template == null:
		return

	if _pixels_emitted_this_dash >= pixels_per_dash:
		return

	var new_pixel := (
		pixel_template.duplicate()
		as Sprite2D
	)

	if new_pixel == null:
		return

	new_pixel.visible = true

	add_child(
		new_pixel
	)

	var random_offset := Vector2(
		roundf(
			randf_range(
				-pixel_position_randomness.x,
				pixel_position_randomness.x
			)
		),
		roundf(
			randf_range(
				-pixel_position_randomness.y,
				pixel_position_randomness.y
			)
		)
	)

	new_pixel.position = (
		player.global_transform
		* _emission_offset
	) + random_offset

	_dash_pixels.append(
		new_pixel
	)

	_dash_pixel_ages.append(
		0.0
	)

	_pixels_emitted_this_dash += 1


func _update_afterimage_emission(
	delta: float
) -> void:
	if afterimage_template == null:
		return

	if images_per_dash <= 1:
		return

	if _images_emitted_this_dash >= images_per_dash:
		return

	if player.DashTime <= 0.0:
		return

	var emit_interval: float = (
		player.DashTime
		/ float(
			images_per_dash - 1
		)
	)

	_afterimage_emit_timer += delta

	while (
		_afterimage_emit_timer >= emit_interval
		and _images_emitted_this_dash < images_per_dash
	):
		_afterimage_emit_timer -= emit_interval

		_emit_afterimage()


func _emit_afterimage() -> void:
	if afterimage_template == null:
		return

	if _images_emitted_this_dash >= images_per_dash:
		return

	var new_afterimage := (
		afterimage_template.duplicate()
		as ColorRect
	)

	if new_afterimage == null:
		return

	new_afterimage.visible = true

	add_child(
		new_afterimage
	)

	new_afterimage.position = (
		afterimage_template.global_position
	)

	new_afterimage.rotation = (
		afterimage_template.rotation
	)

	new_afterimage.scale = (
		afterimage_template.scale
	)

	_afterimages.append(
		new_afterimage
	)

	_afterimage_ages.append(
		0.0
	)

	_images_emitted_this_dash += 1


func _age_dash_pixels(
	delta: float
) -> void:
	for i in range(
		_dash_pixel_ages.size()
	):
		_dash_pixel_ages[i] += delta

		var pixel: Sprite2D = (
			_dash_pixels[i]
		)

		if pixel == null:
			continue

		if pixel_lifetime <= 0.0:
			pixel.modulate.a = 0.0
			continue

		pixel.modulate.a = (
			1.0
			- clampf(
				_dash_pixel_ages[i]
				/ pixel_lifetime,
				0.0,
				1.0
			)
		)


func _age_afterimages(
	delta: float
) -> void:
	for i in range(
		_afterimage_ages.size()
	):
		_afterimage_ages[i] += delta

		var afterimage: ColorRect = (
			_afterimages[i]
		)

		if afterimage == null:
			continue

		if afterimage_lifetime <= 0.0:
			afterimage.modulate.a = 0.0
			continue

		afterimage.modulate.a = (
			1.0
			- clampf(
				_afterimage_ages[i]
				/ afterimage_lifetime,
				0.0,
				1.0
			)
		)


func _remove_expired_dash_pixels() -> void:
	for i in range(
		_dash_pixels.size() - 1,
		-1,
		-1
	):
		if (
			_dash_pixel_ages[i]
			< pixel_lifetime
		):
			continue

		var pixel: Sprite2D = (
			_dash_pixels[i]
		)

		if pixel != null:
			pixel.queue_free()

		_dash_pixels.remove_at(
			i
		)

		_dash_pixel_ages.remove_at(
			i
		)


func _remove_expired_afterimages() -> void:
	for i in range(
		_afterimages.size() - 1,
		-1,
		-1
	):
		if (
			_afterimage_ages[i]
			< afterimage_lifetime
		):
			continue

		var afterimage: ColorRect = (
			_afterimages[i]
		)

		if afterimage != null:
			afterimage.queue_free()

		_afterimages.remove_at(
			i
		)

		_afterimage_ages.remove_at(
			i
		)


func _age_trails(
	delta: float
) -> void:
	for ages in _trail_ages:
		for i in range(
			ages.size()
		):
			ages[i] += delta


func _remove_expired_points() -> void:
	for line_index in range(
		_trail_lines.size()
	):
		var line: Line2D = (
			_trail_lines[
				line_index
			]
		)

		var ages: Array = (
			_trail_ages[
				line_index
			]
		)

		while (
			not ages.is_empty()
			and ages[0] >= trail_lifetime
		):
			if line.get_point_count() > 0:
				line.remove_point(
					0
				)

			ages.remove_at(
				0
			)


func _update_gradients() -> void:
	for line_index in range(
		_trail_lines.size()
	):
		_update_line_gradient(
			_trail_lines[
				line_index
			],
			_trail_ages[
				line_index
			]
		)


func _update_line_gradient(
	line: Line2D,
	ages: Array
) -> void:
	var new_gradient := Gradient.new()

	var point_count: int = (
		line.get_point_count()
	)

	if point_count == 0:
		var transparent_color := trail_color

		transparent_color.a = 0.0

		new_gradient.set_color(
			0,
			transparent_color
		)

		new_gradient.set_color(
			1,
			transparent_color
		)

		line.gradient = new_gradient

		return

	if point_count == 1:
		var single_color := trail_color

		single_color.a *= (
			_get_alpha(
				ages,
				0
			)
		)

		new_gradient.set_color(
			0,
			single_color
		)

		new_gradient.set_color(
			1,
			single_color
		)

		line.gradient = new_gradient

		return

	var total_length: float = 0.0

	for i in range(
		1,
		point_count
	):
		total_length += (
			line.get_point_position(
				i
			).distance_to(
				line.get_point_position(
					i - 1
				)
			)
		)

	var first_color := trail_color

	first_color.a *= (
		_get_alpha(
			ages,
			0
		)
	)

	new_gradient.set_offset(
		0,
		0.0
	)

	new_gradient.set_color(
		0,
		first_color
	)

	var last_color := trail_color

	last_color.a *= (
		_get_alpha(
			ages,
			point_count - 1
		)
	)

	new_gradient.set_offset(
		1,
		1.0
	)

	new_gradient.set_color(
		1,
		last_color
	)

	var distance_so_far: float = 0.0

	for i in range(
		1,
		point_count - 1
	):
		distance_so_far += (
			line.get_point_position(
				i
			).distance_to(
				line.get_point_position(
					i - 1
				)
			)
		)

		var offset: float = 0.0

		if total_length > 0.0:
			offset = (
				distance_so_far
				/ total_length
			)

		var point_color := trail_color

		point_color.a *= (
			_get_alpha(
				ages,
				i
			)
		)

		new_gradient.add_point(
			offset,
			point_color
		)

	line.gradient = new_gradient


func _get_alpha(
	ages: Array,
	index: int
) -> float:
	if index < 0:
		return 0.0

	if index >= ages.size():
		return 0.0

	if trail_lifetime <= 0.0:
		return 0.0

	return (
		1.0
		- clampf(
			float(
				ages[index]
			)
			/ trail_lifetime,
			0.0,
			1.0
		)
	)


func _remove_empty_trails() -> void:
	for i in range(
		_trail_lines.size() - 1,
		-1,
		-1
	):
		var line: Line2D = (
			_trail_lines[
				i
			]
		)

		if line == _active_line:
			continue

		if line.get_point_count() > 0:
			continue

		line.queue_free()

		_trail_lines.remove_at(
			i
		)

		_trail_ages.remove_at(
			i
		)


func _on_player_died(
	event_player: PlayerRoot
) -> void:
	if event_player != player:
		return

	_clear_all_trails()


func _on_player_respawned(
	event_player: PlayerRoot
) -> void:
	if event_player != player:
		return

	_clear_all_trails()

	if afterimage_template != null:
		afterimage_template.visible = true

	_last_point = (
		player.global_transform
		* _emission_offset
	)


func _clear_all_trails() -> void:
	_dash_trail_active = false
	_dash_trail_timer = 0.0
	_active_line = null

	_pixels_emitted_this_dash = 0
	_pixel_emit_timer = 0.0

	_images_emitted_this_dash = 0
	_afterimage_emit_timer = 0.0

	for line in _trail_lines:
		if line != null:
			line.queue_free()

	_trail_lines.clear()
	_trail_ages.clear()

	for pixel in _dash_pixels:
		if pixel != null:
			pixel.queue_free()

	_dash_pixels.clear()
	_dash_pixel_ages.clear()

	for afterimage in _afterimages:
		if afterimage != null:
			afterimage.queue_free()

	_afterimages.clear()
	_afterimage_ages.clear()
