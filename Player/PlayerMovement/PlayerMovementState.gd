extends RefCounted
class_name PlayerMovementState


var Speed: Vector2 = Vector2.ZERO
var Facing: int = 1

var Dashes: int = 0
var StateMachineState: int = 0

var onGround: bool = false
var wasOnGround: bool = false

var moveX: int = 0
var moveY: int = 0

var jumpGraceTimer: float = 0.0

var AutoJump: bool = false
var AutoJumpTimer: float = 0.0

var varJumpSpeed: float = 0.0
var varJumpTimer: float = 0.0

var forceMoveX: int = 0
var forceMoveXTimer: float = 0.0

var lastAim: Vector2 = Vector2.RIGHT

var dashCooldownTimer: float = 0.0
var dashRefillCooldownTimer: float = 0.0

var DashDir: Vector2 = Vector2.ZERO

var wallSlideTimer: float = 0.0
var wallSlideDir: int = 0

var wallSpeedRetentionTimer: float = 0.0
var wallSpeedRetained: float = 0.0

var wallBoostDir: int = 0
var wallBoostTimer: float = 0.0

var maxFall: float = 0.0

var dashAttackTimer: float = 0.0
var dashStartedOnGround: bool = false
var beforeDashSpeed: Vector2 = Vector2.ZERO

var StartedDashing: bool = false
var dashTimer: float = 0.0
var dashPending: bool = false

var jump_pressed: bool = false
var jump_check: bool = false

var dash_pressed: bool = false

var grab_check: bool = false

@warning_ignore("unused_private_class_variable")
var _jump_was_down: bool = false
@warning_ignore("unused_private_class_variable")
var _dash_was_down: bool = false

var Ducking: bool = false
var launched: bool = false

var LiftBoost: Vector2 = Vector2.ZERO

var Stamina: float = 0.0
var climbNoMoveTimer: float = 0.0

var movement_phase: StringName = &""


# Wavedash debug tracking.
#
# These do NOT create a new movement state.
# They only remember how the current SuperJump was reached.

var dash_landed_from_air: bool = false
var dash_refilled_after_air_landing: bool = false
