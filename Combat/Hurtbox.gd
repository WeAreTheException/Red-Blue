extends Area2D
class_name Hurtbox


@export_group("References")

@export var health: HealthComponent


func _ready() -> void:
	# Layer 5 = ENEMY_HURTBOX / HURTBOX
	collision_layer = 16

	collision_mask = 0

	# Hurtbox doesn't need to search for attacks.
	# Attacks search for the Hurtbox.
	monitoring = false
	monitorable = true


func receive_damage(
	info: DamageInfo
) -> void:
	if health == null:
		return

	health.take_damage(
		info
	)
