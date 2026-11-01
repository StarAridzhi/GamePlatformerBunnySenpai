class_name Enemy
extends CharacterBody2D
## Data-driven enemy with many behaviours (walker, charger, hopper, flyer, bat, ghost, shooter, turtle, skull, slam, boss).

const GRAVITY := 900.0

const TYPES := {
	"slime": {"g": "slime", "hb": Vector2(30, 18), "beh": "walker", "spd": 18.0, "move": "idle_run", "idle": "idle_run", "hit": "hit"},
	"snail": {"g": "snail", "hb": Vector2(26, 16), "beh": "walker", "spd": 12.0, "move": "walk", "idle": "idle", "hit": "hit"},
	"mushroom": {"g": "mushroom", "hb": Vector2(22, 18), "beh": "walker", "spd": 26.0, "move": "run", "idle": "idle", "hit": "hit"},
	"chicken": {"g": "chicken", "hb": Vector2(20, 24), "beh": "walker", "spd": 16.0, "chase": 62.0, "move": "run", "idle": "idle", "hit": "hit"},
	"pig": {"g": "angrypig", "hb": Vector2(26, 22), "beh": "walker", "spd": 20.0, "chase": 78.0, "move": "walk", "chase_anim": "run", "idle": "idle", "hit": "hit_1"},
	"radish": {"g": "radish", "hb": Vector2(20, 26), "beh": "walker", "spd": 26.0, "move": "run", "idle": "idle_1", "hit": "hit", "hp": 2},
	"rock1": {"g": "rock1", "hb": Vector2(28, 24), "beh": "walker", "spd": 16.0, "move": "run", "idle": "idle", "hit": "hit"},
	"rock2": {"g": "rock2", "hb": Vector2(24, 20), "beh": "walker", "spd": 20.0, "move": "run", "idle": "idle", "hit": "hit"},
	"rock3": {"g": "rock3", "hb": Vector2(14, 12), "beh": "walker", "spd": 28.0, "move": "run", "idle": "idle", "hit": "hit"},
	"rino": {"g": "rino", "hb": Vector2(34, 22), "beh": "charger", "spd": 14.0, "charge": 190.0, "move": "run", "idle": "idle", "hit": "hit"},
	"duck": {"g": "duck", "hb": Vector2(22, 24), "beh": "hopper", "idle": "idle", "hit": "hit"},
	"trunk": {"g": "trunk", "hb": Vector2(26, 24), "beh": "trunk", "spd": 14.0, "move": "run", "idle": "idle", "attack": "attack", "hit": "hit", "ox": 5.0, "shoot_frame": 5, "bullet": "trunk"},
	"plant": {"g": "plant", "hb": Vector2(22, 30), "beh": "shooter", "idle": "idle", "attack": "attack", "hit": "hit", "ox": 4.0, "shoot_frame": 4, "bullet": "plant"},
	"turtle": {"g": "turtle", "hb": Vector2(30, 18), "beh": "turtle", "idle": "idle_2", "hit": "hit"},
	"bluebird": {"g": "bluebird", "hb": Vector2(22, 16), "beh": "flyer", "feet": false, "spd": 34.0, "move": "flying", "idle": "flying", "hit": "hit"},
	"bee": {"g": "bee", "hb": Vector2(22, 22), "beh": "bee", "feet": false, "idle": "idle", "attack": "attack", "hit": "hit", "shoot_frame": 4, "bullet": "bee"},
	"bat": {"g": "bat", "hb": Vector2(20, 16), "beh": "bat", "feet": false, "idle": "idle", "hit": "hit"},
	"ghost": {"g": "ghost", "hb": Vector2(20, 20), "beh": "ghost", "feet": false, "idle": "idle", "hit": "hit"},
	"skull": {"g": "skull", "hb": Vector2(26, 24), "beh": "skull", "feet": false, "idle": "idle_2", "hit": "hit"},
	"fatbird": {"g": "fatbird", "hb": Vector2(30, 34), "beh": "slam", "feet": false, "idle": "idle", "hit": "hit"},
	"boss": {"g": "angrypig", "hb": Vector2(26, 22), "beh": "boss", "scale": 3.0, "hp": 5, "idle": "idle", "hit": "hit_1"},
}

