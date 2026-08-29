extends RefCounted
class_name PlayerDash


var player: PlayerRoot
var movement: PlayerMovement
var state: PlayerMovementState
var super_jump: PlayerSuperJump
var wall_jump: PlayerWallJump


# Remembers a JUMP press that happened on the
# exact same physics frame that the dash started.
#
# Without this, PlayerInput sees the press once,
# StartDash() consumes that frame, and by the next
# DashUpdate the edge press is already gone.
var _jump_pressed_on_dash_start: bool = false


func setup(
	source_player: PlayerRoot,
	source_movement: PlayerMovement,
	source_state: PlayerMovementState,
	source_super_jump: PlayerSuperJump,
	source_wall_jump: PlayerWallJump
) -> void:
	player = source_player
	movement = source_movement
	state = source_state
	super_jump = source_super_jump
	wall_jump = source_wall_jump


func CanDash() -> bool:
	return (
		state.dash_pressed
		and state.dashCooldownTimer <= 0.0
		and state.Dashes > 0
	)


func StartDash() -> int:
	state.Dashes = max(
		0,
		state.Dashes - 1
	)

	state.StateMachineState = (
		player.StDash
	)

	DashBegin()

	return player.StDash


func DashBegin() -> void:
	state.dashStartedOnGround = (
		state.onGround
	)

	state.dash_landed_from_air = false
	state.dash_refilled_after_air_landing = false

	state.launched = false

	state.dashCooldownTimer = (
		player.DashCooldown
	)

	state.dashRefillCooldownTimer = (
		player.DashRefillCooldown
	)

	state.StartedDashing = true

	state.wallSlideTimer = (
		player.WallSlideTime
	)

	state.dashAttackTimer = (
		player.DashAttackTime
	)

	state.beforeDashSpeed = (
		state.Speed
	)

	state.Speed = Vector2.ZERO
	state.DashDir = Vector2.ZERO

	state.dashTimer = 0.0
	state.dashPending = true

	# Preserve JUMP if DASH + JUMP were pressed
	# on the exact same physics frame.
	_jump_pressed_on_dash_start = (
		state.jump_pressed
	)

	state.movement_phase = &"DASH"

	movement.emit_movement_state(
		&"DASH"
	)

	_start_dash_hitstop()


func DashUpdate(delta: float) -> int:
	state.StartedDashing = false

	if state.dashPending:
		state.dashPending = false

		var dir := state.lastAim

		if dir == Vector2.ZERO:
			dir = (
				Vector2.RIGHT
				* state.Facing
			)

		var newSpeed := (
			dir
			* player.DashSpeed
		)

		if (
			sign(state.beforeDashSpeed.x)
			== sign(newSpeed.x)
			and abs(state.beforeDashSpeed.x)
			> abs(newSpeed.x)
		):
			newSpeed.x = (
				state.beforeDashSpeed.x
			)

		state.Speed = newSpeed

		if player.InWater:
			state.Speed *= (
				player.SwimDashSpeedMult
			)

		state.DashDir = dir

		PlayerEvents.broadcast_dash_direction(
			player,
			dir
		)

		if state.DashDir.x != 0.0:
			state.Facing = int(
				sign(state.DashDir.x)
			)

		# Grounded Dash Slide / Hyper setup.
		#
		# This is NOT a wavedash because the dash
		# started while already grounded.
		if (
			state.onGround
			and state.DashDir.x != 0.0
			and state.DashDir.y > 0.0
			and state.Speed.y > 0.0
		):
			state.DashDir.x = sign(
				state.DashDir.x
			)

			state.DashDir.y = 0.0
			state.Speed.y = 0.0

			state.Speed.x *= (
				player.DodgeSlideSpeedMult
			)

			state.Ducking = true

		state.dashTimer = (
			player.DashTime
		)

		# DASH + JUMP on the same frame.
		#
		# PlayerInput's jump_pressed is an edge press,
		# so normally it would already be gone by this
		# first DashUpdate.
		#
		# Restore it exactly once so the existing
		# PlayerSuperJump logic gets to evaluate it.
		if _jump_pressed_on_dash_start:
			_jump_pressed_on_dash_start = false

			state.jump_pressed = true

			if super_jump.CanSuperJump():
				super_jump.SuperJump()

				state.StateMachineState = (
					player.StNormal
				)

				return player.StNormal

		return player.StDash

	# Normal jump press during the dash.
	if super_jump.CanSuperJump():
		_jump_pressed_on_dash_start = false

		super_jump.SuperJump()

		state.StateMachineState = (
			player.StNormal
		)

		return player.StNormal

	if wall_jump.TryDashWallJump():
		_jump_pressed_on_dash_start = false

		state.StateMachineState = (
			player.StNormal
		)

		return player.StNormal

	state.dashTimer -= delta

	if state.dashTimer <= 0.0:
		_jump_pressed_on_dash_start = false

		DashEnd()

		state.StateMachineState = (
			player.StNormal
		)

		return player.StNormal

	return player.StDash


func DashEnd() -> void:
	state.AutoJump = true
	state.AutoJumpTimer = 0.0

	if state.DashDir.y <= 0.0:
		state.Speed = (
			state.DashDir
			* player.EndDashSpeed
		)

	if state.Speed.y < 0.0:
		state.Speed.y *= (
			player.EndDashUpMult
		)


func RefillDash() -> bool:
	if state.Dashes < player.MaxDashes:
		state.Dashes = player.MaxDashes

		if state.dash_landed_from_air:
			state.dash_refilled_after_air_landing = true

		return true

	return false


func _start_dash_hitstop() -> void:
	if player == null:
		return

	if player.DashHitstopTime <= 0.0:
		return

	_run_dash_hitstop(
		player.DashHitstopTime
	)


func _run_dash_hitstop(
	duration: float
) -> void:
	# Celeste only performs its dash freeze when
	# the game is running at a meaningful time rate.
	if Engine.time_scale <= 0.25:
		return

	var previous_time_scale: float = (
		Engine.time_scale
	)

	Engine.time_scale = 0.0

	await player.get_tree().create_timer(
		duration,
		true,
		false,
		true
	).timeout

	Engine.time_scale = (
		previous_time_scale
	)
