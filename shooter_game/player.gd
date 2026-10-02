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
var fire_delay := 1.0            # שניות בין יריות (1 = כדור אחד בשנייה)
var grenade_speed := 620.0
var grenade_delay := 0.7
var recoil_push := 70.0          # כמה כל ירייה דוחפת אחורה על הריצפה
var air_recoil_push := 120.0     # כמה כל ירייה דוחפת באוויר (גם למעלה אם יורים למטה)
var air_control := 0.35          # שליטה בתנועה באוויר (קטן = הרתיעה מורגשת יותר)

# ---- חיים ----
var max_health := 5
var health := 5
var invuln_time := 0.8           # שניות שבהן אי אפשר להיפגע שוב

# ---- צבעים (סגנון מנגה: שחור עם קצוות לבנים) ----
var coat_color := Color("0d0d11")
var coat_lining := Color("44444e")
var rim_color := Color("e8e8f0")      # קווי האור הלבנים על המעיל
var pants_color := Color("111115")
var boot_color := Color("08080a")
var glove_color := Color("141418")
## כמה הדמות רזה (1 = רגיל, קטן יותר = רזה יותר)
@export_range(0.5, 1.0) var slim := 0.8
## עיניים זוהרות בתוך הברדס (false = רק חושך, כמו בתמונה)
@export var glowing_eyes := false
var eye_color := Color("ff3030")

var world_w := 100000.0          # רוחב העולם (main.gd קובע)
var weapon := GUN
var dead := false

const W := 22.0
const BREATH_SPEED := 1.6        # מהירות הנשימה
const H_STAND := 52.0
const H_CROUCH := 34.0

var _shape: CollisionShape2D
var _crouching := false
var _crouch_k := 0.0             # 0 = עומד, 1 = כורע (לאנימציה חלקה)
var _cooldown := 0.0
var _invuln := 0.0
var _walk_phase := 0.0
var _time := 0.0
var _idle_k := 0.0               # 0 = זז, 1 = עומד במקום (לאנימציית נשימה)
var _breath_was_up := false
var _mist := []                  # אדי נשימה: [מיקום, מהירות, גיל]
var _base_xf := Transform2D.IDENTITY
var _aim := Vector2.RIGHT
var _muzzle_flash := 0.0
var _recoil := 0.0
var _dead_t := 0.0
var _push_t := 0.0
var _fire_test := false   # לבדיקות אוטומטיות בלבד


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
	_push_t -= delta

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
	var acc := accel if is_on_floor() else accel * air_control
	if _push_t > 0.0:   # רגע אחרי ירייה - הדחיפה גוברת על ההליכה
		acc *= 0.25
	velocity.x = move_toward(velocity.x, dir * speed, acc * delta)

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

	# עמידה במקום: נשימה + אדים יוצאים מהברדס בכל נשיפה
	var standing := is_on_floor() and absf(velocity.x) < 10.0 and not _crouching
	_idle_k = move_toward(_idle_k, 1.0 if standing else 0.0, delta * 3.0)
	var up := cos(_time * BREATH_SPEED) > 0.0
	if _breath_was_up and not up and _idle_k > 0.6:
		for i in 4:
			_mist.append([Vector2(8.5, -47.0 + randf_range(-1.0, 1.0)), Vector2(randf_range(7.0, 14.0), randf_range(-7.0, -2.0)), -float(i) * 0.08])
	_breath_was_up = up
	for m in _mist:
		m[2] += delta
		if m[2] > 0.0:
			m[0] += m[1] * delta
	_mist = _mist.filter(func(m): return m[2] < 1.6)

	# כיוון ויריה
	var sh := global_position + _front_shoulder()
	var to_mouse := get_global_mouse_position() - sh
	if to_mouse.length() > 4.0 and not _fire_test:
		_aim = to_mouse.normalized()
	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _fire_test) and _cooldown <= 0.0:
		_fire()
	_fire_test = false

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
		# רתיעה: הירייה דוחפת את הדמות הפוך לכיוון הקנה
		if is_on_floor():
			velocity.x -= _aim.x * recoil_push
		else:
			velocity -= _aim * air_recoil_push
			velocity.y = maxf(velocity.y, -700.0)
		_push_t = 0.12
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
		_base_xf = outer * Transform2D(0.0, Vector2(face, 1.0), 0.0, Vector2.ZERO)
		draw_set_transform_matrix(_base_xf)
		_draw_body(Vector2(1.0, 0.25), true)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return

	var la := Vector2(_aim.x * face, _aim.y)   # כיוון הנשק במרחב המקומי (תמיד ימינה)
	if is_on_floor():
		Art.ground_shadow(self, Vector2.ZERO, 15.0)
	var blink := _invuln > 0.0 and int(_invuln * 16.0) % 2 == 0
	modulate = Color(1.0, 0.55, 0.55) if blink else Color.WHITE
	_base_xf = Transform2D(0.0, Vector2(face, 1.0), 0.0, Vector2.ZERO)
	draw_set_transform_matrix(_base_xf)
	_draw_body(la, false)
	# אדי נשימה
	for m in _mist:
		var age: float = m[2]
		if age <= 0.0:
			continue
		var a := 0.32 * clampf(age / 0.2, 0.0, 1.0) * (1.0 - age / 1.6)
		draw_circle(m[0], 1.2 + age * 4.0, Color(0.85, 0.88, 0.95, a))
	draw_set_transform_matrix(Transform2D.IDENTITY)


