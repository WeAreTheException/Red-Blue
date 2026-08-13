extends Node


signal movement_state_changed(
	player: PlayerRoot,
	state_name: StringName
)

signal jumped(player: PlayerRoot)
signal super_jumped(player: PlayerRoot)
signal dashed(player: PlayerRoot)

signal dash_direction_set(
	player: PlayerRoot,
	direction: Vector2
)

signal wall_jumped(player: PlayerRoot)
signal super_wall_jumped(player: PlayerRoot)
signal landed(player: PlayerRoot)

signal wavedashed(player: PlayerRoot)

signal player_died(player: PlayerRoot)
signal player_respawned(player: PlayerRoot)


func broadcast_movement_state(
	player: PlayerRoot,
	state_name: StringName
) -> void:
	movement_state_changed.emit(
		player,
		state_name
	)

	match state_name:
		&"JUMP":
			jumped.emit(
				player
			)

		&"SUPER JUMP":
			super_jumped.emit(
				player
			)

		&"DASH":
			dashed.emit(
				player
			)

		&"WALL JUMP":
			wall_jumped.emit(
				player
			)

		&"SUPER WALL JUMP":
			super_wall_jumped.emit(
				player
			)

		&"LANDED":
			landed.emit(
				player
			)

		&"WAVEDASH":
			wavedashed.emit(
				player
			)


func broadcast_dash_direction(
	player: PlayerRoot,
	direction: Vector2
) -> void:
	dash_direction_set.emit(
		player,
		direction
	)


func broadcast_player_died(
	player: PlayerRoot
) -> void:
	player_died.emit(
		player
	)


func broadcast_player_respawned(
	player: PlayerRoot
) -> void:
	player_respawned.emit(
		player
	)
