extends Area2D
class_name Hazard

signal player_hit(player: PlayerRoot)

@export_group("Optional Color Link")
@export var color_reactive: ColorReactive

@export_group("Current Player Death")
@export var player_death: PlayerDeath

@export_group("Hitstop")
@export var hitstop_controller: HitstopController
@export var hostile_hitstop: float = 0.07

var hazard_enabled: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if color_reactive != null:
		color_reactive.active_changed.connect(_on_color_active_changed)
		color_reactive.activation_overlap.connect(_on_color_activation_overlap)
		_set_hazard_enabled(color_reactive.is_active)

func _on_body_entered(body: Node) -> void:
	if not hazard_enabled:
		return
	if not body is PlayerRoot:
		return

	hit_player(body as PlayerRoot)

func _on_color_active_changed(active: bool) -> void:
	_set_hazard_enabled(active)

func _on_color_activation_overlap(player: PlayerRoot) -> void:
	# ColorSystemRoot has already moved the Player safely outside
	# before this signal is emitted.
	hit_player(player)

func hit_player(player: PlayerRoot) -> void:
	if player == null:
		return

	player_hit.emit(player)

	if hitstop_controller != null and hostile_hitstop > 0.0:
		hitstop_controller.play_hitstop(hostile_hitstop)

	# Current Player has no HP/Hurt system, so Hazard uses the existing
	# PlayerDeath path when a PlayerDeath reference is assigned.
	if player_death != null and not player_death.is_dead:
		player_death.die()

func _set_hazard_enabled(enabled: bool) -> void:
	hazard_enabled = enabled
	set_deferred("monitoring", enabled)
