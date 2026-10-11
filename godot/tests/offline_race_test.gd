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
	for driver in range(16):
		game.race_menu.select(driver)
		game.race_menu.open()
		check(game.kart.get_node("Driver").face_id == driver, "Selection retains driver %d" % driver)
		check(game.race_menu.cards[driver].visible, "Selected driver is on visible page %d" % driver)
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
	for target in [6, 9]:
		root.get_node("Network").selected_laps = target
		race.reset()
		var racer: Dictionary = race.racers[0]
		for lap_index in range(target):
			for point in game.checkpoints.slice(0, 3):
				racer.kart.position = point + Vector3.UP * 0.7
				race.advance_racer(racer)
			racer.kart.position = Vector3(30, 0.7, -1)
			race.advance_racer(racer)
			racer.kart.position.z = 1
			race.advance_racer(racer)
			check(racer.finished == (lap_index + 1 == target), "Offline finish respects %d laps" % target)
		game.hud.update_display(target, 1.0, INF, 0, true, true, false, target)
		check(game.hud.stats.text.contains("/ %d" % target), "HUD shows selected lap total")
	root.get_node("Network").selected_bots = 15
	game.start_offline()
	await physics_frame
	check(game.offline_race.racers.size() == 16, "Offline supports sixteen racers")
	root.get_node("Network").selected_laps = 3
	root.get_node("Network").selected_bots = 3
	game.start_solo()
	await physics_frame
	await physics_frame
	check(not is_instance_valid(game.offline_race), "Training removes offline race")
	check(game.get_children().filter(func(n): return n is CharacterBody3D).size() == 1, "Training removes all rival karts")
	print("Offline: ", checks, " checks, ", failures, " failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
