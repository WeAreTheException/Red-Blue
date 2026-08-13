extends Camera2D
class_name CameraShake


@export_group("Dash Shake")

@export var dash_strength_px: float = 8.0
@export var dash_time: float = 0.10


@export_group("Shake Style")

@export var max_offset_px: float = 30.0

@export var directional_ratio: float = 0.85
@export var noise_ratio: float = 0.15
@export var noise_px_cap: float = 3.0
@export var decay_curve_power: float = 2.0


var _dir: Vector2 = Vector2.ZERO
var _strength_px: float = 0.0
var _time_left: float = 0.0
var _duration: float = 0.0


func _ready() -> void:
	PlayerEvents.dash_direction_set.connect(
		_on_dash_direction_set
	)


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


func _process(
	delta: float
) -> void:
	if (
		_time_left <= 0.0
		or _strength_px <= 0.0
	):
		offset = Vector2.ZERO
		return

	_time_left = maxf(
		0.0,
		_time_left - delta
	)

	var t := (
		_time_left
		/ _duration
	)

	var falloff := pow(
		t,
		decay_curve_power
	)

	var dir_part := (
		_dir
		* (
			_strength_px
			* directional_ratio
		)
	)

	var jitter := Vector2(
		randf_range(
			-1.0,
			1.0
		),
		randf_range(
			-1.0,
			1.0
		)
	)

	var noise_amt := minf(
		noise_px_cap,
		_strength_px
		* noise_ratio
	)

	var noise_part := (
		jitter
		* noise_amt
	)

	var out := (
		dir_part
		+ noise_part
	) * falloff

	if out.length() > max_offset_px:
		out = (
			out.normalized()
			* max_offset_px
		)

	offset = out
