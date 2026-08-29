extends Area2D
class_name CameraBounds


const CAMERA_BOUNDS_GROUP: StringName = &"camera_bounds"


@export_group("References")

@export var bounds_shape: CollisionShape2D


@export_group("Debug")

@warning_ignore("shadowed_global_identifier")
@export var print_debug: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0

	monitoring = false
	monitorable = false

	add_to_group(
		CAMERA_BOUNDS_GROUP
	)

	if bounds_shape == null:
		bounds_shape = _find_bounds_shape()

	if bounds_shape == null:
		push_error(
			"CameraBounds: CollisionShape2D missing."
		)
		return

	if not bounds_shape.shape is RectangleShape2D:
		push_error(
			"CameraBounds: Shape must be RectangleShape2D."
		)
		return

	bounds_shape.disabled = true

	if print_debug:
		print(
			"CAMERA BOUNDS READY: ",
			get_global_rect()
		)


func contains_global_point(
	point: Vector2
) -> bool:
	return get_global_rect().has_point(
		point
	)


func get_global_rect() -> Rect2:
	if bounds_shape == null:
		return Rect2(
			global_position,
			Vector2.ZERO
		)

	var rectangle: RectangleShape2D = (
		bounds_shape.shape
		as RectangleShape2D
	)

	if rectangle == null:
		return Rect2(
			global_position,
			Vector2.ZERO
		)

	var shape_scale: Vector2 = (
		bounds_shape.global_scale
	)

	var scale_abs: Vector2 = Vector2(
		absf(
			shape_scale.x
		),
		absf(
			shape_scale.y
		)
	)

	var size: Vector2 = (
		rectangle.size
		* scale_abs
	)

	var center: Vector2 = (
		bounds_shape.global_position
	)

	return Rect2(
		center
		- size * 0.5,
		size
	)


func _find_bounds_shape() -> CollisionShape2D:
	for child: Node in get_children():
		if child is CollisionShape2D:
			return (
				child
				as CollisionShape2D
			)

	return null
