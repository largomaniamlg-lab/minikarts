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
var circuit_panel: PanelContainer
var circuit_label: Label
var timing_panel: PanelContainer
var time_number: Label
var options: PanelContainer
var options_button: Button
var touch_controls: Control
var _lap := 1
var _lap_target := 3
var _test_clock := 0.0

func _ready() -> void:
	_touch_mode = TouchControls.is_touch_mode()
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	timing_panel = _panel(root, Vector2(0.5, 0) if _touch_mode else Vector2.ZERO, Rect2(-310, 12, 620, 54) if _touch_mode else Rect2(24, 24, 400, 108))
	var timing_row: Container = HBoxContainer.new() if _touch_mode else VBoxContainer.new()
	timing_row.add_theme_constant_override("separation", 18 if _touch_mode else 4)
	timing_panel.add_child(timing_row)
	if not _touch_mode:
		timing_row.add_child(_label("MINIKARTS / CIRCUITO DE JUGUETE", 18, YELLOW))
	stats = _label("VUELTA 1/3" if _touch_mode else "VUELTA 1 / 3\nTIEMPO 0.00 s    MEJOR --", 20 if _touch_mode else 18, WHITE)
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timing_row.add_child(stats)
	if _touch_mode:
		time_number = _label("0:00", 20, WHITE)
		time_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		timing_row.add_child(time_number)
	var controls := _panel(root, Vector2(0, 1), Rect2(24, -122, 510, 98))
	controls.visible = not _touch_mode
	var help_column := VBoxContainer.new()
	help_column.add_theme_constant_override("separation", 5)
	controls.add_child(help_column)
	help_column.add_child(_label("R RECUPERA  /  ESPACIO SALTA  /  F DISPARA", 15, YELLOW))
	help_column.add_child(_label("W / ↑ ACELERA     A D / ← → GIRA", 18, WHITE))
	help_column.add_child(_label("S / ↓ FRENA     B ATRÁS     SHIFT FRENO DE MANO", 15, WHITE))
	var speed_column: VBoxContainer
	if _touch_mode:
		speed_column = null
	else:
		var speed_panel := _panel(root, Vector2.ONE, Rect2(-234, -150, 210, 126))
		speed_column = VBoxContainer.new()
		speed_column.add_theme_constant_override("separation", 0)
		speed_panel.add_child(speed_column)
	speed_number = _label("0 km/h" if _touch_mode else "0", 24 if _touch_mode else 52, WHITE)
	speed_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if _touch_mode else HORIZONTAL_ALIGNMENT_RIGHT
	if _touch_mode:
		speed_number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		timing_row.add_child(speed_number)
	else:
		speed_column.add_child(speed_number)
	if not _touch_mode:
		var unit := _label("km/h", 18, YELLOW)
		unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		speed_column.add_child(unit)
	_message_panel = _panel(root, Vector2(0.5, 0) if _touch_mode else Vector2(0.5, 0.5), Rect2(-310, 74, 620, 56) if _touch_mode else Rect2(-290, -154, 580, 74))
	message = _label("Aceleración automática. Joystick para girar." if _touch_mode else "Pulsa W o ↑ para salir. Mantén el centro a tu derecha.", 20, YELLOW)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_panel.add_child(message)
	touch_controls = TouchControls.new()
	root.add_child(touch_controls)
	if _touch_mode:
		circuit_panel=_panel(root,Vector2.ZERO,Rect2(24,12,278,54))
		circuit_label=_label("",17,WHITE)
		circuit_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		circuit_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		circuit_panel.add_child(circuit_label)
		circuit_panel.hide()
		_build_options(root)

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
	style.set_corner_radius_all(24)
	style.border_color = Color(0.80, 0.90, 1.0, 0.45)
	style.set_border_width_all(2)
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
	_lap = mini(lap, lap_target)
	_lap_target = lap_target
	if _touch_mode:
		stats.text = "VUELTA %d/%d" % [_lap, lap_target]
		time_number.text = "%d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]
	else:
		stats.text = "VUELTA %d / %d\nTIEMPO %.2f s    MEJOR %s" % [_lap, lap_target, elapsed, best_text]
	speed_number.text = ("%d km/h" if _touch_mode else "%d") % roundi(absf(speed))
	_message_panel.visible = finished or recovered or not started
	if finished:
		message.text = "¡META! Espera los resultados de la sala." if Network.playing else ("¡META! Abre Menú para otra carrera." if _touch_mode else "¡META!\nPulsa Enter para otra carrera.")
		message.add_theme_color_override("font_color", GREEN)
	elif recovered:
		message.text = "De vuelta en la pista.\nEl reloj sigue corriendo."
		message.add_theme_color_override("font_color", WHITE)
	elif not started:
		message.text = "Joystick para girar · SALTO salta · DISPARO dispara." if _touch_mode else "Pulsa W o ↑ para salir.\nMantén el centro de la pista a tu derecha."
		message.add_theme_color_override("font_color", YELLOW)

