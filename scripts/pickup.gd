class_name Pickup
extends Area2D
## Coins (magnetic) and gems.

var kind := "coin"
var level
var base_y := 0.0
var t := 0.0
var magnet := false
var taken := false
var spr: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Game.L_PLAYER
	var sh := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0 if kind == "coin" else 11.0
	sh.shape = c
	add_child(sh)
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Game.get_frames(kind)
	add_child(spr)
	spr.play("spin")
	spr.frame = randi() % 8
	if kind == "gem":
		spr.scale = Vector2(1.4, 1.4)
	z_index = 3
	base_y = position.y
	t = randf() * TAU
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	t += delta * 4.0
	var p = level.player
	if p != null and not p.dead and kind == "coin":
		var d: Vector2 = p.global_position + Vector2(0, -14) - global_position
		if d.length() < 38.0 or magnet:
			magnet = true
			global_position += d.normalized() * minf(d.length(), 230.0 * delta)
			return
	position.y = base_y + sin(t) * 2.0


func _on_body(body: Node2D) -> void:
	if taken or not body is Player:
		return
	taken = true
	level.on_pickup(kind, global_position)
	queue_free()
