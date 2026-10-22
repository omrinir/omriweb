extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  SPIRIT TIGER - פריט מיוחד (progression/arsenal.gd -> SPECIALS "tiger", שימוש אחד).
#  C -> רוח של נמר יוצאת מהגוף של השחקן: הגוף זוהר ירוק, ענן ירוק עולה מהחזה ומתחיל לרחף.
#  v3 (המשתמש: "קטן יותר, פחות מוגדר, ענן כשהוא מרחף, נמר כשהוא תוקף"):
#    מרחף = ענן רך של "נשיפות" (PUFFS) שמסתובבות לאט, רק עין זוהרת אחת.
#    מתקרב לזומבי (ATTACK_R) -> הנשיפות מתאספות לצורת נמר (_m: 0 = ענן, 1 = נמר), הגוף השקוף + פסים + לסת פתוחה מופיעים,
#    עובר דרך הזומבי (הוא מת), ואחרי ההריגה נמס חזרה לענן (MORPH_OUT).
#  תנועה: גולש באוויר בקשתות חלקות (היגוי רך), לא נוגע ברצפה, וממשיך בתנופה לבא בתור. בלי קווי מתאר חדים.
#  אחרי KILLS הריגות (או IDLE_MAX שניות בלי זומבים / LIFE_MAX בסך הכל) - עולה למעלה ונמסה.
#  בוסים וזומבי MIND CONTROL - לא נוגעת. עוברת דרך קירות.
#  ציור: צומת אחד (נשיפות הענן + גוף הנמר השקוף, DrawBatch) + ילד _glow עם אור מצטבר (הילה, עין, אד).
#  לשנות: KILLS, SPEED, STEER, HIT_R, SCALE, LEN_K, ATTACK_R, MORPH_IN / MORPH_OUT, PUFF_T, WISP_RATE, WISPS_MAX.  בדיקה: devtools/t_tiger.gd.
# ============================================================

const Sfx := preload("res://sfx.gd")

const KILLS := 3
const SCALE := 0.85
const LEN_K := 0.82              # הנמר קצר יותר (מכווץ לאורך)
const ATTACK_R := 250.0          # מהמרחק הזה הענן הופך לנמר
const MORPH_IN := 4.5            # כמה מהר הופך לנמר (לשנייה)
const MORPH_OUT := 1.6           # כמה מהר נמס חזרה לענן
const SEARCH := 1100.0           # כמה רחוק היא מחפשת זומבים
const SPEED := 470.0             # מהירות גלישה
const STEER := 2.7               # כמה מהר המהירות נמשכת לכיוון (קטן = קשתות רחבות וחלקות)
const HIT_R := 38.0              # עוברת כל כך קרוב למרכז הזומבי -> הוא מת
const AFTER_HIT := 0.22          # אחרי הריגה: ממשיכה בתנופה לפני שמחפשת את הבא
const HOVER := 34.0              # גובה המרכז מעל כפות הרגליים של הזומבי
const SUMMON_T := 0.9            # יוצאת מהגוף
const FADE_T := 1.1
const IDLE_MAX := 5.0
const LIFE_MAX := 22.0
const WISP_RATE := 60.0          # להבות בשנייה
const WISPS_MAX := 200
const DMG := 9999

const C_BODY := Color(0.5, 1.0, 0.66)
const C_STRIPE := Color(0.04, 0.42, 0.18)
# הנשיפות: [מיקום בצורת נמר, רדיוס בנמר]. בענן הן מסתובבות סביב המרכז
static var PUFF_T := [[Vector2(-30, 0), 12.0], [Vector2(-14, -1), 12.0], [Vector2(2, -2), 12.0], [Vector2(18, -3), 12.0], [Vector2(33, -6), 11.0],
	[Vector2(48, -8), 11.0], [Vector2(24, 14), 7.0], [Vector2(-26, 14), 7.0], [Vector2(-52, -10), 6.0], [Vector2(-68, -18), 5.0]]
const C_CORE := Color(0.85, 1.0, 0.9)
const C_EYE := Color(0.92, 1.0, 0.94)

