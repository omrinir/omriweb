extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  SPIRIT TIGER - פריט מיוחד (progression/arsenal.gd -> SPECIALS "tiger", שימוש אחד).
#  C -> רוח של נמר יוצאת מהגוף של השחקן: הגוף זוהר ירוק, הרוח עולה מהחזה, שקופה וזוהרת, ומתחילה לרחף.
#  רוח, לא חיה: לא רצה על הרצפה ולא קופצת - גולשת באוויר בקשתות חלקות (היגוי רך: המהירות נמשכת לאט לכיוון המטרה),
#  עוברת דרך הזומבי (הוא מת) וממשיכה בתנופה לבא בתור. הגוף שקוף, עם הילה, עקבות (צלליות שנשארות מאחור),
#  רגליים שנמסות לאד, זנב ארוך שמתנפנף, ולהבות ירוקות רכות שנמשכות אחריה.
#  אחרי KILLS הריגות (או IDLE_MAX שניות בלי זומבים / LIFE_MAX בסך הכל) - עולה למעלה ונמסה.
#  בוסים וזומבי MIND CONTROL - לא נוגעת. עוברת דרך קירות.
#  ציור: צומת אחד (גוף שקוף, DrawBatch) + ילד _glow עם אור מצטבר (הילה, עקבות, עיניים, להבות).
#  לשנות: KILLS, SPEED, STEER, HIT_R, SCALE, TRAIL_N, WISP_RATE, WISPS_MAX.  בדיקה: devtools/t_tiger.gd.
# ============================================================

const Sfx := preload("res://sfx.gd")

const KILLS := 3
const SCALE := 1.15
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
const TRAIL_N := 7               # כמה צלליות-עקבות
const TRAIL_STEP := 0.035
const WISP_RATE := 60.0          # להבות בשנייה
const WISPS_MAX := 200
const DMG := 9999

const C_BODY := Color(0.5, 1.0, 0.66)
const C_STRIPE := Color(0.04, 0.42, 0.18)
const C_RIM := Color(0.75, 1.0, 0.82)
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
var _trail: Array = []           # [Transform2D, jaw, swim]
var _trail_t := 0.0
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
	var want_rot := clampf(atan2(vel.y, maxf(absf(vel.x), 60.0)), -0.6, 0.6) * 0.55 * signf(_face_s if _face_s != 0.0 else face)
	_rot = lerpf(_rot, want_rot, 1.0 - exp(-6.0 * delta))
	_swim += delta * (2.0 + vel.length() / 90.0)
	_trail_t -= delta
	if _trail_t <= 0.0:
		_trail_t = TRAIL_STEP
		_trail.push_front([_xf(), _jaw, _swim])
		if _trail.size() > TRAIL_N:
			_trail.pop_back()
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
			var r := randf()
			var lp: Vector2
			if r < 0.4:
				lp = Vector2(randf_range(-40.0, 36.0), randf_range(-11.0, -5.0))   # הגב
			elif r < 0.6:
				lp = _tail_pt(randf_range(0.5, 1.0), _t)
			elif r < 0.85:
				lp = Vector2(randf_range(-30.0, 28.0), randf_range(14.0, 26.0))   # הרגליים נמסות לאד
			else:
				lp = Vector2(randf_range(30.0, 48.0), -16.0)   # ראש
			var wp := xf * lp
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
	return Transform2D(_rot, Vector2(_face_s * s, s), 0.0, pos)


static var BODY := PackedVector2Array([Vector2(-42, -2), Vector2(-30, -11), Vector2(-8, -10), Vector2(12, -13), Vector2(30, -12), Vector2(40, -8),
	Vector2(38, 5), Vector2(18, 10), Vector2(-4, 8), Vector2(-26, 9), Vector2(-42, 5)])
static var HEAD := PackedVector2Array([Vector2(33, -12), Vector2(44, -19), Vector2(54, -15), Vector2(61, -8), Vector2(62, -2), Vector2(56, 2), Vector2(44, 2), Vector2(34, -2)])


static func _tail_pt(u: float, t: float) -> Vector2:
	return Vector2(-38.0 - 44.0 * u, -6.0 - 14.0 * u + sin(t * 4.0 - u * 3.5) * 10.0 * u)


# ============ ציור ============
func _draw() -> void:
	DrawBatch.begin(self)
	if _alpha > 0.01:   # הגוף השקוף (ערבוב רגיל, כדי שייראה גם על רקע בהיר)
		DrawBatch.set_transform_matrix(self, _xf())
		draw_body(self, _t, _swim, _jaw, 0.55 * _alpha, C_BODY, true)
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


# קו מתאר זוהר (באור המצטבר): מגדיר את הצורה של הרוח
static func draw_rim(ci: CanvasItem, t: float, a: float) -> void:
	var col := Color(C_RIM, a)
	var b := BODY.duplicate()
	b.append(BODY[0])
	var h := HEAD.duplicate()
	h.append(HEAD[0])
	for pass_i in 2:   # רחב וחלש (זוהר) + דק ובהיר
		var c2 := Color(C_RIM, a * (0.3 if pass_i == 0 else 0.75))
		DrawBatch.polyline(ci, b, c2, 6.0 if pass_i == 0 else 1.5)
		DrawBatch.polyline(ci, h, c2, 5.0 if pass_i == 0 else 1.4)
	var prev := _tail_pt(0.0, t)
	for i in range(1, 10):
		var u := float(i) / 9.0
		var p := _tail_pt(u, t)
		DrawBatch.line(ci, prev, p, Color(C_RIM, a * 0.6 * (1.0 - u)), 2.0)
		prev = p


func _draw_glow() -> void:
	DrawBatch.begin(_glow)
	var a := _alpha
	if a > 0.01:
		for i in range(_trail.size() - 1, -1, -1):   # עקבות: צלליות שנשארות מאחור ודוהות
			var tr: Array = _trail[i]
			var k := 1.0 - float(i + 1) / float(TRAIL_N + 1)
			DrawBatch.set_transform_matrix(_glow, tr[0])
			draw_body(_glow, _t, float(tr[2]), float(tr[1]), 0.07 * k * k * a, C_BODY, false)
		var xf := _xf()
		DrawBatch.set_transform_matrix(_glow, xf)
		DrawBatch.ellipse(_glow, Vector2(0.0, -1.0), 62.0, 24.0, Color(0.2, 1.0, 0.45, 0.045 * a))   # הילה
		DrawBatch.ellipse(_glow, Vector2(0.0, -2.0), 30.0, 5.0, Color(C_CORE, 0.12 * a))   # ליבה
		draw_rim(_glow, _t, 0.4 * a)
		DrawBatch.set_transform_matrix(_glow, Transform2D.IDENTITY)
		var ep := xf * Vector2(51.0, -11.0)   # עין
		DrawBatch.circle(_glow, ep, 7.0 * _grow, Color(0.5, 1.0, 0.65, 0.4 * a))
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
		DrawBatch.circle(_glow, p, r, Color(0.15, 0.95, 0.4, 0.16 * fa))
		DrawBatch.circle(_glow, p, r * 0.45, Color(0.6, 1.0, 0.7, 0.32 * fa * (1.0 - u)))
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
