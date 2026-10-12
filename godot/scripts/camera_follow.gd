extends Camera3D

var target: CharacterBody3D
var _initialized: bool = false
const FOLLOW_DISTANCE: float = 5.8
const FOLLOW_HEIGHT: float = 3.6

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if Network.server_mode:
		set_process(false)
		return
	top_level = true
	fov = 65.0
	near = 0.15
	far = 300.0
	reset_follow()

func reset_follow() -> void:
	_initialized = false
	if not is_instance_valid(target):
		return
	global_position = target.global_position + target.global_basis.z * FOLLOW_DISTANCE + Vector3.UP * FOLLOW_HEIGHT
	look_at(target.global_position + Vector3.UP * 0.6, Vector3.UP)
	reset_physics_interpolation()

func _process(delta: float) -> void:
	follow(delta)

func follow(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var pose := target.global_transform if Network.playing else target.get_global_transform_interpolated()
	var focus: Vector3 = pose.origin + Vector3.UP * 0.6
	var desired: Vector3 = pose.origin + pose.basis.z * FOLLOW_DISTANCE + Vector3.UP * FOLLOW_HEIGHT
	var candidate: Vector3 = desired
	if _initialized and global_position.distance_to(desired) < 20.0:
		candidate = global_position.lerp(desired, 1.0 - exp(-8.0 * delta))
	var query := PhysicsRayQueryParameters3D.create(focus, candidate)
	var excluded: Array[RID] = []
	for kart in get_tree().get_nodes_in_group("karts"):
		excluded.append(kart.get_rid())
	query.exclude = excluded
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_position: Vector3 = hit["position"]
		var hit_normal: Vector3 = hit["normal"]
		candidate = hit_position + hit_normal * 0.3
	global_position = candidate
	if global_position.distance_squared_to(focus) > 0.01:
		look_at(focus, Vector3.UP)
	_initialized = true
