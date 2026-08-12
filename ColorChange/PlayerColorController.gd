extends Node
class_name PlayerColorController


const ACTION_SWAP: StringName = &"SWAP"


@export_group("Starting Color")

@export_enum(
	"RED",
	"BLUE"
)
var starting_color: int = (
	ColorState.PlayerColor.RED
)


@export_group("Player Visual")

@export var player_visual: ColorRect

@export var red_color: Color = Color8(
	173,
	50,
	12,
	255
)

@export var blue_color: Color = Color8(
	43,
	60,
	154,
	255
)


var color_state: ColorState = null


func _ready() -> void:
	_connect_to_color_system()


func _input(
	event: InputEvent
) -> void:
	if color_state == null:
		return

	if not event.is_action_pressed(
		ACTION_SWAP
	):
		return

	color_state.request_toggle()


func _connect_to_color_system() -> void:
	var color_system: ColorSystemRoot = (
		ColorSystemRoot.instance
	)

	if color_system == null:
		push_error(
			"PlayerColorController could not find ColorSystemRoot."
		)

		return

	color_state = (
		color_system.color_state
	)

	if color_state == null:
		push_error(
			"ColorSystemRoot has no ColorState assigned."
		)

		return

	color_state.color_change_requested.connect(
		_on_color_change_requested
	)

	color_state.color_changed.connect(
		_on_color_changed
	)

	color_state.initial_color_set.connect(
		_on_initial_color_set
	)

	color_state.color_change_cancelled.connect(
		_on_color_change_cancelled
	)

	if not color_state.has_initial_color:
		color_state.set_initial_color(
			starting_color
		)

	else:
		_apply_player_color(
			color_state.current_color
		)


func _on_color_change_requested(
	_previous_color: int,
	new_color: int
) -> void:
	_apply_player_color(
		new_color
	)


func _on_color_changed(
	_previous_color: int,
	new_color: int
) -> void:
	_apply_player_color(
		new_color
	)


func _on_initial_color_set(
	new_color: int
) -> void:
	_apply_player_color(
		new_color
	)


func _on_color_change_cancelled(
	current_color: int
) -> void:
	_apply_player_color(
		current_color
	)


func _apply_player_color(
	player_color: int
) -> void:
	if player_visual == null:
		return

	if (
		player_color
		== ColorState.PlayerColor.BLUE
	):
		player_visual.color = (
			blue_color
		)

	else:
		player_visual.color = (
			red_color
		)
