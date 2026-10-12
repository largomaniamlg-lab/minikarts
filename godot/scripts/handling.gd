extends RefCounted

# Shared by authoritative physics and client prediction.
const TURN_RADIUS := 15.0
const STEERING_PRESS_RATE := 6.0
const STEERING_RELEASE_RATE := 12.0

static func steer(current: float, desired: float, delta: float) -> float:
	return move_toward(current, clampf(desired, -1.0, 1.0), (STEERING_RELEASE_RATE if is_zero_approx(desired) else STEERING_PRESS_RATE) * delta)

static func turn(steering: float, speed: float, delta: float) -> float:
	return -steering * speed / TURN_RADIUS * delta
