extends Node
class_name RoomTransition


signal transition_started
signal transition_midpoint
signal transition_finished


@export_group("Transition")

@export var transition_time: float = 0.70
@export var zoom_out_amount: float = 0.80


@export_group("Debug")

@warning_ignore("shadowed_global_identifier")
@export var print_debug: bool = false


var camera: CameraShake = null

var is_transitioning: bool = false


func transition_to(
	target_position: Vector2
) -> void:
	if is_transitioning:
		return

	if camera == null:
		push_error(
			"RoomTransition: Camera reference is missing."
		)
		return

	is_transitioning = true

	transition_started.emit()

	if print_debug:
		print(
			"ROOM TRANSITION START: ",
			camera.global_position,
			" -> ",
			target_position
		)

	var start_zoom: Vector2 = camera.zoom

	var zoomed_out: Vector2 = (
		start_zoom
		* zoom_out_amount
	)

	var move_tween: Tween = create_tween()

	move_tween.set_trans(
		Tween.TRANS_SINE
	)

	move_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	move_tween.tween_property(
		camera,
		"global_position",
		target_position,
		transition_time
	)

	var zoom_tween: Tween = create_tween()

	zoom_tween.set_trans(
		Tween.TRANS_SINE
	)

	zoom_tween.set_ease(
		Tween.EASE_IN_OUT
	)

	zoom_tween.tween_property(
		camera,
		"zoom",
		zoomed_out,
		transition_time * 0.5
	)

	zoom_tween.tween_callback(
		_on_transition_midpoint
	)

	zoom_tween.tween_property(
		camera,
		"zoom",
		start_zoom,
		transition_time * 0.5
	)

	await move_tween.finished

	camera.global_position = target_position
	camera.zoom = start_zoom

	is_transitioning = false

	transition_finished.emit()

	if print_debug:
		print(
			"ROOM TRANSITION FINISHED"
		)


func _on_transition_midpoint() -> void:
	transition_midpoint.emit()

	if print_debug:
		print(
			"ROOM TRANSITION MIDPOINT"
		)
