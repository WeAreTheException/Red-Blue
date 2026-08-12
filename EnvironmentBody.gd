extends StaticBody2D
class_name EnvironmentBody


signal active_changed(
	is_active: bool
)

signal activation_overlap(
	player: PlayerRoot
)


@export_group("Environment")

@export_enum(
	"RED",
	"BLUE",
	"NEUTRAL"
)
var affiliation: int = (
	ColorState.Affiliation.NEUTRAL
)

@export var hostile: bool = false

@export_range(
	0.1,
	8.0,
	0.1
)
var hostile_contact_margin: float = 1.0


@export_group("Visual")

@export_range(
	0.0,
	1.0,
	0.01
)
var inactive_opacity: float = 0.25


@export_group("Debug")

@export var print_debug: bool = true


const RED_COLOR: Color = Color8(
	173,
	50,
	12,
	255
)

const BLUE_COLOR: Color = Color8(
	43,
	60,
	154,
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


var color_system_root: ColorSystemRoot = null

var polygons: Array[Polygon2D] = []
var collision_polygons: Array[CollisionPolygon2D] = []

var is_active: bool = true

var _hazard_area: Area2D = null
var _hazard_collision_polygons: Array[CollisionPolygon2D] = []


func _ready() -> void:
	_find_children()

	_apply_visual(
		true
	)

	if hostile:
		_create_hazard_area()

	call_deferred(
		"_register_with_color_system"
	)


func _exit_tree() -> void:
	if color_system_root != null:
		color_system_root.unregister_reactive(
			self
		)


func _find_children() -> void:
	polygons.clear()
	collision_polygons.clear()

	for child in get_children():
		if child is Polygon2D:
			polygons.append(
				child as Polygon2D
			)

		elif child is CollisionPolygon2D:
			collision_polygons.append(
				child as CollisionPolygon2D
			)

	if polygons.is_empty():
		push_warning(
			"EnvironmentBody has no direct child Polygon2D."
		)

	if collision_polygons.is_empty():
		push_warning(
			"EnvironmentBody has no direct child CollisionPolygon2D."
		)


func _register_with_color_system() -> void:
	color_system_root = (
		ColorSystemRoot.instance
	)

	if color_system_root == null:
		await get_tree().process_frame

		color_system_root = (
			ColorSystemRoot.instance
		)

	if color_system_root == null:
		push_error(
			"EnvironmentBody could not find ColorSystemRoot."
		)

		return

	color_system_root.register_reactive(
		self
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
	_apply_visual(
		true
	)


func complete_activation() -> void:
	var changed: bool = (
		not is_active
	)

	is_active = true

	_apply_visual(
		true
	)

	_set_collision_active(
		true
	)

	_set_hazard_active(
		true
	)

	if changed:
		active_changed.emit(
			true
		)


func deactivate() -> void:
	var changed: bool = (
		is_active
	)

	is_active = false

	_apply_visual(
		false
	)

	_set_collision_active(
		false
	)

	_set_hazard_active(
		false
	)

	if changed:
		active_changed.emit(
			false
		)


func set_active_immediate(
	active: bool
) -> void:
	var changed: bool = (
		is_active != active
	)

	is_active = active

	_apply_visual(
		active
	)

	_set_collision_active(
		active
	)

	_set_hazard_active(
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

	if hostile:
		_hit_player(
			player
		)


func get_collision_polygons() -> Array[CollisionPolygon2D]:
	return collision_polygons


func _apply_visual(
	active: bool
) -> void:
	var environment_color: Color = (
		_get_affiliation_color()
	)

	for polygon in polygons:
		if polygon == null:
			continue

		polygon.color = (
			environment_color
		)

		if active:
			polygon.modulate.a = 1.0

		else:
			polygon.modulate.a = (
				inactive_opacity
			)


func _set_collision_active(
	active: bool
) -> void:
	for collision_polygon in collision_polygons:
		if collision_polygon == null:
			continue

		collision_polygon.set_deferred(
			"disabled",
			not active
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


func _create_hazard_area() -> void:
	if _hazard_area != null:
		return

	_hazard_area = Area2D.new()

	_hazard_area.name = (
		"EnvironmentHazard"
	)

	_hazard_area.collision_layer = 0

	# Player is on collision layer 1.
	_hazard_area.collision_mask = 1

	_hazard_area.monitoring = true
	_hazard_area.monitorable = true

	add_child(
		_hazard_area
	)

	_hazard_collision_polygons.clear()

	for source_polygon in collision_polygons:
		if source_polygon == null:
			continue

		if source_polygon.polygon.size() < 3:
			continue

		_create_expanded_hazard_polygons(
			source_polygon
		)

	_hazard_area.body_entered.connect(
		_on_hazard_body_entered
	)

	if print_debug:
		print(
			"HOSTILE ENVIRONMENT READY | COLLIDERS: ",
			_hazard_collision_polygons.size()
		)


func _create_expanded_hazard_polygons(
	source_polygon: CollisionPolygon2D
) -> void:
	var expanded_parts: Array[PackedVector2Array] = (
		Geometry2D.offset_polygon(
			source_polygon.polygon,
			hostile_contact_margin
		)
	)

	if expanded_parts.is_empty():
		_create_hazard_polygon(
			source_polygon.polygon,
			source_polygon.transform
		)

		return

	for expanded_polygon in expanded_parts:
		if expanded_polygon.size() < 3:
			continue

		_create_hazard_polygon(
			expanded_polygon,
			source_polygon.transform
		)


func _create_hazard_polygon(
	points: PackedVector2Array,
	source_transform: Transform2D
) -> void:
	var hazard_polygon := (
		CollisionPolygon2D.new()
	)

	hazard_polygon.polygon = points

	hazard_polygon.transform = (
		source_transform
	)

	_hazard_area.add_child(
		hazard_polygon
	)

	_hazard_collision_polygons.append(
		hazard_polygon
	)


func _set_hazard_active(
	active: bool
) -> void:
	if _hazard_area == null:
		return

	_hazard_area.set_deferred(
		"monitoring",
		active and hostile
	)


func _on_hazard_body_entered(
	body: Node2D
) -> void:
	if print_debug:
		print(
			"HOSTILE BODY ENTERED: ",
			body.name
		)

	if not hostile:
		return

	if not is_active:
		return

	if not body is PlayerRoot:
		return

	_hit_player(
		body as PlayerRoot
	)


func _hit_player(
	player: PlayerRoot
) -> void:
	if player == null:
		return

	var player_death: PlayerDeath = null

	for child in player.get_children():
		if child is PlayerDeath:
			player_death = (
				child as PlayerDeath
			)

			break

	if player_death == null:
		print(
			"HOSTILE ENVIRONMENT: PLAYER DEATH MISSING"
		)

		return

	if player_death.is_dead:
		return

	if print_debug:
		print(
			"HOSTILE ENVIRONMENT: KILL PLAYER"
		)

	player_death.die()
