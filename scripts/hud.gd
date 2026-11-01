class_name Hud
extends CanvasLayer
## In-game overlay: hearts, coins, gems, timer, toasts, boss bar, pause + result panels.

var level
var root: Control
var hearts: Array[TextureRect] = []
var gem_icons: Array[TextureRect] = []
var coin_label: Label
var time_label: Label
var toast_label: Label
var boss_box: Control
var boss_fill: ColorRect
var boss_w := 480.0
var pause_panel: Control
var result_panel: Control
var paused := false
var result_active := false
var tex_heart: Texture2D
var tex_heart_empty: Texture2D
var tex_gem: Texture2D
var tex_gem_empty: Texture2D
var toast_tween: Tween


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	tex_heart = load("res://assets/gen/heart_full.png")
	tex_heart_empty = load("res://assets/gen/heart_empty.png")
	tex_gem = load("res://assets/gen/gem_icon.png")
	tex_gem_empty = load("res://assets/gen/gem_empty.png")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	for i in Player.MAX_HP:
		var h := _icon(tex_heart, Vector2(16 + i * 46, 14), 40)
		hearts.append(h)
	var ci := _icon(load("res://assets/gen/coin_icon.png"), Vector2(18, 62), 32)
	coin_label = Game.make_label("0 / 0", 16, Color("ffe27a"), 4)
	coin_label.position = Vector2(58, 68)
	root.add_child(coin_label)
	for i in level.gem_total:
		var g := _icon(tex_gem_empty, Vector2(1152 - 16 - (level.gem_total - i) * 40, 14), 36)
		gem_icons.append(g)
	time_label = Game.make_label("00:00", 16, Color.WHITE, 4)
	time_label.position = Vector2(1152 - 16 - 120, 64)
	time_label.size = Vector2(120, 20)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(time_label)

	toast_label = Game.make_label("", 16, Color.WHITE, 4)
	toast_label.position = Vector2(0, 118)
	toast_label.size = Vector2(1152, 24)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.modulate.a = 0.0
	root.add_child(toast_label)

	_build_boss_bar()
	pause_panel = _build_panel(Vector2(520, 280), ["PAUSED", "", "ESC / P   RESUME", "R   RESTART LEVEL", "Q   BACK TO TITLE"])
	pause_panel.visible = false
	set_hp(Player.MAX_HP)
	set_counts()


func _icon(tex: Texture2D, pos: Vector2, sz: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = pos
	r.size = Vector2(sz, sz)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(r)
	return r


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.16, 0.92)
	sb.border_color = Color("ffd23f")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	return sb


func _build_panel(size: Vector2, lines: Array) -> Control:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	p.size = size
	p.position = (Vector2(1152, 648) - size) / 2.0
	root.add_child(p)
	var y := 28.0
	for i in lines.size():
		var l := Game.make_label(String(lines[i]), 28 if i == 0 else 16, Color("ffd23f") if i == 0 else Color.WHITE, 4)
		l.position = Vector2(0, y)
		l.size = Vector2(size.x, 30)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_child(l)
		y += 56.0 if i == 0 else 40.0
	return p


func _build_boss_bar() -> void:
	boss_box = Control.new()
	boss_box.position = Vector2((1152 - boss_w) / 2.0, 56)
	boss_box.visible = false
	root.add_child(boss_box)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.1, 0.9)
	bg.size = Vector2(boss_w + 8, 28)
	bg.position = Vector2(-4, -4)
	boss_box.add_child(bg)
	boss_fill = ColorRect.new()
	boss_fill.color = Color("e63946")
	boss_fill.size = Vector2(boss_w, 20)
	boss_box.add_child(boss_fill)
	var l := Game.make_label("KING PIG", 12, Color.WHITE, 3)
	l.position = Vector2(0, -26)
	boss_box.add_child(l)


# ------------------------------------------------------------ public API
func set_hp(hp: int) -> void:
	for i in hearts.size():
		hearts[i].texture = tex_heart if i < hp else tex_heart_empty
		if i == hp:
			var tw := create_tween()
			hearts[i].scale = Vector2(1.4, 1.4)
			tw.tween_property(hearts[i], "scale", Vector2.ONE, 0.25)


func set_counts() -> void:
	coin_label.text = "%d / %d" % [level.coins, level.coin_total]
	for i in gem_icons.size():
		gem_icons[i].texture = tex_gem if i < level.gems else tex_gem_empty


func toast(text: String) -> void:
	toast_label.text = text
	if toast_tween:
		toast_tween.kill()
	toast_label.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6).set_delay(1.4)


func banner(a: String, b: String) -> void:
	var la := Game.make_label(a, 16, Color("ffd23f"), 4)
	la.position = Vector2(0, 250)
	la.size = Vector2(1152, 20)
	la.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lb := Game.make_label(b, 40, Color.WHITE, 8)
	lb.position = Vector2(0, 285)
	lb.size = Vector2(1152, 50)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(la)
	root.add_child(lb)
	for l in [la, lb]:
		l.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(l, "modulate:a", 1.0, 0.4)
		tw.tween_interval(1.5)
		tw.tween_property(l, "modulate:a", 0.0, 0.6)
		tw.tween_callback(l.queue_free)


func set_boss(hp: int, max_hp: int, show: bool) -> void:
	boss_box.visible = show
	var tw := create_tween()
	tw.tween_property(boss_fill, "size:x", boss_w * float(hp) / float(max_hp), 0.25)


func show_result(r: Dictionary) -> void:
	result_active = true
	var last: bool = Game.current_level + 1 >= Game.LEVELS.size()
	var lines := ["LEVEL CLEAR!", "",
		"COINS   %d / %d" % [r["coins"], r["coin_total"]],
		"GEMS    %d / %d" % [r["gems"], r["gem_total"]],
		"TIME    %s" % Game.fmt_time(r["time"]),
		"DEATHS  %d" % r["deaths"], "",
		"ENTER: %s" % ("FINISH" if last else "NEXT LEVEL")]
	result_panel = _build_panel(Vector2(600, 440), lines)
	result_panel.modulate.a = 0.0
	create_tween().tween_property(result_panel, "modulate:a", 1.0, 0.4)


func _process(_delta: float) -> void:
	time_label.text = Game.fmt_time(level.time)


func _unhandled_input(event: InputEvent) -> void:
	if result_active:
		if event.is_action_pressed("accept"):
			result_active = false
			Game.next_level()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and not level.finished:
		paused = not paused
		get_tree().paused = paused
		pause_panel.visible = paused
		Game.play("pause")
		get_viewport().set_input_as_handled()
		return
	if paused and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			paused = false
			get_tree().paused = false
			Game.start_level(Game.current_level)
		elif event.physical_keycode == KEY_Q:
			paused = false
			get_tree().paused = false
			Game.stop_music()
			Game.change_scene("res://scenes/title.tscn")
