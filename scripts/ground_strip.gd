class_name GroundStrip
extends Node2D
## Endless ground drawn under the camera (used on title / ending screens).

var tex: Texture2D
var ground_y := 352.0


func setup(theme: String, gy: float) -> void:
	tex = load("res://assets/gen/tiles_%s.png" % theme)
	ground_y = gy


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var cx := cam.get_screen_center_position().x
	var x0 := int(floor((cx - 300.0) / 16.0))
	for i in 40:
		var x := x0 + i
		var h: int = ((x * 73856093) & 0x7fffffff)
		draw_texture_rect_region(tex, Rect2(x * 16, ground_y, 16, 16), Rect2((1 + h % 3) * 16, 0, 16, 16))
		for r in range(1, 12):
			draw_texture_rect_region(tex, Rect2(x * 16, ground_y + r * 16, 16, 16), Rect2((1 + (h + r) % 3) * 16, 16, 16, 16))
