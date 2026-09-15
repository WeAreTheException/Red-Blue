extends Node2D
class_name RoomManager


@export_group("References")

@export var player: PlayerRoot


@export_group("Starting Room")

@export var starting_spawn_id: StringName = &"from_left"


@export_group("Debug")

@export var print_debug: bool = true


func _ready() -> void:
	_place_player_at_start()


func _place_player_at_start() -> void:
	if player == null:
		push_error(
			"RoomManager: Player missing."
		)
		return

	var current_room: Node = (
		_get_current_room()
	)

	if current_room == null:
		push_error(
			"RoomManager: Current room missing."
		)
		return

	var spawn: RespawnMarker = (
		_find_spawn(
			current_room,
			starting_spawn_id
		)
	)

	if spawn == null:
		push_error(
			"RoomManager: Spawn not found: "
			+ String(
				starting_spawn_id
			)
		)
		return

	player.global_position = (
		spawn.global_position
	)

	if print_debug:
		print(
			"ROOM MANAGER -> PLAYER SPAWNED AT: ",
			starting_spawn_id,
			" | ",
			spawn.global_position
		)


func _get_current_room() -> Node:
	for child: Node in get_children():
		return child

	return null


func _find_spawn(
	node: Node,
	target_spawn_id: StringName
) -> RespawnMarker:
	if node is RespawnMarker:
		var spawn: RespawnMarker = (
			node as RespawnMarker
		)

		if spawn.spawn_id == target_spawn_id:
			return spawn

	for child: Node in node.get_children():
		var found_spawn: RespawnMarker = (
			_find_spawn(
				child,
				target_spawn_id
			)
		)

		if found_spawn != null:
			return found_spawn

	return null
