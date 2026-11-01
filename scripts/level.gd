class_name Level
extends Node2D
## Builds a level from a JSON file: terrain, collisions, decor, entities, player, HUD.

var data: Dictionary
var W := 0
var H := 0
var grid: Array = []
var theme := "meadow"
var player: Player
var hud
var terrain_view: TerrainView
var terrain_body: StaticBody2D
var goal_node: Goal
var boss: Enemy = null
var checkpoint_pos := Vector2.ZERO
var coins := 0
var coin_total := 0
var gems := 0
var gem_total := 0
var kills := 0
var deaths := 0
var time := 0.0
var finished := false
var respawning := false
var arena: Dictionary = {}
var arena_active := false
var spike_rects: Array[Rect2] = []
var blocked := {}


func _ready() -> void:
	var f := FileAccess.open(Game.LEVELS[Game.current_level], FileAccess.READ)
	data = JSON.parse_string(f.get_as_text())
	theme = data["theme"]
	W = int(data["width"])
	H = int(data["height"])
	grid = data["tiles"]
	arena = data["arena"] if data["arena"] != null else {}
	_build_background()
	var ab := AbyssView.new()
	ab.setup(W * 16.0, H * 16.0)
	add_child(ab)
	_build_terrain()
	_build_entities()
	_build_decor()
	_build_player()
	hud = Hud.new()
	hud.level = self
	add_child(hud)
	Game.play_music(data["music"])
	hud.banner("WORLD %d" % int(data["world"]), String(data["name"]).to_upper())


# ------------------------------------------------------------ grid helpers
func cell(x: int, y: int) -> String:
	if x < 0 or x >= W:
		return "#"
	if y < 0:
		return "."
	if y >= H:
		return "#"
	return grid[y][x]


func solid_at(p: Vector2) -> bool:
	var x := floori(p.x / 16.0)
	var y := floori(p.y / 16.0)
	if x < 0 or x >= W:
		return true
	if y < 0 or y >= H:
		return false
	return grid[y][x] == "#"


func ground_at(p: Vector2) -> bool:
	var x := floori(p.x / 16.0)
	var y := floori(p.y / 16.0)
	if x < 0 or x >= W:
		return true
	if y < 0 or y >= H:
		return false
	var c: String = grid[y][x]
	return c == "#" or c == "="


# ------------------------------------------------------------ building
func _build_background() -> void:
	var bg := ParallaxBG.new()
	bg.setup(theme, H * 16.0)
	add_child(bg)


func _build_terrain() -> void:
	terrain_view = TerrainView.new()
	terrain_view.setup(self)
	add_child(terrain_view)
	terrain_body = StaticBody2D.new()
	terrain_body.collision_layer = Game.L_TERRAIN
	terrain_body.collision_mask = 0
	add_child(terrain_body)
	for r in _merge_rects():
		_add_box(terrain_body, Rect2(r.position * 16, r.size * 16), false)
	# one-way planks
	for y in H:
		var x := 0
		while x < W:
			if grid[y][x] == "=":
				var x0 := x
				while x < W and grid[y][x] == "=":
					x += 1
				var body := StaticBody2D.new()
				body.collision_layer = Game.L_ONEWAY
				body.collision_mask = 0
				add_child(body)
				_add_box(body, Rect2(x0 * 16, y * 16, (x - x0) * 16, 8), true)
			else:
				x += 1


func _add_box(body: StaticBody2D, r: Rect2, one_way: bool) -> void:
	var sh := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	sh.shape = rs
	sh.position = r.position + r.size / 2.0
	sh.one_way_collision = one_way
	body.add_child(sh)


func _merge_rects() -> Array[Rect2i]:
	var out: Array[Rect2i] = []
	var open := {}
	for y in range(H + 1):
		var runs := {}
		if y < H:
			var x := 0
			while x < W:
				if grid[y][x] == "#":
					var x0 := x
					while x < W and grid[y][x] == "#":
						x += 1
					runs["%d:%d" % [x0, x]] = [x0, x]
				else:
					x += 1
		for key in open.keys():
			if not runs.has(key):
				var o: Array = open[key]
				out.append(Rect2i(o[0], o[2], o[1] - o[0], y - o[2]))
				open.erase(key)
		for key in runs.keys():
			if not open.has(key):
				open[key] = [runs[key][0], runs[key][1], y]
	return out


