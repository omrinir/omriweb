extends CharacterBody2D
# ============================================================
#  השחקן: דמות עם מעיל ארוך שחור וכובע שחור. נוצר ע"י main.gd.
#  נקודת ה-(0,0) של השחקן היא כפות הרגליים.
#  מקשים:  A/D הליכה | SHIFT ריצה | W/רווח קפיצה | S/CTRL כריעה
#          עכבר = כיוון | לחצן שמאלי = ירי / זריקה | T = רובה/רימון | K = מוות
# ============================================================

signal health_changed(health: int, max_health: int)
signal weapon_changed(weapon: int)
signal died

const Art := preload("res://art.gd")
const BulletScript := preload("res://bullet.gd")
const GrenadeScript := preload("res://grenade.gd")

enum { GUN, GRENADE }

# ---- תנועה (אפשר לשנות) ----
var walk_speed := 190.0
var run_speed := 320.0
var crouch_speed := 90.0
var jump_velocity := -620.0      # כמה חזק קופצים (שלילי = למעלה)
var gravity := 1500.0
var accel := 1800.0

# ---- נשק ----
var bullet_speed := 1300.0
var fire_delay := 0.12           # שניות בין יריות
var grenade_speed := 620.0
var grenade_delay := 0.7

# ---- חיים ----
var max_health := 5
var health := 5
var invuln_time := 0.8           # שניות שבהן אי אפשר להיפגע שוב

# ---- צבעים ----
var coat_color := Color("16161b")
var coat_light := Color("34343f")
var hat_color := Color("101013")
var hat_band := Color("4a1016")
var pants_color := Color("2a2a31")
var boot_color := Color("17110d")
var skin_color := Color("e7b48b")
var glove_color := Color("2b1e17")

var world_w := 100000.0          # רוחב העולם (main.gd קובע)
var weapon := GUN
var dead := false

const W := 22.0
const H_STAND := 52.0
const H_CROUCH := 34.0

var _shape: CollisionShape2D
var _crouching := false
var _crouch_k := 0.0             # 0 = עומד, 1 = כורע (לאנימציה חלקה)
var _cooldown := 0.0
var _invuln := 0.0
var _walk_phase := 0.0
var _time := 0.0
var _aim := Vector2.RIGHT
var _muzzle_flash := 0.0
var _recoil := 0.0
var _dead_t := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2   # שכבה 2 = שחקן
	collision_mask = 1    # מתנגש רק בעולם (ריצפה ולבנים)
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_set_height(H_STAND)
	z_index = 4


func _set_height(h: float) -> void:
	(_shape.shape as RectangleShape2D).size = Vector2(W, h)
	_shape.position = Vector2(0.0, -h / 2.0)


func _height() -> float:
	return H_CROUCH if _crouching else H_STAND


# המלבן של הגוף בעולם (משמש לבדיקה אם רגל שנזרקה פגעה בשחקן)
func body_rect() -> Rect2:
	var h := _height()
	return Rect2(global_position + Vector2(-W / 2.0, -h), Vector2(W, h))


func _face() -> float:
	return 1.0 if _aim.x >= 0.0 else -1.0


# הכתף הקדמית (ממנה יוצא הנשק), בקואורדינטות מקומיות
func _front_shoulder() -> Vector2:
	var c := _crouch_k
	return Vector2((3.0 * c + 2.0) * _face(), -40.0 + 17.0 * c)


