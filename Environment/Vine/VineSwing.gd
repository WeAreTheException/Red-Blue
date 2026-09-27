extends Node2D
class_name VineSwing


@export_group("References")

@export var grab_area: Area2D
@export var end_point: Marker2D


@export_group("Swing")

@export var max_angle: float = 30.0

@export var min_entry_speed: float = 20.0

@export var min_swing_speed: float = 60.0
@export var max_swing_speed: float = 180.0

@export var entry_speed_multiplier: float = 0.75

@export var return_speed: float = 90.0

# How long the vine stays at its maximum angle
# before beginning to return toward center.
@export var return_pause_time: float = 0.05

# Once the vine actually begins returning,
# releasing briefly still launches in the
# original outward direction.
@export var exit_direction_grace_time: float = 0.12


@export_group("Dash")

@export var dash_swing_speed: float = 220.0


var angular_speed: float = 0.0

var _returning: bool = false

var _return_pause_timer: float = 0.0

var _exit_direction: int = 0
var _exit_direction_grace_timer: float = 0.0


func _ready() -> void:
	process_physics_priority = -10

	if grab_area == null:
		push_error(
			"VineSwing: Grab Area is missing."
		)

		return

	if end_point == null:
		push_error(
			"VineSwing: End Point is missing."
		)

		return

	grab_area.body_entered.connect(
		_on_body_entered
	)

	grab_area.body_exited.connect(
		_on_body_exited
	)


func _physics_process(
	delta: float
) -> void:
	if (
		_exit_direction_grace_timer
		> 0.0
	):
		_exit_direction_grace_timer = maxf(
			0.0,
			_exit_direction_grace_timer
			- delta
		)

	# Pause at the end of the swing before
	# beginning the return.
	if _return_pause_timer > 0.0:
		_return_pause_timer = maxf(
			0.0,
			_return_pause_timer
			- delta
		)

		if _return_pause_timer <= 0.0:
			_begin_return()

		return

	if _returning:
		_update_return(
			delta
		)

		return

	if is_zero_approx(
		angular_speed
	):
		return

	rotation_degrees += (
		angular_speed
		* delta
	)

	if rotation_degrees >= max_angle:
		rotation_degrees = max_angle

		_exit_direction = -int(
			sign(
				angular_speed
			)
		)

		angular_speed = 0.0

		_start_return_pause()

	elif rotation_degrees <= -max_angle:
		rotation_degrees = -max_angle

		_exit_direction = -int(
			sign(
				angular_speed
			)
		)

		angular_speed = 0.0

		_start_return_pause()


func begin_swing(
	entry_velocity_x: float
) -> void:
	if (
		absf(
			entry_velocity_x
		)
		< min_entry_speed
	):
		return

	var direction: int = int(
		sign(
			entry_velocity_x
		)
	)

	if direction == 0:
		return

	var speed: float = clampf(
		absf(
			entry_velocity_x
		)
		* entry_speed_multiplier,
		min_swing_speed,
		max_swing_speed
	)

	# Player horizontal travel and vine rotation
	# have opposite signs.
	angular_speed = (
		-speed
		* float(direction)
	)

	_returning = false
	_return_pause_timer = 0.0

	_exit_direction = direction
	_exit_direction_grace_timer = 0.0


func apply_dash_impulse(
	direction: int
) -> void:
	if direction == 0:
		return

	angular_speed = (
		-dash_swing_speed
		* float(direction)
	)

	_returning = false
	_return_pause_timer = 0.0

	_exit_direction = direction
	_exit_direction_grace_timer = 0.0


func is_swinging() -> bool:
	if not is_zero_approx(
		angular_speed
	):
		return true

	# The pause at maximum angle still counts
	# as part of the swing.
	if (
		_return_pause_timer > 0.0
		and not is_zero_approx(
			rotation_degrees
		)
	):
		return true

	if (
		_returning
		and not is_zero_approx(
			rotation_degrees
		)
	):
		return true

	return false


func get_motion_direction() -> int:
	# While paused at maximum extension,
	# releasing still sends the player outward.
	if (
		_return_pause_timer > 0.0
		and _exit_direction != 0
	):
		return _exit_direction

	# Shortly after the actual return begins,
	# preserve the outward exit direction.
	if (
		_exit_direction_grace_timer
		> 0.0
		and _exit_direction != 0
	):
		return _exit_direction

	# Normal outward swing.
	if not is_zero_approx(
		angular_speed
	):
		return -int(
			sign(
				angular_speed
			)
		)

	# Actual return movement after grace ends.
	if (
		_returning
		and not is_zero_approx(
			rotation_degrees
		)
	):
		return int(
			sign(
				rotation_degrees
			)
		)

	return 0


func _start_return_pause() -> void:
	_returning = false

	_exit_direction_grace_timer = 0.0

	_return_pause_timer = maxf(
		0.0,
		return_pause_time
	)

	if _return_pause_timer <= 0.0:
		_begin_return()


func _begin_return() -> void:
	_return_pause_timer = 0.0

	_returning = true

	_exit_direction_grace_timer = (
		exit_direction_grace_time
	)


func _update_return(
	delta: float
) -> void:
	if is_zero_approx(
		rotation_degrees
	):
		rotation_degrees = 0.0
		angular_speed = 0.0
		_returning = false

		return

	rotation_degrees = move_toward(
		rotation_degrees,
		0.0,
		return_speed
		* delta
	)

	if is_zero_approx(
		rotation_degrees
	):
		rotation_degrees = 0.0
		angular_speed = 0.0
		_returning = false


func _on_body_entered(
	body: Node2D
) -> void:
	var player := (
		body as PlayerRoot
	)

	if player == null:
		return

	if player.movement == null:
		return

	if player.movement.player_vine == null:
		return

	player.movement.player_vine.enter_vine_area(
		self
	)


func _on_body_exited(
	body: Node2D
) -> void:
	var player := (
		body as PlayerRoot
	)

	if player == null:
		return

	if player.movement == null:
		return

	if player.movement.player_vine == null:
		return

	player.movement.player_vine.exit_vine_area(
		self
	)
