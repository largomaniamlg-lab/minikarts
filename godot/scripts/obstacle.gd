extends StaticBody3D

var destroyed: bool = false

func _ready() -> void:
	add_to_group("obstacles")
	add_to_group("destructible")
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, 1.4, 1.4)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color("ffc93c")
	surface.roughness = 0.85
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = surface
	add_child(visual)
	var band_material := StandardMaterial3D.new()
	band_material.albedo_color = Color("e4483c")
	for band_size: Vector3 in [Vector3(1.43, 0.2, 1.43), Vector3(0.2, 1.43, 1.43)]:
		var band_mesh := BoxMesh.new()
		band_mesh.size = band_size
		var band := MeshInstance3D.new()
		band.mesh = band_mesh
		band.material_override = band_material
		add_child(band)

func hit() -> void:
	if destroyed:
		return
	destroyed = true
	remove_from_group("destructible")
	remove_from_group("obstacles")
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	hide()
	queue_free()
