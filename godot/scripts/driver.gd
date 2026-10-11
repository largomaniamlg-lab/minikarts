extends Node3D

var kart: CharacterBody3D
var body: Node3D

func _ready() -> void:
	body = Node3D.new()
	body.name = "AnimatedBody"
	add_child(body)
	part(Vector3(0.48, 0.55, 0.30), Vector3(0, 0.48, 0.25), Color("e5b83b"))
	for side: float in [-1.0, 1.0]:
		part(Vector3(0.16, 0.18, 0.50), Vector3(side * 0.17, 0.12, -0.05), Color("254c4b"))
		part(Vector3(0.17, 0.17, 0.22), Vector3(side * 0.17, 0.10, -0.34), Color("33875a"))
		part(Vector3(0.14, 0.16, 0.47), Vector3(side * 0.29, 0.51, -0.03), Color("e5b83b"))
		part(Vector3(0.17, 0.17, 0.16), Vector3(side * 0.29, 0.50, -0.30), Color("33875a"))
	var face := Sprite3D.new()
	face.name = "PhotoFace"
	face.texture = preload("res://assets/drivers/friend_face.png")
	face.pixel_size = 0.00065
	face.position = Vector3(0, 1.10, 0.20)
	face.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	face.shaded = false
	face.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(face)

func part(dimensions: Vector3, offset: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	visual.position = offset
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	body.add_child(visual)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(kart):
		return
	# Only the body leans; the photographic expression and head remain fixed.
	body.rotation.z = -float(kart.get("_steering")) * 0.16
	body.rotation.x = clampf(kart.velocity.y * 0.015, -0.12, 0.12)
