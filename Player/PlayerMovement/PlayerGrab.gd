extends RefCounted
class_name PlayerGrab


var player: PlayerRoot
var movement: PlayerMovement
var state: PlayerMovementState
var collision: PlayerCollision
var dash: PlayerDash
var wall_jump: PlayerWallJump


var climb_dir: int = 0


func setup(
	source_player: PlayerRoot,
	source_movement: PlayerMovement,
	source_state: PlayerMovementState,
	source_collision: PlayerCollision,
	source_dash: PlayerDash,
	source_wall_jump: PlayerWallJump
) -> void:
	player = source_player
	movement = source_movement
	state = source_state
	collision = source_collision
	dash = source_dash
	wall_jump = source_wall_jump


func CanGrab() -> bool:
	if not state.grab_check:
		return false

	if state.Stamina <= 0.0:
		return false

	var direction: int = (
		_get_grab_direction()
	)

	if direction == 0:
		return false

	climb_dir = direction

	return true


func StartGrab() -> int:
	state.StateMachineState = (
		player.StClimb
	)

	ClimbBegin()

	return player.StClimb


func ClimbBegin() -> void:
	state.Ducking = false

	state.Facing = climb_dir

	state.Speed.x = 0.0

	state.Speed.y *= (
		player.ClimbGrabYMult
	)

	state.climbNoMoveTimer = (
		player.ClimbNoMoveTime
	)

	state.wallSlideDir = 0

	state.movement_phase = (
		&"CLIMB"
	)

	movement.emit_movement_state(
		&"CLIMB"
	)


func ClimbUpdate(
	delta: float
) -> int:
	if dash.CanDash():
		ClimbEnd()

		return dash.StartDash()

	if state.jump_pressed:
		ClimbEnd()

		state.StateMachineState = (
			player.StNormal
		)

		if wall_jump.TryWallJump():
			return player.StNormal

		return player.StNormal

	if not state.grab_check:
		return _leave_climb()

	if state.Stamina <= 0.0:
		return _leave_climb()

	if not _wall_check(
		climb_dir
	):
		return _leave_climb()

	state.Facing = climb_dir
	state.Speed.x = 0.0

	if state.climbNoMoveTimer > 0.0:
		state.climbNoMoveTimer = maxf(
			0.0,
			state.climbNoMoveTimer
			- delta
		)

		state.Speed.y = _approach(
			state.Speed.y,
			0.0,
			player.ClimbAccel
			* delta
		)

		return player.StClimb

	var target_speed_y: float = 0.0

	if (
		state.Stamina
		<= player.ClimbTiredThreshold
	):
		if state.moveY == 1:
			target_speed_y = (
				player.ClimbDownSpeed
			)

		else:
			target_speed_y = (
				player.ClimbSlipSpeed
			)

	else:
		if state.moveY == -1:
			target_speed_y = (
				player.ClimbUpSpeed
			)

			state.Stamina = maxf(
				0.0,
				state.Stamina
				- (
					player.ClimbUpCost
					* delta
				)
			)

		elif state.moveY == 1:
			target_speed_y = (
				player.ClimbDownSpeed
			)

		else:
			target_speed_y = 0.0

			state.Stamina = maxf(
				0.0,
				state.Stamina
				- (
					player.ClimbStillCost
					* delta
				)
			)

	state.Speed.y = _approach(
		state.Speed.y,
		target_speed_y,
		player.ClimbAccel
		* delta
	)

	return player.StClimb


func ClimbEnd() -> void:
	climb_dir = 0

	state.climbNoMoveTimer = 0.0


func _leave_climb() -> int:
	ClimbEnd()

	state.StateMachineState = (
		player.StNormal
	)

	return player.StNormal


func _get_grab_direction() -> int:
	if state.moveX != 0:
		if _wall_check(
			state.moveX
		):
			return state.moveX

	if _wall_check(
		state.Facing
	):
		return state.Facing

	return 0


func _wall_check(
	direction: int
) -> bool:
	if direction == 0:
		return false

	return player.test_move(
		player.global_transform,
		Vector2.RIGHT
		* direction
		* player.ClimbCheckDist
	)


func _approach(
	value: float,
	target: float,
	amount: float
) -> float:
	if value < target:
		return minf(
			value + amount,
			target
		)

	return maxf(
		value - amount,
		target
	)
