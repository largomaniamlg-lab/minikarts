extends CharacterBody3D

var speed: float = 0.0
var enabled: bool = true
var spawn_transform: Transform3D
var _steering: float = 0.0
var _camera: Camera3D
var _body_visual: MeshInstance3D
const MAX_SPEED: float = 22.0
const CameraFollow = preload("res://scripts/camera_follow.gd")
const TouchControls = preload("res://scripts/touch_controls.gd")
var _touch_driving: bool = false
var _focused: bool = true
var _shot_cooldown: float = 0.0
var network_controlled: bool = false
var controls: Dictionary = {}
var kart_color: Color = Color(0.95, 0.22, 0.08)
var hit_time: float = 0.0
var protection_time: float = 0.0
var _jump_held: bool = false
var _impact_cooldown := 0.0

func strength(action: String) -> float:
	return float(controls.get(action, 0.0)) if network_controlled else Input.get_action_strength(action)

func pressed(action: String) -> bool:
	return strength(action) > 0.5

func receive_hit() -> bool:
	if not enabled or protection_time > 0.0:
		return false
	Sound.play_effect("spin", global_position)
	speed *= 0.25
	hit_time = 1.0
	protection_time = 3.0
	return true

func _ready() -> void:
	_touch_driving = network_controlled or TouchControls.is_touch_mode()
	spawn_transform = global_transform
	floor_snap_length = 0.5
	floor_stop_on_slope = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.25, 0.65, 1.9)
	shape.shape = box
	shape.position.y = -0.085
	add_child(shape)
	_add_box(Vector3(1.25, 0.3, 1.8), Vector3(0, 0, 0), kart_color)
	_add_box(Vector3(0.7, 0.35, 0.6), Vector3(0, 0.28, 0.35), Color(0.08, 0.10, 0.14))
	_add_box(Vector3(1.1, 0.15, 0.45), Vector3(0, 0.18, -0.63), Color(1.0, 0.8, 0.12))
	for x: float in [-0.7, 0.7]:
		for z: float in [-0.58, 0.58]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.27
			cylinder.bottom_radius = 0.27
			cylinder.height = 0.22
			wheel.mesh = cylinder
			wheel.rotation.z = PI / 2.0
			wheel.position = Vector3(x, -0.14, z)
			wheel.material_override = _material(Color(0.055, 0.06, 0.075))
			add_child(wheel)
	var driver = preload("res://scripts/driver.gd").new()
	driver.name = "Driver"
	driver.kart = self
	add_child(driver)
	var camera := CameraFollow.new()
	_camera = camera
	camera.target = self
	add_child(camera)
	camera.current = true

func _physics_process(delta: float) -> void:
	_impact_cooldown = maxf(0, _impact_cooldown - delta)
	protection_time = maxf(0.0, protection_time - delta)
	if hit_time > 0.0:
		rotate_y(TAU * minf(delta, hit_time))
		hit_time = maxf(0.0, hit_time - delta)
	var jump_now: bool = pressed("jump") and not _jump_held if network_controlled else Input.is_action_just_pressed("jump")
	_jump_held = pressed("jump")
	var active: bool = enabled and _focused and hit_time <= 0.0
	var throttle: float = (strength("accelerate") if network_controlled else (1.0 if _touch_driving else strength("accelerate"))) if active else 0.0
	var brake_input: float = strength("brake") if active else 0.0
	if brake_input > 0.0:
		if _touch_driving or speed > 0.0:
			speed = move_toward(speed, 0.0, 24.0 * delta)
		elif not _touch_driving:
			speed = move_toward(speed, -6.0, 6.0 * delta)
	elif active and pressed("reverse"):
		speed = move_toward(speed, -6.0, 12.0 * delta)
	elif throttle > 0.0:
		speed = move_toward(speed, MAX_SPEED, 10.0 * delta)
	else:
		speed = move_toward(speed, 0.0, 4.0 * delta)
	if active and pressed("handbrake"):
		speed = move_toward(speed, 0.0, 32.0 * delta)
	var steer_input: float = (strength("steer_right") - strength("steer_left")) if active else 0.0
	if _touch_driving:
		# Progressive press, quick release; a held arrow follows the broad track curve.
		var steering_rate: float = 12.0 if is_zero_approx(steer_input) else 3.0
		_steering = move_toward(_steering, steer_input, steering_rate * delta)
		rotate_y(-_steering * speed / 22.0 * delta)
	else:
		_steering = move_toward(_steering, steer_input, 5.0 * delta)
		rotate_y(-_steering * 1.6 * clampf(absf(speed) / 7.0, 0.0, 1.0) * signf(speed) * delta)
	var forward: Vector3 = -global_basis.z
	var movement_direction: Vector3 = forward * signf(speed)
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	if is_on_floor() and active and jump_now:
		Sound.play_effect("jump", global_position)
		velocity.y = 8.5
	elif is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y = maxf(velocity.y - 24.0 * delta, -40.0)
	var airborne := not is_on_floor()
	move_and_slide()
	if airborne and is_on_floor():
		Sound.play_effect("land", global_position)
	_shot_cooldown = maxf(0.0, _shot_cooldown - delta)
	if active and pressed("shoot") and _shot_cooldown <= 0.0:
		var projectile = preload("res://scripts/projectile.gd").new()
		projectile.direction = forward
		projectile.shooter = get_rid()
		get_parent().add_child(projectile)
		projectile.global_position = global_position + Vector3.UP * 0.15 + forward * 1.8
		_shot_cooldown = 0.35
	for index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(index)
		var normal: Vector3 = collision.get_normal()
		if absf(normal.y) < 0.5 and movement_direction.dot(normal) < -0.15:
			if absf(speed) > 4 and _impact_cooldown == 0:
				Sound.play_effect("impact", global_position)
				_impact_cooldown = 0.4
			speed = signf(speed) * minf(absf(speed), Vector2(velocity.x, velocity.z).length())
	if global_position.y < -10.0:
		reset_to(spawn_transform)

func reset_to(new_transform: Transform3D) -> void:
	global_transform = new_transform
	enabled = true
	velocity = Vector3.ZERO
	speed = 0.0
	_steering = 0.0
	_shot_cooldown = 0.0
	hit_time = 0.0
	protection_time = 0.0
	_jump_held = false
	reset_physics_interpolation()
	if is_instance_valid(_camera):
		_camera.call("reset_follow")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	return material

func _add_box(size: Vector3, offset: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = offset
	mesh_instance.material_override = _material(color)
	add_child(mesh_instance)
