extends Camera3D

var target: CharacterBody3D
var _initialized: bool = false

func _ready() -> void:
	top_level = true
	fov = 65.0
	near = 0.15
	far = 300.0
	reset_follow()

func reset_follow() -> void:
	_initialized = false
	if not is_instance_valid(target):
		return
	global_position = target.global_position + target.global_basis.z * 7.0 + Vector3.UP * 4.3
	look_at(target.global_position + Vector3.UP * 0.6, Vector3.UP)
	reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var focus: Vector3 = target.global_position + Vector3.UP * 0.6
	var desired: Vector3 = target.global_position + target.global_basis.z * 7.0 + Vector3.UP * 4.3
	var candidate: Vector3 = desired
	if _initialized and global_position.distance_to(desired) < 20.0:
		candidate = global_position.lerp(desired, 1.0 - exp(-8.0 * delta))
	var query := PhysicsRayQueryParameters3D.create(focus, candidate)
	query.exclude = [target.get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_position: Vector3 = hit["position"]
		var hit_normal: Vector3 = hit["normal"]
		candidate = hit_position + hit_normal * 0.3
	global_position = candidate
	if global_position.distance_squared_to(focus) > 0.01:
		look_at(focus, Vector3.UP)
	_initialized = true
