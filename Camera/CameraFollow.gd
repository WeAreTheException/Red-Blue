extends Node2D
class_name CameraFollow


const CAMERA_BOUNDS_GROUP: StringName = &"camera_bounds"


@export_group("References")

@export var camera: Camera2D


@export_group("Vertical Follow")

# Normal jumps inside this distance do not
# affect the camera vertically.
@export var vertical_dead_zone_up_px: float = 30.0

@export var vertical_dead_zone_down_px: float = 24.0

# Speed used once the player actually pushes
# outside the vertical dead zone.
@export var vertical_follow_speed: float = 8.0


@export_group("Camera Damping")

# Ignore microscopic internal camera corrections.
@export var position_deadband_px: float = 0.5


@export_group("Pixel")

# Final rendered camera position stays on
# whole internal-resolution pixels.
@export var pixel_snap: bool = true


@export_group("Debug")

@warning_ignore("shadowed_global_identifier")
@export var print_debug: bool = true
@export var debug_key: Key = KEY_KP_6


var player: PlayerRoot = null
var current_bounds: CameraBounds = null


var _follow_position: Vector2 = Vector2.ZERO


var _horizontal_target_x: float = 0.0

var _horizontal_step_start_x: float = 0.0
var _horizontal_step_elapsed: float = 0.0

var _horizontal_transitioning: bool = false


var _look_ahead_x: float = 0.0


var _transition_speed_multiplier: float = 1.0


var _vertical_target_y: float = 0.0


var _initialized: bool = false


func _ready() -> void:
	if camera == null:
		camera = _find_camera()

	if camera == null:
		push_error(
			"CameraFollow: Camera2D child missing."
		)
		return

	camera.set_as_top_level(
		false
	)

	camera.position = Vector2.ZERO

	camera.position_smoothing_enabled = false

	camera.enabled = true

	camera.make_current()

	if print_debug:
		print(
			"CAMERA FOLLOW READY"
		)

	call_deferred(
		"_refresh_world_references"
	)


func _physics_process(
	delta: float
) -> void:
	if camera == null:
		return

	if (
		player == null
		or not is_instance_valid(
			player
		)
	):
		player = _find_player()

		if player == null:
			return

	var found_bounds: CameraBounds = (
		_find_bounds_for_player()
	)

	if found_bounds != current_bounds:
		current_bounds = found_bounds

		_initialized = false

		_horizontal_transitioning = false

		if (
			print_debug
			and current_bounds != null
		):
			print(
				"CAMERA FOLLOW -> NEW BOUNDS: ",
				current_bounds.name
			)

	if current_bounds == null:
		return

	if not _initialized:
		_initialize_follow()
		return

	if (
		current_bounds.horizontal_mode
		== CameraBounds.HorizontalMode.STEP
	):
		_update_look_ahead(
			delta
		)

		if not _horizontal_transitioning:
			_check_horizontal_step()

	if (
		current_bounds.vertical_mode
		== CameraBounds.VerticalMode.DEAD_ZONE
	):
		_update_vertical_target()


func _process(
	delta: float
) -> void:
	if not _initialized:
		return

	if current_bounds == null:
		return

	if camera == null:
		return

	if _horizontal_transitioning:
		_update_horizontal_transition(
			delta
		)

	_update_vertical_position(
		delta
	)

	_apply_camera_position()


func _initialize_follow() -> void:
	if (
		player == null
		or current_bounds == null
	):
		return

	var bounds: Rect2 = (
		current_bounds.get_global_rect()
	)

	var view_size: Vector2 = (
		_get_world_view_size()
	)

	var half_view: Vector2 = (
		view_size
		* 0.5
	)

	var initial_x: float = (
		bounds.position.x
		+ bounds.size.x * 0.5
	)

	if bounds.size.x > view_size.x:
		var legal_min_x: float = (
			bounds.position.x
			+ half_view.x
		)

		var legal_max_x: float = (
			bounds.end.x
			- half_view.x
		)

		var bounds_center_x: float = (
			bounds.position.x
			+ bounds.size.x * 0.5
		)

		var step_size: float = maxf(
			1.0,
			current_bounds.horizontal_step_distance_px
		)

		var player_clamped_x: float = clampf(
			player.global_position.x,
			legal_min_x,
			legal_max_x
		)

		var relative_step: float = (
			(
				player_clamped_x
				- bounds_center_x
			)
			/ step_size
		)

		var nearest_step: int = roundi(
			relative_step
		)

		initial_x = (
			bounds_center_x
			+ float(
				nearest_step
			)
			* step_size
		)

		initial_x = clampf(
			initial_x,
			legal_min_x,
			legal_max_x
		)

	var initial_position: Vector2 = (
		_clamp_to_bounds(
			Vector2(
				initial_x,
				player.global_position.y
			)
		)
	)

	_follow_position = (
		initial_position
	)

	_horizontal_target_x = (
		initial_position.x
	)

	_horizontal_step_start_x = (
		initial_position.x
	)

	_horizontal_step_elapsed = 0.0

	_horizontal_transitioning = false

	_look_ahead_x = 0.0

	_transition_speed_multiplier = 1.0

	_vertical_target_y = (
		initial_position.y
	)

	_initialized = true

	_apply_camera_position()

	if print_debug:
		print(
			"CAMERA FOLLOW INITIALIZED -> ",
			_follow_position
		)


