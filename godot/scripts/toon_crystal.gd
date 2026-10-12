extends Node3D
func _ready() -> void:
	if has_node("Gem"): return
	var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices=[Vector3.UP*0.55,Vector3.DOWN*0.55,Vector3.LEFT*0.32,Vector3.FORWARD*0.32,Vector3.RIGHT*0.32,Vector3.BACK*0.32]
	for i in range(4):
		for index in [0,2+i,2+(i+1)%4,1,2+(i+1)%4,2+i]: tool.add_vertex(vertices[index])
	tool.generate_normals()
	var visual:=MeshInstance3D.new(); visual.name="Gem"; visual.mesh=tool.commit(); visual.material_override=ToonStyle.material(ToonStyle.PALETTE.cyan,true,0.04,true); add_child(visual)
	add_to_group("toon_crystals")
func _process(delta: float) -> void:
	rotate_y(delta*1.5)
	for kart in get_tree().get_nodes_in_group("karts"):
		if global_position.distance_to(kart.global_position)<1:
			visible=false; set_process(false)
			get_tree().create_timer(5).timeout.connect(func(): visible=true; set_process(true))
			break