func _physics_process(delta: float) -> void:
	_time += delta
	_cooldown -= delta
	_invuln -= delta
	_muzzle_flash -= delta
	_recoil = move_toward(_recoil, 0.0, delta * 12.0)

	if not is_on_floor():
		velocity.y += gravity * delta

	if dead:
		_dead_t += delta
		velocity.x = move_toward(velocity.x, 0.0, accel * delta)
		move_and_slide()
		queue_redraw()
		return

	# כריעה
	var want_crouch := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_CTRL)
	if want_crouch and not _crouching:
		_crouching = true
		_set_height(H_CROUCH)
	elif not want_crouch and _crouching and _can_stand():
		_crouching = false
		_set_height(H_STAND)
	_crouch_k = move_toward(_crouch_k, 1.0 if _crouching else 0.0, delta * 8.0)

	# הליכה / ריצה
	var dir := 0.0
	if Input.is_physical_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	var speed := walk_speed
	if _crouching:
		speed = crouch_speed
	elif Input.is_physical_key_pressed(KEY_SHIFT):
		speed = run_speed
	velocity.x = move_toward(velocity.x, dir * speed, accel * delta)

	# קפיצה
	var jump := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SPACE)
	if jump and is_on_floor() and not _crouching:
		velocity.y = jump_velocity

	move_and_slide()
	global_position.x = clampf(global_position.x, W, world_w - W)

	if is_on_floor() and absf(velocity.x) > 10.0:
		_walk_phase += delta * absf(velocity.x) * 0.055
	else:
		_walk_phase = move_toward(_walk_phase, roundf(_walk_phase / PI) * PI, delta * 6.0)

	# כיוון ויריה
	var sh := global_position + _front_shoulder()
	var to_mouse := get_global_mouse_position() - sh
	if to_mouse.length() > 4.0:
		_aim = to_mouse.normalized()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _cooldown <= 0.0:
		_fire()

	queue_redraw()


func _can_stand() -> bool:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(W - 2.0, H_STAND - 2.0)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = rect
	q.transform = Transform2D(0.0, global_position + Vector2(0.0, -H_STAND / 2.0 - 1.0))
	q.collision_mask = 1
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func _fire() -> void:
	var sh := global_position + _front_shoulder()
	if weapon == GUN:
		_cooldown = fire_delay
		_muzzle_flash = 0.05
		_recoil = 1.0
		var b = BulletScript.new()
		get_parent().add_child(b)
		var spread := randf_range(-0.025, 0.025)
		b.setup(sh + _aim * 40.0, _aim.rotated(spread) * bullet_speed, sh)
	else:
		_cooldown = grenade_delay
		var g = GrenadeScript.new()
		get_parent().add_child(g)
		g.setup(sh + _aim * 14.0, _aim * grenade_speed + velocity * 0.3)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_T and not dead:
		weapon = GRENADE if weapon == GUN else GUN
		weapon_changed.emit(weapon)
	elif event.physical_keycode == KEY_K:
		_invuln = 0.0
		hurt(health, Vector2.ZERO)


# נקרא ע"י זומבים, רגליים שנזרקות ורימונים
func hurt(amount: int, knock_dir: Vector2) -> void:
	if dead or _invuln > 0.0:
		return
	_invuln = invuln_time
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	velocity += Vector2(knock_dir.x * 260.0, -180.0)
	if health <= 0:
		dead = true
		died.emit()


