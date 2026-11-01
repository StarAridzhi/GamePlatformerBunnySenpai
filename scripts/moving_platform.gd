class_name MovingPlatform
extends AnimatableBody2D

var a := Vector2.ZERO
var b := Vector2.ZERO
var w := 3
var speed := 40.0
var tex: Texture2D
var phase := 0.0
var period := 4.0


func setup(theme: String, pos_a: Vector2, pos_b: Vector2, width: int, spd: float) -> void:
	tex = load("res://assets/gen/tiles_%s.png" % theme)
	a = pos_a
	b = pos_b
	w = width
	speed = spd
	position = a
	period = maxf(0.5, a.distance_to(b) / spd)


func _ready() -> void:
	collision_layer = Game.L_ONEWAY
	collision_mask = 0
	sync_to_physics = true
	z_index = 1
	var sh := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w * 16, 8)
	sh.shape = rs
	sh.position = Vector2(w * 8, 4)
	sh.one_way_collision = true
	add_child(sh)


func _physics_process(delta: float) -> void:
	phase += delta / period
	var tri := absf(fposmod(phase, 2.0) - 1.0)        # 0..1..0
	position = a.lerp(b, smoothstep(0.0, 1.0, tri))


func _draw() -> void:
	for i in w:
		var col := 1
		if w == 1: col = 4
		elif i == 0: col = 0
		elif i == w - 1: col = 3
		draw_texture_rect_region(tex, Rect2(i * 16, 0, 16, 16), Rect2(col * 16, 48, 16, 16))
