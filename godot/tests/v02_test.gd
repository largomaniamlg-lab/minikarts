extends SceneTree
var failures := 0
var viewport: SubViewport
var controls: Control

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error("V02: " + description)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func find_controls(node: Node) -> void:
	if node.get_script() != null and node.get_script().resource_path == "res://scripts/touch_controls.gd":
		controls = node
	for child in node.get_children():
		find_controls(child)

func touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	viewport.push_input(event)

func run_checks() -> void:
	check("--force-touch" in OS.get_cmdline_user_args(), "Touch mode enabled")
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var game = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(game)
	await frames(45)
	var kart = game.kart
	check(kart.speed > 1.0, "Automatic acceleration without input")
	Input.action_press("brake")
	await frames(90)
	check(absf(kart.speed) < 0.01, "Brake dominates automatic acceleration and cannot reverse")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	check(not kart.is_on_floor() and kart.velocity.y > 0.0, "Ground jump becomes airborne")
	await frames(8)
	var before_second_jump: float = kart.velocity.y
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	check(kart.velocity.y < before_second_jump, "No extra jump in midair")
	await frames(60)
	check(kart.is_on_floor(), "Jump lands on track")
	Input.action_release("brake")
	Input.action_press("reverse")
	var reverse_origin: Vector3 = kart.position
	var reverse_direction: Vector3 = kart.basis.z
	await frames(45)
	check(kart.speed < -0.5 and (kart.position - reverse_origin).dot(reverse_direction) > 0.5, "Explicit reverse moves backward")
	Input.action_release("reverse")
	game.reset_race()
	Input.action_press("brake")
	await frames(5)
	find_controls(game)
	check(controls != null, "Joystick controls exist")
	if controls != null:
		var buttons: Array = controls.get("_buttons")
		var center: Vector2 = controls.get("_joystick_center")
		touch(0, center + Vector2(-45, 0), true)
		var brake_position: Vector2 = buttons[0].global_position + buttons[0].texture_normal.get_size() / 2.0
		var shoot_position: Vector2 = buttons[2].global_position + buttons[2].texture_normal.get_size() / 2.0
		touch(1, brake_position, true)
		touch(2, shoot_position, true)
		check(Input.get_action_strength("steer_left") > 0.1 and Input.get_action_strength("steer_left") < 0.9, "Joystick proportional steering")
		check(Input.is_action_pressed("brake") and Input.is_action_pressed("shoot"), "Joystick brake and shoot support three fingers")
		touch(0, center, false)
		touch(1, brake_position, false)
		touch(2, shoot_position, false)
		check(not Input.is_action_pressed("steer_left") and not Input.is_action_pressed("shoot"), "Multitouch release clears actions")
		# Five independent contacts; moving the joystick vertically cannot change steering.
		touch(3, center + Vector2(45, 0), true)
		var initial_strength := Input.get_action_strength("steer_right")
		var drag := InputEventScreenDrag.new()
		drag.index = 3
		drag.position = center + Vector2(45, -160)
		viewport.push_input(drag)
		check(is_equal_approx(Input.get_action_strength("steer_right"), initial_strength), "Vertical thumb drift preserves steering")
		touch(4, brake_position, true)
		touch(5, shoot_position, true)
		touch(6, controls._button_center(1), true)
		touch(7, shoot_position, true)
		check(Input.is_action_pressed("brake") and Input.is_action_pressed("shoot") and Input.is_action_pressed("jump") and Input.is_action_pressed("steer_right"), "Five contacts combine steering brake jump and shoot")
		drag.index = 5
		drag.position = Vector2(640, 300)
		viewport.push_input(drag)
		check(Input.is_action_pressed("shoot") and not Input.is_action_pressed("reverse"), "Button ownership survives drift without switching actions")
		touch(5, drag.position, false)
		check(Input.is_action_pressed("shoot"), "Second finger keeps shared button held")
		var canceled := InputEventScreenTouch.new()
		canceled.index = 7
		canceled.pressed = true
		canceled.canceled = true
		viewport.push_input(canceled)
		check(not Input.is_action_pressed("shoot") and Input.is_action_pressed("brake"), "Cancellation releases only its action")
		touch(3, center, false)
		touch(4, brake_position, false)
		touch(6, controls._button_center(1), false)
		touch(8, center + Vector2(6, 0), true)
		check(not Input.is_action_pressed("steer_right"), "Center deadzone absorbs thumb jitter")
		touch(8, center, false)
		touch(9, center + Vector2(90, 0), true)
		check(is_equal_approx(Input.get_action_strength("steer_right"), 1.0), "Full joystick travel reaches full steering")
		controls._layout_buttons()
		check(not Input.is_action_pressed("steer_right") and controls.get("_finger") == -1, "Relayout releases active touches")

	Input.action_press("brake")
	var obstacle = load("res://scripts/obstacle.gd").new()
	game.add_child(obstacle)
	obstacle.global_position = Vector3(0, 0.7, 0)
	await frames(2)
	var projectile = load("res://scripts/projectile.gd").new()
	projectile.direction = Vector3.FORWARD
	projectile.shooter = kart.get_rid()
	game.add_child(projectile)
	projectile.global_position = Vector3(0, 0.7, 5)
	await frames(12)
	check(not is_instance_valid(obstacle), "Projectile destroys a box")
	check(not is_instance_valid(projectile), "Projectile consumed by impact")
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 3, 3)
	collision.shape = shape
	wall.add_child(collision)
	game.add_child(wall)
	wall.position = Vector3(10, 1, 0)
	await frames(2)
	var wall_shot = load("res://scripts/projectile.gd").new()
	wall_shot.direction = Vector3.RIGHT
	wall_shot.shooter = kart.get_rid()
	game.add_child(wall_shot)
	wall_shot.global_position = Vector3(7, 1, 0)
	await frames(8)
	check(not is_instance_valid(wall_shot), "Fast projectile stops at thin wall without tunneling")
	var leftover = load("res://scripts/projectile.gd").new()
	leftover.shooter = kart.get_rid()
	game.add_child(leftover)
	leftover.global_position = Vector3(0, 20, 0)
	game.reset_race()
	await frames(2)
	check(get_nodes_in_group("projectiles").is_empty(), "Race reset clears remaining projectiles")
	check(get_nodes_in_group("obstacles").size() == 14, "Race reset restores fourteen obstacles")
	game.started = true
	kart.position = Vector3(30, 0.7, 1)
	game._process(0.1)
	check(game.lap == 0, "Checkpoint skipping cannot finish a lap")
	game.reset_race()
	game.started = true
	for lap_index in range(3):
		for point in game.checkpoints.slice(0, 3):
			kart.position = point + Vector3.UP * 0.7
			game._process(0.1)
		kart.position = Vector3(30, 0.7, -1)
		game._process(0.1)
		kart.position.z = 1
		game._process(0.1)
	check(game.finished and not kart.enabled, "Three ordered laps finish and disable driving")
	Input.action_release("brake")
	await frames(30)
	check(absf(kart.speed) < 0.01, "Finish prevents automatic acceleration")
	game.reset_race()
	Input.action_press("brake")
	game.started = true
	kart.position = game.checkpoints[0] + Vector3.UP * 0.7
	game._process(0.1)
	var recovery_origin: Vector3 = kart.spawn_transform.origin
	kart.position.y = -20
	await frames(5)
	check(kart.position.distance_to(recovery_origin) < 2 and absf(kart.speed) < 0.01, "Recovery resets at checkpoint with stopped kart")
	Input.action_release("brake")
	if controls != null:
		Input.action_press("steer_left", 0.5)
		Input.action_press("shoot")
		controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(not Input.is_action_pressed("steer_left") and not Input.is_action_pressed("shoot"), "Focus loss clears joystick and shoot")
		controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	print("MiniKarts v0.2 test: %d failures" % failures)
	quit(0 if failures == 0 else 1)
