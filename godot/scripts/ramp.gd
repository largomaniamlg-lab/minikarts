extends StaticBody3D
var length := 7.0
var width := 7.0
var height := 1.2
var dangerous := false
var theme_id:=0
var safe_spawn := Transform3D.IDENTITY

func _ready() -> void:
	add_to_group("ramps")
	var vertices := PackedVector3Array([Vector3(-width/2,0,length/2),Vector3(width/2,0,length/2),Vector3(width/2,height,-length/2),Vector3(-width/2,height,-length/2),Vector3(-width/2,0,-length/2),Vector3(width/2,0,-length/2)])
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [0,2,1,0,3,2,3,5,2,3,4,5]:
		mesh.add_vertex(vertices[index])
	mesh.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = mesh.commit()
	var surface := StandardMaterial3D.new()
	surface.albedo_color = preload("res://scripts/scenario_theme.gd").ACCENTS[theme_id] if theme_id>0 else (Color("ed7046") if dangerous else Color("329ad2"))
	visual.material_override = surface
	add_child(visual)
	var trigger := Area3D.new()
	trigger.position = Vector3(0,height+0.7,-length/2+0.15)
	trigger.collision_layer = 0
	trigger.collision_mask = 1
	var detector := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width,1.5,0.5)
	detector.shape = box
	trigger.add_child(detector)
	add_child(trigger)
	trigger.body_entered.connect(func(body):
		if body.has_method("launch_from_ramp") and body.enabled and body.hit_time <= 0:
			body.spawn_transform = safe_spawn
			var fast: bool = body.speed >= body.MAX_SPEED*0.98
			body.launch_from_ramp(5.4 if dangerous and fast else (2.0 if dangerous else 4.3))
	)
	var sign := Label3D.new()
	sign.text = "65 km/h · HUECO" if dangerous else ("RAMPA DE CARGA" if theme_id==1 else "RAMPA")
	sign.font_size = 36
	sign.pixel_size = 0.015
	sign.position = Vector3(0,3.8,length/2+8)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(sign)
