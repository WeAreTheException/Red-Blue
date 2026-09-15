extends Area2D
class_name RoomExit


const ROOM_MANAGER_GROUP: StringName = &"room_manager"


enum ExitDirection {
	ANY,
	LEFT,
	RIGHT,
	UP,
	DOWN
}


@export_group("Destination")

@export var destination_room: PackedScene

@export var destination_spawn_id: StringName = &"default"


@export_group("Entry")

@export var required_direction: ExitDirection = (
	ExitDirection.ANY
)

@export var minimum_entry_speed: float = 1.0


@export_group("Debug")

@export var print_debug: bool = true


var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)

	body_exited.connect(
		_on_body_exited
	)


func _on_body_entered(
	body: Node2D
) -> void:
	var player: PlayerRoot = (
		body as PlayerRoot
	)

	if player == null:
		return

	if _triggered:
		return

	if not _is_correct_direction(
		player
	):
		if print_debug:
			print(
				"ROOM EXIT -> WRONG ENTRY DIRECTION"
			)

		return

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

	_triggered = true

	if print_debug:
		print(
			"ROOM EXIT -> ",
			destination_room,
			" | SPAWN: ",
			destination_spawn_id
		)

	room_manager.transition_to_room(
		destination_room,
		destination_spawn_id
	)


func _on_body_exited(
	body: Node2D
) -> void:
	var player: PlayerRoot = (
		body as PlayerRoot
	)

	if player == null:
		return

	_triggered = false


func _is_correct_direction(
	player: PlayerRoot
) -> bool:
	match required_direction:

		ExitDirection.LEFT:
			return (
				player.velocity.x
				< -minimum_entry_speed
			)

		ExitDirection.RIGHT:
			return (
				player.velocity.x
				> minimum_entry_speed
			)

		ExitDirection.UP:
			return (
				player.velocity.y
				< -minimum_entry_speed
			)

		ExitDirection.DOWN:
			return (
				player.velocity.y
				> minimum_entry_speed
			)

		_:
			return true
