extends RefCounted
class_name PlayerVine


var player: PlayerRoot
var movement: PlayerMovement
var state: PlayerMovementState
var dash: PlayerDash


var candidate_vine: VineSwing = null
var active_vine: VineSwing = null


var _candidate_inside: bool = false
var _grab_grace_timer: float = 0.0


var _attach_start_position: Vector2 = (
	Vector2.ZERO
)

var _attach_timer: float = 0.0


func setup(
	source_player: PlayerRoot,
	source_movement: PlayerMovement,
	source_state: PlayerMovementState,
	source_dash: PlayerDash
) -> void:
	player = source_player
	movement = source_movement
	state = source_state
	dash = source_dash


func update_grace(
	delta: float
) -> void:
	if _candidate_inside:
		return

	if _grab_grace_timer <= 0.0:
		return

	_grab_grace_timer -= delta

	if _grab_grace_timer <= 0.0:
		_grab_grace_timer = 0.0

		if active_vine == null:
			candidate_vine = null


func enter_vine_area(
	vine: VineSwing
) -> void:
	candidate_vine = vine

	_candidate_inside = true

	_grab_grace_timer = (
		player.VineGrabGraceTime
	)


func exit_vine_area(
	vine: VineSwing
) -> void:
	if candidate_vine != vine:
		return

	_candidate_inside = false

	_grab_grace_timer = (
		player.VineGrabGraceTime
	)


func CanGrab() -> bool:
	if active_vine != null:
		return false

	if candidate_vine == null:
		return false

	if not is_instance_valid(
		candidate_vine
	):
		candidate_vine = null
		return false

	if (
		not _candidate_inside
		and _grab_grace_timer <= 0.0
	):
		return false

	if not state.grab_check:
		return false

	return true


func StartGrab() -> int:
	if candidate_vine == null:
		return player.StNormal

	active_vine = candidate_vine

	state.StateMachineState = (
		player.StVine
	)

	state.Ducking = false
	state.AutoJump = false

	var entry_velocity_x: float = (
		state.Speed.x
	)

	state.Speed = (
		Vector2.ZERO
	)

	state.onGround = false

	_attach_start_position = (
		player.global_position
	)

	_attach_timer = 0.0

	active_vine.begin_swing(
		entry_velocity_x
	)

	state.movement_phase = (
		&"VINE"
	)

	movement.emit_movement_state(
		&"VINE"
	)

	return player.StVine


func VineUpdate(
	delta: float
) -> int:
	if active_vine == null:
		return ForceDetach(
			false
		)

	if not is_instance_valid(
		active_vine
	):
		active_vine = null

		return ForceDetach(
			false
		)

	# JUMP off the vine.
	if state.jump_pressed:
		return _detach_with_exit(
			true
		)

	# Release GRAB.
	if not state.grab_check:
		return _detach_with_exit(
			false
		)

	# DASH while remaining attached.
	if dash.CanDash():
		_vine_dash()

	_attach_timer += delta

	var target_position: Vector2 = (
		active_vine.end_point.global_position
	)

	if (
		player.VineAttachTime
		> 0.0
		and _attach_timer
		< player.VineAttachTime
	):
		var amount: float = clampf(
			_attach_timer
			/ player.VineAttachTime,
			0.0,
			1.0
		)

		player.global_position = (
			_attach_start_position.lerp(
				target_position,
				amount
			)
		)

	else:
		player.global_position = (
			target_position
		)

	state.Speed = (
		Vector2.ZERO
	)

	state.onGround = false

	return player.StVine


func ForceDetach(
	use_exit_velocity: bool
) -> int:
	if (
		use_exit_velocity
		and active_vine != null
		and is_instance_valid(
			active_vine
		)
	):
		_apply_exit_velocity()

	else:
		state.Speed = (
			Vector2.ZERO
		)

	active_vine = null

	state.StateMachineState = (
		player.StNormal
	)

	return player.StNormal


func _detach_with_exit(
	from_jump: bool
) -> int:
	_apply_exit_velocity()

	active_vine = null

	state.StateMachineState = (
		player.StNormal
	)

	if from_jump:
		state.movement_phase = (
			&"JUMP"
		)

		movement.emit_movement_state(
			&"JUMP"
		)

	else:
		state.movement_phase = (
			&"AIR_UP"
		)

	return player.StNormal


func _apply_exit_velocity() -> void:
	if active_vine == null:
		state.Speed = (
			Vector2.ZERO
		)

		return

	if not active_vine.is_swinging():
		state.Speed = (
			Vector2.ZERO
		)

		return

	var direction: int = (
		active_vine.get_motion_direction()
	)

	if direction == 0:
		direction = (
			state.Facing
		)

	state.Speed.x = (
		player.VineExitHSpeed
		* float(direction)
	)

	state.Speed.y = (
		player.VineExitVSpeed
	)

	state.Facing = direction


func _vine_dash() -> void:
	state.Dashes = max(
		0,
		state.Dashes - 1
	)

	state.dashCooldownTimer = (
		player.DashCooldown
	)

	state.dashRefillCooldownTimer = (
		player.DashRefillCooldown
	)

	var direction: int = 0

	if state.lastAim.x < 0.0:
		direction = -1

	elif state.lastAim.x > 0.0:
		direction = 1

	else:
		direction = (
			state.Facing
		)

	active_vine.apply_dash_impulse(
		direction
	)

	state.Facing = direction

	PlayerEvents.broadcast_dash_direction(
		player,
		Vector2(
			float(direction),
			0.0
		)
	)

	movement.emit_movement_state(
		&"DASH"
	)