# הגוף מצויר צר יותר (רזה), הידיים והנשק ברוחב רגיל
func _slim(on: bool) -> void:
	draw_set_transform_matrix(_base_xf * Transform2D(0.0, Vector2(slim, 1.0), 0.0, Vector2.ZERO) if on else _base_xf)


func _draw_body(la: Vector2, limp: bool) -> void:
	var c := _crouch_k
	var speed_k := clampf(absf(velocity.x) / run_speed, 0.0, 1.0)
	var air := not is_on_floor() and not limp
	var p := _walk_phase
	# נשימה: החזה עולה ויורד, הראש נוטה קצת אחורה בשאיפה, והמשקל עובר מרגל לרגל
	var idle := 0.0 if limp else _idle_k
	var br := sin(_time * BREATH_SPEED) * idle
	var sway := sin(_time * 0.55) * idle
	var breathe := sin(_time * 2.2) * 0.6 * (1.0 - speed_k) * (1.0 - idle)

	# שלד: ירכיים, כתפיים, ראש
	var hip := Vector2(sway * 0.9, -24.0 + 11.0 * c - absf(cos(p)) * 1.2 * speed_k)
	var sh := Vector2(3.0 * c + speed_k * 2.0 + sway * 0.5, -41.0 + 17.0 * c + breathe * 0.4 - absf(cos(p)) * 1.2 * speed_k - br * 2.0)
	var head := sh + Vector2(1.5 + br * 0.6, -8.5 - br * 0.6)

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
	else:   # בעמידה: רגליים קצת פתוחות
		f_front.x += 3.0 * idle
		f_back.x -= 3.0 * idle

	# כמה המעיל מתנופף (ריצה / אוויר / רתיעה) + רפרוף של הרוח
	var flow := clampf(speed_k * 0.8 + (0.5 if air else 0.0) + _recoil * 0.25 + 0.15, 0.0, 1.0)
	if limp:
		flow = 0.0
	var wv := sin(_time * 7.0) * (0.6 + flow * 1.6)

	# ---- יד אחורית ----
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
	_arm(bs, back_hand, true)
	_slim(true)

	# ---- זנב אחורי של המעיל (מתנופף מאחור) ----
	var bottom := -1.0
	var tail := PackedVector2Array([
		hip + Vector2(-2.0, -2.0),
		Vector2(hip.x - 3.0 - flow * 2.0, minf(-6.0 + wv, bottom)),
		Vector2(hip.x - 6.0 - flow * 7.0, minf(-1.0 + wv * 1.5, bottom)),
		Vector2(hip.x - 9.0 - flow * 10.0, minf(-6.0 - flow * 3.0 + wv, bottom)),
		Vector2(hip.x - 13.0 - flow * 16.0, minf(-3.0 - flow * 9.0 + wv * 2.0, bottom)),
		Vector2(hip.x - 12.0 - flow * 10.0, hip.y + 2.0 - flow * 4.0),
		hip + Vector2(-9.0, -3.0),
	])
	Art.fill(self, tail, coat_color, Art.OUTLINE, 1.4)
	# בטנה אפורה + קפלים
	Art.fill_shaded(self, PackedVector2Array([tail[0], tail[1], tail[2], Vector2(hip.x - 5.0 - flow * 4.0, hip.y + 6.0)]), coat_lining, 0.1, 0.4, Art.NONE)
	draw_line(Vector2(hip.x - 5.0 - flow * 5.0, hip.y + 8.0), Vector2(hip.x - 8.0 - flow * 9.0, -6.0 - flow * 2.0 + wv), Color(1, 1, 1, 0.12), 1.0, true)
	draw_line(Vector2(hip.x - 8.0 - flow * 6.0, hip.y + 4.0), Vector2(hip.x - 12.0 - flow * 13.0, -6.0 - flow * 7.0 + wv * 1.5), Color(1, 1, 1, 0.1), 1.0, true)
	draw_polyline(PackedVector2Array([tail[0], tail[1], tail[2]]), rim_color, 1.0, true)

	# ---- רגליים ----
	_leg(hip + Vector2(-1.5, 0.0), f_back, true)
	_leg(hip + Vector2(1.5, 0.0), f_front, false)

	# ---- גוף המעיל ----
	var torso := PackedVector2Array([
		sh + Vector2(-9.0, -1.0), sh + Vector2(7.0, -2.0), sh + Vector2(9.0 + br * 0.8, 4.0),
		hip + Vector2(8.5, -1.0), hip + Vector2(-8.5, -1.0), sh + Vector2(-10.0, 5.0),
	])
	Art.fill_shaded(self, torso, coat_color, 0.1, 0.3, Art.OUTLINE, 1.5)
	# הארה לבנה בצד הקדמי (כמו במנגה)
	draw_polyline(PackedVector2Array([sh + Vector2(7.5, -1.0), sh + Vector2(9.0, 4.0), hip + Vector2(8.0, -1.5)]), rim_color, 1.1, true)
	draw_polyline(PackedVector2Array([sh + Vector2(2.0, 0.0), hip + Vector2(3.0, -2.0)]), coat_lining, 1.0, true)   # פתח המעיל
	draw_polyline(PackedVector2Array([sh + Vector2(-5.0, 4.0), sh + Vector2(-3.0, 9.0), sh + Vector2(-5.0, 12.0)]), Color(1, 1, 1, 0.1), 1.0, true)
	draw_line(hip + Vector2(-8.5, -2.5), hip + Vector2(8.5, -2.5), Color("050507"), 2.4, true)   # חגורה

	# ---- הפאנל הקדמי של המעיל (עם חריץ שרואים דרכו את הרגליים) ----
	var front := PackedVector2Array([
		hip + Vector2(1.0, -2.0), hip + Vector2(8.5, -2.0),
		Vector2(hip.x + 10.5 - flow * 2.0, minf(-6.0 + wv * 0.5, bottom)),
		Vector2(hip.x + 6.0 - flow * 2.0, minf(-2.5 + wv * 0.4, bottom)),
		Vector2(hip.x + 3.0 - flow * 3.0, minf(-8.0 + wv * 0.3, bottom)),
		hip + Vector2(0.0, 6.0),
	])
	Art.fill_shaded(self, front, coat_color, 0.08, 0.3, Art.OUTLINE, 1.3)
	draw_polyline(PackedVector2Array([front[1], front[2]]), rim_color, 1.0, true)
	draw_line(hip + Vector2(4.0, 2.0), Vector2(hip.x + 6.0 - flow * 2.0, -6.0), Color(1, 1, 1, 0.1), 0.9, true)

	# ---- צווארון גבוה (אחורי) ----
	Art.fill(self, PackedVector2Array([sh + Vector2(-7.0, 1.0), sh + Vector2(-10.0, -10.0), sh + Vector2(-2.0, -3.0)]), coat_color, Art.OUTLINE, 1.2)
	draw_line(sh + Vector2(-9.5, -9.0), sh + Vector2(-3.0, -3.5), Color(1, 1, 1, 0.25), 0.9, true)

	# ---- ברדס: הפנים חבויות בחושך ----
	var hood := PackedVector2Array([
		sh + Vector2(-7.0, -1.0), head + Vector2(-8.0, 2.0), head + Vector2(-7.5, -5.0),
		head + Vector2(-3.0, -10.5), head + Vector2(-0.5, -12.0), head + Vector2(3.5, -9.5),
		head + Vector2(7.0, -4.0), head + Vector2(7.8, 3.0), sh + Vector2(6.0, -1.0),
	])
	Art.fill_shaded(self, hood, coat_color, 0.14, 0.25, Art.OUTLINE, 1.5)
	var face := PackedVector2Array([
		head + Vector2(0.5, -6.5), head + Vector2(4.5, -6.0), head + Vector2(6.8, -2.5),
		head + Vector2(6.6, 3.5), head + Vector2(3.0, 5.5), head + Vector2(0.0, 2.0),
	])
	Art.fill(self, face, Color("000000"), Art.NONE)
	# קצה לבן של הברדס
	draw_polyline(PackedVector2Array([head + Vector2(-0.5, -12.0), head + Vector2(3.5, -9.5), head + Vector2(7.0, -4.0), head + Vector2(7.8, 3.0)]), rim_color, 1.2, true)
	draw_polyline(PackedVector2Array([head + Vector2(0.5, -6.5), head + Vector2(0.0, 2.0), head + Vector2(3.0, 5.5)]), Color(1, 1, 1, 0.35), 0.8, true)
	draw_line(head + Vector2(-3.0, -9.5), head + Vector2(-6.5, -3.0), Color(1, 1, 1, 0.12), 1.0, true)
	if glowing_eyes:
		Art.glow(self, head + Vector2(5.0, -1.5), 2.6, Color(eye_color, 0.8))
		draw_line(head + Vector2(3.8, -1.6), head + Vector2(5.8, -1.3), eye_color, 1.0, true)

	# ---- צווארון גבוה (קדמי) ----
	Art.fill(self, PackedVector2Array([sh + Vector2(3.0, -1.0), sh + Vector2(10.0, -9.5), sh + Vector2(8.0, 2.0)]), coat_color, Art.OUTLINE, 1.2)
	draw_polyline(PackedVector2Array([sh + Vector2(3.5, -1.5), sh + Vector2(10.0, -9.5), sh + Vector2(8.0, 2.0)]), rim_color, 1.0, true)

	# ---- נשק + יד קדמית ----
	_slim(false)
	if limp:
		_arm(fs, hand, false)
		return
	if weapon == GUN:
		_draw_rifle(hand, la)
	else:
		var g := hand + la * 3.0
		Art.disc(self, g, 4.3, Color("4a5a2c"))
		draw_line(g + Vector2(-1.5, -4.0), g + Vector2(2.5, -5.0), Color("9a9a9a"), 1.4, true)
	_arm(fs, hand, false)


