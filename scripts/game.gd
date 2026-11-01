extends Node
## Autoload singleton: input map, audio, save data, sprite frames, scene transitions.

const LEVELS := ["res://levels/level1.json", "res://levels/level2.json", "res://levels/level3.json"]
const SAVE_PATH := "user://bunny_quest.cfg"

# collision layers (bit values)
const L_TERRAIN := 1
const L_ONEWAY := 2
const L_PLAYER := 4
const L_ENEMY := 8

var current_level := 0
var unlocked := 1
var best := {}                     # "0" -> {coins, gems, time}
var manifest := {}
var frames_cache := {}
var sounds := {}
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_index := 0
var music_player: AudioStreamPlayer
var music_name := ""
var ui_font: FontFile
var star_tex: Texture2D
var fade_rect: ColorRect
var transitioning := false

# test / debug helpers (used from the command line, harmless otherwise)
var bot := false
var god := false
var shots: Array = []
var shot_prefix := "/tmp/shot_"
var frame_count := 0
var tp_x := -1.0
var killboss := false
var presses: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_load_manifest()
	_load_font()
	_load_sounds()
	_setup_audio()
	_setup_fade()
	_load_save()
	star_tex = load("res://assets/gen/star.png")
	_parse_args()


# ---------------------------------------------------------------- input
func _setup_input() -> void:
	var keys := {
		"left": [KEY_LEFT, KEY_A],
		"right": [KEY_RIGHT, KEY_D],
		"up": [KEY_UP, KEY_W],
		"down": [KEY_DOWN, KEY_S],
		"jump": [KEY_SPACE, KEY_W, KEY_UP, KEY_Z, KEY_K],
		"accept": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
		"pause": [KEY_ESCAPE, KEY_P],
		"restart": [KEY_R],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)
		for k in keys[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
	var pads := {
		"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
		"up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN,
		"jump": JOY_BUTTON_A, "accept": JOY_BUTTON_A, "pause": JOY_BUTTON_START,
	}
	for action in pads:
		var b := InputEventJoypadButton.new()
		b.button_index = pads[action]
		InputMap.action_add_event(action, b)
	var axes := [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0],
		["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0]]
	for a in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = a[1]
		m.axis_value = a[2]
		InputMap.action_add_event(a[0], m)


# ---------------------------------------------------------------- assets
func _load_manifest() -> void:
	var f := FileAccess.open("res://assets/manifest.json", FileAccess.READ)
	manifest = JSON.parse_string(f.get_as_text())


func get_frames(group: String) -> SpriteFrames:
	if frames_cache.has(group):
		return frames_cache[group]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	if not manifest.has(group):
		push_error("Unknown sprite group: " + group)
		return sf
	var g: Dictionary = manifest[group]
	for anim_name in g:
		var info: Dictionary = g[anim_name]
		var tex: Texture2D = load(info["file"])
		var fw := int(info["fw"])
		var fh := int(info["fh"])
		var start := int(info.get("start", 0))
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(info.get("fps", 12)))
		sf.set_animation_loop(anim_name, bool(info.get("loop", true)))
		for i in int(info["n"]):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2((start + i) * fw, 0, fw, fh)
			sf.add_frame(anim_name, at)
	frames_cache[group] = sf
	return sf


func _load_font() -> void:
	ui_font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	if ui_font:
		ui_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		ui_font.hinting = TextServer.HINTING_NONE
		ui_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED


func make_label(text: String, size := 16, color := Color.WHITE, outline := -1) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = ui_font
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = outline if outline >= 0 else maxi(2, size / 4)
	ls.outline_color = Color(0.06, 0.03, 0.14, 1)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ---------------------------------------------------------------- audio
func _load_sounds() -> void:
	for n in ["jump", "djump", "coin", "gem", "stomp", "hurt", "spring", "checkpoint", "win", "die", "shoot",
			"land", "select", "pause", "start", "boss_hit", "boss_die", "bullet_break"]:
		var p := "res://assets/audio/%s.wav" % n
		if ResourceLoader.exists(p):
			sounds[n] = load(p)


func _setup_audio() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -9.0
	add_child(music_player)
	music_player.finished.connect(func(): music_player.play())


func play(sound: String, vol := 0.0, pitch := 1.0) -> void:
	if not sounds.has(sound):
		return
	var p := sfx_players[sfx_index]
	sfx_index = (sfx_index + 1) % sfx_players.size()
	p.stream = sounds[sound]
	p.volume_db = vol - 4.0
	p.pitch_scale = pitch
	p.play()


func play_music(track: String) -> void:
	if music_name == track and music_player.playing:
		return
	music_name = track
	var path := "res://assets/audio/music_%s.wav" % track
	if not ResourceLoader.exists(path):
		return
	var s: AudioStreamWAV = load(path)
	if s:
		var bytes_per := 2 if s.format == AudioStreamWAV.FORMAT_16_BITS else 1
		var samples := int(s.data.size() / (bytes_per * (2 if s.stereo else 1)))
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples
	music_player.stream = s
	music_player.play()


func stop_music() -> void:
	music_player.stop()
	music_name = ""


# ---------------------------------------------------------------- transitions
func _setup_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0.03, 0.02, 0.08, 0.0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade_rect)


