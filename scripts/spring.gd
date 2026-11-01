class_name Spring
extends Node2D

var level
var spr: AnimatedSprite2D
var cd := 0.0


func _ready() -> void:
	z_index = 3
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Game.get_frames("spring")
	spr.position = Vector2(0, -8)
	add_child(spr)
	spr.play("idle")


func _physics_process(delta: float) -> void:
	cd -= delta
	var p = level.player
	if cd <= 0.0 and p != null and not p.dead and p.velocity.y >= 0.0:
		if p.hurtbox().intersects(Rect2(global_position + Vector2(-8, -11), Vector2(16, 11))):
			p.launch(-560.0)
			cd = 0.3
			spr.play("boing")
			Game.play("spring")
			Fx.burst(level, global_position + Vector2(0, -8), Color(1, 0.9, 0.3), 6, 60.0, 0.3, 2.0, 0.0)
			get_tree().create_timer(0.3).timeout.connect(func(): if is_instance_valid(spr): spr.play("idle"))
