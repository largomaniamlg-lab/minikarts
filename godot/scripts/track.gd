extends Node3D

const Scenery = preload("res://scripts/scenario_theme.gd")
const Circuits = preload("res://scripts/circuit_catalog.gd")
var layout_id := 0
var route := PackedVector3Array()
var distances := PackedFloat32Array()
var track_length := 0.0
var boost_sites: Array[float] = []
var ramp_sites: Array = []
var gaps: Array = []
var gate_points: Array[Vector3] = []
const SEGMENTS: int = 96
const Obstacle = preload("res://scripts/obstacle.gd")

func _ready() -> void:
	if layout_id > 0:
		_build_new()
		return
	var grass := material(Color("76bc4c"))
	var asphalt := material(Color("505968"))
	var white := material(Color("fff4d8"))
	var coral := material(Color("ed5046"))
	var blue := material(Color("4d99c7"))
	box("Ground", Vector3(120, 1, 120), Vector3(0, -0.5, 0), grass, true)
	annulus(21.0, 39.0, 0.018, asphalt)
	annulus(20.8, 21.15, 0.03, white)
	annulus(38.85, 39.2, 0.03, white)
	for i in range(SEGMENTS):
		var angle := TAU * float(i) / float(SEGMENTS)
		var next_angle: float = TAU * float(i + 1) / float(SEGMENTS)
		for radius: float in [20.5, 39.5]:
			var start: Vector3 = track_point(angle, radius, 0.55)
			var end: Vector3 = track_point(next_angle, radius, 0.55)
			var direction: Vector3 = end - start
			var barrier := box("Barrier", Vector3(direction.length() + 0.12, 1.1, 0.45), (start + end) * 0.5, coral if i % 2 == 0 else white, true)
			barrier.rotation.y = -atan2(direction.z, direction.x)
	for i in range(48):
		var angle := TAU * float(i) / 48.0
		var stripe := box("LaneStripe", Vector3(1.1, 0.025, 0.16), track_point(angle, 30.0, 0.045), white)
		var tangent: Vector3 = track_point(angle + 0.01, 30.0, 0.045) - track_point(angle, 30.0, 0.045)
		stripe.rotation.y = -atan2(tangent.z, tangent.x)
	for x in range(18):
		for z in range(2):
			box("FinishTile", Vector3(1, 0.025, 0.65), Vector3(21.5 + x, 0.065, -0.325 + z * 0.65), white if (x + z) % 2 == 0 else asphalt)
	# Trees use only original primitive geometry, safely outside the driving area.
	var bark := material(Color("835342"))
	var foliage := material(Color("49a94b"))
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		var radius := 47.0 + float(i % 3)
		var position := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		box("Trunk", Vector3(0.45, 2.0, 0.45), position + Vector3(0, 1, 0), bark)
		for tuft in range(3):
			var crown := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 1.35
			sphere.height = 2.7
			sphere.radial_segments = 16
			sphere.rings = 8
			crown.mesh = sphere
			crown.material_override = foliage
			crown.position = position + Vector3((tuft - 1) * 0.9, 2.8 + (0.9 if tuft == 1 else 0.0), 0)
			add_child(crown)
	_build_scenery()

	for tier in range(3):
		box("Grandstand", Vector3(13, 0.6, 1.5), Vector3(0, 0.3 + tier * 0.6, -48 - tier * 1.5), blue if tier % 2 == 0 else white)
	box("InfieldAccent", Vector3(8, 0.15, 5), Vector3(0, 0.075, 0), blue)
	_build_obstacles()
	var sleeper := preload("res://scripts/neutral_sleeper.gd").new()
	add_child(sleeper)
	for i in range(12):
		var decoration := Sprite3D.new()
		decoration.texture = preload("res://assets/memes/legs.png")
		decoration.pixel_size = 6.0 / float(decoration.texture.get_height())
		decoration.position = track_point(TAU * float(i) / 12.0, 44.0, 3.0)
		decoration.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		decoration.shaded = false
		decoration.name = "LegTree%d" % i
		add_child(decoration)

func track_point(angle: float, base_radius: float = 30.0, height: float = 0.0) -> Vector3:
	if layout_id > 0:
		return sample(fposmod(angle,TAU)/TAU*track_length,base_radius-30.0,height)
	var radius: float = base_radius + 3.0 * sin(3.0 * angle)
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)

