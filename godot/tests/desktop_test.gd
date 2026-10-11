extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func run_checks() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	var kart = game.kart
	check(not kart._touch_driving, "Desktop mode")
	Input.action_press("reverse")
	await frames(30)
	check(kart.speed < -1.0, "B action moves backward on desktop")
	Input.action_release("reverse")
	game.reset_race()
	Input.action_press("accelerate")
	await frames(30)
	check(kart.speed > 1.0, "Desktop accelerates")
	Input.action_press("brake")
	await frames(5)
	check(kart.speed < 5.0, "Brake takes priority over throttle")
	Input.action_release("brake")
	Input.action_release("accelerate")
	game.reset_race()
	Input.action_press("accelerate")
	await frames(30)
	var before_jump: float = kart.speed
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	check(not Input.is_action_pressed("handbrake"), "Space does not apply handbrake")
	check(not kart.is_on_floor() and kart.velocity.y > 0.0, "Space jumps")
	check(kart.speed >= before_jump, "Jump preserves forward acceleration")
	event.pressed = false
	Input.parse_input_event(event)
	Input.action_release("accelerate")
	Input.action_press("handbrake")
	var before_brake: float = kart.speed
	await frames(5)
	check(kart.speed < before_brake, "Separate handbrake still works")
	Input.action_release("handbrake")
	print("MiniKarts desktop test: %d failures" % failures)
	quit(0 if failures == 0 else 1)
