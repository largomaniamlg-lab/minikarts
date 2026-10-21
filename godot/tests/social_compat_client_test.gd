extends SceneTree
var network: Node
var host := WebSocketPeer.new()
var states: Array = []
var welcome: Dictionary = {}
var failures:=0
var checks:=0
var legacy_client:=false
var legacy_server:=false
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1;print("PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func pump(steps:int=15) -> void:
	for i in steps:
		host.poll()
		while host.get_available_packet_count()>0:
			var m=JSON.parse_string(host.get_packet().get_string_from_utf8())
			if m is Dictionary:
				if m.get("type")=="welcome":welcome=m
				if m.get("type")=="state":states.append(m)
		await create_timer(0.02).timeout
func send_host(msg:Dictionary) -> void:
	host.send_text(JSON.stringify(msg));await pump()
func run() -> void:
	legacy_client="--legacy-client" in OS.get_cmdline_user_args()
	legacy_server="--legacy-server" in OS.get_cmdline_user_args()
	var url:="ws://127.0.0.1:18097" if legacy_server else "ws://127.0.0.1:18096"
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
	await process_frame;await process_frame
	network=root.get_node("Network")
	var modern:bool=network.get_property_list().any(func(p):return p.name=="server_social_version")
	check(modern!=legacy_client,"actual old pack vs new source selected")
	host.connect_to_url(url);await pump()
	check(host.get_ready_state()==WebSocketPeer.STATE_OPEN,"compat fixture host connected")
	await send_host({"type":"create","name":"CompatHost","social_version":1})
	check(not welcome.is_empty(),"host created room")
	if welcome.is_empty():quit(1);return
	network.address.text=url;network.nickname.text="CompatGuest";network.code_input.text=welcome.code;network.connect_room(false)
	var deadline:=Time.get_ticks_msec()+6000
	while not network.playing and Time.get_ticks_msec()<deadline:await pump(1)
	check(network.playing and network.snapshot.players.size()==2,"actual client joins shared room")
	if not network.playing:quit(1);return
	network.menu.get_node("Panel").show()
	await process_frame;await process_frame
	if modern:
		check(network.server_social_version==(0 if legacy_server else 1),"capability version negotiated")
		check(network.social_ui.panel.visible!=legacy_server,"new UI hidden on old server")
	if not legacy_server:
		await send_host({"type":"bots","count":2})
		await pump()
		check(network.snapshot.players.size()==4,"legacy compatible state includes bots")
		check(network.remote_karts.has(-1) and network.remote_karts.has(-2),"client renders negative bot IDs")
		await send_host({"type":"chat","text":"Compatibility plain text"})
		if modern:check(network.social_ui.history_label.text.contains("Compatibility plain text"),"new client receives social event")
		else:check(network.snapshot.phase=="lobby","old client continues normally without social events")
	network.ready_button.pressed.emit();await pump()
	await send_host({"type":"ready","ready":true})
	await send_host({"type":"start"})
	deadline=Time.get_ticks_msec()+5000
	while network.snapshot.phase!="racing" and Time.get_ticks_msec()<deadline:await pump(1)
	check(network.snapshot.phase=="racing","compatible clients start shared race")
	game.kart._focused=true
	await pump(45)
	check(states.any(func(state):return state.players.any(func(p):return p.name=="CompatGuest" and absf(float(p.speed))>0)),"guest drives with shared authority")
	host.close();network.socket.close();await pump(10)
	var label:=("old-client-old-server" if legacy_server else "old-client-new-server") if legacy_client else ("new-client-old-server" if legacy_server else "new-client-new-server")
	if "--apk-client" in OS.get_cmdline_user_args():label="apk024-client-new-server"
	var f=FileAccess.open(OS.get_environment("COMPAT_REPORT"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"case":label,"checks":checks,"failures":failures,"legacy_client_pack":legacy_client,"legacy_server_pack":legacy_server,"physical_devices":false,"focused":game.kart._focused,"phase":network.snapshot.get("phase","")},"\t"));f.close()
	print("COMPAT ",label," checks=",checks," failures=",failures);quit(0 if failures==0 else 1)
