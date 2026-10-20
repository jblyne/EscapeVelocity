class_name EVFlight
extends RefCounted

# Provisional conversions from the original data. These are deliberately isolated
# until original executable timing and unit conversions have been established.
const ACCEL_SCALE = 0.7
const TURN_SCALE = 0.65
const WEAPON_TICK_SECONDS = 1.0 / 60.0

static func facing(direction: Vector2) -> float:
	return atan2(direction.x, -direction.y)

static func steering(heading: float, target: float, fields: Dictionary, dt: float) -> float:
	return clampf(angle_difference(heading, target) / maxf(float(fields.Maneuver) * TURN_SCALE * dt, 0.000001), -1, 1)

static func step(pos: Vector2, velocity: Vector2, heading: float, turn: float, thrust: bool, retrograde: bool, fields: Dictionary, dt: float, throttle: float = 1.0) -> Dictionary:
	# Down only turns against drift. Main-engine thrust must provide deceleration.
	# Explicit left/right steering takes priority when both controls are held.
	if retrograde and is_zero_approx(turn) and velocity.length_squared() > 0.000001:
		turn = steering(heading, facing(-velocity), fields, dt)
	var next_heading: float = heading + turn * float(fields.Maneuver) * TURN_SCALE * dt
	var mid_heading: float = (heading + next_heading) * 0.5
	var acceleration = Vector2(sin(mid_heading), -cos(mid_heading)) * float(fields.Accel) * ACCEL_SCALE
	var next_velocity = velocity
	if thrust:
		next_velocity += acceleration * dt * clampf(throttle, 0, 1)
	# A canceled hyperdrive burn can leave excess momentum. Preserve that coast;
	# the main engine cannot add speed above it, and retrograde thrust still brakes.
	next_velocity = next_velocity.limit_length(maxf(float(fields.Speed), velocity.length()))
	return {"position": pos + (velocity + next_velocity) * 0.5 * dt,
		"velocity": next_velocity, "heading": wrapf(next_heading, -PI, PI)}
