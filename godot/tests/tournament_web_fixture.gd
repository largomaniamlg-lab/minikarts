extends SceneTree
# Local UI integration fixture only. Production never starts this script.
# Drives authoritative gate transitions to exercise all five stages quickly;
# physical lap timing and jumps are covered independently by circuits_test.gd.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var network=root.get_node("Network")
	while true:
		await create_timer(0.18).timeout
		for room in network.rooms.values():
			if room.get("mode","single")!="tournament": continue
			if room.phase=="countdown": room.timer=0.1
			elif room.phase=="racing":
				var gates: Array=room.track.gates()
				for player in room.players.values():
					if player.finished: continue
					player.kart.set_physics_process(false)
					player.kart.speed=0.0
					player.kart.position=gates[player.checkpoint]+Vector3.UP*0.7
					if player.checkpoint==gates.size()-1:
						player.prev_z=-1.0
						if room.track.layout_id>0: player.kart.position+=room.track.tangent(0)*0.2