func _build_decor() -> void:
	var d := DecorView.new()
	d.z_index = -1
	d.setup(self, blocked)
	add_child(d)


func _build_entities() -> void:
	for c in data["coins"]:
		var p := Pickup.new()
		p.kind = "coin"
		p.level = self
		p.position = Vector2(c[0] * 16.0, c[1] * 16.0)
		add_child(p)
		coin_total += 1
	for g in data["gems"]:
		var p := Pickup.new()
		p.kind = "gem"
		p.level = self
		p.position = Vector2(g[0] * 16.0, g[1] * 16.0)
		add_child(p)
		gem_total += 1
	var spike_tex: Texture2D = load("res://assets/gen/spikes.png")
	for s in data["spikes"]:
		var sp := Sprite2D.new()
		sp.texture = spike_tex
		sp.centered = false
		sp.position = Vector2(s[0] * 16.0, s[1] * 16.0)
		sp.z_index = 2
		add_child(sp)
		spike_rects.append(Rect2(s[0] * 16.0 + 2.0, s[1] * 16.0 + 7.0, 12.0, 9.0))
		blocked[Vector2i(int(s[0]), int(s[1]))] = true
	for s in data["springs"]:
		var sp := Spring.new()
		sp.level = self
		sp.position = Vector2(s[0] * 16.0 + 8.0, (s[1] + 1) * 16.0)
		add_child(sp)
		blocked[Vector2i(int(s[0]), int(s[1]))] = true
	for c in data["checkpoints"]:
		var cp := Checkpoint.new()
		cp.level = self
		cp.position = Vector2(c[0] * 16.0 + 8.0, c[1] * 16.0)
		add_child(cp)
		blocked[Vector2i(int(c[0]), int(c[1]) - 1)] = true
	var gl: Array = data["goal"]
	goal_node = Goal.new()
	goal_node.level = self
	goal_node.position = Vector2(gl[0] * 16.0, gl[1] * 16.0)
	add_child(goal_node)
	for dx in range(-1, 3):
		blocked[Vector2i(int(gl[0]) + dx, int(gl[1]) - 1)] = true
	if not arena.is_empty():
		goal_node.set_enabled(false)
	for m in data["moving"]:
		var mp := MovingPlatform.new()
		mp.setup(theme, Vector2(m["x"] * 16.0, m["y"] * 16.0), Vector2((m["x"] + m["dx"]) * 16.0, (m["y"] + m["dy"]) * 16.0), int(m["w"]), float(m["speed"]))
		add_child(mp)
	for h in data["hints"]:
		var l := Game.make_label(String(h["text"]), 8, Color(1, 1, 1, 0.95), 2)
		l.position = Vector2(h["x"] * 16.0, h["y"] * 16.0)
		l.z_index = 1
		add_child(l)
	for e in data["enemies"]:
		var en := Enemy.new()
		en.setup(String(e["t"]), Vector2(e["x"] * 16.0, e["y"] * 16.0), float(e["r"]), self, {"home_y": float(e.get("home_y", e["y"]))})
		add_child(en)


func _build_player() -> void:
	var s: Array = data["start"]
	player = Player.new()
	player.level = self
	player.position = Vector2(s[0] * 16.0 + 8.0, s[1] * 16.0)
	if Game.tp_x >= 0.0:
		var tx := int(Game.tp_x)
		var ty := 0
		while ty < H and grid[ty][tx] != "#":
			ty += 1
		player.position = Vector2(tx * 16.0 + 8.0, ty * 16.0 - 1.0)
	checkpoint_pos = player.position
	add_child(player)
	blocked[Vector2i(int(s[0]), int(s[1]) - 1)] = true


# ------------------------------------------------------------ loop
func _physics_process(delta: float) -> void:
	if not finished:
		time += delta
	if player == null or player.dead:
		return
	var hb := player.hurtbox()
	for r in spike_rects:
		if hb.intersects(r):
			player.hurt(r.position.x + 6.0)
	if not arena.is_empty() and not arena_active and player.global_position.x > (float(arena["x0"]) + 5.0) * 16.0:
		_start_arena()


