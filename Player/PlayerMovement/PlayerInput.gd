extends RefCounted
class_name PlayerInput


const ACTION_LEFT: StringName = &"LEFT"
const ACTION_RIGHT: StringName = &"RIGHT"
const ACTION_UP: StringName = &"UP"
const ACTION_DOWN: StringName = &"DOWN"
const ACTION_JUMP: StringName = &"JUMP"
const ACTION_DASH: StringName = &"DASH"


var player: PlayerRoot
var state: PlayerMovementState


func setup(
	source_player: PlayerRoot,
	source_state: PlayerMovementState
) -> void:
	player = source_player
	state = source_state


func update() -> void:
	var horizontal_strength: float = Input.get_axis(
		ACTION_LEFT,
		ACTION_RIGHT
	)

	var vertical_strength: float = Input.get_axis(
		ACTION_UP,
		ACTION_DOWN
	)

	var input_move_x: int = 0
	var input_move_y: int = 0

	if horizontal_strength < 0.0:
		input_move_x = -1

	elif horizontal_strength > 0.0:
		input_move_x = 1

	if vertical_strength < 0.0:
		input_move_y = -1

	elif vertical_strength > 0.0:
		input_move_y = 1

	if state.forceMoveXTimer <= 0.0:
		state.moveX = input_move_x

	state.moveY = input_move_y

	var aim := Vector2(
		input_move_x,
		input_move_y
	)

	if aim != Vector2.ZERO:
		state.lastAim = aim.normalized()

	else:
		state.lastAim = (
			Vector2.RIGHT
			* state.Facing
		)

	var jump_down: bool = Input.is_action_pressed(
		ACTION_JUMP
	)

	state.jump_pressed = (
		jump_down
		and not state._jump_was_down
	)

	state.jump_check = jump_down
	state._jump_was_down = jump_down

	var dash_down: bool = Input.is_action_pressed(
		ACTION_DASH
	)

	state.dash_pressed = (
		dash_down
		and not state._dash_was_down
	)

	state._dash_was_down = dash_down

	if (
		state.moveX != 0
		and state.StateMachineState
		== player.StNormal
	):
		state.Facing = state.moveX
