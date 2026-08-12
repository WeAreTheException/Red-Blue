extends RefCounted
class_name PlayerCollision


var player: PlayerRoot
var state: PlayerMovementState

var xRemainder: float = 0.0
var yRemainder: float = 0.0


func setup(
	source_player: PlayerRoot,
	source_state: PlayerMovementState
) -> void:
	player = source_player
	state = source_state

	player.global_position.x = roundi(
		player.global_position.x
	)

	player.global_position.y = roundi(
		player.global_position.y
	)


func MoveH(amount: float) -> void:
	xRemainder += amount

	var move: int = roundi(
		xRemainder
	)

	if move != 0:
		xRemainder -= move

		MoveHExact(
			move
		)


func MoveV(amount: float) -> void:
	yRemainder += amount

	var move: int = roundi(
		yRemainder
	)

	if move != 0:
		yRemainder -= move

		MoveVExact(
			move
		)


func MoveHExact(amount: int) -> bool:
	var move: int = amount

	if move == 0:
		return false

	var step: int = int(
		sign(move)
	)

	while move != 0:
		var collision := (
			player.move_and_collide(
				Vector2(step, 0)
			)
		)

		if collision == null:
			move -= step

		else:
			OnCollideH(
				collision
			)

			return true

	return false


func MoveVExact(amount: int) -> bool:
	var move: int = amount

	if move == 0:
		return false

	var step: int = int(
		sign(move)
	)

	while move != 0:
		var collision := (
			player.move_and_collide(
				Vector2(0, step)
			)
		)

		if collision == null:
			move -= step

		else:
			OnCollideV(
				collision
			)

			return true

	return false


func OnGround() -> bool:
	return _collide_solid(
		Vector2.DOWN
	)


func WallJumpCheck(dir: int) -> bool:
	return _collide_solid(
		Vector2.RIGHT
		* dir
		* player.WallJumpCheckDist
	)


func OnCollideH(
	_collision: KinematicCollision2D = null
) -> void:
	if (
		state.StateMachineState
		== player.StDash
	):
		if (
			is_zero_approx(state.Speed.y)
			and not is_zero_approx(
				state.Speed.x
			)
		):
			var x_dir := int(
				sign(state.Speed.x)
			)

			for i in range(
				1,
				player.DashCornerCorrection + 1
			):
				for j in [1, -1]:
					var correction := Vector2(
						x_dir,
						i * j
					)

					if not _collide_solid(
						correction
					):
						player.global_position.y += (
							i * j
						)

						MoveHExact(
							x_dir
						)

						return

	if (
		state.wallSpeedRetentionTimer
		<= 0.0
	):
		state.wallSpeedRetained = (
			state.Speed.x
		)

		state.wallSpeedRetentionTimer = (
			player.WallSpeedRetentionTime
		)

	state.Speed.x = 0.0
	state.dashAttackTimer = 0.0


func OnCollideV(
	_collision: KinematicCollision2D = null
) -> void:
	if state.Speed.y > 0.0:
		if (
			state.StateMachineState
			== player.StDash
			and not state.dashStartedOnGround
		):
			if state.Speed.x <= 0.0:
				for i in range(
					-1,
					-player.DashCornerCorrection - 1,
					-1
				):
					if not _on_ground_at(
						Vector2(i, 0.0)
					):
						player.global_position.x += i

						MoveVExact(
							1
						)

						return

			if state.Speed.x >= 0.0:
				for i in range(
					1,
					player.DashCornerCorrection + 1
				):
					if not _on_ground_at(
						Vector2(i, 0.0)
					):
						player.global_position.x += i

						MoveVExact(
							1
						)

						return

		# Dash Slide
		if (
			state.DashDir.x != 0.0
			and state.DashDir.y > 0.0
			and state.Speed.y > 0.0
		):
			# If this was an active dash that began
			# airborne, this is the landing portion
			# of a possible wavedash.
			if (
				state.StateMachineState
				== player.StDash
				and not state.dashStartedOnGround
			):
				state.dash_landed_from_air = true

			state.DashDir.x = sign(
				state.DashDir.x
			)

			state.DashDir.y = 0.0

			state.Speed.y = 0.0

			state.Speed.x *= (
				player.DodgeSlideSpeedMult
			)

			state.Ducking = true

	else:
		if state.Speed.y < 0.0:
			if state.Speed.x <= 0.0:
				for i in range(
					1,
					player.UpwardCornerCorrection + 1
				):
					var correction := Vector2(
						-i,
						-1
					)

					if not _collide_solid(
						correction
					):
						player.global_position += (
							correction
						)

						return

			if state.Speed.x >= 0.0:
				for i in range(
					1,
					player.UpwardCornerCorrection + 1
				):
					var correction := Vector2(
						i,
						-1
					)

					if not _collide_solid(
						correction
					):
						player.global_position += (
							correction
						)

						return

			if (
				state.varJumpTimer
				< player.VarJumpTime
				- player.CeilingVarJumpGrace
			):
				state.varJumpTimer = 0.0

	state.dashAttackTimer = 0.0
	state.Speed.y = 0.0


func update_wall_speed_retention(
	delta: float
) -> void:
	if (
		state.wallSpeedRetentionTimer
		<= 0.0
	):
		return

	if (
		sign(state.Speed.x)
		== -sign(state.wallSpeedRetained)
	):
		state.wallSpeedRetentionTimer = 0.0
		return

	var dir := int(
		sign(state.wallSpeedRetained)
	)

	if dir == 0:
		state.wallSpeedRetentionTimer = 0.0
		return

	if not _collide_solid(
		Vector2.RIGHT * dir
	):
		state.Speed.x = (
			state.wallSpeedRetained
		)

		state.wallSpeedRetentionTimer = 0.0

	else:
		state.wallSpeedRetentionTimer -= delta


func _collide_solid(
	offset: Vector2
) -> bool:
	return player.test_move(
		player.global_transform,
		offset
	)


func _on_ground_at(
	offset: Vector2
) -> bool:
	var test_transform := (
		player.global_transform
	)

	test_transform.origin += offset

	return player.test_move(
		test_transform,
		Vector2.DOWN
	)
