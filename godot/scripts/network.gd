extends Node

const Wire = preload("res://scripts/network_wire.gd")
var state_packet_bytes := 0
var diagnostics_due := false
var diagnostics_clock := 0.0
var menu_snapshot_time := -INF
var menu_refresh_clock := 0.0
var previous_inputs: Dictionary = {}

const Motion = preload("res://scripts/network_motion.gd")
var motion := Motion.new()
var round_trip := 0.0
var ping_clock := -2.0
var ping_pending := -1.0
var ping_serial := 0

const Catalog = preload("res://scripts/driver_catalog.gd")
const Settings = preload("res://scripts/race_settings.gd")
const LIMIT = Settings.CAPACITY
var selected_laps := 3
var selected_bots := 3
const CHECKPOINTS := [Vector3(0, 0, 30), Vector3(-30, 0, 0), Vector3(0, 0, -30), Vector3(30, 0, 0)]
const COLORS = Settings.COLORS
var server_mode := false
var listener: TCPServer
var peers: Dictionary = {}
var rooms: Dictionary = {}
var next_id := 1
var socket: WebSocketPeer
var playing := false
var snapshot: Dictionary = {}
var player_id := 0
var room_code := ""
var status := ""
var status_until := 0.0
var connecting := false
var connection_job := 0
var clock := 0.0
var input_clock := 0.0
var pending_reset := false
var displayed_phase := ""
var browser_test := false
var selected_driver := 0
var driver_button: Button
var remote_karts: Dictionary = {}
var remote_shots: Array = []
var menu: CanvasLayer
var info: Label
var address: LineEdit
var nickname: LineEdit
var code_input: LineEdit
var start_button: Button
var ready_button: Button
var browse_controls: Control
var waiting_controls: Control
var room_list: VBoxContainer
var directory_clock := 0.0
var room_request_pending := false
var room_request_deadline := 0.0
var available_rooms: Array = []
var lobby_buttons: Dictionary = {}

func _ready() -> void:
	server_mode = "--server" in OS.get_cmdline_user_args()
	if server_mode:
		listener = TCPServer.new()
		var port := int(OS.get_environment("PORT")) if OS.has_environment("PORT") else 8080
		var error := listener.listen(port, "0.0.0.0")
		if error != OK:
			push_error("No se pudo abrir el servidor: %s" % error)
			get_tree().quit(1)
		else:
			print("MiniKarts WebSocket server listening on %d" % port)
	else:
		call_deferred("make_menu")

func send(peer: WebSocketPeer, message: Dictionary) -> void:
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		peer.send_text(JSON.stringify(message))

func _process(delta: float) -> void:
	clock += delta
	diagnostics_due = browser_test and clock >= diagnostics_clock
	if diagnostics_due:
		diagnostics_clock = clock + 0.1
	if diagnostics_due and is_instance_valid(info):
		JavaScriptBridge.eval("window.minikartsConnectionTest=" + JSON.stringify({"connecting": connecting, "message": info.text, "room": room_code}) + ";")
	if diagnostics_due and is_instance_valid(room_list):
		var buttons := {}
		for key in lobby_buttons:
			var button: Control = lobby_buttons[key]
			if is_instance_valid(button) and button.is_visible_in_tree():
				var rect := button.get_global_rect()
				buttons[key] = {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}
		JavaScriptBridge.eval("window.minikartsLobbyTest=" + JSON.stringify({"rooms": available_rooms, "joined": player_id != 0, "connected": socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN, "buttons": buttons}) + ";")
	if server_mode:
		server_tick(delta)
		return
	if is_instance_valid(browse_controls):
		for key in ["create", "refresh", "join"]:
			lobby_buttons[key].disabled = connecting or room_request_pending
	if socket == null:
		return
	socket.poll()
	var received_state := false
	while socket.get_available_packet_count() > 0:
		var packet := socket.get_packet()
		var message = JSON.parse_string(packet.get_string_from_utf8())
		if message is Dictionary:
			if message.get("type") == "welcome":
				room_request_pending = false
				status_until = 0.0
				player_id = int(message.id)
				room_code = message.code
			elif message.get("type") == "rooms":
				available_rooms = message.get("rooms", [])
				render_room_directory()
				if clock >= status_until:
					info.text = "Elige una sala y pulsa Entrar, o crea la tuya."
			elif message.get("type") == "state":
				state_packet_bytes = packet.size()
				snapshot = message
				motion.push(message, clock)
				playing = true
				received_state = true
			elif message.get("type") == "pong" and ping_pending >= 0 and message.get("stamp") == ping_serial:
				var sample := clampf(clock - ping_pending, 0.0, 2.0)
				round_trip = sample if round_trip == 0 else lerpf(round_trip, sample, 0.25)
				ping_pending = -1.0
			elif message.get("type") == "error":
				room_request_pending = false
				status = str(message.message)
				status_until = clock + 6.0
				info.text = status
	if received_state:
		show_lobby_mode(true)
	if room_request_pending and clock > room_request_deadline:
		room_request_pending = false
		info.text = "La sala no respondió. Actualiza la lista y vuelve a intentar."
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN and player_id == 0 and is_instance_valid(menu) and menu.get_node("Panel").visible and clock - directory_clock >= 3.0:
		directory_clock = clock
		send(socket, {"type": "list"})
	if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		room_request_pending = false
		if playing:
			status = "Conexión perdida. Sal de la sala para volver a jugar."
			info.text = status
			menu.get_node("Panel").show()
		return
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN and clock - ping_clock >= 2.0:
		ping_clock = clock
		ping_pending = clock
		ping_serial += 1
		send(socket, {"type": "ping", "stamp": ping_serial})
	pending_reset = pending_reset or Input.is_action_just_pressed("reset")
	input_clock += delta
	if playing and snapshot.get("phase", "") in ["countdown", "racing"] and input_clock >= 1.0 / 30.0:
		var inputs := driving_inputs()
		var changed := inputs != previous_inputs or pending_reset
		if input_clock >= 0.05 or changed:
			input_clock = 0.0
			previous_inputs = inputs.duplicate()
			inputs["reset"] = pending_reset
			pending_reset = false
			send(socket, {"type": "input", "controls": inputs})

