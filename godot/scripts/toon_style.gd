extends Node
const PALETTE := {"red":Color("FF4F6D"),"yellow":Color("FFD23F"),"blue":Color("3F8CFF"),"green":Color("35D06B"),"purple":Color("B05CFF"),"cyan":Color("52E3FF"),"grass":Color("79D24A"),"grass_shadow":Color("58B83C"),"asphalt":Color("5B5F78"),"curb":Color("FF3B4E"),"outline":Color("2A1458"),"sky":Color("2F8CFF"),"horizon":Color("D4ECFF")}
const SHADER = preload("res://shaders/toon.gdshader")
const OUTLINE = preload("res://shaders/outline.gdshader")
const RAMP = preload("res://materials/toon/ramp.png")
static var low_quality := false
static var materials: Dictionary = {}
static var transient_materials: Array[WeakRef] = []

static func material(color: Color, outlined: bool=false, thickness: float=0.05, glow: bool=false) -> ShaderMaterial:
	var key="%s:%s:%s:%s" % [color.to_html(),outlined,thickness,glow]
	if materials.has(key): return materials[key].main
	var mat:=ShaderMaterial.new()
	mat.shader=SHADER
	mat.set_shader_parameter("albedo",color)
	mat.set_shader_parameter("ramp",RAMP)
	if glow: mat.set_shader_parameter("glow",Vector3(color.r,color.g,color.b)*0.35)
	var shell: ShaderMaterial
	if outlined:
		shell=ShaderMaterial.new(); shell.shader=OUTLINE
		shell.set_shader_parameter("thickness",thickness)
		# A smooth normal layer in the shell closes hard-edged primitive seams.
		shell.set_shader_parameter("smooth_shell",false)
		if not low_quality: mat.next_pass=shell
	materials[key]={"main":mat,"outline":shell}
	return mat

static func set_low(value: bool) -> void:
	low_quality=value
	for reference in transient_materials:
		var mat=reference.get_ref()
		if mat!=null: mat.next_pass=null if value else mat.get_meta("toon_outline")
	for entry in materials.values(): entry.main.next_pass=null if value else entry.outline
	# Base resources used by the original prototype also honor the quality preset.
	for name in ["body","tire","metal","skin","trunk","leaf"]:
		var mat=load("res://materials/toon/%s.tres" % name)
		if not mat.has_meta("outline"): mat.set_meta("outline",mat.next_pass)
		mat.next_pass=null if value else mat.get_meta("outline")

func _ready() -> void:
	var settings:=ConfigFile.new()
	if settings.load("user://graphics.cfg")==OK: set_low(bool(settings.get_value("graphics","low",false)))

func toggle_quality() -> void:
	set_low(not low_quality)
	for light in get_tree().get_nodes_in_group("toon_sun"): light.shadow_enabled=not low_quality
	var settings:=ConfigFile.new()
	settings.set_value("graphics","low",low_quality); settings.save("user://graphics.cfg")

# Merge static decorative geometry by material in small spatial cells.
# Only geometry is batched: original physics bodies, pickups and hazard behavior stay intact.
static func batch_static(root: Node3D) -> void:
	var buckets: Dictionary={}
	for node in root.find_children("*","MeshInstance3D",true,false):
		if node.is_in_group("dynamic_visual") or node.mesh==null: continue
		var parent=node
		var dynamic:=false
		while parent!=root and parent!=null:
			if parent.is_in_group("destructible") or parent.is_in_group("neutral_hazards") or parent.is_in_group("boost_panels"): dynamic=true; break
			parent=parent.get_parent()
		if dynamic: continue
		var mat=node.material_override
		if mat==null: continue
		var cell=Vector2i(floori(node.position.x/50),floori(node.position.z/50))
		var local=root.global_transform.affine_inverse()*node.global_transform
		cell=Vector2i(floori(local.origin.x/50),floori(local.origin.z/50))
		var key=str(mat.get_instance_id())+str(cell)
		if not buckets.has(key): buckets[key]={"tool":SurfaceTool.new(),"material":mat,"nodes":[]}
		var entry=buckets[key]
		if entry.nodes.is_empty(): entry.tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var source: Mesh = smooth_mesh(node.mesh) if node.mesh is BoxMesh and mat is ShaderMaterial and mat.next_pass!=null else node.mesh
		for surface in range(source.get_surface_count()): entry.tool.append_from(source,surface,local)
		entry.nodes.append(node)
	for entry in buckets.values():
		if entry.nodes.size()<2: continue
		var visual:=MeshInstance3D.new()
		visual.name="ToonStaticBatch"
		visual.mesh=entry.tool.commit(); visual.material_override=entry.material
		root.add_child(visual)
		for node in entry.nodes: node.hide()

static func smooth_mesh(mesh: Mesh) -> ArrayMesh:
	var result:=ArrayMesh.new()
	for surface in range(mesh.get_surface_count()):
		var arrays=mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var combined: Dictionary={}
		for i in range(vertices.size()):
			var key=str(vertices[i])
			combined[key]=combined.get(key,Vector3.ZERO)+normals[i]
		for i in range(vertices.size()): normals[i]=combined[str(vertices[i])].normalized()
		arrays[Mesh.ARRAY_NORMAL]=normals
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

func _exit_tree() -> void:
	materials.clear()
	transient_materials.clear()

static func register_transient(mat: ShaderMaterial) -> void:
	if mat.has_meta("toon_outline"): return
	var shell=mat.next_pass
	if shell==null:
		shell=ShaderMaterial.new(); shell.shader=OUTLINE; shell.set_shader_parameter("thickness",0.05)
	mat.set_meta("toon_outline",shell)
	mat.next_pass=null if low_quality else shell
	transient_materials=transient_materials.filter(func(ref):return ref.get_ref()!=null)
	transient_materials.append(weakref(mat))
