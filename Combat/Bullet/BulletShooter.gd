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
var shot_interval: float = 0.1

@export_range(
	0.0,
	10.0,
	0.01
)
var burst_interval: float = 1.0

@export var fire_on_ready: bool = false


var time_until_next_shot: float = 0.0
var is_counting_down: bool = false

var _is_firing: bool = false


func _ready() -> void:
	if fire_on_ready:
		call_deferred(
			"start_firing"
		)


func _process(
	delta: float
) -> void:
	if not is_counting_down:
		return

	time_until_next_shot = maxf(
		0.0,
		time_until_next_shot - delta
	)


func start_firing() -> void:
	if _is_firing:
		return

	_is_firing = true

	_fire_loop()


func stop_firing() -> void:
	_is_firing = false
	is_counting_down = false
	time_until_next_shot = 0.0


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
				await _wait_for_next_shot(
					shot_interval
				)

		if not _is_firing:
			return

		await _wait_for_next_shot(
			burst_interval
		)


func _wait_for_next_shot(
	duration: float
) -> void:
	time_until_next_shot = duration
	is_counting_down = true

	await get_tree().create_timer(
		duration
	).timeout

	time_until_next_shot = 0.0
	is_counting_down = false


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
		var player_node := (
			get_tree().get_first_node_in_group(
				"player"
			) as Node2D
		)

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

	spawn_parent.add_child(
		bullet
	)

	bullet.global_position = (
		global_position
	)
