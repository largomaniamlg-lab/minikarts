extends StaticBody3D

const Scenery=preload("res://scripts/scenario_theme.gd")
var theme_id:=0
var destroyed: bool = false

func _ready() -> void:
	add_to_group("obstacles")
	add_to_group("destructible")
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, 1.4, 1.4)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	if theme_id==1:
		var barrel:=CylinderShape3D.new()
		barrel.radius=0.68; barrel.height=1.4
		collision.shape=barrel
	add_child(collision)
	if theme_id>0:
		var body_color=[Color.WHITE,Color("789898"),Color("997047"),Color("d78046"),Color("42516f")][theme_id]
		if theme_id==1:
			Scenery.cylinder(self,0.68,1.4,Vector3.ZERO,Scenery.surface(body_color))
			for height in [-0.45,0.45]: Scenery.cylinder(self,0.71,0.16,Vector3(0,height,0),Scenery.surface(Color("e3c34a")))
		else:
			Scenery.block(self,shape.size,Vector3.ZERO,Scenery.surface(body_color))
			Scenery.block(self,Vector3(1.43,0.18,1.43),Vector3.ZERO,Scenery.surface(Scenery.ACCENTS[theme_id]))
		Scenery.badge(self,theme_id,Vector3(0,0,0.72),0.85)
		return
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
	Sound.play_effect("box", global_position)
	destroyed = true
	remove_from_group("destructible")
	remove_from_group("obstacles")
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	hide()
	queue_free()
