extends CanvasLayer

const Driver = preload("res://scripts/driver.gd")
const NAMES := ["Kikoso", "Largo", "Sipollo", "Antocino"]
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
	for index in range(4):
		var card := button(NAMES[index], Vector2(260 + index * 195, 125), Vector2(175, 205))
		card.toggle_mode = true
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_theme_constant_override("outline_size", 0)
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.texture = Driver.FACES[index]
		portrait.position = Vector2(12, 10)
		portrait.size = Vector2(151, 151)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.text = "\n\n\n\n\n" + NAMES[index]
		card.add_child(portrait)
		portrait.size = Vector2(151, 151)
		card.pressed.connect(select.bind(index))
		cards.append(card)
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
	for card in cards:
		card.show()
	online.disabled = Network.address.text.is_empty()
	status.text = "Online pendiente de activar el servidor gratuito." if online.disabled else "Crea una sala y comparte su código con tus amigos."

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
	result_text.show()
