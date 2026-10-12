extends RefCounted
const TITLES := ["Circuito de juguete","Laboratorio nuclear","Jungla tropical","Desierto y taller","Ciudad futurista"]
const GROUND := [Color("76bc4c"),Color("527178"),Color("589f4c"),Color("c7a06b"),Color("29344d")]
const ROAD := [Color("505968"),Color("293c47"),Color("4b5551"),Color("625951"),Color("343550")]
const ACCENTS := [Color("ed5046"),Color("e7ca45"),Color("65cbb0"),Color("f0a846"),Color("66e8eb")]
const BARRIERS := [Color("fff4d8"),Color("26353c"),Color("f1dfaf"),Color("f1d5a4"),Color("7967b4")]
const ICONS := [null,preload("res://assets/scenarios/radiation.svg"),preload("res://assets/scenarios/leaf.svg"),preload("res://assets/scenarios/fuel.svg"),preload("res://assets/scenarios/energy.svg")]
const SKY := [Color("398cdb"),Color("6f99ad"),Color("369cce"),Color("83a4c4"),Color("162643")]
const HORIZON := [Color("b5e6fa"),Color("c5e1dc"),Color("b9eaca"),Color("ffe2b1"),Color("635388")]

static func surface(color: Color, glow: bool=false) -> Material:
	return ToonStyle.material(color,true,0.07,glow)

static func piece(parent: Node3D, mesh: Mesh, position: Vector3, mat: Material) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	node.mesh=ToonStyle.smooth_mesh(mesh) if mesh is BoxMesh else mesh; node.position=position; node.material_override=mat
	parent.add_child(node)
	return node

static func block(parent: Node3D, size: Vector3, position: Vector3, mat: Material) -> MeshInstance3D:
	var mesh:=BoxMesh.new(); mesh.size=size
	return piece(parent,mesh,position,mat)

static func cylinder(parent: Node3D, radius: float, height: float, position: Vector3, mat: Material, top: float=-1.0) -> MeshInstance3D:
	var mesh:=CylinderMesh.new()
	mesh.bottom_radius=radius; mesh.top_radius=radius if top<0 else top
	mesh.height=height; mesh.radial_segments=12
	return piece(parent,mesh,position,mat)

static func sphere(parent: Node3D, size: Vector3, position: Vector3, mat: Material) -> MeshInstance3D:
	var mesh:=SphereMesh.new(); mesh.radius=0.5; mesh.height=1
	mesh.radial_segments=12; mesh.rings=6
	var node=piece(parent,mesh,position,mat); node.scale=size
	return node

static func badge(parent: Node3D, theme: int, position: Vector3, width: float) -> void:
	var icon:=Sprite3D.new()
	icon.texture=ICONS[theme]; icon.pixel_size=width/128.0
	icon.position=position; icon.shaded=false
	parent.add_child(icon)

static func sky(track: Node3D, id: int) -> void:
	var world=track.get_parent().get_node_or_null("WorldEnvironment")
	if world==null: return
	var material=world.environment.sky.sky_material
	material.sky_top_color=SKY[id]; material.sky_horizon_color=HORIZON[id]
	material.ground_horizon_color=HORIZON[id]; material.ground_bottom_color=HORIZON[id].darkened(0.15)
	material.sky_curve=0.22
	material.ground_curve=0.35
	world.environment.ambient_light_color=HORIZON[id]
	world.environment.ambient_light_energy=0.35 if id!=4 else 0.5
	world.environment.fog_light_color=HORIZON[id]

static func safe_site(track: Node3D, distance: float, lateral: float, clearance: float) -> Transform3D:
	var candidate=track.transform_at(distance,lateral,0)
	for extra in range(0,81,8):
		candidate=track.transform_at(distance,lateral+signf(lateral)*extra,0)
		var nearest=track.nearest(candidate.origin)
		if candidate.origin.distance_to(track.sample(nearest.distance))>=clearance: return candidate
	return candidate

