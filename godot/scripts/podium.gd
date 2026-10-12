extends Control
const Catalog = preload("res://scripts/driver_catalog.gd")

func present(entries: Array) -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text="PODIO DEL TORNEO"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",28)
	title.size=Vector2(size.x,35)
	add_child(title)
	var container := SubViewportContainer.new()
	container.position=Vector2(0,35); container.size=Vector2(size.x,size.y-35); container.stretch=true
	container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var view := SubViewport.new()
	view.size=Vector2i(container.size)
	view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	container.add_child(view)
	var world := Node3D.new()
	view.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-40,-30,0)
	world.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("132834")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color.WHITE
	env.environment.ambient_light_energy=0.65
	world.add_child(env)
	var camera := Camera3D.new()
	camera.position=Vector3(0,3.3,5.8)
	camera.fov=50
	world.add_child(camera)
	camera.look_at(Vector3(0,2.05,0))
	camera.current=true
	for rank in range(mini(3,entries.size())):
		var entry: Dictionary=entries[rank]
		var x: float = [0.0,-2.8,2.8][rank]
		var height: float=[1.15,0.75,0.45][rank]
		var gold := Color("ffd04b")
		var medal_color: Color=[gold,Color("cad6df"),Color("c88b52")][rank]
		box(world,Vector3(2.4,height,1.7),Vector3(x,height/2,0),medal_color)
		var portrait := Sprite3D.new()
		var texture: Texture2D=Catalog.PORTRAITS[clampi(int(entry.driver),0,Catalog.PORTRAITS.size()-1)]
		portrait.texture=texture
		portrait.pixel_size=2.7/float(texture.get_height())
		portrait.position=Vector3(x,height+1.35,0)
		portrait.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		portrait.shaded=false
		world.add_child(portrait)
		text(world,str(rank+1),Vector3(x,height/2,0.87),76)
		text(world,str(entry.name)+"\n%d pts" % entry.points,Vector3(x,height+3.12,0),30)
		if rank==0:
			# A playful raised arm holds a real 3D cup above the winner.
			rod(world,Vector3(0.45,height+1.25,0.15),Vector3(1.0,height+2.0,0.15),0.12,Color("ffc86b"))
			rod(world,Vector3(1.0,height+2.0,0.15),Vector3(1.0,height+2.7,0.15),0.12,Color("ffc86b"))
			var y:=height+2.75
			cylinder(world,0.24,0.24,0.08,Vector3(1,y,0.15),gold)
			cylinder(world,0.07,0.07,0.23,Vector3(1,y+0.13,0.15),gold)
			cylinder(world,0.32,0.14,0.43,Vector3(1,y+0.43,0.15),gold)
			for side in [-1,1]:
				var handle:=MeshInstance3D.new()
				var torus:=TorusMesh.new()
				torus.inner_radius=0.13; torus.outer_radius=0.19; torus.rings=12; torus.ring_segments=8
				handle.mesh=torus; handle.material_override=surface(gold)
				handle.position=Vector3(1+side*0.31,y+0.43,0.15); handle.rotation.x=PI/2
				world.add_child(handle)
		else:
			var medal:=cylinder(world,0.22,0.22,0.06,Vector3(x,height+1.45,0.2),medal_color)
			medal.rotation.x=PI/2
			rod(world,Vector3(x-0.18,height+1.9,0.15),Vector3(x,height+1.45,0.2),0.025,Color("e4483c"))
			rod(world,Vector3(x+0.18,height+1.9,0.15),Vector3(x,height+1.45,0.2),0.025,Color("e4483c"))
			text(world,str(rank+1),Vector3(x,height+1.45,0.25),28)

func surface(color: Color) -> StandardMaterial3D:
	var result:=StandardMaterial3D.new()
	result.albedo_color=color
	return result

func box(world: Node3D, dimensions: Vector3, position: Vector3, color: Color) -> void:
	var part:=MeshInstance3D.new()
	var mesh:=BoxMesh.new(); mesh.size=dimensions
	part.mesh=mesh; part.position=position; part.material_override=surface(color)
	world.add_child(part)

func cylinder(world: Node3D, top: float, bottom: float, height: float, position: Vector3, color: Color) -> MeshInstance3D:
	var part:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=top; mesh.bottom_radius=bottom; mesh.height=height; mesh.radial_segments=16
	part.mesh=mesh; part.position=position; part.material_override=surface(color)
	world.add_child(part)
	return part

func rod(world: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var part:=cylinder(world,radius,radius,from.distance_to(to),(from+to)/2,color)
	part.quaternion=Quaternion(Vector3.UP,(to-from).normalized())

func text(world: Node3D, content: String, position: Vector3, font: int) -> void:
	var label:=Label3D.new()
	label.text=content; label.position=position; label.font_size=font; label.pixel_size=0.012
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	world.add_child(label)
