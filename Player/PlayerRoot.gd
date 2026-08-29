extends CharacterBody2D
class_name PlayerRoot


#region State IDs

const StNormal: int = 0
const StClimb: int = 1
const StDash: int = 2

#endregion


#region References

@export_group("References")

@export var player_visual: ColorRect
@export var respawn_point: Node2D

#endregion


#region Run

@export_group("Run")

@export var MaxRun: float = 90.0
@export var RunAccel: float = 1000.0
@export var RunReduce: float = 400.0
@export var AirMult: float = 0.65

#endregion


#region Fall

@export_group("Fall")

@export var MaxFall: float = 160.0
@export var Gravity: float = 900.0
@export var HalfGravThreshold: float = 40.0

@export var FastMaxFall: float = 240.0
@export var FastMaxAccel: float = 300.0

#endregion


#region Jump

@export_group("Jump")

@export var JumpGraceTime: float = 0.1
@export var JumpSpeed: float = -105.0
@export var JumpHBoost: float = 40.0
@export var VarJumpTime: float = 0.2
@export var CeilingVarJumpGrace: float = 0.05
@export var UpwardCornerCorrection: int = 4

#endregion


#region Bounce

@export_group("Bounce")

# Your current normal spring launch.
@export var BounceSpeed: float = -185.0
@export var BounceVarJumpTime: float = 0.2
@export var BounceAutoJumpTime: float = 0.1


@export_subgroup("Super Bounce")

# JUMP + UP spring.
# Separate from the normal spring speed.
@export var SuperBounceSpeed: float = -235.0
@export var SuperBounceVarJumpTime: float = 0.2
@export var SuperBounceAutoJumpTime: float = 0.0


@export_subgroup("Side Bounce")

@export var SideBounceHSpeed: float = 240.0
@export var SideBounceVSpeed: float = -140.0
@export var SideBounceVarJumpTime: float = 0.2
@export var SideBounceAutoJumpTime: float = 0.0
@export var SideBounceForceTime: float = 0.3

#endregion


#region Super Jump

@export_group("Super Jump")

@export var SuperJumpH: float = 260.0
@export var DuckSuperJumpXMult: float = 1.25
@export var DuckSuperJumpYMult: float = 0.5

#endregion


#region Wall Jump

@export_group("Wall Jump")

@export var WallJumpCheckDist: int = 3
@export var WallJumpForceTime: float = 0.16
@export var WallJumpHSpeed: float = 130.0
@export var WallSpeedRetentionTime: float = 0.06


@export_subgroup("Wall Slide")

@export var WallSlideStartMax: float = 20.0
@export var WallSlideTime: float = 1.2


@export_subgroup("Super Wall Jump")

@export var SuperWallJumpSpeed: float = -160.0
@export var SuperWallJumpVarTime: float = 0.25
@export var SuperWallJumpForceTime: float = 0.2
@export var SuperWallJumpH: float = 170.0

#endregion


#region Climb

@export_group("Climb")

# Leave this ON while testing.
# Turn it OFF when you want real stamina.
@export var ClimbInfiniteStamina: bool = true

@export var ClimbMaxStamina: float = 110.0
@export var ClimbTiredThreshold: float = 20.0

@export var ClimbCheckDist: int = 2
@export var ClimbUpCheckDist: int = 2
@export var ClimbNoMoveTime: float = 0.1

@export var ClimbUpSpeed: float = -45.0
@export var ClimbDownSpeed: float = 80.0
@export var ClimbSlipSpeed: float = 30.0
@export var ClimbAccel: float = 900.0

@export var ClimbGrabYMult: float = 0.2

@export var ClimbUpCost: float = (
	100.0 / 2.2
)

@export var ClimbStillCost: float = (
	100.0 / 10.0
)

@export var ClimbJumpCost: float = (
	110.0 / 4.0
)


@export_subgroup("Climb Jump")

@export var ClimbJumpBoostTime: float = 0.2


@export_subgroup("Ledge Hop")

@export var ClimbHopY: float = -120.0
@export var ClimbHopX: float = 100.0
@export var ClimbHopForceTime: float = 0.2

#endregion


#region Dash

@export_group("Dash")

@export var MaxDashes: int = 1
@export var DashSpeed: float = 240.0
@export var EndDashSpeed: float = 160.0
@export var EndDashUpMult: float = 0.75
@export var DashTime: float = 0.15
@export var DashCooldown: float = 0.2
@export var DashRefillCooldown: float = 0.1
@export var DashCornerCorrection: int = 4
@export var DashVFloorSnapDist: int = 3
@export var DashAttackTime: float = 0.3
@export var DodgeSlideSpeedMult: float = 1.2
@export_range(
	0.0,
	0.2,
	0.005
)
var DashHitstopTime: float = 0.05

#endregion


#region Launch

@export_group("Launch")

@export var LaunchedBoostCheckSpeedSq: float = 100.0 * 100.0
@export var LaunchedJumpCheckSpeedSq: float = 220.0 * 220.0

#endregion


#region Environment

@export_group("Environment")

@export var SpacePhysicsMult: float = 0.6
@export var SwimDashSpeedMult: float = 0.75

@export var InSpace: bool = false
@export var InCold: bool = false
@export var InWater: bool = false

#endregion


#region Runtime

var movement: PlayerMovement = PlayerMovement.new()

#endregion


func _ready() -> void:
	movement.setup(
		self
	)


func _physics_process(
	delta: float
) -> void:
	movement.update(
		delta
	)
