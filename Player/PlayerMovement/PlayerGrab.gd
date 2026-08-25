extends RefCounted
class_name PlayerGrab


const SLIP_CHECK_Y: int = -4


var player: PlayerRoot
var movement: PlayerMovement
var state: PlayerMovementState
var collision: PlayerCollision

var jump: PlayerJump
var dash: PlayerDash
var wall_jump: PlayerWallJump


var climb_dir: int = 0

var _is_climbing: bool = false
var _last_climb_move: int = 0


func setup(
	source_player: PlayerRoot,
	source_movement: PlayerMovement,
	source_state: PlayerMovementState,
	source_collision: PlayerCollision,
	source_jump: PlayerJump,
	source_dash: PlayerDash,
	source_wall_jump: PlayerWallJump
) -> void:
	player = source_player
	movement = source_movement
	state = source_state
	collision = source_collision

	jump = source_jump
	dash = source_dash
	wall_jump = source_wall_jump

	_broadcast_stamina()


func CanGrab() -> bool:
	if not state.grab_check:
		return false

	if state.Ducking:
		return false

	# Celeste does not begin a normal climb grab
	# while the player is travelling upward.
	if state.Speed.y < 0.0:
		return false

	if (
		not player.ClimbInfiniteStamina
		and state.Stamina
		< player.ClimbTiredThreshold
	):
		return false

	var direction: int = (
		state.Facing
	)

	if direction == 0:
		return false

	# Do not grab a wall while velocity is
	# carrying us directly away from it.
	if (
		int(sign(state.Speed.x))
		== -direction
	):
		return false

	if _wall_check(
		direction
	):
		climb_dir = direction
		return true

	# Celeste checks a tiny amount upward as well.
	# This lets the grab catch cleanly around
	# small corners.
	if state.moveY != 1:
		for distance in range(
			1,
			player.ClimbUpCheckDist + 1
		):
			if player.test_move(
				player.global_transform,
				Vector2.UP
				* float(distance)
			):
				continue

			if not _wall_check_at(
				direction,
				-distance
			):
				continue

			collision.MoveVExact(
				-distance
			)

			climb_dir = direction

			return true

	return false


func StartGrab() -> int:
	state.StateMachineState = (
		player.StClimb
	)

	ClimbBegin()

	return player.StClimb


func ClimbBegin() -> void:
	_is_climbing = true

	state.Ducking = false
	state.AutoJump = false

	state.Facing = climb_dir

	state.Speed.x = 0.0

	state.Speed.y *= (
		player.ClimbGrabYMult
	)

	state.wallSlideTimer = (
		player.WallSlideTime
	)

	state.climbNoMoveTimer = (
		player.ClimbNoMoveTime
	)

	state.wallBoostTimer = 0.0
	state.wallBoostDir = 0

	state.wallSlideDir = 0

	_last_climb_move = 0

	_snap_to_wall()

	state.movement_phase = (
		&"CLIMB"
	)

	movement.emit_movement_state(
		&"CLIMB"
	)

	PlayerEvents.broadcast_climb_started(
		player
	)


func ClimbUpdate(
	delta: float
) -> int:
	state.climbNoMoveTimer = maxf(
		0.0,
		state.climbNoMoveTimer
		- delta
	)

	if (
		player.ClimbInfiniteStamina
		or state.onGround
	):
		RefillStamina()

	# Jump from climb.
	if state.jump_pressed:
		var facing: int = (
			state.Facing
		)

		if (
			state.moveX
			== -facing
		):
			ClimbEnd()

			state.StateMachineState = (
				player.StNormal
			)

			wall_jump.WallJump(
				-facing
			)

			return player.StNormal

		_climb_jump()

		return player.StNormal

	# Dash directly out of climb.
	if dash.CanDash():
		state.Speed += (
			state.LiftBoost
		)

		ClimbEnd()

		return dash.StartDash()

	# Released grab.
	if not state.grab_check:
		state.Speed += (
			state.LiftBoost
		)

		return _leave_climb()

	# Wall disappeared / player reached top.
	if not _wall_check(
		climb_dir
	):
		if state.Speed.y < 0.0:
			_climb_hop()

			return player.StNormal

		return _leave_climb()

	state.Facing = climb_dir
	state.Speed.x = 0.0

	var target_speed_y: float = 0.0
	var try_slip: bool = false

	if state.climbNoMoveTimer <= 0.0:
		if state.moveY == -1:
			target_speed_y = (
				player.ClimbUpSpeed
			)

			# Ceiling directly above.
			if player.test_move(
				player.global_transform,
				Vector2.UP
			):
				if state.Speed.y < 0.0:
					state.Speed.y = 0.0

				target_speed_y = 0.0
				try_slip = true

			# Reached the top of the wall.
			elif _slip_check():
				_climb_hop()

				return player.StNormal

		elif state.moveY == 1:
			target_speed_y = (
				player.ClimbDownSpeed
			)

			if state.onGround:
				if state.Speed.y > 0.0:
					state.Speed.y = 0.0

				target_speed_y = 0.0

		else:
			try_slip = true

	else:
		try_slip = true

	# Match Celeste's stamina bookkeeping:
	# slipping still counts as "holding still".
	_last_climb_move = int(
		sign(
			target_speed_y
		)
	)

	if (
		try_slip
		and _slip_check()
	):
		target_speed_y = (
			player.ClimbSlipSpeed
		)

	state.Speed.y = _approach(
		state.Speed.y,
		target_speed_y,
		player.ClimbAccel
		* delta
	)

	# If the hands no longer have wall beneath
	# them, do not slide down unless DOWN is held.
	if (
		state.moveY != 1
		and state.Speed.y > 0.0
		and not _wall_check_at(
			climb_dir,
			1
		)
	):
		state.Speed.y = 0.0

	_update_stamina(
		delta
	)

	if (
		not player.ClimbInfiniteStamina
		and state.Stamina <= 0.0
	):
		state.Speed += (
			state.LiftBoost
		)

		return _leave_climb()

	return player.StClimb