func _build_obstacles() -> void:
	if layout_id > 0:
		_build_new_crates()
		return
	var yellow := material(Color("ffc93c"))
	var occupied: Array[Vector3] = []
	for index: int in range(6):
		var angle: float = 0.65 + float(index) * 0.90
		var offset: float = -3.5 if index % 2 == 0 else 3.5
		var low := box("JumpBlock", Vector3(4.0, 0.55, 1.1), track_point(angle, 30.0 + offset, 0.275), yellow, true)
		low.rotation.y = -angle
		low.add_to_group("obstacles")
		occupied.append(low.position)
	for index: int in range(8):
		var angle: float = 0.9 + float(index) * 0.65
		var crate := Obstacle.new()
		crate.name = "BreakableCrate"
		crate.position = track_point(angle, 30.0 + (-4.0 if index % 2 == 0 else 4.0), 0.7)
		while occupied.any(func(p): return p.distance_to(crate.position) < 7.0):
			angle += 0.08
			crate.position = track_point(angle,30.0 + (-4.0 if index % 2 == 0 else 4.0),0.7)
		crate.rotation.y = -angle
		occupied.append(crate.position)
		add_child(crate)

func reset_obstacles() -> void:
	if has_node("NeutralSleeper"):
		get_node("NeutralSleeper").reset_path()
	for child in get_children():
		if child.is_in_group("obstacles"):
			remove_child(child)
			child.queue_free()
	_build_obstacles()

func material(color: Color) -> Material:
	return ToonStyle.material(color)

func box(label: String, size: Vector3, position: Vector3, surface: Material, solid: bool = false) -> Node3D:
	var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
	root.name = label
	root.position = position
	add_child(root)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = surface
	root.add_child(visual)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		root.add_child(collision)
	return root

func annulus(inner: float, outer: float, height: float, surface: Material) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(SEGMENTS):
		var a := TAU * float(i) / float(SEGMENTS)
		var b := TAU * float(i + 1) / float(SEGMENTS)
		var p0: Vector3 = track_point(a, inner, height)
		var p1: Vector3 = track_point(a, outer, height)
		var p2: Vector3 = track_point(b, outer, height)
		var p3: Vector3 = track_point(b, inner, height)
		# Godot front faces use clockwise winding when viewed from above.
		for point in [p0, p1, p2, p0, p2, p3]:
			builder.set_normal(Vector3.UP)
			builder.add_vertex(point)
	var visual := MeshInstance3D.new()
	visual.mesh = builder.commit()
	visual.material_override = surface
	add_child(visual)

