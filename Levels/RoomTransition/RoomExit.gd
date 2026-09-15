extends Area2D
class_name RoomExit


const ROOM_MANAGER_GROUP: StringName = &"room_manager"


@export_group("Destination")

@export var destination_room: PackedScene
@export var destination_spawn_id: StringName = &"default"


@export_group("Debug")

@export var print_debug: bool = true


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)


func _on_body_entered(
	body: Node2D
) -> void:
	var player: PlayerRoot = (
		body as PlayerRoot
	)

	if player == null:
		return

	if print_debug:
		print(
			"ROOM EXIT -> ",
			destination_room,
			" | SPAWN: ",
			destination_spawn_id
		)

	var room_manager: RoomManager = (
		get_tree().get_first_node_in_group(
			ROOM_MANAGER_GROUP
		)
		as RoomManager
	)

	if room_manager == null:
		push_error(
			"RoomExit: RoomManager not found."
		)
		return

	print(
		"ROOM EXIT -> ROOM MANAGER FOUND"
	)

	print(
		"ROOM EXIT -> MANAGER PATH: ",
		room_manager.get_path()
	)

	print(
		"ROOM EXIT -> CALLING TRANSITION NOW"
	)

	room_manager.transition_to_room(
		destination_room,
		destination_spawn_id
	)

	print(
		"ROOM EXIT -> TRANSITION CALL RETURNED"
	)
