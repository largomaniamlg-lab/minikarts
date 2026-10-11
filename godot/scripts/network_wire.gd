extends RefCounted
# Only serialization is rounded; authoritative physics retains full precision.
const STATE_BACKLOG_LIMIT := 8192
static func number(value: float, step: float = 0.01) -> float:
	return snappedf(value, step)
static func vector(value: Vector3, step: float = 0.01) -> Array:
	return [number(value.x, step), number(value.y, step), number(value.z, step)]
static func can_queue_state(buffered: int) -> bool:
	return buffered <= STATE_BACKLOG_LIMIT
