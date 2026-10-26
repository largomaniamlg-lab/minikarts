extends Node3D
var wheels: Array[Node3D] = []
var spin := 0.0
func _ready() -> void:
	for node in find_children("V2_wheel*","Node3D",true,false): wheels.append(node)
func _process(delta: float) -> void:
	var kart=get_parent()
	spin=fmod(spin+float(kart.get("speed"))*delta/0.1875,TAU)
	for wheel in wheels:
		wheel.rotation.x=spin
		wheel.rotation.y=-float(kart.get("_steering"))*0.4 if "_F" in wheel.name else 0.0
