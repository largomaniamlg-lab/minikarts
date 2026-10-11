extends RefCounted
const LAP_OPTIONS := [3, 6, 9]
const BOT_OPTIONS := [3, 6, 12]
const CAPACITY := 13
const COLORS := [Color("ee3814"), Color("397cdc"), Color("51ba66"), Color("b464d5"), Color("f4cf39"), Color("39d5d2"), Color("ed6bb1"), Color("f49b38"), Color("dddddd"), Color("637049"), Color("864629"), Color("5675ab"), Color("bdcf87")]
static func valid_laps(value: Variant) -> int:
	if value is int or value is float:
		if is_finite(float(value)) and float(value) == floor(float(value)) and int(value) in LAP_OPTIONS:
			return int(value)
	return 3
static func grid_position(slot: int) -> Vector3:
	var angle := -0.11 - float(slot / 2) * 0.16
	var radius := 27.0 + float(slot % 2) * 6.0
	return Vector3(cos(angle) * radius, 0.7, sin(angle) * radius)
static func grid_transform(slot: int) -> Transform3D:
	var position := grid_position(slot)
	return Transform3D(Basis(Vector3.UP, PI - atan2(position.z, position.x)), position)
