extends SceneTree
func own(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		child.owner=root_node
		own(child,root_node)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var demo=load("res://scripts/toon_demo.gd").new()
	demo.name="ToonDemo"
	root.add_child(demo)
	for name in ["StaticTrack","Sun","WorldEnvironment","IndirectLightmap"]:
		var node=demo.get_node(name); node.owner=demo; own(node,demo)
	var packed:=PackedScene.new(); packed.pack(demo)
	assert(ResourceSaver.save(packed,"res://scenes/toon_demo.tscn")==OK)
	var visual=load("res://scenes/toon/kart_prototype.tscn").instantiate()
	root.add_child(visual); own(visual,visual)
	packed=PackedScene.new(); packed.pack(visual)
	assert(ResourceSaver.save(packed,"res://scenes/toon/kart_prototype.tscn")==OK)
	print("Saved static demo with UV2 ArrayMeshes and original kart scene")
	quit()
