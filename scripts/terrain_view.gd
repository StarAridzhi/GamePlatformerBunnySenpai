class_name TerrainView
extends Node2D
## Draws the tile grid with simple auto-tiling (grass top, dirt body, outlined edges).

var level
var tex: Texture2D


func setup(lvl) -> void:
	level = lvl
	tex = load("res://assets/gen/tiles_%s.png" % lvl.theme)


func _solid(x: int, y: int) -> bool:
	return level.cell(x, y) == "#"


func _draw() -> void:
	for y in level.H:
		for x in level.W:
			var c: String = level.cell(x, y)
			if c == "#":
				draw_texture_rect_region(tex, Rect2(x * 16, y * 16, 16, 16), _region(x, y))
			elif c == "=":
				draw_texture_rect_region(tex, Rect2(x * 16, y * 16, 16, 16), _oneway(x, y))


func _region(x: int, y: int) -> Rect2:
	var up := _solid(x, y - 1)
	var dn := _solid(x, y + 1)
	var lf := _solid(x - 1, y)
	var rt := _solid(x + 1, y)
	var h: int = ((x * 73856093) ^ (y * 19349663)) & 0x7fffffff
	var v := 1 + h % 3
	var col := 0
	if not up:
		if not lf and not rt: col = 5
		elif not lf: col = 0
		elif not rt: col = 4
		else: col = v
		return Rect2(col * 16, 0, 16, 16)
	if not dn:
		if not lf and not rt: col = 3
		elif not lf: col = 0
		elif not rt: col = 2
		else: col = 1
		return Rect2(col * 16, 32, 16, 16)
	if not lf and not rt: col = 5
	elif not lf: col = 0
	elif not rt: col = 4
	else: col = v
	return Rect2(col * 16, 16, 16, 16)


func _oneway(x: int, y: int) -> Rect2:
	var lf: bool = level.cell(x - 1, y) == "="
	var rt: bool = level.cell(x + 1, y) == "="
	var col := 1 + (x % 2)
	if not lf and not rt: col = 4
	elif not lf: col = 0
	elif not rt: col = 3
	return Rect2(col * 16, 48, 16, 16)
