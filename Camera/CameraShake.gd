extends Camera2D
class_name CameraShake


@export_group("References")

@export var room_transition: RoomTransition


@export_group("Dash Shake")

@export var dash_strength_px: float = 8.0
@export var dash_time: float = 0.10


@export_group("Shake Style")

@export var max_offset_px: float = 30.0

@export var directional_ratio: float = 0.85
@export var noise_ratio: float = 0.15
@export var noise_px_cap: float = 3.0

@export var decay_curve_power: float = 2.0


@export_group("Shake Damping")

# How quickly the camera responds to the shake target.
#
# Higher = sharper / jerkier.
# Lower = softer / heavier.
@export var shake_response_speed: float = 32.0

# How quickly the camera settles back to zero
# after the active shake is finished.
@export var shake_return_speed: float = 24.0

# Once the remaining shake is this tiny,
# force it completely back to zero.
@export var shake_deadband_px: float = 0.20


@export_group("Room Transition Test")

@export var test_room_center: Marker2D
@export var test_transition_key: Key = KEY_KP_5


var _dir: Vector2 = Vector2.ZERO

var _strength_px: float = 0.0

var _time_left: float = 0.0
var _duration: float = 0.0

var _current_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	PlayerEvents.dash_direction_set.connect(
		_on_dash_direction_set
	)

	if room_transition != null:
		room_transition.camera = self


func _on_dash_direction_set(
	_player: PlayerRoot,
	direction: Vector2
) -> void:
	_start_shake(
		direction,
		dash_strength_px,
		dash_time
	)


func _start_shake(
	dir: Vector2,
	strength_px: float,
	time: float
) -> void:
	_dir = (
		dir.normalized()
		if dir.length() > 0.001
		else Vector2.ZERO
	)

	_strength_px = maxf(
		0.0,
		strength_px
	)

	_duration = maxf(
		0.001,
		time
	)

	_time_left = _duration


func _physics_process(
	delta: float
) -> void:
	if (
		_time_left > 0.0
		and _strength_px > 0.0
	):
		_update_active_shake(
			delta
		)

	else:
		_update_return(
			delta
		)

	_apply_offset()


func _update_active_shake(
	delta: float
) -> void:
	_time_left = maxf(
		0.0,
		_time_left - delta
	)

	var t: float = (
		_time_left
		/ _duration
	)

	var falloff: float = pow(
		t,
		decay_curve_power
	)

	var dir_part: Vector2 = (
		_dir
		* (
			_strength_px
			* directional_ratio
		)
	)

	var jitter: Vector2 = Vector2(
		randf_range(
			-1.0,
			1.0
		),
		randf_range(
			-1.0,
			1.0
		)
	)

	var noise_amt: float = minf(
		noise_px_cap,
		_strength_px
		* noise_ratio
	)

	var noise_part: Vector2 = (
		jitter
		* noise_amt
	)

	var target_offset: Vector2 = (
		dir_part
		+ noise_part
	) * falloff

	if (
		target_offset.length()
		> max_offset_px
	):
		target_offset = (
			target_offset.normalized()
			* max_offset_px
		)

	var response_weight: float = (
		1.0
		- exp(
			-shake_response_speed
			* delta
		)
	)

	_current_offset = (
		_current_offset.lerp(
			target_offset,
			response_weight
		)
	)


func _update_return(
	delta: float
) -> void:
	if (
		_current_offset.length()
		<= shake_deadband_px
	):
		_current_offset = Vector2.ZERO
		return

	var return_weight: float = (
		1.0
		- exp(
			-shake_return_speed
			* delta
		)
	)

	_current_offset = (
		_current_offset.lerp(
			Vector2.ZERO,
			return_weight
		)
	)


func _apply_offset() -> void:
	offset = Vector2(
		roundf(
			_current_offset.x
		),
		roundf(
			_current_offset.y
		)
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

	if key_event.keycode != test_transition_key:
		return

	if room_transition == null:
		print(
			"CAMERA TEST: RoomTransition missing"
		)
		return

	if test_room_center == null:
		print(
			"CAMERA TEST: Room center missing"
		)
		return

	print(
		"CAMERA TEST -> ",
		test_room_center.global_position
	)

	room_transition.transition_to(
		test_room_center.global_position
	)
