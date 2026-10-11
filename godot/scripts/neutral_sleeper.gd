extends Area3D

var elapsed := 0.0
const ANGLE := 1.7

func _ready() -> void:
	name = "NeutralSleeper"
	add_to_group("neutral_hazards")
	collision_layer = 0
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.5, 1.15, 2.3)
	collider.shape = shape
	add_child(collider)
	var sprite := Sprite3D.new()
	sprite.texture = preload("res://assets/memes/sleeper.png")
	sprite.pixel_size = 4.0 / float(sprite.texture.get_width())
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	add_child(sprite)
	reset_path()

func reset_path() -> void:
	elapsed = 0.0
	position = get_parent().track_point(ANGLE, 30.0, 0.75)
	reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	# The server determines the position and hits in each isolated room.
	if Network.playing and not Network.server_mode:
		return
	elapsed += delta
	position = get_parent().track_point(ANGLE, 30.0 + 6.5 * sin(elapsed * 0.85), 0.75)
	for body in get_overlapping_bodies():
		if body.has_method("receive_hit"):
			body.receive_hit()
