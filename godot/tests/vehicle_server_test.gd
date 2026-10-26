extends SceneTree
var net: Node
var peers: Array=[]
var messages: Array=[[],[],[]]
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func _initialize() -> void:call_deferred("run")
func pump(count:=20) -> void:
	for i in count:
		for index in peers.size():
			peers[index].poll()
			while peers[index].get_available_packet_count()>0:
				var message=JSON.parse_string(peers[index].get_packet().get_string_from_utf8())
				if message is Dictionary: messages[index].append(message)
		await create_timer(0.01).timeout
func send(index: int,message: Dictionary) -> void:
	peers[index].send_text(JSON.stringify(message))
	await pump()
func state(index: int) -> Dictionary:
	var states=messages[index].filter(func(m):return m.get("type")=="state")
	return states[-1] if not states.is_empty() else {}
func run() -> void:
	await process_frame;await process_frame
	net=root.get_node("Network");net.server_mode=true;net.social_local=true;net.listener=TCPServer.new()
	check(net.listener.listen(18106,"127.0.0.1")==OK,"Listener")
	for i in 3:
		var peer:=WebSocketPeer.new();peers.append(peer);peer.connect_to_url("ws://127.0.0.1:18106")
	await pump(40)
	check(peers.all(func(p):return p.get_ready_state()==WebSocketPeer.STATE_OPEN),"Three WebSocket clients incl legacy")
	await send(0,{"type":"create","driver":6,"name":"Dragon","vehicle":"dragon_experimental_v1","vehicle_version":1,"social_version":1})
	var room: Dictionary=net.rooms.values()[0]
	await send(1,{"type":"join","driver":2,"name":"Usual","code":room.code,"vehicle":"habitual","vehicle_version":1,"social_version":1})
	await send(2,{"type":"join","driver":4,"name":"Legacy","code":room.code})
	var snapshot:=state(1)
	check(snapshot.vehicle_version==1,"Capability advertised")
	check(snapshot.players.any(func(p):return p.name=="Dragon" and p.vehicle=="dragon_experimental_v1" and p.driver==6),"Stable dragon ID and independent driver")
	check(snapshot.players.any(func(p):return p.name=="Usual" and p.vehicle=="habitual" and p.driver==2),"Other client's usual vehicle retained")
	check(snapshot.players.any(func(p):return p.name=="Legacy" and p.vehicle=="habitual"),"Legacy join defaults safely")
	for player in room.players.values():
		var colliders=player.kart.get_children().filter(func(n):return n is CollisionShape3D)
		check(colliders.size()==1 and colliders[0].shape.size==Vector3(1.25,0.65,1.9),"Same authoritative collider")
	await send(0,{"type":"vehicle","vehicle":"habitual"})
	check(room.players[room.host].vehicle=="dragon_experimental_v1","Vehicle immutable after join")
	await send(0,{"type":"bots","count":1})
	await send(0,{"type":"ready","ready":true})
	await send(1,{"type":"ready","ready":true})
	await send(2,{"type":"ready","ready":true})
	await send(0,{"type":"start"})
	await pump(350)
	check(state(0).phase=="racing" and state(1).phase=="racing","Distinct vehicles enter same race")
	check(state(2).phase=="racing","Legacy protocol participates")
	check(state(1).players.any(func(p):return p.vehicle=="dragon_experimental_v1"),"Vehicle survives race transition")
	for peer in peers:peer.close()
	await pump(30)
	check(net.rooms.is_empty(),"Room and bots cleaned on exit")
	net.listener.stop()
	print("Vehicle server: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