static func accents(track: Node3D, parent: Node3D, id: int) -> void:
	var instances: Array[Transform3D]=[]
	for i in range(48):
		var pose=safe_site(track,(i+0.3)*track.track_length/48,15 if i%2==0 else -15,14)
		pose.origin.y=0.9 if id==1 else (2.0 if id==4 else 1.1)
		instances.append(pose)
	var mesh: Mesh
	if id in [1,4]:
		var cube:=BoxMesh.new(); cube.size=Vector3(0.7,1.2,5.0) if id==1 else Vector3(0.45,4,0.45)
		mesh=cube
	else:
		var ball:=SphereMesh.new(); ball.radius=1.6; ball.height=2.2; ball.radial_segments=12; ball.rings=6
		mesh=ball
	var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D; batch.mesh=mesh; batch.instance_count=instances.size()
	for i in range(instances.size()): batch.set_instance_transform(i,instances[i])
	var node:=MultiMeshInstance3D.new(); node.multimesh=batch
	node.material_override=surface([Color.WHITE,Color("6cafb1"),Color("287d49"),Color("ad8058"),Color("688be8")][id],id in [1,4])
	parent.add_child(node)
	if id==1:
		var pool:=Node3D.new(); pool.transform=safe_site(track,track.track_length*0.45,-42,28); parent.add_child(pool)
		block(pool,Vector3(12,0.15,16),Vector3(0,0.1,0),surface(Color("4ddd8c"),true))
		for side in [-6.0,6.0]: block(pool,Vector3(0.5,1,17),Vector3(side,0.5,0),surface(Color("809497")))
		for side in [-8.0,8.0]: block(pool,Vector3(12,1,0.5),Vector3(0,0.5,side),surface(Color("809497")))

static func build(track: Node3D, id: int) -> void:
	if Network.server_mode: return
	var scenery:=Node3D.new()
	scenery.name="ScenarioDecor"
	scenery.add_to_group("scenario_decor")
	track.add_child(scenery)
	atmosphere(track,scenery,id)
	var concrete=surface(Color("a8bdbe"))
	var steel=surface(Color("596d7c"))
	var green=surface(Color("5bee96"),true)
	var amber=surface(Color("f5cd54"),true)
	for i in range(24):
		var site:=Node3D.new()
		site.transform=safe_site(track,(i+0.3)*track.track_length/24,26 if i%2==0 else -26,22)
		scenery.add_child(site)
		match id:
			1:
				if i%3==0:
					block(site,Vector3(13,8,7),Vector3(0,4,0),concrete)
					block(site,Vector3(12,1,7.2),Vector3(0,7.8,0),steel)
					for x in [-4.0,0.0,4.0]: block(site,Vector3(2.8,2.5,0.1),Vector3(x,4,3.6),green)
					badge(site,1,Vector3(0,6,3.7),1.7)
				else:
					cylinder(site,3,8,Vector3(0,4,0),steel)
					cylinder(site,3.1,0.55,Vector3(0,1.5,0),amber)
					cylinder(site,3.1,0.55,Vector3(0,6.5,0),amber)
					badge(site,1,Vector3(0,4,3.1),2.4)
					var pipe=cylinder(site,0.5,9,Vector3(0,8,4),green)
					pipe.rotation.x=PI/2
			2:
				cylinder(site,0.8,8,Vector3(0,4,0),surface(Color("8b6b47")),0.55)
				for leaf in range(5):
					var branch=block(site,Vector3(1.7,0.25,7),Vector3(0,8,0),surface(Color("227d4e")))
					branch.rotation=Vector3(-0.22,leaf*TAU/5,0)
				if i%3==0: sphere(site,Vector3(5,3,4),Vector3(4,1.5,0),surface(Color("879b7e")))
			3:
				if i%3==0:
					block(site,Vector3(10,4,7),Vector3(0,2,0),surface(Color("a46243")))
					block(site,Vector3(11,0.4,8),Vector3(0,4,0),surface(Color("493e3f")))
					badge(site,3,Vector3(0,2.8,3.6),2.4)
					for tire in range(3): cylinder(site,1.2,0.7,Vector3(6,0.35+tire*0.7,2),surface(Color("292f34")))
				else:
					var cactus=surface(Color("547647"))
					cylinder(site,0.65,6,Vector3(0,3,0),cactus)
					sphere(site,Vector3(1.3,1.3,1.3),Vector3(0,6,0),cactus)
					var arm=cylinder(site,0.4,3,Vector3(1.5,3,0),cactus); arm.rotation.z=PI/2
					cylinder(site,0.4,2.5,Vector3(3,4.1,0),cactus)
			4:
				var height=12.0+float(i%4)*5
				block(site,Vector3(9,height,7),Vector3(0,height/2,0),surface(Color("29364f")))
				block(site,Vector3(9.3,0.3,7.3),Vector3(0,height,0),surface(Color("b38aff"),true))
				for row in range(3): block(site,Vector3(7,0.45,0.1),Vector3(0,height*(row+1)/4,3.6),surface(Color("50d5dc"),true))
				badge(site,4,Vector3(0,4,3.7),2.1)
	if id==1:
		for distance in [track.track_length*0.2,track.track_length*0.65]:
			var tower:=Node3D.new()
			tower.transform=safe_site(track,distance,-52,26); scenery.add_child(tower)
			cylinder(tower,11,13,Vector3(0,6.5,0),concrete,7)
			cylinder(tower,7,8,Vector3(0,17,0),concrete,9)
			cylinder(tower,9.4,0.7,Vector3(0,21,0),steel)
			for puff in range(3): sphere(tower,Vector3(10+puff*2,6,8+puff),Vector3(puff*2,24+puff*4,0),surface(Color("dce8df")))
		var gate:=Node3D.new()
		gate.transform=track.transform_at(25); scenery.add_child(gate)
		for side in [-12.0,12.0]: cylinder(gate,0.65,9,Vector3(side,4.5,0),steel)
		var bridge=cylinder(gate,0.65,24,Vector3(0,9,0),steel); bridge.rotation.z=PI/2
		var title:=Label3D.new()
		title.text="SECTOR K · LABORATORIO"; title.position=Vector3(0,10,0); title.font_size=52; title.pixel_size=0.025
		title.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		gate.add_child(title)
	accents(track,scenery,id)
	# Keep the running joke, with themed plinths instead of random trees.
	for i in range(4):
		var joke:=Node3D.new()
		joke.transform=safe_site(track,track.track_length*(0.12+i*0.22),19,16)
		scenery.add_child(joke)
		block(joke,Vector3(4,1,4),Vector3(0,0.5,0),surface(ACCENTS[id]))
		var legs:=Sprite3D.new()
		legs.texture=preload("res://assets/memes/legs.png"); legs.pixel_size=5.0/legs.texture.get_height()
		legs.position=Vector3(0,3.5,0); legs.billboard=BaseMaterial3D.BILLBOARD_ENABLED; legs.shaded=false
		joke.add_child(legs)

