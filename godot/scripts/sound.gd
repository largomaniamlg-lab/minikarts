extends Node

var game: Node3D
var music_circuit:=0
var music_path:="res://assets/audio/race_music.ogg"
var music: AudioStreamPlayer
var engine: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var music_volume := 0.35
var effects_volume := 0.7
var muted := false
var focused := true
var previous_phase := ""
var previous_count := -1
var previous_finished := false
var online_hit := false
var online_height := 0.7
var brake_clock := 0.0
var sound_button: Button
var panel: VBoxContainer
var mute_button: CheckButton
var events: Dictionary = {}

func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		set_process(false)
		return
	for key in ["jump", "land", "shoot", "spin", "tick", "go", "impact", "box", "brake"]:
		streams[key] = load("res://assets/audio/%s.wav" % key)
	streams.finish = load("res://assets/audio/finish.ogg")
	var song := load("res://assets/audio/race_music.ogg").duplicate() as AudioStreamOggVorbis
	song.loop = true
	music = player(song)
	var motor := load("res://assets/audio/engine.wav").duplicate() as AudioStreamWAV
	motor.loop_mode = AudioStreamWAV.LOOP_FORWARD
	motor.loop_begin = 0
	motor.loop_end = motor.data.size() / 2
	engine = player(motor)
	for i in range(12):
		effects.append(player(null))
	var config := ConfigFile.new()
	if config.load("user://sound.cfg") == OK:
		music_volume = clampf(float(config.get_value("audio", "music", 0.35)), 0, 1)
		effects_volume = clampf(float(config.get_value("audio", "effects", 0.7)), 0, 1)
		muted = bool(config.get_value("audio", "muted", false))
	build_controls()
	apply_volumes()
	music.play()

func set_circuit(id: int) -> void:
	if music==null: return
	music_circuit=id
	var path="res://assets/audio/velocity_music.ogg" if id==1 and ResourceLoader.exists("res://assets/audio/velocity_music.ogg") else "res://assets/audio/race_music.ogg"
	if path==music_path: return
	var song=load(path).duplicate() as AudioStreamOggVorbis
	song.loop=true
	music.stop(); music.stream=song; music_path=path
	music.play(); apply_volumes()

func player(stream: AudioStream) -> AudioStreamPlayer:
	var node := AudioStreamPlayer.new()
	node.stream = stream
	add_child(node)
	return node

func play_effect(key: String, position: Vector3 = Vector3.INF) -> void:
	if music == null or muted or not focused or effects_volume <= 0:
		return
	var gain := 1.0
	if position != Vector3.INF:
		if not is_instance_valid(game):
			return
		gain = clampf(1.0 - game.kart.global_position.distance_to(position) / 35.0, 0, 1)
	if gain < 0.05:
		return
	for effect in effects:
		if not effect.playing:
			effect.stream = streams[key]
			effect.volume_db = linear_to_db(effects_volume * gain * 0.65)
			effect.play()
			events[key] = int(events.get(key, 0)) + 1
			return

func apply_volumes() -> void:
	music.volume_db = linear_to_db(maxf(0.0001, music_volume * 0.55))
	music.stream_paused = muted or not focused or music_volume <= 0
	engine.stream_paused = muted or not focused or effects_volume <= 0
	for effect in effects:
		effect.stream_paused = muted or not focused or effects_volume <= 0

func save_settings() -> void:
	apply_volumes()
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "effects", effects_volume)
	config.set_value("audio", "muted", muted)
	config.save("user://sound.cfg")