var type := "slime"
var cfg: Dictionary
var level
var player: Player
var spr: AnimatedSprite2D
var hb := Vector2(20, 20)
var feet := true
var scale_f := 1.0
var dir := -1
var state := ""
var timer := 0.0
var t := 0.0
var home := Vector2.ZERO
var leash := 64.0
var hp := 1
var dead := false
var dead_spin := 0.0
var invuln := 0.0
var shot_cd := 1.0
var stomp_mode := 1      # 0 = spiky (hurts when stomped), 1 = killable, 2 = bounce only
var harmful := true
var vy := 0.0
var vel2 := Vector2.ZERO
var boss_flag := false
var max_hp := 1
var extra := {}


func setup(type_name: String, pos: Vector2, r_tiles: float, lvl, params := {}) -> void:
	type = type_name
	cfg = TYPES[type_name]
	position = pos
	home = pos
	leash = r_tiles * 16.0
	level = lvl
	extra = params


func _uses_physics() -> bool:
	return cfg["beh"] in ["walker", "charger", "hopper", "trunk", "boss"]


func _ready() -> void:
	add_to_group("enemy")
	feet = cfg.get("feet", true)
	scale_f = cfg.get("scale", 1.0)
	hb = cfg["hb"] * scale_f
	hp = cfg.get("hp", 1)
	max_hp = hp
	boss_flag = cfg["beh"] == "boss"
	collision_layer = Game.L_ENEMY
	collision_mask = (Game.L_TERRAIN | Game.L_ONEWAY) if _uses_physics() else 0
	z_index = 4
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Game.get_frames(cfg["g"])
	spr.scale = Vector2(scale_f, scale_f)
	add_child(spr)
	if _uses_physics():
		var sh := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = hb
		sh.shape = rs
		sh.position = Vector2(0, -hb.y / 2.0)
		add_child(sh)
		position.y -= 0.5
	spr.animation_finished.connect(_on_anim_finished)
	spr.frame_changed.connect(_on_frame_changed)
	timer = randf_range(0.4, 1.2)
	t = randf() * 6.0
	dir = -1 if randf() < 0.5 else 1
	_init_state()
	_play(cfg.get("idle", cfg.get("move", "")))
	_sprite_pos()


func _init_state() -> void:
	match cfg["beh"]:
		"charger": state = "patrol"
		"hopper": state = "idle"
		"trunk": state = "move"
		"shooter": state = "idle"
		"bee": state = "idle"
		"bat": state = "hang"
		"turtle":
			state = "safe"
			timer = randf_range(1.0, 2.2)
		"skull":
			state = "calm"
			timer = randf_range(1.5, 3.0)
			vel2 = Vector2(1 if dir > 0 else -1, 0.6) * 42.0
		"slam": state = "idle"
		"boss":
			state = "walk"
			timer = 2.0
			stomp_mode = 2
		_: state = "move"


func _sprite_pos() -> void:
	var ox: float = cfg.get("ox", 0.0) * scale_f
	if feet:
		var fh: float = spr.sprite_frames.get_frame_texture(spr.animation, 0).get_size().y if spr.animation != "" else 30.0
		spr.position = Vector2(ox * dir, -fh * scale_f / 2.0)
	else:
		spr.position = Vector2(ox * dir, 0)
	spr.flip_h = dir > 0


func _play(anim: String) -> void:
	if anim == "" or not spr.sprite_frames.has_animation(anim):
		return
	if spr.animation != anim or not spr.is_playing():
		spr.play(anim)


func rect() -> Rect2:
	var p := global_position
	return Rect2(p + Vector2(-hb.x / 2.0, -hb.y if feet else -hb.y / 2.0), hb)


func _pv() -> bool:
	return player != null and is_instance_valid(player) and not player.dead


func _dx() -> float:
	return player.global_position.x - global_position.x


func _dy() -> float:
	var my := global_position.y - (hb.y / 2.0 if feet else 0.0)
	return (player.global_position.y - 14.0) - my


func _sees(rx: float, ry: float) -> bool:
	if not _pv():
		return false
	var dx := _dx()
	return absf(dx) < rx and absf(_dy()) < ry and (1 if dx > 0.0 else -1) == dir


func _face_player() -> void:
	if _pv():
		dir = 1 if _dx() > 0.0 else -1


