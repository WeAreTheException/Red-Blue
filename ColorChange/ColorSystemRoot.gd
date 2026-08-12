extends Node
class_name ColorSystemRoot


signal color_transaction_started(
	previous_color: int,
	new_color: int
)

signal color_transaction_finished(
	new_color: int
)

signal color_transaction_failed(
	requested_color: int
)


static var instance: ColorSystemRoot


@export_group("Systems")

@export var color_state: ColorState
@export var ejection_resolver: ColorEjectionResolver
@export var player_ejection_bridge: PlayerColorEjectionBridge


var _reactives: Array[Node] = []

var _transaction_active: bool = false


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	if color_state == null:
		return

	color_state.color_change_requested.connect(
		_on_color_change_requested
	)

	color_state.initial_color_set.connect(
		_on_initial_color_set
	)


func _exit_tree() -> void:
	if instance == self:
		instance = null


func register_reactive(
	reactive: Node
) -> void:
	if reactive == null:
		return

	if _reactives.has(
		reactive
	):
		return

	if not reactive.has_method(
		"should_be_active"
	):
		return

	if not reactive.has_method(
		"set_active_immediate"
	):
		return

	_reactives.append(
		reactive
	)

	if color_state == null:
		return

	var wants_active: bool = bool(
		reactive.call(
			"should_be_active",
			color_state.current_color
		)
	)

	reactive.call(
		"set_active_immediate",
		wants_active
	)


func unregister_reactive(
	reactive: Node
) -> void:
	_reactives.erase(
		reactive
	)


func _on_initial_color_set(
	new_color: int
) -> void:
	_sync_all_reactives(
		new_color
	)


func _on_color_change_requested(
	previous_color: int,
	new_color: int
) -> void:
	if _transaction_active:
		if color_state != null:
			color_state.cancel_requested_change()

		return

	_run_color_transaction(
		previous_color,
		new_color
	)


func _run_color_transaction(
	previous_color: int,
	new_color: int
) -> void:
	_transaction_active = true

	color_transaction_started.emit(
		previous_color,
		new_color
	)

	var becoming_inactive: Array[Node] = []
	var becoming_active: Array[Node] = []

	for reactive in _reactives:
		if reactive == null:
			continue

		if not is_instance_valid(
			reactive
		):
			continue

		var wants_active: bool = bool(
			reactive.call(
				"should_be_active",
				new_color
			)
		)

		var currently_active: bool = bool(
			reactive.get(
				"is_active"
			)
		)

		if (
			currently_active
			and not wants_active
		):
			becoming_inactive.append(
				reactive
			)

		elif (
			not currently_active
			and wants_active
		):
			becoming_active.append(
				reactive
			)

	if player_ejection_bridge != null:
		player_ejection_bridge.begin_color_transaction()

	for reactive in becoming_inactive:
		reactive.call(
			"deactivate"
		)

	for reactive in becoming_active:
		reactive.call(
			"begin_activation"
		)

	var overlapping: Array[Node] = []

	if (
		ejection_resolver != null
		and player_ejection_bridge != null
	):
		overlapping = (
			ejection_resolver.get_overlapping_reactives(
				player_ejection_bridge,
				becoming_active
			)
		)

	var had_ejection: bool = false

	if not overlapping.is_empty():
		if (
			ejection_resolver == null
			or player_ejection_bridge == null
		):
			_rollback_transaction(
				becoming_inactive,
				becoming_active,
				new_color
			)

			return

		var ejection_result: Dictionary = (
			ejection_resolver.resolve_escape(
				player_ejection_bridge,
				becoming_active
			)
		)

		if not bool(
			ejection_result.get(
				"success",
				false
			)
		):
			_rollback_transaction(
				becoming_inactive,
				becoming_active,
				new_color
			)

			return

		had_ejection = true

		player_ejection_bridge.apply_position_correction(
			ejection_result
		)

		for reactive in overlapping:
			if reactive.has_method(
				"notify_activation_overlap"
			):
				reactive.call(
					"notify_activation_overlap",
					player_ejection_bridge.player
				)

	for reactive in becoming_active:
		reactive.call(
			"complete_activation"
		)

	if color_state != null:
		color_state.commit_color(
			new_color
		)

	await get_tree().process_frame

	if player_ejection_bridge != null:
		player_ejection_bridge.finish_color_transaction(
			had_ejection
		)

	_transaction_active = false

	color_transaction_finished.emit(
		new_color
	)


func _rollback_transaction(
	becoming_inactive: Array[Node],
	becoming_active: Array[Node],
	requested_color: int
) -> void:
	for reactive in becoming_active:
		reactive.call(
			"set_active_immediate",
			false
		)

	for reactive in becoming_inactive:
		reactive.call(
			"set_active_immediate",
			true
		)

	if player_ejection_bridge != null:
		player_ejection_bridge.cancel_color_transaction()

	if color_state != null:
		color_state.cancel_requested_change()

	_transaction_active = false

	color_transaction_failed.emit(
		requested_color
	)


func _sync_all_reactives(
	player_color: int
) -> void:
	for reactive in _reactives:
		if reactive == null:
			continue

		if not is_instance_valid(
			reactive
		):
			continue

		var wants_active: bool = bool(
			reactive.call(
				"should_be_active",
				player_color
			)
		)

		reactive.call(
			"set_active_immediate",
			wants_active
		)
