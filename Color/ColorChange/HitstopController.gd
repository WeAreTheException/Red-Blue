extends Node
class_name HitstopController

signal hitstop_started(duration: float)
signal hitstop_finished

var is_hitstop_active: bool = false
var _hitstop_end_msec: int = 0
var _previous_time_scale: float = 1.0

func play_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return

	var requested_end := Time.get_ticks_msec() + int(round(duration * 1000.0))

	if is_hitstop_active:
		_hitstop_end_msec = max(_hitstop_end_msec, requested_end)
		await hitstop_finished
		return

	is_hitstop_active = true
	_hitstop_end_msec = requested_end
	_previous_time_scale = Engine.time_scale
	Engine.time_scale = 0.0

	hitstop_started.emit(duration)

	while is_hitstop_active and Time.get_ticks_msec() < _hitstop_end_msec:
		await get_tree().process_frame

	_finish_hitstop()

func force_finish_hitstop() -> void:
	if not is_hitstop_active:
		return
	_finish_hitstop()

func _finish_hitstop() -> void:
	if not is_hitstop_active:
		return

	is_hitstop_active = false
	Engine.time_scale = _previous_time_scale
	hitstop_finished.emit()

func _exit_tree() -> void:
	if is_hitstop_active:
		Engine.time_scale = _previous_time_scale
		is_hitstop_active = false
