extends Node

const Progress = preload("res://scripts/race_progress.gd")
var tournament: RefCounted
const BotDriver = preload("res://scripts/bot_driver.gd")
const Catalog = preload("res://scripts/driver_catalog.gd")
const NAMES = Catalog.NAMES
var game: Node3D
var racers: Array = []
var bots: Array = []
var phase := "countdown"
var timer := 3.0
var elapsed := 0.0
var first_finish := -1.0
var results: Array = []
var paused := false
var lap_target := 3

func _ready() -> void:
	racers.append({"kart": game.kart, "name": "Tú", "lap": 0, "checkpoint": 0, "prev_z": -3.0, "finished": false})
	for index in range(Network.selected_bots):
		var kart = preload("res://scenes/kart.tscn").instantiate()
		kart.network_controlled = true
		kart.kart_color = Network.COLORS[index + 1]
		game.add_child(kart)
		kart._camera.queue_free()
		var driver_id: int = (Network.selected_driver + index + 1) % NAMES.size()
		kart.get_node("Driver").set_face(driver_id)
		var label := Label3D.new()
		label.name = "BotName"
		label.text = "IA · " + NAMES[driver_id]
		label.position.y = 1.95
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		kart.add_child(label)
		var bot := BotDriver.new()
		bot.kart = kart
		bot.track = game.get_node("Track")
		bot.slot = index
		add_child(bot)
		bots.append(bot)
		racers.append({"kart": kart, "name": label.text, "lap": 0, "checkpoint": 0, "prev_z": -3.0, "finished": false})
	game.kart._camera.current = true
	begin()

func begin() -> void:
	tournament = null
	if Network.selected_mode=="tournament":
		tournament=preload("res://scripts/tournament.gd").new()
		var entries := []
		for index in range(racers.size()):
			var driver_id: int=(Network.selected_driver+index)%NAMES.size()
			entries.append({"id":index,"name":"Tú" if index==0 else "IA · "+NAMES[driver_id],"driver":driver_id})
		tournament.start(entries,Network.selected_laps)
	reset()

func continue_tournament() -> void:
	if tournament!=null and tournament.next():
		reset()
		game.race_menu.resume()

func reset() -> void:
	lap_target = tournament.laps() if tournament!=null else Network.selected_laps
	game.get_node("Track").configure(tournament.stage if tournament!=null else Network.selected_track)
	game.hud.set_circuit(game.get_node("Track").layout_id,tournament.stage if tournament!=null else -1)
	phase = "countdown"
	timer = 3.0
	elapsed = 0.0
	first_finish = -1.0
	paused = false
	results.clear()
	game.get_node("Track/NeutralSleeper").set_physics_process(true)
	game.get_node("Track").reset_obstacles()
	for child in game.get_children():
		if child.is_in_group("projectiles"):
			child.queue_free()
	for index in range(racers.size()):
		var racer: Dictionary = racers[index]
		var slot: int = tournament.grid.find(index) if tournament!=null else index
		var spawn: Transform3D = game.get_node("Track").grid_transform(maxi(0,slot))
		racer.kart.reset_to(spawn)
		racer.kart.spawn_transform = spawn
		racer.kart.enabled = false
		racer.kart.set_physics_process(true)
		racer.kart.controls = {}
		racer.lap = 0
		racer.checkpoint = 0
		racer.prev_z = game.get_node("Track").finish_side(spawn.origin)
		racer.lap_start=0.0
		racer.best_lap=INF
		racer.finished = false
		if index > 0:
			var driver_id: int = int(tournament.table[index].driver) if tournament!=null else (Network.selected_driver+index)%NAMES.size()
			racer.kart.get_node("Driver").set_face(driver_id)
			racer.name = tournament.table[index].name if tournament!=null else "IA · "+NAMES[driver_id]
			racer.kart.get_node("BotName").text = racer.name
	for bot in bots:
		bot.stuck_time = 0.0
		bot.jump_cooldown = 0.0
		bot.route_hint = -1
		bot.last_position = Vector3.INF
		bot.airborne_time = 0.0
	game.kart.get_node("Driver").set_face(Network.selected_driver)

