class_name Checkpoint
extends Node2D

var level
var active := false
var spr: AnimatedSprite2D


func _ready() -> void:
	z_index = 2
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Game.get_frames("checkpoint")
	spr.position = Vector2(5, -16)
	add_child(spr)
	spr.play("off")


func _physics_process(_delta: float) -> void:
	if active:
		return
	var p = level.player
	if p != null and not p.dead and absf(p.global_position.x - global_position.x) < 14.0 and absf(p.global_position.y - global_position.y) < 36.0:
		active = true
		spr.play("on")
		level.on_checkpoint(global_position)