func driving_inputs() -> Dictionary:
	var inputs := {}
	for action in ["brake", "reverse", "jump", "shoot", "steer_left", "steer_right", "handbrake"]:
		inputs[action] = Input.get_action_strength(action)
	inputs["accelerate"] = 1.0 if get_tree().current_scene.kart._focused else 0.0
	if not get_tree().current_scene.kart._focused:
		inputs["brake"] = 1.0
	return inputs

func server_tick(delta: float) -> void:
	while listener.is_connection_available():
		var stream := listener.take_connection()
		if peers.size() >= 60:
			stream.disconnect_from_host()
			continue
		var peer := WebSocketPeer.new()
		peer.inbound_buffer_size = 16384
		peer.outbound_buffer_size = 262144
		peer.max_queued_packets = 32
		if peer.accept_stream(stream) == OK:
			peers[next_id] = {"socket": peer, "room": "", "since": clock, "window": clock, "count": 0}
			next_id += 1
	for id in peers.keys():
		var connection: Dictionary = peers[id]
		var peer: WebSocketPeer = connection.socket
		peer.poll()
		if peer.get_ready_state() == WebSocketPeer.STATE_CLOSED or (connection.room == "" and clock - connection.since > 10.0):
			remove_peer(id)
			continue
		while peer.get_available_packet_count() > 0:
			var packet := peer.get_packet()
			if packet.size() > 4096:
				peer.close(1009, "Mensaje demasiado grande")
				break
			if clock - connection.window >= 1.0:
				connection.window = clock
				connection.count = 0
			connection.count += 1
			if connection.count > 60:
				peer.close(1008, "Demasiados mensajes")
				break
			var message = JSON.parse_string(packet.get_string_from_utf8())
			if message is Dictionary:
				server_message(id, message)
	for room in rooms.values():
		tick_room(room, delta)
	for room in rooms.values():
		broadcast_room(room)

func broadcast_room(room: Dictionary) -> bool:
	var interval := 0.20 if room.phase == "lobby" or room.phase == "results" else 0.05
	var due := float(room.get("next_broadcast", clock))
	if room.get("broadcast_phase", "") != room.phase:
		due = clock
	if clock + 0.001 < due:
		return false
	# Keep the scheduled cadence rather than losing fractional frame time.
	# After a stall send only the latest state, never a burst of catch-up states.
	if clock - due >= interval:
		due = clock
	room.next_broadcast = due + interval
	room.broadcast_phase = room.phase
	var payload := JSON.stringify(room_state(room))
	for id in room.players:
		if peers.has(id):
			var peer: WebSocketPeer = peers[id].socket
			if peer.get_ready_state() == WebSocketPeer.STATE_OPEN and Wire.can_queue_state(peer.get_current_outbound_buffered_amount()):
				peer.send_text(payload)
	return true

