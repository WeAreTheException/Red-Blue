extends ColorRect
class_name SceneTransition


@export_range(
	0.05,
	2.0,
	0.05
)
var transition_duration: float = 0.4


var shader_material: ShaderMaterial
var is_transitioning: bool = false


func _ready() -> void:
	shader_material = (
		material
		as ShaderMaterial
	)

	if shader_material == null:
		print(
			"SCENE TRANSITION ERROR: SHADER MATERIAL MISSING"
		)
		return

	shader_material.set_shader_parameter(
		"animation_progress",
		0.0
	)

	PlayerEvents.player_died.connect(
		_on_player_died
	)


func _on_player_died(
	_player: PlayerRoot
) -> void:
	if is_transitioning:
		return

	is_transitioning = true

	var tween := create_tween()

	tween.tween_property(
		shader_material,
		"shader_parameter/animation_progress",
		1.0,
		transition_duration
	)

	await tween.finished

	get_tree().reload_current_scene()
