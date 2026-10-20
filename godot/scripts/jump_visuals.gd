class_name EVJumpVisuals
extends RefCounted

const STRETCH_SECONDS: float = 2.0
const MAX_LENGTH: float = 2.8
const SNAP_SECONDS: float = 0.65
var arrival_age: float = -1.0

func reset() -> void:
	arrival_age = -1.0

func arrive() -> void:
	arrival_age = 0.0

func advance(dt: float) -> void:
	if arrival_age < 0: return
	arrival_age += dt
	if arrival_age >= SNAP_SECONDS: reset()

func departure_strength(drive) -> float:
	if drive.phase != "accelerating": return 0.0
	var progress = clampf(1.0-drive.remaining/STRETCH_SECONDS,0.0,1.0)
	return progress*progress*(3.0-2.0*progress)

func ship_offset(drive, clock: float) -> Vector3:
	if drive.phase != "accelerating": return Vector3.ZERO
	var progress=clampf(1.0-drive.remaining/drive.ACCELERATION_SECONDS,0.0,1.0)
	# A small visual vibration builds with the departure burn, never affecting
	# the pilot's physical position, camera, or ordinary main-engine thrust.
	return Vector3(sin(clock*61)*1.2+sin(clock*89)*.6,0,cos(clock*73)*.4)*progress*progress

func ship_scale(drive) -> Vector3:
	var length: float = lerpf(1.0,MAX_LENGTH,departure_strength(drive))
	if arrival_age >= 0:
		# Fast contraction, a small squash, then one damped rebound. Evaluating
		# from elapsed time avoids accumulating scale or frame-rate-dependent springs.
		length = 1.0+(MAX_LENGTH-1.0)*exp(-11.0*arrival_age)*cos(18.0*arrival_age)
	return Vector3(pow(length,-0.32),1.0,length)
