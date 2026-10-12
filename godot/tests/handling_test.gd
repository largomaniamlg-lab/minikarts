extends SceneTree

const Motion = preload("res://scripts/network_motion.gd")
var failures := 0
var checks := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var kart = load("res://scenes/kart.tscn").instantiate()
	kart.network_controlled = true
	world.add_child(kart)
	kart._camera.queue_free()
	await physics_frame
	kart.position = Vector3(1000, 10, 1000)
	kart.rotation = Vector3.ZERO
	kart.speed = kart.MAX_SPEED
	kart.velocity = Vector3(0, 0, -kart.MAX_SPEED)
	kart._steering = 0.0
	kart.controls = {"accelerate": 1, "steer_right": 1}
	var source := {"position": [1000, 10, 1000], "rotation": [0, 0, 0], "speed": kart.speed, "velocity": [0, 0, -kart.speed], "steering": 0.0, "hit": 0.0}
	var prediction := Motion.new().project(source, 12.0 / 60.0, kart.controls, 0.25)
	for frame in range(12):
		await physics_frame
	var position := Motion.new().vec(prediction.position)
	check(Vector2(position.x-kart.position.x, position.z-kart.position.z).length() < 0.015, "Turning prediction matches authoritative horizontal path over 200 ms")
	check(absf(angle_difference(prediction.rotation[1], kart.rotation.y)) < 0.002, "Client and server agree on gradual steering angle")
	check(kart._steering > 0.99, "Full joystick reaches full steering within 200 ms")
	var yaw: float = kart.rotation.y
	for frame in range(30):
		await physics_frame
	var rate: float = absf(angle_difference(yaw, kart.rotation.y)) / 0.5
	check(rate > kart.MAX_SPEED / 22.0 * 1.4 and rate < 1.3, "Full-speed turning is at least 40 percent stronger while bounded")
	kart.controls = {"accelerate": 1, "steer_left": 1}
	for frame in range(21):
		await physics_frame
	check(kart._steering < -0.99, "Direction reversal responds within 350 ms")
	kart.controls = {"accelerate": 1}
	for frame in range(6):
		await physics_frame
	check(is_zero_approx(kart._steering), "Releasing the joystick promptly straightens the kart")
	check(kart.speed <= 65.0 / 3.6 + 0.001, "Improved handling preserves speed cap")
	# A nearby rival must not push the camera forward; walls must still block it.
	var target := CharacterBody3D.new()
	world.add_child(target)
	target.add_to_group("karts")
	target.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var camera = load("res://scripts/camera_follow.gd").new()
	camera.target = target
	target.add_child(camera)
	camera.set_process(false)
	var rival := CharacterBody3D.new()
	rival.position = Vector3(0, 2, 3)
	rival.add_to_group("karts")
	world.add_child(rival)
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 2)
	collider.shape = box
	rival.add_child(collider)
	for frame in range(3):
		await physics_frame
	camera.reset_follow()
	camera.follow(1.0 / 60.0)
	check(camera.position.z > 5.5, "A rival between player and camera does not produce a camera jump")
	var wall := StaticBody3D.new()
	wall.position = Vector3(0, 2, 4)
	world.add_child(wall)
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(3, 3, 0.6)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	for frame in range(3):
		await physics_frame
	camera.reset_follow()
	camera.follow(1.0 / 60.0)
	check(camera.position.z < 3.7, "Camera still respects static circuit walls")
	print("Handling: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