# ============================================================
#  ציור הדמות
#  מציירים תמיד כאילו הדמות פונה ימינה, ומשקפים לפי הצורך.
# ============================================================
func _draw() -> void:
	var face := _face()
	if dead:
		var k := clampf(_dead_t / 0.45, 0.0, 1.0)
		k = 1.0 - (1.0 - k) * (1.0 - k)
		var pool := clampf(_dead_t / 3.0, 0.0, 1.0)
		if pool > 0.0:   # שלולית דם
			Art.oval(self, Vector2(-face * 22.0, -1.0), 26.0 * pool, 3.0 * pool, Color("6a0a0a"), 0.0, Art.NONE)
		var outer := Transform2D(-PI / 2.0 * k * face, Vector2(0.0, -9.0 * k))
		draw_set_transform_matrix(outer * Transform2D(0.0, Vector2(face, 1.0), 0.0, Vector2.ZERO))
		_draw_body(Vector2(1.0, 0.25), true)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return

	var la := Vector2(_aim.x * face, _aim.y)   # כיוון הנשק במרחב המקומי (תמיד ימינה)
	if is_on_floor():
		Art.ground_shadow(self, Vector2.ZERO, 15.0)
	var blink := _invuln > 0.0 and int(_invuln * 16.0) % 2 == 0
	modulate = Color(1.0, 0.55, 0.55) if blink else Color.WHITE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(face, 1.0))
	_draw_body(la, false)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_body(la: Vector2, limp: bool) -> void:
	var c := _crouch_k
	var speed_k := clampf(absf(velocity.x) / run_speed, 0.0, 1.0)
	var air := not is_on_floor() and not limp
	var p := _walk_phase
	var breathe := sin(_time * 2.2) * 0.6 * (1.0 - speed_k)

	# שלד: ירכיים, כתפיים, ראש
	var hip := Vector2(0.0, -24.0 + 11.0 * c - absf(cos(p)) * 1.2 * speed_k)
	var sh := Vector2(3.0 * c + speed_k * 2.0, -41.0 + 17.0 * c + breathe * 0.4 - absf(cos(p)) * 1.2 * speed_k)
	var head := sh + Vector2(1.5, -8.5)

	# כפות רגליים
	var stride := 6.0 + 6.0 * speed_k
	var f_front: Vector2
	var f_back: Vector2
	if air:
		f_front = Vector2(6.0, -9.0)
		f_back = Vector2(-5.0, -5.0)
	elif c > 0.5:
		f_front = Vector2(7.0 + sin(p) * 3.0, 0.0)
		f_back = Vector2(-8.0 - sin(p) * 3.0, 0.0)
	else:
		f_front = Vector2(sin(p) * stride + 1.0, -maxf(0.0, cos(p)) * 5.0)
		f_back = Vector2(sin(p + PI) * stride - 1.0, -maxf(0.0, cos(p + PI)) * 5.0)
	if limp:
		f_front = Vector2(2.0, 0.0)
		f_back = Vector2(-2.0, 0.0)

	# ---- יד אחורית (מאחורי הגוף) ----
	var bs := sh + Vector2(-2.0, 1.5)
	var fs := sh + Vector2(2.0, 1.5)
	var kick := la * -2.5 * _recoil
	var hand := fs + la * 15.0 + kick
	var back_hand: Vector2
	if limp:
		hand = fs + Vector2(4.0, 15.0)
		back_hand = bs + Vector2(-3.0, 15.0)
	elif weapon == GUN:
		back_hand = hand + la * 9.0 + la.rotated(PI / 2.0) * 2.0
	else:
		back_hand = bs + Vector2(-3.0 + sin(p) * 3.0, 15.0)
	_arm(bs, back_hand, Art.shade(coat_color, -0.04), true)

	# ---- רגליים ----
	_leg(hip + Vector2(-1.5, 0.0), f_back, Art.shade(pants_color, 0.25), Art.shade(boot_color, 0.2))
	_leg(hip + Vector2(1.5, 0.0), f_front, pants_color, boot_color)

	# ---- מעיל ----
	var flare := speed_k * 5.0 + (3.0 if air else 0.0)
	var hem := minf(hip.y + 15.0 - c * 3.0, -1.0)
	var coat := PackedVector2Array([
		sh + Vector2(-9.0, -1.0), sh + Vector2(-3.0, -3.5), sh + Vector2(6.5, -2.5), sh + Vector2(9.0, 4.0),
		hip + Vector2(8.0, -2.0), Vector2(hip.x + 10.5 - flare * 0.3, hem - 1.0),
		Vector2(hip.x + 1.0, hem + 1.0), Vector2(hip.x - 11.5 - flare * 1.5, hem - 1.5 - flare * 0.6),
		hip + Vector2(-8.5, -2.0), sh + Vector2(-10.0, 5.0),
	])
	Art.fill_shaded(self, coat, coat_color, 0.12, 0.4, Art.OUTLINE, 1.5)
	# קפלים והארה
	draw_colored_polygon(PackedVector2Array([sh + Vector2(4.0, -1.5), sh + Vector2(8.0, 4.0), hip + Vector2(7.0, -2.0), hip + Vector2(4.5, -2.0)]), Color(1, 1, 1, 0.07))
	draw_polyline(PackedVector2Array([sh + Vector2(3.0, 0.0), hip + Vector2(3.5, 0.0), Vector2(hip.x + 4.0, hem)]), coat_light, 1.0, true)
	draw_polyline(PackedVector2Array([hip + Vector2(-4.0, 2.0), Vector2(hip.x - 6.0 - flare, hem - 1.0)]), Color(0, 0, 0, 0.6), 1.0, true)
	draw_polyline(PackedVector2Array([hip + Vector2(0.0, 3.0), Vector2(hip.x - 1.0, hem)]), Color(0, 0, 0, 0.5), 1.0, true)
	# חגורה + אבזם
	draw_line(hip + Vector2(-8.5, -2.5), hip + Vector2(8.0, -2.5), Color("0a0a0c"), 2.6, true)
	Art.fill(self, PackedVector2Array([hip + Vector2(3.0, -4.0), hip + Vector2(6.0, -4.0), hip + Vector2(6.0, -1.0), hip + Vector2(3.0, -1.0)]), Color("8a7448"), Art.OUTLINE, 0.8)
	# כפתורים
	Art.disc(self, sh + Vector2(5.0, 6.0), 0.9, Color("55555f"), Art.NONE)
	Art.disc(self, sh + Vector2(5.5, 11.0), 0.9, Color("55555f"), Art.NONE)
	# צעיף אדום כהה
	Art.fill_shaded(self, PackedVector2Array([sh + Vector2(-4.0, -3.5), sh + Vector2(4.5, -3.0), sh + Vector2(5.0, 0.5), sh + Vector2(-4.0, 0.5)]), Color("5a1218"), 0.2, 0.3, Art.OUTLINE, 1.0)
	var tail := sin(_time * 3.0 + speed_k * 2.0) * 1.5 + speed_k * 4.0
	Art.fill_shaded(self, PackedVector2Array([sh + Vector2(-3.0, -1.0), sh + Vector2(-0.5, -0.5), sh + Vector2(-5.0 - tail, 9.0), sh + Vector2(-8.0 - tail, 8.0)]), Color("4a0e14"), 0.2, 0.3, Art.OUTLINE, 1.0)
	# צווארון מורם
	Art.fill(self, PackedVector2Array([sh + Vector2(-5.0, -2.5), sh + Vector2(-1.0, -8.0), sh + Vector2(1.5, -3.0)]), Art.shade(coat_color, -0.1), Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([sh + Vector2(2.0, -3.0), sh + Vector2(6.5, -6.5), sh + Vector2(6.5, -1.5)]), Art.shade(coat_color, -0.15), Art.OUTLINE, 1.0)

	# ---- ראש ----
	Art.oval(self, head + Vector2(-2.8, -0.5), 5.0, 6.2, Color("2a1c14"))                 # שיער מאחור
	Art.oval_shaded(self, head, 6.6, 7.2, skin_color)                                    # פנים
	Art.oval(self, head + Vector2(-1.5, 2.5), 3.5, 3.0, Color(0.5, 0.25, 0.2, 0.18), 0.0, Art.NONE)   # צל בלחי
	Art.oval(self, head + Vector2(-2.2, 1.2), 1.0, 1.7, Art.shade(skin_color, 0.22), 0.0, Art.NONE)   # אוזן
	Art.fill(self, PackedVector2Array([head + Vector2(5.8, -1.0), head + Vector2(8.3, 2.0), head + Vector2(5.8, 2.6)]), Art.shade(skin_color, 0.05), Art.OUTLINE, 0.9)   # אף
	Art.oval(self, head + Vector2(2.5, 4.0), 4.5, 2.6, Color(0.25, 0.18, 0.14, 0.35), 0.0, Art.NONE)   # זיפים
	draw_line(head + Vector2(3.0, 4.6), head + Vector2(5.6, 4.3), Color("7a3b30"), 1.0, true)        # פה
	Art.oval(self, head + Vector2(3.6, -0.3), 1.0, 1.4, Color("1a1414"), 0.0, Art.NONE)             # עין
	draw_line(head + Vector2(2.0, -2.6), head + Vector2(5.4, -2.0), Color("2a1c14"), 1.2, true)     # גבה
	Art.oval(self, head + Vector2(2.0, -2.8), 6.5, 1.8, Color(0, 0, 0, 0.3), 0.0, Art.NONE)         # צל של הכובע

	# ---- כובע ----
	var hb := head + Vector2(0.5, -5.2)
	Art.oval(self, hb, 12.5, 2.3, hat_color, 0.0, Art.OUTLINE, 1.3)
	var crown := PackedVector2Array([
		hb + Vector2(-7.0, 0.0), hb + Vector2(-6.6, -7.0), hb + Vector2(-3.0, -9.6), hb + Vector2(0.0, -8.4),
		hb + Vector2(3.0, -9.6), hb + Vector2(6.6, -7.0), hb + Vector2(7.0, 0.0),
	])
	Art.fill_shaded(self, crown, Art.shade(hat_color, -0.06), 0.12, 0.3, Art.OUTLINE, 1.3)
	Art.fill(self, PackedVector2Array([hb + Vector2(-7.0, -1.0), hb + Vector2(7.0, -1.0), hb + Vector2(6.9, -3.2), hb + Vector2(-6.9, -3.2)]), hat_band, Art.NONE)
	draw_polyline(PackedVector2Array([hb + Vector2(-5.6, -3.6), hb + Vector2(-5.4, -7.0), hb + Vector2(-2.8, -8.8)]), Color(1, 1, 1, 0.16), 1.0, true)
	draw_line(hb + Vector2(-11.0, -0.8), hb + Vector2(10.0, -0.8), Color(1, 1, 1, 0.1), 0.8, true)

	# ---- נשק + יד קדמית ----
	if limp:
		_arm(fs, hand, coat_color, false)
		return
	if weapon == GUN:
		_draw_rifle(hand, la)
	else:
		var g := hand + la * 3.0
		Art.disc(self, g, 4.3, Color("4a5a2c"))
		draw_line(g + Vector2(-1.5, -4.0), g + Vector2(2.5, -5.0), Color("9a9a9a"), 1.4, true)
	_arm(fs, hand, coat_color, false)


