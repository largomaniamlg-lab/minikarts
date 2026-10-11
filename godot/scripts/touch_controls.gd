extends Control

const ACTIONS: Array[StringName] = [&"accelerate", &"brake", &"reverse", &"jump", &"shoot", &"steer_left", &"steer_right", &"reset", &"restart_race"]
var _buttons: Array[TouchScreenButton] = []
const JOYSTICK_RADIUS: float = 90.0
const DEADZONE: float = 0.15
var _joystick_center := Vector2.ZERO
var _joystick_offset := Vector2.ZERO
var _finger: int = -1
var _focused: bool = true

static func is_touch_mode() -> bool:
	return OS.has_feature("mobile") or "--force-touch" in OS.get_cmdline_user_args()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = is_touch_mode()
	if not visible:
		return
	_add_button("brake", "FRENO", Vector2(110, 90), Color("e4483c"))
	_add_button("jump", "SALTO", Vector2(110, 90), Color("5bbf6a"))
	_add_button("shoot", "DISPARO", Vector2(110, 90), Color("d59732"))
	_add_button("reverse", "ATRÁS", Vector2(110, 56), Color("33414f"))
	_add_button("reset", "RECUPERAR", Vector2(170, 56), Color("33414f"))
	_add_button("restart_race", "NUEVA CARRERA", Vector2(190, 56), Color("33414f"))
	resized.connect(_layout_buttons)
	_layout_buttons()

func _add_button(action_name: String, caption: String, dimensions: Vector2, color: Color) -> void:
	var button := TouchScreenButton.new()
	button.action = action_name
	button.texture_normal = _texture(dimensions, Color(color.r, color.g, color.b, 0.85))
	button.texture_pressed = _texture(dimensions, color.lightened(0.25))
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions
	button.shape = rectangle
	button.shape_centered = true
	button.passby_press = false
	add_child(button)
	_buttons.append(button)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.size = dimensions
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_label.add_theme_font_size_override("font_size", 22)
	caption_label.add_theme_color_override("font_color", Color("f2f5f7"))
	caption_label.add_theme_color_override("font_outline_color", Color("33414f"))
	caption_label.add_theme_constant_override("outline_size", 3)
	button.add_child(caption_label)

func _texture(dimensions: Vector2, color: Color) -> ImageTexture:
	var image := Image.create(int(dimensions.x), int(dimensions.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func _layout_buttons() -> void:
	if _buttons.size() != 6:
		return
	_joystick_center = Vector2(135, size.y - 135)
	_buttons[0].position = Vector2(size.x - 394, size.y - 114)
	_buttons[1].position = Vector2(size.x - 270, size.y - 114)
	_buttons[2].position = Vector2(size.x - 146, size.y - 114)
	_buttons[3].position = Vector2(size.x - 394, size.y - 184)
	_buttons[4].position = Vector2(size.x - 194, 166)
	_buttons[5].position = Vector2(size.x - 404, 166)
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	draw_circle(_joystick_center, JOYSTICK_RADIUS, Color(0.2, 0.26, 0.31, 0.7))
	draw_arc(_joystick_center, JOYSTICK_RADIUS, 0, TAU, 64, Color("f2f5f7"), 3.0, true)
	draw_line(_joystick_center + Vector2(-65, 0), _joystick_center + Vector2(65, 0), Color(1, 1, 1, 0.3), 3.0)
	draw_circle(_joystick_center + _joystick_offset, 33, Color("ffc93c"))

func _input(event: InputEvent) -> void:
	if not visible or not _focused:
		return
	if event is InputEventScreenTouch:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if event.pressed and _finger == -1 and point.distance_to(_joystick_center) <= JOYSTICK_RADIUS + 20.0:
			_finger = event.index
			_move_joystick(point)
		elif not event.pressed and event.index == _finger:
			_clear_joystick()
	elif event is InputEventScreenDrag and event.index == _finger:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_move_joystick(point)

func _move_joystick(point: Vector2) -> void:
	_joystick_offset = (point - _joystick_center).limit_length(JOYSTICK_RADIUS)
	var axis: float = clampf(_joystick_offset.x / JOYSTICK_RADIUS, -1.0, 1.0)
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	if absf(axis) > DEADZONE:
		var strength: float = (absf(axis) - DEADZONE) / (1.0 - DEADZONE)
		Input.action_press("steer_left" if axis < 0 else "steer_right", strength)
	queue_redraw()

func _clear_joystick() -> void:
	_finger = -1
	_joystick_offset = Vector2.ZERO
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	queue_redraw()

func release_actions() -> void:
	_clear_joystick()
	for action_name: StringName in ACTIONS:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		release_actions()
		for button: TouchScreenButton in _buttons:
			button.hide()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
		for button: TouchScreenButton in _buttons:
			button.show()

func _exit_tree() -> void:
	if is_touch_mode():
		release_actions()
