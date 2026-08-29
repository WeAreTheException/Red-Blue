extends Node2D
class_name PlayerShooter


const ACTION_ATTACK: StringName = &"ATTACK"


@export_group("References")

@export var bullet_shooter: BulletShooter


@export_group("Fire")

@export_range(
	0.1,
	30.0,
	0.1
)
var shots_per_second: float = 6.0


@export_group("Aim")

@export_range(
	0,
	7,
	1
)
var joy_device: int = 0

@export_range(
	0.0,
	1.0,
	0.01
)
var left_stick_deadzone: float = 0.25


@export_group("Debug")

@warning_ignore("shadowed_global_identifier")
@export var print_debug: bool = false


var player: PlayerRoot = null

var aim_direction: Vector2 = (
	Vector2.RIGHT
)

var _fire_cooldown: float = 0.0


func _ready() -> void:
	player = (
		_find_player()
	)

	if player == null:
		push_error(
			"PlayerShooter could not find PlayerRoot."
		)

		return

	if bullet_shooter == null:
		push_error(
			"PlayerShooter has no BulletShooter assigned."
		)

		return

	bullet_shooter.stop_firing()

	bullet_shooter.fire_on_ready = false
	bullet_shooter.follow_player = false

	bullet_shooter.team = (
		Bullet.Team.PLAYER
	)

	_update_aim()


func _physics_process(
	delta: float
) -> void:
	if player == null:
		return

	if bullet_shooter == null:
		return

	_update_aim()

	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

	if not Input.is_action_pressed(
		ACTION_ATTACK
	):
		return

	if _fire_cooldown > 0.0:
		return

	_fire()

	_fire_cooldown = (
		1.0
		/ maxf(
			shots_per_second,
			0.1
		)
	)


func _fire() -> void:
	_sync_bullet_affiliation()

	bullet_shooter.direction = (
		aim_direction
	)

	bullet_shooter.fire_once()

	if print_debug:
		print(
			"PLAYER FIRE | AIM: ",
			aim_direction
		)


func _update_aim() -> void:
	var stick_aim: Vector2 = Vector2(
		Input.get_joy_axis(
			joy_device,
			JOY_AXIS_LEFT_X
		),
		Input.get_joy_axis(
			joy_device,
			JOY_AXIS_LEFT_Y
		)
	)

	if (
		stick_aim.length()
		>= left_stick_deadzone
	):
		aim_direction = (
			stick_aim.normalized()
		)

		return

	var mouse_direction: Vector2 = (
		get_global_mouse_position()
		- global_position
	)

	if mouse_direction != Vector2.ZERO:
		aim_direction = (
			mouse_direction.normalized()
		)

		return

	if (
		player != null
		and player.movement != null
		and player.movement.movement_state != null
	):
		aim_direction = Vector2(
			float(
				player.movement.movement_state.Facing
			),
			0.0
		)


func _sync_bullet_affiliation() -> void:
	var color_system: ColorSystemRoot = (
		ColorSystemRoot.instance
	)

	if color_system == null:
		return

	if color_system.color_state == null:
		return

	var player_color: int = (
		color_system.color_state.current_color
	)

	match player_color:
		ColorState.PlayerColor.RED:
			bullet_shooter.affiliation = (
				ColorState.Affiliation.RED
			)

		ColorState.PlayerColor.BLUE:
			bullet_shooter.affiliation = (
				ColorState.Affiliation.BLUE
			)


func _find_player() -> PlayerRoot:
	var current: Node = (
		get_parent()
	)

	while current != null:
		if current is PlayerRoot:
			return (
				current as PlayerRoot
			)

		current = (
			current.get_parent()
		)

	return null