# ------------------------------------------------------------ main loop
func _physics_process(delta: float) -> void:
	if dead:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		spr.rotation += dead_spin * delta
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return
	if absf(player.global_position.x - global_position.x) > 560.0 and not boss_flag:
		return
	t += delta
	invuln -= delta
	shot_cd -= delta
	match cfg["beh"]:
		"walker": _walker(delta)
		"charger": _charger(delta)
		"hopper": _hopper(delta)
		"trunk": _trunk(delta)
		"shooter": _shooter(delta)
		"turtle": _turtle(delta)
		"flyer": _flyer(delta)
		"bee": _bee(delta)
		"bat": _bat(delta)
		"ghost": _ghost(delta)
		"skull": _skull(delta)
		"slam": _slam(delta)
		"boss": _boss(delta)
	_sprite_pos()
	if state == "stun":
		queue_redraw()
	_check_player()


func _gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 380.0)


func _patrol_turn() -> void:
	if is_on_wall():
		dir = -dir
	elif is_on_floor():
		var ahead := global_position + Vector2(dir * (hb.x * 0.5 + 3.0), 3.0)
		if not level.ground_at(ahead):
			dir = -dir
	if leash > 0.0:
		var off := global_position.x - home.x
		if absf(off) > leash and (1 if off > 0.0 else -1) == dir:
			dir = -dir


# ------------------------------------------------------------ behaviours
func _walker(delta: float) -> void:
	var sp: float = cfg["spd"]
	var anim: String = cfg["move"]
	if cfg.has("chase") and _sees(110.0, 26.0):
		sp = cfg["chase"]
		anim = cfg.get("chase_anim", cfg["move"])
	if hp < max_hp:
		sp *= 1.7
	_play(anim)
	_gravity(delta)
	velocity.x = dir * sp
	move_and_slide()
	_patrol_turn()


func _charger(delta: float) -> void:
	_gravity(delta)
	match state:
		"patrol":
			spr.speed_scale = 0.5
			_play("run")
			velocity.x = dir * float(cfg["spd"])
			move_and_slide()
			_patrol_turn()
			if _sees(230.0, 28.0):
				state = "windup"
				timer = 0.55
				velocity.x = 0.0
		"windup":
			spr.speed_scale = 1.0
			velocity.x = 0.0
			_play("idle")
			move_and_slide()
			timer -= delta
			spr.offset.x = sin(t * 70.0) * 1.0
			if timer <= 0.0:
				spr.offset.x = 0.0
				state = "charge"
		"charge":
			spr.speed_scale = 1.6
			_play("run")
			velocity.x = dir * float(cfg["charge"])
			move_and_slide()
			if is_on_wall():
				_stun(1.5)
			elif is_on_floor() and not level.ground_at(global_position + Vector2(dir * (hb.x * 0.5 + 6.0), 3.0)):
				_stun(0.8)
		"stun":
			velocity.x = 0.0
			move_and_slide()
			timer -= delta
			if timer <= 0.0:
				state = "patrol"
				dir = -dir
				stomp_mode = 1


func _stun(d: float) -> void:
	state = "stun"
	timer = d
	spr.speed_scale = 1.0
	if spr.sprite_frames.has_animation("hit_wall"):
		spr.play("hit_wall")
	Game.play("stomp", -8.0, 0.7)
	if _pv() and absf(_dx()) < 300.0:
		player.shake(2.5, 0.2)
	Fx.puff(level, global_position + Vector2(dir * 18, -4), 5, 20.0)


func _hopper(delta: float) -> void:
	_gravity(delta)
	match state:
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_play("idle")
			timer -= delta
			if timer <= 0.0:
				if _pv() and absf(_dx()) < 220.0:
					_face_player()
				elif absf(global_position.x - home.x) > leash and leash > 0.0:
					dir = 1 if home.x > global_position.x else -1
				state = "wind"
				timer = 0.3
				if spr.sprite_frames.has_animation("jump_anticipation"):
					spr.play("jump_anticipation")
		"wind":
			velocity.x = 0.0
			timer -= delta
			if timer <= 0.0:
				velocity = Vector2(dir * 70.0, -250.0)
				state = "air"
				timer = 0.12
		"air":
			timer -= delta
			_play("jump" if velocity.y < 0.0 else "fall")
	move_and_slide()
	if state == "air" and timer <= 0.0 and is_on_floor():
		state = "idle"
		timer = randf_range(0.7, 1.4)
		Fx.puff(level, global_position, 2, 10.0)
	if state == "air" and is_on_wall():
		velocity.x = 0.0


