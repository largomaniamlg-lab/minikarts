extends RefCounted

static func advance(track: Node3D, racer: Dictionary, elapsed: float, target: int) -> bool:
	var kart = racer.kart
	if kart.position.y < -4:
		kart.reset_to(kart.spawn_transform)
		kart.protection_time = 1.5
		racer.prev_z = track.finish_side(kart.position)
		racer.respawns = int(racer.get("respawns",0))+1
		return false
	var gates: Array = track.gates()
	var point: Vector3 = gates[racer.checkpoint]
	var flat := Vector3(kart.position.x,0,kart.position.z)
	var reached: bool = flat.distance_to(point)<11 if racer.checkpoint<gates.size()-1 else track.crossed_finish(float(racer.prev_z),kart.position)
	if reached:
		kart.spawn_transform = track.gate_spawn(racer.checkpoint)
		racer.checkpoint += 1
		if racer.checkpoint==gates.size():
			racer.checkpoint=0
			racer.lap += 1
			var lap_time := elapsed-float(racer.get("lap_start",0))
			racer.best_lap = minf(float(racer.get("best_lap",INF)),lap_time)
			racer.lap_start = elapsed
			if racer.lap==target:
				racer.finished=true
				kart.enabled=false
				racer.prev_z=track.finish_side(kart.position)
				return true
	racer.prev_z=track.finish_side(kart.position)
	return false