const SOUNDS := {
	"tiger_summon": {"rev": 0.6, "layers": [["N", 0, 0, 0.0, 0.9, 0.4, 0.0, 0.3, 0.25, 0], ["S", 220, 660, 0.0, 0.9, 0.35, 0.0, 0.16, 1.0, 0.04], ["S", 330, 990, 0.1, 0.8, 0.35, 0.0, 0.08, 1.0, 0.05]]},
	"tiger_roar": {"drive": 1.6, "rev": 0.7, "layers": [["V", 140, 90, 0.0, 1.2, 0.15, 1.4, 0.6, 0.7, 0.06, 0, [320, 760, 18]], ["S", 440, 330, 0.0, 1.1, 0.2, 1.6, 0.08, 1.0, 0.06], ["N", 0, 0, 0.0, 1.0, 0.2, 2.0, 0.15, 0.15, 0]]},
	"tiger_swoop": {"rev": 0.5, "layers": [["N", 0, 0, 0.0, 0.45, 0.15, 4.0, 0.35, 0.3, 0], ["S", 520, 880, 0.0, 0.4, 0.1, 5.0, 0.07, 1.0, 0.03]]},
	"tiger_hit": {"rev": 0.6, "layers": [["S", 880, 660, 0.0, 0.6, 0.0, 4.0, 0.16, 1.0, 0.02], ["S", 1320, 990, 0.0, 0.5, 0.0, 5.0, 0.08, 1.0, 0.02], ["S", 90, 50, 0.0, 0.3, 0.0, 9.0, 0.45, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.02, 9.0, 0.25, 0.35, 0]]},
}

enum { SUMMON, HUNT, LEAVE }
var pl: Node2D = null
var state := SUMMON
var kills := 0
var face := 1.0
var pos := Vector2.ZERO          # מרכז הגוף (קואורדינטות השלב)
var vel := Vector2.ZERO
var _st := 0.0
var _life := 0.0
var _t := 0.0
var _idle := 0.0
var _coast := 0.0                # תנופה אחרי הריגה
var _target: Node2D = null
var _skip := {}
var _face_s := 1.0               # הפנייה חלקה (עוברת דרך 0 = מסתובבת)
var _rot := 0.0
var _jaw := 0.0
var _grow := 0.0
var _alpha := 0.0
var _swim := 0.0                 # תנועת "שחייה" של הרגליים (מתגברת עם המהירות)
var _m := 0.0                    # 0 = ענן, 1 = נמר
var _wisps: Array = []           # [pos, vel, life, age, size]
var _emit := 0.0
var _glow: Node2D
var kills_log: Array = []        # לבדיקות


func setup(player: Node2D) -> void:
	pl = player
	face = float(player._face()) if player.has_method("_face") else 1.0
	_face_s = face
	pos = player.global_position + Vector2(0.0, -30.0)


func _ready() -> void:
	z_index = 3
	_glow = Node2D.new()
	_glow.material = preload("res://effects/boom_fx.gd").res()["add"]
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	Sfx.play("tiger_summon", pos, 1.0, 0.0, 1)


func _process(delta: float) -> void:
	_t += delta
	_st += delta
	_life += delta
	match state:
		SUMMON:
			_do_summon(delta)
		HUNT:
			_do_hunt(delta)
		LEAVE:
			_alpha = clampf(1.0 - _st / FADE_T, 0.0, 1.0)
			vel = vel.lerp(Vector2(0.0, -140.0), 1.0 - exp(-2.0 * delta))
			pos += vel * delta
			_grow = 1.0 + 0.25 * (1.0 - _alpha)
			if _st > FADE_T and _wisps.is_empty():
				queue_free()
				return
	if state == HUNT and _life > LIFE_MAX:
		_leave()
	if absf(vel.x) > 50.0:
		face = signf(vel.x)
	_face_s = move_toward(_face_s, face, delta * 5.0)
	var want_rot := clampf(atan2(vel.y, maxf(absf(vel.x), 60.0)), -0.6, 0.6) * 0.55 * _m * signf(_face_s if _face_s != 0.0 else face)
	_rot = lerpf(_rot, want_rot, 1.0 - exp(-6.0 * delta))
	_swim += delta * (2.0 + vel.length() / 90.0)
	var want_m := 0.0
	if state == HUNT and _coast <= 0.0 and _valid(_target) and pos.distance_to(_target.global_position + Vector2(0.0, -HOVER)) < ATTACK_R:
		want_m = 1.0
	_m = move_toward(_m, want_m, delta * (MORPH_IN if want_m > _m else MORPH_OUT))
	_update_wisps(delta)
	queue_redraw()
	_glow.queue_redraw()


