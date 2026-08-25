extends Area2D
class_name Spring


enum Direction {
	UP,
	LEFT,
	RIGHT
}


const ACTION_JUMP: StringName = &"JUMP"


@export_group("References")

@export var bounce_point: Marker2D
@export var spring_top: Node2D
@export var spring_line: Line2D


@export_group("Spring")

@export var direction: Direction = Direction.UP

@export var snap_to_center: bool = true

@export var bounce_speed: float = -185.0

@export var horizontal_bounce_speed: float = 240.0
@export var side_vertical_bounce_speed: float = -140.0

@export var bounce_var_jump_time: float = 0.2
@export var auto_jump_time: float = 0.1

@export var horizontal_force_time: float = 0.3

@export var refill_dash: bool = true


@export_group("Programmer Animation")

@export var punch_distance: float = 6.0
@export var punch_time: float = 0.06

@export var settle_overshoot: float = 2.0
@export var settle_time: float = 0.08

@export var final_settle_time: float = 0.10


@export_group("Debug")

@export var print_debug: bool = false


var _top_start_position: Vector2 = Vector2.ZERO

var _line_start_points: PackedVector2Array = (
	PackedVector2Array()
)

var _feedback_tween: Tween = null


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)

	if spring_top != null:
		_top_start_position = (
			spring_top.position
		)

	if spring_line != null:
		_line_start_points = (
			spring_line.points.duplicate()
		)


func _process(
	_delta: float
) -> void:
	_update_line()


func _on_body_entered(
	body: Node2D
) -> void:
	if not body is PlayerRoot:
		return

	var player := (
		body as PlayerRoot
	)

	if player.movement == null:
		return

	if player.movement.movement_state == null:
		return

	var state := (
		player.movement.movement_state
	)

	if not _can_activate(
		state
	):
		return

	_bounce_player(
		player
	)

	_play_feedback()


func _can_activate(
	state: PlayerMovementState
) -> bool:
	match direction:
		Direction.UP:
			# Area body_entered already prevents the spring
			# from repeatedly firing while the player exits.
			# Do not reject an UP spring just because a jump
			# started on the same frame.
			return true

		Direction.RIGHT:
			if state.Speed.x > 0.0:
				return false

		Direction.LEFT:
			if state.Speed.x < 0.0:
				return false

	return true


func _bounce_player(
	player: PlayerRoot
) -> void:
	var state := (
		player.movement.movement_state
	)

	_snap_player_to_bounce_point(
		player
	)

	state.StateMachineState = (
		player.StNormal
	)

	if refill_dash:
		state.Dashes = (
			player.MaxDashes
		)

	state.jumpGraceTimer = 0.0

	state.dashAttackTimer = 0.0

	state.wallSlideTimer = (
		player.WallSlideTime
	)

	state.wallBoostTimer = 0.0

	state.DashDir = (
		Vector2.ZERO
	)

	state.dashPending = false
	state.StartedDashing = false
	state.Ducking = false

	# Consume the fresh normal-jump press so it
	# cannot overwrite the spring on this frame.
	#
	# jump_check is NOT cleared, so holding jump
	# can still affect the variable spring height.
	state.jump_pressed = false

	state._jump_was_down = (
		Input.is_action_pressed(
			ACTION_JUMP
		)
	)

	match direction:
		Direction.UP:
			_bounce_up(
				state
			)

		Direction.RIGHT:
			_bounce_horizontal(
				state,
				1
			)

		Direction.LEFT:
			_bounce_horizontal(
				state,
				-1
			)

	state.launched = false

	state.movement_phase = (
		&"AIR_UP"
	)

	if print_debug:
		print(
			"SPRING | DIRECTION: ",
			Direction.keys()[direction],
			" | SPEED: ",
			state.Speed
		)


func _bounce_up(
	state: PlayerMovementState
) -> void:
	state.Speed.y = (
		bounce_speed
	)

	state.varJumpSpeed = (
		state.Speed.y
	)

	state.varJumpTimer = (
		bounce_var_jump_time
	)

	state.AutoJump = true

	state.AutoJumpTimer = (
		auto_jump_time
	)


func _bounce_horizontal(
	state: PlayerMovementState,
	horizontal_direction: int
) -> void:
	state.Speed.x = (
		horizontal_bounce_speed
		* float(horizontal_direction)
	)

	state.Speed.y = (
		side_vertical_bounce_speed
	)

	state.varJumpSpeed = (
		state.Speed.y
	)

	state.varJumpTimer = (
		bounce_var_jump_time
	)

	state.AutoJump = true

	state.AutoJumpTimer = (
		auto_jump_time
	)

	state.forceMoveX = (
		horizontal_direction
	)

	state.forceMoveXTimer = (
		horizontal_force_time
	)


func _snap_player_to_bounce_point(
	player: PlayerRoot
) -> void:
	if bounce_point == null:
		return

	match direction:
		Direction.UP:
			# Always normalize the spring surface Y.
			player.global_position.y = (
				bounce_point.global_position.y
			)

			# Optional center correction.
			if snap_to_center:
				player.global_position.x = (
					bounce_point.global_position.x
				)

		Direction.LEFT:
			# Normalize the side surface X.
			player.global_position.x = (
				bounce_point.global_position.x
			)

			if snap_to_center:
				player.global_position.y = (
					bounce_point.global_position.y
				)

		Direction.RIGHT:
			# Normalize the side surface X.
			player.global_position.x = (
				bounce_point.global_position.x
			)

			if snap_to_center:
				player.global_position.y = (
					bounce_point.global_position.y
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
