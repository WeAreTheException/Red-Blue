extends Area2D
class_name Spring


const ACTION_JUMP: StringName = &"JUMP"


enum Direction {
	UP,
	LEFT,
	RIGHT
}


@export_group("References")

@export var bounce_point: Marker2D
@export var spring_top: Node2D
@export var spring_line: Line2D


@export_group("Spring")

@export var direction: Direction = Direction.UP

@export var super_bounce_on_jump: bool = true

@export var refill_dash: bool = true
@export var refill_stamina: bool = true

@export_range(
	0.0,
	0.2,
	0.005
)
var hitstop_time: float = 0.05


@export_group("Contact")

@export var contact_tolerance_px: float = 3.0

@export var snap_to_center: bool = true


@export_group("Programmer Animation")

@export var punch_distance: float = 6.0
@export var punch_time: float = 0.06

@export var settle_overshoot: float = 2.0
@export var settle_time: float = 0.08

@export var final_settle_time: float = 0.10


@export_group("Debug")

@export var print_debug: bool = false


var _top_start_position: Vector2 = (
	Vector2.ZERO
)

var _line_start_points: PackedVector2Array = (
	PackedVector2Array()
)

var _feedback_tween: Tween = null


var _player_inside: PlayerRoot = null

var _fired_for_current_overlap: bool = false


# During spring hitstop, JUMP input is buffered here.
var _waiting_for_bounce: bool = false
var _buffered_super_bounce: bool = false


func _ready() -> void:
	process_physics_priority = 100

	body_entered.connect(
		_on_body_entered
	)

	body_exited.connect(
		_on_body_exited
	)

	if spring_top != null:
		_top_start_position = (
			spring_top.position
		)

	if spring_line != null:
		_line_start_points = (
			spring_line.points.duplicate()
		)


func _input(
	event: InputEvent
) -> void:
	if not _waiting_for_bounce:
		return

	if not super_bounce_on_jump:
		return

	if event.is_action_pressed(
		ACTION_JUMP
	):
		_buffered_super_bounce = true


func _physics_process(
	_delta: float
) -> void:
	if _waiting_for_bounce:
		return

	if _fired_for_current_overlap:
		return

	if _player_inside == null:
		return

	if not is_instance_valid(
		_player_inside
	):
		_player_inside = null
		_fired_for_current_overlap = false

		return

	var player: PlayerRoot = (
		_player_inside
	)

	if player.movement == null:
		return

	if (
		player.movement.movement_state
		== null
	):
		return

	if (
		player.movement.player_bounce
		== null
	):
		return

	var state: PlayerMovementState = (
		player.movement.movement_state
	)

	var bounce: PlayerBounce = (
		player.movement.player_bounce
	)

	if not _can_activate(
		player,
		state,
		bounce
	):
		return

	_fired_for_current_overlap = true

	_begin_spring_activation(
		player,
		state,
		bounce
	)


func _process(
	_delta: float
) -> void:
	_update_line()


func _begin_spring_activation(
	player: PlayerRoot,
	state: PlayerMovementState,
	bounce: PlayerBounce
) -> void:
	_waiting_for_bounce = true

	# If JUMP is already held when contact happens,
	# the SuperBounce is already buffered.
	_buffered_super_bounce = (
		super_bounce_on_jump
		and bounce.WantsSuperBounce()
	)

	# Stop movement immediately during hitstop.
	state.Speed = Vector2.ZERO

	var previous_time_scale: float = (
		Engine.time_scale
	)

	if hitstop_time > 0.0:
		Engine.time_scale = 0.0

		await get_tree().create_timer(
			hitstop_time,
			true,
			false,
			true
		).timeout

		Engine.time_scale = (
			previous_time_scale
		)

	if not is_instance_valid(
		player
	):
		_waiting_for_bounce = false
		_buffered_super_bounce = false

		return

	if (
		_player_inside != player
		and not is_instance_valid(
			_player_inside
		)
	):
		_waiting_for_bounce = false
		_buffered_super_bounce = false

		return

	if snap_to_center:
		_snap_player_to_bounce_point(
			player
		)

	match direction:
		Direction.UP:
			if (
				super_bounce_on_jump
				and _buffered_super_bounce
			):
				bounce.SuperBounce(
					refill_dash,
					refill_stamina
				)

			else:
				bounce.Bounce(
					refill_dash,
					refill_stamina
				)

		Direction.LEFT:
			bounce.SideBounce(
				-1,
				refill_dash,
				refill_stamina
			)

		Direction.RIGHT:
			bounce.SideBounce(
				1,
				refill_dash,
				refill_stamina
			)

	_waiting_for_bounce = false
	_buffered_super_bounce = false

	_play_feedback()

	if print_debug:
		print(
			"SPRING | ",
			Direction.keys()[direction],
			" | SPEED: ",
			state.Speed,
			" | STATE: ",
			state.movement_phase
		)


