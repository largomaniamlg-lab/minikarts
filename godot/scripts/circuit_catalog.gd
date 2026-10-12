extends RefCounted

const NAMES := ["Circuito de juguete", "Velocidad", "Curvas", "Horquillas", "Gran Final"]
const LENGTHS := [0.0, 900.0, 960.0, 1050.0, 1150.0]
const RAMP_COUNTS := [0, 2, 3, 4, 5]
const COLORS := [Color("329ad2"), Color("329ad2"), Color("51ba66"), Color("ffc93c"), Color("a67ee8")]

static func valid(value: Variant) -> int:
	if (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)):
		return clampi(int(value), 0, 4)
	return 0

static func points(id: int) -> PackedVector3Array:
	var layouts := [[],
		[Vector2(0,0),Vector2(180,0),Vector2(210,30),Vector2(205,65),Vector2(170,80),Vector2(100,65),Vector2(65,95),Vector2(0,95),Vector2(-30,65),Vector2(-15,35)],
		[Vector2(0,0),Vector2(160,0),Vector2(205,35),Vector2(190,100),Vector2(140,105),Vector2(125,60),Vector2(85,60),Vector2(70,115),Vector2(10,125),Vector2(-45,100),Vector2(-55,60),Vector2(-15,60),Vector2(-35,25)],
		[Vector2(0,0),Vector2(240,0),Vector2(270,30),Vector2(245,60),Vector2(75,55),Vector2(40,115),Vector2(-5,145),Vector2(-40,125),Vector2(-20,90),Vector2(15,80),Vector2(-15,35)],
		[Vector2(0,0),Vector2(210,0),Vector2(250,50),Vector2(215,85),Vector2(160,70),Vector2(155,130),Vector2(100,160),Vector2(70,100),Vector2(20,100),Vector2(-20,150),Vector2(-80,140),Vector2(-100,70),Vector2(-65,20)]]
	var vertices: Array = layouts[valid(id)]
	var result := PackedVector3Array()
	for i in range(vertices.size()):
		var previous: Vector2 = vertices[posmod(i-1, vertices.size())]
		var vertex: Vector2 = vertices[i]
		var next: Vector2 = vertices[(i+1)%vertices.size()]
		var before := vertex.move_toward(previous, minf(22, vertex.distance_to(previous)*0.3))
		var after := vertex.move_toward(next, minf(22, vertex.distance_to(next)*0.3))
		for step in range(12):
			var t := step/12.0
			var point := before.lerp(vertex,t).lerp(vertex.lerp(after,t),t)
			result.append(Vector3(point.x,0,point.y))
		var following: Vector2 = next.move_toward(vertex, minf(22,next.distance_to(vertex)*0.3))
		var count := maxi(1,ceili(after.distance_to(following)/2.0))
		for step in range(count):
			var point := after.lerp(following,step/float(count))
			result.append(Vector3(point.x,0,point.y))
	var total := 0.0
	for i in range(result.size()):
		total += result[i].distance_to(result[(i+1)%result.size()])
	var scale: float = LENGTHS[id]/total
	for i in range(result.size()): result[i] *= scale
	# Put the start in the middle of the main straight, with room for sixteen karts.
	var start := 0
	var nearest := INF
	var desired := Vector3(float(vertices[1].x)*scale*0.5,0,0)
	for i in range(result.size()):
		var distance := result[i].distance_to(desired)
		if distance < nearest: nearest = distance; start = i
	var ordered := PackedVector3Array()
	for i in range(result.size()): ordered.append(result[(start+i)%result.size()])
	return ordered
