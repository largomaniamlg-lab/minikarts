extends SceneTree
const Progress = preload("res://scripts/race_progress.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.kart.set_physics_process(false)
	game.kart.position=Vector3(10000,0,10000)
	await physics_frame
	var track=game.get_node("Track")
	for id in ([4] if "--last-circuit" in OS.get_cmdline_user_args() else range(1,5)):
		track.configure(id)
		var racers: Array=[]
		var bots: Array=[]
		for slot in range(16):
			var kart=load("res://scenes/kart.tscn").instantiate()
			kart.network_controlled=true
			game.add_child(kart)
			kart._camera.queue_free()
			var spawn=track.grid_transform(slot)
			kart.reset_to(spawn); kart.spawn_transform=spawn; kart.enabled=false
			var bot=load("res://scripts/bot_driver.gd").new()
			bot.kart=kart; bot.track=track; bot.slot=slot
			game.add_child(bot); bots.append(bot)
			racers.append({"kart":kart,"lap":0,"checkpoint":0,"prev_z":track.finish_side(kart.position),"finished":false,"best_lap":INF,"lap_start":0.0})
		# Match the real countdown: start protection must expire before racing.
		for frame in range(180): await physics_frame
		for racer in racers: racer.kart.enabled=true
		for frame in range(14400):
			await physics_frame
			for racer in racers:
				if not racer.finished: Progress.advance(track,racer,float(frame)/60,1)
			if frame==1800:
				for racer in racers:
					if not racer.finished and racer.kart.position.y < -1: print("Early falling ",racer.kart.position," spawn ",racer.kart.spawn_transform.origin)
			if racers.all(func(r):return r.finished): break
		var completed := 0
		for racer in racers:
			if racer.finished: completed+=1
		print("16-bot circuit ",id,": ",completed," finished; recoveries ",bots.map(func(b):return b.recovery_count))
		for racer in racers:
			if not racer.finished: print("STUCK ", racer.kart.position," spawn ",racer.kart.spawn_transform," gate ",racer.checkpoint," speed ",racer.kart.speed)
		if completed!=16: failures+=1; push_error("Every bot must complete despite traffic, weapons and ramps")
		for bot in bots: bot.queue_free()
		for racer in racers: racer.kart.queue_free()
		await physics_frame
	quit(0 if failures==0 else 1)
