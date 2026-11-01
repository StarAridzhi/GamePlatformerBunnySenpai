class_name Player
extends CharacterBody2D
## The bunny hero: tight platformer controls (coyote time, jump buffer, variable jump, double jump).

const SPEED := 140.0
const ACCEL := 1300.0
const FRICTION := 1500.0
const AIR_ACCEL := 900.0
const AIR_FRICTION := 320.0
const GRAVITY := 1000.0
const FALL_GRAVITY := 1350.0
const MAX_FALL := 430.0
const JUMP_V := -385.0
const DJUMP_V := -335.0
const COYOTE := 0.1
const BUFFER := 0.12
const MAX_HP := 3
const ART_FACES_LEFT := true

var level
var hp := MAX_HP
var coyote := 0.0
var buffer := 0.0
var air_jumps := 1
var invuln := 0.0
var hurt_lock := 0.0
var dead := false
var frozen := false
var facing := 1
var drop_timer := 0.0
var was_on_floor := true
var on_oneway := false
var dust_t := 0.0
var shake_t := 0.0
var shake_amp := 0.0
var cheer_t := 0.0
var squash := Vector2.ONE
var spr: AnimatedSprite2D
var pivot: Node2D
var cam: Camera2D
var bot_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = Game.L_PLAYER
	collision_mask = Game.L_TERRAIN | Game.L_ONEWAY
	floor_snap_length = 5.0
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_VELOCITY
	z_index = 10

	var sh := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(14, 28)
	sh.shape = rs
	sh.position = Vector2(0, -14)
	add_child(sh)

	pivot = Node2D.new()
	add_child(pivot)
	spr = AnimatedSprite2D.new()
	spr.sprite_frames = Game.get_frames("bunny")
	spr.position = Vector2(0, -22)
	pivot.add_child(spr)
	spr.play("idle")

	cam = Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = level.W * 16
	cam.limit_bottom = level.H * 16
	add_child(cam)
	cam.make_current()


func hurtbox() -> Rect2:
	return Rect2(global_position + Vector2(-6, -26), Vector2(12, 25))


func shake(amp: float, dur: float) -> void:
	shake_amp = amp
	shake_t = dur


# ------------------------------------------------------------ input (or bot)
func _bot_input(delta: float) -> Dictionary:
	var d := {"dir": 1.0, "jp": false, "jh": false, "down": false}
	var p := global_position
	var wall: bool = level.solid_at(p + Vector2(14, -6)) or level.solid_at(p + Vector2(14, -22))
	var ledge: bool = not level.ground_at(p + Vector2(14, 4)) and not level.ground_at(p + Vector2(26, 4))
	var enemy_ahead := false
	for e in get_tree().get_nodes_in_group("enemy"):
		var dx: float = e.global_position.x - p.x
		if dx > 4.0 and dx < 56.0 and absf(e.global_position.y - p.y) < 30.0:
			enemy_ahead = true
	if is_on_floor():
		if wall or ledge or enemy_ahead:
			d["jp"] = true
	elif air_jumps > 0 and velocity.y > -20.0:
		var no_floor: bool = not level.ground_at(p + Vector2(8, 40)) and not level.ground_at(p + Vector2(8, 80))
		if wall or no_floor:
			d["jp"] = true
	d["jh"] = velocity.y < 0.0 or d["jp"]
	return d


# ------------------------------------------------------------ main loop
func _physics_process(delta: float) -> void:
	if dead:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		pivot.rotation += 7.0 * delta * facing
		return

	var dir := 0.0
	var jump_pressed := false
	var jump_held := false
	var down := false
	if not frozen:
		if Game.bot:
			var b := _bot_input(delta)
			dir = b["dir"]
			jump_pressed = b["jp"]
			jump_held = b["jh"]
			down = b["down"]
		else:
			dir = Input.get_axis("left", "right")
			jump_pressed = Input.is_action_just_pressed("jump")
			jump_held = Input.is_action_pressed("jump")
			down = Input.is_action_pressed("down")

	hurt_lock -= delta
	invuln -= delta
	var on_floor := is_on_floor()

	if not on_floor:
		var g := FALL_GRAVITY if velocity.y > 0.0 else GRAVITY
		if velocity.y < 0.0 and not jump_held:
			g *= 2.2
		velocity.y = minf(velocity.y + g * delta, MAX_FALL)
		coyote -= delta
	else:
		coyote = COYOTE
		air_jumps = 1

	buffer -= delta
	if jump_pressed:
		buffer = BUFFER

	if buffer > 0.0 and hurt_lock <= 0.0 and not frozen:
		if on_floor and down and on_oneway:
			drop_timer = 0.25
			collision_mask = Game.L_TERRAIN
			position.y += 1.0
			buffer = 0.0
		elif coyote > 0.0:
			_jump(false)
		elif air_jumps > 0:
			_jump(true)

	if drop_timer > 0.0:
		drop_timer -= delta
		if drop_timer <= 0.0:
			collision_mask = Game.L_TERRAIN | Game.L_ONEWAY

	if hurt_lock <= 0.0:
		var acc := ACCEL if on_floor else AIR_ACCEL
		var fr := FRICTION if on_floor else AIR_FRICTION
		if dir != 0.0:
			if signf(dir) != signf(velocity.x) and velocity.x != 0.0:
				acc *= 1.8
			velocity.x = move_toward(velocity.x, dir * SPEED, acc * delta)
			facing = 1 if dir > 0.0 else -1
		else:
			velocity.x = move_toward(velocity.x, 0.0, fr * delta)

	if frozen and on_floor:
		cheer_t -= delta
		if cheer_t <= 0.0:
			velocity.y = -230.0
			cheer_t = 0.75
			squash = Vector2(0.8, 1.2)

	move_and_slide()

	on_oneway = false
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y < -0.7:
			var col = c.get_collider()
			if col is CollisionObject2D and (col.collision_layer & Game.L_ONEWAY) != 0:
				on_oneway = true

	var now_floor := is_on_floor()
	if now_floor and not was_on_floor:
		_on_land()
	was_on_floor = now_floor

	# running dust
	if now_floor and absf(velocity.x) > 90.0 and hurt_lock <= 0.0:
		dust_t -= delta
		if dust_t <= 0.0:
			dust_t = 0.13
			Fx.puff(level, global_position + Vector2(-facing * 6, -1), 1, 8.0)

	if global_position.y > level.H * 16 + 40:
		die(false)

	_update_visuals(delta, now_floor)


