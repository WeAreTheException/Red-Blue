extends Node
class_name CameraRoot


@export_group("References")

@export var camera_shake: CameraShake
@export var room_transition: RoomTransition


func _ready() -> void:
	if camera_shake == null:
		push_error(
			"CameraRoot: CameraShake reference is missing."
		)
		return

	if room_transition == null:
		push_error(
			"CameraRoot: RoomTransition reference is missing."
		)
		return

	room_transition.camera = camera_shake
