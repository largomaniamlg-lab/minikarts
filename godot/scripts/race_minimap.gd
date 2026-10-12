extends Control
var track: Node3D
var kart: CharacterBody3D
var points:=PackedVector2Array()
var minimum:=Vector3.ZERO
var span:=Vector3.ONE
var clock:=0.0
var layout:=-1
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func project(point: Vector3) -> Vector2:
	return Vector2(12+(point.x-minimum.x)/span.x*(size.x-24),12+(point.z-minimum.z)/span.z*(size.y-24))
func rebuild() -> void:
	layout=track.layout_id
	var route: PackedVector3Array=track.route
	if route.is_empty():
		for i in range(64): route.append(track.track_point(i*TAU/64))
	minimum=route[0]; var maximum=minimum
	for point in route: minimum=minimum.min(point); maximum=maximum.max(point)
	span=maximum-minimum; span.x=maxf(span.x,1); span.z=maxf(span.z,1)
	points.clear()
	for point in route: points.append(project(point))
	points.append(points[0])
func _process(delta: float) -> void:
	if not is_instance_valid(track): return
	clock+=delta
	if clock<0.1: return
	clock=0
	if layout!=track.layout_id or points.is_empty(): rebuild()
	queue_redraw()
func _draw() -> void:
	if points.size()<2: return
	draw_style_box(get_theme_stylebox("panel","Panel"),Rect2(Vector2.ZERO,size))
	draw_polyline(points,Color("2A1458"),7,true)
	draw_polyline(points,Color("D4ECFF"),3,true)
	if is_instance_valid(kart): draw_circle(project(kart.position),5,Color("FFD23F"))
