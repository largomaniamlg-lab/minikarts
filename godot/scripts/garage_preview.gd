extends SubViewportContainer
var preview: Node3D
var view: SubViewport
const COLORS := [Color("ee4149"),Color("35ade5"),Color("ffd02e"),Color("ac65df")]
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	stretch=true
	view=SubViewport.new(); view.size=Vector2i(600,300)
	view.transparent_bg=true; view.own_world_3d=true
	view.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	add_child(view)
	var world:=Node3D.new(); view.add_child(world)
	preview=preload("res://scenes/toon/kart_prototype.tscn").instantiate()
	preview.show_chibi=false; world.add_child(preview)
	var camera:=Camera3D.new(); camera.position=Vector3(1.6,1.05,-1.9)
	world.add_child(camera); camera.look_at(Vector3(0,0.15,0)); camera.fov=38
	var key:=DirectionalLight3D.new(); key.rotation_degrees=Vector3(-45,-35,0)
	key.light_energy=1.6; world.add_child(key)
	var fill:=DirectionalLight3D.new(); fill.rotation_degrees=Vector3(-15,130,0)
	fill.light_color=Color("82c9ff"); fill.light_energy=0.8; world.add_child(fill)
	var env:=WorldEnvironment.new(); env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0,0,0,0)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("a3b5c9"); env.environment.ambient_light_energy=0.5
	world.add_child(env)
func choose(index: int) -> void:
	if preview==null: return
	var color=COLORS[index%COLORS.size()]
	preview.body_color=color
	preview.get_node("PaintedBody").material_override.set_shader_parameter("albedo",color)
func _process(delta: float) -> void:
	if preview!=null and is_visible_in_tree(): preview.rotation.y+=delta*0.15
