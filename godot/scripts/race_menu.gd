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

var step := 0
var with_friends := false
var steps: Label
var garage: TextureRect
var driver_name: Label
var summary: Label
var back_button: Button
var forward_button: Button
var mode_buttons: Array[Button] = []
var rival_buttons: Array[Button] = []
var training_button: Button
var resume_button: Button
var vehicle_choice: OptionButton
var vehicle_preview: SubViewportContainer
const Vehicles = preload("res://scripts/vehicle_catalog.gd")

static func menu_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 22
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("edf2fa") if state=="normal" else Color("cbdcf4")
		if state=="focus": box.bg_color=Color.TRANSPARENT
		if state=="pressed": box.bg_color=Color("ffd34d")
		if state=="disabled": box.bg_color=Color("c7ccd4")
		box.set_corner_radius_all(18)
		box.set_border_width_all(3 if state=="focus" else 1)
		box.border_color=Color("408ee4")
		box.content_margin_left=16; box.content_margin_right=16
		for kind in ["Button", "OptionButton", "LineEdit"]: theme.set_stylebox(state,kind,box)
	for kind in ["Button", "OptionButton", "Label", "LineEdit"]:
		for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			theme.set_color(key,kind,Color("142c4f"))
		theme.set_color("font_disabled_color",kind,Color("68778a"))
	return theme

static func highlight_button(action: Button) -> void:
	action.add_theme_font_size_override("font_size",26)
	for state in ["normal","hover","pressed"]:
		var box:=StyleBoxFlat.new()
		box.bg_color=Color("ffd34d") if state=="normal" else Color("ffbd32")
		box.set_corner_radius_all(18)
		box.set_border_width_all(2); box.border_color=Color("e5b026")
		action.add_theme_stylebox_override(state,box)

