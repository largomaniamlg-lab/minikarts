extends SceneTree
const Motion=preload("res://scripts/network_motion.gd")
var checks:=0
var failures:=0
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(text)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(4)
	var track=game.get_node("Track")
	var kart=game.kart
	kart.network_controlled=true; kart._touch_driving=true
	for id in range(1,5):
		track.configure(id)
		await frames(3)
		print("Boost panels, track ",id,": ",track.boost_sites)
		if id in [1,3,4]: check(not track.boost_sites.is_empty(),"Boost appears where a long safe straight is available")
		for distance in track.boost_sites:
			for offset in range(-8,46,5): check(track.tangent(distance).angle_to(track.tangent(distance+offset))<=0.101,"Boost activates on a straight, away from sharp turns")
			check(not track.ramp_sites.any(func(site): return fposmod(site.distance-distance,track.track_length)<95),"Boost cannot overlap ramp/gap approach")
		for obstacle in track.get_children().filter(func(n):return n.is_in_group("destructible")):
			check(obstacle.theme_id==id,"Obstacle visual matches circuit")
		check(track.has_node("ScenarioDecor"),"Circuit owns distinct low-poly scenery")
	track.configure(1)
	await frames(3)
	for obstacle in track.get_children().filter(func(n):return n.is_in_group("destructible")): obstacle.queue_free()
	track.get_node("NeutralSleeper").queue_free()
	await frames(2)
	var distance: float=track.boost_sites[0]
	kart.reset_to(track.transform_at(distance-7))
	kart.controls={"accelerate":1}
	await frames(10)
	kart.speed=kart.MAX_SPEED
	await frames(60)
	check(kart.boost_time>1.5 and kart.speed>79.9/3.6 and kart.speed<=80.01/3.6,"Real pad overlap reaches 80 km/h")
	check(not kart.try_boost(),"Same boost cannot be extended during cooldown")
	var source={"position":[kart.position.x,kart.position.y,kart.position.z],"rotation":[0,kart.rotation.y,0],"speed":kart.speed,"velocity":[kart.velocity.x,kart.velocity.y,kart.velocity.z],"steering":kart._steering,"hit":0.0,"boost":kart.boost_time}
	var predicted=Motion.new().project(source,0.2,{"accelerate":1},0.25)
	await frames(12)
	check(absf(predicted.speed-kart.speed)<0.01 and absf(predicted.boost-kart.boost_time)<0.02,"Client and server agree on boosted speed/timer")
	check(Motion.new().vec(predicted.position).distance_to(kart.position)<0.08,"Boost prediction follows authoritative straight")
	await frames(300)
	check(kart.boost_time==0 and kart.speed<=kart.MAX_SPEED+0.01,"Boost expires and speed returns smoothly to 65")
	kart.boost_time=2; kart.protection_time=0
	game.hud.update_display(9,3599,INF,80,false,true,false,9)
	game.hud.set_position(16,16)
	await process_frame
	check(game.hud.speed_number.text.contains("BOOST"),"HUD identifies temporary boost")
	check(game.hud.timing_panel.size.x<=640,"Boost marker fits compact timing bar")
	check(kart.receive_hit() and kart.boost_time==0,"Shot cancels boost")
	kart.boost_time=2; kart.boost_cooldown=5
	kart.reset_to(track.grid_transform(0))
	check(kart.boost_time==0 and kart.boost_cooldown==0,"Respawn clears boost")
	kart.enabled=false
	check(not kart.try_boost(),"Countdown/finished racer cannot gain boost")
	var custom=source.duplicate(true); custom.boost=0.1
	var expired=Motion.new().project(custom,0.2,{"accelerate":1},0.25)
	check(expired.boost==0 and expired.speed<source.speed,"Prediction decelerates at boost expiration")
	print("Boost/themes: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