func ClimbEnd() -> void:
	if not _is_climbing:
		return

	_is_climbing = false

	climb_dir = 0

	state.climbNoMoveTimer = 0.0
	state.wallSpeedRetentionTimer = 0.0

	PlayerEvents.broadcast_climb_ended(
		player
	)


func RefillStamina() -> void:
	_set_stamina(
		player.ClimbMaxStamina
	)


func RefundClimbJumpStamina() -> void:
	if player.ClimbInfiniteStamina:
		RefillStamina()
		return

	_set_stamina(
		state.Stamina
		+ player.ClimbJumpCost
	)


func _climb_jump() -> void:
	var facing: int = (
		state.Facing
	)

	if not state.onGround:
		_consume_stamina(
			player.ClimbJumpCost
		)

	ClimbEnd()

	state.StateMachineState = (
		player.StNormal
	)

	jump.Jump()

	# If the player initially jumps straight up,
	# Celeste gives a brief window where pressing
	# away converts it into wall-jump horizontal
	# speed and refunds the climb-jump stamina.
	if state.moveX == 0:
		state.wallBoostDir = (
			-facing
		)

		state.wallBoostTimer = (
			player.ClimbJumpBoostTime
		)


func _climb_hop() -> void:
	var facing: int = (
		state.Facing
	)

	ClimbEnd()

	state.StateMachineState = (
		player.StNormal
	)

	state.Speed.x = (
		float(facing)
		* player.ClimbHopX
	)

	state.Speed.y = minf(
		state.Speed.y,
		player.ClimbHopY
	)

	state.forceMoveX = 0

	state.forceMoveXTimer = (
		player.ClimbHopForceTime
	)

	PlayerEvents.broadcast_climb_hopped(
		player
	)


func _update_stamina(
	delta: float
) -> void:
	if player.ClimbInfiniteStamina:
		RefillStamina()
		return

	if state.climbNoMoveTimer > 0.0:
		return

	if _last_climb_move == -1:
		_consume_stamina(
			player.ClimbUpCost
			* delta
		)

	elif _last_climb_move == 0:
		_consume_stamina(
			player.ClimbStillCost
			* delta
		)


func _consume_stamina(
	amount: float
) -> void:
	if player.ClimbInfiniteStamina:
		return

	_set_stamina(
		state.Stamina
		- amount
	)


func _set_stamina(
	value: float
) -> void:
	var new_stamina: float = clampf(
		value,
		0.0,
		player.ClimbMaxStamina
	)

	if is_equal_approx(
		state.Stamina,
		new_stamina
	):
		return

	state.Stamina = (
		new_stamina
	)

	_broadcast_stamina()


func _broadcast_stamina() -> void:
	if player == null:
		return

	var tired: bool = (
		not player.ClimbInfiniteStamina
		and state.Stamina
		<= player.ClimbTiredThreshold
	)

	PlayerEvents.broadcast_climb_stamina_changed(
		player,
		state.Stamina,
		player.ClimbMaxStamina,
		tired
	)


func _leave_climb() -> int:
	ClimbEnd()

	state.StateMachineState = (
		player.StNormal
	)

	return player.StNormal


func _snap_to_wall() -> void:
	if climb_dir == 0:
		return

	for _i in range(
		player.ClimbCheckDist
	):
		if player.test_move(
			player.global_transform,
			Vector2.RIGHT
			* float(climb_dir)
		):
			break

		player.global_position.x += (
			float(climb_dir)
		)


func _wall_check(
	direction: int
) -> bool:
	return _wall_check_at(
		direction,
		0
	)


func _wall_check_at(
	direction: int,
	y_offset: int
) -> bool:
	if direction == 0:
		return false

	var test_transform: Transform2D = (
		player.global_transform
	)

	test_transform.origin.y += (
		float(y_offset)
	)

	return player.test_move(
		test_transform,
		Vector2.RIGHT
		* float(direction)
		* float(
			player.ClimbCheckDist
		)
	)


func _slip_check() -> bool:
	if climb_dir == 0:
		return false

	if not _wall_check(
		climb_dir
	):
		return false

	# Approximation of Celeste's two hand-height
	# ledge checks using our existing body collider.
	return not _wall_check_at(
		climb_dir,
		SLIP_CHECK_Y
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