func build_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var button := Button.new()
	sound_button = button
	button.text = "SONIDO"
	button.position = Vector2(1050, 204)
	button.size = Vector2(150, 48)
	layer.add_child(button)
	if preload("res://scripts/touch_controls.gd").is_touch_mode():
		button.hide()
	panel = VBoxContainer.new()
	panel.position = Vector2(970, 257)
	panel.custom_minimum_size = Vector2(210, 200)
	layer.add_child(panel)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.05, 0.1, 0.15, 0.96)
	var wrapper := Panel.new()
	wrapper.add_theme_stylebox_override("panel", background)
	wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wrapper)
	panel.move_child(wrapper, 0)
	mute_button = CheckButton.new()
	mute_button.text = "Silenciar todo"
	mute_button.button_pressed = muted
	panel.add_child(mute_button)
	mute_button.toggled.connect(func(value: bool): muted = value; save_settings())
	for kind in ["Música", "Efectos"]:
		var label := Label.new()
		label.text = kind
		panel.add_child(label)
		var slider := HSlider.new()
		slider.name = "MusicVolume" if kind == "Música" else "EffectsVolume"
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(210, 38)
		slider.value = music_volume if kind == "Música" else effects_volume
		panel.add_child(slider)
		slider.value_changed.connect(func(value: float):
			if kind == "Música": music_volume = value
			else: effects_volume = value
			save_settings()
		)
	panel.hide()
	button.pressed.connect(func(): panel.visible = not panel.visible)

func _process(delta: float) -> void:
	if not is_instance_valid(game) or music == null:
		return
	var circuit: int=game.get_node("Track").layout_id
	if circuit!=music_circuit: set_circuit(circuit)
	var phase := "menu" if game.race_menu.visible else "racing"
	var count := 0
	var done: bool = game.finished
	if Network.playing and not Network.snapshot.is_empty():
		phase = str(Network.snapshot.phase)
		count = int(Network.snapshot.countdown)
		for racer in Network.snapshot.players:
			if int(racer.id) == Network.player_id:
				done = bool(racer.finished)
				var hit: bool = racer.hit > 0
				if hit and not online_hit: play_effect("spin")
				online_hit = hit
				var height: float = racer.position[1]
				if height > 1.1 and online_height <= 1.1: play_effect("jump")
				if height < 0.9 and online_height >= 0.9: play_effect("land")
				online_height = height
	elif is_instance_valid(game.offline_race):
		phase = "menu" if game.offline_race.paused else game.offline_race.phase
		count = ceili(game.offline_race.timer)
		done = game.offline_race.racers[0].finished
	else:
		online_hit = false
	if phase == "countdown" and (count != previous_count or previous_phase != phase):
		play_effect("tick")
	if phase == "racing" and previous_phase == "countdown": play_effect("go")
	if done and not previous_finished: play_effect("finish")
	previous_finished = done
	previous_count = count
	if phase != previous_phase and panel != null: panel.hide()
	previous_phase = phase
	var driving: bool = phase == "racing" and not done and game.kart.is_visible_in_tree()
	if driving:
		if not engine.playing: engine.play()
		var speed: float = absf(game.kart.speed)
		engine.pitch_scale = 0.75 + speed / 22.0 * 1.35
		engine.volume_db = linear_to_db(maxf(0.0001, effects_volume * (0.10 + speed / 22.0 * 0.20)))
		brake_clock = maxf(0, brake_clock - delta)
		if speed > 4 and (Input.is_action_pressed("brake") or Input.is_action_pressed("handbrake")) and brake_clock == 0:
			play_effect("brake")
			brake_clock = 0.6
	else:
		engine.stop()
	if Network.browser_test:
		JavaScriptBridge.eval("window.minikartsAudioTest=" + JSON.stringify({"music": music.playing, "circuit":music_circuit,"track":music_path, "muted": muted, "music_volume": music_volume, "effects_volume": effects_volume, "mixer_visible":panel.visible, "mixer":mixer_rects(), "engine": engine.playing, "pitch": engine.pitch_scale, "events": events}) + ";")

func mixer_rects() -> Dictionary:
	var result: Dictionary={}
	for key in ["MusicVolume","EffectsVolume"]:
		var control=panel.get_node(key)
		var rect=control.get_global_rect()
		result[key]={"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y}
	var rect=mute_button.get_global_rect()
	result.mute={"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y}
	return result

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = what == NOTIFICATION_APPLICATION_FOCUS_IN
		if music != null: apply_volumes()

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	streams.clear()
