extends Node

var kart: CharacterBody3D
var track: Node3D
var slot := 0
var stuck_time := 0.0
var recovery_count := 0
var jump_cooldown := 0.0
var route_hint := -1

func _physics_process(delta: float) -> void:
	if not is_instance_valid(kart) or not kart.enabled:
		return
	jump_cooldown = maxf(0.0, jump_cooldown - delta)
	if track.layout_id>0:
		drive_route(delta)
		return
	var angle := atan2(kart.position.z, kart.position.x)
	var lane := float(slot % 4) * 1.0
	var target: Vector3 = track.track_point(angle + 0.25, 30.0 + lane, kart.position.y)
	var desired := (target - kart.position).normalized()
	var forward := -kart.global_basis.z
	var error := atan2(forward.cross(desired).y, forward.dot(desired))
	var limit := 12.0 + float(slot % 4) * 0.6
	var input := {"accelerate": 1.0 if kart.speed < limit else 0.0, "brake": 1.0 if kart.speed > limit + 0.5 else 0.0,
		"steer_right": maxf(0.0, -error * 3.5), "steer_left": maxf(0.0, error * 3.5), "jump": 0.0, "shoot": 0.0}
	input.steer_right = minf(input.steer_right, 1.0)
	input.steer_left = minf(input.steer_left, 1.0)
	var query := PhysicsRayQueryParameters3D.create(kart.global_position, kart.global_position + forward * 9.0)
	query.exclude = [kart.get_rid()]
	var collision := kart.get_world_3d().direct_space_state.intersect_ray(query)
	if not collision.is_empty():
		var body: Object = collision.collider
		var distance: float = kart.global_position.distance_to(collision.position)
		input.shoot = 1.0 if body.is_in_group("destructible") or body.has_method("receive_hit") else 0.0
		if body.is_in_group("obstacles") and distance < 4.5 and jump_cooldown <= 0 and kart.is_on_floor():
			input.jump = 1.0
			jump_cooldown = 0.7
	kart.controls = input
	stuck_time = stuck_time + delta if absf(kart.speed) < 1.0 and kart.hit_time <= 0 else 0.0
	if stuck_time > 3.0 or kart.position.y < -4.0:
		var shield: float = kart.protection_time
		var stun: float = kart.hit_time
		kart.reset_to(kart.spawn_transform)
		kart.protection_time = shield
		kart.hit_time = stun
		recovery_count += 1
		stuck_time = 0.0

func drive_route(delta: float) -> void:
	var nearest: Dictionary = track.nearest(kart.position,route_hint)
	route_hint=nearest.index
	var distance: float = nearest.distance
	var lookahead := maxf(8.0,absf(kart.speed)*0.6)
	var target: Vector3 = track.sample(distance+lookahead,float(slot%3-1)*1.2,kart.position.y)
	var forward := -kart.global_basis.z
	var desired := (target-kart.position).normalized()
	var error := atan2(forward.cross(desired).y,forward.dot(desired))
	var steer := clampf(-15.0*2.0*sin(error)/lookahead,-1,1)
	var curvature: float = track.tangent(distance+5).angle_to(track.tangent(distance+25))/20.0
	var limit := minf(kart.MAX_SPEED-0.1,sqrt(12.0/maxf(curvature,0.001)))
	for site in track.ramp_sites:
		if site.dangerous and fposmod(site.distance-distance,track.track_length)<55: limit=kart.MAX_SPEED
	var shoot := 0.0
	var query := PhysicsRayQueryParameters3D.create(kart.global_position,kart.global_position+forward*9.0)
	query.exclude=[kart.get_rid()]
	var hit: Dictionary=kart.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): shoot=1.0 if hit.collider.is_in_group("destructible") or hit.collider.has_method("receive_hit") else 0.0
	kart.controls={"accelerate":1.0 if kart.speed<limit else 0.0,"brake":1.0 if kart.speed>limit+0.3 else 0.0,"steer_right":maxf(steer,0),"steer_left":maxf(-steer,0),"shoot":shoot}
	stuck_time=stuck_time+delta if absf(kart.speed)<1 and kart.hit_time<=0 else 0.0
	if stuck_time>4 or kart.position.y<-4:
		kart.reset_to(kart.spawn_transform)
		stuck_time=0; route_hint=-1; recovery_count+=1
