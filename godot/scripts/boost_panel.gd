extends Area3D
const DURATION := 3.0
const SPEED := 80.0 / 3.6
var accent := Color("49efbd")
var touched: Dictionary = {}

func _ready() -> void:
	add_to_group("boost_panels")
	collision_layer=0; collision_mask=1
	var detector:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(14,1.8,4)
	detector.shape=shape; detector.position.y=0.65
	add_child(detector)
	body_exited.connect(func(body): touched.erase(body.get_instance_id()))
	if Network.server_mode: return
	var surface:=StandardMaterial3D.new()
	surface.albedo_color=accent.darkened(0.45)
	surface.emission_enabled=true; surface.emission=accent*0.3
	var pad:=MeshInstance3D.new()
	var plane:=PlaneMesh.new(); plane.size=Vector2(14,4)
	pad.mesh=plane; pad.position.y=0.09; pad.material_override=surface
	add_child(pad)
	var arrows:=SurfaceTool.new()
	arrows.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-4.5,0.0,4.5]:
		for z in [-0.5,0.8]:
			var vertices=[Vector3(x-1.5,0.1,z+0.4),Vector3(x,0.1,z-0.6),Vector3(x+1.5,0.1,z+0.4),Vector3(x+1.5,0.1,z+0.9),Vector3(x,0.1,z-0.1),Vector3(x-1.5,0.1,z+0.9)]
			for i in [0,4,1,0,5,4,1,3,2,1,4,3]:
				arrows.set_normal(Vector3.UP); arrows.add_vertex(vertices[i])
	var marks:=MeshInstance3D.new()
	marks.mesh=arrows.commit()
	var ink:=StandardMaterial3D.new()
	ink.albedo_color=accent; ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	marks.material_override=ink; add_child(marks)
	for side in [-8.0,8.0]:
		var sign:=Label3D.new()
		sign.text="BOOST\n80 km/h"; sign.position=Vector3(side,2,0)
		sign.font_size=40; sign.pixel_size=0.012; sign.modulate=accent
		sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(sign)

func _physics_process(_delta: float) -> void:
	if Network.playing and not Network.server_mode: return
	for body in get_overlapping_bodies():
		var id: int=body.get_instance_id()
		if not touched.has(id) and body.has_method("try_boost") and body.try_boost():
			touched[id]=true