func _start_arena() -> void:
	arena_active = true
	var x0 := int(arena["x0"])
	var x1 := int(arena["x1"])
	for y in H:
		for x in [x0, x0 + 1]:
			var row: String = grid[y]
			grid[y] = row.substr(0, x) + "#" + row.substr(x + 1)
	var body := StaticBody2D.new()
	body.collision_layer = Game.L_TERRAIN
	body.collision_mask = 0
	add_child(body)
	_add_box(body, Rect2(x0 * 16, 0, 32, H * 16), false)
	terrain_view.queue_redraw()
	player.cam.limit_left = x0 * 16
	player.cam.limit_right = x1 * 16
	checkpoint_pos = Vector2((x0 + 4) * 16.0, float(arena["top"]) * 16.0)
	boss = Enemy.new()
	boss.setup("boss", Vector2(float(arena["boss_x"]) * 16.0, float(arena["top"]) * 16.0), 0.0, self)
	add_child(boss)
	boss.player = player
	hud.set_boss(boss.hp, boss.max_hp, true)
	hud.toast("KING PIG APPEARS!")
	player.shake(3.0, 0.5)
	Game.play("boss_hit", -4.0, 0.6)
	Game.play_music("boss")


# ------------------------------------------------------------ events
func on_hp_changed(hp: int) -> void:
	if hud:
		hud.set_hp(hp)


func on_pickup(kind: String, pos: Vector2) -> void:
	if kind == "coin":
		coins += 1
		Game.play("coin", -4.0, 1.0 + minf(0.3, (coins % 8) * 0.04))
		Fx.burst(self, pos, Color("ffd23f"), 4, 50.0, 0.3, 2.0, 0.0)
	else:
		gems += 1
		Game.play("gem")
		Fx.burst(self, pos, Color("6fe3ff"), 12, 90.0, 0.5, 3.0, 0.0)
		Fx.popup(self, pos + Vector2(0, -8), "GEM!", Color("6fe3ff"))
		hud.toast("GEM %d / %d" % [gems, gem_total])
	hud.set_counts()


func on_checkpoint(pos: Vector2) -> void:
	checkpoint_pos = pos
	Game.play("checkpoint")
	hud.toast("CHECKPOINT!")
	Fx.burst(self, pos + Vector2(5, -30), Color("ff6b7a"), 10, 70.0, 0.5, 3.0, 0.0)


func on_enemy_killed(pos: Vector2, was_boss: bool) -> void:
	kills += 1
	if was_boss:
		_boss_defeated(pos)
		return
	coins += 1
	hud.set_counts()
	Fx.popup(self, pos + Vector2(-4, -8), "+1", Color("ffd23f"))


func on_boss_hp(hp: int, max_hp: int) -> void:
	hud.set_boss(hp, max_hp, true)


func _boss_defeated(pos: Vector2) -> void:
	hud.set_boss(0, 1, false)
	Game.play("boss_die")
	player.shake(6.0, 0.8)
	for i in 14:
		var p := Pickup.new()
		p.kind = "coin"
		p.level = self
		p.position = pos + Vector2(randf_range(-40, 40), randf_range(-50, -10))
		add_child(p)
		coin_total += 1
	for i in 5:
		Fx.burst(self, pos + Vector2(randf_range(-30, 30), randf_range(-50, 0)), Color("ffd23f") if i % 2 == 0 else Color.WHITE, 12, 130.0, 0.7, 4.0)
	hud.toast("KING PIG DEFEATED!")
	goal_node.set_enabled(true)
	Game.play_music(String(data["music"]))


func on_player_died() -> void:
	if respawning:
		return
	respawning = true
	deaths += 1
	await get_tree().create_timer(1.1).timeout
	await Game.fade_out(0.25)
	player.respawn(checkpoint_pos)
	await Game.fade_in(0.25)
	respawning = false


func finish() -> void:
	if finished:
		return
	finished = true
	player.cheer()
	Game.music_player.stop()
	Game.play("win")
	Game.record_result(Game.current_level, coins, gems, time)
	Fx.burst(self, goal_node.position + Vector2(8, -40), Color("ffd23f"), 24, 140.0, 0.8, 4.0)
	await get_tree().create_timer(1.6).timeout
	hud.show_result({"coins": coins, "coin_total": coin_total, "gems": gems, "gem_total": gem_total,
		"time": time, "deaths": deaths, "kills": kills})
