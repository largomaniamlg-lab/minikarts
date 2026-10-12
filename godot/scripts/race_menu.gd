extends CanvasLayer

const Driver = preload("res://scripts/driver.gd")
const Catalog = preload("res://scripts/driver_catalog.gd")
const NAMES = Catalog.NAMES
var circuit_choice: OptionButton
var mode_choice: OptionButton
var race_button: Button
var continuation_button: Button
var podium: Control
var lap_choice: OptionButton
var bot_choice: OptionButton
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
	circuit_choice=OptionButton.new()
	circuit_choice.position=Vector2(260,12); circuit_choice.size=Vector2(470,38)
	circuit_choice.add_theme_font_size_override("font_size",20)
	for id in range(5): circuit_choice.add_item(preload("res://scripts/circuit_catalog.gd").NAMES[id],id)
	circuit_choice.item_selected.connect(func(index): Network.selected_track=index)
	root.add_child(circuit_choice)
	mode_choice=OptionButton.new()
	mode_choice.position=Vector2(750,12); mode_choice.size=Vector2(270,38)
	mode_choice.add_theme_font_size_override("font_size",20)
	mode_choice.add_item("Carrera suelta"); mode_choice.add_item("Torneo · 4 carreras")
	mode_choice.item_selected.connect(func(index):
		Network.selected_mode="single" if index==0 else "tournament"
		circuit_choice.disabled=index==1
		status.text="Clasificación: 3 vueltas en el original. Después, 4 carreras con las vueltas elegidas." if index==1 else "Elige circuito, piloto y vueltas."
	)
	root.add_child(mode_choice)
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
	lap_choice = OptionButton.new()
	lap_choice.position = Vector2(260, 350)
	lap_choice.size = Vector2(370, 40)
	lap_choice.add_theme_font_size_override("font_size", 22)
	for laps in Network.Settings.LAP_OPTIONS:
		lap_choice.add_item("%d vueltas" % laps, laps)
	lap_choice.item_selected.connect(func(index): Network.selected_laps = lap_choice.get_item_id(index))
	root.add_child(lap_choice)
	bot_choice = OptionButton.new()
	bot_choice.position = Vector2(650, 350)
	bot_choice.size = Vector2(370, 40)
	bot_choice.add_theme_font_size_override("font_size", 22)
	for count in Network.Settings.BOT_OPTIONS:
		bot_choice.add_item("IA · %d rivales" % count, count)
	bot_choice.item_selected.connect(func(index): Network.selected_bots = bot_choice.get_item_id(index))
	root.add_child(bot_choice)
	race_button=button("CARRERA CONTRA LA IA", Vector2(260,405),Vector2(760,55))
	race_button.pressed.connect(game.start_offline)
	continuation_button=button("CONTINUAR TORNEO",Vector2(260,405),Vector2(760,55))
	continuation_button.pressed.connect(func():
		if game.offline_race.tournament.stage==4: open()
		else: game.offline_race.continue_tournament()
	)
	continuation_button.hide()
	online = button("ONLINE · CON AMIGOS", Vector2(260, 475), Vector2(760, 60))
	online.pressed.connect(func():
		game.prepare_online()
		Network.menu.get_node("Panel").show()
	)
	button("ENTRENAR A SOLAS", Vector2(260, 545), Vector2(370, 55)).pressed.connect(game.start_solo)
	button("VOLVER A LA CARRERA", Vector2(650, 545), Vector2(370, 55)).pressed.connect(resume)
	status = label("", Vector2(260, 610), Vector2(760, 65), 21)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	result_text = label("", Vector2(260, 110), Vector2(760, 285), 18)
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
	if is_instance_valid(game.offline_race) and game.offline_race.tournament!=null:
		game.offline_race.tournament.table[0].driver=index
	game.kart.get_node("Driver").set_face(index)
	for i in range(cards.size()):
		cards[i].set_pressed_no_signal(i == index)

func open() -> void:
	if Network.playing:
		return
	show()
	if is_instance_valid(podium): podium.queue_free()
	podium=null
	circuit_choice.show(); mode_choice.show(); race_button.show(); continuation_button.hide()
	circuit_choice.select(Network.selected_track)
	mode_choice.select(1 if Network.selected_mode=="tournament" else 0)
	circuit_choice.disabled=Network.selected_mode=="tournament"
	game.hud.hide()
	game.kart.enabled = false
	game.kart.set_physics_process(false)
	game.get_node("Track/NeutralSleeper").set_physics_process(false)
	if is_instance_valid(game.offline_race):
		game.offline_race.pause_race(true)
	title.text = "ELIGE TU PILOTO"
	result_text.hide()
	lap_choice.show()
	bot_choice.show()
	page = Network.selected_driver / 4
	update_page()
	online.disabled = Network.address.text.is_empty()
	status.text = "Online pendiente de activar el servidor gratuito." if online.disabled else "Crea una sala o elige una disponible · hasta 16 jugadores."

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
	title.text = "RESULTADOS · %d VUELTAS" % game.offline_race.lap_target
	for card in cards:
		card.hide()
	result_text.text = ""
	for index in range(results.size()):
		var racer: Dictionary = results[index]
		result_text.text += "%d. %s — %s\n" % [index + 1, racer.name, "%.2f s" % racer.time if racer.time >= 0 else "Sin terminar"]
	previous.hide()
	next.hide()
	page_label.hide()
	lap_choice.hide()
	bot_choice.hide()
	result_text.show()
	circuit_choice.hide(); mode_choice.hide()
	if game.offline_race.tournament!=null:
		var tournament=game.offline_race.tournament
		race_button.hide(); continuation_button.show()
		if tournament.stage==0:
			title.text="PARRILLA · MEJOR VUELTA DE CLASIFICACIÓN"
			result_text.text=""
			for i in range(results.size()): result_text.text+="%d. %s · %s\n" % [i+1,results[i].name,"%.2f s" % results[i].best_lap if results[i].best_lap>=0 else "Sin vuelta válida"]
		else:
			title.text="TORNEO · CARRERA %d/4" % tournament.stage
			result_text.text=""
			var standings: Array=tournament.standings()
			for i in range(standings.size()): result_text.text+="%d. %s · %d puntos\n" % [i+1,standings[i].name,standings[i].points]
			if tournament.stage==4:
				result_text.hide()
				podium=preload("res://scripts/podium.gd").new()
				podium.position=Vector2(260,110); podium.size=Vector2(760,285)
				root.add_child(podium); podium.present(standings)
		continuation_button.text="VOLVER AL MENÚ" if tournament.stage==4 else "CONTINUAR TORNEO"

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
