extends Node

const LIMIT := 4
const CHECKPOINTS := [Vector3(0, 0, 30), Vector3(-30, 0, 0), Vector3(0, 0, -30), Vector3(30, 0, 0)]
const COLORS := [Color("ee3814"), Color("397cdc"), Color("51ba66"), Color("b464d5")]
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
var clock := 0.0
var send_clock := 0.0
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
	if server_mode:
		server_tick(delta)
		return
	if socket == null:
		return
	socket.poll()
	while socket.get_available_packet_count() > 0:
		var message = JSON.parse_string(socket.get_packet().get_string_from_utf8())
		if message is Dictionary:
			if message.get("type") == "welcome":
				player_id = int(message.id)
				room_code = message.code
			elif message.get("type") == "state":
				snapshot = message
				playing = true
			elif message.get("type") == "error":
				status = str(message.message)
				info.text = status
	if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		if playing:
			status = "Conexión perdida. Sal de la sala para volver a jugar."
			info.text = status
			menu.get_node("Panel").show()
		return
	pending_reset = pending_reset or Input.is_action_just_pressed("reset")
	input_clock += delta
	if playing and input_clock >= 0.05:
		input_clock = 0.0
		var inputs := {}
		for action in ["brake", "reverse", "jump", "shoot", "steer_left", "steer_right", "handbrake"]:
			inputs[action] = Input.get_action_strength(action)
		inputs["accelerate"] = 1.0 if get_tree().current_scene.kart._focused else 0.0
		if not get_tree().current_scene.kart._focused:
			inputs["brake"] = 1.0
		inputs["reset"] = pending_reset
		pending_reset = false
		send(socket, {"type": "input", "controls": inputs})

func server_tick(delta: float) -> void:
	while listener.is_connection_available():
		var stream := listener.take_connection()
		if peers.size() >= 16:
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
	send_clock += delta
	if send_clock >= 0.05:
		send_clock = 0.0
		for room in rooms.values():
			var state := room_state(room)
			for id in room.players:
				if peers.has(id):
					send(peers[id].socket, state)

func reject(id: int, message: String) -> void:
	send(peers[id].socket, {"type": "error", "message": message})

func server_message(id: int, message: Dictionary) -> void:
	var connection: Dictionary = peers[id]
	var kind := str(message.get("type", ""))
	if kind == "create" or kind == "join":
		if connection.room != "":
			reject(id, "Ya estás en una sala.")
			return
		var code := str(message.get("code", "")).to_upper()
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
			rooms[code] = {"code": code, "host": id, "world": world, "stage": stage, "track": track, "players": {}, "phase": "lobby", "timer": 0.0, "elapsed": 0.0, "results": [], "first_finish": -1.0}
		if not rooms.has(code):
			reject(id, "No existe esa sala.")
			return
		var room: Dictionary = rooms[code]
		if room.phase != "lobby" or room.players.size() >= LIMIT:
			reject(id, "Sala llena o carrera en marcha.")
			return
		var kart = preload("res://scenes/kart.tscn").instantiate()
		kart.network_controlled = true
		kart.kart_color = COLORS[room.players.size()]
		kart.position = Vector3(25 + room.players.size() * 3, 0.7, -3)
		room.stage.add_child(kart)
		kart.enabled = false
		var name_text := str(message.get("name", "Piloto")).strip_edges().left(20)
		if name_text == "":
			name_text = "Piloto"
		var requested_driver = message.get("driver", 0)
		var driver_id := clampi(int(requested_driver), 0, 3) if (requested_driver is int or requested_driver is float) and is_finite(float(requested_driver)) else 0
		kart.get_node("Driver").set_face(driver_id)
		room.players[id] = {"kart": kart, "name": name_text, "driver": driver_id, "ready": false, "lap": 0, "checkpoint": 0, "prev_z": -3.0, "input_time": clock, "finished": false, "spawn": kart.transform}
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
				if player.lap == 3:
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
	return [v.x, v.y, v.z]

