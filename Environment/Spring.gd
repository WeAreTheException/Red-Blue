extends Area2D
class_name Spring


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


@export_group("Contact")

# Helps stop an UP spring firing when the player
# merely walks into its lower side.
@export var contact_tolerance_px: float = 3.0

# Optional for now.
# BouncePoint represents the desired PlayerRoot
# origin at the moment the spring fires.
@export var snap_to_center: bool = false


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

	var player: PlayerRoot = (
		body as PlayerRoot
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

	if snap_to_center:
		_snap_player_to_bounce_point(
			player
		)

	match direction:
		Direction.UP:
			if (
				super_bounce_on_jump
				and bounce.WantsSuperBounce()
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


func _can_activate(
	player: PlayerRoot,
	state: PlayerMovementState,
	bounce: PlayerBounce
) -> bool:
	match direction:
		Direction.UP:
			# If we have a BouncePoint, reject contacts
			# clearly below the top face of the spring.
			#
			# PlayerRoot uses a bottom-center origin,
			# so this is comparing the player's feet.
			if bounce_point != null:
				if (
					player.global_position.y
					> bounce_point.global_position.y
					+ contact_tolerance_px
				):
					return false

			# Already travelling upward should normally
			# not trigger an UP spring.
			#
			# Exception: jump is currently held and this
			# contact is intentionally becoming a
			# SuperBounce.
			if state.Speed.y < 0.0:
				if not (
					super_bounce_on_jump
					and bounce.WantsSuperBounce()
				):
					return false

		Direction.LEFT:
			# Already travelling away from the spring.
			if state.Speed.x < 0.0:
				return false

			if bounce_point != null:
				if (
					player.global_position.x
					> bounce_point.global_position.x
					+ contact_tolerance_px
				):
					return false

		Direction.RIGHT:
			# Already travelling away from the spring.
			if state.Speed.x > 0.0:
				return false

			if bounce_point != null:
				if (
					player.global_position.x
					< bounce_point.global_position.x
					- contact_tolerance_px
				):
					return false

	return true


func _snap_player_to_bounce_point(
	player: PlayerRoot
) -> void:
	if bounce_point == null:
		return

	player.global_position = (
		bounce_point.global_position
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
