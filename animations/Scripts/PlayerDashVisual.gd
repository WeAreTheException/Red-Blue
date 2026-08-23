extends Node2D
class_name PlayerDashVisual


@export var dash_visual: AnimatedSprite2D
@export var dash_animation: StringName = &"dash"


var player: PlayerRoot = null


func _ready() -> void:
	player = get_parent() as PlayerRoot

	if player == null:
		push_error(
			"PlayerDashVisual must be a direct child of PlayerRoot."
		)
		return

	if dash_visual == null:
		push_error(
			"PlayerDashVisual has no Dash Visual assigned."
		)
		return

	PlayerEvents.dashed.connect(
		_on_dashed
	)


func _on_dashed(
	event_player: PlayerRoot
) -> void:
	if event_player != player:
		return

	dash_visual.stop()
	dash_visual.frame = 0
	dash_visual.play(
		dash_animation
	)
