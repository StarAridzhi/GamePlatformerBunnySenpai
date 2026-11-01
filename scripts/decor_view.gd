class_name DecorView
extends Node2D
## Randomly placed props (flowers, cacti, pines...) on top of terrain surfaces.

var items: Array = []     # [Vector2 pos, int index]
var tex: Texture2D


func setup(lvl, blocked: Dictionary) -> void:
	tex = load("res://assets/gen/props_%s.png" % lvl.theme)
	var cols := int(tex.get_width() / 32)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + lvl.W
	for x in range(3, lvl.W - 3):
		for y in lvl.H:
			if lvl.cell(x, y) == "#" and lvl.cell(x, y - 1) == "." and not blocked.has(Vector2i(x, y - 1)):
				if rng.randf() < 0.28:
					items.append([Vector2(x * 16 + 8, y * 16), rng.randi() % cols])
				break


func _draw() -> void:
	for it in items:
		var p: Vector2 = it[0]
		draw_texture_rect_region(tex, Rect2(p.x - 16, p.y - 31, 32, 32), Rect2(it[1] * 32, 0, 32, 32))
