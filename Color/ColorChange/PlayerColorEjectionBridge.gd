extends Node
class_name PlayerColorEjectionBridge


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


@export_group("Up Ejection")

@export var travel_acceleration: float = 4000.0
@export var max_travel_speed: float = 300.0
@export var exit_speed: float = 0.0


@export_group("Ejection Jump Boost")

@export var lift_boost_cap: float = 130.0


@export_group("Ejection Hazard Protection")

@export var ejection_hazard_grace_time: float = 0.08


var player: PlayerRoot = null

var is_color_transaction_active: bool = false


var _player_physics_was_enabled: bool = true

var _pre_speed: Vector2 = Vector2.ZERO
var _pre_state_machine_state: int = 0
var _pre_lift_boost: Vector2 = Vector2.ZERO

var _last_ejection_result: Dictionary = {}
var _last_travel_speed: float = 0.0

var _ejection_lift_active: bool = false
var _ejection_lift_timer: float = 0.0
var _ejection_lift_value: Vector2 = Vector2.ZERO

var _ejection_hazard_protected: bool = false
var _ejection_hazard_grace_timer: float = 0.0


func _ready() -> void:
	var parent_node := (
		get_parent()
	)

	player = (
		parent_node as PlayerRoot
	)

	if (
		player == null
		and parent_node != null
	):
		player = (
			parent_node.get_parent()
			as PlayerRoot
		)

	if player == null:
		push_error(
			"PlayerColorEjectionBridge could not find PlayerRoot."
		)

	var player_events := (
		get_node_or_null(
			"/root/PlayerEvents"
		)
	)

	if player_events != null:
		player_events.movement_state_changed.connect(
			_on_movement_state_changed
		)


func _process(
	delta: float
) -> void:
	if _ejection_lift_active:
		_ejection_lift_timer -= delta

		if _ejection_lift_timer <= 0.0:
			_clear_ejection_lift_boost()

	if _ejection_hazard_grace_timer > 0.0:
		_ejection_hazard_grace_timer -= delta

		if _ejection_hazard_grace_timer <= 0.0:
			_ejection_hazard_protected = false
			_ejection_hazard_grace_timer = 0.0


func begin_color_transaction() -> void:
	if player == null:
		return

	if is_color_transaction_active:
		return

	is_color_transaction_active = true

	_last_ejection_result.clear()
	_last_travel_speed = 0.0

	var state := (
		player.movement.movement_state
	)

	_pre_speed = (
		state.Speed
	)

	_pre_state_machine_state = (
		state.StateMachineState
	)

	_pre_lift_boost = (
		state.LiftBoost
	)

	state.Speed = (
		Vector2.ZERO
	)

	_player_physics_was_enabled = (
		player.is_physics_processing()
	)

	player.set_physics_process(
		false
	)


func cancel_color_transaction() -> void:
	if not is_color_transaction_active:
		return

	if player != null:
		var state := (
			player.movement.movement_state
		)

		state.Speed = (
			_pre_speed
		)

		state.StateMachineState = (
			_pre_state_machine_state
		)

		state.LiftBoost = (
			_pre_lift_boost
		)

	_clear_ejection_hazard_protection()

	_restore_player_physics()

	is_color_transaction_active = false

	_last_ejection_result.clear()

	ejection_debug_changed.emit(
		false,
		&"NONE",
		&"NONE",
		0,
		false
	)


func apply_position_correction(
	result: Dictionary
) -> void:
	if player == null:
		return

	if not bool(
		result.get(
			"success",
			false
		)
	):
		return

	_last_ejection_result = (
		result.duplicate(
			true
		)
	)

	var route: StringName = (
		result.get(
			"route",
			&"NONE"
		)
	)

	# Side correction only.
	# This is not an ejection or movement mechanic.
	if route == &"SIDE_CORRECTION":
		var offset: Vector2 = (
			result.get(
				"offset",
				Vector2.ZERO
			)
		)

		player.global_position += (
			offset
		)

		ejection_debug_changed.emit(
			false,
			_direction_name(
				result.get(
					"direction",
					Vector2.ZERO
				)
			),
			&"SIDE_CORRECTION",
			int(
				result.get(
					"distance",
					0
				)
			),
			false
		)

		await get_tree().process_frame

		return

	if route != &"UP":
		return

	var distance := float(
		result.get(
			"distance",
			0
		)
	)

	if distance <= 0.0:
		await get_tree().process_frame
		return

	_ejection_hazard_protected = true
	_ejection_hazard_grace_timer = 0.0

	ejection_debug_changed.emit(
		true,
		&"UP",
		&"UP",
		int(distance),
		false
	)

	var start_x := (
		player.global_position.x
	)

	var remaining := (
		distance
	)

	var travel_speed := 0.0

	while remaining > 0.0:
		await get_tree().physics_frame

		if player == null:
			return

		var delta := (
			get_physics_process_delta_time()
		)

		travel_speed = minf(
			travel_speed
			+ (
				travel_acceleration
				* delta
			),
			max_travel_speed
		)

		var movement := minf(
			travel_speed
			* delta,
			remaining
		)

		player.global_position = Vector2(
			start_x,
			player.global_position.y
			- movement
		)

		remaining -= (
			movement
		)

	_last_travel_speed = (
		travel_speed
	)


