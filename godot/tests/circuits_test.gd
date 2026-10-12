extends SceneTree
const Progress = preload("res://scripts/race_progress.gd")
var failures:=0
var checks:=0
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(text)
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await frames(3)
	var track=game.get_node("Track")
	var kart=game.kart
	kart.network_controlled=true; kart._touch_driving=true
	kart._camera.queue_free()
	for id in range(1,5):
		track.configure(id)
		await frames(3)
		check(absf(track.track_length-track.Circuits.LENGTHS[id])<0.05,"Exact circuit length %d" % id)
		check(track.ramp_sites.size()==id+1 and track.gaps.size()==1,"Distinct ramp count and one gap per circuit %d" % id)
		for child in track.get_children():
			if child.is_in_group("destructible"):
				var distance: float=track.nearest(child.position).distance
				check(track.ramp_sites.all(func(site):return absf(distance-site.distance)>=34),"Crates are outside ramp approaches and landing zones")
		# A real ray must find road but no collision across the hole.
		var gap: Dictionary=track.gaps[0]
		for sample in [gap.start-8,(gap.start+gap.end)*0.5,gap.end+8]:
			var p: Vector3=track.sample(sample)
			var query=PhysicsRayQueryParameters3D.create(p+Vector3.UP*4,p-Vector3.UP*2)
			query.exclude=[kart.get_rid()]
			var hit: Dictionary=track.get_world_3d().direct_space_state.intersect_ray(query)
			check(hit.is_empty() if sample>gap.start and sample<gap.end else not hit.is_empty(),"Gap has genuinely missing road collision")
		var site: Dictionary=track.ramp_sites[0]
		for variant in ["fast","slow","shot"]:
			kart.reset_to(track.transform_at(site.distance-15))
			kart.speed=kart.MAX_SPEED if variant!="slow" else 12.0
			kart.controls={"accelerate":1.0}
			var fell:=false
			var landed:=false
			var shot:=false
			for frame in range(300):
				if variant=="slow": kart.speed=12.0
				if variant=="shot" and not shot and kart.velocity.y>3.0:
					kart.receive_hit(); shot=true
				await physics_frame
				if kart.position.y < -4: fell=true; break
				var distance: float=track.nearest(kart.position).distance
				if distance>gap.end+4 and kart.is_on_floor(): landed=true; break
			if variant=="fast" and not landed: print("Failed fast jump:",id,site,kart.position,kart.speed,kart.velocity)
			check(landed and not fell if variant=="fast" else fell,"Actual jump physics %s on circuit %d" % [variant,id])
			if fell:
				var racer={"kart":kart,"lap":1,"checkpoint":0,"prev_z":-1,"finished":false}
				Progress.advance(track,racer,42.0,3)
				check(racer.lap==1 and kart.position.distance_to(track.sample(site.distance-12,0,0.7))<0.1,"Falling respawns before the ramp without losing laps")
		# Measure one unobstructed real AI lap, retaining the real ramps and gap.
		for child in track.get_children():
			if child.is_in_group("obstacles"): track.remove_child(child); child.queue_free()
		track.get_node("NeutralSleeper").set_physics_process(false)
		var bot=load("res://scripts/bot_driver.gd").new()
		bot.kart=kart; bot.track=track
		game.add_child(bot)
		kart.reset_to(track.grid_transform(0))
		var racer={"kart":kart,"lap":0,"checkpoint":0,"prev_z":track.finish_side(kart.position),"finished":false,"best_lap":INF,"lap_start":0.0}
		var elapsed:=0.0
		for frame in range(7200):
			await physics_frame
			elapsed+=1.0/60.0
			if Progress.advance(track,racer,elapsed,1): break
		print("Circuit %d: measured clean AI lap %.2f s; respawns %d" % [id,elapsed,racer.get("respawns",0)])
		check(racer.finished,"AI navigates every ordered gate and completes circuit %d" % id)
		check(elapsed>=50 and elapsed<=80,"Clean one-lap duration target on circuit %d" % id)
		bot.queue_free()
		await frames(2)
	print("Circuits: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
