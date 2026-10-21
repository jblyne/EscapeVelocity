class_name EVFlight
extends RefCounted

# EV 1.0.5: loader 0x24744/0x24788, helpers 0x62400/0x62548,
# turn helper 0x622b0. One reference coordinate = 5/3 world units, so the
# recovered projectile speeds retain their existing world-units/second values.
const REFERENCE_HZ = 60.0
const WORLD_UNITS_PER_REFERENCE_UNIT = 5.0 / 3.0
const ACCEL_SCALE = 2.0 / 10000.0 * REFERENCE_HZ * REFERENCE_HZ * WORLD_UNITS_PER_REFERENCE_UNIT
const TURN_SCALE = PI / 180.0 * REFERENCE_HZ
const PLAYER_SPEED_MULTIPLIER = 1.75
const WEAPON_TICK_SECONDS = 1.0 / REFERENCE_HZ

static func acceleration(fields: Dictionary) -> float:
	return float(fields.Accel) * (0.7 if fields.get("custom_flight",false) else ACCEL_SCALE)

static func turn_rate(fields: Dictionary) -> float:
	return float(fields.Maneuver) * (0.65 if fields.get("custom_flight",false) else TURN_SCALE)

static func reload_remaining(remaining: float, dt: float, held: bool=false) -> float:
	if remaining==0: return 0.0
	var value: float=remaining-dt
	# Decimal tick subtraction must not add an extra frame at a reload boundary.
	if absf(value)<=.000001: return 0.0
	return maxf(-dt,value) if held else maxf(0,value)

static func facing(direction: Vector2) -> float:
	return atan2(direction.x, -direction.y)

static func steering(heading: float, target: float, fields: Dictionary, dt: float) -> float:
	return clampf(angle_difference(heading, target) / maxf(turn_rate(fields) * dt, 0.000001), -1, 1)

static func step(pos: Vector2, velocity: Vector2, heading: float, turn: float, thrust: bool, retrograde: bool, fields: Dictionary, dt: float, throttle: float = 1.0) -> Dictionary:
	# Down only turns against drift. Main-engine thrust must provide deceleration.
	# Explicit left/right steering takes priority when both controls are held.
	if retrograde and is_zero_approx(turn) and velocity.length_squared() > 0.000001:
		turn = steering(heading, facing(-velocity), fields, dt)
	var next_heading: float = heading + turn * turn_rate(fields) * dt
	var mid_heading: float = (heading + next_heading) * 0.5
	var force = Vector2(sin(mid_heading), -cos(mid_heading)) * acceleration(fields)
	var next_velocity = velocity
	if thrust:
		next_velocity += force * dt * clampf(throttle, 0, 1)
	# A canceled hyperdrive burn can leave excess momentum. Preserve that coast;
	# the main engine cannot add speed above it, and retrograde thrust still brakes.
	next_velocity = next_velocity.limit_length(maxf(float(fields.Speed), velocity.length()))
	return {"position": pos + (velocity + next_velocity) * 0.5 * dt,
		"velocity": next_velocity, "heading": wrapf(next_heading, -PI, PI)}
