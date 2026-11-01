class_name Goal
extends Node2D

var level
var spr: AnimatedSprite2D
var enabled := true


func _ready() -> void:
	z_index = 2
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Game.get_frames("goal")
	spr.position = Vector2(12, -24)
	add_child(spr)
	spr.play("wave")


func set_enabled(v: bool) -> void:
	enabled = v
	visible = v


func _physics_process(_delta: float) -> void:
	if not enabled:
		return
	var p = level.player
	if p != null and not p.dead and absf(p.global_position.x - (global_position.x + 8.0)) < 16.0 and absf(p.global_position.y - global_position.y) < 40.0:
		level.finish()
