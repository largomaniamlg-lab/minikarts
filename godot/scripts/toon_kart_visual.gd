@tool
extends Node3D
@export var body_color := Color("FF4F6D")
@export var helmet_color := Color("FFD23F")
@export var show_chibi := true
var speed := 0.0
var steering := 0.0
var bounce := 0.0
var previous_vertical := 0.0
var wheel_angle := 0.0
var parts: Array=[]
const Style = preload("res://scripts/toon_style.gd")

func primitive(mesh: Mesh, pose: Transform3D, color: Color, recolor: bool=false) -> void:
	parts.append({"mesh":mesh,"pose":pose,"color":Color(color.r,color.g,color.b,1 if recolor else 0)})
func ball(size: Vector3, pos: Vector3, color: Color, recolor: bool=false) -> void:
	var mesh:=SphereMesh.new(); mesh.radius=0.5; mesh.height=1.0; mesh.radial_segments=12; mesh.rings=6
	primitive(mesh,Transform3D(Basis.IDENTITY.scaled(size),pos),color,recolor)
func painted_mesh() -> ArrayMesh:
	var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in parts:
		var arrays=part.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		for index in indices:
			tool.set_color(part.color)
			tool.set_normal((part.pose.basis.inverse().transposed()*normals[index]).normalized())
			tool.add_vertex(part.pose*vertices[index])
	return tool.commit()
func _ready() -> void:
	if Network.server_mode: set_process(false)
	if not has_node("PaintedBody"): build()
	# Mutable instance transforms must never be shared by different racers.
	for name in ["Wheels","Flames"]:
		var old=get_node(name).multimesh
		var instances:=MultiMesh.new()
		instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.mesh=old.mesh
		instances.instance_count=old.instance_count
		for index in range(old.instance_count): instances.set_instance_transform(index,old.get_instance_transform(index))
		get_node(name).multimesh=instances
	upgrade_motorsport()
	var mat=Style.material(body_color,true,0.015).duplicate() as ShaderMaterial
	mat.set_shader_parameter("use_vertex_color",true)
	mat.set_shader_parameter("finish_roughness",0.24)
	mat.set_shader_parameter("finish_metallic",0.42)
	Style.register_transient(mat)
	$PaintedBody.material_override=mat
	var tire=Style.material(Color("161a20"),true,0.012)
	tire.set_shader_parameter("finish_roughness",0.92)
	tire.set_shader_parameter("use_albedo_texture",true)
	tire.set_shader_parameter("albedo_texture",load("res://materials/toon/tire_marks.svg"))
	$Wheels.material_override=tire
	$PilotPrototype.visible=show_chibi
	$PilotPrototype/Helmet.material_override=Style.material(helmet_color,true,0.05)
	$PilotPrototype/Torso.material_override=Style.material(body_color,true,0.05)
	for node in find_children("*","GeometryInstance3D",true,false):
		if node.material_override is ShaderMaterial and node.material_override.next_pass!=null: Style.register_transient(node.material_override)
func build() -> void:
	parts.clear()
	ball(Vector3(1.4,0.45,1.95),Vector3.ZERO,Color.WHITE,true)
	ball(Vector3(1.05,0.4,0.78),Vector3(0,0.13,-0.68),Color.WHITE,true)
	for side in [-1.0,1.0]:
		ball(Vector3(0.35,0.3,1.1),Vector3(side*0.61,-0.03,0),Color.WHITE,true)
		ball(Vector3(0.19,0.19,0.35),Vector3(side*0.48,0,1.0),Color("B9CDE3"))
		ball(Vector3(0.11,0.11,0.03),Vector3(side*0.48,0,1.18),Color("30304B"))
	ball(Vector3(0.66,0.6,0.55),Vector3(0,0.25,0.25),Color("30304B"))
	ball(Vector3(0.7,0.25,0.65),Vector3(0,-0.05,0.7),Color("B9CDE3"))
	ball(Vector3(1.5,0.12,0.3),Vector3(0,0.36,0.95),Color("FFD23F"))
	ball(Vector3(0.16,0.08,0.8),Vector3(0,0.36,-0.6),Color("D4ECFF"))
	var body:=MeshInstance3D.new(); body.name="PaintedBody"; body.mesh=painted_mesh(); add_child(body)
	var torus:=TorusMesh.new(); torus.inner_radius=0.15; torus.outer_radius=0.33; torus.rings=12; torus.ring_segments=8
	var wheels:=MultiMeshInstance3D.new(); wheels.name="Wheels"
	var mm:=MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=torus; mm.instance_count=4
	wheels.multimesh=mm; wheels.material_override=Style.material(Color("161a20"),true,0.012); add_child(wheels)
	var flame_mesh:=SphereMesh.new(); flame_mesh.radius=0.5; flame_mesh.height=1; flame_mesh.radial_segments=8; flame_mesh.rings=4
	var flame:=MultiMeshInstance3D.new(); flame.name="Flames"
	var fm:=MultiMesh.new(); fm.transform_format=MultiMesh.TRANSFORM_3D; fm.mesh=flame_mesh; fm.instance_count=2; flame.multimesh=fm
	var flame_mat:=ShaderMaterial.new(); flame_mat.shader=load("res://shaders/exhaust.gdshader"); flame.material_override=flame_mat; flame.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(flame)
	var pilot:=Node3D.new(); pilot.name="PilotPrototype"; add_child(pilot)
	for spec in [["Torso",Vector3(0.4,0.48,0.35),Vector3(0,0.5,0.2),Color.WHITE],["Helmet",Vector3(0.78,0.8,0.72),Vector3(0,1.12,0.2),Color.WHITE],["Visor",Vector3(0.64,0.3,0.45),Vector3(0,1.15,-0.12),Color("2A1458")]]:
		var node:=MeshInstance3D.new(); node.name=spec[0]
		var sphere:=SphereMesh.new(); sphere.radius=0.5; sphere.height=1; sphere.radial_segments=12; sphere.rings=6
		node.mesh=sphere; node.scale=spec[1]; node.position=spec[2]; node.material_override=Style.material(spec[3],true); pilot.add_child(node)
	animate(0.0)