func reject(id: int, message: String) -> void:
	send(peers[id].socket, {"type": "error", "message": message})

func room_directory() -> Array:
	var directory := []
	for room in rooms.values():
		if room.phase != "lobby" or room.players.size() >= LIMIT or room.players.is_empty():
			continue
		var host: Dictionary = room.players[room.host]
		directory.append({"code": room.code, "host": str(host.name).replace("\n", " ").replace("\r", " "), "players": room.players.size(), "capacity": LIMIT, "laps": room.laps})
	directory.sort_custom(func(a: Dictionary, b: Dictionary): return str(a.code) < str(b.code))
	return directory

func server_message(id: int, message: Dictionary) -> void:
	var connection: Dictionary = peers[id]
	var kind := str(message.get("type", ""))
	if kind == "ping":
		send(connection.socket, {"type": "pong", "stamp": message.get("stamp", 0)})
		return
	if kind == "list" and connection.room == "":
		connection.since = clock
		send(connection.socket, {"type": "rooms", "rooms": room_directory()})
		return
	if kind == "create" or kind == "join":
		if connection.room != "":
			reject(id, "Ya estás en una sala.")
			return
		var code := normalize_room_code(str(message.get("code", "")))
		if kind == "create":
			if rooms.size() >= 4:
				reject(id, "Servidor lleno. Inténtalo más tarde.")
				return
			code = new_code()
			var world := SubViewport.new()
			world.own_world_3d = true
			world.size = Vector2i(1, 1)
			world.render_target_update_mode = SubViewport.UPDATE_DISABLED
			add_child(world)
			var stage := Node3D.new()
			world.add_child(stage)
			var track = preload("res://scenes/track.tscn").instantiate()
			stage.add_child(track)
			rooms[code] = {"code": code, "host": id, "world": world, "stage": stage, "track": track, "players": {}, "phase": "lobby", "timer": 0.0, "elapsed": 0.0, "results": [], "first_finish": -1.0, "laps": Settings.valid_laps(message.get("laps", 3))}
		if not rooms.has(code):
			reject(id, "No existe esa sala. Comprueba el código; el creador debe mantener el juego abierto.")
			return
		var room: Dictionary = rooms[code]
		if room.phase != "lobby":
			reject(id, "La carrera ya ha empezado. Espera a que el creador vuelva a la sala.")
			return
		if room.players.size() >= LIMIT:
			reject(id, "Sala llena: ya hay dieciséis jugadores.")
			return
		var kart = preload("res://scenes/kart.tscn").instantiate()
		kart.network_controlled = true
		var grid_slot := 0
		var occupied: Array = room.players.values().map(func(p): return p.grid_slot)
		while grid_slot in occupied:
			grid_slot += 1
		kart.kart_color = COLORS[grid_slot]
		kart.transform = Settings.grid_transform(grid_slot)
		room.stage.add_child(kart)
		kart.enabled = false
		var name_text := str(message.get("name", "Piloto")).strip_edges().left(20)
		if name_text == "":
			name_text = "Piloto"
		var requested_driver = message.get("driver", 0)
		var driver_id := clampi(int(requested_driver), 0, Catalog.NAMES.size() - 1) if (requested_driver is int or requested_driver is float) and is_finite(float(requested_driver)) else 0
		kart.get_node("Driver").set_face(driver_id)
		room.players[id] = {"grid_slot": grid_slot, "kart": kart, "name": name_text, "driver": driver_id, "ready": false, "lap": 0, "checkpoint": 0, "prev_z": -3.0, "input_time": clock, "finished": false, "spawn": kart.transform}
		connection.room = code
		send(connection.socket, {"type": "welcome", "id": id, "code": code})
		return
	if not rooms.has(connection.room):
		return
	var room: Dictionary = rooms[connection.room]
	var player: Dictionary = room.players[id]
	if kind == "ready" and room.phase == "lobby":
		player.ready = message.get("ready", false) == true
	elif kind == "start" or kind == "restart":
		if id != room.host:
			reject(id, "Solo el creador puede iniciar la carrera.")
			return
		if kind == "restart" and room.phase == "results":
			reset_room(room)
		elif room.phase == "lobby" and room.players.size() < 2:
			reject(id, "Se necesitan al menos dos pilotos.")
		elif room.phase == "lobby" and room.players.size() >= 2:
			for participant in room.players.values():
				if not participant.ready:
					reject(id, "Todos deben marcar Listo.")
					return
			room.phase = "countdown"
			room.timer = 3.0
	elif kind == "input" and message.get("controls") is Dictionary:
		var controls := {}
		for action in ["accelerate", "brake", "reverse", "jump", "shoot", "steer_left", "steer_right", "handbrake"]:
			var value = message.controls.get(action, 0.0)
			controls[action] = clampf(float(value), 0, 1) if (value is float or value is int) and is_finite(float(value)) else 0.0
		player.kart.controls = controls
		player.input_time = clock
		if message.controls.get("reset", false) == true and room.phase == "racing" and not player.finished:
			var shield: float = player.kart.protection_time
			var stun: float = player.kart.hit_time
			player.kart.reset_to(player.kart.spawn_transform)
			player.kart.protection_time = shield
			player.kart.hit_time = stun
			player.prev_z = player.kart.position.z

