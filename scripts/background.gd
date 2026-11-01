class_name ParallaxBG
extends Node2D
## Camera-driven parallax background (5 tileable layers, 576x324 each).

const LAYERS := [
	["sky", 1.0, 0.0, 0.0],
	["clouds", 0.96, 0.0, 5.0],
	["mountains", 0.86, -26.0, 0.0],
	["hills", 0.7, -32.0, 0.0],
	["trees", 0.5, -26.0, 0.0],
]
const VIEW := Vector2(576, 324)

var textures: Array = []
var bottom_px := 480.0
var drift := 0.0
var fixed_cam: Camera2D = null


func setup(theme: String, level_bottom: float) -> void:
	for l in LAYERS:
		textures.append(load("res://assets/gen/bg_%s_%s.png" % [theme, l[0]]))
	bottom_px = level_bottom
	z_index = -100
	z_as_relative = false


func _process(delta: float) -> void:
	drift += delta
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var c := cam.get_screen_center_position()
	var left := c.x - VIEW.x / 2.0
	var ref_y := bottom_px - VIEW.y / 2.0
	for i in LAYERS.size():
		var l: Array = LAYERS[i]
		var d: float = l[1]
		var ox: float = left * d + drift * float(l[3])
		var oy: float = (ref_y - VIEW.y / 2.0) + (c.y - ref_y) * d + float(l[2])
		var x := floorf((left - ox) / VIEW.x) * VIEW.x + ox
		while x < left + VIEW.x:
			draw_texture(textures[i], Vector2(x, oy))
			x += VIEW.x
