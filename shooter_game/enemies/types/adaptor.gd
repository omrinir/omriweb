extends "res://enemies/zombie_type.gd"
# ============================================================
#  ADAPTOR (שלב 8 - "THEY ADAPT") - נבדק מעבדה שלומד את הנשק שלך.
#  צללית: גוף אנושי זקוף בחלוק בית-חולים קרוע, ראש קירח עם 3 אלקטרודות מתכת
#         וחוטים שמשתלשלים לגב. "שריון עצם" צומח עליו לפי מה שהוא למד.
#  למידה (הדרגתית והוגנת): הוא לא מסתכל רק על הנשק שביד עכשיו, אלא על PlayerMemory
#    (likes_close_range / likes_long_range / likes_spray) - מה שהשחקן עשה לאורך זמן.
#    כדי לשנות התנהגות הוא צריך "ללמוד" אותך: מד _study מתמלא כשהוא רואה אותך
#    (ומהר יותר כשאתה יורה לידו). בזמן הלמידה מופיע "?" מעל הראש, וברגע ההחלטה - "!".
#  מצבים (mode):
#    NONE  - זומבי רגיל (עיניים אפורות)
#    KEEP  - נגד שוטגאן: שומר מרחק ~250, נכנס רק כשאתה טוען / מסתובב.
#            לוחות עצם על החזה (פחות נזק מכדורי שוטגאן). עיניים ירוקות.
#    EVADE - נגד צלפים / נשק מדויק: זיגזג, עצירות פתאומיות, קפיצות קטנות, מתכופף
#            כשמכוונים אליו. מגן עצם על הפנים (ירייה בראש פחות קטלנית). עיניים תכלת.
#    RUSH  - נגד מרססים (SMG / רובה סער): מסתער נמוך ומהר ומזנק מקרוב.
#            כריות כתף משוריינות. עיניים כתומות.
#  התקפה: שריטה רגילה, וב-RUSH - זינוק.
#  צליל: "adapt_query" (צפצופים סקרניים עולים) כשהוא לומד, "adapt_learn" (קול יורד + צליל) כשהוא מחליט.
#  לשנות: STUDY_RATE / SHOT_STUDY (כמה מהר לומד), THRESH (כמה ברור צריך להיות הסגנון שלך).
# ============================================================

const SOUNDS := {
	"adapt_query": [["S", 900, 1500, 0.0, 0.09, 0.0, 30.0, 0.25, 1.0, 0], ["S", 1100, 1800, 0.12, 0.09, 0.0, 30.0, 0.22, 1.0, 0], ["C", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.4, 1.0, 0]],
	"adapt_learn": {"drive": 2.4, "layers": [["V", 260, 140, 0.0, 0.5, 0.01, 4.5, 0.7, 1.0, 0.04, 0, [640, 1500, 70]], ["S", 2200, 2200, 0.05, 0.08, 0.0, 25.0, 0.25, 1.0, 0], ["S", 2900, 2900, 0.16, 0.12, 0.0, 20.0, 0.25, 1.0, 0]]},
}

enum { NONE, KEEP, EVADE, RUSH }
const MODE_NAMES := ["?", "KEEP AWAY", "EVADE", "RUSH"]
const MODE_COLORS := [Color(0.75, 0.78, 0.8), Color(0.45, 1.0, 0.45), Color(0.4, 0.9, 1.0), Color(1.0, 0.55, 0.15)]
const STUDY_RATE := 0.16     # כמה למידה בשנייה כשהוא רואה אותך
const SHOT_STUDY := 0.07     # כמה למידה לכל ירייה שהוא רואה
const THRESH := 0.5          # מתחת לזה: "לא ברור" -> NONE

var mode := NONE
var _study := 0.0
var _target := NONE
var _q_t := 0.0              # כמה זמן ה-"?" מוצג
var _plates := 0.0           # כמה השריון "גדל" (0..1) - אנימציה
var _last_shots := 0
var _zig_t := 0.0
var _zig := 1.0
var _lunge_t := 0.0
var _leap_cd := 0.0
var _duck_cd := 0.0
var _read_t := 0.0
var _queried := false
var switches := 0            # לבדיקות: כמה פעמים שינה מצב


