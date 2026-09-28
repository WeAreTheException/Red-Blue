extends RefCounted
class_name PlayerBounce


const ACTION_JUMP: StringName = &"JUMP"


var player: PlayerRoot
var movement: PlayerMovement
var state: PlayerMovementState
var grab: PlayerGrab


func setup(
	source_player: PlayerRoot,
	source_movement: PlayerMovement,
	source_state: PlayerMovementState,
	source_grab: PlayerGrab
) -> void:
	player = source_player
	movement = source_movement
	state = source_state
	grab = source_grab


func WantsSuperBounce() -> bool:
	return Input.is_action_pressed(
		ACTION_JUMP
	)


func Bounce(
	refill_dash: bool = true,
	refill_stamina: bool = true
) -> void:
	_prepare_bounce(
		refill_dash,
		refill_stamina
	)

	# Fixed normal bounce.
	#
	# Holding JUMP after the spring fires
	# cannot extend this bounce.
	state.Speed.y = (
		player.BounceSpeed
	)

	state.varJumpSpeed = (
		state.Speed.y
	)

	state.varJumpTimer = 0.0

	state.AutoJump = false
	state.AutoJumpTimer = 0.0

	_consume_jump_press()

	movement.emit_movement_state(
		&"BOUNCE"
	)


func SuperBounce(
	refill_dash: bool = true,
	refill_stamina: bool = true
) -> void:
	_prepare_bounce(
		refill_dash,
		refill_stamina
	)

	# Fixed SuperBounce.
	state.Speed.x = 0.0

	state.Speed.y = (
		player.SuperBounceSpeed
	)

	state.varJumpSpeed = (
		state.Speed.y
	)

	state.varJumpTimer = 0.0

	state.AutoJump = false
	state.AutoJumpTimer = 0.0

	_consume_jump_press()

	movement.emit_movement_state(
		&"SUPER BOUNCE"
	)


func SideBounce(
	direction: int,
	refill_dash: bool = true,
	refill_stamina: bool = true
) -> void:
	if direction == 0:
		return

	_prepare_bounce(
		refill_dash,
		refill_stamina
	)

	state.Speed.x = (
		player.SideBounceHSpeed
		* float(direction)
	)

	state.Speed.y = (
		player.SideBounceVSpeed
	)

	state.varJumpSpeed = (
		state.Speed.y
	)

	state.varJumpTimer = (
		player.SideBounceVarJumpTime
	)

	state.AutoJump = true

	state.AutoJumpTimer = (
		player.SideBounceAutoJumpTime
	)

	state.forceMoveX = (
		direction
	)

	state.forceMoveXTimer = (
		player.SideBounceForceTime
	)

	_consume_jump_press()

	movement.emit_movement_state(
		&"SIDE BOUNCE"
	)


func _prepare_bounce(
	refill_dash: bool,
	refill_stamina: bool
) -> void:
	state.StateMachineState = (
		player.StNormal
	)

	state.jumpGraceTimer = 0.0

	state.dashAttackTimer = 0.0

	state.wallSlideTimer = (
		player.WallSlideTime
	)

	state.wallSlideDir = 0

	state.wallBoostTimer = 0.0
	state.wallBoostDir = 0

	state.DashDir = (
		Vector2.ZERO
	)

	state.dashPending = false
	state.StartedDashing = false

	state.Ducking = false
	state.launched = false

	state.forceMoveX = 0
	state.forceMoveXTimer = 0.0

	if refill_dash:
		state.Dashes = (
			player.MaxDashes
		)

	if (
		refill_stamina
		and grab != null
	):
		grab.RefillStamina()


func _consume_jump_press() -> void:
	var jump_down: bool = (
		Input.is_action_pressed(
			ACTION_JUMP
		)
	)

	state.jump_pressed = false

	state.jump_check = (
		jump_down
	)

	state._jump_was_down = (
		jump_down
	)
