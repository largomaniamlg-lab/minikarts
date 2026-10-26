extends RefCounted

const Handling = preload("res://scripts/handling.gd")

# Presentation only: never sends positions or changes race rules.
const BUFFER_SECONDS := 0.10
const MAX_PREDICTION := 0.15
const MAX_LOCAL_PREDICTION := 0.25
const MAX_LOCAL_STALE := 0.35
const MAX_LOCAL_DISTANCE := 5.0
const MAX_BUFFER := 0.22
var buffer_seconds := BUFFER_SECONDS
var jitter := 0.0
var arrival_samples := 0
var render_time := INF
var render_clock := -1.0
var local_pose: Dictionary = {}
var local_source: Dictionary = {}
var local_stamp := -INF
var states: Array = []
var offset := INF
var received_at := 0.0

func clear() -> void:
	states.clear()
	offset = INF
	received_at = 0.0
	buffer_seconds = BUFFER_SECONDS
	jitter = 0.0
	arrival_samples = 0
	render_time = INF
	render_clock = -1.0
	local_pose.clear()
	local_source.clear()
	local_stamp = -INF

func push(state: Dictionary, arrival: float) -> void:
	if not states.is_empty() and states.back().phase != state.phase:
		clear()
	var timestamp := float(state.get("time", arrival))
	if not states.is_empty() and timestamp <= float(states.back().get("time", 0.0)):
		return
	if not states.is_empty():
		var server_interval := timestamp - float(states.back().time)
		var error := absf((arrival - received_at) - server_interval)
		jitter = lerpf(jitter, minf(error, 0.30), 0.15)
		arrival_samples += 1
		if arrival_samples >= 5:
			var desired := clampf(BUFFER_SECONDS + 2.0 * jitter, BUFFER_SECONDS, MAX_BUFFER)
			buffer_seconds = lerpf(buffer_seconds, desired, 0.35 if desired > buffer_seconds else 0.05)
	offset = minf(offset, arrival - timestamp)
	received_at = arrival
	# Client-only index: do not add fields to the authoritative packet or wire.
	var buffered := state.duplicate()
	var by_id: Dictionary = {}
	for racer in state.players:
		var id := int(racer.id)
		if not by_id.has(id): by_id[id] = racer
	buffered["_by_id"] = by_id
	states.append(buffered)
	while states.size() > 32:
		states.pop_front()

func vec(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

func project(racer: Dictionary, seconds: float, controls: Dictionary = {}, limit: float = MAX_PREDICTION) -> Dictionary:
	var result := racer.duplicate()
	var age := clampf(seconds, 0.0, limit)
	var pos := vec(racer.position)
	var yaw := float(racer.rotation[1])
	var speed := float(racer.speed)
	var boost := float(racer.get("boost",0.0))
	var steering := float(racer.steering)
	var velocity := vec(racer.get("velocity", [0, 0, 0]))
	if float(racer.hit) > 0:
		yaw += TAU * minf(age, float(racer.hit))
	elif not controls.is_empty():
		var desired := float(controls.get("steer_right", 0)) - float(controls.get("steer_left", 0))
		var target := 65.0 / 3.6
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
		var blocked := Vector2(velocity.x, velocity.z).length() <= 0.1 and absf(speed) >= 0.05
		var remaining := age
		# A packet horizon must integrate the same gradual turn as physics;
		# applying the final steering angle to the whole horizon over-turns it.
		while remaining > 0.000001:
			var step := minf(remaining, 1.0 / 60.0)
			boost=maxf(0.0,boost-step)
			if target>0: target=80.0/3.6 if boost>0 else 65.0/3.6
			steering = Handling.steer(steering, desired, step)
			speed = move_toward(speed, target, rate * step)
			yaw += Handling.turn(steering, speed, step)
			if not blocked:
				velocity.x = -sin(yaw) * speed
				velocity.z = -cos(yaw) * speed
			pos += velocity * step
			remaining -= step
	else:
		yaw += Handling.turn(steering, speed, age)
	if controls.is_empty() or float(racer.hit) > 0:
		pos += velocity * age
	result.position = [pos.x, pos.y, pos.z]
	result.rotation = [racer.rotation[0], yaw, racer.rotation[2]]
	result.boost = maxf(0.0,boost-age) if controls.is_empty() or float(racer.hit)>0 else boost
	result.speed = speed
	result.steering = steering
	result.velocity = [velocity.x, velocity.y, velocity.z]
	result.hit = maxf(0.0, float(racer.hit) - age)
	return result

func remote(id: int, now: float) -> Dictionary:
	if states.is_empty():
		return {}
	var desired := now - offset - buffer_seconds
	if render_time == INF:
		render_time = desired
	elif now > render_clock:
		var delta := maxf(0.0, now - render_clock)
		# Change playback speed gently instead of rewinding when the buffer grows.
		var drift := desired - render_time - delta
		render_time += delta * clampf(1.0 + drift * 3.0, 0.75, 1.25)
		if absf(desired - render_time) > 0.75:
			render_time = desired
	render_clock = now
	var time := render_time
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
	if state.has("_by_id"):
		return state._by_id.get(id, {})
	for racer in state.players:
		if int(racer.id) == id:
			return racer
	return {}

# Frame-by-frame visual prediction, corrected toward authoritative snapshots.
# This does not simulate local collisions or change laps, hits, or results.
func local(racer: Dictionary, now: float, delta: float, controls: Dictionary, rtt: float) -> Dictionary:
	var age := maxf(0.0, now - received_at)
	var timestamp := float(states.back().time) if not states.is_empty() else now
	var horizon := minf(age + maxf(0.0, rtt) * 0.5, MAX_LOCAL_PREDICTION)
	var target := project(racer, horizon, controls, MAX_LOCAL_PREDICTION)
	var fresh := timestamp != local_stamp
	var discontinuity := local_pose.is_empty()
	if fresh and not local_source.is_empty():
		discontinuity = discontinuity or vec(racer.position).distance_to(vec(local_source.position)) > 6.0
		discontinuity = discontinuity or float(racer.hit) > float(local_source.hit) + 0.10
	if discontinuity:
		local_pose = target.duplicate(true)
	elif age <= MAX_LOCAL_STALE:
		if fresh:
			# Ground/air velocity and a blocked wall come from the server.
			local_pose.velocity = racer.velocity.duplicate()
			local_pose.hit = racer.hit
			local_pose.boost=target.get("boost",0.0)
		var step := clampf(delta, 0.0, 0.05)
		local_pose = project(local_pose, step, controls)
		var correction := 1.0 - exp(-6.0 * step)
		var position := vec(local_pose.position).lerp(vec(target.position), correction)
		local_pose.position = [position.x, position.y, position.z]
		local_pose.rotation[1] = lerp_angle(float(local_pose.rotation[1]), float(target.rotation[1]), 1.0 - exp(-3.0 * step))
		local_pose.speed = lerpf(float(local_pose.speed), float(target.speed), correction)
		var anchor := vec(racer.position)
		var bounded := anchor + (vec(local_pose.position) - anchor).limit_length(MAX_LOCAL_DISTANCE)
		local_pose.position = [bounded.x, bounded.y, bounded.z]
	if fresh:
		local_source = racer.duplicate(true)
		local_stamp = timestamp
	return local_pose.duplicate(true)
