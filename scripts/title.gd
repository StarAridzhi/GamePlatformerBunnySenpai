extends Node2D
## Title screen + level select.

var cam: Camera2D
var ui: CanvasLayer
var title_group: Control
var select_group: Control
var prompt: Label
var logo: Label
var cards: Array[Control] = []
var state := "title"
var sel := 0
var t := 0.0
const THEMES := ["meadow", "canyon", "frost"]
const NAMES := ["SUNNY MEADOW", "SUNSET CANYON", "MOONLIT PEAKS"]


func _ready() -> void:
	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position = Vector2(0, 318)
	add_child(cam)
	cam.make_current()
	var bg := ParallaxBG.new()
	bg.setup("meadow", 480.0)
	add_child(bg)
	var gs := GroundStrip.new()
	gs.setup("meadow", 352.0)
	gs.z_index = 1
	add_child(gs)
	var pr := Parade.new()
	add_child(pr)
	pr.setup(352.0)
	_build_ui()
	Game.play_music("title")
	sel = clampi(Game.unlocked - 1, 0, 2)


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	title_group = Control.new()
	title_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(title_group)
	logo = Game.make_label("BUNNY QUEST", 76, Color("ffd23f"), 14)
	logo.position = Vector2(0, 60)
	logo.size = Vector2(1152, 90)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_group.add_child(logo)
	var sub := Game.make_label("A PIXEL PLATFORMER ADVENTURE", 14, Color.WHITE, 4)
	sub.position = Vector2(0, 165)
	sub.size = Vector2(1152, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_group.add_child(sub)
	prompt = Game.make_label("PRESS ENTER", 20, Color.WHITE, 5)
	prompt.position = Vector2(0, 215)
	prompt.size = Vector2(1152, 24)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_group.add_child(prompt)
	var help := Game.make_label("ARROWS / WASD MOVE   SPACE JUMP   ESC PAUSE", 10, Color(1, 1, 1, 0.9), 3)
	help.position = Vector2(0, 600)
	help.size = Vector2(1152, 14)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_group.add_child(help)

	select_group = Control.new()
	select_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	select_group.visible = false
	ui.add_child(select_group)
	var head := Game.make_label("SELECT LEVEL", 32, Color("ffd23f"), 8)
	head.position = Vector2(0, 60)
	head.size = Vector2(1152, 40)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_group.add_child(head)
	for i in 3:
		cards.append(_make_card(i))
	var hint := Game.make_label("LEFT / RIGHT CHOOSE   ENTER PLAY   ESC BACK", 10, Color.WHITE, 3)
	hint.position = Vector2(0, 560)
	hint.size = Vector2(1152, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_group.add_child(hint)


func _make_card(i: int) -> Control:
	var card := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.16, 0.92)
	sb.border_color = Color(0.6, 0.6, 0.8)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", sb)
	card.size = Vector2(300, 270)
	card.position = Vector2(96 + i * 330, 160)
	select_group.add_child(card)
	for l in ["sky", "clouds", "mountains", "hills", "trees"]:
		var tr := TextureRect.new()
		tr.texture = load("res://assets/gen/bg_%s_%s.png" % [THEMES[i], l])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.position = Vector2(10, 10)
		tr.size = Vector2(280, 158)
		card.add_child(tr)
	var n := Game.make_label("%d. %s" % [i + 1, NAMES[i]], 12, Color.WHITE, 3)
	n.position = Vector2(10, 180)
	card.add_child(n)
	var stats: String
	if i >= Game.unlocked:
		stats = "LOCKED"
	elif Game.best.has(str(i)):
		var b: Dictionary = Game.best[str(i)]
		stats = "COINS %d  GEMS %d\nBEST %s" % [b["coins"], b["gems"], Game.fmt_time(b["time"])]
	else:
		stats = "NOT CLEARED"
	var s := Game.make_label(stats, 10, Color("ffe27a") if i < Game.unlocked else Color(0.7, 0.7, 0.8), 3)
	s.position = Vector2(10, 208)
	card.add_child(s)
	if i >= Game.unlocked:
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.55)
		dim.position = Vector2(10, 10)
		dim.size = Vector2(280, 158)
		card.add_child(dim)
	return card


func _process(delta: float) -> void:
	t += delta
	cam.position.x += 45.0 * delta
	logo.position.y = 60 + sin(t * 2.0) * 6.0
	prompt.modulate.a = 0.45 + 0.55 * absf(sin(t * 3.0))
	for i in cards.size():
		var c := cards[i]
		var sb: StyleBoxFlat = c.get_theme_stylebox("panel")
		if i == sel:
			sb.border_color = Color("ffd23f")
			c.position.y = lerpf(c.position.y, 146.0 + sin(t * 4.0) * 3.0, 0.3)
			c.modulate = Color.WHITE
		else:
			sb.border_color = Color(0.6, 0.6, 0.8)
			c.position.y = lerpf(c.position.y, 164.0, 0.3)
			c.modulate = Color(0.75, 0.75, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if Game.transitioning:
		return
	if state == "title":
		if event.is_action_pressed("accept"):
			state = "select"
			title_group.visible = false
			select_group.visible = true
			Game.play("select")
	else:
		if event.is_action_pressed("left"):
			sel = maxi(0, sel - 1)
			Game.play("select", -6.0)
		elif event.is_action_pressed("right"):
			sel = mini(2, sel + 1)
			Game.play("select", -6.0)
		elif event.is_action_pressed("accept"):
			if sel < Game.unlocked:
				Game.start_level(sel)
			else:
				Game.play("hurt", -8.0, 1.4)
		elif event.is_action_pressed("pause"):
			state = "title"
			title_group.visible = true
			select_group.visible = false
