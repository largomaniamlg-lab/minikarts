extends RefCounted
const HISTORY_LIMIT := 32
const TEXT_LIMIT := 160
const REACTIONS := ["smile", "star", "flag"]

func clean(value: Variant, limit: int) -> String:
	if not value is String: return ""
	var result := ""
	for ch in value.left(limit * 2):
		var code: int = ch.unicode_at(0)
		if code >= 32 and code != 127 and not (code >= 0x202a and code <= 0x202e) and not (code >= 0x2066 and code <= 0x2069): result += ch
	return result.strip_edges().left(limit)

func ensure(room: Dictionary) -> Dictionary:
	if not room.has("social"):
		room.social = {"history":[],"serial":0,"revision":0,"active":[],"name":"Sala " + room.code}
	return room.social

func emit_event(net: Node, room: Dictionary, event: Dictionary) -> void:
	var social := ensure(room)
	social.serial += 1
	event["seq"] = social.serial
	event["type"] = "social_event"
	if event.kind != "reaction":
		social.history.append(event)
		while social.history.size() > HISTORY_LIMIT: social.history.pop_front()
	for pid in room.players:
		if net.peers.has(pid) and net.peers[pid].get("social_version",0)>=1: net.send(net.peers[pid].socket, event)

func system(net: Node, room: Dictionary, text: String) -> void:
	ensure(room)["notice"] = clean(text,TEXT_LIMIT)
	emit_event(net,room,{"kind":"system","id":0,"name":"Sistema","text":clean(text,TEXT_LIMIT)})

func changed(net: Node, room: Dictionary, reason: String) -> void:
	ensure(room).revision += 1
	for player in room.players.values(): player.ready = player.get("bot",false)
	system(net,room,reason + "; todos los humanos deben marcar Listo de nuevo.")

func joined(net: Node, room: Dictionary, pid: int) -> void:
	var social := ensure(room)
	if net.peers[pid].get("social_version",0)>=1:
		net.send(net.peers[pid].socket,{"type":"social_history","messages":social.history})
	system(net,room,clean(room.players[pid].name,20) + " ha entrado.")

func handle(net: Node, room: Dictionary, pid: int, msg: Dictionary) -> bool:
	var kind: String = str(msg.get("type",""))
	if kind not in ["chat","reaction","rules"]: return false
	var social := ensure(room)
	var player: Dictionary = room.players[pid]
	if kind == "rules":
		if pid != room.host or room.phase != "lobby" or room.tournament.started:
			net.reject(pid,"Solo el anfitrion puede cambiar reglas antes de iniciar."); return true
		var name := clean(msg.get("room_name",social.name),32)
		var laps: int = net.Settings.valid_laps(msg.get("laps",room.race_laps))
		var layout: int = net.Circuits.valid(msg.get("track",room.track.layout_id))
		var mode := "tournament" if msg.get("mode",room.mode) == "tournament" else "single"
		if mode == "tournament": layout = 0
		if name.is_empty(): name = social.name
		if name == social.name and laps == room.race_laps and layout == room.track.layout_id and mode == room.mode: return true
		social.name = name
		room.mode = mode; room.race_laps = laps; room.laps = 3 if mode == "tournament" else laps
		room.track.configure(layout)
		for p in room.players.values(): p.spawn = room.track.grid_transform(p.grid_slot)
		net.reset_room(room)
		changed(net,room,"Reglas o nombre de sala actualizados")
		return true
	if kind == "chat":
		if room.phase not in ["lobby","results"]:
			net.reject(pid,"Chat escrito desactivado durante la carrera y la salida."); return true
		var text := clean(msg.get("text",""),TEXT_LIMIT)
		if text.is_empty(): return true
		if net.clock - float(player.get("chat_at",-100.0)) < 1.0:
			net.reject(pid,"Espera un segundo entre mensajes."); return true
		player.chat_at = net.clock
		emit_event(net,room,{"kind":"chat","id":pid,"name":clean(player.name,20),"text":text})
		return true
	var icon: String = str(msg.get("icon",""))
	if icon not in REACTIONS: return true
	if room.phase not in ["lobby","racing","results"]: return true
	if net.clock - float(player.get("reaction_at",-100.0)) < 1.5: return true
	social.active = social.active.filter(func(expiry): return expiry > net.clock)
	if social.active.size() >= 3: return true
	player.reaction_at = net.clock
	social.active.append(net.clock + 2.0)
	emit_event(net,room,{"kind":"reaction","id":pid,"name":clean(player.name,20),"icon":icon,"duration":2.0})
	return true
