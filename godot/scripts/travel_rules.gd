class_name EVTravelRules
extends RefCounted

# Provisional world-unit thresholds, pending comparison with the original engine.
const MAX_LANDING_SPEED: float = 25.0
const HYPERSPACE_CLEARANCE: float = 500.0

static func landing_body(position: Vector2, bodies: Array) -> Dictionary:
	var result: Dictionary = {}
	var nearest: float = INF
	for body in bodies:
		var distance: float = position.distance_to(body.position)
		if distance <= body.radius and distance < nearest:
			nearest = distance
			result = body
	return result

static func hyperspace_obstacle(position: Vector2, bodies: Array) -> Dictionary:
	var result: Dictionary = {}
	var largest_shortfall: float = 0.0
	for body in bodies:
		var remaining: float = body.radius + HYPERSPACE_CLEARANCE - position.distance_to(body.position)
		if remaining > largest_shortfall:
			largest_shortfall = remaining
			result = {"body": body, "remaining": remaining}
	return result
