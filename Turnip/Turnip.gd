extends Area2D
class_name Turnip


@export var sprite: Sprite2D


@export_group("Float")

@export var float_height: float = 2.0
@export var float_speed: float = 2.5
@export var sway_degrees: float = 2.0


var collected: bool = false

var original_scale: Vector2
var original_position: Vector2
var original_rotation: float

var float_time: float = 0.0


func _ready() -> void:
	if sprite != null:
		original_scale = sprite.scale
		original_position = sprite.position
		original_rotation = sprite.rotation

		float_time = randf_range(
			0.0,
			TAU
		)

	body_entered.connect(
		_on_body_entered
	)

	PlayerEvents.player_died.connect(
		_on_player_died
	)


func _process(
	delta: float
) -> void:
	if sprite == null:
		return

	if collected:
		return

	float_time += (
		delta
		* float_speed
	)

	sprite.position.y = (
		original_position.y
		+ sin(float_time)
		* float_height
	)

	sprite.rotation = (
		original_rotation
		+ deg_to_rad(sway_degrees)
		* sin(float_time * 0.5)
	)


func _on_body_entered(
	body: Node2D
) -> void:
	if collected:
		return

	if not body is PlayerRoot:
		return

	collected = true
	monitoring = false

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		sprite,
		"scale",
		Vector2.ZERO,
		0.12
	)

	tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		0.12
	)


func _on_player_died(
	_player: PlayerRoot
) -> void:
	if not collected:
		return

	collected = false
	monitoring = true

	sprite.position = original_position
	sprite.rotation = original_rotation

	sprite.scale = Vector2.ZERO
	sprite.modulate.a = 0.0

	var tween := create_tween()

	tween.tween_property(
		sprite,
		"modulate:a",
		1.0,
		0.05
	)

	tween.tween_property(
		sprite,
		"scale",
		original_scale * 1.25,
		0.10
	)

	tween.tween_property(
		sprite,
		"scale",
		original_scale * 0.90,
		0.06
	)

	tween.tween_property(
		sprite,
		"scale",
		original_scale * 1.06,
		0.05
	)

	tween.tween_property(
		sprite,
		"scale",
		original_scale,
		0.06
	)