func set_position(rank: int, total: int) -> void:
	if _touch_mode:
		stats.text = "VUELTA %d/%d · PUESTO %d/%d" % [_lap, _lap_target, rank, total]
	else:
		stats.text += "\nPOSICIÓN %d / %d" % [rank, total]

func _build_options(root: Control) -> void:
	options_button = Button.new()
	options_button.text = "Menú"
	root.add_child(options_button)
	options_button.anchor_left = 1
	options_button.anchor_right = 1
	options_button.offset_left = -290
	options_button.offset_right = -180
	options_button.offset_top = 12
	options_button.offset_bottom = 66
	options_button.add_theme_font_size_override("font_size", 22)
	options = _panel(root, Vector2(1, 0), Rect2(-300, 78, 270, 304))
	options.mouse_filter = Control.MOUSE_FILTER_STOP
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	options.add_child(column)
	for caption in ["Recuperar", "Nueva carrera", "Salas online", "Piloto y vueltas", "Sonido"]:
		var button := Button.new()
		button.text = caption
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 20)
		column.add_child(button)
		button.pressed.connect(_choose_option.bind(caption))
	options.hide()
	options_button.pressed.connect(func():
		options.visible = not options.visible
		touch_controls.release_actions()
		if is_instance_valid(Sound.panel):
			Sound.panel.hide()
		var game=get_parent()
		column.get_child(1).text="Reiniciar torneo" if is_instance_valid(game.offline_race) and game.offline_race.tournament!=null else "Nueva carrera"
		column.get_child(1).disabled = Network.playing
		column.get_child(3).disabled = Network.playing
	)

func _choose_option(caption: String) -> void:
	options.hide()
	var game := get_parent()
	match caption:
		"Recuperar":
			if Network.playing:
				Network.pending_reset = true
			elif is_instance_valid(game.offline_race):
				if not game.offline_race.racers[0].finished:
					game.kart.reset_to(game.kart.spawn_transform)
					game.offline_race.racers[0].prev_z = game.get_node("Track").finish_side(game.kart.position)
			else:
				game.recover()
		"Nueva carrera":
			if not Network.playing:
				game.reset_race()
		"Salas online":
			Network.friends_button.pressed.emit()
		"Piloto y vueltas":
			if not Network.playing:
				game.race_menu.open()
		"Sonido":
			if is_instance_valid(Sound.sound_button):
				Sound.sound_button.pressed.emit()

func _process(delta: float) -> void:
	if not Network.browser_test or not _touch_mode:
		return
	_test_clock += delta
	if _test_clock < 0.1:
		return
	_test_clock = 0.0
	var rects := {}
	var nodes := {"timing": timing_panel, "notice": _message_panel, "menu": options_button, "options": options}
	for entry in nodes:
		var node: Control = nodes[entry]
		var rect := node.get_global_rect()
		rects[entry] = {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y, "visible": node.is_visible_in_tree()}
	JavaScriptBridge.eval("window.minikartsHudTest=" + JSON.stringify({"rects": rects, "text": stats.text, "viewport": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y]}) + ";")

func set_circuit(id: int, stage: int=-1) -> void:
	if circuit_panel==null: return
	circuit_panel.visible=id>0 or stage>=0
	var catalog=preload("res://scripts/circuit_catalog.gd")
	if stage==0: circuit_label.text="CLASIFICACIÓN · 3 VUELTAS"
	elif stage>0: circuit_label.text="TORNEO %d/4 · %s" % [stage,catalog.NAMES[id].to_upper()]
	else: circuit_label.text="%s · %d m" % [catalog.NAMES[id].to_upper(),catalog.LENGTHS[id]]
