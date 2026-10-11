extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.race_menu.open()
	game.race_menu.select(3)
	check(game.kart.get_node("Driver").face_id == 3, "Visual character selection applies chosen face")
	check(not game.kart.is_physics_processing(), "Menu pauses kart")
	game.start_offline()
	var race = game.offline_race
	check(race.racers.size() == 4 and race.bots.size() == 3, "Offline mode creates exactly three rivals")
	game.kart.network_controlled = true
	var autopilot = load("res://scripts/bot_driver.gd").new()
	autopilot.kart = game.kart
	autopilot.track = game.get_node("Track")
	autopilot.slot = 3
	game.add_child(autopilot)
	var frames := 0
	while race.phase != "results" and frames < 24000:
		await physics_frame
		frames += 1
		if frames % 3600 == 0:
			var progress := []
			for racer in race.racers:
				progress.append([racer.lap, racer.checkpoint, racer.kart.position, racer.kart.speed])
			print("Offline progress: ", progress)
	check(race.phase == "results", "Race reaches results")
	for racer in race.racers:
		check(racer.finished and racer.lap == 3, "Physical racer completes three ordered laps: " + racer.name)
	print("Offline race elapsed: ", race.elapsed, " results: ", race.results)
	game.race_menu.select(1)
	game.start_offline()
	check(race.racers.all(func(r): return r.lap == 0 and not r.finished), "Rematch resets every racer progress")
	check(race.racers[1].kart.get_node("Driver").face_id == 2, "Rematch updates rival faces after new player selection")
	check(race.phase == "countdown" and race.results.is_empty(), "Rematch resets clock and results")
	check(game.get_node("Track").get_children().filter(func(n): return n.is_in_group("obstacles")).size() == 14, "Rematch restores obstacles")
	game.start_solo()
	await physics_frame
	await physics_frame
	check(not is_instance_valid(game.offline_race), "Training removes offline race")
	check(game.get_children().filter(func(n): return n is CharacterBody3D).size() == 1, "Training removes all rival karts")
	print("Offline: ", checks, " checks, ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
