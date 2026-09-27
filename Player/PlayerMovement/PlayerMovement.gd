extends RefCounted
class_name PlayerMovement


var player: PlayerRoot

var movement_enabled: bool = true

var movement_state: PlayerMovementState

var player_input: PlayerInput
var player_move: PlayerMove
var player_jump: PlayerJump
var player_dash: PlayerDash
var player_super_jump: PlayerSuperJump
var player_wall_jump: PlayerWallJump
var player_collision: PlayerCollision
var player_grab: PlayerGrab
var player_bounce: PlayerBounce
var player_vine: PlayerVine


func setup(
	source_player: PlayerRoot
) -> void:
	player = source_player

	_build_movement_runtime()

	_set_phase(
		&"IDLE",
		true
	)


func update(
	delta: float
) -> void:
	if not movement_enabled:
		return

	if player == null:
		return

	player_input.update()

	player_vine.update_grace(
		delta
	)

	_update_timers(
		delta
	)

	if movement_state.Speed.y >= 0.0:
		movement_state.onGround = (
			player_collision.OnGround()
		)

	else:
		movement_state.onGround = false

	if player.ClimbInfiniteStamina:
		player_grab.RefillStamina()

	elif (
		movement_state.onGround
		and movement_state.StateMachineState
		!= player.StClimb
	):
		player_grab.RefillStamina()

	if movement_state.onGround:
		movement_state.jumpGraceTimer = (
			player.JumpGraceTime
		)

		movement_state.wallSlideTimer = (
			player.WallSlideTime
		)

		if (
			movement_state.dashRefillCooldownTimer
			<= 0.0
		):
			player_dash.RefillDash()

	else:
		if movement_state.jumpGraceTimer > 0.0:
			movement_state.jumpGraceTimer -= (
				delta
			)

	player_collision.update_wall_speed_retention(
		delta
	)

	match movement_state.StateMachineState:
		player.StNormal:
			_normal_update(
				delta
			)

		player.StClimb:
			player_grab.ClimbUpdate(
				delta
			)

		player.StDash:
			player_dash.DashUpdate(
				delta
			)

		player.StVine:
			player_vine.VineUpdate(
				delta
			)

	if (
		movement_state.StateMachineState
		!= player.StDash
	):
		movement_state.StartedDashing = false

	player_collision.MoveH(
		movement_state.Speed.x
		* delta
	)

	player_collision.MoveV(
		movement_state.Speed.y
		* delta
	)

	if movement_state.Speed.y >= 0.0:
		movement_state.onGround = (
			player_collision.OnGround()
		)

	else:
		movement_state.onGround = false

	if (
		not movement_state.onGround
		and movement_state.StateMachineState
		== player.StDash
		and movement_state.DashDir.y == 0.0
	):
		if player.test_move(
			player.global_transform,
			Vector2.DOWN
			* player.DashVFloorSnapDist
		):
			player_collision.MoveVExact(
				player.DashVFloorSnapDist
			)

	_update_public_state_events()

	movement_state.wasOnGround = (
		movement_state.onGround
	)


func _build_movement_runtime() -> void:
	movement_state = PlayerMovementState.new()

	player_input = PlayerInput.new()
	player_move = PlayerMove.new()
	player_jump = PlayerJump.new()
	player_dash = PlayerDash.new()
	player_super_jump = PlayerSuperJump.new()
	player_wall_jump = PlayerWallJump.new()
	player_collision = PlayerCollision.new()
	player_grab = PlayerGrab.new()
	player_bounce = PlayerBounce.new()
	player_vine = PlayerVine.new()

	movement_state.Dashes = (
		player.MaxDashes
	)

	movement_state.Stamina = (
		player.ClimbMaxStamina
	)

	movement_state.lastAim = (
		Vector2.RIGHT
		* movement_state.Facing
	)

	movement_state.wallSlideTimer = (
		player.WallSlideTime
	)

	movement_state.maxFall = (
		player.MaxFall
	)

	player_input.setup(
		player,
		movement_state
	)

	player_collision.setup(
		player,
		movement_state
	)

	player_move.setup(
		player,
		movement_state,
		player_collision
	)

	player_jump.setup(
		player,
		self,
		movement_state
	)

	player_super_jump.setup(
		player,
		self,
		movement_state
	)

	player_wall_jump.setup(
		player,
		self,
		movement_state,
		player_collision
	)

	player_dash.setup(
		player,
		self,
		movement_state,
		player_super_jump,
		player_wall_jump
	)

	player_grab.setup(
		player,
		self,
		movement_state,
		player_collision,
		player_jump,
		player_dash,
		player_wall_jump
	)

	player_bounce.setup(
		player,
		self,
		movement_state,
		player_grab
	)

	player_vine.setup(
		player,
		self,
		movement_state,
		player_dash
	)