func animate(delta: float) -> void:
	if not has_node("Wheels"): return
	wheel_angle+=speed*delta/0.33
	for i in range(4):
		var rear:=i>=2
		var pose:=Transform3D.IDENTITY
		pose.origin=Vector3(-0.74 if i%2==0 else 0.74,-0.12,0.63 if rear else -0.61)
		pose.basis=Basis(Vector3.FORWARD,PI/2)*Basis(Vector3.UP,wheel_angle)
		pose.basis=pose.basis.scaled(Vector3.ONE*(1.1 if rear else 0.85))
		$Wheels.multimesh.set_instance_transform(i,pose)
	for i in range(2):
		var amount=clampf(absf(speed)/22.22,0,1)
		var flicker=0.85+sin(Time.get_ticks_msec()*0.031+i)*0.15
		$Flames.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3(0.16,0.16,0.2+amount*0.8)*flicker),Vector3(-0.48 if i==0 else 0.48,0,1.25+amount*0.2)))
	$Flames.visible=absf(speed)>3 and not Style.low_quality
	bounce=move_toward(bounce,0,delta*2)
	rotation.z=lerpf(rotation.z,-steering*0.06,minf(delta*10,1))
	$PaintedBody.position.y=bounce
func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	var kart=get_parent()
	if kart is CharacterBody3D:
		speed=kart.speed; steering=kart._steering
		if previous_vertical<-2 and kart.is_on_floor(): bounce=-0.08
		previous_vertical=kart.velocity.y
	animate(delta)

# Original detailed chassis, shared geometry and one merged metal surface per kart.
func upgrade_motorsport() -> void:
	parts.clear()
	ball(Vector3(0.85,0.18,1.3),Vector3(0,-0.13,-0.2),Color.WHITE,true)
	ball(Vector3(0.8,0.18,0.75),Vector3(0,-0.05,-0.8),Color.WHITE,true)
	for side in [-1.0,1.0]:
		ball(Vector3(0.32,0.27,0.95),Vector3(side*0.58,-0.02,0.05),Color.WHITE,true)
	ball(Vector3(0.58,0.5,0.5),Vector3(0,0.15,0.3),Color("151b24"))
	ball(Vector3(1.4,0.08,0.24),Vector3(0,0.4,0.85),Color.WHITE,true)
	$PaintedBody.mesh=painted_mesh()
	parts.clear()
	for side in [-1.0,1.0]:
		metal_tube(Vector3(side*0.52,-0.2,-0.9),Vector3(side*0.52,-0.2,0.85),0.035)
		metal_tube(Vector3(side*0.52,-0.2,-0.35),Vector3(side*0.72,-0.1,-0.61),0.035)
		metal_tube(Vector3(side*0.52,-0.2,0.4),Vector3(side*0.74,-0.12,0.63),0.04)
		metal_tube(Vector3(side*0.4,0.03,0.5),Vector3(side*0.4,0.03,1.15),0.08)
		metal_tube(Vector3(side*0.52,-0.15,0.8),Vector3(side*0.52,0.38,0.85),0.025)
		# Machined wheel hubs, five metallic spokes per rim.
		for z in [-0.61,0.63]:
			metal_tube(Vector3(side*0.82,-0.12,z),Vector3(side*0.88,-0.12,z),0.085)
			for spoke in range(5):
				var angle=spoke*TAU/5
				metal_tube(Vector3(side*0.87,-0.12,z),Vector3(side*0.87,-0.12+cos(angle)*0.22,z+sin(angle)*0.22),0.018)
		# Coil spring: visibly articulated suspension instead of floating wheels.
		for coil in range(7):
			var ring:=TorusMesh.new(); ring.inner_radius=0.055; ring.outer_radius=0.08; ring.rings=8; ring.ring_segments=6
			primitive(ring,Transform3D(Basis.IDENTITY,Vector3(side*0.6,-0.1+coil*0.03,0.58)),Color("ffc83d"))
	metal_tube(Vector3(-0.65,-0.17,-1),Vector3(0.65,-0.17,-1),0.05)
	metal_tube(Vector3(-0.72,-0.15,0.85),Vector3(0.72,-0.15,0.85),0.045)
	var metal:=MeshInstance3D.new(); metal.name="MotorsportChassis"; metal.mesh=painted_mesh()
	var material=Style.material(Color("b4c2d4"),false).duplicate()
	material.set_shader_parameter("use_vertex_color",true)
	material.set_shader_parameter("finish_metallic",0.75)
	material.set_shader_parameter("finish_roughness",0.3)
	metal.material_override=material; add_child(metal)
func metal_tube(a: Vector3,b: Vector3,radius: float) -> void:
	var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius
	mesh.height=a.distance_to(b); mesh.radial_segments=8
	var axis=(b-a).normalized()
	var rotation:=Quaternion(Vector3.UP,axis)
	primitive(mesh,Transform3D(Basis(rotation),(a+b)*0.5),Color("aebdce"))
