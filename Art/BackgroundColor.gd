extends ColorRect
class_name WorldBackgroundColor


@export_group("Background Colors")

@export var red_background: Color = Color8(
	65,
	25,
	25,
	255
)

@export var blue_background: Color = Color8(
	25,
	44,
	65,
	255
)


var color_state: ColorState = null


func _ready() -> void:
	var color_system: ColorSystemRoot = (
		ColorSystemRoot.instance
	)

	if color_system == null:
		push_error(
			"WorldBackgroundColor could not find ColorSystemRoot."
		)
		return

	color_state = color_system.color_state

	if color_state == null:
		push_error(
			"ColorSystemRoot has no ColorState assigned."
		)
		return

	color_state.color_changed.connect(
		_on_color_changed
	)

	color_state.initial_color_set.connect(
		_on_initial_color_set
	)

	_apply_background_color(
		color_state.current_color
	)


func _on_color_changed(
	_previous_color: int,
	new_color: int
) -> void:
	_apply_background_color(
		new_color
	)


func _on_initial_color_set(
	new_color: int
) -> void:
	_apply_background_color(
		new_color
	)


func _apply_background_color(
	player_color: int
) -> void:
	if (
		player_color
		== ColorState.PlayerColor.BLUE
	):
		color = red_background

	else:
		color = blue_background
