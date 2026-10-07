extends CharacterBody2D
const SIZE := 0.85   # גודל הניצולה (בגובה הדמות הראשית)
# ============================================================
#  ניצולה (אישה, לא זומבי). כשהשחקן מתקרב היא רצה אליו ומבקשת עזרה.
#  * קליע אחד הורג אותה.
#  * כשהיא ממש קרובה לשחקן - לחיצה על ירייה מפעילה את המכשיר:
#    כוח החיים שלה נשאב לשחקן (חיים מלאים), והיא נשארת שרופה וחסרת חיים.
#  נקודת ה-(0,0) = כפות הרגליים.
# ============================================================

const Art := preload("res://art.gd")
const BloodScript := preload("res://blood_drop.gd")
const ZombieScript := preload("res://zombie.gd")
const PickupScript := preload("res://pickup.gd")

enum { IDLE, RUN, WAIT, DRAINED, DEAD, LEAVE }

## מראה: 0 = שיער חום, 1 = בלונדינית, 2 = שיער שחור
@export_range(0, 2) var variant := 0

const VARIANTS := [
	{"hair": Color("4a2a1a"), "top": Color("8a2f3c"), "pants": Color("34405a"), "skin": Color("e6b48e"), "boots": Color("2a1d16")},
	{"hair": Color("d0a24e"), "top": Color("2f5e50"), "pants": Color("2c2c33"), "skin": Color("f0c6a0"), "boots": Color("3a2a20")},
	{"hair": Color("161112"), "top": Color("5a4a80"), "pants": Color("4a3a2a"), "skin": Color("a8744e"), "boots": Color("1c1614")},
]

var run_speed := 170.0
var notice_range := 620.0        # מאיזה מרחק היא רואה את השחקן ורצה אליו
var stop_dist := 46.0            # כמה קרוב היא נעצרת
var drain_range := 72.0          # מאיזה מרחק אפשר להפעיל את המכשיר
var gravity := 1500.0
var jump_velocity := -560.0
var world_w := 100000.0
var mercy_time := 5.0            # אם לא שואבים ממנה תוך 5 שניות - היא נותנת אספקה ובורחת
var _wait_t := 0.0
var _leave_t := 0.0

var state := IDLE
var scripted := false            # סצנת סיפור (story/): עומדת במקום, לא רצה לשחקן ולא בורחת
var _c: Dictionary
var _dir := -1.0
var _t := 0.0
var _phase := 0.0
var _drain_k := 0.0              # 0..1 כמה כוח חיים נשאב
var _burn_t := -1.0              # זמן מאז שנשרפה
var _dead_t := 0.0
var _angle := 0.0
var _player: Node = null
var _shape: CollisionShape2D
var _tick := 0


func _ready() -> void:
	add_to_group("survivors")
	_c = VARIANTS[clampi(variant, 0, 2)]
	collision_layer = 4   # הקליעים פוגעים בה
	collision_mask = 1
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(15, 44)
	_shape.shape = r
	_shape.position = Vector2(0, -22)
	add_child(_shape)
	_t = randf() * 5.0
	z_index = 3


