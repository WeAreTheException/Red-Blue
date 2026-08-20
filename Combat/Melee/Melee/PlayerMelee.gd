extends Node2D
class_name PlayerMelee


@export_group("Visual")

@export var melee_visual: AnimatedSprite2D
@export var melee_animation: StringName = &"melee"


@export_group("Controller Aim")

@export var right_stick_deadzone: float = 0.25


@export_group("Debug")

@export var print_debug: bool = false


const RIGHT_STICK_LEFT: StringName = &"AIM_LEFT"
const RIGHT_STICK_RIGHT: StringName = &"AIM_RIGHT"
const RIGHT_STICK_UP: StringName = &"AIM_UP"
const RIGHT_STICK_DOWN: StringName = &"AIM_DOWN"


var player: PlayerRoot = null

var current_aim_direction: Vector2 = (
	Vector2.RIGHT
)

var _visual_start_position: Vector2 = (
	Vector2.ZERO
)


func _ready() -> void:
	player = (
		get_parent()
		as PlayerRoot
	)

	if player == null:
		push_error(
			"PlayerMelee must be a direct child of PlayerRoot."
		)

		return

	if melee_visual == null:
		push_error(
			"PlayerMelee has no Melee Visual assigned."
		)

		return

	_visual_start_position = (
		melee_visual.position
	)


func _input(
	event: InputEvent
) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event := (
		event as InputEventMouseButton
	)

	if (
		mouse_event.button_index
		!= MOUSE_BUTTON_LEFT
	):
		return

	if not mouse_event.pressed:
		return

	attack()


func attack() -> void:
	if player == null:
		return

	if melee_visual == null:
		return

	current_aim_direction = (
		_get_aim_direction()
	)

	_apply_melee_direction(
		current_aim_direction
	)

	melee_visual.play(
		melee_animation
	)

	if print_debug:
		print(
			"MELEE | AIM: ",
			current_aim_direction,
			" | SIDE: ",
			_get_horizontal_side(
				current_aim_direction
			)
		)


func _get_aim_direction() -> Vector2:
	var stick_direction := (
		_get_right_stick_direction()
	)

	if (
		stick_direction
		!= Vector2.ZERO
	):
		return stick_direction

	return _get_facing_direction()


func _get_right_stick_direction() -> Vector2:
	var stick_direction := Input.get_vector(
		RIGHT_STICK_LEFT,
		RIGHT_STICK_RIGHT,
		RIGHT_STICK_UP,
		RIGHT_STICK_DOWN
	)

	if (
		stick_direction.length()
		< right_stick_deadzone
	):
		return Vector2.ZERO

	return stick_direction.normalized()


func _get_facing_direction() -> Vector2:
	if player == null:
		return Vector2.RIGHT

	if player.movement == null:
		return Vector2.RIGHT

	if player.movement.movement_state == null:
		return Vector2.RIGHT

	return (
		Vector2.RIGHT
		* player.movement.movement_state.Facing
	)


func _apply_melee_direction(
	aim_direction: Vector2
) -> void:
	if melee_visual == null:
		return

	var side: int = (
		_get_horizontal_side(
			aim_direction
		)
	)

	melee_visual.flip_h = (
		side < 0
	)

	melee_visual.position = (
		_visual_start_position
	)

	melee_visual.position.x = (
		absf(
			_visual_start_position.x
		)
		* float(side)
	)


func _get_horizontal_side(
	aim_direction: Vector2
) -> int:
	if aim_direction.x < 0.0:
		return -1

	if aim_direction.x > 0.0:
		return 1

	if player == null:
		return 1

	if player.movement == null:
		return 1

	if player.movement.movement_state == null:
		return 1

	return (
		player.movement.movement_state.Facing
	)
