extends Node
class_name PlayerColorEjectionBridge


const ACTION_LEFT: StringName = &"LEFT"
const ACTION_RIGHT: StringName = &"RIGHT"
const ACTION_UP: StringName = &"UP"
const ACTION_DOWN: StringName = &"DOWN"
const ACTION_JUMP: StringName = &"JUMP"
const ACTION_DASH: StringName = &"DASH"

signal ejection_debug_changed(
	is_ejecting: bool,
	direction_name: StringName,
	route_name: StringName,
	distance: int,
	color_boost_applied: bool
)

@export_group("Player")
@export var player_collision_shape: CollisionShape2D
@export var player_death: PlayerDeath

@export_group("Ejection")
@export var eject_speed: float = 60.0

@export_group("Color Chain")
@export var color_chain_horizontal_mult: float = 1.0

var player: PlayerRoot
var is_color_transaction_active: bool = false

var _player_physics_was_enabled: bool = true

var _buffered_jump: bool = false
var _buffered_dash: bool = false
var _buffered_direction: Vector2 = Vector2.ZERO

var _pre_speed: Vector2 = Vector2.ZERO
var _pre_state_machine_state: int = 0
var _pre_dash_dir: Vector2 = Vector2.ZERO
var _pre_dash_started_on_ground: bool = false

var _last_ejection_result: Dictionary = {}

func _ready() -> void:
	player = get_parent() as PlayerRoot

func _input(event: InputEvent) -> void:
	if not is_color_transaction_active:
		return

	if player == null:
		return

	if event.is_action_pressed(
		ACTION_JUMP
	):
		_buffered_jump = true

	if event.is_action_pressed(
		ACTION_DASH
	):
		_buffered_dash = true

	_buffered_direction = (
		_read_current_direction()
	)

func begin_color_transaction() -> void:
	if player == null:
		return

	if is_color_transaction_active:
		return

	is_color_transaction_active = true

	var state := player.movement.movement_state

	_pre_speed = state.Speed
	_pre_state_machine_state = state.StateMachineState
	_pre_dash_dir = state.DashDir
	_pre_dash_started_on_ground = state.dashStartedOnGround

	_buffered_jump = (
		state.jump_pressed
		or (
			Input.is_action_pressed(ACTION_JUMP)
			and not state._jump_was_down
		)
	)

	_buffered_dash = (
		state.dash_pressed
		or (
			Input.is_action_pressed(ACTION_DASH)
			and not state._dash_was_down
		)
	)

	_buffered_direction = _read_current_direction()

	_player_physics_was_enabled = player.is_physics_processing()
	player.set_physics_process(false)

func cancel_color_transaction() -> void:
	if not is_color_transaction_active:
		return

	_restore_player_physics()
	is_color_transaction_active = false
	_clear_buffers()

	ejection_debug_changed.emit(
		false,
		&"NONE",
		&"NONE",
		0,
		false
	)

func apply_position_correction(result: Dictionary) -> void:
	if player == null:
		return

	if not result.get("success", false):
		return

	var offset: Vector2 = result.get("offset", Vector2.ZERO)
	player.global_position += offset

	_last_ejection_result = result.duplicate(true)

	var direction: Vector2 = result.get("direction", Vector2.ZERO)

	ejection_debug_changed.emit(
		true,
		_direction_name(direction),
		result.get("route", &"NONE"),
		int(result.get("distance", 0)),
		false
	)

func finish_color_transaction(had_ejection: bool) -> void:
	if player == null:
		return

	if not is_color_transaction_active:
		return

	if player_death != null and player_death.is_dead:
		_restore_player_physics()
		is_color_transaction_active = false
		_clear_buffers()
		return

	var action_performed := false

	if had_ejection:
		action_performed = _finish_ejection_chain()
	else:
		action_performed = _process_buffered_action_without_ejection()

	var boost_applied := false

	if had_ejection and action_performed:
		boost_applied = _apply_color_chain_boost()

	var direction := Vector2.ZERO
	var route_name: StringName = &"NONE"
	var distance := 0

	if not _last_ejection_result.is_empty():
		direction = _last_ejection_result.get("direction", Vector2.ZERO)
		route_name = _last_ejection_result.get("route", &"NONE")
		distance = int(_last_ejection_result.get("distance", 0))

	ejection_debug_changed.emit(
		false,
		_direction_name(direction),
		route_name,
		distance,
		boost_applied
	)

	_refresh_input_edge_memory()
	_restore_player_physics()

	is_color_transaction_active = false
	_clear_buffers()

func get_player_collision_shape() -> CollisionShape2D:
	return player_collision_shape

func get_velocity_for_ejection_bias() -> Vector2:
	if is_color_transaction_active:
		return _pre_speed
	if player == null:
		return Vector2.ZERO
	return player.movement.movement_state.Speed

func get_directional_input_for_ejection_bias() -> Vector2:
	return _buffered_direction

func route_blocked_by_active_world(offset: Vector2) -> bool:
	if player == null:
		return true
	return player.test_move(player.global_transform, offset)