func _arm(shoulder: Vector2, hand: Vector2, sleeve: Color, back: bool) -> void:
	var elbow := Art.joint(shoulder, hand, 8.5, 8.5, -1.0)
	Art.limb(self, PackedVector2Array([shoulder, elbow, hand]), 5.6, sleeve)
	if not back:
		draw_line(shoulder + Vector2(0.0, 1.0), elbow, Color(1, 1, 1, 0.06), 1.5, true)
	Art.disc(self, hand, 2.6, glove_color)


func _leg(hip: Vector2, foot: Vector2, pants: Color, boot: Color) -> void:
	var ankle := foot + Vector2(0.0, -3.5)
	var knee := Art.joint(hip, ankle, 11.5, 11.0, 1.0)
	Art.limb(self, PackedVector2Array([hip, knee, ankle]), 6.4, pants)
	Art.fill(self, PackedVector2Array([
		foot + Vector2(-3.5, -5.0), foot + Vector2(2.5, -5.0), foot + Vector2(4.0, -2.8),
		foot + Vector2(7.5, -1.8), foot + Vector2(7.5, 0.0), foot + Vector2(-3.8, 0.0),
	]), boot, Art.OUTLINE, 1.1)


func _draw_rifle(hand: Vector2, la: Vector2) -> void:
	var n := la.rotated(PI / 2.0)
	var g := func(x: float, y: float) -> Vector2: return hand + la * x + n * y
	var metal := Color("1d1d23")
	var wood := Color("4b2d1c")
	Art.fill(self, PackedVector2Array([g.call(-11.0, -0.5), g.call(-2.0, -1.6), g.call(-1.0, 2.2), g.call(-11.0, 4.2)]), wood, Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([
		g.call(-2.0, -1.6), g.call(14.0, -1.6), g.call(14.0, 1.6), g.call(4.0, 1.6),
		g.call(2.6, 6.4), g.call(-0.6, 6.4), g.call(-1.0, 2.2),
	]), metal, Art.OUTLINE, 1.0)
	Art.fill(self, PackedVector2Array([g.call(5.0, 1.6), g.call(13.0, 1.6), g.call(12.0, 3.6), g.call(6.0, 3.6)]), wood, Art.OUTLINE, 0.9)   # ידית קדמית
	Art.limb(self, PackedVector2Array([g.call(14.0, -0.4), g.call(25.0, -0.4)]), 2.0, Color("2c2c34"), Art.OUTLINE)   # קנה
	Art.fill(self, PackedVector2Array([g.call(1.0, -1.6), g.call(9.0, -1.6), g.call(9.0, -3.8), g.call(1.0, -3.8)]), Color("101014"), Art.OUTLINE, 0.9)   # כוונת
	draw_line(g.call(-1.0, -1.0), g.call(13.0, -1.0), Color(1, 1, 1, 0.12), 0.8, true)
	if _muzzle_flash > 0.0:
		var m: Vector2 = g.call(28.0, -0.4)
		Art.glow(self, m, 9.0, Color(1.0, 0.75, 0.3, 0.9))
		Art.fill(self, PackedVector2Array([m + la * -2.0 + n * -2.5, m + la * 8.0, m + la * -2.0 + n * 2.5]), Color(1.0, 0.95, 0.7), Art.NONE)