func _arm(shoulder: Vector2, hand: Vector2, back: bool) -> void:
	var elbow := Art.joint(shoulder, hand, 8.5, 8.5, -1.0)
	var col := Art.shade(coat_color, -0.05) if back else coat_color
	Art.limb(self, PackedVector2Array([shoulder, elbow, hand]), 4.6, col)
	if not back:   # הארה לבנה על השרוול
		draw_polyline(PackedVector2Array([shoulder + Vector2(0.0, -2.6), elbow + (elbow - shoulder).orthogonal().normalized() * 2.6]), Color(rim_color, 0.7), 0.9, true)
	# שרוול רחב ליד כף היד
	var d := (hand - elbow).normalized()
	var n := d.orthogonal()
	Art.fill(self, PackedVector2Array([hand - d * 4.5 + n * 3.6, hand - d * 1.0 + n * 3.2, hand - d * 1.0 - n * 3.2, hand - d * 4.5 - n * 3.6]), col, Art.OUTLINE, 1.0)
	Art.disc(self, hand, 2.5, glove_color)


func _leg(hip: Vector2, foot: Vector2, back: bool) -> void:
	var ankle := foot + Vector2(0.0, -3.5)
	var knee := Art.joint(hip, ankle, 11.5, 11.0, 1.0)
	var pants := Art.shade(pants_color, 0.25) if back else pants_color
	var boot := Art.shade(boot_color, 0.2) if back else boot_color
	Art.limb(self, PackedVector2Array([hip, knee, ankle]), 6.2, pants)
	# מגף גבוה עם שוליים משוננים
	var top := knee.lerp(ankle, 0.25)
	var d := (ankle - top).normalized()
	var n := d.orthogonal()
	Art.fill(self, PackedVector2Array([
		top + n * 4.2 - d * 1.5, top + n * 2.0 + d * 1.5, top - d * 0.5, top - n * 2.0 + d * 1.5, top - n * 4.2 - d * 1.5,
		ankle - n * 3.6, foot + Vector2(-3.8, 0.0), foot + Vector2(7.5, 0.0), foot + Vector2(7.5, -2.0),
		foot + Vector2(3.0, -4.0), ankle + n * 3.4,
	]), boot, Art.OUTLINE, 1.1)
	if not back:
		draw_polyline(PackedVector2Array([top + n * 4.0 - d * 1.2, ankle + n * 3.2, foot + Vector2(3.0, -4.0), foot + Vector2(7.5, -2.0)]), Color(rim_color, 0.6), 0.9, true)


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
