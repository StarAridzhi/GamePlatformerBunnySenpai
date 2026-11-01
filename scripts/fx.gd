class_name Fx
extends RefCounted
## Tiny particle / popup helpers (no assets needed).

class Particle extends Node2D:
	var vel := Vector2.ZERO
	var grav := 0.0
	var drag := 0.0
	var life := 0.5
	var t := 0.0
	var size := 3.0
	var col := Color.WHITE
	var tex: Texture2D = null
	var spin := 0.0

	func _process(delta: float) -> void:
		t += delta
		if t >= life:
			queue_free()
			return
		vel.y += grav * delta
		vel *= maxf(0.0, 1.0 - drag * delta)
		position += vel * delta
		rotation += spin * delta
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 - t / life
		if tex:
			draw_texture(tex, -tex.get_size() / 2.0, Color(1, 1, 1, minf(1.0, k * 2.0)))
			return
		var s := maxf(1.0, size * k)
		draw_rect(Rect2(-s / 2.0, -s / 2.0, s, s), Color(col.r, col.g, col.b, col.a * minf(1.0, k * 2.5)))


static func burst(parent: Node, pos: Vector2, color: Color, count := 8, speed := 90.0, life := 0.45, size := 3.0, grav := 240.0) -> void:
	for i in count:
		var p := Particle.new()
		p.position = pos
		var a := randf() * TAU
		p.vel = Vector2(cos(a), sin(a)) * speed * randf_range(0.35, 1.0)
		p.grav = grav
		p.life = life * randf_range(0.7, 1.2)
		p.size = size * randf_range(0.8, 1.4)
		p.col = color
		p.z_index = 20
		parent.add_child(p)


static func puff(parent: Node, pos: Vector2, count := 4, spread := 14.0, color := Color(1, 1, 1, 0.75)) -> void:
	for i in count:
		var p := Particle.new()
		p.position = pos + Vector2(randf_range(-3, 3), 0)
		p.vel = Vector2(randf_range(-spread, spread), randf_range(-14, -2))
		p.drag = 3.0
		p.life = randf_range(0.25, 0.4)
		p.size = randf_range(3.0, 5.0)
		p.col = color
		p.z_index = 9
		parent.add_child(p)


static func debris(parent: Node, tex: Texture2D, pos: Vector2, vel: Vector2) -> void:
	var p := Particle.new()
	p.position = pos
	p.vel = vel
	p.grav = 380.0
	p.life = 0.7
	p.tex = tex
	p.spin = randf_range(-8, 8)
	p.z_index = 20
	parent.add_child(p)


static func popup(parent: Node, pos: Vector2, text: String, color := Color.WHITE) -> void:
	var l := Game.make_label(text, 8, color, 2)
	l.position = pos - Vector2(12, 0)
	l.z_index = 30
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 22.0, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)
