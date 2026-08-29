extends Node2D
class_name BulletShooter


@export_group("Bullet")

@export var bullet_scene: PackedScene

@export_enum(
	"PLAYER",
	"ENEMY"
)
var team: int = (
	Bullet.Team.ENEMY
)

@export_enum(
	"RED",
	"BLUE",
	"NEUTRAL"
)
var affiliation: int = (
	ColorState.Affiliation.NEUTRAL
)

@export var direction: Vector2 = (
	Vector2.LEFT
)

@export var bullet_speed: float = 100.0


@export_group("Targeting")

@export var follow_player: bool = false


@export_group("Cadence")

@export_range(
	1,
	20,
	1
)
var shots_per_burst: int = 1

@export_range(
	0.0,
	5.0,
	0.01
)
var time_between_shots: float = 0.1

@export_range(
	0.0,
	10.0,
	0.01
)
var time_between_bursts: float = 1.0

@export var fire_on_ready: bool = false


var _is_firing: bool = false


func _ready() -> void:
	if fire_on_ready:
		call_deferred(
			"start_firing"
		)


func start_firing() -> void:
	if _is_firing:
		return

	_is_firing = true

	_fire_loop()


func stop_firing() -> void:
	_is_firing = false


func fire_once() -> void:
	_spawn_bullet()


func _fire_loop() -> void:
	while _is_firing:
		for shot_index: int in range(
			shots_per_burst
		):
			if not _is_firing:
				return

			_spawn_bullet()

			if (
				shot_index
				< shots_per_burst - 1
			):
				await get_tree().create_timer(
					time_between_shots
				).timeout

		if not _is_firing:
			return

		await get_tree().create_timer(
			time_between_bursts
		).timeout


func _spawn_bullet() -> void:
	if bullet_scene == null:
		return

	var bullet := (
		bullet_scene.instantiate()
		as Bullet
	)

	if bullet == null:
		return

	var spawn_direction: Vector2 = (
		direction
	)

	if follow_player:
		var player_node := get_tree().get_first_node_in_group(
			"player"
		) as Node2D

		if player_node != null:
			spawn_direction = (
				player_node.global_position
				- global_position
			).normalized()

	if spawn_direction == Vector2.ZERO:
		spawn_direction = Vector2.LEFT

	bullet.setup(
		spawn_direction,
		bullet_speed,
		affiliation,
		team
	)

	var spawn_parent: Node = (
		get_tree().current_scene
	)

	if spawn_parent == null:
		spawn_parent = get_tree().root

	var spawn_position: Vector2 = (
		global_position
	)

	_add_bullet_deferred(
		bullet,
		spawn_parent,
		spawn_position
	)


func _add_bullet_deferred(
	bullet: Bullet,
	spawn_parent: Node,
	spawn_position: Vector2
) -> void:
	await get_tree().process_frame

	if not is_instance_valid(
		bullet
	):
		return

	if not is_instance_valid(
		spawn_parent
	):
		bullet.free()
		return

	spawn_parent.add_child(
		bullet
	)

	bullet.global_position = (
		spawn_position
	)
