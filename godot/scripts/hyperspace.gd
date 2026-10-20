class_name EVHyperspace
extends RefCounted

const Flight = preload("res://scripts/flight.gd")
const Travel = preload("res://scripts/travel_rules.gd")
# Departure tuned from playtest feedback; arrival from the observed Levo/Rigel flights.
# These are remake tuning values, not recovered engine constants.
const SPOOL_SECONDS: float = 0.6
const ACCELERATION_SECONDS: float = 4.8
const DEPARTURE_SPEED_MULTIPLIER: float = 7.5
const ARRIVAL_APPROACH_SECONDS: float = 4.8
const ALIGN_TOLERANCE: float = 0.0001
const STOP_TOLERANCE: float = 0.0001
var phase: String = "idle"
var destination: int = -1
var heading: float = 0
var remaining: float = SPOOL_SECONDS

func active() -> bool:
	return phase != "idle"

func begin(target: int, warp_heading: float) -> void:
	destination = target
	heading = warp_heading
	remaining = SPOOL_SECONDS
	phase = "stopping"

func reset() -> void:
	phase = "idle"
	destination = -1
	remaining = SPOOL_SECONDS

func status() -> String:
	match phase:
		"stopping": return "Stopping with main engines"
		"aligning": return "Aligning with destination"
		"spooling": return "Spooling hyperdrive · %.1f s" % remaining
		"accelerating": return "Accelerating into hyperspace · %.1f s" % remaining
	return ""

func step(pos: Vector2, velocity: Vector2, ship_heading: float, fields: Dictionary, dt: float) -> Dictionary:
	var turn: float = 0
	var throttle: float = 0
	var complete: bool = false
	match phase:
		"stopping":
			if velocity.length() <= STOP_TOLERANCE:
				# Remove floating-point residue only, after engine thrust has stopped us.
				velocity = Vector2.ZERO
				phase = "aligning"
			else:
				var target: float = Flight.facing(-velocity)
				turn = Flight.steering(ship_heading, target, fields, dt)
				if absf(angle_difference(ship_heading, target)) <= ALIGN_TOLERANCE:
					# Throttle the final engine impulse so it cannot reverse our drift.
					throttle = minf(1, velocity.length() / (float(fields.Accel) * Flight.ACCEL_SCALE * dt))
		"aligning":
			turn = Flight.steering(ship_heading, heading, fields, dt)
			if absf(angle_difference(ship_heading, heading)) <= ALIGN_TOLERANCE:
				phase = "spooling"
		"spooling":
			remaining = maxf(0, remaining - dt)
			if remaining <= 0:
				phase = "accelerating"
				remaining = ACCELERATION_SECONDS
		"accelerating":
			# Hyperdrive thrust keeps building speed beyond the main engine's cruise cap.
			# Integrate only the remaining burn time so the endpoint is frame-rate independent.
			var burn_dt: float = minf(dt, remaining)
			var direction = Vector2(sin(heading), -cos(heading))
			var departure_speed: float = float(fields.Speed) * DEPARTURE_SPEED_MULTIPLIER
			var next_velocity = velocity + direction * (departure_speed / ACCELERATION_SECONDS) * burn_dt
			remaining = maxf(0, remaining - burn_dt)
			return {"position": pos + (velocity + next_velocity) * 0.5 * burn_dt,
				"velocity": next_velocity, "heading": heading, "thrust": 1.0, "complete": remaining <= 0}
	var result = Flight.step(pos, velocity, ship_heading, turn, throttle > 0, false, fields, dt, throttle)
	result["thrust"] = throttle
	result["complete"] = complete
	return result

static func arrival(warp_heading: float, fields: Dictionary, bodies: Array) -> Dictionary:
	var direction = Vector2(sin(warp_heading), -cos(warp_heading))
	var speed: float = fields.Speed
	var focus: Vector2 = Vector2.ZERO if bodies.is_empty() else bodies[0].position
	# Pass close to the primary world, with a small lateral offset as observed.
	var offset: float = 0 if bodies.is_empty() else float(bodies[0].radius) * 0.35
	var approach = focus + direction.orthogonal() * offset
	var distance: float = speed * ARRIVAL_APPROACH_SECONDS
	# Multi-world entry is a conservative extension: enter before every exclusion
	# circle intersecting this approach line. The original's rule is unverified.
	for body in bodies:
		var relative: Vector2 = approach - body.position
		var along: float = relative.dot(direction)
		var across: float = absf(relative.cross(direction))
		var clearance: float = float(body.radius) + Travel.HYPERSPACE_CLEARANCE
		if across < clearance:
			distance = maxf(distance, along + sqrt(clearance * clearance - across * across) + 1)
	return {"position": approach - direction * distance,
		"velocity": direction * speed, "heading": warp_heading}