func _ready() -> void:
	layer=20
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme=menu_theme()
	add_child(root)
	var shade:=ColorRect.new()
	shade.color=Color("bce7f3")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	move_child(shade,0)
	for rect in [Rect2(400,95,830,595),Rect2(40,125,340,430)]:
		var panel:=Panel.new()
		panel.position=rect.position; panel.size=rect.size
		panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var box:=StyleBoxFlat.new()
		box.bg_color=Color("f9fbff"); box.set_corner_radius_all(28)
		box.shadow_color=Color(0.1,0.3,0.5,0.15); box.shadow_size=8
		panel.add_theme_stylebox_override("panel",box)
		root.add_child(panel)
	label("MINIKARTS",Vector2(40,24),Vector2(260,60),38)
	steps=label("",Vector2(320,30),Vector2(910,48),24)
	title=label("",Vector2(420,105),Vector2(780,55),30)
	garage=TextureRect.new()
	garage.position=Vector2(100,135); garage.size=Vector2(220,235)
	garage.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	garage.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	garage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(garage)
	driver_name=label("",Vector2(40,550),Vector2(350,48),30)
	vehicle_preview=preload("res://scripts/vehicle_preview.gd").new()
	vehicle_preview.position=Vector2(42,360);vehicle_preview.size=Vector2(330,180)
	root.add_child(vehicle_preview)
	vehicle_choice=OptionButton.new()
	vehicle_choice.position=Vector2(40,605);vehicle_choice.size=Vector2(350,45)
	for vehicle_name in Vehicles.NAMES: vehicle_choice.add_item(vehicle_name)
	vehicle_choice.select(1 if Vehicles.selected==Vehicles.DRAGON else 0)
	vehicle_choice.item_selected.connect(choose_vehicle)
	root.add_child(vehicle_choice)
	for i in range(2):
		var mode_button=button("CARRERA INDIVIDUAL" if i==0 else "TORNEO · 4 CARRERAS",Vector2(420+i*400,185),Vector2(380,100))
		mode_button.toggle_mode=true
		mode_button.pressed.connect(func():
			Network.selected_mode="single" if i==0 else "tournament"
			set_step(0)
		)
		mode_buttons.append(mode_button)
		var rival_button=button("CON IA" if i==0 else "CON AMIGOS",Vector2(420+i*400,315),Vector2(380,110))
		rival_button.toggle_mode=true
		rival_button.pressed.connect(func():
			with_friends=i==1
			set_step(0)
		)
		rival_buttons.append(rival_button)
	for index in range(NAMES.size()):
		var card=button(NAMES[index],Vector2(475+(index%4)*178,175),Vector2(165,235))
		card.toggle_mode=true
		card.add_theme_font_size_override("font_size",20)
		card.text="\n\n\n\n\n\n"+NAMES[index]
		var portrait:=TextureRect.new()
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.texture=Catalog.PORTRAITS[index]
		portrait.position=Vector2(10,10); portrait.size=Vector2(145,175)
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		card.pressed.connect(select.bind(index))
		cards.append(card)
	previous=button("<",Vector2(420,260),Vector2(48,70))
	next=button(">",Vector2(1188,260),Vector2(48,70))
	previous.pressed.connect(func(): change_page(-1))
	next.pressed.connect(func(): change_page(1))
	page_label=label("",Vector2(700,420),Vector2(200,28),18)
	circuit_choice=OptionButton.new()
	circuit_choice.position=Vector2(420,460); circuit_choice.size=Vector2(780,48)
	for id in range(5): circuit_choice.add_item("%s · %s" % [preload("res://scripts/circuit_catalog.gd").NAMES[id],preload("res://scripts/scenario_theme.gd").TITLES[id]] if id>0 else "Circuito de juguete",id)
	circuit_choice.item_selected.connect(func(index): Network.selected_track=index)
	root.add_child(circuit_choice)
	# Kept as a model selector for existing callers; the visible choices are the large cards.
	mode_choice=OptionButton.new(); mode_choice.add_item("Carrera individual"); mode_choice.add_item("Torneo")
	root.add_child(mode_choice); mode_choice.hide()
	mode_choice.item_selected.connect(func(index): Network.selected_mode="single" if index==0 else "tournament")
	lap_choice=OptionButton.new()
	lap_choice.position=Vector2(420,520); lap_choice.size=Vector2(370,48)
	for laps in Network.Settings.LAP_OPTIONS: lap_choice.add_item("%d vueltas" % laps,laps)
	lap_choice.item_selected.connect(func(index): Network.selected_laps=lap_choice.get_item_id(index))
	root.add_child(lap_choice)
	bot_choice=OptionButton.new()
	bot_choice.position=Vector2(820,520); bot_choice.size=Vector2(380,48)
	for count in Network.Settings.BOT_OPTIONS: bot_choice.add_item("IA · %d rivales" % count,count)
	bot_choice.item_selected.connect(func(index): Network.selected_bots=bot_choice.get_item_id(index))
	root.add_child(bot_choice)
	summary=label("",Vector2(440,200),Vector2(740,270),28)
	summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	race_button=button("¡A CORRER!",Vector2(620,605),Vector2(580,65))
	race_button.pressed.connect(game.start_offline)
	online=button("VER SALAS / CREAR SALA",Vector2(620,605),Vector2(580,65))
	online.pressed.connect(func():
		game.prepare_online()
		Network.menu.get_node("Panel").show()
	)
	continuation_button=button("CONTINUAR TORNEO",Vector2(620,605),Vector2(580,65))
	continuation_button.pressed.connect(func():
		if game.offline_race.tournament.stage==4: open()
		else: game.offline_race.continue_tournament()
	)
	back_button=button("VOLVER",Vector2(420,605),Vector2(185,65))
	back_button.pressed.connect(func():
		if result_text.visible or is_instance_valid(podium) or continuation_button.visible: open()
		else: set_step(maxi(0,step-1))
	)
	forward_button=button("SIGUIENTE",Vector2(620,605),Vector2(580,65))
	forward_button.pressed.connect(func(): set_step(mini(2,step+1)))
	for action in [forward_button,race_button,online,continuation_button]: highlight_button(action)
	training_button=button("Entrenar a solas",Vector2(420,500),Vector2(370,55))
	training_button.pressed.connect(game.start_solo)
	resume_button=button("Volver a la carrera",Vector2(820,500),Vector2(380,55))
	resume_button.pressed.connect(resume)
	status=label("",Vector2(420,575),Vector2(780,26),18)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	result_text=label("",Vector2(420,170),Vector2(780,390),18)
	select(Network.selected_driver)
	set_step(0)
	get_viewport().size_changed.connect(layout_menu)
	layout_menu()
	hide()

func layout_menu() -> void:
	root.position=(get_viewport().get_visible_rect().size-Vector2(1280,720))*0.5