func _update_look_ahead(
	delta: float
) -> void:
	var velocity_x: float = (
		player.velocity.x
	)

	var desired_look_ahead: float = 0.0

	if (
		absf(
			velocity_x
		)
		>= current_bounds.look_ahead_velocity_threshold
	):
		desired_look_ahead = (
			signf(
				velocity_x
			)
			* current_bounds.horizontal_look_ahead_px
		)

	var response_speed: float = (
		current_bounds.look_ahead_response_speed
	)

	if desired_look_ahead == 0.0:
		response_speed = (
			current_bounds.look_ahead_release_speed
		)

	_look_ahead_x = move_toward(
		_look_ahead_x,
		desired_look_ahead,
		response_speed
		* delta
	)


func _check_horizontal_step() -> void:
	var effective_player_x: float = (
		player.global_position.x
		+ _look_ahead_x
	)

	var left_trigger: float = (
		_horizontal_target_x
		- current_bounds.horizontal_trigger_distance_px
	)

	var right_trigger: float = (
		_horizontal_target_x
		+ current_bounds.horizontal_trigger_distance_px
	)

	if effective_player_x > right_trigger:
		_begin_horizontal_step(
			1
		)

	elif effective_player_x < left_trigger:
		_begin_horizontal_step(
			-1
		)


func _begin_horizontal_step(
	direction: int
) -> void:
	if direction == 0:
		return

	if current_bounds == null:
		return

	var bounds: Rect2 = (
		current_bounds.get_global_rect()
	)

	var view_size: Vector2 = (
		_get_world_view_size()
	)

	if bounds.size.x <= view_size.x:
		return

	var half_view_x: float = (
		view_size.x
		* 0.5
	)

	var legal_min_x: float = (
		bounds.position.x
		+ half_view_x
	)

	var legal_max_x: float = (
		bounds.end.x
		- half_view_x
	)

	var new_target_x: float = (
		_horizontal_target_x
		+ float(
			direction
		)
		* current_bounds.horizontal_step_distance_px
	)

	new_target_x = clampf(
		new_target_x,
		legal_min_x,
		legal_max_x
	)

	if (
		absf(
			new_target_x
			- _horizontal_target_x
		)
		<= position_deadband_px
	):
		return

	_horizontal_step_start_x = (
		_follow_position.x
	)

	_horizontal_target_x = (
		new_target_x
	)

	_horizontal_step_elapsed = 0.0

	_transition_speed_multiplier = 1.0

	_horizontal_transitioning = true

	if print_debug:
		print(
			"CAMERA STEP: ",
			_horizontal_step_start_x,
			" -> ",
			_horizontal_target_x
		)


