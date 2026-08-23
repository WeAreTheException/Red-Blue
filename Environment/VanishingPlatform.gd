extends StaticBody2D
class_name VanishingPlatform


@export_group("References")

@export var visual: Node2D
@export var trigger_area: Area2D


@export_group("Timing")

@export var vanish_delay: float = 0.5
@export var respawn_delay: float = 1.5


@export_group("Feedback")

@export var shake_amount: float = 1.0
@export var shake_speed: float = 35.0


var _triggered: bool = false
var _vanished: bool = false

var _shake_time: float = 0.0
var _visual_start_position: Vector2 = Vector2.ZERO

var _original_collision_layer: int = 0


func _ready() -> void:
	_original_collision_layer = (
		collision_layer
	)

	if visual != null:
		_visual_start_position = (
			visual.position
		)

	if trigger_area == null:
		push_error(
			"VanishingPlatform: Trigger Area is not assigned."
		)

		return

	trigger_area.body_entered.connect(
		_on_trigger_body_entered
	)


func _process(
	delta: float
) -> void:
	if not _triggered:
		return

	if _vanished:
		return

	if visual == null:
		return

	_shake_time += delta

	var shake_x: float = (
		sin(
			_shake_time
			* shake_speed
		)
		* shake_amount
	)

	visual.position = (
		_visual_start_position
		+ Vector2(
			shake_x,
			0.0
		)
	)


func _on_trigger_body_entered(
	body: Node2D
) -> void:
	if _triggered:
		return

	if not body is PlayerRoot:
		return

	_start_vanish_cycle()


func _start_vanish_cycle() -> void:
	_triggered = true
	_shake_time = 0.0

	if trigger_area != null:
		trigger_area.set_deferred(
			"monitoring",
			false
		)

	await get_tree().create_timer(
		vanish_delay
	).timeout

	if not is_inside_tree():
		return

	_vanish()

	await get_tree().create_timer(
		respawn_delay
	).timeout

	if not is_inside_tree():
		return

	_respawn()


func _vanish() -> void:
	_vanished = true

	_reset_visual()

	if visual != null:
		visual.visible = false

	# Disable the StaticBody2D without caring
	# what type of collision child it uses.
	collision_layer = 0


func _respawn() -> void:
	_vanished = false

	collision_layer = (
		_original_collision_layer
	)

	if visual != null:
		visual.visible = true

	_reset_visual()

	_triggered = false

	if trigger_area != null:
		trigger_area.set_deferred(
			"monitoring",
			true
		)


func _reset_visual() -> void:
	if visual == null:
		return

	visual.position = (
		_visual_start_position
	)
