extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,720)
	var network=root.get_node("Network")
	network.selected_mode="tournament"
	network.selected_bots=3
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.start_offline()
	game.set_process(false)
	var tour=game.offline_race.tournament
	tour.stage=4; tour.completed=true
	tour.table={0:{"id":0,"name":"Kikoso","driver":0,"points":64,"wins":4,"qualifying":14.0},1:{"id":1,"name":"Largo","driver":1,"points":60,"wins":0,"qualifying":15.0},2:{"id":2,"name":"Sipollo","driver":2,"points":56,"wins":0,"qualifying":16.0}}
	game.race_menu.show_results([])
	for i in range(30): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/minikarts25-podium.png")
	print("Podium scene rendered")
	tour=null
	current_scene=null
	game.queue_free()
	for i in range(3): await process_frame
	call_deferred("quit")
