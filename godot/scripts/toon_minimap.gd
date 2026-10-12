extends Control
var demo: Node3D
func _ready() -> void: mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	var points:=PackedVector2Array()
	for i in range(65): points.append(Vector2(90+cos(i*TAU/64)*72,70+sin(i*TAU/64)*47))
	draw_polyline(points,Color("2A1458"),9,true)
	draw_polyline(points,Color("D4ECFF"),4,true)
	if is_instance_valid(demo): draw_circle(Vector2(90+cos(demo.phase)*72,70+sin(demo.phase)*47),6,Color("FFD23F"))
