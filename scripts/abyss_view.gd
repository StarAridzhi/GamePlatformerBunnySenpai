class_name AbyssView
extends Node2D
## Dark gradient at the bottom of the level so pits look dangerous.

var w := 0.0
var bottom := 0.0


func setup(width_px: float, bottom_px: float) -> void:
	w = width_px
	bottom = bottom_px
	z_index = -50


func _draw() -> void:
	var steps := 14
	for i in steps:
		var a := pow(float(i + 1) / steps, 1.6) * 1.0
		var y0 := bottom - 120.0 + i * (120.0 / steps)
		draw_rect(Rect2(0, y0, w, 120.0 / steps + 1.0), Color(0.04, 0.02, 0.1, a))
