extends Node2D
class_name PlayerTrail


@export_group("Trail")

@export var trail_template: Line2D

@export var trail_lifetime: float = 0.25
@export var max_points: int = 20
@export var minimum_point_distance: float = 1.0

@export var trail_color: Color = Color.WHITE


var player: PlayerRoot = null

var _emission_offset: Vector2 = Vector2.ZERO
var _last_point: Vector2 = Vector2.ZERO

var _dash_trail_active: bool = false
var _dash_trail_timer: float = 0.0

var _active_line: Line2D = null

var _trail_lines: Array[Line2D] = []
var _trail_ages: Array[Array] = []


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

	if _dash_trail_active:
		_add_active_point()

		_dash_trail_timer -= delta

		if _dash_trail_timer <= 0.0:
			_end_active_dash()

	_remove_expired_points()
	_update_gradients()
	_remove_empty_trails()


func _on_dashed(
	event_player: PlayerRoot
) -> void:
	if event_player != player:
		return

	_end_active_dash()

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
	_dash_trail_active = false
	_dash_trail_timer = 0.0
	_active_line = null


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

	_last_point = (
		player.global_transform
		* _emission_offset
	)


func _clear_all_trails() -> void:
	_dash_trail_active = false
	_dash_trail_timer = 0.0
	_active_line = null

	for line in _trail_lines:
		if line != null:
			line.queue_free()

	_trail_lines.clear()
	_trail_ages.clear()