func _jump(air: bool) -> void:
	buffer = 0.0
	coyote = 0.0
	if air:
		air_jumps -= 1
		velocity.y = DJUMP_V
		Game.play("djump", -2.0)
		Fx.burst(level, global_position + Vector2(0, -4), Color(1, 1, 1, 0.9), 8, 60.0, 0.3, 3.0, 0.0)
	else:
		velocity.y = JUMP_V
		Game.play("jump", -2.0)
		Fx.puff(level, global_position + Vector2(0, -1), 3, 16.0)
	squash = Vector2(0.72, 1.3)


func _on_land() -> void:
	squash = Vector2(1.3, 0.75)
	Fx.puff(level, global_position + Vector2(0, -1), 4, 22.0)
	Game.play("land", -10.0)


func _update_visuals(delta: float, on_floor: bool) -> void:
	squash = squash.lerp(Vector2.ONE, minf(1.0, 14.0 * delta))
	pivot.scale = squash
	spr.flip_h = (facing > 0) if ART_FACES_LEFT else (facing < 0)
	var anim := "idle"
	if hurt_lock > 0.0:
		anim = "hit"
	elif not on_floor:
		anim = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 12.0:
		anim = "run"
	if spr.animation != anim:
		spr.play(anim)
	if anim == "run":
		spr.speed_scale = clampf(absf(velocity.x) / SPEED, 0.6, 1.2)
	else:
		spr.speed_scale = 1.0
	spr.modulate.a = 0.35 if (invuln > 0.0 and int(invuln * 16.0) % 2 == 0) else 1.0
	# camera feel: look-ahead + shake
	var target_off := Vector2(facing * 26.0, clampf(velocity.y * 0.12, -8.0, 30.0))
	var off := cam.offset.lerp(target_off, minf(1.0, 3.0 * delta))
	if shake_t > 0.0:
		shake_t -= delta
		off += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_amp
	cam.offset = off


# ------------------------------------------------------------ interactions
func bounce() -> void:
	velocity.y = -420.0 if Input.is_action_pressed("jump") else -330.0
	air_jumps = 1
	coyote = 0.0
	squash = Vector2(0.8, 1.25)


func launch(vy: float) -> void:
	velocity.y = vy
	air_jumps = 1
	coyote = 0.0
	squash = Vector2(0.7, 1.35)


func hurt(from_x: float) -> void:
	if dead or invuln > 0.0 or Game.god or frozen:
		return
	hp -= 1
	level.on_hp_changed(hp)
	if hp <= 0:
		die(true)
		return
	invuln = 1.5
	hurt_lock = 0.35
	var kd := signf(global_position.x - from_x)
	if kd == 0.0:
		kd = -facing
	velocity = Vector2(kd * 150.0, -230.0)
	Game.play("hurt")
	shake(3.0, 0.25)
	Fx.burst(level, global_position + Vector2(0, -14), Color(1, 0.45, 0.5), 8, 100.0)


func die(with_anim := true) -> void:
	if dead:
		return
	dead = true
	hp = 0
	level.on_hp_changed(0)
	Game.play("die")
	collision_mask = 0
	if with_anim:
		spr.play("hit")
		spr.modulate.a = 1.0
		velocity = Vector2(0, -280)
		shake(4.0, 0.3)
	else:
		velocity = Vector2.ZERO
		spr.visible = false
	level.on_player_died()


func respawn(pos: Vector2) -> void:
	dead = false
	frozen = false
	hp = MAX_HP
	level.on_hp_changed(hp)
	global_position = pos
	velocity = Vector2.ZERO
	invuln = 1.6
	hurt_lock = 0.0
	pivot.rotation = 0.0
	spr.visible = true
	spr.modulate.a = 1.0
	collision_mask = Game.L_TERRAIN | Game.L_ONEWAY
	air_jumps = 1
	cam.reset_smoothing()
	was_on_floor = false


func cheer() -> void:
	frozen = true
	velocity.x = 0.0
	cheer_t = 0.1
