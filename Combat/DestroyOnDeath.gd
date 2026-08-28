extends Node
class_name DestroyOnDeath


@export_group("References")

@export var health: HealthComponent

# Leave empty to destroy this node's parent.
@export var destroy_target: Node


func _ready() -> void:
	if health == null:
		push_error(
			"DestroyOnDeath has no HealthComponent."
		)

		return

	health.died.connect(
		_on_died
	)


func _on_died(
	_info: DamageInfo
) -> void:
	var target: Node = (
		destroy_target
	)

	if target == null:
		target = get_parent()

	if target == null:
		return

	target.queue_free()