func finish_color_transaction(
	had_overlap: bool
) -> void:
	if player == null:
		return

	if not is_color_transaction_active:
		return

	if (
		player_death != null
		and player_death.is_dead
	):
		_clear_ejection_hazard_protection()

		_restore_player_physics()

		is_color_transaction_active = false

		_last_ejection_result.clear()

		return

	var state := (
		player.movement.movement_state
	)

	var route: StringName = (
		&"NONE"
	)

	if (
		had_overlap
		and not _last_ejection_result.is_empty()
	):
		route = (
			_last_ejection_result.get(
				"route",
				&"NONE"
			)
		)

	if route == &"UP":
		state.StateMachineState = (
			player.StNormal
		)

		# Successful upward color ejection
		# refills the player's dash.
		state.Dashes = (
			player.MaxDashes
		)

		state.Speed.x = 0.0

		state.Speed.y = (
			-maxf(
				0.0,
				exit_speed
			)
		)

		state.DashDir = (
			Vector2.ZERO
		)

		state.dashPending = false
		state.StartedDashing = false
		state.Ducking = false

		state.jumpGraceTimer = (
			player.JumpGraceTime
		)

		_arm_ejection_lift_boost(
			_last_travel_speed
		)

		_start_ejection_hazard_grace()

	else:
		# Normal color change or side correction.
		# Movement remains exactly as it was.
		state.Speed = (
			_pre_speed
		)

		state.StateMachineState = (
			_pre_state_machine_state
		)

		state.LiftBoost = (
			_pre_lift_boost
		)

		_clear_ejection_hazard_protection()

	_restore_player_physics()

	is_color_transaction_active = false

	ejection_debug_changed.emit(
		false,
		&"UP" if route == &"UP" else &"NONE",
		route,
		int(
			_last_ejection_result.get(
				"distance",
				0
			)
		),
		false
	)

	_last_ejection_result.clear()


func get_player_collision_shape() -> CollisionShape2D:
	return player_collision_shape


func route_blocked_by_active_world(
	offset: Vector2
) -> bool:
	if player == null:
		return true

	return player.test_move(
		player.global_transform,
		offset
	)


func is_hazard_protected() -> bool:
	return _ejection_hazard_protected


func _start_ejection_hazard_grace() -> void:
	if ejection_hazard_grace_time <= 0.0:
		_clear_ejection_hazard_protection()
		return

	_ejection_hazard_protected = true

	_ejection_hazard_grace_timer = (
		ejection_hazard_grace_time
	)


func _clear_ejection_hazard_protection() -> void:
	_ejection_hazard_protected = false
	_ejection_hazard_grace_timer = 0.0


func _arm_ejection_lift_boost(
	travel_speed: float
) -> void:
	if player == null:
		return

	if _ejection_lift_active:
		_clear_ejection_lift_boost()

	var state := (
		player.movement.movement_state
	)

	var upward_lift := (
		-absf(
			travel_speed
		)
	)

	upward_lift = maxf(
		upward_lift,
		-lift_boost_cap
	)

	_ejection_lift_value = Vector2(
		0.0,
		upward_lift
	)

	state.LiftBoost = (
		_ejection_lift_value
	)

	_ejection_lift_timer = (
		player.JumpGraceTime
	)

	_ejection_lift_active = true


func _clear_ejection_lift_boost() -> void:
	if not _ejection_lift_active:
		return

	if player != null:
		var state := (
			player.movement.movement_state
		)

		if (
			state.LiftBoost
			== _ejection_lift_value
		):
			state.LiftBoost = (
				Vector2.ZERO
			)

	_ejection_lift_active = false

	_ejection_lift_timer = 0.0

	_ejection_lift_value = (
		Vector2.ZERO
	)


func _on_movement_state_changed(
	event_player: PlayerRoot,
	state_name: StringName
) -> void:
	if event_player != player:
		return

	if not _ejection_lift_active:
		return

	if (
		state_name == &"JUMP"
		or state_name == &"SUPER JUMP"
		or state_name == &"HYPER JUMP"
		or state_name == &"WAVEDASH"
		or state_name == &"WALL JUMP"
		or state_name == &"SUPER WALL JUMP"
	):
		_clear_ejection_lift_boost()


func _direction_name(
	direction: Vector2
) -> StringName:
	if direction == Vector2.LEFT:
		return &"LEFT"

	if direction == Vector2.RIGHT:
		return &"RIGHT"

	if direction == Vector2.UP:
		return &"UP"

	return &"NONE"


func _restore_player_physics() -> void:
	if player == null:
		return

	player.set_physics_process(
		_player_physics_was_enabled
	)
