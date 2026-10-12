extends Node3D
const Style = preload("res://scripts/toon_style.gd")
const Catalog = preload("res://scripts/driver_catalog.gd")
var car: CharacterBody3D
var photo: Sprite3D
var camera: Camera3D
var meter: Label
var lap_label: Label
var time_label: Label
var speed_label: Label
var driver_label: Label
var phase:=0.0
var automated:=true
var view:=0
var clock:=0.0
var samples: Array=[]
var capture_index:=0
var driver:=0
var capture := false
var capture_dir := ""

static func point(t: float) -> Vector3:
	return Vector3(cos(t)*25,0.25+2.8*pow(maxf(sin(t),0),2),sin(t)*17)
func _ready() -> void:
	if not has_node("StaticTrack"): build_static()
	if Engine.is_editor_hint(): return
	if Network.friends_button!=null: Network.menu.hide()
	if Sound.sound_button!=null: Sound.sound_button.hide()
	if Sound.music!=null:
		Sound.music.stop(); Sound.music.stream=null
	capture="--capture-toon" in OS.get_cmdline_user_args()
	capture_dir=ProjectSettings.globalize_path("res://").path_join("../docs/screenshots")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir=argument.trim_prefix("--capture-dir=")
	if capture: DirAccess.make_dir_recursive_absolute(capture_dir)
	if "--toon-low" in OS.get_cmdline_user_args(): Style.set_low(true)
	for node in get_node("StaticTrack").find_children("*","GeometryInstance3D",true,false):
		if node.material_override is ShaderMaterial and node.material_override.next_pass!=null: Style.register_transient(node.material_override)
	car=load("res://scenes/kart.tscn").instantiate()
	car.network_controlled=false
	car.kart_color=Style.PALETTE.red
	add_child(car)
	car._camera.queue_free()
	car.set_physics_process(false)
	photo=car.get_node("Driver/PhotoFace")
	camera=Camera3D.new(); camera.far=260; camera.fov=58; add_child(camera); camera.current=true
	build_hud()
	var light=get_node("Sun")
	light.shadow_enabled=not Style.low_quality
	light.add_to_group("toon_sun")
func mesh_node(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, bake: bool=true) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	if bake and mesh is PrimitiveMesh:
		mesh.add_uv2=true
		var stored:=ArrayMesh.new(); stored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh.surface_get_arrays(0)); mesh=stored
	node.mesh=mesh; node.position=pos; node.material_override=mat
	node.gi_mode=GeometryInstance3D.GI_MODE_STATIC if bake else GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(node); return node