func _scenery_ball(position: Vector3, dimensions: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	visual.mesh = mesh
	visual.position = position
	visual.scale = dimensions
	visual.material_override = material(color)
	add_child(visual)

func _build_scenery() -> void:
	# No colliders: new scenery cannot block racers, bots, shots or the follow camera.
	for index in range(10):
		var angle := TAU * index / 10.0
		_scenery_ball(Vector3(cos(angle) * 70.0, 1.0, sin(angle) * 70.0), Vector3(22, 12 + index % 3 * 4, 20), Color("84bd63"))
	for index in range(6):
		var angle := TAU * index / 6.0
		for tuft in range(3):
			_scenery_ball(Vector3(cos(angle) * 80.0 + tuft * 3.0, 24 + index % 2 * 4, sin(angle) * 80.0), Vector3(9, 4.0 + (2 if tuft == 1 else 0), 5), Color("f4faff"))
	var gold := material(Color("ffd05b"))
	for x in [20.0, 40.0]:
		box("FinishArchPost", Vector3(0.55, 5.2, 0.55), Vector3(x, 2.6, 0), gold)
	box("FinishArch", Vector3(20.5, 0.85, 0.60), Vector3(30, 5.1, 0), material(Color("329ad2")))
	var text := Label3D.new()
	text.text = "MINIKARTS"
	text.font_size = 64
	text.pixel_size = 0.013
	text.position = Vector3(30, 5.05, -0.37)
	text.modulate = Color("fff0bb")
	text.no_depth_test = false
	text.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	text.rotation.y = PI
	add_child(text)

func configure(id: int) -> void:
	layout_id = Circuits.valid(id)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	route.clear(); distances.clear(); boost_sites.clear(); ramp_sites.clear(); gaps.clear(); gate_points.clear()
	_ready()
	Scenery.sky(self,layout_id)
	if not Network.server_mode: ToonStyle.batch_static(self)

func _build_new() -> void:
	route = Circuits.points(layout_id)
	distances.append(0.0)
	for i in range(route.size()):
		distances.append(distances[-1]+route[i].distance_to(route[(i+1)%route.size()]))
	track_length = distances[-1]
	_choose_ramps()
	_choose_boosts()
	var minimum := route[0]
	var maximum := route[0]
	for p in route: minimum = minimum.min(p); maximum = maximum.max(p)
	box("Ground",maximum-minimum+Vector3(270,1,270),(minimum+maximum)*0.5-Vector3(0,0.55,0),material(Scenery.GROUND[layout_id]))
	var road := SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(route.size()):
		var middle := (distances[i]+distances[i+1])*0.5
		if in_gap(middle): continue
		var a := sample(distances[i],-9,0.025)
		var b := sample(distances[i],9,0.025)
		var c := sample(distances[i+1],9,0.025)
		var d := sample(distances[i+1],-9,0.025)
		for p in [a,c,b,a,d,c]:
			road.set_normal(Vector3.UP); road.add_vertex(p)
	var road_mesh := road.commit()
	var road_body := StaticBody3D.new()
	road_body.name = "Road"
	add_child(road_body)
	var road_visual := MeshInstance3D.new()
	road_visual.mesh = road_mesh; road_visual.material_override = material(Scenery.ROAD[layout_id])
	road_body.add_child(road_visual)
	var road_shape := CollisionShape3D.new()
	road_shape.shape = road_mesh.create_trimesh_shape()
	road_body.add_child(road_shape)
	var white := material(Scenery.BARRIERS[layout_id])
	var coral := material(Scenery.ACCENTS[layout_id])
	for i in range(ceili(track_length/10)):
		var from := i*10.0
		var to := minf(track_length,from+10.0)
		for side in [-9.7,9.7]:
			var a := sample(from,side,0.55)
			var b := sample(to,side,0.55)
			var barrier := box("Barrier",Vector3(0.5,1.1,a.distance_to(b)+0.2),(a+b)*0.5,coral if i%2==0 else white,true)
			barrier.basis = Basis.looking_at((b-a).normalized())
		if i%2==0 and not in_gap(from):
			var stripe := box("LaneStripe",Vector3(0.17,0.025,2),sample(from,0,0.065),white)
			stripe.basis = Basis.looking_at(tangent(from))
	for gap in gaps:
		var pit := box("Hole",Vector3(18.4,0.02,gap.end-gap.start),sample((gap.start+gap.end)*0.5,0,-0.02),material(Color("10151e")))
		pit.basis = Basis.looking_at(tangent(gap.start))
		pit.add_to_group("track_holes")
	for site in ramp_sites:
		var ramp = preload("res://scripts/ramp.gd").new()
		ramp.theme_id=layout_id
		ramp.dangerous = site.dangerous
		ramp.width = 18.0 if site.dangerous else 7.0
		ramp.height = 1.6 if site.dangerous else 1.2
		ramp.safe_spawn = transform_at(site.distance-30.0)
		ramp.transform = transform_at(site.distance+3.5,site.offset,0.025)
		add_child(ramp)
	_build_new_finish()
	Scenery.build(self,layout_id)
	for distance in boost_sites:
		var panel=preload("res://scripts/boost_panel.gd").new()
		panel.accent=Color("55efbd") if layout_id==1 else Scenery.ACCENTS[layout_id]
		panel.transform=transform_at(distance,0,0.035)
		add_child(panel)
	_build_obstacles()
	add_child(preload("res://scripts/neutral_sleeper.gd").new())

func _choose_boosts() -> void:
	var desired_count=[0,3,2,2,3][layout_id]
	for index in range(desired_count):
		var desired=track_length*(0.07+index*0.28)
		var best: float=-1
		var score: float=INF
		for distance in range(40,int(track_length)-100,3):
			if boost_sites.any(func(site): return absf(site-distance)<100): continue
			if ramp_sites.any(func(site): return fposmod(site.distance-distance,track_length)<95 or fposmod(distance-site.distance,track_length)<30): continue
			var straight=true
			for offset in range(-8,46,5):
				if tangent(distance).angle_to(tangent(distance+offset))>0.1: straight=false; break
			if not straight: continue
			if absf(distance-desired)<score: score=absf(distance-desired); best=distance
		if best<0: break
		boost_sites.append(best)

func _choose_ramps() -> void:
	for index in range(Circuits.RAMP_COUNTS[layout_id]):
		var desired := track_length*(0.18+index*0.16)
		var best := -1.0
		var score := INF
		for s in range(40,int(track_length)-60,3):
			var angle := 0.0
			for offset in (range(-20,31,4) if index==0 else range(-8,17,4)):
				angle=maxf(angle,tangent(s).angle_to(tangent(s+offset)))
			if angle > (0.025 if index==0 else 0.16): continue
			if ramp_sites.any(func(site): return absf(site.distance-s)<65): continue
			if absf(s-desired)<score: score=absf(s-desired); best=s
		assert(best>=0,"Circuit has no safely separated straight for a ramp")
		ramp_sites.append({"distance":best,"dangerous":index==0,"offset":0.0 if index==0 else (-4.0 if index%2==0 else 4.0)})
		if index==0: gaps.append({"start":best+7.25,"end":best+16.25})

func in_gap(distance: float) -> bool:
	return gaps.any(func(gap): return distance>=gap.start and distance<=gap.end)

func _segment(distance: float) -> int:
	var s := fposmod(distance,track_length)
	var low := 0
	var high := route.size()-1
	while low<high:
		var mid := (low+high+1)/2
		if distances[mid]<=s: low=mid
		else: high=mid-1
	return low

func sample(distance: float, lateral: float=0.0, height: float=0.0) -> Vector3:
	var s := fposmod(distance,track_length)
	var i := _segment(s)
	var next := (i+1)%route.size()
	var p := route[i].lerp(route[next],(s-distances[i])/(distances[i+1]-distances[i]))
	p += (route[next]-route[i]).normalized().cross(Vector3.UP)*lateral
	p.y = height
	return p

func tangent(distance: float) -> Vector3:
	var i := _segment(distance)
	return (route[(i+1)%route.size()]-route[i]).normalized()

func transform_at(distance: float, lateral: float=0.0, height: float=0.7) -> Transform3D:
	return Transform3D(Basis.looking_at(tangent(distance)),sample(distance,lateral,height))

func grid_transform(slot: int) -> Transform3D:
	return preload("res://scripts/race_settings.gd").grid_transform(slot) if layout_id==0 else transform_at(-8.0-float(slot/2)*8, -3.0 if slot%2==0 else 3.0)

func gates() -> Array[Vector3]:
	if not gate_points.is_empty(): return gate_points
	if layout_id==0:
		gate_points=[Vector3(0,0,30),Vector3(-30,0,0),Vector3(0,0,-30),Vector3(30,0,0)]
	else:
		var count := ceili(track_length/55.0)
		for i in range(1,count): gate_points.append(sample(i*track_length/count))
		gate_points.append(sample(0))
	return gate_points

func gate_spawn(index: int) -> Transform3D:
	if layout_id==0:
		var p := gates()[index]
		return Transform3D(Basis.looking_at(Vector3(-p.z,0,p.x).normalized()),p+Vector3.UP*0.7)
	var distance := (index+1)*track_length/gates().size()
	for site in ramp_sites:
		if distance>=site.distance-20 and distance<=site.distance+40: distance=site.distance-25
	return transform_at(distance)

func finish_side(position: Vector3) -> float:
	return position.z if layout_id==0 else (position-sample(0)).dot(tangent(0))

func crossed_finish(previous: float, position: Vector3) -> bool:
	return previous<0 and finish_side(position)>=0 and (position.x>21 and position.x<39 if layout_id==0 else position.distance_to(sample(0,0,position.y))<12)

func nearest(position: Vector3, hint: int=-1) -> Dictionary:
	var best := INF
	var best_index := 0
	var best_distance := 0.0
	var search := range(route.size()) if hint<0 else range(hint-20,hint+21)
	for raw in search:
		var i := posmod(raw,route.size())
		var a := route[i]
		var b := route[(i+1)%route.size()]
		var flat := Vector3(position.x,0,position.z)
		var t := clampf((flat-a).dot(b-a)/(b-a).length_squared(),0,1)
		var error := flat.distance_squared_to(a.lerp(b,t))
		if error<best: best=error; best_index=i; best_distance=distances[i]+t*(distances[i+1]-distances[i])
	if hint>=0 and best>400: return nearest(position)
	return {"index":best_index,"distance":best_distance}

func _build_new_crates() -> void:
	var occupied: Array[Vector3] = []
	for i in range(18):
		var s := (i+0.5)*track_length/18
		while ramp_sites.any(func(site): return absf(site.distance-s)<35) or boost_sites.any(func(site): return absf(site-s)<16) or occupied.any(func(p):return p.distance_to(sample(s,-5.0 if i%2==0 else 5.0,0.7))<6.0): s+=4
		var crate := Obstacle.new()
		crate.theme_id=layout_id
		crate.transform = transform_at(s, -5.0 if i%2==0 else 5.0)
		occupied.append(crate.position)
		add_child(crate)

func _build_new_finish() -> void:
	var arch := Node3D.new()
	arch.transform = transform_at(0,0,0)
	add_child(arch)
	for side in [-10.0,10.0]:
		var post := box("FinishPost",Vector3(0.55,5.2,0.55),Vector3(side,2.6,0),material(Color("ffd05b")))
		remove_child(post); arch.add_child(post)
	var beam := box("FinishBeam",Vector3(20.5,0.85,0.6),Vector3(0,5.1,0),material(Circuits.COLORS[layout_id]))
	remove_child(beam); arch.add_child(beam)
	var text := Label3D.new()
	text.text = "MINIKARTS · "+Circuits.NAMES[layout_id]
	text.font_size = 42; text.pixel_size=0.012; text.position=Vector3(0,5.05,0.37)
	arch.add_child(text)
	for lane in range(18):
		for row in range(2):
			var tile := box("FinishTile",Vector3(1,0.025,0.65),Vector3(lane-8.5,0.06,row*0.65-0.325),material(Color("fff4d8") if (lane+row)%2==0 else Color("505968")))
			remove_child(tile); arch.add_child(tile)
