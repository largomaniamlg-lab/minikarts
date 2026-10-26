extends RefCounted

const DEFAULT := "habitual"
const DRAGON := "dragon_experimental_v1"
const MODEL := "res://assets/vehicles/dragon/dragon_experimental_v1.glb"
const NAMES := ["Coche habitual", "Dragón — en pruebas"]
const IDS := [DEFAULT, DRAGON]
const CHARACTER_IDS := ["kikoso","largo","sipollo","antocino","fubux","orehas","young_ex","super_mar_ia","ketamine_yamal","tushkroisant","yisus_samuel","noga","enriquesido","ruso","dego","maik"]
static var selected := DEFAULT
static var selected_character := "kikoso"
static var loaded := false
static var config_path := "user://vehicle_selection.cfg"

static func resolve(value: Variant) -> String:
	return DRAGON if value is String and value == DRAGON else DEFAULT

static func load_selection() -> void:
	var config := ConfigFile.new()
	if config.load(config_path) == OK:
		selected = resolve(config.get_value("selection","vehicle",DEFAULT))
		var id: Variant = config.get_value("selection","character","kikoso")
		selected_character = str(id) if id in CHARACTER_IDS else "kikoso"
	loaded = true

static func save_selection() -> Error:
	var config := ConfigFile.new()
	config.set_value("selection","vehicle",selected)
	config.set_value("selection","character",selected_character)
	return config.save(config_path)

static func apply(kart: Node3D, value: Variant) -> void:
	var id := resolve(value)
	if kart.get_meta("vehicle_id","") == id: return
	var old := kart.get_node_or_null("DragonVehicle")
	if old:
		kart.remove_child(old)
		old.queue_free()
	var original := kart.get_node_or_null("ToonKartVisual")
	var driver := kart.get_node_or_null("Driver")
	if original: original.visible = id == DEFAULT
	if driver:
		driver.position = Vector3(0,-0.1,0.3) if id==DRAGON else Vector3.ZERO
		driver.scale = Vector3.ONE * 0.75 if id==DRAGON else Vector3.ONE
		driver.body.visible = id==DRAGON
	if id==DRAGON and not kart.get_tree().root.get_node("Network").server_mode:
		var model = load(MODEL).instantiate()
		model.name="DragonVehicle"
		model.position.y=-0.4
		model.set_script(load("res://scripts/dragon_visual.gd"))
		kart.add_child(model)
	kart.set_meta("vehicle_id",id)