func _trunk(delta: float) -> void:
	_gravity(delta)
	if state == "attack":
		velocity.x = 0.0
		move_and_slide()
		return
	_play(cfg["move"])
	velocity.x = dir * float(cfg["spd"])
	move_and_slide()
	_patrol_turn()
	if shot_cd <= 0.0 and _sees(200.0, 26.0):
		state = "attack"
		velocity.x = 0.0
		shot_cd = 2.6
		spr.play(cfg["attack"])


func _shooter(_delta: float) -> void:
	if state == "idle":
		_face_player()
		_play("idle")
		if shot_cd <= 0.0 and _pv() and absf(_dx()) < 210.0 and absf(_dy()) < 60.0:
			state = "attack"
			shot_cd = 2.4
			spr.play(cfg["attack"])


func _turtle(delta: float) -> void:
	timer -= delta
	match state:
		"safe":
			stomp_mode = 1
			_play("idle_2")
			if timer <= 0.0:
				state = "out"
				spr.play("spikes_out")
		"spiky":
			stomp_mode = 0
			_play("idle_1")
			if timer <= 0.0:
				state = "in"
				spr.play("spikes_in")
		"out":
			stomp_mode = 0
		"in":
			stomp_mode = 1


func _flyer(delta: float) -> void:
	_play(cfg["move"])
	position.x += dir * float(cfg["spd"]) * delta
	position.y = home.y + sin(t * 2.2) * 8.0
	var off := position.x - home.x
	if absf(off) > leash or level.solid_at(position + Vector2(dir * 14.0, 0)):
		dir = -1 if off > 0.0 else 1
		if absf(off) <= leash:
			dir = -dir


func _bee(delta: float) -> void:
	position.y = home.y + sin(t * 3.0) * 5.0
	position.x += dir * 14.0 * delta
	var off := position.x - home.x
	if absf(off) > leash and (1 if off > 0.0 else -1) == dir:
		dir = -dir
	if state == "idle":
		_play("idle")
		if shot_cd <= 0.0 and _pv() and absf(_dx()) < 36.0 and _dy() > 10.0 and _dy() < 170.0:
			state = "attack"
			shot_cd = 2.2
			spr.play("attack")


func _bat(delta: float) -> void:
	match state:
		"hang":
			_play("idle")
			if _pv() and absf(_dx()) < 110.0 and _dy() > 0.0 and _dy() < 150.0:
				state = "wake"
				spr.play("ceiling_out")
		"wake":
			pass
		"chase":
			_play("flying")
			timer -= delta
			var target := player.global_position + Vector2(0, -14) if _pv() else home
			var want := (target - position).normalized() * 78.0
			vel2 = vel2.lerp(want, minf(1.0, 4.0 * delta))
			position += vel2 * delta
			if absf(vel2.x) > 4.0:
				dir = 1 if vel2.x > 0.0 else -1
			if timer <= 0.0:
				state = "return"
		"return":
			_play("flying")
			var d := home - position
			vel2 = vel2.lerp(d.normalized() * 70.0, minf(1.0, 4.0 * delta))
			position += vel2 * delta
			if absf(vel2.x) > 4.0:
				dir = 1 if vel2.x > 0.0 else -1
			if d.length() < 5.0:
				position = home
				vel2 = Vector2.ZERO
				state = "settle"
				spr.play("ceiling_in")
		"settle":
			pass


func _ghost(delta: float) -> void:
	_play("idle")
	var looked := false
	if _pv():
		var away := signf(global_position.x - player.global_position.x)
		looked = int(away) == player.facing and absf(_dx()) < 280.0
	harmful = not looked
	var target_a := 0.3 if looked else (0.85 + sin(t * 4.0) * 0.1)
	modulate.a = move_toward(modulate.a, target_a, 3.0 * delta)
	if not looked and _pv() and absf(_dx()) < 300.0 and absf(_dy()) < 200.0:
		var d := (player.global_position + Vector2(0, -14)) - global_position
		position += d.normalized() * 36.0 * delta
		dir = 1 if d.x > 0.0 else -1
	else:
		position.y += sin(t * 2.0) * 0.12


