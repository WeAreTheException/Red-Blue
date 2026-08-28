extends Area2D
class_name Bullet


enum Team {
	PLAYER,
	ENEMY
}


@export_group("Bullet")

@export_enum(
	"PLAYER",
	"ENEMY"
)
var team: int = (
	Team.ENEMY
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

@export var speed: float = 100.0

@export var damage: float = 10.0

@export_range(
	0.1,
	30.0,
	0.1
)
var lifetime: float = 8.0


@export_group("Visual")

@export var visual: Sprite2D

@export_range(
	0.0,
	1.0,
	0.01
)
var inactive_opacity: float = 0.25


@export_group("Debug")

@export var print_debug: bool = false


const RED_COLOR: Color = Color8(
	213,
	32,
	32,
	255
)

const BLUE_COLOR: Color = Color8(
	67,
	110,
	177,
	255
)

const NEUTRAL_COLOR: Color = Color8(
	25,
	25,
	25,
	255
)


var color_state: ColorState = null

var is_active: bool = true

var _life_elapsed: float = 0.0

var _has_hit_target: bool = false


func _ready() -> void:
	_configure_collision()

	monitoring = true
	monitorable = true

	body_entered.connect(
		_on_body_entered
	)

	area_entered.connect(
		_on_area_entered
	)

	_apply_visual()

	_connect_color_state()


func setup(
	new_direction: Vector2,
	new_speed: float,
	new_affiliation: int,
	new_team: int
) -> void:
	direction = new_direction

	speed = new_speed

	affiliation = new_affiliation

	team = new_team


func _configure_collision() -> void:
	match team:
		Team.PLAYER:
			# Layer 6 = PLAYER_ATTACK
			collision_layer = 32

			# Mask:
			# 2 = WORLD
			# 3 = COLOR_WORLD
			# 5 = ENEMY_HURTBOX
			collision_mask = 22

		Team.ENEMY:
			# Layer 7 = ENEMY_ATTACK
			collision_layer = 64

			# Mask:
			# 1 = PLAYER
			# 2 = WORLD
			# 3 = COLOR_WORLD
			collision_mask = 7


func _physics_process(
	delta: float
) -> void:
	if direction != Vector2.ZERO:
		global_position += (
			direction.normalized()
			* speed
			* delta
		)

	_life_elapsed += delta

	if _life_elapsed >= lifetime:
		queue_free()


func _connect_color_state() -> void:
	var color_system_root: ColorSystemRoot = (
		ColorSystemRoot.instance
	)

	if color_system_root == null:
		await get_tree().process_frame

		color_system_root = (
			ColorSystemRoot.instance
		)

	if color_system_root == null:
		push_error(
			"Bullet could not find ColorSystemRoot."
		)

		return

	color_state = (
		color_system_root.color_state
	)

	if color_state == null:
		push_error(
			"Bullet could not find ColorState."
		)

		return

	color_state.color_changed.connect(
		_on_color_changed
	)

	color_state.initial_color_set.connect(
		_on_initial_color_set
	)

	_sync_active_state(
		color_state.current_color
	)


func _on_initial_color_set(
	new_color: int
) -> void:
	_sync_active_state(
		new_color
	)


func _on_color_changed(
	_previous_color: int,
	new_color: int
) -> void:
	_sync_active_state(
		new_color
	)


func _sync_active_state(
	player_color: int
) -> void:
	if color_state == null:
		return

	# Enemy bullets are always active attacks.
	#
	# Player bullets use the player's current
	# RED / BLUE color behavior.
	if team == Team.ENEMY:
		is_active = true

	else:
		is_active = (
			color_state.is_affiliation_active(
				affiliation,
				player_color
			)
		)

	_apply_visual()


func _apply_visual() -> void:
	if visual == null:
		return

	var bullet_color: Color = (
		_get_affiliation_color()
	)

	if is_active:
		bullet_color.a = 1.0

	else:
		bullet_color.a = (
			inactive_opacity
		)

	visual.modulate = (
		bullet_color
	)


func _get_affiliation_color() -> Color:
	match affiliation:
		ColorState.Affiliation.RED:
			return RED_COLOR

		ColorState.Affiliation.BLUE:
			return BLUE_COLOR

		ColorState.Affiliation.NEUTRAL:
			return NEUTRAL_COLOR

		_:
			return NEUTRAL_COLOR


func _on_body_entered(
	body: Node2D
) -> void:
	if _has_hit_target:
		return

	# Colored environment / armor.
	if body is EnvironmentBody:
		var environment: EnvironmentBody = (
			body as EnvironmentBody
		)

		if _environment_blocks_bullet(
			environment
		):
			if print_debug:
				print(
					"BULLET BLOCKED | BULLET: ",
					ColorState.affiliation_name(
						affiliation
					),
					" | BLOCK: ",
					ColorState.affiliation_name(
						environment.affiliation
					)
				)

			queue_free()

		return

	# Enemy bullets can hurt PlayerRoot.
	if (
		team == Team.ENEMY
		and body is PlayerRoot
	):
		_hit_player(
			body as PlayerRoot
		)

		return

	# Anything else on WORLD stops bullets.
	queue_free()


func _on_area_entered(
	area: Area2D
) -> void:
	if _has_hit_target:
		return

	# Only PLAYER bullets interact with
	# ENEMY Hurtboxes.
	if team != Team.PLAYER:
		return

	if not area is Hurtbox:
		return

	var hurtbox: Hurtbox = (
		area as Hurtbox
	)

	_has_hit_target = true

	var info: DamageInfo = (
		DamageInfo.new()
	)

	info.setup(
		damage,
		self,
		affiliation
	)

	hurtbox.receive_damage(
		info
	)

	if print_debug:
		print(
			"PLAYER BULLET DAMAGE: ",
			damage
		)

	queue_free()


func _environment_blocks_bullet(
	environment: EnvironmentBody
) -> bool:
	if environment == null:
		return false

	# Neutral WORLD always blocks bullets.
	if (
		environment.affiliation
		== ColorState.Affiliation.NEUTRAL
	):
		return true

	# Neutral bullets ignore colored blocks.
	if (
		affiliation
		== ColorState.Affiliation.NEUTRAL
	):
		return false

	# Colored bullets only collide with
	# the SAME color.
	return (
		affiliation
		== environment.affiliation
	)


func _hit_player(
	player: PlayerRoot
) -> void:
	if player == null:
		return

	if _has_hit_target:
		return

	if team != Team.ENEMY:
		return

	var player_death: PlayerDeath = (
		_find_player_death(
			player
		)
	)

	if player_death == null:
		if print_debug:
			print(
				"BULLET: PLAYER DEATH MISSING"
			)

		return

	if player_death.is_dead:
		return

	_has_hit_target = true

	if print_debug:
		print(
			"ENEMY BULLET: HIT PLAYER"
		)

	player_death.die()

	queue_free()


func _find_player_death(
	node: Node
) -> PlayerDeath:
	if node is PlayerDeath:
		return (
			node as PlayerDeath
		)

	for child: Node in node.get_children():
		var found: PlayerDeath = (
			_find_player_death(
				child
			)
		)

		if found != null:
			return found

	return null
