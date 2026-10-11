extends CanvasLayer

const INK: Color = Color("33414f")
const WHITE: Color = Color("f2f5f7")
const RED: Color = Color("e4483c")
const YELLOW: Color = Color("ffc93c")
const GREEN: Color = Color("5bbf6a")
var stats: Label
var message: Label
var speed_number: Label
var _message_panel: PanelContainer
const TouchControls = preload("res://scripts/touch_controls.gd")
var _touch_mode: bool = false

func _ready() -> void:
	_touch_mode = TouchControls.is_touch_mode()
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var timing := _panel(root, Vector2.ZERO, Rect2(24, 24, 400, 108))
	var timing_column := VBoxContainer.new()
	timing_column.add_theme_constant_override("separation", 4)
	timing.add_child(timing_column)
	timing_column.add_child(_label("MINIKARTS / CIRCUITO DE JUGUETE", 18, YELLOW))
	stats = _label("VUELTA 1 / 3\nTIEMPO 0.00 s    MEJOR --", 18, WHITE)
	timing_column.add_child(stats)
	var controls := _panel(root, Vector2(0, 1), Rect2(24, -122, 510, 98))
	controls.visible = not _touch_mode
	var help_column := VBoxContainer.new()
	help_column.add_theme_constant_override("separation", 5)
	controls.add_child(help_column)
	help_column.add_child(_label("R RECUPERA  /  ESPACIO SALTA  /  F DISPARA", 15, YELLOW))
	help_column.add_child(_label("W / ↑ ACELERA     A D / ← → GIRA", 18, WHITE))
	help_column.add_child(_label("S / ↓ FRENA     B ATRÁS     SHIFT FRENO DE MANO", 15, WHITE))
	var speed_panel := _panel(root, Vector2(1, 0) if _touch_mode else Vector2.ONE, Rect2(-234, 24, 210, 126) if _touch_mode else Rect2(-234, -150, 210, 126))
	var speed_column := VBoxContainer.new()
	speed_column.add_theme_constant_override("separation", 0)
	speed_panel.add_child(speed_column)
	var stripe := HBoxContainer.new()
	stripe.add_theme_constant_override("separation", 0)
	stripe.custom_minimum_size.y = 7
	speed_column.add_child(stripe)
	for index: int in range(8):
		var segment := ColorRect.new()
		segment.color = RED if index % 2 == 0 else WHITE
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stripe.add_child(segment)
	speed_number = _label("0", 52, WHITE)
	speed_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_column.add_child(speed_number)
	var unit := _label("km/h", 18, YELLOW)
	unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speed_column.add_child(unit)
	_message_panel = _panel(root, Vector2(0.5, 0.5), Rect2(-290, -154, 580, 74))
	message = _label("Aceleración automática. Joystick para girar." if _touch_mode else "Pulsa W o ↑ para salir. Mantén el centro a tu derecha.", 20, YELLOW)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_panel.add_child(message)
	var touch_controls := TouchControls.new()
	root.add_child(touch_controls)

func _panel(root: Control, anchor: Vector2, bounds: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	panel.anchor_left = anchor.x
	panel.anchor_right = anchor.x
	panel.anchor_top = anchor.y
	panel.anchor_bottom = anchor.y
	panel.offset_left = bounds.position.x
	panel.offset_top = bounds.position.y
	panel.offset_right = bounds.end.x
	panel.offset_bottom = bounds.end.y
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK.r, INK.g, INK.b, 0.8)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.09, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	return label

func update_display(lap: int, elapsed: float, best: float, speed: float, finished: bool, started: bool, recovered: bool, lap_target: int = 3) -> void:
	var best_text: String = "--" if best == INF else "%.2f s" % best
	stats.text = "VUELTA %d / %d\nTIEMPO %.2f s    MEJOR %s" % [mini(lap, lap_target), lap_target, elapsed, best_text]
	speed_number.text = "%d" % roundi(absf(speed))
	_message_panel.visible = finished or recovered or not started
	if finished:
		message.text = "¡META!\nToca NUEVA CARRERA." if _touch_mode else "¡META!\nPulsa Enter para otra carrera."
		message.add_theme_color_override("font_color", GREEN)
	elif recovered:
		message.text = "De vuelta en la pista.\nEl reloj sigue corriendo."
		message.add_theme_color_override("font_color", WHITE)
	elif not started:
		message.text = "Aceleración automática. Mueve el joystick para girar.\nFRENO frena · SALTO salta · DISPARO dispara." if _touch_mode else "Pulsa W o ↑ para salir.\nMantén el centro de la pista a tu derecha."
		message.add_theme_color_override("font_color", YELLOW)
