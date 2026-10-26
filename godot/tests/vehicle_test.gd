extends SceneTree
const Vehicles=preload("res://scripts/vehicle_catalog.gd")
var network: Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	network=root.get_node("Network")
	Vehicles.config_path="res://tests/vehicle-roundtrip.cfg"
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.race_menu.hide();network.menu.hide()
	var kart=game.kart
	kart.set_physics_process(false)
	var collider: CollisionShape3D
	for child in kart.get_children():
		if child is CollisionShape3D:collider=child
	var shape_size=collider.shape.size
	var shape_position=collider.position
	for index in range(16):
		game.race_menu.select(index)
		game.race_menu.choose_vehicle(1)
		check(kart.get_node("Driver").face_id==index,"Dragon keeps character %d"%index)
		check(kart.get_meta("vehicle_id")==Vehicles.DRAGON,"Dragon selected independently")
		check(collider.shape.size==shape_size and collider.position==shape_position,"Same collision for both vehicles")
		game.race_menu.choose_vehicle(0)
		check(kart.get_node("Driver").face_id==index and kart.get_node("ToonKartVisual").visible,"Usual vehicle and character restored")
	game.race_menu.select(6);game.race_menu.choose_vehicle(1)
	Vehicles.selected=Vehicles.DEFAULT;Vehicles.selected_character="kikoso"
	Vehicles.load_selection()
	check(Vehicles.selected==Vehicles.DRAGON and Vehicles.selected_character=="young_ex","Roundtrip preserves stable vehicle and character IDs")
	check(Vehicles.resolve("unknown_future")==Vehicles.DEFAULT and Vehicles.resolve(99)==Vehicles.DEFAULT,"Unknown vehicle has safe fallback")
	var dragon=kart.get_node("DragonVehicle")
	check(dragon.find_children("V2_wheel*","Node3D",true,false).size()==4,"Four wheels exported separately")
	var visual_bounds:=AABB()
	var initialized:=false
	for mesh in dragon.find_children("*","MeshInstance3D",true,false):
		var box: AABB=mesh.global_transform*mesh.get_aabb()
		visual_bounds=visual_bounds.merge(box) if initialized else box
		initialized=true
	check(visual_bounds.size.x<1.25 and visual_bounds.size.z<3.2,"Uniform scale fits width and platform length")
	check(visual_bounds.size.y<1.2,"Dragon visual alone fits 1.2m beam")
	network.selected_bots=1
	game.start_offline()
	check(game.kart.get_meta("vehicle_id")==Vehicles.DRAGON,"Vehicle retained at race start")
	game.race_menu.open()
	check(game.race_menu.visible and Vehicles.selected==Vehicles.DRAGON,"Menu return retains selection")
	game.clear_offline()
	kart.set_physics_process(false)
	game.race_menu.hide();network.menu.hide()
	if DisplayServer.get_name()!="headless":
		for i in range(20):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/dragon-release/race-camera.png"))
		kart._camera.set_script(null)
		kart._camera.global_position=kart.global_position+Vector3(2.4,1.4,-3)
		kart._camera.look_at(kart.global_position+Vector3(0,0.3,0.25))
		for i in range(15):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/dragon-release/dragon-side.png"))
	print("Vehicle validation: %d checks, %d failures; visual bounds %s"%[checks,failures,visual_bounds])
	quit(0 if failures==0 else 1)
