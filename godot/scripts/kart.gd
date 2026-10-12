extends CharacterBody3D

var speed: float = 0.0
var enabled: bool = true
var spawn_transform: Transform3D
var _steering: float = 0.0
var _camera: Camera3D
var _body_visual: MeshInstance3D
var _shadow_visual: MeshInstance3D
const Handling = preload("res://scripts/handling.gd")
const MAX_SPEED: float = 65.0 / 3.6
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
var _ramp_launch := 0.0

func launch_from_ramp(lift: float) -> void:
	_ramp_launch = lift


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
	add_to_group("karts")
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
	_build_body()

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
		_steering = Handling.steer(_steering, steer_input, delta)
		rotate_y(Handling.turn(_steering, speed, delta))
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
	if _ramp_launch > 0:
		velocity.y = maxf(velocity.y,_ramp_launch)
		_ramp_launch = 0.0
		Sound.play_effect("jump",global_position)
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
	_ramp_launch = 0.0
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
	material.roughness = 0.42
	return material

func _add_box(size: Vector3, offset: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = offset
	mesh_instance.material_override = _material(color)
	add_child(mesh_instance)

func _rounded_part(dimensions: Vector3, offset: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 10
	part.mesh = mesh
	part.scale = dimensions
	part.position = offset
	part.material_override = _material(color)
	add_child(part)
	return part

func _build_body() -> void:
	_build_shadow()
	# Presentation geometry only: the original collision box and driving stay unchanged.
	_body_visual = _rounded_part(Vector3(1.35, 0.42, 1.95), Vector3(0, 0, 0), kart_color)
	_rounded_part(Vector3(1.05, 0.38, 0.75), Vector3(0, 0.15, -0.62), kart_color.lightened(0.10))
	_rounded_part(Vector3(0.68, 0.55, 0.55), Vector3(0, 0.25, 0.35), Color("172638"))
	_rounded_part(Vector3(0.20, 0.10, 0.8), Vector3(0, 0.32, -0.60), Color("fff5dd"))
	_rounded_part(Vector3(1.30, 0.16, 0.25), Vector3(0, -0.10, -0.90), Color("f1c746"))
	for x: float in [-0.71, 0.71]:
		for z: float in [-0.58, 0.58]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.29
			cylinder.bottom_radius = 0.29
			cylinder.height = 0.25
			cylinder.radial_segments = 16
			wheel.mesh = cylinder
			wheel.rotation.z = PI / 2.0
			wheel.position = Vector3(x, -0.14, z)
			wheel.material_override = _material(Color("171e29"))
			add_child(wheel)
			_rounded_part(Vector3(0.07, 0.32, 0.32), Vector3(x + signf(x) * 0.135, -0.14, z), Color("bac7d6"))
		_rounded_part(Vector3(0.19, 0.19, 0.23), Vector3(x * 0.62, 0.02, 0.96), Color("f05a3f"))
		var exhaust := MeshInstance3D.new()
		var pipe := CylinderMesh.new()
		pipe.top_radius = 0.11
		pipe.bottom_radius = 0.14
		pipe.height = 0.28
		pipe.radial_segments = 12
		exhaust.mesh = pipe
		exhaust.rotation.x = PI / 2.0
		exhaust.position = Vector3(x * 0.50, -0.12, 0.92)
		exhaust.material_override = _material(Color("abb6c6"))
		add_child(exhaust)
		_rounded_part(Vector3(0.16, 0.16, 0.025), Vector3(x * 0.50, -0.12, 1.07), Color("192633"))

func _build_shadow() -> void:
	_shadow_visual = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.9, 2.5)
	_shadow_visual.mesh = plane
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var radius := Vector2((x - 15.5) / 15.5, (y - 15.5) / 15.5).length()
			image.set_pixel(x, y, Color(0.05, 0.09, 0.12, maxf(0.0, 1.0 - radius) * 0.36))
	var surface := StandardMaterial3D.new()
	surface.albedo_texture = ImageTexture.create_from_image(image)
	surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shadow_visual.material_override = surface
	add_child(_shadow_visual)

func _process(_delta: float) -> void:
	if is_instance_valid(_shadow_visual):
		_shadow_visual.position.y = 0.04 - global_position.y
