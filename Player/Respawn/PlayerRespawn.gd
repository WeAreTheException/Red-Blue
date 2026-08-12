extends Node
class_name PlayerRespawn


var player: PlayerRoot


func _ready() -> void:
	player = get_parent() as PlayerRoot


func respawn() -> bool:
	if player == null:
		return false

	if player.respawn_point == null:
		print("RESPAWN POINT MISSING")
		return false

	player.global_position = (
		player.respawn_point.global_position
	)

	player.movement.reset_movement()

	return true
