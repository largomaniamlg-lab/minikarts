extends Node3D

@onready var kart: CharacterBody3D = $Kart
var elapsed: float = 0.0
var lap: int = 0
var checkpoint: int = 0
var finished: bool = false
var started: bool = false
var lap_start: float = 0.0
var best_lap: float = INF
var notice_time: float = 0.0
var checkpoints: Array[Vector3] = [Vector3(0, 0, 30), Vector3(-30, 0, 0), Vector3(0, 0, -30), Vector3(30, 0, 0)]
var initial_transform: Transform3D
var hud: CanvasLayer
var prev_z: float = -3.0
var lap_target := 3
var race_menu: CanvasLayer
var offline_race: Node

func _ready() -> void:
	if Network.server_mode:
		queue_free()
		return
	Sound.game = self
	initial_transform = kart.transform
	prev_z = $Track.finish_side(kart.position)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.15
	add_child(sun)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("398cdb")
	sky_material.sky_horizon_color = Color("b5e6fa")
	sky_material.ground_horizon_color = Color("b5e6fa")
	sky_material.ground_bottom_color = Color("83ba65")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d6e8f7")
	environment.ambient_light_energy = 0.75
	world.environment = environment
	add_child(world)
	hud = preload("res://scripts/hud.gd").new()
	add_child(hud)
	race_menu = preload("res://scripts/race_menu.gd").new()
	race_menu.game = self
	add_child(race_menu)
	call_deferred("startup_menu")

func startup_menu() -> void:
	if get_tree().current_scene == self or OS.has_feature("web") or "--race-menu" in OS.get_cmdline_user_args():
		race_menu.open()

func start_offline() -> void:
	lap_target = Network.selected_laps
	if is_instance_valid(offline_race) and offline_race.bots.size() != Network.selected_bots:
		clear_offline()
	if not is_instance_valid(offline_race):
		offline_race = preload("res://scripts/offline_race.gd").new()
		offline_race.game = self
		add_child(offline_race)
	else:
		offline_race.begin()
	race_menu.resume()

func clear_offline() -> void:
	if is_instance_valid(offline_race):
		offline_race.dispose()
		offline_race = null

func start_solo() -> void:
	lap_target = Network.selected_laps
	clear_offline()
	$Track.configure(Network.selected_track)
	hud.set_circuit(Network.selected_track)
	initial_transform=$Track.grid_transform(0)
	checkpoints=$Track.gates()
	reset_race()
	race_menu.resume()

func prepare_online() -> void:
	clear_offline()
	reset_race()
	race_menu.hide()
	hud.show()
	kart.enabled = false
	kart.set_physics_process(true)
	$Track/NeutralSleeper.set_physics_process(true)

func reset_race() -> void:
	if is_instance_valid(offline_race):
		offline_race.begin()
		return
	for projectile in get_tree().get_nodes_in_group("projectiles"):
		projectile.queue_free()
	$Track.call("reset_obstacles")
	elapsed = 0.0
	lap = 0
	checkpoint = 0
	finished = false
	started = false
	lap_start = 0.0
	best_lap = INF
	notice_time = 0.0
	kart.set("spawn_transform", initial_transform)
	kart.call("reset_to", initial_transform)
	prev_z = $Track.finish_side(kart.position)

func recover() -> void:
	if finished:
		reset_race()
		return
	kart.call("reset_to", kart.get("spawn_transform"))
	prev_z = $Track.finish_side(kart.position)
	notice_time = 2.0

func _process(delta: float) -> void:
	if Network.playing:
		Network.update_game(self, delta)
		return
	if race_menu.visible:
		return
	if is_instance_valid(offline_race):
		offline_race.update(delta)
		return
	if Input.is_action_just_pressed("restart_race"):
		reset_race()
	elif Input.is_action_just_pressed("reset"):
		recover()
	if kart.position.y < -4.0:
		recover()
	if absf(float(kart.get("speed"))) > 0.5:
		started = true
	if started and not finished:
		elapsed += delta
		var flat := Vector3(kart.position.x, 0, kart.position.z)
		var crossed: bool = $Track.crossed_finish(prev_z,kart.position)
		var reached := flat.distance_to(checkpoints[checkpoint]) < 11.0 if checkpoint < checkpoints.size()-1 else crossed
		if reached:
			var point: Vector3 = checkpoints[checkpoint]
			var tangent := Vector3(-point.z, 0, point.x).normalized()
			var respawn: Transform3D = $Track.gate_spawn(checkpoint)
			kart.set("spawn_transform", respawn)
			checkpoint += 1
			if checkpoint == checkpoints.size():
				checkpoint = 0
				lap += 1
				best_lap = minf(best_lap, elapsed - lap_start)
				lap_start = elapsed
				if lap == lap_target:
					finished = true
					kart.set("enabled", false)
	notice_time = maxf(0.0, notice_time - delta)
	prev_z = $Track.finish_side(kart.position)
	hud.call("update_display", mini(lap + 1, lap_target), elapsed, best_lap, absf(float(kart.get("speed"))) * 3.6, finished, started, notice_time > 0.0, lap_target)
