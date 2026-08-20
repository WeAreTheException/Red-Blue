extends Node2D
class_name BulletShooter


@export_group("Bullet")

@export var bullet_scene: PackedScene

@export_enum(
	"RED",
	"BLUE",
	"NEUTRAL"
)
var affiliation: int = (
	ColorState.Affiliation.NEUTRAL
)

@export var hostile: bool = true

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
var shots_per_burst: int = 3

@export_range(
	0.01,
	5.0,
	0.01
)
var shot_interval: float = 0.12

@export_range(
	0.01,
	10.0,
	0.01
)
var burst_interval: float = 1.0

@export var fire_on_ready: bool = true


@export_group("Debug")

@export var print_debug: bool = false


var is_firing: bool = false

var _fire_generation: int = 0


func _ready() -> void:
	if fire_on_ready:
		start_firing()


func start_firing() -> void:
	if is_firing:
		return

	if bullet_scene == null:
		push_error(
			"BulletShooter has no Bullet Scene."
		)

		return

	is_firing = true

	_fire_generation += 1

	_fire_loop(
		_fire_generation
	)


func stop_firing() -> void:
	if not is_firing:
		return

	is_firing = false

	_fire_generation += 1


func _fire_loop(
	generation: int
) -> void:
	while (
		is_firing
		and generation
		== _fire_generation
	):
		var shot_count: int = (
			maxi(
				shots_per_burst,
				1
			)
		)

		for shot_index in range(
			shot_count
		):
			if not is_firing:
				return

			if (
				generation
				!= _fire_generation
			):
				return

			_spawn_bullet()

			if (
				shot_index
				< shot_count - 1
			):
				await get_tree().create_timer(
					shot_interval
				).timeout

		if not is_firing:
			return

		if (
			generation
			!= _fire_generation
		):
			return

		await get_tree().create_timer(
			burst_interval
		).timeout


func _spawn_bullet() -> void:
	if bullet_scene == null:
		return

	var shot_direction: Vector2 = (
		direction
	)

	if follow_player:
		var player_locator := get_node_or_null(
			"/root/PlayerLocator"
		)

		if player_locator == null:
			if print_debug:
				print(
					"BULLET SHOOTER: PLAYER LOCATOR MISSING"
				)

			return

		var target_player: PlayerRoot = (
			player_locator.get_player()
		)

		if target_player == null:
			if print_debug:
				print(
					"BULLET SHOOTER: PLAYER NOT FOUND"
				)

			return

		shot_direction = (
			global_position.direction_to(
				target_player.global_position
			)
		)

		if shot_direction == Vector2.ZERO:
			return

	var bullet_node := (
		bullet_scene.instantiate()
	)

	if not bullet_node is Bullet:
		push_error(
			"BulletShooter Bullet Scene root must use Bullet.gd."
		)

		bullet_node.free()

		return

	var bullet := (
		bullet_node as Bullet
	)

	bullet.setup(
		shot_direction,
		bullet_speed,
		affiliation,
		hostile
	)

	var spawn_parent := (
		get_tree().current_scene
	)

	if spawn_parent == null:
		bullet.free()

		return

	spawn_parent.add_child(
		bullet
	)

	bullet.global_position = (
		global_position
	)

	if print_debug:
		print(
			"BULLET FIRED | ",
			ColorState.affiliation_name(
				affiliation
			),
			" | HOSTILE: ",
			hostile,
			" | DIRECTION: ",
			shot_direction
		)