func _finish_ejection_chain() -> bool:
	if _last_ejection_result.is_empty():
		return false

	var direction: Vector2 = _last_ejection_result.get("direction", Vector2.ZERO)
	var state := player.movement.movement_state

	state.Speed = _pre_speed

	if direction == Vector2.UP:
		_prepare_up_ejection()

		if state.StateMachineState == player.StDash and _buffered_jump:
			state.jump_pressed = true
			player.movement.player_dash.DashUpdate(0.0)
			return _is_jump_family_phase(state.movement_phase)

		if state.StateMachineState == player.StNormal and _buffered_dash:
			return _start_existing_dash()

		if _buffered_jump:
			state.jump_pressed = true
			return player.movement.player_jump.update(0.0)

		_apply_outward_eject_velocity(direction)
		return false

	if direction == Vector2.LEFT or direction == Vector2.RIGHT:
		if _buffered_jump:
			var wall_jump_dir := int(sign(direction.x))

			if (
				_pre_state_machine_state == player.StDash
				and is_zero_approx(_pre_dash_dir.x)
				and _pre_dash_dir.y < 0.0
			):
				player.movement.player_wall_jump.SuperWallJump(wall_jump_dir)
			else:
				player.movement.player_wall_jump.WallJump(wall_jump_dir)

			state.StateMachineState = player.StNormal
			return true

		if state.StateMachineState == player.StNormal and _buffered_dash:
			return _start_existing_dash()

		_apply_outward_eject_velocity(direction)
		return false

	# DOWN is ceiling-like and never fabricates grounded status.
	if state.StateMachineState == player.StNormal and _buffered_dash:
		return _start_existing_dash()

	_apply_outward_eject_velocity(direction)
	return false

func _prepare_up_ejection() -> void:
	var state := player.movement.movement_state

	state.onGround = true
	state.jumpGraceTimer = player.JumpGraceTime

	var valid_air_dash_landing := (
		_pre_state_machine_state == player.StDash
		and not _pre_dash_started_on_ground
		and not is_zero_approx(_pre_dash_dir.x)
		and _pre_dash_dir.y > 0.0
	)

	if not valid_air_dash_landing:
		return

	state.DashDir.x = sign(_pre_dash_dir.x)
	state.DashDir.y = 0.0

	state.Speed.x = _pre_speed.x * player.DodgeSlideSpeedMult
	state.Speed.y = 0.0

	state.Ducking = true
	state.dash_landed_from_air = true

	if state.dashRefillCooldownTimer <= 0.0:
		player.movement.player_dash.RefillDash()

func _process_buffered_action_without_ejection() -> bool:
	var state := player.movement.movement_state

	if state.StateMachineState == player.StDash:
		if _buffered_jump:
			state.jump_pressed = true
			player.movement.player_dash.DashUpdate(0.0)
			return _is_jump_family_phase(state.movement_phase)
		return false

	if state.StateMachineState == player.StNormal and _buffered_dash:
		return _start_existing_dash()

	if state.StateMachineState == player.StNormal and _buffered_jump:
		state.jump_pressed = true
		return player.movement.player_jump.update(0.0)

	return false

func _start_existing_dash() -> bool:
	var state := player.movement.movement_state
	state.dash_pressed = true

	if not player.movement.player_dash.CanDash():
		return false

	if _buffered_direction != Vector2.ZERO:
		state.lastAim = _buffered_direction.normalized()

	player.movement.player_dash.StartDash()
	return true

func _apply_outward_eject_velocity(direction: Vector2) -> void:
	var state := player.movement.movement_state
	var speed := _pre_speed

	if direction.x != 0.0:
		var outward_x := speed.x * direction.x
		speed.x = direction.x * max(
			eject_speed,
			max(0.0, outward_x)
		)
	else:
		var outward_y := speed.y * direction.y
		speed.y = direction.y * max(
			eject_speed,
			max(0.0, outward_y)
		)

	state.Speed = speed

func _apply_color_chain_boost() -> bool:
	if is_equal_approx(color_chain_horizontal_mult, 1.0):
		return false

	var state := player.movement.movement_state

	if not _is_jump_family_phase(state.movement_phase):
		return false

	state.Speed.x *= color_chain_horizontal_mult
	return true

func _is_jump_family_phase(phase: StringName) -> bool:
	return (
		phase == &"JUMP"
		or phase == &"SUPER JUMP"
		or phase == &"HYPER JUMP"
		or phase == &"WAVEDASH"
		or phase == &"WALL JUMP"
		or phase == &"SUPER WALL JUMP"
	)

func _refresh_input_edge_memory() -> void:
	if player == null:
		return

	var state := player.movement.movement_state

	state._jump_was_down = Input.is_action_pressed(ACTION_JUMP)
	state._dash_was_down = Input.is_action_pressed(ACTION_DASH)

	state.jump_pressed = false
	state.dash_pressed = false

func _restore_player_physics() -> void:
	if player == null:
		return
	player.set_physics_process(_player_physics_was_enabled)

func _clear_buffers() -> void:
	_buffered_jump = false
	_buffered_dash = false
	_buffered_direction = Vector2.ZERO
	_last_ejection_result.clear()

func _read_current_direction() -> Vector2:
	var horizontal_strength: float = Input.get_axis(
		ACTION_LEFT,
		ACTION_RIGHT
	)

	var vertical_strength: float = Input.get_axis(
		ACTION_UP,
		ACTION_DOWN
	)

	var direction := Vector2.ZERO

	if horizontal_strength < 0.0:
		direction.x = -1.0

	elif horizontal_strength > 0.0:
		direction.x = 1.0

	if vertical_strength < 0.0:
		direction.y = -1.0

	elif vertical_strength > 0.0:
		direction.y = 1.0

	return direction


func _direction_name(direction: Vector2) -> StringName:
	if direction == Vector2.LEFT:
		return &"LEFT"
	if direction == Vector2.RIGHT:
		return &"RIGHT"
	if direction == Vector2.UP:
		return &"UP"
	if direction == Vector2.DOWN:
		return &"DOWN"
	return &"NONE"
