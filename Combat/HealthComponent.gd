extends Node
class_name HealthComponent


signal damaged(
	info: DamageInfo
)

signal health_changed(
	current_health: float,
	max_health: float
)

signal died(
	info: DamageInfo
)


@export_group("Health")

@export var max_health: float = 100.0


var current_health: float = 0.0

var is_dead: bool = false


func _ready() -> void:
	reset_health()


func take_damage(
	info: DamageInfo
) -> void:
	if info == null:
		return

	if is_dead:
		return

	if info.damage <= 0.0:
		return

	current_health = maxf(
		0.0,
		current_health - info.damage
	)

	damaged.emit(
		info
	)

	health_changed.emit(
		current_health,
		max_health
	)

	if current_health <= 0.0:
		is_dead = true

		died.emit(
			info
		)


func heal(
	amount: float
) -> void:
	if is_dead:
		return

	if amount <= 0.0:
		return

	current_health = minf(
		max_health,
		current_health + amount
	)

	health_changed.emit(
		current_health,
		max_health
	)


func reset_health() -> void:
	current_health = maxf(
		0.0,
		max_health
	)

	is_dead = false

	health_changed.emit(
		current_health,
		max_health
	)
