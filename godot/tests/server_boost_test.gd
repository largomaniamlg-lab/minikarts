extends SceneTree
var failures:=0
var checks:=0
var network: Node
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(text)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func _initialize() -> void: call_deferred("run")
func run() -> void:
	network=root.get_node("Network"); network.set_process(false)
	network.peers[701]={"socket":WebSocketPeer.new(),"room":"","since":0.0,"window":0.0,"count":0}
	network.server_message(701,{"type":"create","track":1})
	var room: Dictionary=network.rooms[network.peers[701].room]
	var kart=room.players[701].kart
	await frames(5)
	network.server_message(701,{"type":"input","boost":99,"speed":800,"position":[999,999,999],"controls":{"boost":1,"accelerate":1}})
	check(kart.boost_time==0 and kart.speed==0,"Client cannot forge boost/speed during lobby")
	check(not room.track.has_node("ScenarioDecor"),"Server skips visual scenery")
	for obstacle in room.track.get_children().filter(func(n):return n.is_in_group("destructible")): obstacle.queue_free()
	room.track.get_node("NeutralSleeper").set_physics_process(false)
	room.track.get_node("NeutralSleeper").position=Vector3(10000,0,10000)
	await frames(2)
	room.phase="racing"; kart.enabled=true
	kart.reset_to(room.track.transform_at(room.track.boost_sites[0]-7))
	kart.controls={"accelerate":1}
	await frames(10); kart.speed=kart.MAX_SPEED
	await frames(60)
	var state=network.room_state(room)
	check(kart.boost_time>0 and kart.speed>79.9/3.6,"Authoritative pad triggers 80 km/h")
	check(state.players[0].boost>0 and state.players[0].speed<=80.01/3.6,"State carries trusted boost timer and bounded speed")
	var remaining: float=kart.boost_time
	network.server_message(701,{"type":"input","boost":99,"speed":800,"controls":{"boost":1,"accelerate":1}})
	check(kart.boost_time==remaining,"Client cannot extend active boost")
	kart.receive_hit()
	check(network.room_state(room).players[0].boost==0,"Shot cancellation immediately reaches client")
	print("Server boost: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
