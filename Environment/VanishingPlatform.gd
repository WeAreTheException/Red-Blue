extends StaticBody2D
class_name VanishingPlatform


@export_group("References")

@export var visual: Polygon2D
@export var solid_collision: CollisionPolygon2D
@export var step_trigger: Area2D


@export_group("Vanish")

@export var vanish_delay: float = 0.8


@export_group("Warning Shake")

@export var shake_amount: float = 1.0
@export var shake_speed: float = 20.0


@export_group("Debug")

@export var print_debug: bool = true


var is_triggered: bool = false
var shake_time: float = 0.0
var visual_start_position: Vector2


func _ready() -> void:
	if print_debug:
		print("----- VANISH PLATFORM READY -----")
		print("Visual: ", visual)
		print("Solid Collision: ", solid_collision)
		print("Step Trigger: ", step_trigger)

	if visual != null:
		visual_start_position = visual.position

	if step_trigger == null:
		if print_debug:
			print("ERROR: Step Trigger is NOT assigned.")
		return

	# For testing, detect bodies on every collision layer.
	step_trigger.collision_layer = 0
	step_trigger.collision_mask = 0xFFFFFFFF
	step_trigger.monitoring = true

	if print_debug:
		print(
			"Trigger monitoring: ",
			step_trigger.monitoring
		)

		print(
			"Trigger collision layer: ",
			step_trigger.collision_layer
		)

		print(
			"Trigger collision mask: ",
			step_trigger.collision_mask
		)

	step_trigger.body_entered.connect(
		_on_body_entered
	)

	if print_debug:
		print("body_entered signal CONNECTED.")


func _process(delta: float) -> void:
	if not is_triggered:
		return

	shake_time += delta

	_update_warning_shake()


func _on_body_entered(body: Node2D) -> void:
	if print_debug:
		print("------------------------------")
		print("BODY ENTERED TRIGGER")
		print("Body: ", body)
		print("Body name: ", body.name)
		print("Body class: ", body.get_class())
		print("Is PlayerRoot: ", body is PlayerRoot)
		print("------------------------------")

	if is_triggered:
		return

	if not body is PlayerRoot:
		if print_debug:
			print("IGNORED: Body is not PlayerRoot.")
		return

	if print_debug:
		print("PLAYER DETECTED. STARTING COUNTDOWN.")

	_start_countdown()


func _start_countdown() -> void:
	if is_triggered:
		return

	is_triggered = true
	shake_time = 0.0

	if print_debug:
		print(
			"VANISH COUNTDOWN STARTED: ",
			vanish_delay,
			" seconds"
		)

	await get_tree().create_timer(
		vanish_delay
	).timeout

	_vanish()


func _update_warning_shake() -> void:
	if visual == null:
		return

	var frame: int = int(
		shake_time * shake_speed
	)

	var x_offset: float = shake_amount

	if frame % 2 == 0:
		x_offset = -shake_amount

	visual.position = (
		visual_start_position
		+ Vector2(
			x_offset,
			0.0
		)
	)


func _vanish() -> void:
	if print_debug:
		print("VANISHING PLATFORM NOW.")

	if visual != null:
		visual.position = visual_start_position
		visual.visible = false
	else:
		if print_debug:
			print("ERROR: No Polygon2D assigned.")

	if solid_collision != null:
		solid_collision.set_deferred(
			"disabled",
			true
		)
	else:
		if print_debug:
			print(
				"ERROR: No CollisionPolygon2D assigned."
			)

	if step_trigger != null:
		step_trigger.set_deferred(
			"monitoring",
			false
		)
