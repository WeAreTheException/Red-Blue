extends Node


signal player_registered(
	player: PlayerRoot
)

signal player_unregistered(
	player: PlayerRoot
)


var player: PlayerRoot = null


func _ready() -> void:
	get_tree().node_added.connect(
		_on_node_added
	)

	get_tree().node_removed.connect(
		_on_node_removed
	)

	call_deferred(
		"_find_existing_player"
	)


func get_player() -> PlayerRoot:
	if (
		player != null
		and is_instance_valid(
			player
		)
	):
		return player

	player = null

	_find_existing_player()

	return player


func _on_node_added(
	node: Node
) -> void:
	if not node is PlayerRoot:
		return

	_set_player(
		node as PlayerRoot
	)


func _on_node_removed(
	node: Node
) -> void:
	if player == null:
		return

	if node != player:
		return

	var previous_player := player

	player = null

	player_unregistered.emit(
		previous_player
	)

	call_deferred(
		"_find_existing_player"
	)


func _find_existing_player() -> void:
	if (
		player != null
		and is_instance_valid(
			player
		)
	):
		return

	player = null

	var root := (
		get_tree().root
	)

	if root == null:
		return

	var found_player := (
		_find_player_recursive(
			root
		)
	)

	if found_player == null:
		return

	_set_player(
		found_player
	)


func _find_player_recursive(
	node: Node
) -> PlayerRoot:
	if node is PlayerRoot:
		return (
			node as PlayerRoot
		)

	for child in node.get_children():
		var found_player := (
			_find_player_recursive(
				child
			)
		)

		if found_player != null:
			return found_player

	return null


func _set_player(
	new_player: PlayerRoot
) -> void:
	if new_player == null:
		return

	if (
		player != null
		and is_instance_valid(
			player
		)
		and player == new_player
	):
		return

	player = new_player

	player_registered.emit(
		player
	)
