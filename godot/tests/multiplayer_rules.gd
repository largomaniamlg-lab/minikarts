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
	network.server_message(102, {"type": "join", "code": room.code, "name": "Dos", "driver": 3})
	network.server_message(103, {"type": "create", "name": "Otra sala"})
	var other: Dictionary = network.rooms[network.peers[103].room]
	await frames(10)
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
	network.remove_peer(103)
	print("MiniKarts multiplayer rules: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
