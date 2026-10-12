extends SceneTree
var failures:=0
var checks:=0
var network: Node
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(text)
func _initialize() -> void: call_deferred("run")
func fake(id: int) -> void:
	network.peers[id]={"socket":WebSocketPeer.new(),"room":"","since":0.0,"window":0.0,"count":0}
func run() -> void:
	network=root.get_node("Network")
	network.set_process(false)
	for id in [101,102,103,104]: fake(id)
	network.server_message(101,{"type":"create","name":"Uno","mode":"tournament","track":4,"laps":6,"driver":0})
	var room: Dictionary=network.rooms[network.peers[101].room]
	for id in [102,103]: network.server_message(id,{"type":"join","name":"Piloto %d" % id,"code":room.code,"driver":id%16})
	check(room.track.layout_id==0 and room.laps==3,"Tournament qualifies on original for three laps regardless of race choice")
	for stage in range(5):
		check(room.phase=="lobby" and room.track.layout_id==stage,"Correct track in each tournament stage")
		for id in [101,102,103]: network.server_message(id,{"type":"ready","ready":true})
		network.server_message(101,{"type":"start"})
		check(room.phase=="countdown","Every stage retains readiness and a synchronized countdown")
		network.tick_room(room,3.1)
		check(room.phase=="racing","Every stage enables racing")
		network.server_message(104,{"type":"join","code":room.code})
		check(room.players.size()==3,"Late join cannot corrupt championship roster")
		var results:=[]
		for id in [101,102,103]:
			room.players[id].finished=true
			results.append({"id":id,"name":room.players[id].name,"time":float(id-20),"best_lap":float(114-id)})
		room.results=results
		network.tick_room(room,0.1)
		check(room.phase=="results","Stage produces authoritative results")
		var state: Dictionary=network.room_state(room)
		check(state.tournament.stage==stage,"Shared state identifies tournament stage")
		if stage==0:
			check(state.results[0].id==103 and room.tournament.grid==[103,102,101],"Best individual lap, not fastest total race, determines first grid")
		else:
			check(room.tournament.table[101].points==16*stage,"Points accumulate once across each of four races")
			var before: int=room.tournament.table[101].points
			room.tournament.finish(results)
			check(room.tournament.table[101].points==before,"Repeated completion cannot award points twice")
		if stage<4:
			network.server_message(101,{"type":"restart"})
			check(room.laps==6,"Selected race laps apply after qualifying")
			var order: Array=[103,102,101] if stage==0 else [101,102,103]
			for rank in range(order.size()):
				check(room.players[order[rank]].spawn.origin.is_equal_approx(room.track.grid_transform(rank).origin),"Next grid follows qualifying or previous race order")
	check(room.tournament.summary().finished,"Podium only becomes final after four races")
	check(room.tournament.standings()[0].id==101,"Championship winner is chosen by accumulated points")
	network.server_message(101,{"type":"restart"})
	check(room.track.layout_id==0 and not room.tournament.started,"New tournament resets the championship")
	var positions: Array=[]
	for player in room.players.values(): positions.append(player.spawn.origin)
	check(positions[0]!=positions[1] and positions[1]!=positions[2],"Fresh tournament has distinct grid slots before ready")
	var Tor=load("res://scripts/tournament.gd")
	var tour=Tor.new()
	tour.start([{"id":1,"name":"A","driver":0},{"id":2,"name":"B","driver":1}],3)
	tour.finish([{"id":1,"time":10,"best_lap":4},{"id":2,"time":-1,"best_lap":-1}])
	tour.next()
	tour.finish([{"id":1,"time":10},{"id":2,"time":-1}])
	check(tour.table[2].points==0,"Not finishing earns zero championship points")
	print("Tournament: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
