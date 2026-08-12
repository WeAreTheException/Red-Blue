extends Node
class_name ColorReactive


signal active_changed(
	is_active: bool
)

signal activation_overlap(
	player: PlayerRoot
)


@export_group("Color")

@export_enum(
	"RED",
	"BLUE",
	"NEUTRAL"
)
var affiliation: int = (
	ColorState.Affiliation.NEUTRAL
)

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

@export var neutral_color: Color = Color8(
	65,
	65,
	65,
	255
)


@export_group("Visual")

@export_range(
	0.0,
	1.0,
	0.01
)
var inactive_opacity: float = 0.25


var color_system_root: ColorSystemRoot

var color_rect: ColorRect

var collision_shapes: Array[CollisionShape2D] = []

var is_active: bool = true


func _ready() -> void:
	_find_family_components()

	color_system_root = (
		ColorSystemRoot.instance
	)

	_apply_affiliation_color()

	if color_system_root != null:
		color_system_root.register_reactive(
			self
		)


func _exit_tree() -> void:
	if color_system_root != null:
		color_system_root.unregister_reactive(
			self
		)


func _find_family_components() -> void:
	var parent: Node = get_parent()

	if parent == null:
		return

	for child in parent.get_children():
		if (
			color_rect == null
			and child is ColorRect
		):
			color_rect = child as ColorRect

		if child is CollisionShape2D:
			collision_shapes.append(
				child as CollisionShape2D
			)


func should_be_active(
	player_color: int
) -> bool:
	if (
		affiliation
		== ColorState.Affiliation.NEUTRAL
	):
		return true

	if (
		affiliation
		== ColorState.Affiliation.RED
		and player_color
		== ColorState.PlayerColor.RED
	):
		return true

	if (
		affiliation
		== ColorState.Affiliation.BLUE
		and player_color
		== ColorState.PlayerColor.BLUE
	):
		return true

	return false


func begin_activation() -> void:
	_set_visual_active(
		true
	)


func complete_activation() -> void:
	if not is_active:
		is_active = true

		_set_visual_active(
			true
		)

		_set_collision_active(
			true
		)

		active_changed.emit(
			true
		)

		return

	_set_visual_active(
		true
	)

	_set_collision_active(
		true
	)


func deactivate() -> void:
	if is_active:
		is_active = false

		_set_visual_active(
			false
		)

		_set_collision_active(
			false
		)

		active_changed.emit(
			false
		)

		return

	_set_visual_active(
		false
	)

	_set_collision_active(
		false
	)


func set_active_immediate(
	active: bool
) -> void:
	var changed: bool = (
		is_active != active
	)

	is_active = active

	_set_visual_active(
		active
	)

	_set_collision_active(
		active
	)

	if changed:
		active_changed.emit(
			active
		)


func notify_activation_overlap(
	player: PlayerRoot
) -> void:
	activation_overlap.emit(
		player
	)


func has_solid_collision() -> bool:
	for collision_shape in collision_shapes:
		if (
			collision_shape != null
			and collision_shape.shape != null
		):
			return true

	return false


func get_collision_shapes() -> Array[CollisionShape2D]:
	return collision_shapes


func _apply_affiliation_color() -> void:
	if color_rect == null:
		return

	match affiliation:
		ColorState.Affiliation.RED:
			color_rect.color = (
				red_color
			)

		ColorState.Affiliation.BLUE:
			color_rect.color = (
				blue_color
			)

		_:
			color_rect.color = (
				neutral_color
			)


func _set_visual_active(
	active: bool
) -> void:
	if color_rect == null:
		return

	_apply_affiliation_color()

	if active:
		color_rect.modulate.a = 1.0

	else:
		color_rect.modulate.a = (
			inactive_opacity
		)


func _set_collision_active(
	active: bool
) -> void:
	for collision_shape in collision_shapes:
		if collision_shape == null:
			continue

		collision_shape.set_deferred(
			"disabled",
			not active
		)
