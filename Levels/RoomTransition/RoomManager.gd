extends Node2D
class_name RoomManager


const ROOM_MANAGER_GROUP: StringName = &"room_manager"


@export_group("References")

@export var player: PlayerRoot


@export_group("Starting Room")

@export var starting_spawn_id: StringName = &"from_left"


@export_group("Debug")

@export var print_debug: bool = true


func _ready() -> void:
	add_to_group(
		ROOM_MANAGER_GROUP
	)

	_place_player_at_start()


func transition_to_room(
	room_scene: PackedScene,
	spawn_id: StringName
) -> void:
	if room_scene == null:
		push_error(
			"RoomManager: Destination room missing."
		)
		return

	var current_room: Node = (
		_get_current_room()
	)

	if current_room != null:
		remove_child(
			current_room
		)

		current_room.queue_free()

	var new_room: Node = (
		room_scene.instantiate()
	)

	add_child(
		new_room
	)

	var spawn: RespawnMarker = (
		_find_spawn(
			new_room,
			spawn_id
		)
	)

	if spawn == null:
		push_error(
			"RoomManager: Spawn not found: "
			+ String(
				spawn_id
			)
		)
		return

	player.global_position = (
		spawn.global_position
	)

	player.respawn_point = spawn

	if print_debug:
		print(
			"ROOM MANAGER -> LOADED ROOM | SPAWN: ",
			spawn_id,
			" | ",
			spawn.global_position
		)


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

	player.respawn_point = spawn

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
