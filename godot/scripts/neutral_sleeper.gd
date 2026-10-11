extends Area3D

var elapsed := 0.0
const ANGLE := 1.7
const SIZE_MULTIPLIER := 1.875
const DISPLAY_WIDTH := 4.0 * SIZE_MULTIPLIER
const PATH_HEIGHT := 0.75

func _ready() -> void:
	name = "NeutralSleeper"
	add_to_group("neutral_hazards")
	collision_layer = 0
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.5, 1.15, 2.3) * SIZE_MULTIPLIER
	collider.shape = shape
	collider.position.y = shape.size.y * 0.5 - PATH_HEIGHT
	add_child(collider)
	var sprite := Sprite3D.new()
	sprite.texture = preload("res://assets/memes/jordan.png")
	sprite.pixel_size = DISPLAY_WIDTH / float(sprite.texture.get_width())
	# Keep the enlarged cutout above the road without changing the network path.
	sprite.position.y = sprite.texture.get_height() * sprite.pixel_size * 0.5 - PATH_HEIGHT
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	add_child(sprite)
	reset_path()

func reset_path() -> void:
	elapsed = 0.0
	position = get_parent().track_point(ANGLE, 30.0, PATH_HEIGHT)
	reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	# The server determines the position and hits in each isolated room.
	if Network.playing and not Network.server_mode:
		return
	elapsed += delta
	position = get_parent().track_point(ANGLE, 30.0 + 6.5 * sin(elapsed * 0.85), PATH_HEIGHT)
	for body in get_overlapping_bodies():
		if body.has_method("receive_hit"):
			body.receive_hit()
