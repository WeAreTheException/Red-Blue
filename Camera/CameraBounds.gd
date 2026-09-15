extends Area2D
class_name CameraBounds


const CAMERA_BOUNDS_GROUP: StringName = &"camera_bounds"


enum HorizontalMode {
	LOCKED,
	STEP,
	FOLLOW
}


enum VerticalMode {
	LOCKED,
	DEAD_ZONE,
	FOLLOW
}


@export_group("References")

@export var bounds_shape: CollisionShape2D


@export_group("Camera Movement")

@export var horizontal_mode: HorizontalMode = (
	HorizontalMode.STEP
)

@export var vertical_mode: VerticalMode = (
	VerticalMode.DEAD_ZONE
)


@export_group("Horizontal Step")

# How far the player can move from the current
# camera center before the next chunk begins.
@export var horizontal_trigger_distance_px: float = 100.0

# How far the camera moves per chunk.
@export var horizontal_step_distance_px: float = 160.0

# Normal cinematic duration of a camera chunk.
@export var horizontal_step_time: float = 1.5


@export_group("Horizontal Look Ahead")

# Look-ahead affects when the next chunk triggers
# in STEP mode.
#
# In FOLLOW mode, it offsets the follow target
# after the player leaves the follow dead zone.
@export var horizontal_look_ahead_px: float = 24.0

# Tiny horizontal velocities are ignored.
@export var look_ahead_velocity_threshold: float = 15.0

# How quickly look-ahead builds while moving.
@export var look_ahead_response_speed: float = 70.0

# How quickly look-ahead returns to zero
# when horizontal movement stops.
@export var look_ahead_release_speed: float = 45.0


@export_group("Horizontal Follow")

# How far the player can move left/right
# before FOLLOW begins moving the camera.
@export var horizontal_follow_dead_zone_px: float = 8.0

@export var horizontal_follow_speed: float = 8.0


@export_group("Catch Up")

# Once the player gets this far from the
# actual camera center, speed up the chunk.
@export var catch_up_distance_px: float = 115.0

@export var catch_up_multiplier: float = 2.25

# Emergency distance before the player gets
# dangerously close to leaving the screen.
@export var emergency_catch_up_distance_px: float = 140.0

@export var emergency_catch_up_multiplier: float = 5.0

# Damps the transition into and out of catch-up.
@export var catch_up_response_speed: float = 12.0

# Emergency catch-up reacts more quickly.
@export var emergency_catch_up_response_speed: float = 28.0


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