# Static horizon silhouettes and clouds: one shared mesh per batch, no physics.
static func atmosphere(track: Node3D, parent: Node3D, id: int) -> void:
	var center := Vector3.ZERO
	for point in track.route: center += point
	center /= track.route.size()
	var mesh := SphereMesh.new()
	mesh.radius=0.5; mesh.height=1; mesh.radial_segments=12; mesh.rings=6
	var batch := MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D; batch.mesh=mesh
	batch.instance_count=36 if id!=4 else 64
	for i in range(batch.instance_count):
		var angle := float(i)*2.399963
		var pose := Transform3D.IDENTITY
		if id==4:
			pose.origin=center+Vector3(cos(angle)*340,90+float(i%7)*19,sin(angle)*340)
			pose.basis=Basis.IDENTITY.scaled(Vector3.ONE*(1.0+float(i%3)*0.5))
		else:
			pose.origin=center+Vector3(cos(angle)*(170+float(i%3)*60),62+float(i%4)*8,sin(angle)*(170+float(i%3)*60))
			pose.basis=Basis.IDENTITY.scaled(Vector3(25+float(i%3)*8,6,12))
		batch.set_instance_transform(i,pose)
	var node := MultiMeshInstance3D.new()
	node.multimesh=batch
	var mat=StandardMaterial3D.new()
	mat.albedo_color=Color("c7ddff") if id==4 else Color("fff1dc") if id==3 else Color("edf6fa")
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override=mat; parent.add_child(node)
	if id==4:
		sphere(parent,Vector3(22,22,22),center+Vector3(-240,100,-280),mat)
	# Mountains/dunes stay well beyond the driving area.
	for i in range(16):
		var angle=float(i)*TAU/16
		var point=center+Vector3(cos(angle)*440,0,sin(angle)*440)
		sphere(parent,Vector3(100,35+float(i%4)*16,85),point,surface(GROUND[id].darkened(0.14)))
