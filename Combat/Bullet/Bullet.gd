extends Area2D
class_name Bullet


@export_group("Bullet")

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

@export var speed: float = 100.0

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
	173,
	170,
	170,
	255
)

const NEUTRAL_HOSTILE_COLOR: Color = Color8(
	25,
	25,
	25,
	255
)


var color_state: ColorState = null

var is_active: bool = true

var _life_elapsed: float = 0.0
var _has_hit_player: bool = false


func _ready() -> void:
	_configure_collision()

	monitoring = true
	monitorable = true

	body_entered.connect(
		_on_body_entered
	)

	_apply_visual()

	_connect_color_state()


func setup(
	new_direction: Vector2,
	new_speed: float,
	new_affiliation: int,
	new_hostile: bool
) -> void:
	direction = new_direction
	speed = new_speed
	affiliation = new_affiliation
	hostile = new_hostile


func _configure_collision() -> void:
	if hostile:
		# ENEMY BULLET
		#
		# Layer 7 = ENEMY_ATTACK
		#
		# Detect:
		# Layer 1 = PLAYER
		# Layer 2 = WORLD
		# Layer 3 = COLOR_WORLD

		collision_layer = 64
		collision_mask = 7

	else:
		# PLAYER BULLET
		#
		# Layer 6 = PLAYER_ATTACK
		#
		# Detect:
		# Layer 2 = WORLD
		# Layer 3 = COLOR_WORLD
		# Layer 5 = ENEMY_HURTBOX

		collision_layer = 32
		collision_mask = 22


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
	var color_system_root := (
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

	var wants_active: bool = (
		color_state.is_affiliation_active(
			affiliation,
			player_color
		)
	)

	var became_active: bool = (
		not is_active
		and wants_active
	)

	is_active = wants_active

	_apply_visual()

	if became_active:
		call_deferred(
			"_check_overlapping_player"
		)

	if print_debug:
		print(
			"BULLET ACTIVE: ",
			is_active,
			" | AFFILIATION: ",
			ColorState.affiliation_name(
				affiliation
			)
		)


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
			if hostile:
				return NEUTRAL_HOSTILE_COLOR

			return NEUTRAL_COLOR

		_:
			return NEUTRAL_COLOR


func _on_body_entered(
	body: Node2D
) -> void:
	if not is_active:
		return

	# Active EnvironmentBody blocks the bullet.
	#
	# Inactive colored EnvironmentBody collision
	# is already disabled by the color system,
	# so bullets pass through automatically.
	if body is EnvironmentBody:
		if print_debug:
			print(
				"BULLET: HIT ENVIRONMENT | ",
				body.name
			)

		queue_free()

		return

	# Player bullets don't hurt PlayerRoot.
	if not hostile:
		return

	if not body is PlayerRoot:
		return

	_hit_player(
		body as PlayerRoot
	)


func _check_overlapping_player() -> void:
	if not is_inside_tree():
		return

	if not is_active:
		return

	if not hostile:
		return

	if _has_hit_player:
		return

	for body in get_overlapping_bodies():
		if not body is PlayerRoot:
			continue

		_hit_player(
			body as PlayerRoot
		)

		return


func _hit_player(
	player: PlayerRoot
) -> void:
	if player == null:
		return

	if _has_hit_player:
		return

	if not hostile:
		return

	if not is_active:
		return

	var player_death := (
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

	_has_hit_player = true

	if print_debug:
		print(
			"BULLET: KILL PLAYER"
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

	for child in node.get_children():
		var found := (
			_find_player_death(
				child
			)
		)

		if found != null:
			return found

	return null
