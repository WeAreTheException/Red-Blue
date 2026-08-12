extends RefCounted
class_name PlayerJump


var player: PlayerRoot
var movement: PlayerMovement
var state: PlayerMovementState


func setup(
	source_player: PlayerRoot,
	source_movement: PlayerMovement,
	source_state: PlayerMovementState
) -> void:
	player = source_player
	movement = source_movement
	state = source_state


func update(_delta: float) -> bool:
	if state.varJumpTimer > 0.0:
		if state.AutoJump or state.jump_check:
			state.Speed.y = min(
				state.Speed.y,
				state.varJumpSpeed
			)
		else:
			state.varJumpTimer = 0.0

	if not state.jump_pressed:
		return false

	if state.jumpGraceTimer > 0.0:
		Jump()
		return true

	return false


func Jump() -> void:
	state.jumpGraceTimer = 0.0
	state.varJumpTimer = player.VarJumpTime
	state.AutoJump = false
	state.dashAttackTimer = 0.0
	state.wallSlideTimer = player.WallSlideTime
	state.wallBoostTimer = 0.0

	state.Speed.x += (
		player.JumpHBoost
		* state.moveX
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
		&"JUMP"
	)