func fade_out(d := 0.25) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0, d)
	await tw.finished


func fade_in(d := 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, d)
	await tw.finished


func change_scene(path: String) -> void:
	if transitioning:
		return
	transitioning = true
	await fade_out(0.25)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in(0.3)
	transitioning = false


func start_level(i: int) -> void:
	current_level = clampi(i, 0, LEVELS.size() - 1)
	play("start")
	change_scene("res://scenes/level.tscn")


func next_level() -> void:
	if current_level + 1 >= LEVELS.size():
		change_scene("res://scenes/ending.tscn")
	else:
		start_level(current_level + 1)


# ---------------------------------------------------------------- save
func _load_save() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	unlocked = int(cf.get_value("progress", "unlocked", 1))
	best = cf.get_value("progress", "best", {})


func save_game() -> void:
	var cf := ConfigFile.new()
	cf.set_value("progress", "unlocked", unlocked)
	cf.set_value("progress", "best", best)
	cf.save(SAVE_PATH)


func record_result(idx: int, coins: int, gems: int, time: float) -> void:
	var k := str(idx)
	var old: Dictionary = best.get(k, {"coins": 0, "gems": 0, "time": 99999.0})
	best[k] = {
		"coins": maxi(int(old["coins"]), coins),
		"gems": maxi(int(old["gems"]), gems),
		"time": minf(float(old["time"]), time),
	}
	unlocked = maxi(unlocked, mini(idx + 2, LEVELS.size()))
	save_game()


func fmt_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]


# ---------------------------------------------------------------- debug args
func _parse_args() -> void:
	var start := -1
	for a in OS.get_cmdline_user_args():
		if a == "--bot":
			bot = true
		elif a == "--god":
			god = true
		elif a.begins_with("--level="):
			start = int(a.get_slice("=", 1))
		elif a.begins_with("--shots="):
			for s in a.get_slice("=", 1).split(","):
				shots.append(int(s))
		elif a.begins_with("--prefix="):
			shot_prefix = a.get_slice("=", 1)
		elif a.begins_with("--press="):
			for p in a.get_slice("=", 1).split(","):
				presses.append([int(p.get_slice(":", 0)), p.get_slice(":", 1)])
		elif a == "--killboss":
			killboss = true
		elif a.begins_with("--tp="):
			tp_x = float(a.get_slice("=", 1))
		elif a.begins_with("--speed="):
			Engine.time_scale = float(a.get_slice("=", 1))
	if start >= 0:
		unlocked = 3
		await get_tree().process_frame
		start_level(start)


func _process(_delta: float) -> void:
	frame_count += 1
	if bot and frame_count % 300 == 0:
		var pl = get_tree().get_first_node_in_group("player")
		var lv = get_tree().current_scene
		if pl and lv and "deaths" in lv:
			print("[bot] frame ", frame_count, " tile_x=", int(pl.global_position.x / 16.0), " hp=", pl.hp, " deaths=", lv.deaths, " coins=", lv.coins, " finished=", lv.finished)
	for p in presses:
		if p[0] == frame_count:
			var ev := InputEventAction.new()
			ev.action = p[1]
			ev.pressed = true
			Input.parse_input_event(ev)
	if killboss and frame_count > 150 and frame_count % 90 == 0:
		for e in get_tree().get_nodes_in_group("enemy"):
			if e.boss_flag and not e.dead:
				e._on_stomped()
	if shots.has(frame_count):
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s%d.png" % [shot_prefix, frame_count])
