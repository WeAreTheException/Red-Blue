extends Node
class_name ColorEjectionResolver


@export_group("Search")

@export var max_eject_distance: int = 96


@export_group("Side Correction")

# If the player can escape sideways in LESS than
# this many pixels, it is only a side correction.
#
# 2 means:
# 1 px inside -> side correction
# 2+ px inside -> eject UP
@export var minimum_horizontal_overlap: int = 2


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
	var failed_result := {
		"success": false,
		"route": &"NONE",
		"direction": Vector2.ZERO,
		"distance": 0,
		"offset": Vector2.ZERO,
	}

	if bridge == null:
		return failed_result

	if not _overlaps_any_pending(
		bridge,
		pending_reactives,
		Vector2.ZERO
	):
		return failed_result

	var side_result := _find_side_correction(
		bridge,
		pending_reactives
	)

	if bool(
		side_result.get(
			"success",
			false
		)
	):
		return side_result

	return _find_up_route(
		bridge,
		pending_reactives
	)


func _find_side_correction(
	bridge: PlayerColorEjectionBridge,
	pending_reactives: Array[Node]
) -> Dictionary:
	var failed_result := {
		"success": false,
		"route": &"NONE",
		"direction": Vector2.ZERO,
		"distance": 0,
		"offset": Vector2.ZERO,
	}

	if minimum_horizontal_overlap <= 1:
		return failed_result

	for reactive in pending_reactives:
		if reactive == null:
			continue

		if not is_instance_valid(
			reactive
		):
			continue

		if not _player_overlaps_reactive(
			bridge,
			reactive,
			Vector2.ZERO
		):
			continue

		var direction := _get_side_direction(
			bridge,
			reactive
		)

		if direction == Vector2.ZERO:
			continue

		# We only search BELOW the UP-ejection threshold.
		#
		# With threshold 2:
		# only a 1 px correction is allowed.
		for distance in range(
			1,
			minimum_horizontal_overlap
		):
			var offset := (
				direction
				* float(distance)
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

			return {
				"success": true,
				"route": &"SIDE_CORRECTION",
				"direction": direction,
				"distance": distance,
				"offset": offset,
			}

	return failed_result


func _find_up_route(
	bridge: PlayerColorEjectionBridge,
	pending_reactives: Array[Node]
) -> Dictionary:
	var failed_result := {
		"success": false,
		"route": &"NONE",
		"direction": Vector2.ZERO,
		"distance": 0,
		"offset": Vector2.ZERO,
	}

	for distance in range(
		1,
		max_eject_distance + 1
	):
		var offset := (
			Vector2.UP
			* float(distance)
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

		return {
			"success": true,
			"route": &"UP",
			"direction": Vector2.UP,
			"distance": distance,
			"offset": offset,
		}

	return failed_result


func _get_side_direction(
	bridge: PlayerColorEjectionBridge,
	reactive: Node
) -> Vector2:
	var player_shape := (
		bridge.get_player_collision_shape()
	)

	if player_shape == null:
		return Vector2.ZERO

	if player_shape.shape == null:
		return Vector2.ZERO

	var player_transform := (
		player_shape.global_transform
	)

	var player_x := (
		player_transform.origin.x
	)

	# Current EnvironmentBody.
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
				var collision_polygon := (
					value as CollisionPolygon2D
				)

				if collision_polygon == null:
					continue

				if not _player_overlaps_polygon(
					player_shape,
					player_transform,
					collision_polygon
				):
					continue

				var bounds := (
					_get_polygon_world_bounds(
						collision_polygon
					)
				)

				var center_x := (
					bounds.position.x
					+ bounds.size.x * 0.5
				)

				if player_x < center_x:
					return Vector2.LEFT

				return Vector2.RIGHT

	# Compatibility with older ColorReactive scenes.
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
				var collision_shape := (
					value as CollisionShape2D
				)

				if collision_shape == null:
					continue

				if collision_shape.shape == null:
					continue

				if not collision_shape.shape.collide(
					collision_shape.global_transform,
					player_shape.shape,
					player_transform
				):
					continue

				var bounds := (
					_get_shape_world_bounds(
						collision_shape.shape,
						collision_shape.global_transform
					)
				)

				var center_x := (
					bounds.position.x
					+ bounds.size.x * 0.5
				)

				if player_x < center_x:
					return Vector2.LEFT

				return Vector2.RIGHT

	return Vector2.ZERO


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
	var player_shape := (
		bridge.get_player_collision_shape()
	)

	if player_shape == null:
		return false

	if player_shape.shape == null:
		return false

	var player_transform := (
		player_shape.global_transform
	)

	player_transform.origin += offset

	# Current EnvironmentBody.
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
				var collision_polygon := (
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

	# Older ColorReactive compatibility.
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
				var collision_shape := (
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

		var polygon_shape := (
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


func _get_polygon_world_bounds(
	collision_polygon: CollisionPolygon2D
) -> Rect2:
	var points := (
		collision_polygon.polygon
	)

	var first_point := (
		collision_polygon.global_transform
		* points[0]
	)

	var min_x := first_point.x
	var max_x := first_point.x
	var min_y := first_point.y
	var max_y := first_point.y

	for i in range(
		1,
		points.size()
	):
		var point := (
			collision_polygon.global_transform
			* points[i]
		)

		min_x = minf(
			min_x,
			point.x
		)

		max_x = maxf(
			max_x,
			point.x
		)

		min_y = minf(
			min_y,
			point.y
		)

		max_y = maxf(
			max_y,
			point.y
		)

	return Rect2(
		Vector2(
			min_x,
			min_y
		),
		Vector2(
			max_x - min_x,
			max_y - min_y
		)
	)


func _get_shape_world_bounds(
	shape: Shape2D,
	transform: Transform2D
) -> Rect2:
	var local_rect := (
		shape.get_rect()
	)

	var corners: Array[Vector2] = [
		local_rect.position,
		Vector2(
			local_rect.end.x,
			local_rect.position.y
		),
		local_rect.end,
		Vector2(
			local_rect.position.x,
			local_rect.end.y
		),
	]

	var first_point := (
		transform
		* corners[0]
	)

	var min_x := first_point.x
	var max_x := first_point.x
	var min_y := first_point.y
	var max_y := first_point.y

	for i in range(
		1,
		corners.size()
	):
		var point := (
			transform
			* corners[i]
		)

		min_x = minf(
			min_x,
			point.x
		)

		max_x = maxf(
			max_x,
			point.x
		)

		min_y = minf(
			min_y,
			point.y
		)

		max_y = maxf(
			max_y,
			point.y
		)

	return Rect2(
		Vector2(
			min_x,
			min_y
		),
		Vector2(
			max_x - min_x,
			max_y - min_y
		)
	)
