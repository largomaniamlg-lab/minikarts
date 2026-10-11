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
	network.server_message(101, {"type": "create", "name": "Uno"})
	var room: Dictionary = network.rooms[network.peers[101].room]
	network.server_message(102, {"type": "join", "code": room.code, "name": "Dos"})
	network.server_message(103, {"type": "create", "name": "Otra sala"})
	var other: Dictionary = network.rooms[network.peers[103].room]
	await frames(10)
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
	network.remove_peer(101)
	check(room.host == 102, "Host transfers after disconnect")
	network.remove_peer(102)
	check(not network.rooms.has(room.code), "Empty room released")
	network.remove_peer(103)
	print("MiniKarts multiplayer rules: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