func _update_horizontal_transition(
	delta: float
) -> void:
	var duration: float = maxf(
		0.001,
		current_bounds.horizontal_step_time
	)

	var player_distance_from_camera: float = absf(
		player.global_position.x
		- _follow_position.x
	)

	var desired_multiplier: float = 1.0

	var multiplier_response_speed: float = (
		current_bounds.catch_up_response_speed
	)

	if (
		player_distance_from_camera
		>= current_bounds.emergency_catch_up_distance_px
	):
		desired_multiplier = (
			current_bounds.emergency_catch_up_multiplier
		)

		multiplier_response_speed = (
			current_bounds.emergency_catch_up_response_speed
		)

	elif (
		player_distance_from_camera
		>= current_bounds.catch_up_distance_px
	):
		desired_multiplier = (
			current_bounds.catch_up_multiplier
		)

	var multiplier_weight: float = (
		1.0
		- exp(
			-multiplier_response_speed
			* delta
		)
	)

	_transition_speed_multiplier = lerpf(
		_transition_speed_multiplier,
		desired_multiplier,
		multiplier_weight
	)

	_horizontal_step_elapsed = minf(
		duration,
		_horizontal_step_elapsed
		+ delta
		* _transition_speed_multiplier
	)

	var t: float = (
		_horizontal_step_elapsed
		/ duration
	)

	t = clampf(
		t,
		0.0,
		1.0
	)

	var eased_t: float = (
		1.0
		- pow(
			1.0 - t,
			3.0
		)
	)

	var new_x: float = lerpf(
		_horizontal_step_start_x,
		_horizontal_target_x,
		eased_t
	)

	if (
		absf(
			new_x
			- _follow_position.x
		)
		> position_deadband_px
	):
		_follow_position.x = (
			new_x
		)

	if t >= 1.0:
		_follow_position.x = (
			_horizontal_target_x
		)

		_horizontal_transitioning = false

		_horizontal_step_elapsed = 0.0

		_transition_speed_multiplier = 1.0

		if print_debug:
			print(
				"CAMERA STEP FINISHED -> ",
				_horizontal_target_x
			)


func _update_vertical_target() -> void:
	var player_y: float = (
		player.global_position.y
	)

	var top_limit: float = (
		_vertical_target_y
		- vertical_dead_zone_up_px
	)

	var bottom_limit: float = (
		_vertical_target_y
		+ vertical_dead_zone_down_px
	)

	if player_y < top_limit:
		_vertical_target_y = (
			player_y
			+ vertical_dead_zone_up_px
		)

	elif player_y > bottom_limit:
		_vertical_target_y = (
			player_y
			- vertical_dead_zone_down_px
		)


func _update_vertical_position(
	delta: float
) -> void:
	if current_bounds == null:
		return

	var vertical_target: Vector2 = (
		_clamp_to_bounds(
			Vector2(
				_follow_position.x,
				_vertical_target_y
			)
		)
	)

	var difference: float = (
		vertical_target.y
		- _follow_position.y
	)

	if (
		absf(
			difference
		)
		<= position_deadband_px
	):
		return

	var weight: float = (
		1.0
		- exp(
			-vertical_follow_speed
			* delta
		)
	)

	_follow_position.y = lerpf(
		_follow_position.y,
		vertical_target.y,
		weight
	)


func _clamp_to_bounds(
	target: Vector2
) -> Vector2:
	if current_bounds == null:
		return target

	var bounds: Rect2 = (
		current_bounds.get_global_rect()
	)

	var view_size: Vector2 = (
		_get_world_view_size()
	)

	var half_view: Vector2 = (
		view_size
		* 0.5
	)

	var result: Vector2 = target

	if bounds.size.x <= view_size.x:
		result.x = (
			bounds.position.x
			+ bounds.size.x * 0.5
		)

	else:
		result.x = clampf(
			target.x,
			bounds.position.x
			+ half_view.x,
			bounds.end.x
			- half_view.x
		)

	if bounds.size.y <= view_size.y:
		result.y = (
			bounds.position.y
			+ bounds.size.y * 0.5
		)

	else:
		result.y = clampf(
			target.y,
			bounds.position.y
			+ half_view.y,
			bounds.end.y
			- half_view.y
		)

	return result


func _get_world_view_size() -> Vector2:
	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)

	var safe_zoom: Vector2 = Vector2(
		maxf(
			0.001,
			camera.zoom.x
		),
		maxf(
			0.001,
			camera.zoom.y
		)
	)

	return Vector2(
		viewport_size.x
		/ safe_zoom.x,
		viewport_size.y
		/ safe_zoom.y
	)


func _apply_camera_position() -> void:
	if pixel_snap:
		global_position = Vector2(
			roundf(
				_follow_position.x
			),
			roundf(
				_follow_position.y
			)
		)

	else:
		global_position = (
			_follow_position
		)


func _unhandled_input(
	event: InputEvent
) -> void:
	if not event is InputEventKey:
		return

	var key_event: InputEventKey = (
		event as InputEventKey
	)

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	if key_event.keycode != debug_key:
		return

	_print_debug_snapshot()


