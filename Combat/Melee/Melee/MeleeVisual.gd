extends AnimatedSprite2D
class_name MeleeVisual


@export var melee_animation: StringName = &"melee"


func _unhandled_input(
	event: InputEvent
) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event := (
		event as InputEventMouseButton
	)

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not mouse_event.pressed:
		return

	play(
		melee_animation
	)