func _goto(s: int) -> void:
	state = s
	_st = 0.0


# ---- עולה מהגוף של השחקן ----
func _do_summon(delta: float) -> void:
	var u := clampf(_st / SUMMON_T, 0.0, 1.0)
	if pl != null and is_instance_valid(pl):
		var e := u * u * (3.0 - 2.0 * u)
		var chest: Vector2 = pl.global_position + Vector2(0.0, -30.0)
		pos = chest + Vector2(face * 34.0 * e, -46.0 * e)
	_grow = 0.35 + 0.65 * (1.0 - pow(1.0 - u, 3.0))
	_alpha = minf(1.0, u * 1.6)
	_jaw = 0.6 * sin(u * PI)
	vel = Vector2(face * 40.0, -40.0) * (1.0 - u)
	if u >= 1.0:
		_grow = 1.0
		_jaw = 0.0
		vel = Vector2(face * SPEED * 0.4, -60.0)
		Sfx.play("tiger_roar", pos, 0.0, 0.05, 1)
		_goto(HUNT)


# ---- גלישה: היגוי רך לזומבי, עוברת דרכו, ממשיכה בתנופה ----
func _do_hunt(delta: float) -> void:
	_coast = maxf(0.0, _coast - delta)
	if _coast <= 0.0 and not _valid(_target):
		_target = _find_target()
		if _target != null:
			Sfx.play("tiger_swoop", pos, -2.0, 0.1, 2)
	var desired := Vector2.ZERO
	if _coast > 0.0:
		desired = vel   # תנופה: ממשיכה ישר
	elif _target != null:
		_idle = 0.0
		var tp := _target.global_position + Vector2(0.0, -HOVER)
		var to := tp - pos
		var d := to.length()
		desired = to / maxf(d, 1.0) * SPEED * clampf(0.55 + d / 300.0, 0.55, 1.15)
		_jaw = lerpf(_jaw, clampf(1.0 - (d - 40.0) / 160.0, 0.0, 1.0), 1.0 - exp(-10.0 * delta))
		if d < HIT_R:
			_strike()
	else:   # אין זומבים: מרחפת לאט ליד השחקן
		_idle += delta
		_jaw = lerpf(_jaw, 0.0, 1.0 - exp(-6.0 * delta))
		var home := pos
		if pl != null and is_instance_valid(pl):
			home = pl.global_position + Vector2(-face * 60.0, -95.0 + sin(_t * 1.6) * 14.0)
		desired = (home - pos) * 2.0
		if desired.length() > SPEED * 0.5:
			desired = desired.normalized() * SPEED * 0.5
		if _idle > IDLE_MAX:
			_leave()
	vel = vel.lerp(desired, 1.0 - exp(-STEER * delta))
	pos += vel * delta + Vector2(0.0, sin(_t * 2.4) * 10.0 * delta)


func _strike() -> void:
	var z := _target
	_target = null
	_coast = AFTER_HIT
	var d := vel.normalized() if vel.length() > 1.0 else Vector2(face, 0.0)
	var hit := z.global_position + Vector2(0.0, -HOVER)
	z.take_damage(DMG, hit, d, false, {"source": "tiger", "fixed": DMG})
	if not z.dead:
		z.take_damage(DMG, hit, d, true, {"source": "tiger", "fixed": DMG})
	Sfx.play("tiger_hit", hit, 0.0, 0.08, 3)
	for i in 26:   # הבזק רך של להבות במקום שעברה
		var a := randf() * TAU
		_wisp(hit + Vector2.from_angle(a) * randf_range(0.0, 14.0), Vector2.from_angle(a) * randf_range(40.0, 170.0) + vel * 0.25 + Vector2(0.0, -40.0), randf_range(0.45, 0.85), randf_range(6.0, 13.0))
	if z.dead:
		kills += 1
		kills_log.append(z.get("kind") if z.get("kind") != null else -1)
		if z.has_method("_popup"):
			z._popup("SPIRIT %d/%d" % [kills, KILLS], Color("9dffbc"), 18, -95.0)
		if kills >= KILLS:
			_leave()
	else:
		_skip[z.get_instance_id()] = true


func _leave() -> void:
	if state == LEAVE:
		return
	Sfx.play("tiger_roar", pos, -2.0, 0.05, 1)
	_jaw = 0.8
	_goto(LEAVE)


