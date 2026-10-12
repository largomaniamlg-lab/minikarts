extends Control
@export var scale_demo := false
static func logical_safe_rect(safe: Rect2, screen_size: Vector2, viewport_size: Vector2) -> Rect2:
	if screen_size.x<=0 or screen_size.y<=0 or safe.size.x<=0 or safe.size.y<=0: return Rect2(Vector2.ZERO,viewport_size)
	var ratio=viewport_size/screen_size
	return Rect2(safe.position*ratio,safe.size*ratio)
func _ready() -> void: call_deferred("layout")
func layout() -> void:
	if not (OS.has_feature("android") or OS.has_feature("ios")): return
	var screen_size=Vector2(DisplayServer.screen_get_size())
	var safe=logical_safe_rect(Rect2(DisplayServer.get_display_safe_area()),screen_size,get_viewport_rect().size)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position=safe.position
	if scale_demo:
		size=Vector2(1280,720); scale=safe.size/size
	else: size=safe.size