func _print_debug_snapshot() -> void:
	print(
		""
	)

	print(
		"========== CAMERA DEBUG =========="
	)

	if player == null:
		print(
			"PLAYER: NULL"
		)

	else:
		print(
			"PLAYER: ",
			player.name
		)

		print(
			"PLAYER POS: ",
			player.global_position
		)

		print(
			"PLAYER VELOCITY: ",
			player.velocity
		)

	print(
		"CAMERA ROOT POS: ",
		global_position
	)

	print(
		"FOLLOW POS: ",
		_follow_position
	)

	print(
		"HORIZONTAL TARGET X: ",
		_horizontal_target_x
	)

	print(
		"LOOK AHEAD X: ",
		_look_ahead_x
	)

	print(
		"HORIZONTAL TRANSITIONING: ",
		_horizontal_transitioning
	)

	print(
		"TRANSITION SPEED MULTIPLIER: ",
		_transition_speed_multiplier
	)

	if current_bounds == null:
		print(
			"CURRENT BOUNDS: NULL"
		)

	else:
		var bounds_rect: Rect2 = (
			current_bounds.get_global_rect()
		)

		print(
			"TRIGGER DISTANCE: ",
			current_bounds.horizontal_trigger_distance_px
		)

		print(
			"STEP DISTANCE: ",
			current_bounds.horizontal_step_distance_px
		)

		print(
			"STEP TIME: ",
			current_bounds.horizontal_step_time
		)

		if player != null:
			var camera_player_distance: float = absf(
				player.global_position.x
				- _follow_position.x
			)

			print(
				"PLAYER CAMERA DISTANCE: ",
				camera_player_distance
			)

			print(
				"CATCH UP ACTIVE: ",
				camera_player_distance
				>= current_bounds.catch_up_distance_px
			)

			print(
				"EMERGENCY CATCH UP: ",
				camera_player_distance
				>= current_bounds.emergency_catch_up_distance_px
			)

		print(
			"CURRENT BOUNDS: ",
			current_bounds.name
		)

		print(
			"BOUNDS RECT: ",
			bounds_rect
		)

		print(
			"BOUNDS SIZE: ",
			bounds_rect.size
		)

	if camera != null:
		print(
			"WORLD VIEW SIZE: ",
			_get_world_view_size()
		)

		print(
			"CAMERA2D GLOBAL POS: ",
			camera.global_position
		)

		print(
			"CAMERA2D OFFSET: ",
			camera.offset
		)

		print(
			"THIS CAMERA IS CURRENT: ",
			get_viewport().get_camera_2d()
			== camera
		)

	print(
		"=================================="
	)

	print(
		""
	)


func _refresh_world_references() -> void:
	player = _find_player()

	if player == null:
		if print_debug:
			print(
				"CAMERA FOLLOW: PlayerRoot not found."
			)

		return

	current_bounds = (
		_find_bounds_for_player()
	)

	if current_bounds == null:
		if print_debug:
			print(
				"CAMERA FOLLOW: CameraBounds not found."
			)

		return

	_initialize_follow()


func _find_camera() -> Camera2D:
	for child: Node in get_children():
		if child is Camera2D:
			return (
				child
				as Camera2D
			)

	return null


func _find_player() -> PlayerRoot:
	var current_scene: Node = (
		get_tree().current_scene
	)

	if current_scene == null:
		return null

	return _find_player_recursive(
		current_scene
	)


func _find_player_recursive(
	node: Node
) -> PlayerRoot:
	if node is PlayerRoot:
		return (
			node
			as PlayerRoot
		)

	for child: Node in node.get_children():
		var found_player: PlayerRoot = (
			_find_player_recursive(
				child
			)
		)

		if found_player != null:
			return found_player

	return null


func _find_bounds_for_player() -> CameraBounds:
	if player == null:
		return null

	if (
		current_bounds != null
		and is_instance_valid(
			current_bounds
		)
		and current_bounds.contains_global_point(
			player.global_position
		)
	):
		return current_bounds

	var nodes: Array[Node] = (
		get_tree().get_nodes_in_group(
			CAMERA_BOUNDS_GROUP
		)
	)

	var only_bounds: CameraBounds = null
	var bounds_count: int = 0

	for node: Node in nodes:
		if not node is CameraBounds:
			continue

		var bounds: CameraBounds = (
			node
			as CameraBounds
		)

		bounds_count += 1
		only_bounds = bounds

		if bounds.contains_global_point(
			player.global_position
		):
			return bounds

	if bounds_count == 1:
		return only_bounds

	return null