func _valid(z: Node2D) -> bool:
	return z != null and is_instance_valid(z) and not z.dead and not z.is_boss() and z.get("possessed") == null and not _skip.has(z.get_instance_id())


func _find_target() -> Node2D:
	var best: Node2D = null
	var bd := INF
	for z in get_tree().get_nodes_in_group("zombies"):
		if not _valid(z):
			continue
		var d: Vector2 = z.global_position + Vector2(0.0, -HOVER) - pos
		if absf(d.x) > SEARCH or absf(d.y) > 450.0:
			continue
		var s := d.length() + (140.0 if signf(d.x) != signf(vel.x) else 0.0)   # עדיף מה שלפניה (פחות סיבובים)
		if s < bd:
			bd = s
			best = z
	return best


# ============ להבות (אד ירוק רך) ============
func _wisp(p: Vector2, v: Vector2, life: float, size: float) -> void:
	if _wisps.size() >= WISPS_MAX:
		return
	_wisps.append([p, v, life, 0.0, size])


func _update_wisps(delta: float) -> void:
	if state != LEAVE or _st < FADE_T:
		_emit += delta * WISP_RATE * (1.6 if state == LEAVE else 1.0)
		var xf := _xf()
		while _emit >= 1.0:
			_emit -= 1.0
			var pf := _puff(randi() % PUFF_T.size())   # אד יוצא מהנשיפות
			var wp := xf * (pf[0] as Vector2 + Vector2.from_angle(randf() * TAU) * float(pf[1]) * 0.7)
			if state == SUMMON and pl != null and is_instance_valid(pl) and randf() < 0.5:   # אד עולה מהגוף של השחקן
				wp = pl.global_position + Vector2(randf_range(-10.0, 10.0), -randf_range(0.0, 56.0))
			_wisp(wp, -vel * 0.18 + Vector2(randf_range(-18.0, 18.0), -randf_range(25.0, 70.0)), randf_range(0.45, 0.9), randf_range(4.0, 8.0) * _grow)
	for i in range(_wisps.size() - 1, -1, -1):
		var w: Array = _wisps[i]
		w[3] += delta
		if w[3] >= w[2]:
			_wisps.remove_at(i)
			continue
		var v: Vector2 = w[1]
		v = v.lerp(Vector2(v.x * 0.3, -55.0), 1.0 - exp(-2.5 * delta))   # מאט ועולה לאט
		w[1] = v
		w[0] += v * delta


func _xf() -> Transform2D:
	var s := SCALE * _grow
	return Transform2D(_rot, Vector2(_face_s * s * LEN_K, s), 0.0, pos)


# נשיפה i: [מיקום מקומי, רדיוס] - בין הענן (_m=0) לצורת הנמר (_m=1)
func _puff(i: int) -> Array:
	var fi := float(i)
	var a := fi * 2.4 + _t * (0.5 + 0.15 * float(i % 3))
	var rr := 6.0 + fmod(fi * 7.0, 22.0)
	var cloud := Vector2(cos(a) * rr * 1.5, sin(a) * rr * 0.6 - 2.0)   # ענן רחב ושטוח
	var cr := 15.0 + fmod(fi * 5.0, 8.0) + sin(_t * 2.0 + fi) * 2.5
	var e := _m * _m * (3.0 - 2.0 * _m)
	var tp: Vector2 = PUFF_T[i][0]
	if i >= 8:   # הזנב מתנפנף
		tp += Vector2(0.0, sin(_t * 4.0 - fi) * 5.0)
	return [cloud.lerp(tp + Vector2(sin(_t * 3.0 + fi) * 1.5, cos(_t * 2.6 + fi) * 1.5), e), lerpf(cr, float(PUFF_T[i][1]), e)]


static var BODY := PackedVector2Array([Vector2(-42, -2), Vector2(-30, -11), Vector2(-8, -10), Vector2(12, -13), Vector2(30, -12), Vector2(40, -8),
	Vector2(38, 5), Vector2(18, 10), Vector2(-4, 8), Vector2(-26, 9), Vector2(-42, 5)])
static var HEAD := PackedVector2Array([Vector2(33, -12), Vector2(44, -19), Vector2(54, -15), Vector2(61, -8), Vector2(62, -2), Vector2(56, 2), Vector2(44, 2), Vector2(34, -2)])


static func _tail_pt(u: float, t: float) -> Vector2:
	return Vector2(-38.0 - 44.0 * u, -6.0 - 14.0 * u + sin(t * 4.0 - u * 3.5) * 10.0 * u)


