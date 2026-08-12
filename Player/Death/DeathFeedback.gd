extends Node
class_name DeathFeedback


var player: PlayerRoot
var player_visual: ColorRect

var normal_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	var death_node := get_parent()

	if death_node == null:
		return

	player = (
		death_node.get_parent()
		as PlayerRoot
	)

	if player == null:
		return

	player_visual = player.player_visual

	if player_visual == null:
		return

	normal_scale = player_visual.scale

	_update_pivot()


func play_death() -> void:
	if player_visual == null:
		return

	_update_pivot()

	var squash_scale := Vector2(
		normal_scale.x * 1.25,
		normal_scale.y * 0.18
	)

	var tween := create_tween()

	tween.tween_property(
		player_visual,
		"scale",
		squash_scale,
		0.08
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		player_visual,
		"scale",
		Vector2.ZERO,
		0.06
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await tween.finished

	player_visual.visible = false


func play_respawn() -> void:
	if player_visual == null:
		return

	_update_pivot()

	player_visual.visible = true

	player_visual.scale = Vector2(
		0.0,
		normal_scale.y * 0.15
	)

	var pop_scale := Vector2(
		normal_scale.x * 1.20,
		normal_scale.y * 0.82
	)

	var rebound_scale := Vector2(
		normal_scale.x * 0.94,
		normal_scale.y * 1.08
	)

	var tween := create_tween()

	tween.tween_property(
		player_visual,
		"scale",
		pop_scale,
		0.08
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		player_visual,
		"scale",
		rebound_scale,
		0.06
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		player_visual,
		"scale",
		normal_scale,
		0.06
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await tween.finished


func _update_pivot() -> void:
	if player_visual == null:
		return

	player_visual.pivot_offset = Vector2(
		player_visual.size.x * 0.5,
		player_visual.size.y
	)
