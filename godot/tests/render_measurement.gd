extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.race_menu.hide()
	root.get_node("Network").menu.hide()
	game.kart.set_physics_process(false)
	for index in range(1,16):
		var kart=load("res://scenes/kart.tscn").instantiate()
		game.add_child(kart)
		kart.position=game.kart.position+Vector3((index%4-1.5)*2.0,0,-(index/4)*2.5)
		kart.set_physics_process(false)
		kart.get_node("Driver").set_face(index)
		kart._camera.queue_free()
	game.kart._camera.current=true
	game.kart._camera.set_script(null)
	game.kart._camera.global_position=game.kart.global_position+Vector3(0,9,13)
	game.kart._camera.look_at(game.kart.global_position+Vector3(0,0,-3))
	var results: Array=[]
	for kart in get_nodes_in_group("karts"): preload("res://scripts/vehicle_catalog.gd").apply(kart,preload("res://scripts/vehicle_catalog.gd").DRAGON)
	for low in [false,true]:
		root.get_node("ToonStyle").set_low(low)
		for light in get_nodes_in_group("toon_sun"): light.shadow_enabled=not low
		for i in range(60): await process_frame
		var times: Array=[]
		var previous:=Time.get_ticks_usec()
		for i in range(120):
			await RenderingServer.frame_post_draw
			var now:=Time.get_ticks_usec()
			times.append((now-previous)/1000.0)
			previous=now
		times.sort()
		results.append({"low":low,"frame_p50_ms":times[60],"frame_p95_ms":times[114],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	var result: Dictionary={"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"fixture":"16 stationary dragons, original 2D faces; desktop only; VSync on; no network","results":results}
	var file=FileAccess.open(OS.get_environment("MEASUREMENT_OUT"),FileAccess.WRITE)
	if file:file.store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/dragon-release/render-fixture.png"))
	quit()