# ============ ציור ============
func _draw() -> void:
	DrawBatch.begin(self)
	if _alpha > 0.01:   # ערבוב רגיל, כדי שייראה גם על רקע בהיר
		DrawBatch.set_transform_matrix(self, _xf())
		for i in PUFF_T.size():   # הענן: נשיפות רכות (שתי שכבות שקופות)
			var pf := _puff(i)
			DrawBatch.circle(self, pf[0], float(pf[1]) * 1.3, Color(C_BODY, 0.10 * _alpha))
			DrawBatch.circle(self, pf[0], float(pf[1]) * 0.85, Color(C_BODY, 0.16 * _alpha))
		if _m > 0.05:   # הנמר מתגבש מהענן
			draw_body(self, _t, _swim, _jaw, 0.4 * _m * _m * _alpha, C_BODY, true)
		DrawBatch.set_transform_matrix(self, Transform2D.IDENTITY)
	DrawBatch.end(self)


# הגוף בקואורדינטות מקומיות: פונה ימינה, מרכז הגוף ב-(0,0), אורך ~110. detail = רגליים / זנב / פסים
static func draw_body(ci: CanvasItem, t: float, swim: float, jaw: float, a: float, col: Color, detail: bool) -> void:
	var c := Color(col, a)
	if detail:
		for i in 4:   # רגליים: נמתחות לאחור ולפנים, נעות לאט כמו בשחייה, ונעלמות למטה
			var front := i >= 2
			var bx := (22.0 if front else -24.0) + (3.0 if i % 2 == 0 else -3.0)
			var ph := swim + float(i) * 1.7
			var base := Vector2(bx, 4.0)
			var dirv := Vector2.from_angle(PI * 0.5 - (0.75 if front else -0.75) + sin(ph) * 0.35)
			var knee := base + dirv * 13.0
			var tip := knee + dirv.rotated(-0.25 if front else 0.25) * 14.0
			DrawBatch.line(ci, base, knee, Color(col, a * (0.8 if i % 2 == 0 else 0.5)), 7.0)
			DrawBatch.line(ci, knee, tip, Color(col, a * (0.4 if i % 2 == 0 else 0.25)), 4.0)
		var prev := _tail_pt(0.0, t)
		for i in range(1, 10):   # זנב ארוך, מתנפנף, נעלם בקצה
			var u := float(i) / 9.0
			var p := _tail_pt(u, t)
			DrawBatch.line(ci, prev, p, Color(col, a * (1.0 - u * 0.75)), 6.5 - 4.5 * u)
			prev = p
	DrawBatch.colored_polygon(ci, BODY, c)
	var hd := Vector2(38.0, 0.0)
	DrawBatch.colored_polygon(ci, PackedVector2Array([hd + Vector2(-2, -14), hd + Vector2(0, -21), hd + Vector2(5, -16)]), c)   # אוזניים
	DrawBatch.colored_polygon(ci, PackedVector2Array([hd + Vector2(7, -17), hd + Vector2(10, -24), hd + Vector2(13, -16)]), c)
	var jp := hd + Vector2(5.0, 1.0)   # לסת: נפתחת כשמתקרבת לזומבי
	var jaw_pts := PackedVector2Array()
	for p: Vector2 in [Vector2(0, 0), Vector2(17, 0), Vector2(13, 5), Vector2(2, 4)]:
		jaw_pts.append(jp + p.rotated(jaw * 0.65))
	DrawBatch.colored_polygon(ci, jaw_pts, Color(col, a * 0.8))
	DrawBatch.colored_polygon(ci, HEAD, c)
	if detail:
		for i in 5:   # פסים כהים שקופים
			var x := -30.0 + float(i) * 12.0
			DrawBatch.line(ci, Vector2(x, -10.0), Vector2(x - 6.0, 2.0), Color(C_STRIPE, a * 0.9), 3.0)
			DrawBatch.line(ci, Vector2(x - 6.0, 2.0), Vector2(x - 4.0, 6.0), Color(C_STRIPE, a * 0.6), 2.0)
		DrawBatch.line(ci, hd + Vector2(5, -17), hd + Vector2(8, -12), Color(C_STRIPE, a * 0.8), 2.0)
		DrawBatch.line(ci, hd + Vector2(10, -16), hd + Vector2(11, -12), Color(C_STRIPE, a * 0.8), 2.0)


