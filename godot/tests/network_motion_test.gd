extends SceneTree

const Motion = preload("res://scripts/network_motion.gd")
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func state(time: float, z: float, phase := "racing", yaw := 0.0) -> Dictionary:
	return {"time": time, "phase": phase, "players": [{"id": 1, "position": [0, 0.7, z], "rotation": [0, yaw, 0], "velocity": [0, 0, -20], "speed": 20.0, "steering": 0.0, "hit": 0.0, "finished": false}]}

func _initialize() -> void:
	var motion := Motion.new()
	var racer: Dictionary = state(0, 0).players[0]
	var predicted := motion.project(racer, 0.1, {"accelerate": 1, "steer_right": 1})
	check(predicted.rotation[1] < 0 and predicted.position[0] > 0, "Steering responds before the next server packet")
	check(racer.rotation[1] == 0 and racer.position[0] == 0, "Prediction never changes authoritative state")
	check(motion.project(racer, 10).position == motion.project(racer, Motion.MAX_PREDICTION).position, "A stalled connection cannot extrapolate indefinitely")
	check(motion.vec(motion.project(racer, -1).position).is_equal_approx(motion.vec(racer.position)), "Negative prediction time does not rewind")
	var braking := motion.project(racer, 0.1, {"accelerate": 1, "brake": 1})
	check(braking.speed < racer.speed, "Brake anticipates priority over automatic acceleration")
	var blocked := racer.duplicate(true)
	blocked.velocity = [0, 0, 0]
	check(motion.vec(motion.project(blocked, 0.15, {"accelerate": 1}).position).is_equal_approx(motion.vec(blocked.position)), "Blocked kart is not predicted through a wall")
	var hit := racer.duplicate(true)
	hit.hit = 1.0
	check(motion.project(hit, 0.1, {"steer_left": 1}).rotation[1] > 0.5, "Authoritative spin overrides steering prediction")
	motion.push(state(10, 0), 20)
	motion.push(state(10.1, -2), 20.12)
	check(absf(motion.remote(1, 20.15).position[2] + 1) < 0.001, "Buffered interpolation handles delayed packet arrival")
	motion.clear()
	motion.push(state(0, 0, "racing", deg_to_rad(179)), 0)
	motion.push(state(0.1, -2, "racing", deg_to_rad(-179)), 0.1)
	check(absf(absf(motion.remote(1, 0.15).rotation[1]) - PI) < 0.001, "Rotation crosses the angle boundary without a full turn")
	motion.push(state(0.2, -30), 0.2)
	check(motion.remote(1, 0.25).position[2] == -30, "Recovery snaps instead of crossing the track")
	motion.push(state(0.3, 0, "lobby"), 0.3)
	check(motion.states.size() == 1 and motion.remote(1, 10).position[2] == 0, "Phase change clears racing history and lobby never extrapolates")
	motion.clear()
	# 20 Hz snapshots, arriving in uneven bursts. Render at 60 Hz.
	var next := 0
	var last_z := 0.0
	var largest_step := 0.0
	for frame in range(120):
		var now := frame / 60.0
		while next < 40 and next * 0.05 + ([0.04, 0.08, 0.02, 0.06][next % 4]) <= now:
			motion.push(state(next * 0.05, -20 * next * 0.05), now)
			next += 1
		var visual := motion.remote(1, now)
		if not visual.is_empty():
			var z := float(visual.position[2])
			if now > 0.4:
				largest_step = maxf(largest_step, absf(z - last_z))
			last_z = z
	check(largest_step < 0.5, "Uneven arrivals render smoothly instead of two-metre packet jumps")
	check(motion.states.size() <= 32, "Snapshot history stays bounded")
	motion.clear()
	var source := state(0, 0)
	var untouched := JSON.stringify(source)
	motion.push(source, 0)
	var straight := motion.local(source.players[0], 0.0, 1.0 / 60.0, {"accelerate": 1}, 0.20)
	var turn := motion.local(source.players[0], 1.0 / 60.0, 1.0 / 60.0, {"accelerate": 1, "steer_right": 1}, 0.20)
	check(float(turn.rotation[1]) < float(straight.rotation[1]), "Local steering changes on the first rendered frame without a new snapshot")
	check(JSON.stringify(source) == untouched, "Local prediction leaves authoritative positions untouched")
	var latest := turn
	for frame in range(2, 24):
		latest = motion.local(source.players[0], frame / 60.0, 1.0 / 60.0, {"accelerate": 1}, 0.20)
	check(motion.vec(latest.position).distance_to(Vector3(0, 0.7, 0)) <= Motion.MAX_LOCAL_DISTANCE + 0.001, "Local visual prediction stays within its spatial bound")
	var frozen := motion.local(source.players[0], 2.0, 0.1, {"accelerate": 1, "steer_left": 1}, 0.20)
	check(frozen.position == latest.position and frozen.rotation == latest.rotation, "Stalled link freezes local visual prediction")
	motion.push(state(2, -30), 2)
	var recovered := motion.local(state(2, -30).players[0], 2, 0.016, {}, 0)
	check(recovered.position[2] == -30, "Local recovery discards predicted path immediately")
	var collision := state(2.05, -30.2)
	collision.players[0].hit = 1.0
	motion.push(collision, 2.05)
	var spun := motion.local(collision.players[0], 2.05, 0.016, {"steer_right": 1}, 0)
	check(spun.hit == 1.0, "Fresh authoritative hit replaces local prediction immediately")
	motion.clear()
	var last_cursor := -INF
	for index in range(30):
		var now := index * 0.05 + (0.14 if index % 4 == 0 else 0.03)
		# Packet arrival times must stay ordered even on a jittery TCP connection.
		now = maxf(now, motion.received_at)
		motion.push(state(index * 0.05, -index), now)
		motion.remote(1, now)
		check(motion.render_time >= last_cursor, "Adaptive buffer never rewinds playback")
		last_cursor = motion.render_time
	check(motion.buffer_seconds > Motion.BUFFER_SECONDS and motion.buffer_seconds <= Motion.MAX_BUFFER, "Interpolation buffer adapts to observed arrival jitter with a fixed upper bound")
	for index in range(30, 180):
		motion.push(state(index * 0.05, -index), index * 0.05 + 0.20)
	check(motion.buffer_seconds < 0.12, "Buffer relaxes again when packet timing stabilizes")
	motion.clear()
	var pending: Array = []
	var due := 0.0
	for index in range(80):
		due = maxf(due, index * 0.05 + [0.06, 0.10, 0.22, 0.08][index % 4])
		pending.append({"due": due, "time": index * 0.05})
	var largest_local_step := 0.0
	var previous_position := Vector3.ZERO
	var reversed := false
	for frame in range(240):
		var now := frame / 60.0
		while not pending.is_empty() and pending.front().due <= now:
			var item: Dictionary = pending.pop_front()
			var packet := state(item.time, -18.0 * item.time)
			packet.players[0].speed = 18.0
			packet.players[0].velocity = [0, 0, -18.0]
			motion.push(packet, now)
		if motion.states.is_empty():
			continue
		var pose := motion.local(motion.states.back().players[0], now, 1.0 / 60.0, {"accelerate": 1}, 0.24)
		var position := motion.vec(pose.position)
		if now > 0.5:
			largest_local_step = maxf(largest_local_step, position.distance_to(previous_position))
			reversed = reversed or position.z > previous_position.z + 0.001
		previous_position = position
	check(largest_local_step < 0.55, "Continuous local motion limits jumps under delayed bursts")
	check(not reversed, "Network corrections do not reverse a steadily moving local kart")
	print("Largest local jitter step: %.3f m" % largest_local_step)
	motion.clear()
	pending.clear()
	due = 0.0
	for index in range(80):
		due = maxf(due, index * 0.05 + [0.06, 0.10, 0.22, 0.08][index % 4])
		pending.append({"due": due, "time": index * 0.05})
	var previous_yaw := 0.0
	var largest_turn_step := 0.0
	var largest_turn_move := 0.0
	for frame in range(240):
		var now := frame / 60.0
		while not pending.is_empty() and pending.front().due <= now:
			var item: Dictionary = pending.pop_front()
			var theta: float = 18.0 / 15.0 * item.time
			var packet := state(item.time, -15.0 * sin(theta), "racing", -theta)
			packet.players[0].position[0] = 15.0 * (1.0 - cos(theta))
			packet.players[0].speed = 18.0
			packet.players[0].steering = 1.0
			packet.players[0].velocity = [18.0 * sin(theta), 0, -18.0 * cos(theta)]
			motion.push(packet, now)
		if motion.states.is_empty():
			continue
		var pose := motion.local(motion.states.back().players[0], now, 1.0 / 60.0, {"accelerate": 1, "steer_right": 1}, 0.24)
		var position := motion.vec(pose.position)
		if now > 0.5:
			largest_turn_move = maxf(largest_turn_move, position.distance_to(previous_position))
			largest_turn_step = maxf(largest_turn_step, absf(angle_difference(previous_yaw, float(pose.rotation[1]))))
		previous_position = position
		previous_yaw = pose.rotation[1]
	check(largest_turn_move < 0.55 and largest_turn_step < 0.03, "Sharper continuous turns stay smooth under delayed packet bursts")
	print("Turning jitter: %.3f m/frame, %.3f radians/frame" % [largest_turn_move, largest_turn_step])
	var Wire = load("res://scripts/network_wire.gd")
	var original := Vector3(31.123456, 0.712345, -29.987654)
	var rounded: Array = Wire.vector(original)
	check(motion.vec(rounded).distance_to(original) < 0.009, "Wire rounding keeps position error below one centimetre")
	check(JSON.stringify(rounded).length() < JSON.stringify([original.x, original.y, original.z]).length(), "Rounded coordinates reduce serialized network bytes")
	check(not Wire.can_queue_state(9000) and Wire.can_queue_state(0), "Slow peer skips stale states and resumes after backlog drains")
	print("MiniKarts network motion: %d checks, %d failures; largest jitter step %.3f m" % [checks, failures, largest_step])
	quit(0 if failures == 0 else 1)