func _physics_process(delta: float) -> void:
	_t += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if not is_on_floor():
		velocity.y += gravity * delta
	match state:
		IDLE:
			velocity.x = 0.0
			if not scripted and _player != null and not _player.dead and absf(_player.global_position.x - global_position.x) < notice_range \
					and absf(_player.global_position.y - global_position.y) < 200.0:
				state = RUN
				_say("HELP!")
				Game.story.emit("survivor_seen", {"s": self})
		RUN, WAIT:
			if _player == null or _player.dead:
				velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			else:
				var dx: float = _player.global_position.x - global_position.x
				_dir = signf(dx) if dx != 0.0 else _dir
				if absf(dx) <= stop_dist:
					state = WAIT
				elif absf(dx) > stop_dist + 25.0:
					state = RUN
				if state == WAIT:
					_wait_t += delta
					if _wait_t >= mercy_time:
						_leave()
						return
				var target := run_speed * _dir if state == RUN else 0.0
				velocity.x = move_toward(velocity.x, target, 1200.0 * delta)
				if state == RUN and is_on_wall() and is_on_floor():
					velocity.y = jump_velocity
		LEAVE:   # רצה הרחק מהשחקן ונעלמת
			_leave_t += delta
			velocity.x = move_toward(velocity.x, run_speed * 1.1 * _dir, 1200.0 * delta)
			if is_on_wall() and is_on_floor():
				velocity.y = jump_velocity
			if _leave_t > 4.0:
				modulate.a = clampf(5.0 - _leave_t, 0.0, 1.0)
				if _leave_t > 5.0:
					queue_free()
					return
		DRAINED:
			velocity.x = 0.0
			if _burn_t >= 0.0:
				_burn_t += delta
		DEAD:
			_dead_t += delta
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
				_angle = lerp_angle(_angle, PI / 2.0 * -_dir, 6.0 * delta)
			else:
				_angle += -_dir * 6.0 * delta
			if _dead_t > 12.0:
				modulate.a = clampf(14.0 - _dead_t, 0.0, 1.0)
				if _dead_t > 14.0:
					queue_free()
					return
	move_and_slide()
	global_position.x = clampf(global_position.x, 15.0, world_w - 15.0)
	if is_on_floor() and (state == RUN or state == LEAVE):
		_phase += delta * absf(velocity.x) * 0.075
	_tick += 1
	if (_tick % 2 == 0 or state == DRAINED) and Art.on_screen(self, global_position):   # ביצועים: כל פריים שני
		queue_redraw()


# חסת עליה: היא משאירה ארגז אספקה ובורחת
func _leave() -> void:
	state = LEAVE
	_say("THANK YOU!")
	var p = PickupScript.new()
	p.kind = PickupScript.SUPPLY
	get_parent().add_child(p)
	p.setup(global_position + Vector2(0, -30), Vector2(-_dir * 60.0, -220.0))
	_dir = -_dir   # בורחת לכיוון ההפוך
	Game.on_spared()
	Game.story.emit("spared", {"s": self})


func _say(text: String) -> void:
	var p = ZombieScript.HitText.new()
	p.text = text
	p.color = Color("f4f0e8")
	p.size = 16
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0, -70)


# ============================================================
#  קליע / פיצוץ = מוות מיידי
# ============================================================
func take_damage(_amount: int, hit_pos: Vector2, dir: Vector2, _explosive := false, _src := {}) -> void:
	if state == DEAD or state == DRAINED:
		return
	state = DEAD
	Game.story.emit("survivor_dead", {"s": self, "source": _src.get("source", "grenade" if _explosive else "bullet")})
	remove_from_group("survivors")
	collision_layer = 0
	var r := _shape.shape as RectangleShape2D
	r.size = Vector2(16, 16)
	_shape.position = Vector2(0, -8)
	_dir = -signf(dir.x) if dir.x != 0.0 else _dir
	velocity = Vector2(dir.x * 130.0, -90.0)   # עפה חצי מרחק (היה 260, -180)
	for i in 7:   # חצי דם (היה 14)
		var b = BloodScript.new()
		get_parent().add_child(b)
		b.setup(hit_pos, Vector2.from_angle(dir.angle() + randf_range(-0.8, 0.8)) * randf_range(80.0, 300.0) + Vector2(0, -120))


# ============================================================
#  המכשיר של השחקן (player.gd קורא לפונקציות האלה)
# ============================================================
func can_drain(p: Node) -> bool:
	if state == DEAD or state == DRAINED or state == LEAVE or not is_on_floor():
		return false
	var d: Vector2 = p.global_position - global_position
	return absf(d.x) < drain_range and absf(d.y) < 40.0


func start_drain() -> void:
	state = DRAINED
	collision_layer = 0   # קליעים כבר לא פוגעים בה
	remove_from_group("survivors")
	velocity = Vector2.ZERO


func set_drain(k: float) -> void:
	_drain_k = clampf(k, 0.0, 1.0)


func finish_drain() -> void:
	_drain_k = 1.0
	_burn_t = 0.0


# נקודה בחזה (משם יוצאת קרן כוח החיים)
func chest() -> Vector2:
	return global_position + Vector2(0, -29.0 - 6.0 * sin(_drain_k * PI) if _burn_t < 0.0 else -17.0)


