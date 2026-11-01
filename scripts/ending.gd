extends Node2D
## Ending screen.

var cam: Camera2D
var t := 0.0
var msg: Label


func _ready() -> void:
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position = Vector2(0, 318)
	add_child(cam)
	cam.make_current()
	var bg := ParallaxBG.new()
	bg.setup("frost", 480.0)
	add_child(bg)
	var gs := GroundStrip.new()
	gs.setup("frost", 352.0)
	gs.z_index = 1
	add_child(gs)
	var pr := Parade.new()
	add_child(pr)
	pr.setup(352.0)
	var ui := CanvasLayer.new()
	add_child(ui)
	var coins := 0
	var gems := 0
	var time := 0.0
	for k in Game.best:
		coins += int(Game.best[k]["coins"])
		gems += int(Game.best[k]["gems"])
		time += float(Game.best[k]["time"])
	var big := Game.make_label("YOU DID IT!", 64, Color("ffd23f"), 12)
	big.position = Vector2(0, 90)
	big.size = Vector2(1152, 80)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(big)
	var lines := "THE KINGDOM IS SAFE!\n\nCOINS  %d     GEMS  %d\nBEST TOTAL TIME  %s" % [coins, gems, Game.fmt_time(time)]
	var l := Game.make_label(lines, 16, Color.WHITE, 5)
	l.position = Vector2(0, 200)
	l.size = Vector2(1152, 120)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(l)
	msg = Game.make_label("PRESS ENTER", 18, Color.WHITE, 5)
	msg.position = Vector2(0, 400)
	msg.size = Vector2(1152, 24)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(msg)
	Game.play_music("title")
	Game.play("win")


func _process(delta: float) -> void:
	t += delta
	cam.position.x += 45.0 * delta
	msg.modulate.a = 0.45 + 0.55 * absf(sin(t * 3.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accept") and not Game.transitioning:
		Game.change_scene("res://scenes/title.tscn")
