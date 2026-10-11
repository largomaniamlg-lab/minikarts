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
	print("MiniKarts network motion: %d checks, %d failures; largest jitter step %.3f m" % [checks, failures, largest_step])
	quit(0 if failures == 0 else 1)
