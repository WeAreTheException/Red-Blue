extends Node2D
class_name RoomManager


const ROOM_MANAGER_GROUP: StringName = &"room_manager"
const CAMERA_FOLLOW_GROUP: StringName = &"camera_follow"


enum TransitionVelocityMode {
	PRESERVE,
	CLEAR
}


@export_group("References")

@export var player: PlayerRoot


@export_group("Starting Room")

@export var starting_spawn_id: StringName = &"from_left"


@export_group("Room Transition")

@export var pre_transition_freeze_time: float = 0.04

@export var post_transition_freeze_time: float = 0.10

@export var velocity_mode: TransitionVelocityMode = (
	TransitionVelocityMode.PRESERVE
)


@export_group("Debug")

@export var print_debug: bool = true


var _transitioning: bool = false

var _current_room: Node = null


func _ready() -> void:
	add_to_group(
		ROOM_MANAGER_GROUP
	)

	_place_player_at_start()


func transition_to_room(
	room_scene: PackedScene,
	spawn_id: StringName
) -> void:
	if _transitioning:
		return

	if room_scene == null:
		push_error(
			"RoomManager: Destination room missing."
		)

		return

	if player == null:
		push_error(
			"RoomManager: Player missing."
		)

		return

	var destination_room: Node = (
		_find_loaded_room(
			room_scene
		)
	)

	if destination_room == null:
		push_error(
			"RoomManager: Loaded destination room not found: "
			+ room_scene.resource_path
		)

		return


	# Do not transition to the room that is
	# already active.
	if destination_room == _current_room:
		if print_debug:
			print(
				"ROOM MANAGER -> ALREADY IN ROOM: ",
				destination_room.name
			)

		return


	var destination_bounds: CameraBounds = (
		_find_camera_bounds(
			destination_room
		)
	)

	if destination_bounds == null:
		push_error(
			"RoomManager: Destination CameraBounds missing."
		)

		return

	var destination_spawn: RespawnMarker = (
		_find_spawn(
			destination_room,
			spawn_id
		)
	)

	if destination_spawn == null:
		push_error(
			"RoomManager: Destination spawn not found: "
			+ String(
				spawn_id
			)
		)

		return

	var camera_follow: CameraFollow = (
		get_tree().get_first_node_in_group(
			CAMERA_FOLLOW_GROUP
		)
		as CameraFollow
	)

	if camera_follow == null:
		push_error(
			"RoomManager: CameraFollow not found."
		)

		return


	_transitioning = true


	var saved_velocity: Vector2 = (
		player.velocity
	)


	player.set_physics_process(
		false
	)

	camera_follow.lock_for_room_transition()


	if print_debug:
		print(
			"ROOM MANAGER -> PLAYER FROZEN"
		)


	if pre_transition_freeze_time > 0.0:
		await get_tree().create_timer(
			pre_transition_freeze_time
		).timeout


	camera_follow.start_room_transition(
		destination_bounds
	)


	if print_debug:
		print(
			"ROOM MANAGER -> CAMERA PAN START"
		)


	await camera_follow.room_transition_finished


	# Destination is now the active room.
	_current_room = (
		destination_room
	)


	# Update respawn without moving the player.
	player.respawn_point = (
		destination_spawn
	)


	if print_debug:
		print(
			"ROOM MANAGER -> CURRENT ROOM: ",
			_current_room.name
		)

		print(
			"ROOM MANAGER -> RESPAWN UPDATED: ",
			spawn_id
		)


	if post_transition_freeze_time > 0.0:
		await get_tree().create_timer(
			post_transition_freeze_time
		).timeout


	match velocity_mode:

		TransitionVelocityMode.PRESERVE:
			player.velocity = (
				saved_velocity
			)

		TransitionVelocityMode.CLEAR:
			player.velocity = (
				Vector2.ZERO
			)


	player.set_physics_process(
		true
	)

	_transitioning = false


	if print_debug:
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


	_current_room = (
		current_room
	)


	player.global_position = (
		spawn.global_position
	)

	player.respawn_point = spawn


	if print_debug:
		print(
			"ROOM MANAGER -> STARTING ROOM: ",
			_current_room.name
		)

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
