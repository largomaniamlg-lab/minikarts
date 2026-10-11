extends RefCounted

# Presentation only: never sends positions or changes race rules.
const BUFFER_SECONDS := 0.10
const MAX_PREDICTION := 0.15
var states: Array = []
var offset := INF
var received_at := 0.0

func clear() -> void:
	states.clear()
	offset = INF
	received_at = 0.0

func push(state: Dictionary, arrival: float) -> void:
	if not states.is_empty() and states.back().phase != state.phase:
		clear()
	var timestamp := float(state.get("time", arrival))
	if not states.is_empty() and timestamp <= float(states.back().get("time", 0.0)):
		return
	offset = minf(offset, arrival - timestamp)
	received_at = arrival
	states.append(state)
	while states.size() > 32:
		states.pop_front()

func vec(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

func project(racer: Dictionary, seconds: float, controls: Dictionary = {}) -> Dictionary:
	var result := racer.duplicate()
	var age := clampf(seconds, 0.0, MAX_PREDICTION)
	var pos := vec(racer.position)
	var yaw := float(racer.rotation[1])
	var speed := float(racer.speed)
	var steering := float(racer.steering)
	var velocity := vec(racer.get("velocity", [0, 0, 0]))
	if float(racer.hit) > 0:
		yaw += TAU * minf(age, float(racer.hit))
	elif not controls.is_empty():
		var desired := float(controls.get("steer_right", 0)) - float(controls.get("steer_left", 0))
		steering = move_toward(steering, desired, (12.0 if is_zero_approx(desired) else 3.0) * age)
		var target := 22.0
		var rate := 10.0
		if float(controls.get("brake", 0)) > 0 or float(controls.get("handbrake", 0)) > 0:
			target = 0.0
			rate = 32.0 if float(controls.get("handbrake", 0)) > 0 else 24.0
		elif float(controls.get("reverse", 0)) > 0.5:
			target = -6.0
			rate = 12.0
		elif float(controls.get("accelerate", 0)) <= 0:
			target = 0.0
			rate = 4.0
		var predicted_speed := move_toward(speed, target, rate * age)
		# Do not anticipate movement through a wall when the server reports blocked velocity.
		if Vector2(velocity.x, velocity.z).length() > 0.1:
			var turn := -steering * (speed + predicted_speed) / 44.0 * age
			velocity.x = -sin(yaw + turn * 0.5) * (speed + predicted_speed) * 0.5
			velocity.z = -cos(yaw + turn * 0.5) * (speed + predicted_speed) * 0.5
			yaw += turn
		speed = predicted_speed
	else:
		yaw -= steering * speed / 22.0 * age
	pos += velocity * age
	result.position = [pos.x, pos.y, pos.z]
	result.rotation = [racer.rotation[0], yaw, racer.rotation[2]]
	result.speed = speed
	result.steering = steering
	return result

func remote(id: int, now: float) -> Dictionary:
	if states.is_empty():
		return {}
	var time := now - offset - BUFFER_SECONDS
	var before: Dictionary = states.front()
	var after: Dictionary = before
	for state in states:
		after = state
		if float(state.get("time", 0.0)) >= time:
			break
		before = state
	var a := find_racer(before, id)
	var b := find_racer(after, id)
	if a.is_empty() or b.is_empty():
		return b
	var span := float(after.get("time", 0.0)) - float(before.get("time", 0.0))
	if span <= 0:
		return project(b, time - float(after.get("time", time))) if after.phase == "racing" and not b.finished else b
	var weight := clampf((time - float(before.time)) / span, 0.0, 1.0)
	# Recovery and restarts must teleport, not drag a kart across the circuit.
	if vec(a.position).distance_to(vec(b.position)) > 6.0:
		return b
	var result := b.duplicate()
	var pos := vec(a.position).lerp(vec(b.position), weight)
	result.position = [pos.x, pos.y, pos.z]
	result.rotation = [b.rotation[0], lerp_angle(float(a.rotation[1]), float(b.rotation[1]), weight), b.rotation[2]]
	return result

func find_racer(state: Dictionary, id: int) -> Dictionary:
	for racer in state.players:
		if int(racer.id) == id:
			return racer
	return {}
