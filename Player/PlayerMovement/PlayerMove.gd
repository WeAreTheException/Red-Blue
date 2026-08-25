extends RefCounted
class_name PlayerMove


var player: PlayerRoot
var state: PlayerMovementState
var collision: PlayerCollision


func setup(
	source_player: PlayerRoot,
	source_state: PlayerMovementState,
	source_collision: PlayerCollision
) -> void:
	player = source_player
	state = source_state
	collision = source_collision


func update(delta: float) -> void:
	var mult: float = 1.0 if state.onGround else player.AirMult

	if state.onGround and player.InCold:
		mult *= 0.3

	var max_run: float = player.MaxRun

	if player.InSpace:
		max_run *= player.SpacePhysicsMult

	if (
		abs(state.Speed.x) > max_run
		and sign(state.Speed.x) == state.moveX
	):
		state.Speed.x = _approach(
			state.Speed.x,
			max_run * state.moveX,
			player.RunReduce * mult * delta
		)

	else:
		state.Speed.x = _approach(
			state.Speed.x,
			max_run * state.moveX,
			player.RunAccel * mult * delta
		)

	var mf: float = player.MaxFall
	var fmf: float = player.FastMaxFall

	if player.InSpace:
		mf *= player.SpacePhysicsMult
		fmf *= player.SpacePhysicsMult

	if state.moveY == 1 and state.Speed.y >= mf:
		state.maxFall = _approach(
			state.maxFall,
			fmf,
			player.FastMaxAccel * delta
		)

	else:
		state.maxFall = _approach(
			state.maxFall,
			mf,
			player.FastMaxAccel * delta
		)

	if not state.onGround:
		var current_max: float = state.maxFall

		state.wallSlideDir = 0

		if (
			(
				state.moveX == state.Facing
				or (
					state.moveX == 0
					and state.grab_check
				)
			)
			and state.moveY != 1
			and state.Speed.y >= 0.0
			and state.wallSlideTimer > 0.0
			and collision.WallJumpCheck(
				state.Facing
			)
		):
			state.wallSlideDir = state.Facing

		if state.wallSlideDir != 0:
			current_max = lerp(
				player.MaxFall,
				player.WallSlideStartMax,
				state.wallSlideTimer
				/ player.WallSlideTime
			)

			state.wallSlideTimer = maxf(
				state.wallSlideTimer - delta,
				0.0
			)

		var gravity_mult: float = 1.0

		if (
			abs(state.Speed.y)
			< player.HalfGravThreshold
			and (
				state.jump_check
				or state.AutoJump
			)
		):
			gravity_mult = 0.5

		if player.InSpace:
			gravity_mult *= (
				player.SpacePhysicsMult
			)

		state.Speed.y = _approach(
			state.Speed.y,
			current_max,
			player.Gravity
			* gravity_mult
			* delta
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
