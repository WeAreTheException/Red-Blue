extends Label
class_name ShooterCountdownLabel


@export_group("References")

@export var bullet_shooter: BulletShooter


@export_group("Display")

@export_range(
	0,
	2,
	1
)
var decimal_places: int = 1

@export var hide_when_not_counting: bool = true


func _process(
	_delta: float
) -> void:
	if bullet_shooter == null:
		text = ""

		return

	if not bullet_shooter.is_counting_down:
		if hide_when_not_counting:
			text = ""

		else:
			text = _format_time(
				0.0
			)

		return

	text = _format_time(
		bullet_shooter.time_until_next_shot
	)


func _format_time(
	value: float
) -> String:
	var safe_value: float = maxf(
		0.0,
		value
	)

	match decimal_places:
		0:
			return "%d" % ceili(
				safe_value
			)

		2:
			return "%.2f" % safe_value

		_:
			return "%.1f" % safe_value
