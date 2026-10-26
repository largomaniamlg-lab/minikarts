extends SubViewportContainer
var kart: Node3D
var camera: Camera3D
func _ready() -> void:
	stretch=true
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var view:=SubViewport.new()
	view.size=Vector2i(600,330)
	view.transparent_bg=true
	view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	add_child(view)
	var world:=Node3D.new()
	view.add_child(world)
	kart=preload("res://scenes/kart.tscn").instantiate()
	kart.transform=Transform3D.IDENTITY
	world.add_child(kart)
	kart.set_physics_process(false)
	kart._camera.queue_free()
	kart.get_node("Driver").set_physics_process(false)
	for rot in [Vector3(-45,-35,0),Vector3(-20,130,0)]:
		var light:=DirectionalLight3D.new()
		light.rotation_degrees=rot
		light.light_energy=1.2
		world.add_child(light)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("b6d4e8")
	environment.environment.ambient_light_energy=0.6
	world.add_child(environment)
	camera=Camera3D.new()
	camera.position=Vector3(2.5,1.5,-3.4)
	world.add_child(camera)
	camera.look_at(Vector3(0,0.4,0.15))
	camera.fov=45
	camera.current=true
func choose(driver_id: int,vehicle: String) -> void:
	if not is_instance_valid(kart): return
	kart.get_node("Driver").set_face(driver_id)
	preload("res://scripts/vehicle_catalog.gd").apply(kart,vehicle)
