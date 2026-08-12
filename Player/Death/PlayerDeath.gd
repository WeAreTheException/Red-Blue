extends Node
class_name PlayerDeath


signal death_started
signal death_finished

signal respawn_started
signal respawn_finished


var player: PlayerRoot
var respawn: PlayerRespawn
var feedback: DeathFeedback

var is_dead: bool = false


func _ready() -> void:
	var parent_node := get_parent()

	player = parent_node as PlayerRoot

	if (
		player == null
		and parent_node != null
	):
		player = (
			parent_node.get_parent()
			as PlayerRoot
		)

	if player == null:
		print(
			"PLAYER DEATH ERROR: PLAYERROOT MISSING"
		)
		return

	# Respawn can either be beside Death under
	# the States node, or directly under Player.
	if parent_node != null:
		for child in parent_node.get_children():
			if child is PlayerRespawn:
				respawn = child as PlayerRespawn
				break

	if respawn == null:
		for child in player.get_children():
			if child is PlayerRespawn:
				respawn = child as PlayerRespawn
				break

	for child in get_children():
		if child is DeathFeedback:
			feedback = child as DeathFeedback
			break


func _input(
	event: InputEvent
) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	if (
		key_event.keycode == KEY_1
		or key_event.physical_keycode == KEY_1
		or key_event.keycode == KEY_KP_1
		or key_event.physical_keycode == KEY_KP_1
	):
		die()


func die() -> void:
	if is_dead:
		return

	if player == null:
		print(
			"PLAYER DIE BLOCKED: PLAYER MISSING"
		)
		return

	is_dead = true

	player.movement.disable_movement()

	death_started.emit()

	_broadcast_state(
		&"DEAD"
	)

	_broadcast_death()

	if feedback != null:
		await feedback.play_death()

	death_finished.emit()

	if respawn == null:
		print(
			"PLAYER RESPAWN COMPONENT MISSING"
		)

		player.movement.enable_movement()
		is_dead = false
		return

	respawn_started.emit()

	if not respawn.respawn():
		player.movement.enable_movement()
		is_dead = false
		return

	_broadcast_state(
		&"RESPAWN"
	)

	if feedback != null:
		await feedback.play_respawn()

	player.movement.enable_movement()

	is_dead = false

	_broadcast_respawn()

	respawn_finished.emit()


func _broadcast_state(
	state_name: StringName
) -> void:
	var player_events := get_node_or_null(
		"/root/PlayerEvents"
	)

	if player_events == null:
		return

	player_events.broadcast_movement_state(
		player,
		state_name
	)


func _broadcast_death() -> void:
	var player_events := get_node_or_null(
		"/root/PlayerEvents"
	)

	if player_events == null:
		return

	player_events.broadcast_player_died(
		player
	)


func _broadcast_respawn() -> void:
	var player_events := get_node_or_null(
		"/root/PlayerEvents"
	)

	if player_events == null:
		return

	player_events.broadcast_player_respawned(
		player
	)