# ============================================================
#  ציור
# ============================================================
func _draw() -> void:
	if state == DEAD:
		var outer := Transform2D(_angle, Vector2(0, -8))
		draw_set_transform_matrix(outer * Transform2D(0.0, Vector2(_dir * SIZE, SIZE), 0.0, Vector2(0, 26.0 * SIZE)))
		_draw_woman(0.0)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	if is_on_floor():
		Art.ground_shadow(self, Vector2.ZERO, 11.0 * SIZE)
	# בזמן השאיבה: מתרוממת קצת ורועדת
	var lift := 0.0
	var shake := Vector2.ZERO
	if state == DRAINED and _burn_t < 0.0:
		lift = -6.0 * sin(_drain_k * PI * 0.5)
		shake = Vector2(randf_range(-1.0, 1.0), randf_range(-0.6, 0.6)) * (0.5 + 1.5 * _drain_k)
	draw_set_transform(Vector2(0, lift) + shake, 0.0, Vector2(_dir * SIZE, SIZE))
	_draw_woman(1.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if state == WAIT:   # כמה זמן נשאר להחליט (שאיבה או רחמים)
		var left := 1.0 - _wait_t / mercy_time
		draw_arc(Vector2(0, -68), 14.0, -PI / 2.0, -PI / 2.0 + TAU * left, 24, Color(1, 1, 1, 0.35), 2.0, true)
	# סימן: אפשר להפעיל את המכשיר עכשיו
	if not scripted and _player != null and is_instance_valid(_player) and can_drain(_player) and not _player.dead:
		var pulse := 0.5 + 0.5 * sin(_t * 8.0)
		var c := Vector2(0, -68)
		draw_arc(c, 9.0 + pulse * 3.0, 0.0, TAU, 24, Color(0.45, 1.0, 0.85, 0.5 + 0.5 * pulse), 2.0, true)
		draw_circle(c, 3.0, Color(0.45, 1.0, 0.85))
		var f := ThemeDB.fallback_font
		var txt := "DRAIN"
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string_outline(f, c + Vector2(-w / 2.0, -16), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.8))
		draw_string(f, c + Vector2(-w / 2.0, -16), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 1.0, 0.85))