func stats() -> Dictionary:
	return {"name": "ADAPTOR", "hp": 34, "walk": 50.0, "chase": 118.0, "damage": 1, "bite_delay": 0.75, "scale": 1.0, "width": 0.92,
		"duck": 0.3, "cover": 0.35, "skin": Color("b4bcc2"), "shirt": Color("8fb2b8"), "pants": Color("4c5a64"), "shoe": Color(0, 0, 0, 0), "points": 260}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.0, "retreat_probability": 0.1}


func setup() -> void:
	_last_shots = PlayerMemory.shots_total


# מה השחקן "עושה" לפי הזיכרון ארוך-הטווח (לא רק הנשק שביד)
func read_player() -> int:
	var c := PlayerMemory.likes_close_range()
	var l := PlayerMemory.likes_long_range()
	var s := PlayerMemory.likes_spray()
	var best := maxf(c, maxf(l, s))
	if best < THRESH:
		return NONE
	if best == s:
		return RUSH
	if best == c:
		return KEEP
	return EVADE


# הלמידה רצה בכל פריים (גם כשהוא לא רודף) - זול: רק השוואות
func physics(pl: Node, delta: float) -> bool:
	_plates = move_toward(_plates, 1.0 if mode != NONE else 0.0, delta * 0.8)
	_q_t -= delta
	_read_t -= delta
	if pl == null or pl.dead or z.dead:
		return false
	if _read_t <= 0.0:
		_read_t = 0.5
		_target = read_player()
	var shots: int = PlayerMemory.shots_total
	var new_shots := shots - _last_shots
	_last_shots = shots
	var watching: bool = z.brain != null and z.brain.sees and z.global_position.distance_to(pl.global_position) < 700.0
	if not watching:
		return false
	if _target == mode:
		_study = maxf(_study - delta * 0.1, 0.0)
		return false
	_study += delta * STUDY_RATE + float(mini(new_shots, 4)) * SHOT_STUDY
	if _study > 0.3:
		_q_t = 0.3   # "?" מעל הראש: הוא מנתח אותך
		if not _queried:
			_queried = true
			Sfx.play("adapt_query", z.global_position, -4.0, 0.1, 2)
	if _study >= 1.0:
		_adapt(_target)
	return false


func _adapt(m: int) -> void:
	mode = m
	_study = 0.0
	_queried = false
	_plates = 0.0
	switches += 1
	Sfx.play("adapt_learn", z.global_position, 0.0, 0.1, 2)
	var mc: Color = MODE_COLORS[m]
	var dr := director()
	if dr != null:
		dr._signal(z.global_position + Vector2(0, -74.0 * z.sc), "!", mc)
	z._popup(MODE_NAMES[m] if m != NONE else "...", mc, 13, -96.0)


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_zig_t -= delta
	_lunge_t -= delta
	_leap_cd -= delta
	_duck_cd -= delta
	var dist := absf(d.x)
	var toward: float = signf(d.x) if d.x != 0.0 else z._dir
	var vuln: bool = pl.is_vulnerable()
	var facing_me: bool = signf(z.global_position.x - pl.global_position.x) == pl._face()
	match mode:
		KEEP:   # נגד שוטגאן: לא נכנס לטווח הקצר מלפנים
			if _lunge_t > 0.0:
				z._dir = toward
				return speed * 1.7
			if (vuln or not facing_me) and dist < 330.0 and dist > 40.0:
				_lunge_t = 1.1   # רגע פגיע / הגב אליו: נכנס!
				z._voice("zscream", 1.0, 2.0)
				z._dir = toward
				return speed * 1.7
			if dist < 210.0:
				z._dir = -toward
				return speed * 1.05
			if dist > 300.0:
				z._dir = toward
				return speed * 0.9
			z._dir = toward
			return 0.0
		EVADE:   # נגד צלף: זיגזג לא צפוי
			if _zig_t <= 0.0:
				_zig_t = randf_range(0.22, 0.55)
				var r := randf()
				_zig = 1.6 if r < 0.6 else (0.0 if r < 0.82 else -0.5)
				if z.is_on_floor() and randf() < 0.3 and dist > 120.0:
					z.velocity.y = z.jump_velocity * 0.55
			var aimed: bool = pl._aim.dot((z.global_position + Vector2(0, -30) - pl.global_position).normalized()) > 0.95
			if aimed and _duck_cd <= 0.0 and dist > 140.0 and randf() < 0.35:
				_duck_cd = 1.4
				z._duck_t = 0.4
			if dist < 70.0:
				z._dir = toward
				return speed
			z._dir = toward if _zig >= 0.0 else -toward
			return speed * absf(_zig)
		RUSH:   # נגד מרסס: הסתערות נמוכה וזינוק
			z._dir = toward
			if dist < 150.0 and dist > 50.0 and _leap_cd <= 0.0 and z.is_on_floor() and absf(d.y) < 60.0:
				_leap_cd = 2.2
				z.velocity.y = -380.0
				z.velocity.x = toward * 380.0
			return speed * 1.55
	return speed