func set_step(value: int) -> void:
	step=value
	var tournament=Network.selected_mode=="tournament"
	steps.text=["1 MODO   /   2 PILOTO Y CARRERA   /   3 SALIDA", "1 Modo   /   2 PILOTO Y CARRERA   /   3 Salida", "1 Modo   /   2 Piloto y carrera   /   3 SALIDA"][step]
	title.text=["ELIGE TU PARTIDA","ELIGE PILOTO Y CARRERA","TODO LISTO PARA SALIR"][step]
	for i in range(2):
		mode_buttons[i].visible=step==0
		rival_buttons[i].visible=step==0
		mode_buttons[i].set_pressed_no_signal((i==1)==tournament)
		rival_buttons[i].set_pressed_no_signal((i==1)==with_friends)
	update_page()
	circuit_choice.visible=step==1
	circuit_choice.disabled=tournament
	lap_choice.visible=step==1
	bot_choice.visible=step==1 and not with_friends
	mode_choice.hide(); result_text.hide(); continuation_button.hide()
	training_button.visible=step==0
	resume_button.visible=step==0
	back_button.visible=step>0
	forward_button.visible=step<2
	race_button.visible=step==2 and not with_friends
	online.visible=step==2 and with_friends
	online.disabled=not is_instance_valid(Network.address) or Network.address.text.is_empty()
	summary.visible=step==2
	summary.text="%s\n\n%s · %s\n\n%s" % ["TORNEO" if tournament else "CARRERA INDIVIDUAL",NAMES[Network.selected_driver],"Con amigos · hasta 16 pilotos" if with_friends else "Con IA · %d rivales" % Network.selected_bots,"Clasificación: 3 vueltas\n4 carreras · %d vueltas cada una" % Network.selected_laps if tournament else "%s · %d vueltas" % [preload("res://scripts/circuit_catalog.gd").NAMES[Network.selected_track],Network.selected_laps]]
	status.text="Torneo: clasificación de 3 vueltas + 4 carreras." if tournament else "Una carrera · elige circuito y 3, 6 o 9 vueltas."
	if step==2 and with_friends: status.text="Elige una sala de la lista o crea la tuya." if not online.disabled else "El servidor online no está configurado."

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
	Vehicles.selected_character=Vehicles.CHARACTER_IDS[index]
	Vehicles.save_selection()
	garage.texture=Catalog.PORTRAITS[index]
	driver_name.text=NAMES[index]
	if is_instance_valid(game.offline_race) and game.offline_race.tournament!=null:
		game.offline_race.tournament.table[0].driver=index
	game.kart.get_node("Driver").set_face(index)
	vehicle_preview.choose(index,Vehicles.selected)
	for i in range(cards.size()):
		cards[i].set_pressed_no_signal(i == index)

func choose_vehicle(index: int) -> void:
	Vehicles.selected=Vehicles.IDS[clampi(index,0,1)]
	Vehicles.save_selection()
	Vehicles.apply(game.kart,Vehicles.selected)
	vehicle_preview.choose(Network.selected_driver,Vehicles.selected)

func _process(_delta: float) -> void:
	if not Network.browser_test or not OS.has_feature("web"): return
	var vehicles: Dictionary={}
	for id in Network.remote_karts:
		vehicles[str(id)]=Network.remote_karts[id].get_meta("vehicle_id",Vehicles.DEFAULT)
	if is_instance_valid(game.kart):vehicles[str(Network.player_id)]=game.kart.get_meta("vehicle_id",Vehicles.DEFAULT)
	var rect:=vehicle_choice.get_global_rect()
	JavaScriptBridge.eval("window.minikartsVehicleTest="+JSON.stringify({"selected":Vehicles.selected,"driver":Network.selected_driver,"menu_visible":visible,"choice_rect":{"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y},"rendered":vehicles,"preview":vehicle_preview.kart.get_meta("vehicle_id",Vehicles.DEFAULT)})+";")

func open() -> void:
	if Network.playing:
		return
	show()
	if is_instance_valid(podium): podium.queue_free()
	podium=null
	circuit_choice.select(Network.selected_track)
	mode_choice.select(1 if Network.selected_mode=="tournament" else 0)
	for i in range(lap_choice.item_count):
		if lap_choice.get_item_id(i)==Network.selected_laps: lap_choice.select(i)
	for i in range(bot_choice.item_count):
		if bot_choice.get_item_id(i)==Network.selected_bots: bot_choice.select(i)
	game.hud.hide()
	game.kart.enabled=false
	game.kart.set_physics_process(false)
	game.get_node("Track/NeutralSleeper").set_physics_process(false)
	if is_instance_valid(game.offline_race): game.offline_race.pause_race(true)
	page=Network.selected_driver / 4
	select(Network.selected_driver)
	set_step(0)

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
	if Sound.panel != null: Sound.panel.hide()
	open()
	set_step(2)
	summary.hide(); race_button.show(); online.hide(); back_button.show()
	steps.text="RESULTADOS"
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
				podium.position=Vector2(420,170); podium.size=Vector2(780,390)
				root.add_child(podium); podium.present(standings)
		continuation_button.text="VOLVER AL MENÚ" if tournament.stage==4 else "CONTINUAR TORNEO"

func change_page(direction: int) -> void:
	page = clampi(page + direction, 0, (NAMES.size() - 1) / 4)
	update_page()

func update_page() -> void:
	for i in range(cards.size()):
		cards[i].visible = step==1 and i / 4 == page
	previous.visible=step==1
	next.visible=step==1
	page_label.visible=step==1
	previous.disabled = page == 0
	next.disabled = page == (NAMES.size() - 1) / 4
	page_label.text = "%d / %d" % [page + 1, ceili(NAMES.size() / 4.0)]
