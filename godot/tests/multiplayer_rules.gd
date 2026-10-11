extends SceneTree

var failures := 0
var checks := 0
var network: Node

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func fake_peer(id: int) -> void:
	network.peers[id] = {"socket": WebSocketPeer.new(), "room": "", "since": 0.0, "window": 0.0, "count": 0}

func run_checks() -> void:
	network = root.get_node("Network")
	network.set_process(false)
	fake_peer(101)
	fake_peer(102)
	fake_peer(103)
	network.server_message(101, {"type": "create", "name": "Uno", "driver": 2})
	var room: Dictionary = network.rooms[network.peers[101].room]
	network.server_message(102, {"type": "join", "code": " \n" + room.code.to_lower() + " \t", "name": "Dos", "driver": 3})
	network.server_message(103, {"type": "create", "name": "Otra sala"})
	var other: Dictionary = network.rooms[network.peers[103].room]
	await frames(10)
	var directory: Array = network.room_directory()
	check(directory.size() == 2, "Directory lists waiting rooms")
	check(directory.any(func(r): return r.code == room.code and r.host == "Uno" and r.players == 2), "Directory identifies host and occupancy")
	check(network.peers[102].room == room.code, "Pasted lowercase code with whitespace joins the correct room")
	check(network.normalize_room_code(" ab cd\u00a0ef ") == "ABCDEF", "Mobile pasted nonbreaking whitespace is cleaned")
	check(room.players[101].driver == 2 and room.players[102].driver == 3, "Each racer retains their chosen driver")
	check(room.players[102].kart.get_node("Driver").face_id == 3, "Server kart uses selected face")
	check(network.room_state(room).has("neutral"), "Moving neutral position is shared with clients")
	network.server_message(102, {"type": "start"})
	check(room.phase == "lobby", "Guest cannot start")
	network.server_message(101, {"type": "start"})
	check(room.phase == "lobby", "Cannot start before all ready")
	network.server_message(101, {"type": "ready", "ready": true})
	network.server_message(102, {"type": "ready", "ready": true})
	network.server_message(101, {"type": "start"})
	check(room.phase == "countdown", "Shared countdown")
	check(not network.room_directory().any(func(r): return r.code == room.code), "Countdown rooms cannot be selected")
	check(not room.players[101].kart.enabled, "Countdown blocks driving")
	network.tick_room(room, 3.1)
	check(room.phase == "racing" and room.players[101].kart.enabled, "Countdown enables racing")
	var shooter = room.players[101].kart
	var victim = room.players[102].kart
	shooter.position = Vector3(0, 0.7, 5)
	victim.position = Vector3(0, 0.7, 0)
	victim.speed = 12.0
	var unrelated = other.players[103].kart
	unrelated.position = victim.position
	unrelated.enabled = true
	await frames(15)
	victim.speed = 12.0
	var shot = load("res://scripts/projectile.gd").new()
	shot.shooter = shooter.get_rid()
	shot.direction = Vector3.FORWARD
	room.stage.add_child(shot)
	shot.position = Vector3(victim.position.x, 0.5, victim.position.z + 3)
	await frames(10)
	check(victim.hit_time > 0, "Projectile triggers kart spin")
	check(victim.speed < 5.0, "Impact reduces speed")
	check(not is_instance_valid(shot), "Projectile consumed on kart impact")
	check(unrelated.hit_time == 0, "Separate rooms isolate physics")
	check(not victim.receive_hit(), "Protection rejects repeated hit")
	network.server_message(102, {"type": "input", "controls": {"reset": true}})
	check(victim.hit_time > 0 and victim.protection_time > 0, "Recovery does not cancel hit or shield")
	await frames(65)
	check(victim.hit_time == 0 and victim.protection_time > 0, "Spin ends before shield")
	room.players[102].prev_z = -1.0
	victim.position = Vector3(30, 0.7, 1)
	network.tick_room(room, 0.1)
	check(room.players[102].lap == 0, "Skipping checkpoints cannot finish lap")
	for id in [101, 102]:
		var player: Dictionary = room.players[id]
		player.checkpoint = 0
		player.lap = 0
		for lap in range(3):
			for point in network.CHECKPOINTS.slice(0, 3):
				player.kart.position = point + Vector3.UP * 0.7
				network.tick_room(room, 0.1)
			player.kart.position = Vector3(30, 0.7, -1)
			network.tick_room(room, 0.1)
			player.kart.position.z = 1
			network.tick_room(room, 0.1)
	network.tick_room(room, 0.1)
	check(room.phase == "results", "All finish produces results")
	check(room.results.size() == 2 and room.results[0].id == 101, "Ranking follows finish order")
	check(not victim.enabled and not shooter.enabled, "Finish disables both karts")
	network.server_message(101, {"type": "restart"})
	await frames(2)
	check(room.phase == "lobby" and room.results.is_empty(), "Host returns to lobby")
	check(room.players[101].lap == 0 and not room.players[101].ready, "Restart resets progress and readiness")
	check(room.track.get_children().filter(func(n): return n.is_in_group("obstacles")).size() == 14, "Restart restores obstacles")
	var neutral = room.track.get_node("NeutralSleeper")
	neutral.reset_path()
	var initial_neutral: Vector3 = neutral.position
	neutral._physics_process(1.0)
	check(neutral.position.distance_to(initial_neutral) > 1.0, "Neutral crosses road laterally")
	victim.reset_to(Transform3D(Basis.IDENTITY, neutral.position))
	victim.speed = 12.0
	await frames(5)
	check(victim.hit_time > 0.0 and victim.protection_time > 0.0, "Actual neutral overlap causes protected spin")
	check(victim.speed < 5.0, "Neutral impact reduces speed")
	# This point was outside the previous obstacle, but inside Jordan's larger body.
	victim.reset_to(Transform3D(Basis.IDENTITY, neutral.position + Vector3.RIGHT * 2.6))
	await frames(3)
	check(victim.hit_time > 0.0, "Enlarged Jordan contact causes spin outside the old footprint")
	room.track.reset_obstacles()
	check(neutral.elapsed == 0.0 and neutral.position.is_equal_approx(initial_neutral), "Restart restores neutral path")
	check(room.track.get_children().filter(func(n): return n.name.begins_with("LegTree")).size() == 12, "Restart preserves decorations without duplication")
	network.remove_peer(101)
	check(room.host == 102, "Host transfers after disconnect")
	network.remove_peer(102)
	check(not network.rooms.has(room.code), "Empty room released")
	check(not network.room_directory().any(func(r): return r.code == room.code), "Empty rooms disappear from directory")
	network.remove_peer(103)
	for id in range(200, 214):
		fake_peer(id)
	network.server_message(200, {"type": "create", "name": "Ten", "driver": 8})
	var large_room: Dictionary = network.rooms[network.peers[200].room]
	for id in range(201, 213):
		network.server_message(id, {"type": "join", "code": large_room.code, "driver": (id - 200) % 13})
	network.server_message(213, {"type": "join", "code": large_room.code})
	check(large_room.players.size() == 13 and network.peers[213].room == "", "Thirteen players admitted; fourteenth rejected")
	check(large_room.players[200].driver == 8, "New character survives server selection")
	check(not network.room_directory().any(func(r): return r.code == large_room.code), "Full thirteen-player room hidden")
	var spawn_positions: Array[Vector3] = []
	var safe := true
	for player in large_room.players.values():
		var position: Vector3 = player.kart.position
		safe = safe and Vector2(position.x, position.z).length() > 24 and Vector2(position.x, position.z).length() < 36
		for previous in spawn_positions:
			safe = safe and previous.distance_to(position) >= 4.0
		spawn_positions.append(position)
	check(safe, "Thirteen starting positions fit the road without overlap")
	var fastest = large_room.players[200].kart
	check(is_equal_approx(fastest.MAX_SPEED * 3.6, 65.0), "Vehicle limit is 65 km/h")
	for target in [3, 6, 9]:
		network.reset_room(large_room)
		large_room.laps = target
		large_room.phase = "racing"
		for player in large_room.players.values():
			player.kart.set_physics_process(false)
			for lap_index in range(target):
				for point in network.CHECKPOINTS.slice(0, 3):
					player.kart.position = point + Vector3.UP * 0.7
					network.tick_room(large_room, 0.01)
				player.kart.position = Vector3(30, 0.7, -1)
				network.tick_room(large_room, 0.01)
				player.kart.position.z = 1
				network.tick_room(large_room, 0.01)
				check(player.finished == (lap_index + 1 == target), "Online finish occurs at selected lap %d" % target)
		network.tick_room(large_room, 0.01)
		check(network.room_state(large_room).laps == target, "Selected laps reach all clients")
		check(large_room.phase == "results" and large_room.results.size() == 13, "Thirteen racers finish selected distance")
	check(network.Settings.valid_laps(4) == 3 and network.Settings.valid_laps("9") == 3 and network.Settings.valid_laps(9.5) == 3 and network.Settings.valid_laps(9.0) == 9, "Invalid lap input defaults safely")
	large_room.phase = "racing"
	var previous_clock: float = network.clock
	var emissions := 0
	for frame in range(60):
		network.clock = previous_clock + frame / 60.0
		if network.broadcast_room(large_room):
			emissions += 1
	check(emissions == 20, "Server emits twenty states per second without rounding away frame time")
	network.clock += 10.0
	check(network.broadcast_room(large_room) and not network.broadcast_room(large_room), "Server stall emits one latest state without catch-up burst")
	large_room.phase = "results"
	check(network.broadcast_room(large_room), "Phase transition broadcasts immediately")
	network.clock = previous_clock
	for id in range(200, 214):
		network.remove_peer(id)
	print("MiniKarts multiplayer rules: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
