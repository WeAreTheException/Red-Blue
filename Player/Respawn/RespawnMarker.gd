extends Area2D
class_name RespawnMarker


@export_group("Room Spawn")

@export var spawn_id: StringName = &"default"


@export_group("Debug")

@export var print_debug: bool = false


func _ready() -> void:
	body_entered.connect(
		_on_body_entered
	)


func _on_body_entered(
	body: Node2D
) -> void:
	var player := (
		body as PlayerRoot
	)

	if player == null:
		return

	player.respawn_point = self

	if print_debug:
		print(
			"RESPAWN POINT SET -> ",
			name,
			" | ",
			global_position
		)