func _draw_glow() -> void:
	DrawBatch.begin(_glow)
	var a := _alpha
	if a > 0.01:
		var xf := _xf()
		DrawBatch.set_transform_matrix(_glow, xf)
		for i in PUFF_T.size():   # הילה רכה סביב כל נשיפה
			var pf := _puff(i)
			DrawBatch.circle(_glow, pf[0], float(pf[1]) * 1.7, Color(0.2, 1.0, 0.45, 0.035 * a))
		DrawBatch.ellipse(_glow, Vector2(0.0, -2.0), 22.0, 10.0, Color(C_CORE, 0.035 * a * (1.0 - _m)))   # ליבה רכה בענן
		DrawBatch.set_transform_matrix(_glow, Transform2D.IDENTITY)
		var ep := xf * Vector2(10.0, -8.0).lerp(Vector2(51.0, -11.0), _m)   # עין (בענן: באמצע, בנמר: בראש)
		DrawBatch.circle(_glow, ep, 6.0 * _grow, Color(0.5, 1.0, 0.65, 0.3 * a))
		DrawBatch.circle(_glow, ep, 2.4 * _grow, Color(C_EYE, 0.95 * a))
		if state == SUMMON and pl != null and is_instance_valid(pl):   # הגוף של השחקן זוהר
			var g := sin(clampf(_st / SUMMON_T, 0.0, 1.0) * PI)
			DrawBatch.ellipse(_glow, pl.global_position + Vector2(0.0, -30.0), 20.0, 34.0, Color(0.25, 1.0, 0.5, 0.3 * g))
			DrawBatch.ellipse(_glow, pl.global_position + Vector2(0.0, -30.0), 34.0, 52.0, Color(0.2, 1.0, 0.45, 0.12 * g))
	for w: Array in _wisps:   # להבות רכות: שתי שכבות עגולות, בהיר בהתחלה, דועך ונעלם
		var u: float = float(w[3]) / float(w[2])
		var fa := sin(minf(u * 5.0, 1.0) * PI * 0.5) * (1.0 - u)   # נכנס בעדינות, יוצא לאט
		var r: float = float(w[4]) * (0.7 + 0.6 * u)
		var p: Vector2 = w[0]
		DrawBatch.circle(_glow, p, r * 1.4, Color(0.15, 0.95, 0.4, 0.07 * fa))   # אד: רך וגדל, בלי ליבה בוהקת
		DrawBatch.circle(_glow, p, r * 0.8, Color(0.4, 1.0, 0.6, 0.09 * fa))
	DrawBatch.end(_glow)


# אייקון (ביד / על הריצפה / בבר): ראש נמר רוח זוהר. s ~1 = 24 פיקסלים
static func draw_icon(ci: CanvasItem, c: Vector2, s: float, t: float) -> void:
	var fl := 0.8 + 0.2 * sin(t * 4.0)
	DrawBatch.circle(ci, c, 12.0 * s, Color(0.2, 1.0, 0.45, 0.14 * fl))
	DrawBatch.circle(ci, c, 8.0 * s, Color(0.3, 1.0, 0.5, 0.16 * fl))
	var col := Color(C_BODY, 0.7)
	DrawBatch.colored_polygon(ci, PackedVector2Array([c + Vector2(-8, -4) * s, c + Vector2(-7, -10) * s, c + Vector2(-3, -6) * s]), col)
	DrawBatch.colored_polygon(ci, PackedVector2Array([c + Vector2(8, -4) * s, c + Vector2(7, -10) * s, c + Vector2(3, -6) * s]), col)
	var h := PackedVector2Array()
	for p: Vector2 in [Vector2(-8, -4), Vector2(-5, -7), Vector2(5, -7), Vector2(8, -4), Vector2(8, 3), Vector2(4, 7), Vector2(-4, 7), Vector2(-8, 3)]:
		h.append(c + p * s)
	DrawBatch.colored_polygon(ci, h, col)
	DrawBatch.line(ci, c + Vector2(0, -7) * s, c + Vector2(0, -3) * s, Color(C_CORE, 0.8), 1.4 * s)
	DrawBatch.circle(ci, c + Vector2(-3, -2) * s, 1.5 * s, C_EYE)
	DrawBatch.circle(ci, c + Vector2(3, -2) * s, 1.5 * s, C_EYE)
