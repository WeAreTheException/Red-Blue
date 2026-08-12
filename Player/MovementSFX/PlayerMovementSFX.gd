extends Node
class_name PlayerMovementSFX


@export_group("Movement SFX")

@export var dash_sfx: AudioStreamPlayer
@export var jump_sfx: AudioStreamPlayer
@export var landed_sfx: AudioStreamPlayer


var player: PlayerRoot = null


func _ready() -> void:
	player = get_parent() as PlayerRoot

	if player == null:
		push_error(
			"PlayerMovementSFX must be a direct child of PlayerRoot."
		)
		return

	_connect_player_events()


func _connect_player_events() -> void:
	var player_events := get_node_or_null(
		"/root/PlayerEvents"
	)

	if player_events == null:
		push_error(
			"PlayerMovementSFX could not find PlayerEvents."
		)
		return

	player_events.dashed.connect(
		_on_dashed
	)

	player_events.jumped.connect(
		_on_jumped
	)

	player_events.landed.connect(
		_on_landed
	)


func _on_dashed(
	event_player: PlayerRoot
) -> void:
	if event_player != player:
		return

	if dash_sfx == null:
		return

	dash_sfx.play()


func _on_jumped(
	event_player: PlayerRoot
) -> void:
	if event_player != player:
		return

	if jump_sfx == null:
		return

	jump_sfx.play()


func _on_landed(
	event_player: PlayerRoot
) -> void:
	if event_player != player:
		return

	if landed_sfx == null:
		return

	landed_sfx.play()