func _skull(delta: float) -> void:
	timer -= delta
	if state == "aura":
		stomp_mode = 0
		hb = Vector2(34, 34)
	else:
		stomp_mode = 1
		hb = Vector2(26, 24)
	if spr.animation.begins_with("idle") or not spr.is_playing():
		_play("idle_1" if state == "aura" else "idle_2")
	if timer <= 0.0:
		state = "aura" if state == "calm" else "calm"
		timer = 3.0 if state == "aura" else 3.5
		Fx.burst(level, global_position, Color("ff8a3d"), 8, 70.0, 0.35, 3.0, 0.0)
	position += vel2 * delta
	var bounced := false
	if level.solid_at(position + Vector2(signf(vel2.x) * 15.0, 0)) or (leash > 0.0 and absf(position.x - home.x) > leash and signf(position.x - home.x) == signf(vel2.x)):
		vel2.x = -vel2.x
		bounced = true
	var home_y: float = extra.get("home_y", home.y / 16.0) * 16.0
	if level.solid_at(position + Vector2(0, signf(vel2.y) * 15.0)) or absf(position.y - home_y) > 40.0 and signf(position.y - home_y) == signf(vel2.y):
		vel2.y = -vel2.y
		bounced = true
	if bounced:
		var a := "hit_wall_2" if state == "aura" else "hit_wall_1"
		if spr.sprite_frames.has_animation(a):
			spr.play(a)
		Fx.burst(level, global_position, Color("ffb347"), 3, 50.0, 0.3, 2.0, 0.0)
	dir = 1 if vel2.x > 0.0 else -1


func _slam(delta: float) -> void:
	match state:
		"idle":
			stomp_mode = 1
			_play("idle")
			position.y = home.y + sin(t * 2.0) * 2.0
			if shot_cd <= 0.0 and _pv() and absf(_dx()) < 22.0 and _dy() > 0.0 and _dy() < 220.0:
				state = "fall"
				vy = 0.0
				_play("fall")
		"fall":
			stomp_mode = 0
			vy += 760.0 * delta
			position.y += vy * delta
			if level.solid_at(position + Vector2(0, hb.y / 2.0 + 1.0)):
				state = "ground"
				timer = 0.9
				_play("ground")
				Game.play("stomp", -2.0, 0.6)
				if _pv() and absf(_dx()) < 320.0:
					player.shake(3.0, 0.25)
				Fx.puff(level, position + Vector2(0, hb.y / 2.0), 6, 30.0)
		"ground":
			stomp_mode = 0
			timer -= delta
			if timer <= 0.0:
				state = "rise"
		"rise":
			stomp_mode = 1
			_play("idle")
			position.y -= 55.0 * delta
			if position.y <= home.y:
				position.y = home.y
				state = "idle"
				shot_cd = 1.2


func _boss(delta: float) -> void:
	_gravity(delta)
	var rage := 1.0 + 0.25 * float(max_hp - hp)
	match state:
		"walk":
			stomp_mode = 2
			_face_player()
			_play("walk")
			velocity.x = dir * 38.0 * rage
			move_and_slide()
			timer -= delta
			if timer <= 0.0:
				state = "telegraph"
				timer = 0.9 / rage
		"telegraph":
			stomp_mode = 2
			velocity.x = 0.0
			_face_player()
			_play("idle")
			move_and_slide()
			timer -= delta
			spr.offset.x = sin(t * 60.0) * 1.2
			spr.self_modulate = Color(1.6, 0.6, 0.6) if int(t * 14.0) % 2 == 0 else Color.WHITE
			if timer <= 0.0:
				spr.offset.x = 0.0
				spr.self_modulate = Color.WHITE
				state = "charge"
		"charge":
			stomp_mode = 2
			_play("run")
			velocity.x = dir * 190.0 * rage
			move_and_slide()
			if is_on_wall():
				state = "stun"
				timer = 2.8
				stomp_mode = 1
				harmful = false
				spr.play("hit_1")
				Game.play("boss_hit", -4.0, 0.8)
				if _pv():
					player.shake(5.0, 0.35)
				Fx.puff(level, global_position + Vector2(dir * 36, -10), 8, 40.0)
		"stun":
			velocity.x = 0.0
			move_and_slide()
			timer -= delta
			if timer <= 0.0:
				_boss_recover()
		"hurt":
			velocity.x = 0.0
			move_and_slide()
			timer -= delta
			if timer <= 0.0:
				state = "walk"
				timer = 1.2
				harmful = true
				stomp_mode = 2


func _boss_recover() -> void:
	state = "walk"
	timer = 1.6
	harmful = true
	stomp_mode = 2
	spr.self_modulate = Color.WHITE


