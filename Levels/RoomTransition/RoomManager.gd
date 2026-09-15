extends Node2D
class_name RoomManager


const ROOM_MANAGER_GROUP: StringName = &"room_manager"
const CAMERA_FOLLOW_GROUP: StringName = &"camera_follow"


@export_group("References")

@export var player: PlayerRoot


@export_group("Starting Room")

@export var starting_spawn_id: StringName = &"from_left"


@export_group("Debug")

@export var print_debug: bool = true


var _transitioning: bool = false


func _ready() -> void:
	add_to_group(
		ROOM_MANAGER_GROUP
	)

	print(
		"ROOM MANAGER READY -> ",
		get_path()
	)

	_place_player_at_start()


func transition_to_room(
	room_scene: PackedScene,
	spawn_id: StringName
) -> void:
	print(
		"ROOM MANAGER -> TRANSITION CALLED"
	)

	if _transitioning:
		print(
			"ROOM MANAGER -> ALREADY TRANSITIONING"
		)
		return

	if room_scene == null:
		print(
			"ROOM MANAGER -> DESTINATION ROOM NULL"
		)
		return

	if player == null:
		print(
			"ROOM MANAGER -> PLAYER NULL"
		)
		return

	print(
		"ROOM MANAGER -> SEARCHING FOR ROOM"
	)

	var destination_room: Node = (
		_find_loaded_room(
			room_scene
		)
	)

	if destination_room == null:
		print(
			"ROOM MANAGER -> LOADED ROOM NOT FOUND: ",
			room_scene.resource_path
		)
		return

	print(
		"ROOM MANAGER -> ROOM FOUND: ",
		destination_room.name
	)

	var spawn: RespawnMarker = (
		_find_spawn(
			destination_room,
			spawn_id
		)
	)

	if spawn == null:
		print(
			"ROOM MANAGER -> SPAWN NOT FOUND: ",
			spawn_id
		)
		return

	print(
		"ROOM MANAGER -> SPAWN FOUND: ",
		spawn.global_position
	)

	var destination_bounds: CameraBounds = (
		_find_camera_bounds(
			destination_room
		)
	)

	if destination_bounds == null:
		print(
			"ROOM MANAGER -> CAMERA BOUNDS NOT FOUND"
		)
		return

	print(
		"ROOM MANAGER -> CAMERA BOUNDS FOUND: ",
		destination_bounds.name
	)

	var camera_follow: CameraFollow = (
		get_tree().get_first_node_in_group(
			CAMERA_FOLLOW_GROUP
		)
		as CameraFollow
	)

	if camera_follow == null:
		print(
			"ROOM MANAGER -> CAMERA FOLLOW NOT FOUND"
		)
		return

	print(
		"ROOM MANAGER -> CAMERA FOLLOW FOUND"
	)

	_transitioning = true

	camera_follow.lock_for_room_transition()

	print(
		"ROOM MANAGER -> CAMERA LOCKED"
	)

	player.set_physics_process(
		false
	)

	player.global_position = (
		spawn.global_position
	)

	player.respawn_point = spawn

	print(
		"ROOM MANAGER -> PLAYER MOVED"
	)

	camera_follow.start_room_transition(
		destination_bounds
	)

	print(
		"ROOM MANAGER -> CAMERA TRANSITION STARTED"
	)

	await camera_follow.room_transition_finished

	player.set_physics_process(
		true
	)

	_transitioning = false

	print(
		"ROOM MANAGER -> PLAYER UNFROZEN"
	)


func _place_player_at_start() -> void:
	if player == null:
		push_error(
			"RoomManager: Player missing."
		)
		return

	var current_room: Node = (
		_get_starting_room()
	)

	if current_room == null:
		push_error(
			"RoomManager: Starting room missing."
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


func _get_starting_room() -> Node:
	for child: Node in get_children():
		return child

	return null


func _find_loaded_room(
	room_scene: PackedScene
) -> Node:
	var target_path: String = (
		room_scene.resource_path
	)

	for child: Node in get_children():
		if child.scene_file_path == target_path:
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


func _find_camera_bounds(
	node: Node
) -> CameraBounds:
	if node is CameraBounds:
		return (
			node as CameraBounds
		)

	for child: Node in node.get_children():
		var found_bounds: CameraBounds = (
			_find_camera_bounds(
				child
			)
		)

		if found_bounds != null:
			return found_bounds

	return null
