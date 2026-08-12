extends RefCounted
class_name PlayerSuperJump


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


func CanSuperJump() -> bool:
	return (
		state.StateMachineState
		== player.StDash
		and is_zero_approx(
			state.DashDir.y
		)
		and state.jump_pressed
		and state.jumpGraceTimer > 0.0
	)


func SuperJump() -> void:
	var was_ducking: bool = (
		state.Ducking
	)

	var was_wavedash: bool = (
		was_ducking
		and state.dash_landed_from_air
		and state.dash_refilled_after_air_landing
	)

	state.jumpGraceTimer = 0.0
	state.varJumpTimer = player.VarJumpTime
	state.AutoJump = false
	state.dashAttackTimer = 0.0
	state.wallSlideTimer = player.WallSlideTime
	state.wallBoostTimer = 0.0

	state.Speed.x = (
		player.SuperJumpH
		* state.Facing
	)

	state.Speed.y = (
		player.JumpSpeed
	)

	state.Speed += (
		state.LiftBoost
	)

	if state.Ducking:
		state.Ducking = false

		state.Speed.x *= (
			player.DuckSuperJumpXMult
		)

		state.Speed.y *= (
			player.DuckSuperJumpYMult
		)

	state.varJumpSpeed = (
		state.Speed.y
	)

	state.launched = true

	state.movement_phase = (
		&"AIR_UP"
	)

	state.dash_landed_from_air = false
	state.dash_refilled_after_air_landing = false

	if was_wavedash:
		movement.emit_movement_state(
			&"WAVEDASH"
		)

	elif was_ducking:
		movement.emit_movement_state(
			&"HYPER JUMP"
		)

	else:
		movement.emit_movement_state(
			&"SUPER JUMP"
		)