func room_state(room: Dictionary) -> Dictionary:
	room.results.sort_custom(func(a, b): return a.time >= 0 and (b.time < 0 or a.time < b.time))
	var racers := []
	for id in room.players:
		var player: Dictionary = room.players[id]
		var kart = player.kart
		racers.append({"id": id, "name": player.name, "driver": player.driver, "ready": player.ready, "position": vector(kart.position), "rotation": vector(kart.rotation), "speed": kart.speed, "steering": kart._steering, "hit": kart.hit_time, "protection": kart.protection_time, "lap": player.lap, "finished": player.finished, "color": kart.kart_color.to_html()})
	var shots := []
	for child in room.stage.get_children():
		if child.is_in_group("projectiles"):
			shots.append(vector(child.position))
	var boxes := []
	for child in room.track.get_children():
		if child.is_in_group("destructible"):
			boxes.append(vector(child.position))
	return {"type": "state", "code": room.code, "host": room.host, "phase": room.phase, "countdown": maxi(0, ceili(room.timer)), "elapsed": room.elapsed, "players": racers, "shots": shots, "boxes": boxes, "neutral": vector(room.track.get_node("NeutralSleeper").position), "results": room.results}

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
		var position := as_vector(racer.position)
		kart.position = position if kart.position.distance_to(position) > 6 else kart.position.lerp(position, 1.0 - exp(-20 * delta))
		var rotation := as_vector(racer.rotation)
		kart.rotation.y = lerp_angle(kart.rotation.y, rotation.y, 1.0 - exp(-20 * delta))
		kart._body_visual.material_override.albedo_color = Color(racer.color)
		kart.get_node("Driver").set_face(int(racer.get("driver", 0)))
		kart.speed = racer.speed
		kart._steering = racer.steering
		if id == player_id:
			game.hud.update_display(mini(int(racer.lap) + 1, 3), snapshot.elapsed, INF, absf(racer.speed) * 3.6, racer.finished, snapshot.phase == "racing", false)
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
	update_menu()
	if browser_test:
		JavaScriptBridge.eval("window.minikartsTest = " + JSON.stringify({"state": snapshot, "rendered_karts": 1 + remote_karts.size()}) + ";")

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
			get_tree().current_scene.kart.enabled = not menu.get_node("Panel").visible
	)
	menu.add_child(toggle)
	if "--solo-preview" in OS.get_cmdline_user_args():
		toggle.hide()
	driver_button = Button.new()
	driver_button.position = Vector2(500, 120)
	driver_button.text = "Piloto %d/4" % (selected_driver + 1)
	driver_button.custom_minimum_size = Vector2(150, 44)
	driver_button.add_theme_font_size_override("font_size", 22)
	driver_button.pressed.connect(func():
		if playing:
			return
		selected_driver = (selected_driver + 1) % 4
		driver_button.text = "Piloto %d/4" % (selected_driver + 1)
		get_tree().current_scene.kart.get_node("Driver").set_face(selected_driver)
	)
	menu.add_child(driver_button)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.position = Vector2(320, 150)
	panel.custom_minimum_size = Vector2(640, 380)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.08, 0.12, 0.16, 0.97)
	background.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", background)
	menu.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	info = Label.new()
	info.text = "Carrera privada · hasta 4 pilotos"
	column.add_child(info)
	address = LineEdit.new()
	address.placeholder_text = "Dirección de conexión (solo configuración inicial)"
	address.text = OS.get_environment("MULTIPLAYER_SERVER_URL")
	if OS.has_feature("web"):
		address.text = str(JavaScriptBridge.eval("window.MINIKARTS_SERVER_URL || new URLSearchParams(location.search).get('server') || ''"))
	address.visible = address.text == ""
	column.add_child(address)
	nickname = LineEdit.new()
	nickname.placeholder_text = "Tu nombre"
	nickname.text = "Piloto"
	column.add_child(nickname)
	code_input = LineEdit.new()
	code_input.placeholder_text = "Código de sala (para unirse)"
	code_input.max_length = 6
	if OS.has_feature("web"):
		code_input.text = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('room') || ''"))
	column.add_child(code_input)
	var row := HBoxContainer.new()
	column.add_child(row)
	for label in ["Crear sala", "Unirse"]:
		var button := Button.new()
		button.text = label
		button.pressed.connect(connect_room.bind(label == "Crear sala"))
		row.add_child(button)
	ready_button = Button.new()
	ready_button.text = "Listo"
	ready_button.pressed.connect(func(): send(socket, {"type": "ready", "ready": true}) if socket != null else null)
	column.add_child(ready_button)
	start_button = Button.new()
	start_button.text = "Iniciar carrera"
	start_button.pressed.connect(func(): send(socket, {"type": "restart" if snapshot.get("phase") == "results" else "start"}) if socket != null else null)
	column.add_child(start_button)
	var leave := Button.new()
	leave.text = "Salir de la sala / jugar solo"
	leave.pressed.connect(leave_room)
	column.add_child(leave)
	for child in column.get_children():
		if child is LineEdit or child is Button:
			child.custom_minimum_size.y = 44
			child.add_theme_font_size_override("font_size", 22)
	for child in row.get_children():
		child.custom_minimum_size.y = 44
		child.add_theme_font_size_override("font_size", 22)
	panel.hide()

func connect_room(create: bool) -> void:
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN and player_id == 0:
		send(socket, {"type": "create" if create else "join", "code": code_input.text.to_upper(), "name": nickname.text, "driver": selected_driver})
		return
	if socket != null:
		info.text = "Sal de la sala antes de conectar a otra."
		return
	var url := address.text.strip_edges()
	if not (url.begins_with("wss://") or url.begins_with("ws://")):
		info.text = "Indica el servidor de la partida."
		return
	if OS.has_feature("web") and not url.begins_with("wss://") and not ("127.0.0.1" in url or "localhost" in url):
		info.text = "La web necesita un servidor seguro wss://."
		return
	socket = WebSocketPeer.new()
	if socket.connect_to_url(url) != OK:
		info.text = "No se pudo conectar."
		socket = null
		return
	info.text = "Conectando…"
	var deadline := clock + 10.0
	while socket != null and socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING and clock < deadline:
		await get_tree().process_frame
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send(socket, {"type": "create" if create else "join", "code": code_input.text.to_upper(), "name": nickname.text, "driver": selected_driver})
	else:
		info.text = "Servidor no disponible. Sal de la sala para reintentar."

func update_menu() -> void:
	driver_button.disabled = playing
	var lines := ["Sala %s · %d/4" % [room_code, snapshot.players.size()]]
	for racer in snapshot.players:
		lines.append("%s · %s" % [racer.name, "Listo" if racer.ready else "Esperando"])
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
	info.text = "\n".join(lines)
	start_button.disabled = int(snapshot.host) != player_id
	start_button.text = "Volver a la sala" if snapshot.phase == "results" else "Iniciar carrera"
	ready_button.disabled = snapshot.phase != "lobby"
	displayed_phase = snapshot.phase

func leave_room() -> void:
	if socket != null:
		socket.close()
	socket = null
	playing = false
	snapshot.clear()
	displayed_phase = ""
	room_code = ""
	player_id = 0
	driver_button.disabled = false
	remote_karts.clear()
	remote_shots.clear()
	get_tree().reload_current_scene()
	info.text = "Carrera privada · hasta 4 pilotos"
