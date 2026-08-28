extends RefCounted
class_name DamageInfo


var damage: float = 0.0

var source: Node = null

var affiliation: int = (
	ColorState.Affiliation.NEUTRAL
)


func setup(
	new_damage: float,
	new_source: Node,
	new_affiliation: int
) -> DamageInfo:
	damage = maxf(
		0.0,
		new_damage
	)

	source = new_source

	affiliation = new_affiliation

	return self