func _draw_woman(alive: float) -> void:
	var burned := _burn_t >= 0.0
	var dk := _drain_k if state == DRAINED else 0.0
	var gray := Color(0.55, 0.55, 0.58)
	var skin: Color = _c.skin
	var hair: Color = _c.hair
	var top: Color = _c.top
	var pants: Color = _c.pants
	var boots: Color = _c.boots
	# בזמן השאיבה הצבעים דוהים לאפור
	skin = skin.lerp(gray.lightened(0.2), dk * 0.8)
	hair = hair.lerp(gray, dk * 0.7)
	top = top.lerp(gray.darkened(0.2), dk * 0.7)
	pants = pants.lerp(gray.darkened(0.3), dk * 0.6)
	var collapse := 0.0
	if burned:   # שרופה: פחם שחור
		var char_c := Color("1d1613")
		skin = char_c.lightened(0.05)
		hair = char_c
		top = char_c.lightened(0.02)
		pants = char_c
		boots = char_c.darkened(0.3)
		collapse = clampf(_burn_t / 1.1, 0.0, 1.0)
		collapse = collapse * collapse * (3.0 - 2.0 * collapse)

	var p := _phase
	var running := (state == RUN or state == LEAVE) and is_on_floor()
	var lean := 5.0 if running else 0.0
	var breath := sin(_t * 6.0) * 0.8 if state == WAIT else sin(_t * 2.0) * 0.4
	var hip := Vector2(0, -24.0 - (absf(sin(p)) * 1.5 if running else 0.0))
	var sh := Vector2(lean + 1.0, -40.0 + hip.y + 24.0 - breath * 0.5)
	if dk > 0.0 and not burned:   # מתקשתת אחורה, הראש למעלה
		sh += Vector2(-3.0, -1.0) * dk
	# קריסה לברכיים, גוף שמוט קדימה
	hip = hip.lerp(Vector2(-2.0, -11.0), collapse)
	sh = sh.lerp(Vector2(9.0, -24.0), collapse)
	var head := sh + Vector2(2.0, -7.5)
	if dk > 0.0 and not burned:
		head += Vector2(-2.5, -1.5) * dk
	head = head.lerp(sh + Vector2(7.0, 2.0), collapse)

	# כפות רגליים
	var f1 := Vector2(1.0, 0.0)
	var f2 := Vector2(-2.0, 0.0)
	if running:
		f1 = Vector2(sin(p) * 9.0 + 2.0, -maxf(0.0, cos(p)) * 5.0)
		f2 = Vector2(sin(p + PI) * 9.0, -maxf(0.0, cos(p + PI)) * 5.0)
	elif not is_on_floor() and alive > 0.0:
		f1 = Vector2(5.0, -8.0)
		f2 = Vector2(-4.0, -5.0)
	if dk > 0.0 and not burned:   # מרחפת: רגליים תלויות
		f1 = Vector2(1.5, 2.0 * dk)
		f2 = Vector2(-1.5, 2.0 * dk)
	f1 = f1.lerp(Vector2(-11.0, 0.0), collapse)
	f2 = f2.lerp(Vector2(-14.0, 0.0), collapse)

	# ידיים
	var bs := sh + Vector2(-2.0, 1.5)
	var fs := sh + Vector2(2.0, 1.5)
	var bh := bs + Vector2(-2.0, 15.0)
	var fh := fs + Vector2(3.0, 15.0)
	if running:
		bh = bs + Vector2(-sin(p) * 9.0, 12.0)
		fh = fs + Vector2(sin(p) * 9.0 + 2.0, 11.0)
	elif state == WAIT:   # מושיטה יד לשחקן: "תעזור לי"
		fh = fs + Vector2(15.0, 2.0 + sin(_t * 3.0) * 1.5)
		bh = bs + Vector2(2.0, 14.0)
	if dk > 0.0 and not burned:   # ידיים פתוחות לצדדים
		fh = fs + Vector2(13.0, -4.0 * dk + 6.0)
		bh = bs + Vector2(-11.0, -4.0 * dk + 6.0)
	fh = fh.lerp(sh + Vector2(10.0, 15.0), collapse)
	bh = bh.lerp(sh + Vector2(4.0, 16.0), collapse)

	# שיער ארוך מאחור (קוקו שמתנופף בריצה)
	if not burned:
		var sway := sin(_t * (12.0 if running else 2.0)) * (3.0 if running else 1.0)
		var tail := PackedVector2Array([head + Vector2(-5.0, -3.0), head + Vector2(-10.0 - lean, 3.0 + sway * 0.5), head + Vector2(-13.0 - lean * 1.6, 12.0 + sway)])
		Art.limb(self, tail, 4.5, hair)
	_arm(bs, bh, Art.shade(skin, 0.15), Art.shade(top, 0.15), burned)
	_leg(hip + Vector2(-1.5, 0), f2, Art.shade(pants, 0.2), Art.shade(boots, 0.2), burned)
	_leg(hip + Vector2(1.5, 0), f1, pants, boots, burned)
	# גוף: חולצה צמודה
	var body := PackedVector2Array([
		sh + Vector2(-6.5, -0.5), sh + Vector2(6.0, 0.0), sh + Vector2(6.8, 4.5), hip + Vector2(4.5, -7.0),
		hip + Vector2(6.0, 1.0), hip + Vector2(-6.0, 1.0), hip + Vector2(-4.5, -7.0), sh + Vector2(-7.0, 4.0),
	])
	Art.fill_shaded(self, body, top, 0.15, 0.3, Art.OUTLINE, 1.2)
	draw_line(hip + Vector2(-6.0, -1.0), hip + Vector2(6.0, -1.0), Art.shade(pants, 0.3), 2.0, true)   # חגורה
	# צוואר + ראש
	Art.limb(self, PackedVector2Array([sh + Vector2(1.0, 0.0), head + Vector2(-0.5, 4.0)]), 3.4, skin)
	if burned:
		Art.oval_shaded(self, head, 5.6, 6.2, skin, 0.3, Art.OUTLINE, 1.2)
		Art.oval(self, head + Vector2(3.0, -0.5), 1.4, 1.0, Color(0, 0, 0, 0.8), 0.0, Art.NONE)   # ארובת עין
		_embers(body, head)
	else:
		Art.oval(self, head + Vector2(-1.5, -1.5), 6.6, 6.8, hair)   # שיער מאחורי הראש
		Art.oval_shaded(self, head, 5.6, 6.4, skin, 0.0, Art.OUTLINE, 1.1)
		# פוני ושיער בצד
		Art.fill(self, PackedVector2Array([head + Vector2(-6.0, -1.0), head + Vector2(-5.0, -6.0), head + Vector2(0.0, -7.5), head + Vector2(5.5, -5.0), head + Vector2(4.5, -3.0), head + Vector2(0.0, -4.0), head + Vector2(-3.0, 1.0)]), hair, Art.OUTLINE, 1.0)
		# עין עם ריסים, שפתיים
		var eye := head + Vector2(3.0, -0.8)
		var closed := dk > 0.3
		if closed:
			draw_line(eye + Vector2(-1.2, 0.3), eye + Vector2(1.2, 0.3), Color("1a1010"), 0.8, true)
		else:
			Art.oval(self, eye, 0.9, 1.2, Color("1a1010"), 0.0, Art.NONE)
			draw_line(eye + Vector2(-0.6, -1.3), eye + Vector2(1.6, -1.8), Color("1a1010"), 0.7, true)
		draw_line(head + Vector2(3.0, 3.4), head + Vector2(4.6, 3.2), Color("a8404a").lerp(gray, dk), 1.1, true)
		draw_circle(head + Vector2(-1.0, 2.0), 0.7, Color("d8c070"))   # עגיל
		if dk > 0.0:   # זוהר של כוח החיים שיוצא ממנה
			Art.glow(self, sh + Vector2(1.0, 6.0), 14.0 + 8.0 * dk, Color(0.45, 1.0, 0.85, 0.5 * sin(dk * PI) + 0.1))
	_arm(fs, fh, skin, top, burned)


