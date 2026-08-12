extends Node
class_name ColorState


enum PlayerColor {
	RED,
	BLUE,
}


enum Affiliation {
	RED,
	BLUE,
	NEUTRAL,
}


signal color_change_requested(
	previous_color: int,
	new_color: int
)

signal color_changed(
	previous_color: int,
	new_color: int
)

signal initial_color_set(
	new_color: int
)

signal color_change_cancelled(
	current_color: int
)


var current_color: int = PlayerColor.RED

var has_initial_color: bool = false


func set_initial_color(
	new_color: int
) -> void:
	current_color = _sanitize_player_color(
		new_color
	)

	has_initial_color = true

	initial_color_set.emit(
		current_color
	)


func request_toggle() -> void:
	if current_color == PlayerColor.RED:
		request_color_change(
			PlayerColor.BLUE
		)

	else:
		request_color_change(
			PlayerColor.RED
		)


func request_color_change(
	new_color: int
) -> void:
	new_color = _sanitize_player_color(
		new_color
	)

	if new_color == current_color:
		return

	color_change_requested.emit(
		current_color,
		new_color
	)


func commit_color(
	new_color: int
) -> void:
	new_color = _sanitize_player_color(
		new_color
	)

	if new_color == current_color:
		return

	var previous_color: int = (
		current_color
	)

	current_color = new_color
	has_initial_color = true

	color_changed.emit(
		previous_color,
		current_color
	)


func cancel_requested_change() -> void:
	color_change_cancelled.emit(
		current_color
	)


func is_affiliation_active(
	affiliation: int,
	color: int = current_color
) -> bool:
	if affiliation == Affiliation.NEUTRAL:
		return true

	if (
		affiliation == Affiliation.RED
		and color == PlayerColor.RED
	):
		return true

	if (
		affiliation == Affiliation.BLUE
		and color == PlayerColor.BLUE
	):
		return true

	return false


static func player_color_name(
	color: int
) -> StringName:
	if color == PlayerColor.BLUE:
		return &"BLUE"

	return &"RED"


static func affiliation_name(
	affiliation: int
) -> StringName:
	match affiliation:
		Affiliation.RED:
			return &"RED"

		Affiliation.BLUE:
			return &"BLUE"

		_:
			return &"NEUTRAL"


func _sanitize_player_color(
	color: int
) -> int:
	if color == PlayerColor.BLUE:
		return PlayerColor.BLUE

	return PlayerColor.RED
