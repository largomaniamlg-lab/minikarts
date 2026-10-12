extends SceneTree
var game: Node3D
var camera: Camera3D
var id:=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game); current_scene=game
	await process_frame
	game.set_process(false); game.kart.set_physics_process(false)
	game.race_menu.hide(); game.hud.hide()
	camera=Camera3D.new(); camera.far=1500; camera.fov=55
	game.add_child(camera)
	set_scenario(1)
func set_scenario(value: int) -> void:
	id=value
	var track=game.get_node("Track")
	track.configure(id)
	track.get_node("NeutralSleeper").set_physics_process(false)
	var minimum: Vector3=track.route[0]
	var maximum: Vector3=track.route[0]
	for point in track.route: minimum=minimum.min(point); maximum=maximum.max(point)
	var center=(minimum+maximum)*0.5
	var span=maxf(maximum.x-minimum.x,maximum.z-minimum.z)
	camera.global_position=center+Vector3(span*0.45,span*0.95,span*0.95)
	camera.look_at(center)
	camera.current=true
	if OS.has_feature("web"): JavaScriptBridge.eval("window.scenarioPreview="+JSON.stringify({"id":id,"boosts":track.boost_sites.size()})+";")
func _process(_delta: float) -> bool:
	if OS.has_feature("web"):
		var value=int(JavaScriptBridge.eval("window.nextScenario || 0"))
		if value in [1,2,3,4] and value!=id: set_scenario(value)

	return false