func pause_race(value: bool) -> void:
	paused = value
	for racer in racers:
		racer.kart.enabled = not paused and phase == "racing" and not racer.finished
		racer.kart.set_physics_process(not paused)
	game.get_node("Track/NeutralSleeper").set_physics_process(not paused)

func dispose() -> void:
	for index in range(1, racers.size()):
		racers[index].kart.queue_free()
	game.kart.set_physics_process(true)
	game.get_node("Track/NeutralSleeper").set_physics_process(true)
	queue_free()

func update(delta: float) -> void:
	if paused:
		return
	if Input.is_action_just_pressed("restart_race"):
		reset()
	if Input.is_action_just_pressed("reset") and not racers[0].finished:
		var shield: float = game.kart.protection_time
		var stun: float = game.kart.hit_time
		game.kart.reset_to(game.kart.spawn_transform)
		game.kart.protection_time = shield
		game.kart.hit_time = stun
		racers[0].prev_z = game.get_node("Track").finish_side(game.kart.position)
	if phase == "countdown":
		timer -= delta
		if timer <= 0:
			phase = "racing"
			for racer in racers:
				racer.kart.enabled = true
	elif phase == "racing":
		elapsed += delta
		var all_finished := true
		for racer in racers:
			if not racer.finished:
				all_finished = false
				advance_racer(racer)
		if all_finished or elapsed >= (600 if game.get_node("Track").layout_id==0 else maxi(600,lap_target*150+120)) or (first_finish >= 0 and elapsed - first_finish >= (60 if game.get_node("Track").layout_id==0 else 120)):
			phase = "results"
			for racer in racers:
				racer.kart.enabled = false
				if not racer.finished:
					results.append({"id":racers.find(racer),"name": racer.name, "time": -1.0,"best_lap":racer.best_lap if is_finite(racer.best_lap) else -1.0})
			if tournament!=null: results=tournament.finish(results)
			game.race_menu.show_results(results)
	var player: Dictionary = racers[0]
	game.hud.update_display(mini(player.lap + 1, lap_target), elapsed, INF, absf(game.kart.speed) * 3.6, player.finished, phase == "racing", false, lap_target)
	if player.finished and tournament!=null: game.hud.message.text="¡META! Espera a los demás pilotos."
	if phase == "countdown":
		game.hud._message_panel.show()
		game.hud.message.text = "Salida en %d…" % maxi(1, ceili(timer))
	elif phase == "racing":
		game.hud.set_position(position_of_player(), racers.size())
		if game.kart.hit_time > 0:
			game.hud._message_panel.show()
			game.hud.message.text = "¡Trompo! Protección temporal."
	if Network.browser_test:
		var summary := []
		for racer in racers:
			summary.append({"name": racer.name, "lap": racer.lap, "finished": racer.finished})
		JavaScriptBridge.eval("window.minikartsOfflineTest=" + JSON.stringify({"phase": phase, "laps": lap_target, "racers": summary, "elapsed": elapsed,"track":game.get_node("Track").layout_id,"tournament":tournament.summary() if tournament!=null else {"enabled":false}}) + ";")

func advance_racer(racer: Dictionary) -> void:
	if Progress.advance(game.get_node("Track"),racer,elapsed,lap_target):
		results.append({"id":racers.find(racer),"name":racer.name,"time":elapsed,"best_lap":racer.best_lap})
		if first_finish<0: first_finish=elapsed

func progress(racer: Dictionary) -> float:
	if game.get_node("Track").layout_id>0:
		var points: Array = game.get_node("Track").gates()
		return racer.lap*points.size()+racer.checkpoint-clampf(racer.kart.position.distance_to(points[racer.checkpoint]),0,80)/80.0
	var angle: float = fposmod(atan2(racer.kart.position.z, racer.kart.position.x), TAU)
	# Before the start line, a kart is behind racers that have begun the lap.
	if racer.checkpoint == 0 and racer.kart.position.z < 0 and racer.kart.position.x > 0:
		angle -= TAU
	return float(racer.lap) * TAU + angle

func position_of_player() -> int:
	var position := 1
	for index in range(1, racers.size()):
		if progress(racers[index]) > progress(racers[0]):
			position += 1
	return position
