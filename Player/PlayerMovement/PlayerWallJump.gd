extends RefCounted
class_name PlayerWallJump


var player: PlayerRoot
var movement: PlayerMovement
var state: PlayerMovementState
var collision: PlayerCollision


func setup(
	source_player: PlayerRoot,
	source_movement: PlayerMovement,
	source_state: PlayerMovementState,
	source_collision: PlayerCollision
) -> void:
	player = source_player
	movement = source_movement
	state = source_state
	collision = source_collision


func TryWallJump() -> bool:
	if not state.jump_pressed:
		return false

	if collision.WallJumpCheck(1):
		WallJump(-1)
		return true

	if collision.WallJumpCheck(-1):
		WallJump(1)
		return true

	return false


func TryDashWallJump() -> bool:
	if not state.jump_pressed:
		return false

	if (
		is_zero_approx(state.DashDir.x)
		and state.DashDir.y < 0.0
	):
		if collision.WallJumpCheck(1):
			SuperWallJump(-1)
			return true

		if collision.WallJumpCheck(-1):
			SuperWallJump(1)
			return true

	else:
		if collision.WallJumpCheck(1):
			WallJump(-1)
			return true

		if collision.WallJumpCheck(-1):
			WallJump(1)
			return true

	return false


func WallJump(dir: int) -> void:
	state.Ducking = false
	state.jumpGraceTimer = 0.0
	state.varJumpTimer = player.VarJumpTime
	state.AutoJump = false
	state.dashAttackTimer = 0.0
	state.wallSlideTimer = player.WallSlideTime
	state.wallBoostTimer = 0.0

	if state.moveX != 0:
		state.forceMoveX = dir
		state.forceMoveXTimer = (
			player.WallJumpForceTime
		)

	state.Speed.x = (
		player.WallJumpHSpeed
		* dir
	)

	state.Speed.y = player.JumpSpeed
	state.Speed += state.LiftBoost
	state.varJumpSpeed = state.Speed.y

	state.launched = (
		state.LiftBoost.length_squared()
		>= player.LaunchedBoostCheckSpeedSq
		and state.Speed.length_squared()
		>= player.LaunchedJumpCheckSpeedSq
	)

	state.movement_phase = &"AIR_UP"

	movement.emit_movement_state(
		&"WALL JUMP"
	)


func SuperWallJump(dir: int) -> void:
	state.Ducking = false
	state.jumpGraceTimer = 0.0
	state.varJumpTimer = (
		player.SuperWallJumpVarTime
	)

	state.AutoJump = false
	state.dashAttackTimer = 0.0
	state.wallSlideTimer = player.WallSlideTime
	state.wallBoostTimer = 0.0

	state.Speed.x = (
		player.SuperWallJumpH
		* dir
	)

	state.Speed.y = (
		player.SuperWallJumpSpeed
	)

	state.Speed += state.LiftBoost
	state.varJumpSpeed = state.Speed.y
	state.launched = true

	state.movement_phase = &"AIR_UP"

	movement.emit_movement_state(
		&"SUPER WALL JUMP"
	)
