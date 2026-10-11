extends CanvasLayer

const Driver = preload("res://scripts/driver.gd")
const Catalog = preload("res://scripts/driver_catalog.gd")
const NAMES = Catalog.NAMES
var page := 0
var previous: Button
var next: Button
var page_label: Label
var game: Node3D
var root: Control
var title: Label
var status: Label
var cards: Array[Button] = []
var online: Button
var result_text: Label

func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.08, 0.12, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	title = label("ELIGE TU PILOTO", Vector2(260, 60), Vector2(760, 50), 32)
	for index in range(NAMES.size()):
		var card := button(NAMES[index], Vector2(260 + (index % 4) * 195, 125), Vector2(175, 205))
		card.toggle_mode = true
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_theme_constant_override("outline_size", 0)
		card.add_theme_font_size_override("font_size", 16)
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.texture = Catalog.PORTRAITS[index]
		portrait.position = Vector2(12, 10)
		portrait.size = Vector2(151, 140)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.text = "\n\n\n\n\n" + NAMES[index]
		card.add_child(portrait)
		portrait.size = Vector2(151, 140)
		card.pressed.connect(select.bind(index))
		cards.append(card)
	previous = button("<", Vector2(145, 195), Vector2(90, 60))
	next = button(">", Vector2(1045, 195), Vector2(90, 60))
	previous.pressed.connect(func(): change_page(-1))
	next.pressed.connect(func(): change_page(1))
	page_label = label("", Vector2(510, 95), Vector2(260, 25), 16)
	button("CARRERA · 3 RIVALES IA", Vector2(260, 360), Vector2(760, 60)).pressed.connect(game.start_offline)
	online = button("ONLINE · CON AMIGOS", Vector2(260, 435), Vector2(760, 60))
	online.pressed.connect(func():
		game.prepare_online()
		Network.menu.get_node("Panel").show()
	)
	button("ENTRENAR A SOLAS", Vector2(260, 510), Vector2(370, 55)).pressed.connect(game.start_solo)
	button("VOLVER A LA CARRERA", Vector2(650, 510), Vector2(370, 55)).pressed.connect(resume)
	status = label("", Vector2(260, 580), Vector2(760, 65), 21)
	result_text = label("", Vector2(260, 110), Vector2(760, 240), 26)
	result_text.hide()
	select(Network.selected_driver)
	hide()

func button(text: String, position: Vector2, size: Vector2) -> Button:
	var node := Button.new()
	node.text = text
	node.position = position
	node.size = size
	node.add_theme_font_size_override("font_size", 22)
	root.add_child(node)
	return node

func label(text: String, position: Vector2, size: Vector2, font: int) -> Label:
	var node := Label.new()
	node.text = text
	node.position = position
	node.size = size
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font)
	root.add_child(node)
	return node

func select(index: int) -> void:
	Network.selected_driver = index
	game.kart.get_node("Driver").set_face(index)
	for i in range(cards.size()):
		cards[i].set_pressed_no_signal(i == index)

func open() -> void:
	if Network.playing:
		return
	show()
	game.hud.hide()
	game.kart.enabled = false
	game.kart.set_physics_process(false)
	game.get_node("Track/NeutralSleeper").set_physics_process(false)
	if is_instance_valid(game.offline_race):
		game.offline_race.pause_race(true)
	title.text = "ELIGE TU PILOTO"
	result_text.hide()
	page = Network.selected_driver / 4
	update_page()
	online.disabled = Network.address.text.is_empty()
	status.text = "Online pendiente de activar el servidor gratuito." if online.disabled else "Crea una sala o elige una disponible · hasta 10 jugadores."

func resume() -> void:
	hide()
	game.hud.show()
	game.kart.set_physics_process(true)
	game.get_node("Track/NeutralSleeper").set_physics_process(true)
	if is_instance_valid(game.offline_race):
		game.offline_race.pause_race(false)
	else:
		game.kart.enabled = not game.finished

func show_results(results: Array) -> void:
	open()
	title.text = "RESULTADOS · TRES VUELTAS"
	for card in cards:
		card.hide()
	result_text.text = ""
	for index in range(results.size()):
		var racer: Dictionary = results[index]
		result_text.text += "%d. %s — %s\n" % [index + 1, racer.name, "%.2f s" % racer.time if racer.time >= 0 else "Sin terminar"]
	previous.hide()
	next.hide()
	page_label.hide()
	result_text.show()

func change_page(direction: int) -> void:
	page = clampi(page + direction, 0, (NAMES.size() - 1) / 4)
	update_page()

func update_page() -> void:
	for i in range(cards.size()):
		cards[i].visible = i / 4 == page
	previous.show()
	next.show()
	page_label.show()
	previous.disabled = page == 0
	next.disabled = page == (NAMES.size() - 1) / 4
	page_label.text = "%d / %d" % [page + 1, ceili(NAMES.size() / 4.0)]