func new_code() -> String:
	var alphabet := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	while true:
		var code := ""
		for i in range(6):
			code += alphabet[randi() % alphabet.length()]
		if not rooms.has(code):
			return code
	return ""

func remove_peer(id: int) -> void:
	var connection: Dictionary = peers[id]
	connection.socket.close()
	if rooms.has(connection.room):
		var room: Dictionary = rooms[connection.room]
		if room.players.has(id):
			if room.phase == "racing" and not room.players[id].finished:
				room.results.append({"id": id, "name": room.players[id].name, "time": -1})
			room.players[id].kart.queue_free()
			room.players.erase(id)
		if room.players.is_empty():
			room.world.queue_free()
			rooms.erase(connection.room)
		else:
			if room.host == id:
				room.host = room.players.keys()[0]
			if room.phase == "countdown" and room.players.size() < 2:
				reset_room(room)
	peers.erase(id)

func reset_room(room: Dictionary) -> void:
	room.phase = "lobby"
	room.results = []
	room.elapsed = 0.0
	room.first_finish = -1.0
	for child in room.stage.get_children():
		if child.is_in_group("projectiles"):
			child.queue_free()
	room.track.reset_obstacles()
	for player in room.players.values():
		player.kart.reset_to(player.spawn)
		player.kart.spawn_transform = player.spawn
		player.kart.enabled = false
		player.kart.controls = {}
		player.ready = false
		player.lap = 0
		player.checkpoint = 0
		player.prev_z = -3.0
		player.finished = false

func tick_room(room: Dictionary, delta: float) -> void:
	if room.phase == "countdown":
		room.timer -= delta
		if room.timer <= 0:
			room.phase = "racing"
			for player in room.players.values():
				player.kart.enabled = true
	if room.phase != "racing":
		return
	room.elapsed += delta
	var all_finished := true
	for id in room.players:
		var player: Dictionary = room.players[id]
		var kart = player.kart
		if player.finished:
			continue
		all_finished = false
		if clock - player.input_time > 1.5:
			kart.controls = {"brake": 1.0}
		if kart.position.y < -4.0:
			kart.reset_to(kart.spawn_transform)
			player.prev_z = kart.position.z
		var crossed: bool = player.prev_z < 0 and kart.position.z >= 0 and kart.position.x > 21 and kart.position.x < 39
		var point: Vector3 = CHECKPOINTS[player.checkpoint]
		var flat := Vector3(kart.position.x, 0, kart.position.z)
		if (flat.distance_to(point) < 11.0 if player.checkpoint < 3 else crossed):
			kart.spawn_transform = Transform3D(Basis.looking_at(Vector3(-point.z, 0, point.x).normalized()), point + Vector3.UP * 0.7)
			player.checkpoint += 1
			if player.checkpoint == 4:
				player.checkpoint = 0
				player.lap += 1
				if player.lap == room.laps:
					player.finished = true
					kart.enabled = false
					room.results.append({"id": id, "name": player.name, "time": room.elapsed})
					if room.first_finish < 0:
						room.first_finish = room.elapsed
		player.prev_z = kart.position.z
	if all_finished or room.elapsed >= 600 or (room.first_finish >= 0 and room.elapsed - room.first_finish >= 60):
		room.phase = "results"
		for id in room.players:
			var player: Dictionary = room.players[id]
			player.kart.enabled = false
			if not player.finished:
				room.results.append({"id": id, "name": player.name, "time": -1})

func vector(v: Vector3) -> Array:
	return Wire.vector(v)

