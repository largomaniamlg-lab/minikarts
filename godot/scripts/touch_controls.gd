extends Control

const ACTIONS: Array[StringName] = [&"accelerate", &"brake", &"reverse", &"jump", &"shoot", &"steer_left", &"steer_right", &"reset", &"restart_race"]
var _buttons: Array[TouchScreenButton] = []
const JOYSTICK_RADIUS: float = 90.0
const DEADZONE: float = 0.08
const RESPONSE_CURVE: float = 1.4
var _button_fingers: Dictionary = {}
var _normal_textures: Array[Texture2D] = []
var _pressed_textures: Array[Texture2D] = []
var _joystick_center := Vector2.ZERO
var _joystick_offset := Vector2.ZERO
var _finger: int = -1
var _focused: bool = true
var _test_clock := 0.0
var _test_mode := false

static func is_touch_mode() -> bool:
	return OS.has_feature("mobile") or "--force-touch" in OS.get_cmdline_user_args()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = is_touch_mode()
	if not visible:
		return
	if OS.has_feature("web"):
		_test_mode = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).has('test')"))
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
	button.set_meta("action", action_name)
	button.texture_normal = _texture(dimensions, Color(color.r, color.g, color.b, 0.85))
	button.texture_pressed = _texture(dimensions, color.lightened(0.25))
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions + Vector2(12, 12)
	button.shape = rectangle
	button.shape_centered = true
	button.passby_press = false
	add_child(button)
	button.set_process_input(false)
	_buttons.append(button)
	_normal_textures.append(button.texture_normal)
	_pressed_textures.append(button.texture_pressed)
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
	release_actions()
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
		if not event.pressed or event.canceled:
			if event.index == _finger:
				_clear_joystick()
			if _button_fingers.has(event.index):
				var button_index: int = _button_fingers[event.index]
				_button_fingers.erase(event.index)
				_update_button(button_index)
		elif event.index != _finger and not _button_fingers.has(event.index):
			for index in range(_buttons.size()):
				var button := _buttons[index]
				var dimensions := _normal_textures[index].get_size()
				if button.visible and Rect2(button.position - Vector2(6, 6), dimensions + Vector2(12, 12)).has_point(point):
					_button_fingers[event.index] = index
					_update_button(index)
					return
			if _finger == -1 and point.distance_to(_joystick_center) <= JOYSTICK_RADIUS + 20.0:
				_finger = event.index
				_move_joystick(point)
	elif event is InputEventScreenDrag and event.index == _finger:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_move_joystick(point)

func _update_button(index: int) -> void:
	var held := _button_fingers.values().has(index)
	var button := _buttons[index]
	var action: String = button.get_meta("action")
	if held:
		Input.action_press(action)
	else:
		Input.action_release(action)
	button.texture_normal = _pressed_textures[index] if held else _normal_textures[index]

func _button_center(index: int) -> Vector2:
	return _buttons[index].global_position + _normal_textures[index].get_size() / 2.0

func _move_joystick(point: Vector2) -> void:
	_joystick_offset = (point - _joystick_center).limit_length(JOYSTICK_RADIUS)
	var axis: float = clampf((point.x - _joystick_center.x) / JOYSTICK_RADIUS, -1.0, 1.0)
	if absf(axis) > DEADZONE:
		var strength: float = pow((absf(axis) - DEADZONE) / (1.0 - DEADZONE), RESPONSE_CURVE)
		Input.action_release("steer_right" if axis < 0 else "steer_left")
		Input.action_press("steer_left" if axis < 0 else "steer_right", strength)
	else:
		Input.action_release("steer_left")
		Input.action_release("steer_right")
	queue_redraw()

func _clear_joystick() -> void:
	_finger = -1
	_joystick_offset = Vector2.ZERO
	Input.action_release("steer_left")
	Input.action_release("steer_right")
	queue_redraw()

func release_actions() -> void:
	_clear_joystick()
	_button_fingers.clear()
	for index in range(_buttons.size()):
		_update_button(index)
	for action_name: StringName in ACTIONS:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)

# Browser-only evidence for actual multitouch delivery, disabled in normal play.
func _process(delta: float) -> void:
	if not _test_mode:
		return
	_test_clock += delta
	if _test_clock < 0.1:
		return
	_test_clock = 0.0
	var strengths := {}
	for action_name in ACTIONS:
		strengths[action_name] = Input.get_action_strength(action_name)
	var contacts := _button_fingers.size() + (1 if _finger != -1 else 0)
	JavaScriptBridge.eval("window.minikartsTouchTest = " + JSON.stringify({"contacts": contacts, "actions": strengths}) + ";")

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