func _arm(shoulder: Vector2, hand: Vector2, skin: Color, sleeve: Color, burned: bool) -> void:
	var elbow := Art.joint(shoulder, hand, 8.0, 8.0, -1.0)
	var cuff := shoulder.lerp(elbow, 0.55)
	Art.limb(self, PackedVector2Array([cuff, elbow, hand]), 3.4, skin)
	Art.limb(self, PackedVector2Array([shoulder, cuff]), 4.2, sleeve)
	Art.disc(self, hand, 2.0, skin, Art.OUTLINE, 0.9)


func _leg(hip: Vector2, foot: Vector2, pants: Color, boots: Color, burned: bool) -> void:
	var ankle := foot + Vector2(0, -3.0)
	var knee := Art.joint(hip, ankle, 11.5, 11.0, 1.0)
	Art.limb(self, PackedVector2Array([hip, knee, ankle]), 5.2, pants)
	var top := knee.lerp(ankle, 0.35)
	Art.limb(self, PackedVector2Array([top, ankle]), 5.6, boots)
	Art.fill(self, PackedVector2Array([foot + Vector2(-2.5, -3.5), foot + Vector2(2.0, -3.5), foot + Vector2(6.0, -1.2), foot + Vector2(6.0, 0.0), foot + Vector2(-3.0, 0.0)]), boots, Art.OUTLINE, 0.9)


# גחלים זוהרים בסדקים של הגוף השרוף, ועשן שעולה
func _embers(body: PackedVector2Array, head: Vector2) -> void:
	var glow := clampf(1.0 - _burn_t / 4.0, 0.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 31 + 5
	if glow > 0.0:
		for i in 7:
			var a := body[rng.randi() % body.size()].lerp(body[rng.randi() % body.size()], rng.randf())
			var b := a + Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0))
			var flick := 0.6 + 0.4 * sin(_t * 9.0 + float(i))
			draw_line(a, b, Color(1.0, 0.45, 0.1, glow * flick), 1.0, true)
		draw_line(head + Vector2(-3, -2), head + Vector2(1, 2), Color(1.0, 0.45, 0.1, glow * 0.8), 0.8, true)
	var smoke := clampf(1.0 - _burn_t / 8.0, 0.0, 1.0)
	if smoke > 0.0:
		for i in 5:
			var k := fmod(float(i) / 5.0 + _t * 0.3, 1.0)
			var p := head + Vector2(sin(k * 6.0 + float(i)) * 3.0 - k * 6.0, -6.0 - k * 40.0)
			draw_circle(p, 3.0 + k * 9.0, Color(0.2, 0.18, 0.18, 0.35 * (1.0 - k) * smoke))