# ------------------------------------------------------------ callbacks
func _on_frame_changed() -> void:
	if dead:
		return
	if spr.animation == cfg.get("attack", "-") and spr.frame == int(cfg.get("shoot_frame", 4)):
		_shoot()


func _on_anim_finished() -> void:
	if dead:
		return
	var a := spr.animation
	match cfg["beh"]:
		"shooter":
			if a == "attack": state = "idle"
		"trunk":
			if a == "attack": state = "move"
		"bee":
			if a == "attack": state = "idle"
		"turtle":
			if a == "spikes_out":
				state = "spiky"
				timer = 1.8
			elif a == "spikes_in":
				state = "safe"
				timer = 2.2
		"bat":
			if a == "ceiling_out":
				state = "chase"
				timer = 4.0
				vel2 = Vector2.ZERO
			elif a == "ceiling_in":
				state = "hang"
		"boss":
			if a == "hit_1" and state == "stun":
				_play("idle")


func _shoot() -> void:
	var b := Bullet.new()
	var g: String = cfg["bullet"]
	b.level = level
	b.group = "plant" if g == "plant" else g
	if cfg["beh"] == "bee":
		b.position = global_position + Vector2(0, 12)
		b.vel = Vector2(0, 110)
	else:
		b.position = global_position + Vector2(dir * 18.0, -hb.y * 0.55)
		b.vel = Vector2(dir * 105.0, 0)
	level.add_child(b)
	Game.play("shoot", -6.0)


func _draw() -> void:
	if state == "stun" and Game.star_tex:
		var c := Vector2(0, -hb.y - 8.0) if feet else Vector2(0, -hb.y / 2.0 - 8.0)
		for i in 3:
			var a := t * 5.0 + i * TAU / 3.0
			draw_texture(Game.star_tex, c + Vector2(cos(a) * 14.0 * scale_f, sin(a) * 4.0) - Game.star_tex.get_size() / 2.0)


# ------------------------------------------------------------ player contact
func _check_player() -> void:
	if not _pv() or not harmful:
		return
	var pr: Rect2 = player.hurtbox()
	var er := rect()
	if not pr.intersects(er):
		return
	var stomping: bool = player.velocity.y > 20.0 and pr.end.y < er.position.y + er.size.y * 0.6
	if stomping:
		match stomp_mode:
			1:
				if invuln > 0.0:
					player.bounce()
				else:
					_on_stomped()
			2:
				player.bounce()
				Game.play("land", -4.0, 1.4)
			_:
				player.hurt(global_position.x)
	else:
		player.hurt(global_position.x)


func _on_stomped() -> void:
	player.bounce()
	hp -= 1
	Game.play("stomp")
	if boss_flag:
		level.on_boss_hp(hp, max_hp)
		Game.play("boss_hit")
		player.shake(4.0, 0.3)
		if hp <= 0:
			kill()
			return
		state = "hurt"
		timer = 1.1
		invuln = 1.1
		spr.play("hit_1")
		spr.self_modulate = Color.WHITE
		harmful = false
		_flash()
		return
	if hp <= 0:
		kill()
	else:
		invuln = 0.4
		_flash()
		Fx.burst(level, global_position + Vector2(0, -hb.y / 2.0), Color.WHITE, 5, 60.0)


func _flash() -> void:
	spr.modulate = Color(3, 3, 3, 1)
	var tw := create_tween()
	tw.tween_property(spr, "modulate", Color.WHITE, 0.25)


func kill() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	collision_mask = 0
	harmful = false
	modulate.a = 1.0
	spr.offset = Vector2.ZERO
	spr.self_modulate = Color.WHITE
	queue_redraw()
	var hit_anim: String = cfg.get("hit", "hit")
	if spr.sprite_frames.has_animation(hit_anim):
		spr.play(hit_anim)
	velocity = Vector2(randf_range(-30.0, 30.0), -170.0 if feet else -110.0)
	dead_spin = randf_range(-5.0, 5.0)
	var center := global_position + Vector2(0, -hb.y / 2.0 if feet else 0.0)
	Fx.burst(level, center, Color(1, 1, 1, 1), 10, 90.0, 0.4, 3.0)
	Fx.burst(level, center, Color("ffd23f"), 6, 70.0, 0.5, 3.0)
	level.on_enemy_killed(center, boss_flag)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.5 if not boss_flag else 1.2)
	tw.tween_callback(queue_free)
