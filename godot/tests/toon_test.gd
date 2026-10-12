extends SceneTree
var failures:=0
func check(ok: bool, text: String) -> void:
	if not ok: failures+=1; push_error(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var style=root.get_node("ToonStyle")
	var sound=root.get_node("Sound")
	if sound.music!=null: sound.music.stop(); sound.music.stream=null
	var catalog=preload("res://scripts/driver_catalog.gd")
	check(catalog.NAMES.size()==16,"All sixteen existing pilots remain")
	var game=load("res://scenes/main.tscn").instantiate(); root.add_child(game)
	await physics_frame
	check(game.kart.has_node("Driver/PhotoFace"),"Race keeps original face sprite")
	var visual=game.kart.get_node("ToonKartVisual")
	check(not visual.get_node("PilotPrototype").visible,"Original faces are not replaced by generic helmets")
	check(visual.get_node("Wheels").multimesh.instance_count==4,"Original kart has four animated wheels")
	var other=load("res://scenes/toon/kart_prototype.tscn").instantiate(); root.add_child(other)
	other.set_process(false); visual.set_process(false)
	visual.speed=6; other.speed=0
	visual.animate(0.1); other.animate(0.1)
	check(visual.get_node("Wheels").multimesh!=other.get_node("Wheels").multimesh and visual.wheel_angle!=other.wheel_angle,"Each racer animates wheels at its own speed")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(visual.get_node("Wheels").multimesh.get_instance_transform(0).basis!=other.get_node("Wheels").multimesh.get_instance_transform(0).basis,"Real renderer retains independent wheel transforms")
	check(visual.get_node("Flames").multimesh!=other.get_node("Flames").multimesh,"Exhaust transforms cannot leak between racers")
	other.queue_free()
	var material=visual.get_node("PaintedBody").material_override
	check(material.next_pass!=null,"High quality includes kart outline")
	style.set_low(true)
	check(material.next_pass==null,"Low quality disables duplicated kart outline too")
	style.set_low(false)
	check(material.next_pass!=null,"Quality restore is reversible")
	var track=game.get_node("Track")
	track.configure(1)
	check(track.get_node("Road").get_child(0).material_override.next_pass==null,"Road has no outline")
	check(track.get_children().any(func(n):return str(n.name).begins_with("ToonStaticBatch")),"Static batching leaves physical route intact")
	for i in range(16): game.kart.get_node("Driver").set_face(i); check(game.kart.get_node("Driver").face.texture==catalog.FACES[i],"Every existing race face remains selectable")
	var safe=preload("res://scripts/toon_safe_area.gd").logical_safe_rect(Rect2(50,0,2300,1080),Vector2(2400,1080),Vector2(1280,720))
	check(safe.position.x>0 and safe.end.x<1280,"Native mobile cutouts map into logical HUD space")
	print("Toon integration: ",failures," failures")
	call_deferred("quit",0 if failures==0 else 1)