func _normal_update(
	delta: float
) -> void:
	if player_vine.CanGrab():
		player_vine.StartGrab()
		return

	if player_grab.CanGrab():
		player_grab.StartGrab()
		return

	if player_dash.CanDash():
		player_dash.StartDash()
		return

	player_move.update(
		delta
	)

	if player_jump.update(
		delta
	):
		return

	player_wall_jump.TryWallJump()


func _update_timers(
	delta: float
) -> void:
	if (
		movement_state.dashCooldownTimer
		> 0.0
	):
		movement_state.dashCooldownTimer -= (
			delta
		)

	if (
		movement_state.dashRefillCooldownTimer
		> 0.0
	):
		movement_state.dashRefillCooldownTimer -= (
			delta
		)

	if (
		movement_state.dashAttackTimer
		> 0.0
	):
		movement_state.dashAttackTimer -= (
			delta
		)

	if (
		movement_state.varJumpTimer
		> 0.0
	):
		movement_state.varJumpTimer -= (
			delta
		)

	# Match Celeste-style AutoJump behavior.
	#
	# A zero AutoJumpTimer does NOT immediately
	# cancel AutoJump.
	#
	# This matters for SuperBounce, which uses:
	#
	# AutoJump = true
	# AutoJumpTimer = 0.0
	if (
		movement_state.AutoJumpTimer
		> 0.0
	):
		if movement_state.AutoJump:
			movement_state.AutoJumpTimer -= (
				delta
			)

			if (
				movement_state.AutoJumpTimer
				<= 0.0
			):
				movement_state.AutoJumpTimer = 0.0
				movement_state.AutoJump = false

		else:
			movement_state.AutoJumpTimer = 0.0

	if (
		movement_state.forceMoveXTimer
		> 0.0
	):
		movement_state.forceMoveXTimer -= (
			delta
		)

		movement_state.moveX = (
			movement_state.forceMoveX
		)

	if (
		movement_state.wallBoostTimer
		> 0.0
	):
		movement_state.wallBoostTimer -= (
			delta
		)

		if (
			movement_state.moveX
			== movement_state.wallBoostDir
			and movement_state.wallBoostDir
			!= 0
		):
			movement_state.Speed.x = (
				player.WallJumpHSpeed
				* movement_state.moveX
			)

			player_grab.RefundClimbJumpStamina()

			movement_state.wallBoostTimer = 0.0
			movement_state.wallBoostDir = 0


func _update_public_state_events() -> void:
	if (
		movement_state.StateMachineState
		== player.StClimb
		or movement_state.StateMachineState
		== player.StVine
	):
		return

	if (
		movement_state.onGround
		and not movement_state.wasOnGround
	):
		_set_phase(
			&"LANDED",
			true
		)

		return

	if (
		movement_state.StateMachineState
		== player.StDash
	):
		return

	if not movement_state.onGround:
		if movement_state.Speed.y > 0.0:
			_set_phase(
				&"FALL"
			)

			return

		if movement_state.Speed.y < 0.0:
			if (
				movement_state.movement_phase
				== &""
			):
				_set_phase(
					&"JUMP"
				)

			return

	if movement_state.moveX != 0:
		_set_phase(
			&"MOVE"
		)

	else:
		_set_phase(
			&"IDLE"
		)


func _set_phase(
	state_name: StringName,
	force_emit: bool = false
) -> void:
	if (
		not force_emit
		and movement_state.movement_phase
		== state_name
	):
		return

	movement_state.movement_phase = (
		state_name
	)

	emit_movement_state(
		state_name
	)


func emit_movement_state(
	state_name: StringName
) -> void:
	movement_state.movement_phase = (
		state_name
	)

	if player == null:
		return

	var player_events := (
		player.get_node_or_null(
			"/root/PlayerEvents"
		)
	)

	if player_events == null:
		return

	player_events.broadcast_movement_state(
		player,
		state_name
	)


func disable_movement() -> void:
	movement_enabled = false

	if movement_state != null:
		movement_state.Speed = (
			Vector2.ZERO
		)


func enable_movement() -> void:
	movement_enabled = true

	_set_phase(
		&"IDLE",
		true
	)


func reset_movement() -> void:
	_build_movement_runtime()
