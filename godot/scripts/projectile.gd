extends Node3D

var direction: Vector3 = Vector3.FORWARD
var shooter: RID
var life: float = 2.0
const DISPLAY_HEIGHT := 1.5

func _ready() -> void:
	add_to_group("projectiles")
	# Deferred: the shooter/network renderer assigns position after add_child.
	call_deferred("sound_shot")
	var photo := Sprite3D.new()
	photo.name = "PhotoProjectile"
	photo.texture = preload("res://assets/memes/projectile.png")
	photo.pixel_size = DISPLAY_HEIGHT / float(photo.texture.get_height())
	photo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	photo.shaded = false
	photo.position.y = 0.55
	add_child(photo)

func _physics_process(delta: float) -> void:
	var next: Vector3 = global_position + direction * 55.0 * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next)
	query.exclude = [shooter]
	query.hit_from_inside = true
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		Sound.play_effect("impact", global_position)
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

func sound_shot() -> void:
	Sound.play_effect("shoot", global_position)