func room_state(room: Dictionary) -> Dictionary:
	room.results.sort_custom(func(a, b): return a.time >= 0 and (b.time < 0 or a.time < b.time))
	var racers := []
	for id in room.players:
		var player: Dictionary = room.players[id]
		var kart = player.kart
		racers.append({"id": id, "name": player.name, "driver": player.driver, "ready": player.ready, "position": vector(kart.position), "velocity": vector(kart.velocity), "rotation": Wire.vector(kart.rotation, 0.001), "speed": Wire.number(kart.speed), "steering": Wire.number(kart._steering, 0.001), "hit": Wire.number(kart.hit_time), "protection": Wire.number(kart.protection_time), "lap": player.lap, "finished": player.finished, "color": kart.kart_color.to_html()})
	var shots := []
	for child in room.stage.get_children():
		if child.is_in_group("projectiles"):
			shots.append(vector(child.position))
	var boxes := []
	for child in room.track.get_children():
		if child.is_in_group("destructible"):
			boxes.append(vector(child.position))
	return {"type": "state", "time": Wire.number(clock, 0.001), "code": room.code, "host": room.host, "phase": room.phase, "laps": room.laps, "countdown": maxi(0, ceili(room.timer)), "elapsed": Wire.number(room.elapsed, 0.001), "players": racers, "shots": shots, "boxes": boxes, "neutral": vector(room.track.get_node("NeutralSleeper").position), "results": room.results}

func as_vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

func update_game(game: Node3D, delta: float) -> void:
	if snapshot.is_empty():
		return
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		game.kart.set_physics_process(false)
		menu.get_node("Panel").show()
		info.text = "Conexión perdida. Sal de la sala para reintentar."
		return
	if displayed_phase == "":
		for child in game.get_children():
			if child.is_in_group("projectiles"):
				child.queue_free()
	if snapshot.phase == "lobby" and displayed_phase == "results":
		game.get_node("Track").reset_obstacles()
	game.kart.set_physics_process(false)
	if snapshot.has("neutral"):
		game.get_node("Track/NeutralSleeper").position = as_vector(snapshot.neutral)
	var active_ids := []
	for racer in snapshot.players:
		var id := int(racer.id)
		active_ids.append(id)
		var kart = game.kart if id == player_id else remote_karts.get(id)
		if kart == null:
			kart = preload("res://scenes/kart.tscn").instantiate()
			kart.kart_color = Color(racer.color)
			game.add_child(kart)
			kart.set_physics_process(false)
			kart._camera.queue_free()
			remote_karts[id] = kart
			var tag := Label3D.new()
			tag.text = racer.name
			tag.position.y = 1.85
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			kart.add_child(tag)
		var visual: Dictionary = racer
		if snapshot.phase == "racing" and not racer.finished:
			if id == player_id:
				visual = motion.local(racer, clock, delta, driving_inputs(), round_trip)
			else:
				var buffered := motion.remote(id, clock)
				if not buffered.is_empty():
					visual = buffered
		var position := as_vector(visual.position)
		kart.position = position if id == player_id or kart.position.distance_to(position) > 6 else kart.position.lerp(position, 1.0 - exp(-20 * delta))
		var rotation := as_vector(visual.rotation)
		kart.rotation.y = rotation.y if id == player_id else lerp_angle(kart.rotation.y, rotation.y, 1.0 - exp(-20 * delta))
		kart._body_visual.material_override.albedo_color = Color(racer.color)
		kart.get_node("Driver").set_face(int(racer.get("driver", 0)))
		kart.speed = visual.speed
		kart._steering = visual.steering
		if id == player_id:
			game.hud.update_display(mini(int(racer.lap) + 1, int(snapshot.get("laps", 3))), snapshot.elapsed, INF, absf(racer.speed) * 3.6, racer.finished, snapshot.phase == "racing", false, int(snapshot.get("laps", 3)))
			if racer.hit > 0:
				game.hud._message_panel.show()
				game.hud.message.text = "¡Trompo! Protección temporal."
	for id in remote_karts.keys():
		if id not in active_ids:
			remote_karts[id].queue_free()
			remote_karts.erase(id)
	# Rendering must not let a rival take over the local follow camera.
	game.kart._camera.current = true
	while remote_shots.size() > snapshot.shots.size():
		remote_shots.pop_back().queue_free()
	while remote_shots.size() < snapshot.shots.size():
		var shot = preload("res://scripts/projectile.gd").new()
		game.add_child(shot)
		shot.set_physics_process(false)
		remote_shots.append(shot)
	for i in range(remote_shots.size()):
		remote_shots[i].position = as_vector(snapshot.shots[i])
	for child in game.get_node("Track").get_children():
		if child.has_method("hit") and child.is_in_group("destructible"):
			var exists := false
			for position in snapshot.boxes:
				if child.position.distance_to(as_vector(position)) < 0.1:
					exists = true
			if not exists:
				child.hit()
	if float(snapshot.time) != menu_snapshot_time or clock >= menu_refresh_clock:
		update_menu()
		menu_snapshot_time = float(snapshot.time)
		menu_refresh_clock = clock + 0.5
	if diagnostics_due:
		JavaScriptBridge.eval("window.minikartsTest = " + JSON.stringify({"state": snapshot, "rendered_karts": 1 + remote_karts.size(), "rtt_ms": round_trip * 1000, "snapshot_age_ms": (clock - motion.received_at) * 1000, "jitter_ms": motion.jitter * 1000, "buffer_ms": motion.buffer_seconds * 1000, "state_bytes": state_packet_bytes, "fps": Engine.get_frames_per_second(), "local_position": vector(game.kart.position), "local_rotation": vector(game.kart.rotation)}) + ";")

