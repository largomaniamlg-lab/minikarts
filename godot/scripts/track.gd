extends Node3D

const SEGMENTS: int = 96
const Obstacle = preload("res://scripts/obstacle.gd")

func _ready() -> void:
	var grass := material(Color("76bc4c"))
	var asphalt := material(Color("505968"))
	var white := material(Color("fff4d8"))
	var coral := material(Color("ed5046"))
	var blue := material(Color("4d99c7"))
	box("Ground", Vector3(120, 1, 120), Vector3(0, -0.5, 0), grass, true)
	annulus(21.0, 39.0, 0.018, asphalt)
	annulus(20.8, 21.15, 0.03, white)
	annulus(38.85, 39.2, 0.03, white)
	for i in range(SEGMENTS):
		var angle := TAU * float(i) / float(SEGMENTS)
		var next_angle: float = TAU * float(i + 1) / float(SEGMENTS)
		for radius: float in [20.5, 39.5]:
			var start: Vector3 = track_point(angle, radius, 0.55)
			var end: Vector3 = track_point(next_angle, radius, 0.55)
			var direction: Vector3 = end - start
			var barrier := box("Barrier", Vector3(direction.length() + 0.12, 1.1, 0.45), (start + end) * 0.5, coral if i % 2 == 0 else white, true)
			barrier.rotation.y = -atan2(direction.z, direction.x)
	for i in range(48):
		var angle := TAU * float(i) / 48.0
		var stripe := box("LaneStripe", Vector3(1.1, 0.025, 0.16), track_point(angle, 30.0, 0.045), white)
		var tangent: Vector3 = track_point(angle + 0.01, 30.0, 0.045) - track_point(angle, 30.0, 0.045)
		stripe.rotation.y = -atan2(tangent.z, tangent.x)
	for x in range(18):
		for z in range(2):
			box("FinishTile", Vector3(1, 0.025, 0.65), Vector3(21.5 + x, 0.065, -0.325 + z * 0.65), white if (x + z) % 2 == 0 else asphalt)
	# Trees use only original primitive geometry, safely outside the driving area.
	var bark := material(Color("835342"))
	var foliage := material(Color("49a94b"))
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		var radius := 47.0 + float(i % 3)
		var position := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		box("Trunk", Vector3(0.45, 2.0, 0.45), position + Vector3(0, 1, 0), bark)
		for tuft in range(3):
			var crown := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 1.35
			sphere.height = 2.7
			sphere.radial_segments = 16
			sphere.rings = 8
			crown.mesh = sphere
			crown.material_override = foliage
			crown.position = position + Vector3((tuft - 1) * 0.9, 2.8 + (0.9 if tuft == 1 else 0.0), 0)
			add_child(crown)
	_build_scenery()

	for tier in range(3):
		box("Grandstand", Vector3(13, 0.6, 1.5), Vector3(0, 0.3 + tier * 0.6, -48 - tier * 1.5), blue if tier % 2 == 0 else white)
	box("InfieldAccent", Vector3(8, 0.15, 5), Vector3(0, 0.075, 0), blue)
	_build_obstacles()
	var sleeper := preload("res://scripts/neutral_sleeper.gd").new()
	add_child(sleeper)
	for i in range(12):
		var decoration := Sprite3D.new()
		decoration.texture = preload("res://assets/memes/legs.png")
		decoration.pixel_size = 6.0 / float(decoration.texture.get_height())
		decoration.position = track_point(TAU * float(i) / 12.0, 44.0, 3.0)
		decoration.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		decoration.shaded = false
		decoration.name = "LegTree%d" % i
		add_child(decoration)

func track_point(angle: float, base_radius: float = 30.0, height: float = 0.0) -> Vector3:
	var radius: float = base_radius + 3.0 * sin(3.0 * angle)
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)

func _build_obstacles() -> void:
	var yellow := material(Color("ffc93c"))
	for index: int in range(6):
		var angle: float = 0.65 + float(index) * 0.90
		var offset: float = -3.5 if index % 2 == 0 else 3.5
		var low := box("JumpBlock", Vector3(4.0, 0.55, 1.1), track_point(angle, 30.0 + offset, 0.275), yellow, true)
		low.rotation.y = -angle
		low.add_to_group("obstacles")
	for index: int in range(8):
		var angle: float = 0.9 + float(index) * 0.65
		var crate := Obstacle.new()
		crate.name = "BreakableCrate"
		crate.position = track_point(angle, 30.0 + (-4.0 if index % 2 == 0 else 4.0), 0.7)
		crate.rotation.y = -angle
		add_child(crate)

func reset_obstacles() -> void:
	if has_node("NeutralSleeper"):
		get_node("NeutralSleeper").reset_path()
	for child in get_children():
		if child.is_in_group("obstacles"):
			remove_child(child)
			child.queue_free()
	_build_obstacles()

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	return result

func box(label: String, size: Vector3, position: Vector3, surface: Material, solid: bool = false) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.name = label
	root.position = position
	add_child(root)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = surface
	root.add_child(visual)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		root.add_child(collision)
	return root

func annulus(inner: float, outer: float, height: float, surface: Material) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(SEGMENTS):
		var a := TAU * float(i) / float(SEGMENTS)
		var b := TAU * float(i + 1) / float(SEGMENTS)
		var p0: Vector3 = track_point(a, inner, height)
		var p1: Vector3 = track_point(a, outer, height)
		var p2: Vector3 = track_point(b, outer, height)
		var p3: Vector3 = track_point(b, inner, height)
		# Godot front faces use clockwise winding when viewed from above.
		for point in [p0, p1, p2, p0, p2, p3]:
			builder.set_normal(Vector3.UP)
			builder.add_vertex(point)
	var visual := MeshInstance3D.new()
	visual.mesh = builder.commit()
	visual.material_override = surface
	add_child(visual)

func _scenery_ball(position: Vector3, dimensions: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	visual.mesh = mesh
	visual.position = position
	visual.scale = dimensions
	visual.material_override = material(color)
	add_child(visual)

func _build_scenery() -> void:
	# No colliders: new scenery cannot block racers, bots, shots or the follow camera.
	for index in range(10):
		var angle := TAU * index / 10.0
		_scenery_ball(Vector3(cos(angle) * 70.0, 1.0, sin(angle) * 70.0), Vector3(22, 12 + index % 3 * 4, 20), Color("84bd63"))
	for index in range(6):
		var angle := TAU * index / 6.0
		for tuft in range(3):
			_scenery_ball(Vector3(cos(angle) * 80.0 + tuft * 3.0, 24 + index % 2 * 4, sin(angle) * 80.0), Vector3(9, 4.0 + (2 if tuft == 1 else 0), 5), Color("f4faff"))
	var gold := material(Color("ffd05b"))
	for x in [20.0, 40.0]:
		box("FinishArchPost", Vector3(0.55, 5.2, 0.55), Vector3(x, 2.6, 0), gold)
	box("FinishArch", Vector3(20.5, 0.85, 0.60), Vector3(30, 5.1, 0), material(Color("329ad2")))
	var text := Label3D.new()
	text.text = "MINIKARTS"
	text.font_size = 64
	text.pixel_size = 0.04
	text.position = Vector3(30, 5.1, -0.33)
	text.modulate = Color("fff0bb")
	text.no_depth_test = false
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