func _on_body_entered(
	body: Node2D
) -> void:
	if not body is PlayerRoot:
		return

	_player_inside = (
		body as PlayerRoot
	)

	_fired_for_current_overlap = false


func _on_body_exited(
	body: Node2D
) -> void:
	if body != _player_inside:
		return

	_player_inside = null

	if not _waiting_for_bounce:
		_fired_for_current_overlap = false


func _can_activate(
	player: PlayerRoot,
	state: PlayerMovementState,
	bounce: PlayerBounce
) -> bool:
	match direction:
		Direction.UP:
			if bounce_point != null:
				var distance_from_surface: float = absf(
					player.global_position.y
					- bounce_point.global_position.y
				)

				if (
					distance_from_surface
					> contact_tolerance_px
				):
					return false

			if state.Speed.y < 0.0:
				if not (
					super_bounce_on_jump
					and bounce.WantsSuperBounce()
				):
					return false

		Direction.LEFT:
			if state.Speed.x < 0.0:
				return false

			if bounce_point != null:
				var distance_from_surface: float = absf(
					player.global_position.x
					- bounce_point.global_position.x
				)

				if (
					distance_from_surface
					> contact_tolerance_px
				):
					return false

		Direction.RIGHT:
			if state.Speed.x > 0.0:
				return false

			if bounce_point != null:
				var distance_from_surface: float = absf(
					player.global_position.x
					- bounce_point.global_position.x
				)

				if (
					distance_from_surface
					> contact_tolerance_px
				):
					return false

	return true


func _snap_player_to_bounce_point(
	player: PlayerRoot
) -> void:
	if bounce_point == null:
		return

	match direction:
		Direction.UP:
			player.global_position.y = (
				bounce_point.global_position.y
			)

		Direction.LEFT:
			player.global_position.x = (
				bounce_point.global_position.x
			)

		Direction.RIGHT:
			player.global_position.x = (
				bounce_point.global_position.x
			)


func _play_feedback() -> void:
	if spring_top == null:
		return

	if (
		_feedback_tween != null
		and _feedback_tween.is_valid()
	):
		_feedback_tween.kill()

	spring_top.position = (
		_top_start_position
	)

	var launch_direction: Vector2 = (
		_get_launch_direction()
	)

	_feedback_tween = (
		create_tween()
	)

	_feedback_tween.tween_property(
		spring_top,
		"position",
		_top_start_position
		+ launch_direction
		* punch_distance,
		punch_time
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	_feedback_tween.tween_property(
		spring_top,
		"position",
		_top_start_position
		- launch_direction
		* settle_overshoot,
		settle_time
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN_OUT
	)

	_feedback_tween.tween_property(
		spring_top,
		"position",
		_top_start_position,
		final_settle_time
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _update_line() -> void:
	if spring_top == null:
		return

	if spring_line == null:
		return

	if _line_start_points.size() < 2:
		return

	var points: PackedVector2Array = (
		_line_start_points.duplicate()
	)

	var top_offset: Vector2 = (
		spring_top.position
		- _top_start_position
	)

	points[0] += (
		top_offset
	)

	spring_line.points = (
		points
	)


func _get_launch_direction() -> Vector2:
	match direction:
		Direction.UP:
			return Vector2.UP

		Direction.LEFT:
			return Vector2.LEFT

		Direction.RIGHT:
			return Vector2.RIGHT

	return Vector2.UP
