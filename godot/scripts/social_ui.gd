extends CanvasLayer
var network: Node
var panel: PanelContainer
var chat_panel: VBoxContainer
var editor: LineEdit
var history_label: Label
var mute_choice: OptionButton
var muted: Dictionary = {}
var messages: Array = []
var queue: Array = []
var reaction_remaining := 0.0
var active_reaction_id := 0
var hide_chat := false
var hide_reactions := false
var reaction_row: HBoxContainer
var reaction_image: TextureRect
var reaction_label: Label
var name_edit: LineEdit
var track_choice: OptionButton
var laps_choice: OptionButton
var mode_choice: OptionButton
var apply_button: Button
var send_button: Button
var mute_button: Button
var chat_toggle: Button
var known_roster := ""
var known_revision := -1
var reaction_buttons: Array[Button] = []
var safe_root: Control
var focused := true
var textures: Dictionary = {}

func button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size.y = 38
	b.pressed.connect(action); parent.add_child(b); return b

func _ready() -> void:
	layer = 11
	safe_root = Control.new(); safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_root.set_script(load("res://scripts/toon_safe_area.gd")); safe_root.set("scale_demo",true); add_child(safe_root)
	safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(safe_root.layout)
	for key in ["smile","star","flag"]: textures[key] = load("res://assets/social/"+key+".svg")
	panel = PanelContainer.new(); panel.position = Vector2(40,125); panel.size = Vector2(380,480)
	var background := StyleBoxFlat.new(); background.bg_color=Color("111c28"); background.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel",background); safe_root.add_child(panel)
	var box := VBoxContainer.new(); panel.add_child(box)
	var heading := HBoxContainer.new(); box.add_child(heading)
	chat_toggle = button(heading,"Ocultar chat",func(): hide_chat = not hide_chat; chat_panel.visible = not hide_chat; release_inputs())
	var tabs := TabContainer.new(); tabs.custom_minimum_size = Vector2(340,420); box.add_child(tabs)
	var chat := VBoxContainer.new(); chat.name = "Chat"; tabs.add_child(chat)
	chat_panel = VBoxContainer.new(); chat.add_child(chat_panel)
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size = Vector2(330,240); chat_panel.add_child(scroll)
	history_label = Label.new(); history_label.custom_minimum_size.x = 310; history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_label.add_theme_font_size_override("font_size",18); scroll.add_child(history_label)
	editor = LineEdit.new(); editor.placeholder_text = "Mensaje (160 caracteres)"; editor.max_length = 160; chat_panel.add_child(editor)
	editor.text_submitted.connect(func(_text): send_chat())
	editor.focus_entered.connect(release_inputs)
	editor.focus_exited.connect(release_inputs)
	send_button = button(chat_panel,"Enviar",send_chat)
	mute_choice = OptionButton.new(); chat.add_child(mute_choice)
	mute_button = button(chat,"Silenciar / escuchar seleccionado",func():
		if mute_choice.selected < 0: return
		var pid := mute_choice.get_item_id(mute_choice.selected)
		if pid == network.player_id: return
		if muted.has(pid): muted.erase(pid)
		else:
			muted[pid] = true
			queue = queue.filter(func(event):return int(event.id)!=pid)
			if active_reaction_id==pid: reaction_remaining=0; reaction_label.text=""
		render_history())
	var rules := VBoxContainer.new(); rules.name = "Reglas"; tabs.add_child(rules)
	name_edit = LineEdit.new(); name_edit.max_length = 32; name_edit.placeholder_text = "Nombre de sala"; rules.add_child(name_edit)
	mode_choice = OptionButton.new(); mode_choice.add_item("Carrera individual"); mode_choice.add_item("Torneo"); rules.add_child(mode_choice)
	track_choice = OptionButton.new()
	for title in network.Circuits.NAMES: track_choice.add_item(title)
	rules.add_child(track_choice)
	laps_choice = OptionButton.new()
	for laps in [3,6,9]: laps_choice.add_item(str(laps)+" vueltas",laps)
	rules.add_child(laps_choice)
	apply_button = button(rules,"Aplicar (retira Listo)",func():
		network.send(network.socket,{"type":"rules","room_name":name_edit.text,"mode":"tournament" if mode_choice.selected==1 else "single","track":track_choice.selected,"laps":laps_choice.get_selected_id()})
		release_inputs())
	for edit in [name_edit]:
		edit.focus_entered.connect(release_inputs); edit.focus_exited.connect(release_inputs)
	reaction_row = HBoxContainer.new()
	reaction_row.position = Vector2(490,140); safe_root.add_child(reaction_row)
	for key in ["smile","star","flag"]:
		var b := button(reaction_row,"",func():
			send_reaction(key))
		b.icon = textures[key]; b.tooltip_text = key; b.custom_minimum_size = Vector2(48,42); b.focus_mode = Control.FOCUS_NONE
		reaction_buttons.append(b)
	button(reaction_row,"Ocultar",func():
		hide_reactions = not hide_reactions
		queue.clear(); reaction_label.text = ""; reaction_remaining=0.0
		reaction_row.get_child(3).text = "Mostrar" if hide_reactions else "Ocultar")
	reaction_image = TextureRect.new(); reaction_image.position=Vector2(440,190); reaction_image.size=Vector2(28,28)
	reaction_image.mouse_filter=Control.MOUSE_FILTER_IGNORE; reaction_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	safe_root.add_child(reaction_image)
	reaction_label = Label.new(); reaction_label.position = Vector2(470,190); reaction_label.size = Vector2(340,30)
	reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; reaction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_root.add_child(reaction_label)
	panel.hide(); reaction_row.hide(); reaction_label.hide()

