extends SceneTree
var checks:=0
var failures:=0
var net: Node
var sockets: Array = []
var inbox: Array = [[],[],[],[]]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1;print("PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func pump(steps:int=12) -> void:
	for j in range(sockets.size()):
		if sockets[j].get_ready_state()==WebSocketPeer.STATE_OPEN and not inbox[j].any(func(m):return m.get("type")=="welcome"):
			sockets[j].send_text(JSON.stringify({"type":"list"}))
	for i in range(steps):
		for j in range(sockets.size()):
			var peer: WebSocketPeer=sockets[j];peer.poll()
			while peer.get_available_packet_count()>0:
				var msg=JSON.parse_string(peer.get_packet().get_string_from_utf8())
				if msg is Dictionary: inbox[j].append(msg)
		await create_timer(0.01).timeout
func send_from(index:int,msg:Dictionary) -> void:
	if msg.get("type") in ["create","join"]: msg["social_version"]=1
	sockets[index].send_text(JSON.stringify(msg));await pump()
func events(index:int,kind:String) -> Array:
	return inbox[index].filter(func(m):return m.get("type")=="social_event" and m.get("kind")==kind)
func last_state(index:int) -> Dictionary:
	var states=inbox[index].filter(func(m):return m.get("type")=="state")
	return {} if states.is_empty() else states[-1]
func run() -> void:
	await process_frame;await process_frame
	net=root.get_node("Network");net.server_mode=true;net.social_local=true;net.listener=TCPServer.new()
	check(net.listener.listen(18082,"127.0.0.1")==OK,"local listener18082")
	for i in 4:
		var peer=WebSocketPeer.new();sockets.append(peer);peer.connect_to_url("ws://127.0.0.1:18082")
	await pump(30)
	check(sockets.all(func(p):return p.get_ready_state()==WebSocketPeer.STATE_OPEN),"four real WebSocket clients")
	await send_from(0,{"type":"create","name":"Host"})
	var room: Dictionary=net.rooms.values()[0]
	await send_from(1,{"type":"join","code":room.code,"name":"Guest"})
	await send_from(2,{"type":"create","name":"OtherRoom"})
	await send_from(3,{"type":"join","code":"XXXXXX","name":"Third"})
	check(inbox[3].any(func(m):return m.get("type")=="error"),"invalid room error")
	await send_from(0,{"type":"chat","text":"[b]plain[/b] <script>","id":999,"name":"Spoof"})
	check(events(1,"chat").size()==1,"chat reaches same room")
	check(events(2,"chat").is_empty(),"chat never reaches other room")
	var event: Dictionary=events(1,"chat")[-1]
	check(event.id==room.host and event.name=="Host","identity assigned by server, spoof ignored")
	check(event.text=="[b]plain[/b] <script>","plain text markup remains literal")
	await send_from(0,{"type":"chat","text":"flood"})
	check(events(1,"chat").size()==1,"chat frequency enforced")
	net.clock+=1.1
	await send_from(0,{"type":"chat","text":"x".repeat(190)})
	check(events(1,"chat")[-1].text.length()==160,"chat length bounded160")
	net.clock+=1.1
	await send_from(0,{"type":"chat","text":"one\ntwo\u202ethree"})
	check(not events(1,"chat")[-1].text.contains("\n") and not events(1,"chat")[-1].text.contains("\u202e"),"control characters stripped")
	for i in 35:
		net.clock+=1.1
		await send_from(0,{"type":"chat","text":"History %d"%i})
	check(room.social.history.size()==32,"server history bounded32")
	await send_from(0,{"type":"bots","count":14})
	check(room.players.size()==16,"humans and bots share capacity16")
	await send_from(3,{"type":"join","code":room.code,"name":"Third"})
	check(room.players.size()==16 and room.players.has(-14),"full join rejected without evicting bots")
	await send_from(0,{"type":"bots","count":1})
	await send_from(3,{"type":"join","code":room.code,"name":"Third"})
	check(room.players.size()==4,"human joins once host frees slots")
	var hist: Array=inbox[3].filter(func(m):return m.get("type")=="social_history")
	check(hist.size()==1 and hist[0].messages.size()<=32,"joining client receives bounded room history")
	await send_from(0,{"type":"ready","ready":true})
	await send_from(1,{"type":"ready","ready":true})
	var guest_id: int=last_state(1).players.filter(func(p):return p.name=="Guest")[0].id
	await send_from(1,{"type":"rules","laps":9,"room_name":"Forbidden"})
	check(room.laps==3 and room.social.name!="Forbidden","guest rules rejected by server")
	await send_from(0,{"type":"rules","laps":6,"track":1,"room_name":"Beta room"})
	check(room.laps==6 and room.track.layout_id==1 and room.social.name=="Beta room","host rules and room name authoritative")
	check(not room.players[room.host].ready and not room.players[guest_id].ready and room.players[-1].ready,"relevant rules revoke humans ready only")
	check(events(1,"system").any(func(m):return str(m.text).contains("Listo")),"ready revocation announced")
	check(net.room_directory().any(func(r):return r.code==room.code and r.room_name=="Beta room"),"directory includes name code occupancy")
	await send_from(0,{"type":"ready","ready":true})
	await send_from(0,{"type":"bots","count":2})
	check(not room.players[room.host].ready,"bot count also revokes ready")
	await send_from(0,{"type":"ready","ready":true})
	await send_from(1,{"type":"ready","ready":true})
	await send_from(3,{"type":"ready","ready":true})
	await send_from(0,{"type":"start"})
	check(room.phase=="countdown","ready start enters countdown")
	var timer:float=room.timer
	await send_from(0,{"type":"start"})
	check(room.timer<=timer,"repeated start cannot restart countdown")
	await send_from(0,{"type":"rules","laps":9})
	await send_from(0,{"type":"bots","count":0})
	check(room.laps==6 and room.players.size()==5,"rules and bot edits blocked during countdown")
	var chats:int=events(1,"chat").size()
	net.clock+=2
	await send_from(0,{"type":"chat","text":"countdown blocked"})
	check(events(1,"chat").size()==chats,"no written chat during countdown")
	net.tick_room(room,3.1)
	await send_from(0,{"type":"chat","text":"racing blocked"})
	check(events(1,"chat").size()==chats,"no written chat during race")
	await send_from(0,{"type":"reaction","icon":"smile","name":"Spoof"})
	check(events(1,"reaction").size()==1 and events(1,"reaction")[0].name=="Host","race reaction identity server validated")
	check(events(2,"reaction").is_empty(),"reactions isolated to room")
	await send_from(0,{"type":"reaction","icon":"star"})
	check(events(1,"reaction").size()==1,"per sender reaction frequency bounded")
	await send_from(1,{"type":"reaction","icon":"star"})
	await send_from(3,{"type":"reaction","icon":"flag"})
	check(events(1,"reaction").size()==3,"three simultaneous reactions allowed")
	room.social.active = [net.clock+2.0,net.clock+2.0,net.clock+2.0]
	room.players[room.host].reaction_at = net.clock-1.6
	await send_from(0,{"type":"reaction","icon":"smile"})
	check(events(1,"reaction").size()==3,"room caps simultaneous reactions at3")
	net.clock+=2.1
	await send_from(0,{"type":"reaction","icon":"unknown"})
	check(events(1,"reaction").size()==3,"unknown icon rejected")
	await send_from(0,{"type":"reaction","icon":"flag"})
	check(events(1,"reaction").size()==4 and events(1,"reaction")[-1].duration==2.0,"reaction expiry permits next bounded duration")
	check(room.social.history.all(func(m):return m.kind!="reaction"),"reaction not retained in chat history")
	for peer in sockets: peer.close()
	await pump(20)
	check(net.rooms.is_empty(),"all rooms cleaned including bots")
	net.listener.stop()
	var report={"checks":checks,"failures":failures,"transport":"real local WebSocket","clock":"controlled increments for rate boundaries","physical_devices":false}
	var f=FileAccess.open("res://../evidence/social-release/server-result.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("SOCIAL_AB ",JSON.stringify(report));quit(0 if failures==0 else 1)