func ball(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh:=SphereMesh.new(); mesh.radius=0.5; mesh.height=1; mesh.radial_segments=12; mesh.rings=6
	var node=mesh_node(parent,mesh,pos,Style.material(color,true,0.08)); node.scale=size; return node
func build_static() -> void:
	var root:=Node3D.new(); root.name="StaticTrack"; add_child(root)
	var ground:=BoxMesh.new(); ground.size=Vector3(140,0.5,115)
	mesh_node(root,ground,Vector3(0,-0.4,0),Style.material(Style.PALETTE.grass))
	var tool:=SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(96):
		var t=i*TAU/96; var next=(i+1)*TAU/96
		var a=point(t); var b=point(next)
		var na=(point(t+0.001)-point(t-0.001)).normalized().cross(Vector3.UP)*3.5
		var nb=(point(next+0.001)-point(next-0.001)).normalized().cross(Vector3.UP)*3.5
		var vertices=[a-na,b+nb,a+na,a-na,b-nb,b+nb]
		for p in vertices:
			tool.set_uv(Vector2(p.x/70+0.5,p.z/50+0.5)); tool.set_uv2(Vector2(p.x/70+0.5,p.z/50+0.5)); tool.add_vertex(p)
	tool.generate_normals()
	var road_mesh=tool.commit()
	var road=StaticBody3D.new(); road.name="Road"; root.add_child(road)
	mesh_node(road,road_mesh,Vector3.ZERO,Style.material(Style.PALETTE.asphalt))
	var collider:=CollisionShape3D.new(); collider.shape=road_mesh.create_trimesh_shape(); road.add_child(collider)
	var curbmesh:=BoxMesh.new(); curbmesh.size=Vector3(0.4,0.22,1.25)
	for parity in range(2):
		var mm:=MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=curbmesh; mm.instance_count=96
		for i in range(48):
			var t=(i*2+parity)*TAU/96
			var tangent=(point(t+0.01)-point(t)).normalized()
			for side in range(2):
				var pose=Transform3D(Basis.looking_at(tangent),point(t)+tangent.cross(Vector3.UP)*(-3.65 if side==0 else 3.65)+Vector3.UP*0.1)
				mm.set_instance_transform(i*2+side,pose)
		var curbs:=MultiMeshInstance3D.new(); curbs.multimesh=mm; curbs.material_override=Style.material(Style.PALETTE.curb if parity==0 else Color.WHITE); root.add_child(curbs)
	for kind in [0,1]:
		var sphere:=SphereMesh.new(); sphere.radius=0.5; sphere.height=1; sphere.radial_segments=10; sphere.rings=5
		var mm:=MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=sphere; mm.instance_count=24
		for i in range(24):
			var t=i*TAU/24
			var pose:=Transform3D.IDENTITY
			pose.origin=Vector3(cos(t)*38,3 if kind==0 else 0.7,sin(t)*29)
			pose.basis=Basis.IDENTITY.scaled(Vector3(4,5,4) if kind==0 else Vector3(4,1.4,3))
			mm.set_instance_transform(i,pose)
		var trees:=MultiMeshInstance3D.new(); trees.multimesh=mm; trees.material_override=Style.material(Style.PALETTE.green if kind==0 else Style.PALETTE.grass_shadow,true,0.08); root.add_child(trees)
	var lake:=SphereMesh.new(); lake.radius=0.5; lake.height=1; lake.radial_segments=32; lake.rings=8
	var water=mesh_node(root,lake,Vector3(-5,-0.12,0),Style.material(Style.PALETTE.cyan)); water.scale=Vector3(25,0.25,15)
	for i in range(7): ball(root,Vector3(18,12+float(i%3)*6,15),Vector3((i-3)*20,0,-48),Color("B05CFF").lerp(Color("52E3FF"),i/8.0))
	var beam:=BoxMesh.new(); beam.size=Vector3(8.6,0.8,0.7)
	var start=point(0)
	mesh_node(root,beam,start+Vector3(0,5,0),Style.material(Style.PALETTE.purple))
	for x in [-4.0,4.0]:
		var post:=CapsuleMesh.new(); post.radius=0.24; post.height=5
		mesh_node(root,post,start+Vector3(x,2.5,0),Style.material(Style.PALETTE.yellow,true))
	var sign:=Label3D.new(); sign.text="MINIKARTS"; sign.font=load("res://assets/fonts/Bungee-Regular.ttf"); sign.font_size=48; sign.pixel_size=0.009; sign.position=start+Vector3(0,5,0.38); sign.modulate=Style.PALETTE.yellow; sign.outline_modulate=Style.PALETTE.outline; root.add_child(sign)
	for t in [0.4,3.5]:
		var panel:=PlaneMesh.new(); panel.size=Vector2(6,3)
		var mat:=ShaderMaterial.new(); mat.shader=load("res://shaders/turbo.gdshader")
		var node=mesh_node(root,panel,point(t)+Vector3.UP*0.04,mat,false)
		node.basis=Basis.looking_at((point(t+0.01)-point(t)).normalized())
	for i in range(8):
		var crystal=Node3D.new(); crystal.name="Crystal%d" % i
		crystal.set_script(load("res://scripts/toon_crystal.gd")); crystal.position=point(0.65+i*TAU/8)+Vector3.UP*1.1; root.add_child(crystal)
	var sun:=DirectionalLight3D.new(); sun.name="Sun"; sun.rotation_degrees=Vector3(-55,-30,0); sun.light_energy=1.25; sun.shadow_enabled=true; sun.directional_shadow_max_distance=45; sun.light_bake_mode=Light3D.BAKE_DISABLED; add_child(sun)
	var env:=Environment.new(); env.background_mode=Environment.BG_SKY
	var sky:=Sky.new(); var sky_mat:=ProceduralSkyMaterial.new(); sky_mat.sky_top_color=Style.PALETTE.sky; sky_mat.sky_horizon_color=Style.PALETTE.horizon; sky_mat.ground_horizon_color=Style.PALETTE.horizon; sky_mat.ground_bottom_color=Style.PALETTE.grass_shadow; sky_mat.sky_curve=0.22; sky.sky_material=sky_mat; env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Style.PALETTE.horizon; env.ambient_light_energy=0.3
	env.fog_enabled=true; env.fog_mode=Environment.FOG_MODE_DEPTH; env.fog_depth_begin=90; env.fog_depth_end=200; env.fog_light_color=Style.PALETTE.horizon
	var world:=WorldEnvironment.new(); world.name="WorldEnvironment"; world.environment=env; add_child(world)
	var gi:=LightmapGI.new(); gi.name="IndirectLightmap"; gi.bounces=2; gi.quality=LightmapGI.BAKE_QUALITY_LOW; gi.directional=false; add_child(gi)
func label(parent: Control, text: String, rect: Rect2, size: int=24, yellow: bool=false) -> Label:
	var node:=Label.new(); node.text=text; node.position=rect.position; node.size=rect.size; node.add_theme_font_override("font",load("res://assets/fonts/Bungee-Regular.ttf" if yellow else "res://assets/fonts/ChakraPetch-Regular.ttf")); node.add_theme_font_size_override("font_size",size); node.add_theme_color_override("font_color",Style.PALETTE.yellow if yellow else Color.WHITE); node.add_theme_color_override("font_outline_color",Style.PALETTE.outline); node.add_theme_constant_override("outline_size",6); parent.add_child(node); return node
func build_hud() -> void:
	var layer:=CanvasLayer.new(); add_child(layer)
	var root:=Control.new(); root.set_script(load("res://scripts/toon_safe_area.gd")); root.scale_demo=true; root.mouse_filter=Control.MOUSE_FILTER_IGNORE; layer.add_child(root); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label(root,"1º",Rect2(28,18,90,65),48,true)
	lap_label=label(root,"VUELTA 1 / 3",Rect2(140,28,280,42),26)
	driver_label=label(root,"DEMO TOON · KIKOSO",Rect2(440,24,480,45),24,true)
	time_label=label(root,"00:00.00",Rect2(1050,28,200,40),26)
	speed_label=label(root,"0 km/h",Rect2(1050,620,190,55),30,true)
	label(root,"◇",Rect2(28,120,90,75),42,true)
	var map:=Control.new(); map.set_script(load("res://scripts/toon_minimap.gd")); map.position=Vector2(32,520); map.size=Vector2(180,140); map.demo=self; root.add_child(map)
	var controls=preload("res://scripts/touch_controls.gd").new(); root.add_child(controls)
	meter=label(root,"",Rect2(300,665,930,35),17)
	for i in range(4):
		var button:=Button.new(); button.text=["Cámara","Calidad","Piloto","Auto/manual"][i]; button.position=Vector2(830+i*106,90); button.size=Vector2(102,40); root.add_child(button)
		button.pressed.connect(func():
			if i==0: view=(view+1)%3
			elif i==1: ToonStyle.toggle_quality()
			elif i==2: driver=(driver+1)%Catalog.NAMES.size(); car.get_node("Driver").set_face(driver)
			else:
				automated=not automated
				car.reset_to(car.global_transform); car.spawn_transform=car.global_transform
				car.set_physics_process(not automated)
		)
func _process(delta: float) -> void:
	if car==null: return
	Network.menu.hide()
	if Sound.sound_button!=null: Sound.sound_button.hide()
	clock+=delta
	if automated:
		phase+=delta*0.52
		var p=point(phase)
		car.global_position=p+Vector3.UP*0.45; car.look_at(point(phase+0.03)+Vector3.UP*0.45); car.speed=13.5
	lap_label.text="VUELTA %d / 3" % (int(phase/TAU)%3+1)
	time_label.text="%02d:%05.2f" % [int(clock)/60,fmod(clock,60)]
	speed_label.text="%d km/h" % roundi(absf(car.speed)*3.6)
	driver_label.text="DEMO TOON · "+Catalog.NAMES[driver].to_upper()
	var target=car.global_position
	var forward=-car.global_basis.z
	if view==0: camera.global_position=target-forward*7.8+Vector3.UP*4.5; camera.look_at(target+forward*2+Vector3.UP*0.4)
	elif view==1: camera.global_position=Vector3(0,66,2); camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	else: camera.global_position=target+forward*6+Vector3.UP*2.6; camera.look_at(target+Vector3.UP*0.4)
	var viewport=get_viewport()
	var draws:=0
	var tris:=0
	for kind in [Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_TYPE_CANVAS]:
		draws+=viewport.get_render_info(kind,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		tris+=viewport.get_render_info(kind,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	meter.text="%s · %d FPS host · %d llamadas · %d triángulos · %s" % [RenderingServer.get_current_rendering_method(),Engine.get_frames_per_second(),draws,tris,"BAJO" if Style.low_quality else "TOON"]
	if clock>2 and clock<14: samples.append({"fps":Engine.get_frames_per_second(),"draws":draws,"triangles":tris})
	if capture and clock>5+capture_index*3:
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(capture_dir.path_join("toon-%s.png" % ["persecucion","aerea","frontal"][capture_index]))
		capture_index+=1
		if capture_index<3: view=capture_index
		else:
			var file=FileAccess.open(capture_dir.path_join("toon-metrics.json"),FileAccess.WRITE)
			file.store_string(JSON.stringify({"renderer":RenderingServer.get_current_rendering_method(),"samples":samples,"device":"cloud software rendering; NOT Android measurements"},"\t")); file.close(); set_process(false); get_tree().call_deferred("quit")
