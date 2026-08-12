extends Node
class_name ColorEjectionResolver


@export_group("Search")

@export var max_eject_distance: int = 96
@export var similar_route_distance: int = 4


@export_group("Bias")

@export var minimum_velocity_for_bias: float = 10.0
@export var velocity_bias_score: float = 3.0
@export var input_bias_score: float = 1.0


func get_overlapping_reactives(
	bridge: PlayerColorEjectionBridge,
	reactives: Array[Node]
) -> Array[Node]:
	var overlapping: Array[Node] = []

	if bridge == null:
		return overlapping

	for reactive in reactives:
		if reactive == null:
			continue

		if not is_instance_valid(
			reactive
		):
			continue

		if _player_overlaps_reactive(
			bridge,
			reactive,
			Vector2.ZERO
		):
			overlapping.append(
				reactive
			)

	return overlapping


func resolve_escape(
	bridge: PlayerColorEjectionBridge,
	pending_reactives: Array[Node]
) -> Dictionary:
	var result := {
		"success": false,
		"direction": Vector2.ZERO,
		"distance": 0,
		"offset": Vector2.ZERO,
		"route": &"NONE",
	}

	if bridge == null:
		return result

	if not _overlaps_any_pending(
		bridge,
		pending_reactives,
		Vector2.ZERO
	):
		return result

	var routes: Array[Dictionary] = []

	var directions: Array[Dictionary] = [
		{
			"direction": Vector2.LEFT,
			"name": &"LEFT",
		},
		{
			"direction": Vector2.RIGHT,
			"name": &"RIGHT",
		},
		{
			"direction": Vector2.UP,
			"name": &"UP",
		},
		{
			"direction": Vector2.DOWN,
			"name": &"DOWN",
		},
	]

	for route_data in directions:
		var route_direction: Vector2 = (
			route_data["direction"]
		)

		var route_name: StringName = (
			route_data["name"]
		)

		var route: Dictionary = _find_route(
			bridge,
			pending_reactives,
			route_direction,
			route_name
		)

		if bool(
			route["success"]
		):
			routes.append(
				route
			)

	if routes.is_empty():
		return result

	var shortest_distance: int = 1000000

	for route in routes:
		var route_distance: int = int(
			route["distance"]
		)

		shortest_distance = mini(
			shortest_distance,
			route_distance
		)

	var velocity: Vector2 = (
		bridge.get_velocity_for_ejection_bias()
	)

	var directional_input: Vector2 = (
		bridge.get_directional_input_for_ejection_bias()
	)

	var best_route: Dictionary = {}
	var best_score: float = INF

	for route in routes:
		var distance: int = int(
			route["distance"]
		)

		if (
			distance
			> shortest_distance
			+ similar_route_distance
		):
			continue

		var direction: Vector2 = (
			route["direction"]
		)

		var score: float = float(
			distance
		)

		if (
			velocity.length()
			>= minimum_velocity_for_bias
		):
			var velocity_alignment: float = maxf(
				0.0,
				velocity.normalized().dot(
					direction
				)
			)

			score -= (
				velocity_alignment
				* velocity_bias_score
			)

		if directional_input != Vector2.ZERO:
			var input_alignment: float = maxf(
				0.0,
				directional_input.normalized().dot(
					direction
				)
			)

			score -= (
				input_alignment
				* input_bias_score
			)

		if score < best_score:
			best_score = score
			best_route = route

	if best_route.is_empty():
		return result

	return best_route


func _find_route(
	bridge: PlayerColorEjectionBridge,
	pending_reactives: Array[Node],
	direction: Vector2,
	route_name: StringName
) -> Dictionary:
	var result := {
		"success": false,
		"direction": direction,
		"distance": 0,
		"offset": Vector2.ZERO,
		"route": route_name,
	}

	for distance in range(
		1,
		max_eject_distance + 1
	):
		var offset: Vector2 = (
			direction
			* distance
		)

		if _overlaps_any_pending(
			bridge,
			pending_reactives,
			offset
		):
			continue

		if bridge.route_blocked_by_active_world(
			offset
		):
			continue

		result["success"] = true
		result["distance"] = distance
		result["offset"] = offset

		return result

	return result


func _overlaps_any_pending(
	bridge: PlayerColorEjectionBridge,
	reactives: Array[Node],
	offset: Vector2
) -> bool:
	for reactive in reactives:
		if reactive == null:
			continue

		if not is_instance_valid(
			reactive
		):
			continue

		if _player_overlaps_reactive(
			bridge,
			reactive,
			offset
		):
			return true

	return false


func _player_overlaps_reactive(
	bridge: PlayerColorEjectionBridge,
	reactive: Node,
	offset: Vector2
) -> bool:
	var player_shape: CollisionShape2D = (
		bridge.get_player_collision_shape()
	)

	if player_shape == null:
		return false

	if player_shape.shape == null:
		return false

	var player_transform: Transform2D = (
		player_shape.global_transform
	)

	player_transform.origin += offset

	# New EnvironmentBody objects.
	if reactive.has_method(
		"get_collision_polygons"
	):
		var polygon_result: Variant = (
			reactive.call(
				"get_collision_polygons"
			)
		)

		if polygon_result is Array:
			for value in polygon_result:
				var collision_polygon: CollisionPolygon2D = (
					value as CollisionPolygon2D
				)

				if collision_polygon == null:
					continue

				if _player_overlaps_polygon(
					player_shape,
					player_transform,
					collision_polygon
				):
					return true

	# Old ColorReactive objects still work too.
	if reactive.has_method(
		"get_collision_shapes"
	):
		var shape_result: Variant = (
			reactive.call(
				"get_collision_shapes"
			)
		)

		if shape_result is Array:
			for value in shape_result:
				var collision_shape: CollisionShape2D = (
					value as CollisionShape2D
				)

				if collision_shape == null:
					continue

				if collision_shape.shape == null:
					continue

				if collision_shape.shape.collide(
					collision_shape.global_transform,
					player_shape.shape,
					player_transform
				):
					return true

	return false


func _player_overlaps_polygon(
	player_shape: CollisionShape2D,
	player_transform: Transform2D,
	collision_polygon: CollisionPolygon2D
) -> bool:
	if collision_polygon == null:
		return false

	if collision_polygon.polygon.size() < 3:
		return false

	var convex_parts: Array = (
		Geometry2D.decompose_polygon_in_convex(
			collision_polygon.polygon
		)
	)

	for convex_part in convex_parts:
		var convex_points: PackedVector2Array = (
			convex_part
		)

		if convex_points.size() < 3:
			continue

		var polygon_shape: ConvexPolygonShape2D = (
			ConvexPolygonShape2D.new()
		)

		polygon_shape.points = (
			convex_points
		)

		if polygon_shape.collide(
			collision_polygon.global_transform,
			player_shape.shape,
			player_transform
		):
			return true

	return false
