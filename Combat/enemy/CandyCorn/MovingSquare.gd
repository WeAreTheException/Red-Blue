extends CharacterBody2D
class_name MovingSquare


@export_group("Movement")

@export var move_speed: float = 80.0

@export var horizontal_choice_distance: float = 64.0
@export var vertical_choice_distance: float = 28.0


@export_group("Collision Check")

@export var direction_check_distance: float = 2.0


@export_group("Decision Pause")

@export_range(0.0, 1.0, 0.05)
var pause_chance: float = 0.30

@export var pause_time_a: float = 0.12
@export var pause_time_b: float = 0.20

@export var pause_scale: float = 0.94
@export var pause_vibrate_px: int = 1


var move_direction: Vector2 = Vector2.ZERO

var distance_since_direction_change: float = 0.0

var choice_used: bool = false

var stopped: bool = false


var decision_paused: bool = false
var pause_time_left: float = 0.0


var visual_node_2d: Node2D
var visual_control: Control

var visual_original_position: Vector2 = Vector2.ZERO
var visual_original_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_find_visual()

	_choose_start_direction()


func _physics_process(delta: float) -> void:
	if stopped:
		return

	if decision_paused:
		_update_decision_pause(delta)
		return

	var previous_position: Vector2 = global_position

	var collision: KinematicCollision2D = move_and_collide(
		move_direction * move_speed * delta
	)

	var distance_moved: float = global_position.distance_to(
		previous_position
	)

	distance_since_direction_change += distance_moved

	if collision != null:
		_handle_collision()
		return

	if choice_used:
		return

	var choice_distance: float = _get_choice_distance()

	if distance_since_direction_change >= choice_distance:
		_reach_decision_point()


func _reach_decision_point() -> void:
	if not _has_meaningful_choice():
		_make_random_choice()
		return

	if randf() <= pause_chance:
		_start_decision_pause()
		return

	_make_random_choice()


func _has_meaningful_choice() -> bool:
	var available_count: int = 0

	var straight: Vector2 = move_direction

	var turn_a: Vector2 = Vector2(
		-move_direction.y,
		move_direction.x
	)

	var turn_b: Vector2 = Vector2(
		move_direction.y,
		-move_direction.x
	)

	if _can_move(straight):
		available_count += 1

	if _can_move(turn_a):
		available_count += 1

	if _can_move(turn_b):
		available_count += 1

	return available_count >= 2


func _find_visual() -> void:
	for child: Node in get_children():
		if child is Sprite2D:
			visual_node_2d = child as Node2D
			visual_original_position = visual_node_2d.position
			visual_original_scale = visual_node_2d.scale
			return

		if child is Polygon2D:
			visual_node_2d = child as Node2D
			visual_original_position = visual_node_2d.position
			visual_original_scale = visual_node_2d.scale
			return

		if child is ColorRect:
			visual_control = child as Control
			visual_original_position = visual_control.position
			visual_original_scale = visual_control.scale
			return


func _start_decision_pause() -> void:
	decision_paused = true

	if randi_range(0, 1) == 0:
		pause_time_left = pause_time_a
	else:
		pause_time_left = pause_time_b

	_set_visual_scale(
		visual_original_scale * pause_scale
	)


func _update_decision_pause(
	delta: float
) -> void:
	pause_time_left -= delta

	_update_pause_vibration()

	if pause_time_left > 0.0:
		return

	decision_paused = false

	_reset_visual()

	_make_random_choice()


func _update_pause_vibration() -> void:
	var vibration_offset: Vector2 = Vector2(
		randi_range(
			-pause_vibrate_px,
			pause_vibrate_px
		),
		randi_range(
			-pause_vibrate_px,
			pause_vibrate_px
		)
	)

	_set_visual_position(
		visual_original_position
		+ vibration_offset
	)


func _reset_visual() -> void:
	_set_visual_position(
		visual_original_position
	)

	_set_visual_scale(
		visual_original_scale
	)


func _set_visual_position(
	new_position: Vector2
) -> void:
	if visual_node_2d != null:
		visual_node_2d.position = new_position

	if visual_control != null:
		visual_control.position = new_position


func _set_visual_scale(
	new_scale: Vector2
) -> void:
	if visual_node_2d != null:
		visual_node_2d.scale = new_scale

	if visual_control != null:
		visual_control.scale = new_scale


func _choose_start_direction() -> void:
	var choices: Array[Vector2] = []

	if _can_move(Vector2.UP):
		choices.append(Vector2.UP)

	if _can_move(Vector2.RIGHT):
		choices.append(Vector2.RIGHT)

	if choices.is_empty():
		stopped = true
		return

	var choice_index: int = randi_range(
		0,
		choices.size() - 1
	)

	_set_direction(
		choices[choice_index]
	)


func _make_random_choice() -> void:
	var choices: Array[Vector2] = []

	var straight: Vector2 = move_direction

	var turn_a: Vector2 = Vector2(
		-move_direction.y,
		move_direction.x
	)

	var turn_b: Vector2 = Vector2(
		move_direction.y,
		-move_direction.x
	)

	if _can_move(straight):
		choices.append(straight)

	if _can_move(turn_a):
		choices.append(turn_a)

	if _can_move(turn_b):
		choices.append(turn_b)

	if choices.is_empty():
		stopped = true
		return

	var choice_index: int = randi_range(
		0,
		choices.size() - 1
	)

	var new_direction: Vector2 = choices[
		choice_index
	]

	if new_direction == move_direction:
		choice_used = true
		return

	_set_direction(
		new_direction
	)


func _handle_collision() -> void:
	var choices: Array[Vector2] = []

	var turn_a: Vector2 = Vector2(
		-move_direction.y,
		move_direction.x
	)

	var turn_b: Vector2 = Vector2(
		move_direction.y,
		-move_direction.x
	)

	if _can_move(turn_a):
		choices.append(turn_a)

	if _can_move(turn_b):
		choices.append(turn_b)

	if choices.is_empty():
		stopped = true
		return

	var choice_index: int = randi_range(
		0,
		choices.size() - 1
	)

	_set_direction(
		choices[choice_index]
	)


func _set_direction(
	new_direction: Vector2
) -> void:
	move_direction = new_direction

	distance_since_direction_change = 0.0
	choice_used = false


func _get_choice_distance() -> float:
	if move_direction.x != 0.0:
		return horizontal_choice_distance

	return vertical_choice_distance


func _can_move(
	direction: Vector2
) -> bool:
	var motion: Vector2 = (
		direction
		* direction_check_distance
	)

	return not test_move(
		global_transform,
		motion
	)
