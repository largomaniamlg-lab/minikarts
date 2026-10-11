extends Node3D

var direction: Vector3 = Vector3.FORWARD
var shooter: RID
var life: float = 2.0

func _ready() -> void:
	add_to_group("projectiles")
	var visual := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	visual.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffd447")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = material
	add_child(visual)

func _physics_process(delta: float) -> void:
	var next: Vector3 = global_position + direction * 55.0 * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next)
	query.exclude = [shooter]
	query.hit_from_inside = true
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		var target: Object = result.collider
		if target.is_in_group("destructible") and target.has_method("hit"):
			target.call("hit")
		elif target.has_method("receive_hit"):
			target.call("receive_hit")
		queue_free()
		return
	global_position = next
	life -= delta
	if life <= 0.0:
		queue_free()