func make_menu() -> void:
	if OS.has_feature("web"):
		browser_test = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('test') || ''")) == "1"
	menu = CanvasLayer.new()
	menu.layer = 10
	add_child(menu)
	var toggle := Button.new()
	toggle.text = "Amigos"
	toggle.position = Vector2(500, 70)
	toggle.pressed.connect(func():
		menu.get_node("Panel").visible = not menu.get_node("Panel").visible
		if not playing and is_instance_valid(get_tree().current_scene):
			var game = get_tree().current_scene
			if menu.get_node("Panel").visible and game.has_method("prepare_online"):
				game.prepare_online()
			else:
				game.kart.enabled = not menu.get_node("Panel").visible
	)
	menu.add_child(toggle)
	if "--solo-preview" in OS.get_cmdline_user_args():
		toggle.hide()
	driver_button = Button.new()
	driver_button.position = Vector2(500, 120)
	driver_button.text = "Menú · piloto"
	driver_button.custom_minimum_size = Vector2(150, 44)
	driver_button.add_theme_font_size_override("font_size", 22)
	driver_button.pressed.connect(func():
		if playing:
			return
		if is_instance_valid(get_tree().current_scene) and get_tree().current_scene.get("race_menu") != null:
			get_tree().current_scene.race_menu.open()
			return
		selected_driver = (selected_driver + 1) % Catalog.NAMES.size()
		driver_button.text = "Menú · piloto"
		if is_instance_valid(get_tree().current_scene):
			get_tree().current_scene.kart.get_node("Driver").set_face(selected_driver)
	)
	menu.add_child(driver_button)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(280, 135)
	panel.size = Vector2(720, 530)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.12, 0.16, 0.97)
	background.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", background)
	menu.add_child(panel)
	info = Label.new()
	info.position = Vector2(20, 16)
	info.size = Vector2(680, 66)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 21)
	info.text = "Salas online · hasta dieciséis pilotos"
	panel.add_child(info)
	address = LineEdit.new()
	address.text = OS.get_environment("MULTIPLAYER_SERVER_URL")
	if OS.has_feature("web"):
		address.text = str(JavaScriptBridge.eval("window.MINIKARTS_SERVER_URL || new URLSearchParams(location.search).get('server') || ''"))
	panel.add_child(address)
	address.hide()
	browse_controls = Control.new()
	browse_controls.position = Vector2(0, 95)
	panel.add_child(browse_controls)
	var name_label := Label.new()
	name_label.text = "Tu nombre"
	name_label.position = Vector2(20, 12)
	name_label.add_theme_font_size_override("font_size", 20)
	browse_controls.add_child(name_label)
	nickname = LineEdit.new()
	nickname.text = "Piloto"
	nickname.position = Vector2(145, 0)
	nickname.size = Vector2(230, 48)
	nickname.add_theme_font_size_override("font_size", 22)
	browse_controls.add_child(nickname)
	lobby_buttons.name = nickname
	lobby_button(browse_controls, "Crear sala", "create", Vector2(395, 0), Vector2(300, 48)).pressed.connect(connect_room.bind(true))
	lobby_button(browse_controls, "Actualizar salas", "refresh", Vector2(20, 65), Vector2(330, 48)).pressed.connect(refresh_rooms)
	var manual := Control.new()
	manual.position = Vector2(0, 300)
	browse_controls.add_child(manual)
	manual.hide()
	lobby_button(browse_controls, "Tengo un código", "manual", Vector2(365, 65), Vector2(330, 48)).pressed.connect(func(): manual.visible = not manual.visible)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 125)
	scroll.size = Vector2(680, 160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	browse_controls.add_child(scroll)
	room_list = VBoxContainer.new()
	room_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_list.add_theme_constant_override("separation", 8)
	scroll.add_child(room_list)
	code_input = LineEdit.new()
	code_input.placeholder_text = "Código de sala (opcional)"
	code_input.position = Vector2(20, 0)
	code_input.size = Vector2(430, 48)
	code_input.add_theme_font_size_override("font_size", 22)
	code_input.max_length = 64
	code_input.text_changed.connect(func(value: String):
		var clean := normalize_room_code(value)
		if clean != value:
			code_input.text = clean
			code_input.caret_column = clean.length()
	)
	manual.add_child(code_input)
	lobby_buttons.code = code_input
	lobby_button(manual, "Unirse", "join", Vector2(465, 0), Vector2(230, 48)).pressed.connect(connect_room.bind(false))
	if OS.has_feature("web"):
		code_input.text = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('room') || ''"))
		manual.visible = not code_input.text.is_empty()
	waiting_controls = Control.new()
	waiting_controls.position = Vector2(0, 275)
	panel.add_child(waiting_controls)
	ready_button = lobby_button(waiting_controls, "Listo", "ready", Vector2(20, 0), Vector2(680, 48))
	ready_button.pressed.connect(func(): send(socket, {"type": "ready", "ready": true}) if socket != null else null)
	start_button = lobby_button(waiting_controls, "Iniciar carrera", "start", Vector2(20, 65), Vector2(680, 48))
	start_button.pressed.connect(func(): send(socket, {"type": "restart" if snapshot.get("phase") == "results" else "start"}) if socket != null else null)
	lobby_button(panel, "Salir / volver al juego", "leave", Vector2(20, 465), Vector2(680, 48)).pressed.connect(leave_room)
	show_lobby_mode(false)
	render_room_directory()
	panel.hide()
	panel.visibility_changed.connect(func():
		if panel.visible and not playing:
			show_lobby_mode(false)
			refresh_rooms()
	)

func lobby_button(parent: Node, text: String, key: String, position: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 22)
	parent.add_child(button)
	lobby_buttons[key] = button
	return button

func show_lobby_mode(joined: bool) -> void:
	if not is_instance_valid(browse_controls):
		return
	browse_controls.visible = not joined
	waiting_controls.visible = joined
	info.size.y = 240 if joined else 66

func render_room_directory() -> void:
	for key in lobby_buttons.keys():
		if str(key).begins_with("room_"):
			lobby_buttons.erase(key)
	for child in room_list.get_children():
		room_list.remove_child(child)
		child.queue_free()
	if available_rooms.is_empty():
		var label := Label.new()
		label.text = "No hay salas disponibles. Crea una y tus amigos la verán aquí."
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = 650
		label.add_theme_font_size_override("font_size", 20)
		room_list.add_child(label)
	for room in available_rooms:
		var button := Button.new()
		button.text = "Entrar · %s · %d/%d · %d vueltas" % [room.host, room.players, room.capacity, room.get("laps", 3)]
		button.custom_minimum_size = Vector2(650, 52)
		button.add_theme_font_size_override("font_size", 22)
		room_list.add_child(button)
		lobby_buttons["room_" + str(room.code)] = button
		button.pressed.connect(func():
			code_input.text = str(room.code)
			connect_room(false)
		)

func refresh_rooms() -> void:
	request_connection("list")

func normalize_room_code(value: String) -> String:
	var clean := value.to_upper()
	for whitespace in [" ", "\t", "\n", "\r", "\u00a0"]:
		clean = clean.replace(whitespace, "")
	return clean

func connect_room(create: bool) -> void:
	request_connection("create" if create else "join")

func request_connection(kind: String) -> void:
	if connecting or room_request_pending:
		return
	if kind == "join":
		code_input.text = normalize_room_code(code_input.text)
		if code_input.text.length() != 6:
			info.text = "Introduce el código de seis caracteres de tu amigo."
			return
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_CLOSED and not playing:
		socket = null
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN and player_id == 0:
		send_lobby_request(kind)
		return
	if socket != null:
		info.text = "Sal de la sala antes de conectar a otra."
		return
	var url := address.text.strip_edges()
	if not (url.begins_with("wss://") or url.begins_with("ws://")):
		info.text = "No hay servidor configurado. Abre el enlace actualizado del juego."
		return
	if OS.has_feature("web") and not url.begins_with("wss://") and not ("127.0.0.1" in url or "localhost" in url):
		info.text = "La web necesita un servidor seguro wss://."
		return
	connecting = true
	connection_job += 1
	var job := connection_job
	var started_at := Time.get_ticks_msec()
	for attempt in range(3):
		if job != connection_job:
			return
		var peer := WebSocketPeer.new()
		# Bound queued snapshots while allowing brief slow frames on mobile.
		peer.inbound_buffer_size = 524288
		peer.outbound_buffer_size = 65536
		peer.max_queued_packets = 128
		socket = peer
		var error := peer.connect_to_url(url)
		var deadline := Time.get_ticks_msec() + 40000
		while error == OK and peer.get_ready_state() == WebSocketPeer.STATE_CONNECTING and Time.get_ticks_msec() < deadline:
			if job != connection_job:
				peer.close()
				return
			info.text = "Conectando al servidor · intento %d/3 · %d s\nEl servidor gratuito puede tardar en despertar." % [attempt + 1, (Time.get_ticks_msec() - started_at) / 1000]
			await get_tree().process_frame
		if job != connection_job:
			peer.close()
			return
		if error == OK and peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			connecting = false
			info.text = "Servidor conectado. Entrando en la sala…"
			send_lobby_request(kind)
			return
		peer.close()
		socket = null
		if attempt < 2:
			info.text = "El servidor aún no responde. Reintentando automáticamente…"
			await get_tree().create_timer(3.0).timeout
	if job != connection_job:
		return
	connecting = false
	info.text = "No se pudo conectar tras tres intentos.\nPulsa Crear sala o Unirse para reintentar."

func send_lobby_request(kind: String) -> void:
	directory_clock = clock
	if kind != "list":
		room_request_pending = true
		room_request_deadline = clock + 10.0
	send(socket, {"type": kind, "code": normalize_room_code(code_input.text), "name": nickname.text, "driver": selected_driver, "laps": selected_laps})

func update_menu() -> void:
	driver_button.disabled = playing
	var lines := ["Sala %s · %d/%d · %d vueltas" % [room_code, snapshot.players.size(), LIMIT, snapshot.get("laps", 3)]]
	for index in range(0, snapshot.players.size(), 2):
		var row: Array[String] = []
		for racer in snapshot.players.slice(index, index + 2):
			row.append("%s · %s" % [racer.name, "Listo" if racer.ready else "Esperando"])
		lines.append("    |    ".join(row))
	info.add_theme_font_size_override("font_size", 16 if snapshot.phase == "results" else 17)
	if snapshot.phase == "countdown":
		lines.append("Salida en %d…" % snapshot.countdown)
	elif snapshot.phase == "racing" and displayed_phase != "racing":
		menu.get_node("Panel").hide()
	elif snapshot.phase == "results":
		lines = ["Clasificación · Sala " + room_code]
		for i in range(snapshot.results.size()):
			var result: Dictionary = snapshot.results[i]
			lines.append("%d. %s · %s" % [i + 1, result.name, "%.2f s" % result.time if result.time >= 0 else "Sin terminar"])
		menu.get_node("Panel").show()
	if clock < status_until:
		lines.append(status)
	info.text = "\n".join(lines)
	start_button.disabled = int(snapshot.host) != player_id
	start_button.text = "Volver a la sala" if snapshot.phase == "results" else "Iniciar carrera"
	ready_button.disabled = snapshot.phase != "lobby"
	displayed_phase = snapshot.phase

func leave_room() -> void:
	room_request_pending = false
	available_rooms.clear()
	connection_job += 1
	connecting = false
	if socket != null:
		socket.close()
	socket = null
	playing = false
	snapshot.clear()
	motion.clear()
	previous_inputs.clear()
	menu_snapshot_time = -INF
	round_trip = 0.0
	ping_pending = -1.0
	ping_clock = -2.0
	displayed_phase = ""
	room_code = ""
	player_id = 0
	driver_button.disabled = false
	menu.get_node("Panel").hide()
	remote_karts.clear()
	remote_shots.clear()
	get_tree().reload_current_scene()
	info.text = "Carrera privada · hasta 16 pilotos"
