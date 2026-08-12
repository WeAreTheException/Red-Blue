extends Label
class_name PlayerStateDebugLabel

@export_group("Color Debug")
@export var color_state: ColorState
@export var color_ejection_bridge: PlayerColorEjectionBridge

var movement_state_name: StringName = &"WAITING"
var color_name: StringName = &"UNKNOWN"

var color_eject_active: bool = false
var eject_direction: StringName = &"NONE"
var eject_route: StringName = &"NONE"
var eject_distance: int = 0
var color_boost_applied: bool = false

func _ready() -> void:
	var player_events := get_node_or_null("/root/PlayerEvents")

	if player_events == null:
		movement_state_name = &"PLAYER EVENTS MISSING"
	else:
		player_events.movement_state_changed.connect(_on_movement_state_changed)

	if color_state != null:
		color_name = ColorState.player_color_name(color_state.current_color)
		color_state.initial_color_set.connect(_on_initial_color_set)
		color_state.color_changed.connect(_on_color_changed)

	if color_ejection_bridge != null:
		color_ejection_bridge.ejection_debug_changed.connect(
			_on_ejection_debug_changed
		)

	_refresh_text()

func _on_movement_state_changed(
	_player: PlayerRoot,
	state_name: StringName
) -> void:
	movement_state_name = state_name
	print(state_name)
	_refresh_text()

func _on_initial_color_set(new_color: int) -> void:
	color_name = ColorState.player_color_name(new_color)
	_refresh_text()

func _on_color_changed(_previous_color: int, new_color: int) -> void:
	color_name = ColorState.player_color_name(new_color)
	_refresh_text()

func _on_ejection_debug_changed(
	is_ejecting: bool,
	direction_name: StringName,
	route_name: StringName,
	distance: int,
	boost_applied: bool
) -> void:
	color_eject_active = is_ejecting
	eject_direction = direction_name
	eject_route = route_name
	eject_distance = distance
	color_boost_applied = boost_applied
	_refresh_text()

func _refresh_text() -> void:
	text = (
		"STATE: " + str(movement_state_name)
		+ "\nCOLOR: " + str(color_name)
		+ "\nCOLOR EJECT: " + str(color_eject_active)
		+ "\nEJECT: " + str(eject_direction)
		+ "\nROUTE: " + str(eject_route) + " " + str(eject_distance) + "px"
		+ "\nCOLOR BOOST: " + str(color_boost_applied)
	)