# שריון העצם לפי המצב (מעט - הקושי מההתנהגות, לא מהחיים)
func damage_mult(zone: String, src: Dictionary) -> float:
	var k := _plates
	match mode:
		KEEP:
			if src.has("fixed") and zone != "head":   # כדורי שוטגאן על לוחות החזה
				return lerpf(1.0, 0.6, k)
		EVADE:
			if zone == "head":
				return lerpf(1.0, 0.6, k)
		RUSH:
			if zone == "body":
				return lerpf(1.0, 0.8, k)
	return 1.0


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var gown := col(z.shirt)
	var dark := col(Art.shade(z.skin, 0.3))
	var bone := col(Color("e4dcc8"))
	var eye: Color = MODE_COLORS[mode]
	var p: float = z._walk_phase
	var ck: float = 0.0 if z.dead else z._crouch_k
	var lean := 3.0
	var low := 0.0
	match mode:
		EVADE: low = 5.0
		RUSH:
			lean = 10.0
			low = 7.0
		KEEP: lean = 0.0
	low = maxf(low, 11.0 * ck)
	var f: Array = feet(6.0 if mode == RUSH else 5.0, 3.0)
	var hip := Vector2(0.0, -24.0 + low * 0.6 + absf(sin(p)) * 1.0)
	var sh := Vector2(lean, -41.0 + low)
	var head := sh + Vector2(2.5 + lean * 0.3, -9.0)
	# יד אחורית + רגליים
	var bh := sh + Vector2(13.0, 4.0 + sin(z._time * 3.0) * 1.5)
	var fh := sh + Vector2(16.0, 2.0 - sin(z._time * 3.0) * 1.5)
	if mode == KEEP:   # ידיים מורמות קדימה (שמירה)
		bh = sh + Vector2(12.0, -4.0)
		fh = sh + Vector2(14.0, -7.0)
	elif mode == RUSH:
		bh = sh + Vector2(-8.0 + sin(p) * 9.0, 12.0)
		fh = sh + Vector2(9.0 - sin(p) * 9.0, 10.0)
	if z._bite_anim > 0.0:
		fh = sh + Vector2(19.0, -2.0)
		bh = sh + Vector2(17.0, 0.0)
	z._arm(sh + Vector2(-2, 2), bh, dark, dark)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), dark, Color(0, 0, 0, 0))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, Color(0, 0, 0, 0))
	if mode == RUSH and _plates > 0.2:   # מגיני שוקיים
		for fp in [f[0], f[1]]:
			var fv: Vector2 = fp
			Art.fill(z, PackedVector2Array([fv + Vector2(1, -13), fv + Vector2(5, -12), fv + Vector2(4, -5), fv + Vector2(1, -6)]), col(Color("d8a070")), Art.OUTLINE, 0.8)
	# חלוק בית חולים (פתוח מאחור, קשרים)
	var body := PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(8, 4), hip + Vector2(4, 8), hip + Vector2(0, 5), hip + Vector2(-4, 9), hip + Vector2(-9, 4)])
	Art.fill_shaded(z, body, gown, 0.15, 0.35)
	for i in 3:   # הדפס נקודות על החלוק
		z.draw_circle(sh.lerp(hip, 0.25 + 0.25 * float(i)) + Vector2(2.0 - float(i), 1.0), 0.9, col(Color(0.35, 0.5, 0.55, 0.7)))
	z.draw_line(sh + Vector2(-8, 4), sh + Vector2(-11, 7), dark, 1.0)   # קשר
	z.draw_rect(Rect2(sh + Vector2(-3, 4), Vector2(6, 4)), col(Color(0.9, 0.9, 0.85)))   # תג נבדק
	z.draw_line(sh + Vector2(-2, 6), sh + Vector2(2, 6), Color(0.2, 0.2, 0.3), 0.8)
	# שריון שגדל לפי המצב
	if mode == KEEP and _plates > 0.0:   # לוחות עצם על החזה
		for i in 3:
			var c: Vector2 = sh.lerp(hip, 0.2 + 0.25 * float(i)) + Vector2(5.0, 0.0)
			var s := 4.5 * _plates
			Art.fill_shaded(z, PackedVector2Array([c + Vector2(-s, -s * 0.8), c + Vector2(s * 0.9, -s), c + Vector2(s, s * 0.6), c + Vector2(-s * 0.8, s * 0.8)]), bone, 0.2, 0.35, Art.OUTLINE, 1.0)
	if mode == RUSH and _plates > 0.0:   # כריות כתף עם קוצים
		var s2 := 6.0 * _plates
		Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -2), sh + Vector2(-1, -2 - s2), sh + Vector2(6, -3), sh + Vector2(7, 4), sh + Vector2(-5, 4)]), col(Color("d89a60")), 0.2, 0.35, Art.OUTLINE, 1.0)
		z.draw_line(sh + Vector2(0, -2 - s2 * 0.8), sh + Vector2(-3, -6 - s2), bone, 1.6)
	# צוואר + ראש קירח עם אלקטרודות
	Art.limb(z, PackedVector2Array([sh + Vector2(1, 0), head + Vector2(-1, 5)]), 4.5, dark)
	Art.oval_shaded(z, head, 6.2, 7.0, sk, 0.0)
	for i in 3:
		var ep := head + Vector2(-4.0 + float(i) * 3.5, -6.0 + absf(float(i) - 1.0) * 1.5)
		z.draw_line(ep, head + Vector2(-9.0 - float(i), 6.0 + float(i) * 3.0), col(Color(0.15, 0.15, 0.18)), 0.9)   # חוטים לגב
		Art.disc(z, ep, 1.4, col(Color("9aa4ae")), Art.OUTLINE, 0.8)
		if mode != NONE:
			z.draw_circle(ep, 0.7, Color(eye, 0.6 + 0.4 * sin(z._time * 9.0 + float(i))))
	z.draw_line(head + Vector2(-2, 3), head + Vector2(4, 3.5), Color(0.25, 0.05, 0.05), 1.1)   # פה
	# עיניים בצבע המצב
	for e in [Vector2(2.5, -1.0), Vector2(5.0, -0.5)]:
		var ev: Vector2 = e
		z.draw_circle(head + ev, 1.2, eye)
		if mode != NONE:
			Art.glow(z, head + ev, 3.2, Color(eye, 0.6))
	if mode == EVADE and _plates > 0.0:   # מגן עצם על הפנים עם חריץ
		var v := PackedVector2Array([head + Vector2(-2, -5.5), head + Vector2(6.5, -4.5 * _plates - 1.0), head + Vector2(7.0, 1.5), head + Vector2(-1, 1.0)])
		Art.fill_shaded(z, v, col(Color("bcc4c0")), 0.2, 0.4, Art.OUTLINE, 1.0)
		z.draw_line(head + Vector2(0, -1.2), head + Vector2(6.5, -1.0), Color(eye, 0.9), 1.2)
	# יד קדמית
	z._arm(sh + Vector2(2.5, 2), fh, sk, gown)
	if mode == KEEP and _plates > 0.3:   # מגן עצם על האמה
		var mid := (sh + fh) * 0.5 + Vector2(4.0, 0.0)
		Art.fill(z, PackedVector2Array([mid + Vector2(-3, -3), mid + Vector2(4, -4), mid + Vector2(4, 2), mid + Vector2(-3, 2)]), bone, Art.OUTLINE, 0.9)
	end_draw()
	# "?" בזמן למידה (מעל הראש, בלי היפוך)
	if _q_t > 0.0 and not z.dead:
		var fnt := ThemeDB.fallback_font
		var tc: Color = MODE_COLORS[_target]
		var a := 0.6 + 0.4 * sin(z._time * 10.0)
		var qp := Vector2(-5.0, -78.0 * z.sc - 4.0 * sin(z._time * 4.0))
		z.draw_string_outline(fnt, qp, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 4, Color(0, 0, 0, 0.8 * a))
		z.draw_string(fnt, qp, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(tc, a))
		var w := 20.0 * clampf(_study, 0.0, 1.0)   # מד הלמידה
		z.draw_rect(Rect2(Vector2(-10.0, -70.0 * z.sc), Vector2(20.0, 3.0)), Color(0, 0, 0, 0.6))
		z.draw_rect(Rect2(Vector2(-10.0, -70.0 * z.sc), Vector2(w, 3.0)), Color(tc, 0.9))
	return true
