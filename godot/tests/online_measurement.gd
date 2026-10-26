extends SceneTree

const Motion = preload("res://scripts/network_motion.gd")

func packet(stamp: float, count: int) -> Dictionary:
	var players: Array = []
	for id in range(count):
		players.append({"id":id,"position":[id * 2.0,0.7,-18.0 * stamp],"rotation":[0,0,0],"velocity":[0,0,-18.0],"speed":18.0,"steering":0.0,"hit":0.0,"finished":false})
	return {"time":stamp,"phase":"racing","players":players}

func _initialize() -> void:
	var results: Dictionary = {"synthetic":true,"physics_changed":false,"renderer_measured":false,"scenarios":[]}
	for delays in [[0.03],[0.10],[0.06,0.10,0.22,0.08]]:
		var motion = Motion.new()
		var pending: Array = []
		var due := 0.0
		for index in range(200):
			due = maxf(due,index * 0.05 + float(delays[index % delays.size()]))
			pending.append({"due":due,"stamp":index * 0.05})
		var positions: Array = []
		var errors: Array = []
		var max_step := 0.0
		var previous := Vector3.ZERO
		var processing_us := 0
		for frame in range(600):
			var now := frame / 60.0
			while not pending.is_empty() and float(pending.front().due) <= now:
				var next: Dictionary = pending.pop_front()
				motion.push(packet(next.stamp,16),now)
			if motion.states.is_empty(): continue
			var start := Time.get_ticks_usec()
			for id in range(16): motion.remote(id,now)
			processing_us += Time.get_ticks_usec()-start
			var pose: Dictionary = motion.local(motion.states.back().players[0],now,1.0/60.0,{"accelerate":1},float(delays[0])*2.0)
			var pos: Vector3 = motion.vec(pose.position)
			if now>1.0:
				max_step=maxf(max_step,pos.distance_to(previous))
				errors.append(absf(pos.z+18.0*now))
			previous=pos
		results.scenarios.append({"one_way_delay_pattern_ms":delays.map(func(x):return x*1000),"remote_16_cpu_us_per_frame":processing_us/600.0,"local_max_step_m":max_step,"local_mean_error_vs_current_server_m":errors.reduce(func(a,b):return a+b,0.0)/maxi(1,errors.size()),"buffer_ms":motion.buffer_seconds*1000,"jitter_ms":motion.jitter*1000})
	var path := OS.get_environment("MEASUREMENT_OUT")
	if not path.is_empty():
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file: file.store_string(JSON.stringify(results,"\t"))
	print(JSON.stringify(results))
	quit()
