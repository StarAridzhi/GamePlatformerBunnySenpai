class_name Bullet
extends Node2D

var vel := Vector2.ZERO
var grav := 0.0
var level
var group := "plant"
var life := 4.0
var spr: Sprite2D


func _ready() -> void:
	z_index = 6
	spr = Sprite2D.new()
	spr.texture = load("res://assets/enemies/%s/bullet.png" % group)
	spr.flip_h = vel.x > 0.0
	add_child(spr)


func _physics_process(delta: float) -> void:
	vel.y += grav * delta
	position += vel * delta
	life -= delta
	if life <= 0.0 or level.solid_at(global_position):
		_break()
		return
	var p = level.player
	if p != null and not p.dead:
		if Rect2(global_position - Vector2(4, 4), Vector2(8, 8)).intersects(p.hurtbox()):
			p.hurt(global_position.x)
			_break()


func _break() -> void:
	Game.play("bullet_break", -8.0)
	var path := "res://assets/enemies/%s/bullet_pieces.png" % group
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		for i in 2:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * 16, 0, 16, 16)
			Fx.debris(level, at, global_position, Vector2(-40 + i * 80, -60))
	queue_free()