func release_inputs() -> void:
	for action in ["accelerate","brake","reverse","jump","shoot","steer_left","steer_right","handbrake","reset","look_back"]:
		if InputMap.has_action(action): Input.action_release(action)
	network.pending_reset = false; network.previous_inputs.clear()
	var game = get_tree().current_scene
	if is_instance_valid(game):
		for child in game.find_children("*","Node",true,false):
			if child.has_method("release_actions"): child.release_actions()

func send_chat() -> void:
	if network.snapshot.get("phase","") not in ["lobby","results"] or not focused: return
	network.send(network.socket,{"type":"chat","text":editor.text})
	editor.clear(); editor.release_focus(); release_inputs()

func receive(message: Dictionary) -> void:
	if message.type == "social_history":
		messages = message.get("messages",[]).slice(-32); render_history(); return
	if message.get("kind") == "reaction":
		if hide_reactions or muted.has(int(message.id)): return
		if queue.size() < 3: queue.append(message)
		return
	messages.append(message)
	while messages.size()>32: messages.pop_front()
	render_history()

func render_history() -> void:
	if not is_instance_valid(history_label): return
	var lines: Array[String] = []
	for msg in messages:
		if not muted.has(int(msg.get("id",0))): lines.append(str(msg.get("name","Sistema"))+": "+str(msg.get("text","")))
	history_label.text = "\n".join(lines)

func clear_room() -> void:
	messages.clear(); muted.clear(); queue.clear(); reaction_remaining=0; known_roster=""; known_revision=-1
	if is_instance_valid(editor): editor.clear(); editor.release_focus()
	release_inputs(); render_history()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		if is_instance_valid(editor): editor.release_focus(); editor.clear()
		if is_instance_valid(network): release_inputs()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN: focused = true
	elif what == NOTIFICATION_PAUSED:
		if is_instance_valid(network): release_inputs()

