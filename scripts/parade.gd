class_name Parade
extends Node2D
## A chase scene: the bunny runs with every enemy of the pack behind it. Follows the camera.

const RUNNERS := [
	["angrypig", "run"], ["chicken", "run"], ["mushroom", "run"], ["rino", "run"], ["trunk", "run"],
	["radish", "run"], ["rock2", "run"], ["slime", "idle_run"], ["snail", "walk"], ["rock1", "run"],
]
const FLYERS := [
	["bat", "flying"], ["bluebird", "flying"], ["bee", "idle"], ["ghost", "idle"], ["fatbird", "idle"], ["skull", "idle_2"],
]

var ground_y := 352.0
var items: Array = []
var t := 0.0


func setup(gy: float) -> void:
	ground_y = gy
	z_index = 5
	var bun := _make("bunny", "run", 34.0)
	items.append({"n": bun, "off": 40.0, "y": gy, "fly": false, "ph": 0.0, "amp": 0.0})
	var off := -20.0
	for i in RUNNERS.size():
		var r: Array = RUNNERS[i]
		var s := _make(r[0], r[1], 30.0)
		off -= 38.0 + (i % 3) * 6.0
		items.append({"n": s, "off": off, "y": gy, "fly": false, "ph": randf() * 6.0, "amp": 10.0})
	for i in FLYERS.size():
		var f: Array = FLYERS[i]
		var s := _make(f[0], f[1], 0.0)
		items.append({"n": s, "off": -230.0 + i * 70.0, "y": gy - 56.0 - (i % 3) * 14.0, "fly": true, "ph": randf() * 6.0, "amp": 6.0})


func _make(group: String, anim: String, _h: float) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = Game.get_frames(group)
	s.flip_h = true      # all art faces left, we run to the right
	add_child(s)
	s.play(anim)
	s.set_meta("fh", s.sprite_frames.get_frame_texture(anim, 0).get_size().y)
	return s


func _process(delta: float) -> void:
	t += delta
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var cx := cam.get_screen_center_position().x
	for it in items:
		var s: AnimatedSprite2D = it["n"]
		var fh: float = s.get_meta("fh")
		var x: float = cx + float(it["off"]) + sin(t * 1.3 + float(it["ph"])) * float(it["amp"])
		var y: float = float(it["y"])
		if it["fly"]:
			y += sin(t * 2.0 + float(it["ph"])) * 8.0
			s.position = Vector2(x, y)
		else:
			s.position = Vector2(x, y - fh / 2.0)