func _process(delta: float) -> void:
	var phase: String = network.snapshot.get("phase","")
	var in_room: bool = network.playing and not network.snapshot.is_empty() and network.server_social_version>=1
	panel.visible = in_room and phase in ["lobby","results"] and network.menu.get_node("Panel").visible
	if not panel.visible:
		if editor.has_focus() or name_edit.has_focus(): editor.release_focus(); name_edit.release_focus(); release_inputs()
	var typing := panel.visible and (editor.has_focus() or name_edit.has_focus())
	if typing: release_inputs()
	if OS.has_feature("web") and network.browser_test and network.diagnostics_due:
		var controls := {"chat_input":editor,"send":send_button,"mute":mute_button,"mute_choice":mute_choice,"hide_chat":chat_toggle,"apply":apply_button,"room_name":name_edit,"reaction_hide":reaction_row.get_child(3)}
		for i in reaction_buttons.size(): controls["reaction_"+["smile","star","flag"][i]]=reaction_buttons[i]
		var rects := {}
		for key in controls:
			var c: Control=controls[key]
			if c.is_visible_in_tree():
				var r:=c.get_global_rect();rects[key]={"x":r.position.x,"y":r.position.y,"width":r.size.x,"height":r.size.y}
		JavaScriptBridge.eval("window.minikartsSocialTest="+JSON.stringify({"buttons":rects,"history":history_label.text,"hidden":hide_chat,"reactions_hidden":hide_reactions,"reaction":reaction_label.text,"queue":queue.size(),"version":network.server_social_version})+";")
	# Driving is already disabled by lobby; no chat editor exists during the race.
	var editable: bool = in_room and phase == "lobby" and network.player_id == int(network.snapshot.get("host",0))
	apply_button.disabled = not editable
	name_edit.editable = editable; track_choice.disabled = not editable; laps_choice.disabled = not editable; mode_choice.disabled = not editable
	if in_room:
		var revision: int = int(network.snapshot.get("rules_revision",0))
		if known_revision != revision:
			known_revision = revision
			name_edit.text = str(network.snapshot.get("room_name","Sala"))
			track_choice.select(int(network.snapshot.get("track",0)))
			mode_choice.select(1 if network.snapshot.get("mode","single")=="tournament" else 0)
			laps_choice.select([3,6,9].find(int(network.snapshot.get("race_laps",3))))
		var roster := JSON.stringify(network.snapshot.players.map(func(p):return [p.id,p.name]))
		if roster != known_roster:
			known_roster = roster; mute_choice.clear()
			for player in network.snapshot.players:
				if not player.get("bot",false): mute_choice.add_item(str(player.name),int(player.id))
	reaction_row.visible = in_room and phase in ["lobby","racing","results"] and not network.client_controls_blocked
	reaction_row.position=Vector2(490,140) if phase=="racing" else Vector2(40,620)
	for b in reaction_buttons: b.visible = not hide_reactions
	reaction_label.visible = reaction_row.visible and not hide_reactions
	reaction_image.visible = reaction_label.visible and reaction_remaining>0
	reaction_remaining = maxf(0,reaction_remaining-delta)
	if reaction_remaining <= 0:
		reaction_label.text = ""
		if not queue.is_empty() and reaction_row.visible:
			var event: Dictionary = queue.pop_front()
			active_reaction_id = int(event.id)
			reaction_label.text = str(event.name)
			reaction_image.texture = textures.get(event.icon)
			reaction_remaining = 2.0

func send_reaction(key: String) -> void:
	if is_instance_valid(network.socket) and focused:
		network.send(network.socket,{"type":"reaction","icon":key})

func _input(event: InputEvent) -> void:
	if get_tree().paused or not focused or not is_instance_valid(reaction_row) or not reaction_row.is_visible_in_tree(): return
	# Each screen finger works independently; generated mouse must not submit twice.
	if event is InputEventMouseButton and event.device == -1:
		var point: Vector2 = reaction_row.get_global_transform_with_canvas().affine_inverse() * event.position
		if Rect2(Vector2.ZERO,reaction_row.size).has_point(point): get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		for i in reaction_buttons.size():
			var b: Button = reaction_buttons[i]
			if b.is_visible_in_tree() and Rect2(Vector2.ZERO,b.size).has_point(b.get_global_transform_with_canvas().affine_inverse()*event.position):
				send_reaction(["smile","star","flag"][i]); get_viewport().set_input_as_handled(); return
		var toggle: Button = reaction_row.get_child(3)
		if Rect2(Vector2.ZERO,toggle.size).has_point(toggle.get_global_transform_with_canvas().affine_inverse()*event.position):
			toggle.pressed.emit(); get_viewport().set_input_as_handled()
