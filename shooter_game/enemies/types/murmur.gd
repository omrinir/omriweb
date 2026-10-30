extends "res://enemies/zombie_type.gd"
# ============================================================
#  MURMUR (שלב 57, "PENGUIN COAST") - להקה של ציפורים מתות (קורמורנים קיסריים שחור-לבן, שחפי אצות, חמסנים חומים)
#    שעפות יחד בצורה של אדם: ראש, כתפיים, ידיים מושטות עם טפרים, רגליים. ציפור אחת אדומה וזוהרת בחזה = הלב.
#    חוטי נבגים ירוקים חיוורים מחברים את כל הציפורים ללב.
#  מה הוא למד, וממה: גוף אחד אפשר לירות (THE ARCHITECT מת בשלב 54 וזה לא שינה כלום) - אז המתים הפסיקו להזדקק לגוף אחד.
#    MURMUR הוא "אדם" שעשוי מהרבה.
#  איך הוא עובד:
#    GATHER - ענן ציפורים מסתחרר גבוה בשמיים. כשאתה מתקרב (WAKE_R) הוא מתכנס (FORM) לצורת אדם.
#    DRIFT  - מרחף מעליך (HOVER_H) בצד (SIDE_OFF), מחליף צד אחרי כל צלילה.
#    WIND   - הצורה מתכווצת לכף יד עם טפרים שמצביעה עליך, הלב בוער, צווחה (WIND_T) - הסימן.
#    SWOOP  - צולל דרכך בקשת (SWOOP_T) ועולה בצד השני. נוגע = RAKE_DMG. תמיד יורד לתקוף תוך SWOOP_CD שניות.
#  פגיעה: כל קליע פוגע בציפור אחת (קרן מהנקודה שהקליע נכנס) - היא נופלת מתה עם נוצות ודם, והצורה מתארגנת מחדש קטנה יותר.
#    קליע שעובר ברווח בין הציפורים ממשיך הלאה (pierce). כל BIRD_HP נזק = ציפור. כשנשארות פחות מ-BREAK_FRAC - הלהקה נשברת
#    (חצי נופלות, חצי בורחות לשמיים) = מת. הלב: פגיעה בציפור האדומה = נזק x HEART_MULT, הלהקה נרתעת, ואחרי HEART_HITS
#    לבבות הלהקה נשברת מיד. פיצוץ = נזק x BLAST_MULT ותולש נתח שלם מהצד של הפיצוץ. אש: ציפורים בוערות נושרות.
#  נגד: לירות בלב כשהוא מתכווץ לפני הצלילה (הוא הכי צפוף), לקפוץ / להתגלגל מתחת לצלילה, רימון כשהוא נמוך.
#  לומד (main meta "mm_breaks" >= LEARN_BREAKS להקות שנשברו):
#    "IT SPLITS NOW" - פגיעה כבדה (פיצוץ / לב / SPLIT_DMG+) כשיש לו SPLIT_MIN ציפורים: הלהקה מתפצלת לשתי להקות קטנות
#      שתוקפות משני הצדדים (פעם אחת). "IT FEINTS NOW" - לפעמים (FEINT_CHANCE) צולל חצי דרך, עולה, ואז צולל באמת.
#  ביצועים: אין צומת לכל ציפור - כל הלהקה = מערך משולשים אחד (RenderingServer.canvas_item_add_triangle_array),
#    ציפורים נופלות / נוצות / בורחות = צומת FX אחד לכל השלב (MurmurFX, עד CAP). עד TOTAL_MAX ציפורים בכל הלהקות יחד.
#  לשנות: N_BIRDS, N_MIN, TOTAL_MAX, BIRD_HP, BREAK_FRAC, HOVER_H, SIDE_OFF, WAKE_R, FLY_V, WIND_T, SWOOP_T, SWOOP_CD,
#         RAKE_DMG, HEART_MULT, HEART_HITS, BLAST_MULT, SPLIT_*, FEINT_CHANCE, LEARN_BREAKS, BIRD_S.
# ============================================================

const SOUNDS := {
	"mm_flock": {"rev": 0.35, "layers": [["N", 0, 0, 0.0, 0.9, 0.12, 2.5, 0.45, 0.3, 0, 0.2], ["S", 2400, 2900, 0.0, 0.06, 0.005, 30.0, 0.16, 1.0, 0.0], ["S", 2900, 2500, 0.11, 0.06, 0.005, 30.0, 0.14, 1.0, 0.0], ["S", 2100, 2700, 0.2, 0.07, 0.005, 26.0, 0.15, 1.0, 0.0], ["S", 3100, 2600, 0.31, 0.05, 0.005, 34.0, 0.12, 1.0, 0.0], ["S", 2600, 3200, 0.45, 0.05, 0.005, 34.0, 0.1, 1.0, 0.0]]},
	"mm_scream": {"drive": 2.2, "layers": [["V", 700, 1150, 0.0, 0.5, 0.04, 3.0, 0.55, 1.0, 0.09, 0, [1500, 3000, 50]], ["S", 2600, 3300, 0.0, 0.4, 0.02, 4.0, 0.18, 1.0, 0.12], ["N", 0, 0, 0.0, 0.5, 0.05, 3.0, 0.3, 0.45, 0, 0.3]]},
	"mm_swoop": {"rev": 0.25, "layers": [["N", 0, 0, 0.0, 0.9, 0.35, 2.4, 0.85, 0.22, 0, 0.05], ["N", 0, 0, 0.2, 0.6, 0.2, 3.0, 0.35, 0.6, 0, 0.35], ["S", 2800, 1900, 0.1, 0.4, 0.05, 4.0, 0.12, 1.0, 0.1]]},
	"mm_scatter": {"rev": 0.3, "layers": [["N", 0, 0, 0.0, 0.8, 0.0, 4.0, 0.8, 0.4, 0, 0.25], ["S", 2500, 3100, 0.0, 0.06, 0.0, 30.0, 0.2, 1.0, 0], ["S", 3000, 2400, 0.08, 0.06, 0.0, 30.0, 0.18, 1.0, 0], ["S", 2200, 2900, 0.15, 0.06, 0.0, 30.0, 0.16, 1.0, 0], ["S", 2700, 3300, 0.24, 0.06, 0.0, 30.0, 0.14, 1.0, 0]]},
	"mm_heart": {"drive": 2.0, "layers": [["S", 150, 55, 0.0, 0.3, 0.0, 10.0, 0.9, 1.0, 0], ["V", 900, 1500, 0.0, 0.35, 0.01, 6.0, 0.5, 1.0, 0.05, 0, [1800, 3200, 60]], ["N", 0, 0, 0.0, 0.2, 0.0, 14.0, 0.4, 0.3, 0]]},
	"mm_thud": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.35, 0.2, 0], ["S", 240, 120, 0.0, 0.06, 0.0, 45.0, 0.25, 1.0, 0]],
}

const N_BIRDS := 52
const N_MIN := 34
const TOTAL_MAX := 240
const BIRD_HP := 7
const BREAK_FRAC := 0.38
const OFF := 32.0                 # z.global_position = מרכז הלהקה + (0, OFF) (פיצוצים פוגעים ב-(0,-32))
const HOVER_H := 185.0
const SIDE_OFF := 220.0
const WAKE_R := 820.0
const FLY_V := 300.0
const WIND_T := 0.55
const SWOOP_T := 1.0
const SWOOP_CD := Vector2(1.4, 2.6)
const FIRST_CD := 2.2
const RAKE_DMG := 1
const RAKE_R := Vector2(34.0, 46.0)
const HEART_MULT := 3.0
const HEART_HITS := 3
const HEART_BACK := 1.1
const HEAD_MULT := 0.45            # "ראש" / "רגל" לא אומרים כלום בלהקה: מנרמלים
const LEG_MULT := 1.5
const BLAST_MULT := 2.0
const SPLIT_DMG := 26
const SPLIT_MIN := 26
const FEINT_CHANCE := 0.45
const LEARN_BREAKS := 2
const BIRD_R := 10.0               # כמה קרוב הקליע צריך לעבור מציפור
const HEART_R := 9.0               # ...ומהלב (הלב קודם לציפורים שמסביבו)
const BIRD_S := 1.3
const SCALE := 1.5

enum {GATHER, FORM, DRIFT, WIND, SWOOP, FEINT, REFORM}
var state := GATHER
# לבדיקות
var birds_hit := 0
var heart_hits := 0
var swoops := 0
var rakes := 0
var feints := 0
var splits := 0
var formed := 0
var chunk_kills := 0
var misses := 0
var reforms := 0

var learned := false
var n0 := N_BIRDS
var n_alive := 0
var break_n := 12
var heart := -1
var center := Vector2.ZERO
var bp := PackedVector2Array()
var bv := PackedVector2Array()
var ok := PackedByteArray()
var bh := PackedFloat32Array()
var _ground := 630.0
var _st := 0.0
var _cd := FIRST_CD
var _t := 0.0
var _side := 1.0
var _face := 1.0
var _heart_t := 0.0
var _heart_flag := false
var _pending: Array = []
var _claw_k := 0.0
var _form_k := 0.0
var _claw_rot := 0.0
var _sw := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _feint := false
var _hit := false
var _split_done := false
var _prev_c := Vector2.ZERO
var _flinch := 0.0
var _hv := 0.5                  # לכל להקה גובה / מרחק ריחוף משלה
var _flash_lp := Vector2.ZERO   # רק הציפורים ליד הפגיעה מהבהבות (לא כל הלהקה)

static var TM := PackedVector2Array()   # תבנית "אדם" (פונה ימינה, 0 = מרכז החזה)
static var TC := PackedVector2Array()   # תבנית "כף יד עם טפרים" (מצביעה ימינה)
const HEART_P := Vector2(3.0, -20.0)


func stats() -> Dictionary:
	return {"name": "MURMUR", "hp": 200, "walk": 60.0, "chase": 120.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("3a3c44"), "shirt": Color("1a1c24"), "pants": Color("1a1c24"), "shoe": Color("1a1c24"),
		"points": 420, "ragdoll": false, "flesh": false}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func death_sound() -> String:
	return "mm_scatter"


func _main() -> Node:
	return z.get_parent()


static func _templates() -> void:
	if not TM.is_empty():
		return
	# לפי חשיבות: קודם השלד (ראש, כתפיים, ידיים, טפרים, ירכיים, ברכיים, כפות), אחר כך מילוי. ציפור במקום k = נקודה k,
	# אז להקה קטנה (אחרי פגיעות) עדיין נראית כמו אדם - רק דליל יותר
	var m := PackedVector2Array([
		Vector2(5, -48), Vector2(5, -57), Vector2(13, -48), Vector2(-3, -47), Vector2(2, -38),
		Vector2(-9, -33), Vector2(11, -33), Vector2(25, -35), Vector2(40, -39), Vector2(48, -44), Vector2(51, -36), Vector2(46, -29),
		Vector2(-15, -20), Vector2(-17, -6), Vector2(0, -26), Vector2(0, -13), Vector2(-7, 4), Vector2(7, 4),
		Vector2(12, 24), Vector2(17, 44), Vector2(24, 46), Vector2(-10, 24), Vector2(-15, 44), Vector2(-8, 46),
		Vector2(-1, -54), Vector2(11, -54), Vector2(-1, -42), Vector2(11, -42), Vector2(-8, -24), Vector2(8, -24),
		Vector2(-7, -10), Vector2(7, -10), Vector2(18, -34), Vector2(32, -38), Vector2(-13, -27), Vector2(-17, -13),
		Vector2(9, 14), Vector2(15, 34), Vector2(-8, 14), Vector2(-13, 34),
		Vector2(-4, -31), Vector2(5, -31), Vector2(-4, -19), Vector2(5, -19), Vector2(-4, -5), Vector2(5, -5), Vector2(0, -1),
		Vector2(-3, -41), Vector2(8, -41), Vector2(-11, -16), Vector2(11, -16), Vector2(-4, -35), Vector2(6, -35), Vector2(0, 7),
		Vector2(0, -20)])
	TM = m
	var c := PackedVector2Array()
	for row in 3:   # כף
		for col in 4:
			c.append(Vector2(-10.0 + float(col) * 7.0, -9.0 + float(row) * 9.0))
	for f in 4:   # ארבע אצבעות מעוקלות
		var fy := -21.0 + float(f) * 14.0
		for q in 5:
			var k := float(q + 1) / 5.0
			c.append(Vector2(14.0 + k * 38.0, fy * (1.0 + k * 0.15) + k * k * 12.0))
	for q in 4:   # אגודל
		c.append(Vector2(2.0 + float(q) * 6.0, 16.0 + float(q) * 3.5))
	for q in 8:   # שובל
		c.append(Vector2(-16.0 - float(q) * 6.0, sin(float(q) * 1.3) * (4.0 + float(q))))
	TC = c


func setup() -> void:
	_templates()
	var m := _main()
	learned = m != null and int(m.get_meta("mm_breaks", 0)) >= LEARN_BREAKS
	var total := 0
	for o in z.get_tree().get_nodes_in_group("s57_murmurs"):
		if o != z and not o.dead and o.type_mod != null:
			total += int(o.type_mod.n_alive)
	z.add_to_group("s57_murmurs")
	n0 = clampi(TOTAL_MAX - total, N_MIN, N_BIRDS)
	var r := RandomNumberGenerator.new()
	r.seed = z.get_instance_id()
	_ground = z.global_position.y
	center = z.global_position + Vector2(r.randf_range(-60.0, 60.0), -HOVER_H - 130.0)
	_prev_c = center
	bp.resize(n0)
	bv.resize(n0)
	ok.resize(n0)
	bh.resize(n0)
	for i in n0:
		var a := r.randf() * TAU
		bp[i] = Vector2(cos(a), sin(a) * 0.5) * r.randf_range(10.0, 90.0)
		bv[i] = Vector2.ZERO
		ok[i] = 1
		bh[i] = r.randf()
	n_alive = n0
	_reset_hp()
	heart = 0
	_side = -1.0 if r.randf() < 0.5 else 1.0
	_hv = r.randf()
	z.global_position = center + Vector2(0.0, OFF)
	_fit_shape()


func _reset_hp() -> void:
	break_n = maxi(4 if _split_done else 5, int(round(float(n_alive) * BREAK_FRAC)))
	z.hp = maxi(1, (n_alive - break_n + 1) * BIRD_HP)
	z.max_hp = z.hp


# (מתפצל) הלהקה השנייה מקבלת חצי מהציפורים
func adopt(world: PackedVector2Array, vel: PackedVector2Array, side: float) -> void:
	var n := world.size()
	if n == 0:
		return
	var c := Vector2.ZERO
	for p in world:
		c += p
	c /= float(n)
	center = c
	_prev_c = c
	n0 = n
	bp.resize(n)
	bv.resize(n)
	ok.resize(n)
	bh.resize(n)
	for i in n:
		bp[i] = world[i] - c
		bv[i] = vel[i]
		ok[i] = 1
		bh[i] = randf()
	n_alive = n
	_split_done = true
	learned = true
	_reset_hp()
	heart = 0
	_heart_t = 0.0
	state = DRIFT
	_form_k = 1.0
	_side = side
	_cd = 1.0
	z.global_position = center + Vector2(0.0, OFF)
	_fit_shape()


# ============================================================
#  תנועה
# ============================================================
func physics(pl: Node, delta: float) -> bool:
	_t += delta
	_st -= delta
	_cd -= delta
	_heart_t -= delta
	_flinch = maxf(0.0, _flinch - delta)
	_sync()
	if n_alive <= 0:
		return true
	var has: bool = pl != null and not pl.dead
	var pp: Vector2 = pl.global_position if has else center + Vector2(0.0, HOVER_H)
	var d: Vector2 = pp - center
	match state:
		GATHER:
			center.x += sin(_t * 0.35 + bh[0] * 6.0) * 26.0 * delta
			center.y += cos(_t * 0.5) * 8.0 * delta
			if has and absf(d.x) < WAKE_R and absf(d.y) < 600.0:
				state = FORM
				formed += 1
				_st = 1.1
				_cd = FIRST_CD
				Sfx.play("mm_flock", center, 2.0, 0.1, 2)
				var m := _main()
				if m != null and not m.has_meta("mm_seen") and pl.has_method("_say"):
					m.set_meta("mm_seen", true)
					pl._say("The birds... they're making a man.", Color("c8d8e8"))
		FORM:
			_hover(pp, delta, 0.5)
			if _st <= 0.0:
				state = DRIFT
		DRIFT, REFORM:
			_hover(pp, delta, 1.0)
			if state == REFORM and _st <= 0.0:
				state = DRIFT
			if state == DRIFT and _cd <= 0.0 and has and absf(d.x) < 760.0:
				_start_wind(pp)
		WIND:
			center += (center - pp).normalized() * 46.0 * delta
			_claw_rot = lerp_angle(_claw_rot, (pp + Vector2(0.0, -48.0) - center).angle(), 1.0 - exp(-10.0 * delta))
			if _st <= 0.0:
				_start_swoop(pp)
		SWOOP:
			var u := clampf(1.0 - _st / SWOOP_T, 0.0, 1.0)
			var e := u * u * (3.0 - 2.0 * u) * 0.35 + u * 0.65
			var a: Vector2 = _sw[0]
			var b: Vector2 = _sw[1]
			var c: Vector2 = _sw[2]
			var np: Vector2 = a.lerp(b, e).lerp(b.lerp(c, e), e)
			var vel := np - center
			if vel.length() > 0.5:
				_claw_rot = lerp_angle(_claw_rot, vel.angle(), 1.0 - exp(-12.0 * delta))
				_face = signf(vel.x) if absf(vel.x) > 0.1 else _face
			center = np
			if has and not _hit:
				var r := Rect2(center - RAKE_R, RAKE_R * 2.0)
				if r.intersects(pl.body_rect()):
					_hit = true
					if pl._roll_t <= 0.0:
						rakes += 1
					pl.hurt(RAKE_DMG, Vector2(signf(vel.x) * 0.9, -0.35))
					FX.of(_main()).feathers(center, 5, Color("2a2c34"))
			if _feint and u >= 0.32:
				state = FEINT
				feints += 1
				_st = 0.35
				var m := _main()
				if m != null and not m.has_meta("mm_feint_said"):
					m.set_meta("mm_feint_said", true)
					z._popup("IT FEINTS NOW", Color("ff8a7a"), 12, -150.0)
			elif _st <= 0.0:
				state = DRIFT
				_side = signf(center.x - pp.x) if absf(center.x - pp.x) > 20.0 else -_side
				_cd = randf_range(SWOOP_CD.x, SWOOP_CD.y)
		FEINT:   # עולה בחזרה ומיד צולל באמת
			center = center.lerp(_sw[0] + Vector2(0.0, -20.0), 1.0 - exp(-7.0 * delta))
			if _st <= 0.0:
				_feint = false
				_start_wind(pp, 0.22)
	if center.y > _ground - 48.0:
		center.y = _ground - 48.0
	center.x = clampf(center.x, 40.0, z.world_w - 40.0)
	_face = signf(d.x) if state in [DRIFT, FORM, REFORM, WIND] and absf(d.x) > 8.0 else _face
	_birds(delta)
	z.velocity = (center + Vector2(0.0, OFF) - z.global_position) / maxf(delta, 0.001)   # (רק מדווח - הלהקה לא זזה ב-move_and_slide)
	z.global_position = center + Vector2(0.0, OFF)
	z._dir = _face
	_fit_shape()
	if Art.on_screen(z, center, 200.0):
		z.queue_redraw()
	return true


func _hover(pp: Vector2, delta: float, k: float) -> void:
	var hv: float = _hv
	var tgt := pp + Vector2(_side * SIDE_OFF * (0.8 + 0.5 * hv), -HOVER_H * (0.85 + 0.35 * hv) + sin(_t * 1.3 + hv * 5.0) * 18.0)
	for o in z.get_tree().get_nodes_in_group("s57_murmurs"):   # שתי להקות לא מתמזגות לגוש אחד
		if o != z and not o.dead and o.type_mod != null:
			var dd: Vector2 = center - o.type_mod.center
			if dd.length_squared() < 170.0 * 170.0:
				tgt += (dd.normalized() if dd != Vector2.ZERO else Vector2.RIGHT) * 170.0
	tgt.y = minf(tgt.y, _ground - 150.0)
	var dv := tgt - center
	var sp := FLY_V * k * clampf(dv.length() / 120.0, 0.25, 1.0)
	center += dv.limit_length(sp * delta)


func _start_wind(pp: Vector2, t := WIND_T) -> void:
	state = WIND
	_st = t
	_claw_rot = (pp + Vector2(0.0, -48.0) - center).angle()
	if t >= WIND_T:
		Sfx.play("mm_scream", center, 1.0, 0.1, 2)


func _start_swoop(pp: Vector2) -> void:
	state = SWOOP
	swoops += 1
	_st = SWOOP_T
	_hit = false
	var p := pp + Vector2(0.0, -48.0)
	var s := center
	var e := Vector2(p.x + (p.x - s.x), s.y - 20.0)
	_sw = [s, p * 2.0 - (s + e) * 0.5, e]
	_feint = learned and randf() < FEINT_CHANCE
	Sfx.play("mm_swoop", center, 2.0, 0.1, 2)


# הציפורים רודפות אחרי המקום שלהן בצורה (קפיץ + טלטול). המרכז זז -> הציפורים נגררות מאחור (שובל)
func _birds(delta: float) -> void:
	var dc := center - _prev_c
	_prev_c = center
	var claw := state in [WIND, SWOOP, FEINT]
	_claw_k = move_toward(_claw_k, 1.0 if claw else 0.0, delta * (5.0 if claw else 2.5))
	_form_k = move_toward(_form_k, 0.0 if state == GATHER else 1.0, delta * 1.2)
	var sc := SCALE * clampf(sqrt(float(n_alive) / float(maxi(n0, 1))), 0.62, 1.0)
	var m := n_alive - (1 if heart >= 0 and ok[heart] == 1 else 0)
	var kk := 60.0 if _flinch <= 0.0 else 10.0
	var damp := exp(-9.0 * delta)
	var rk := 0
	var cr := cos(_claw_rot)
	var sr := sin(_claw_rot)
	for i in bp.size():
		if ok[i] == 0:
			continue
		var h: float = bh[i]
		var tgt: Vector2
		if i == heart:
			tgt = Vector2(HEART_P.x * _face, HEART_P.y) * sc
			tgt = tgt.lerp(Vector2(-6.0 * cr, -6.0 * sr), _claw_k)
		else:
			var f := float(rk) / float(maxi(m, 1))
			var pm: Vector2 = TM[rk % TM.size()]
			rk += 1
			pm = Vector2(pm.x * _face, pm.y) * sc
			var pc: Vector2 = TC[int(f * float(TC.size())) % TC.size()] * sc
			pc = Vector2(pc.x * cr - pc.y * sr, pc.x * sr + pc.y * cr)
			tgt = pm.lerp(pc, _claw_k)
		if _form_k < 1.0:   # ענן מסתחרר (מורמורציה)
			var a := h * TAU + _t * (0.5 + h * 0.6)
			var rr := 25.0 + 70.0 * fposmod(h * 7.31, 1.0)
			var blob := Vector2(cos(a) * rr, sin(a * 1.3) * rr * 0.45) + Vector2(sin(_t * 0.7 + h) * 40.0, 0.0)
			tgt = blob.lerp(tgt, _form_k * _form_k)
		tgt += Vector2(sin(_t * 3.1 + float(i) * 1.7), cos(_t * 2.7 + float(i) * 2.3)) * 2.2
		var v: Vector2 = bv[i]
		v += (tgt - bp[i]) * kk * delta
		v *= damp
		bv[i] = v
		var p: Vector2 = bp[i] + v * delta - dc * (0.15 + 0.35 * h)
		if center.y + p.y > _ground - 4.0:
			p.y = _ground - 4.0 - center.y
		bp[i] = p


func _fit_shape() -> void:
	if n_alive <= 0:
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in bp.size():
		if ok[i] == 1:
			lo = Vector2(minf(lo.x, bp[i].x), minf(lo.y, bp[i].y))
			hi = Vector2(maxf(hi.x, bp[i].x), maxf(hi.y, bp[i].y))
	lo -= Vector2(7.0, 7.0)
	hi += Vector2(7.0, 7.0)
	var rs := z._shape.shape as RectangleShape2D
	rs.size = Vector2(maxf(hi.x - lo.x, 20.0), maxf(hi.y - lo.y, 20.0))
	z._shape.position = (lo + hi) * 0.5 + Vector2(0.0, -OFF)


# ============================================================
#  נזק: כל פגיעה = ציפור
# ============================================================
func _alive_idx() -> Array:
	var a := []
	for i in bp.size():
		if ok[i] == 1:
			a.append(i)
	return a


func _nearest(lp: Vector2) -> int:
	var best := -1
	var bd := INF
	for i in bp.size():
		if ok[i] == 1:
			var dd := bp[i].distance_squared_to(lp)
			if dd < bd:
				bd = dd
				best = i
	return best


# הציפור הראשונה שהקרן (מנקודת הכניסה, בכיוון הקליע) עוברת לידה
func _ray_bird(lp: Vector2, dir: Vector2) -> int:
	if dir == Vector2.ZERO:
		return _nearest(lp)
	if heart >= 0 and ok[heart] == 1:   # הלב קודם: קליע שמכוון אליו פוגע בו גם דרך הציפורים שמסביב
		var hr: Vector2 = bp[heart] - lp
		if hr.dot(dir) > -HEART_R and absf(hr.cross(dir)) < HEART_R:
			return heart
	var best := -1
	var ba := INF
	for i in bp.size():
		if ok[i] == 0:
			continue
		var rel: Vector2 = bp[i] - lp
		var along := rel.dot(dir)
		if along < -BIRD_R:
			continue
		var r := BIRD_R
		if absf(rel.cross(dir)) < r and along < ba:
			ba = along
			best = i
	return best


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if z.dead or n_alive <= 0:
		return true
	var s := str(src.get("source", "bullet"))
	var lp := hit_pos - center
	_flash_lp = lp
	_heart_flag = false
	var heavy := false
	if s == "bullet":
		var bi := _ray_bird(lp, dir)
		if bi < 0:   # עבר ברווח בין הציפורים: הקליע ממשיך
			misses += 1
			var b = instance_from_id(int(src.get("bullet", 0))) if int(src.get("bullet", 0)) != 0 else null
			if b != null and is_instance_valid(b) and b.get("pierce") != null:
				b.pierce += 1
			return false
		_pending.append([bi, bp[bi]])
		if bi == heart:
			_heart_flag = true
		heavy = hit_damage(amount, hit_pos, src) >= SPLIT_DMG
	elif s == "melee" or s == "taser" or s == "laser":
		var bi := _nearest(lp)
		_pending.append([bi, bp[bi] if bi >= 0 else lp])
		if bi == heart and bi >= 0:
			_heart_flag = true
	elif s == "fire":
		_pending.append([-1, bp[_alive_idx().pick_random()]])
	else:   # פיצוץ: נתח מהצד של הפיצוץ, והשאר נרתעות
		var bpos := -dir * 40.0 if dir != Vector2.ZERO else lp
		_pending.append([-1, bpos])
		heavy = true
		_flinch = 0.5
		for i in bp.size():
			if ok[i] == 1:
				var rel: Vector2 = bp[i] - bpos
				bv[i] += rel.normalized() * maxf(0.0, 340.0 - rel.length() * 2.0)
		if state != SWOOP:
			state = REFORM
			reforms += 1
			_st = 0.6
	if _heart_flag:
		heart_hits += 1
		heavy = true
		Sfx.play("mm_heart", hit_pos, 2.0, 0.05, 2)
		z._popup("HEART %d/%d" % [mini(heart_hits, HEART_HITS), HEART_HITS], Color("ff5050"), 15, -140.0)
		_flinch = 0.7
		for i in bp.size():
			if ok[i] == 1:
				bv[i] += bp[i].normalized() * randf_range(160.0, 260.0)
		if state != SWOOP:
			state = REFORM
			reforms += 1
			_st = 0.7
	if learned and heavy and not _split_done and n_alive >= SPLIT_MIN and heart_hits < HEART_HITS:
		_split_done = true
		call_deferred("_split", dir)
	return true


func damage_mult(zone: String, src: Dictionary) -> float:
	var s := str(src.get("source", "bullet"))
	var m := 1.0
	if s == "bullet" or s == "melee":
		if zone == "head":
			m = HEAD_MULT
		elif zone == "leg":
			m = LEG_MULT
	elif s != "fire" and s != "taser" and s != "laser":
		m = BLAST_MULT
	if _heart_flag:
		_heart_flag = false
		m *= HEART_MULT
	if heart_hits >= HEART_HITS:
		m = 99.0
	return m


func _sync() -> void:
	if z.dead or n_alive <= 0:
		_pending.clear()
		return
	var target := break_n - 1 + int(ceil(float(maxi(z.hp, 0)) / float(BIRD_HP)))
	var guard := 0
	while n_alive > target and n_alive > 0 and guard < 80:
		guard += 1
		var idx := -1
		var near := Vector2.ZERO
		if not _pending.is_empty():
			var pe: Array = _pending[0]
			idx = int(pe[0])
			near = pe[1]
			pe[0] = -1
			if idx < 0 or ok[idx] == 0:
				idx = _nearest(near)
		else:
			idx = _alive_idx().pick_random()
		if idx < 0:
			break
		_kill_bird(idx, bv[idx] * 0.4 + (bp[idx] - near).normalized() * 120.0)
	_pending.clear()
	if (heart < 0 or ok[heart] == 0) and _heart_t <= 0.0 and n_alive > 0:   # לב חדש
		heart = _nearest(Vector2(HEART_P.x * _face, HEART_P.y))


func _kill_bird(i: int, push: Vector2) -> void:
	ok[i] = 0
	n_alive -= 1
	birds_hit += 1
	if i == heart:
		heart = -1
		_heart_t = HEART_BACK
	var w := center + bp[i]
	var fx := FX.of(_main())
	if fx != null:
		fx.dead_bird(w, push + Vector2(randf_range(-40.0, 40.0), -80.0), bh[i], z._burn_t > 0.0, i == heart)
		fx.feathers(w, 2 + int(2.0 * Quality.gore()), FX.wing(bh[i]))
	if Art.on_screen(z, w):
		Particles.burst(_main(), w, "hit", Vector2.UP, int(4.0 * Quality.gore()) + 1)
		Sfx.play("mm_thud", w, -6.0, 0.2, 3)


func _split(dir: Vector2) -> void:
	if z.dead:
		return
	_sync()   # קודם הציפורים שהפגיעה הזו הפילה
	var m := _main()
	if n_alive < 8 or m == null or not m.has_method("_spawn_zombie"):
		return
	var a := _alive_idx()
	a.sort_custom(func(p, q): return bp[p].x < bp[q].x)
	var half: Array = a.slice(0, a.size() / 2) if dir.x > 0.0 else a.slice(a.size() / 2)
	if heart in half:
		half.erase(heart)
	var wp := PackedVector2Array()
	var wv := PackedVector2Array()
	for i in half:
		wp.append(center + bp[i])
		wv.append(bv[i] + Vector2(-signf(dir.x + 0.01) * 200.0, -120.0))
	var c2 = m._spawn_zombie(center.x, _ground, z.kind)
	if c2 == null or c2.type_mod == null:
		return
	c2.dormant = false
	c2.type_mod.adopt(wp, wv, -_side)
	for i in half:
		ok[i] = 0
	n_alive -= half.size()
	splits += 1
	_reset_hp()
	z.max_hp = maxi(z.max_hp, z.hp)
	_flinch = 0.5
	Sfx.play("mm_scatter", center, 3.0, 0.05, 2)
	if not m.has_meta("mm_split_said"):
		m.set_meta("mm_split_said", true)
		z._popup("IT SPLITS NOW", Color("ff8a7a"), 13, -150.0)


func on_death() -> void:
	var m := _main()
	if m != null:
		m.set_meta("mm_breaks", int(m.get_meta("mm_breaks", 0)) + 1)
	var fx := FX.of(m)
	for i in bp.size():
		if ok[i] == 0:
			continue
		var w := center + bp[i]
		if fx != null:
			if i == heart or randf() < 0.5:
				fx.dead_bird(w, bv[i] * 0.5 + bp[i].normalized() * randf_range(60.0, 220.0) + Vector2(0.0, -120.0), bh[i], z._burn_t > 0.0, i == heart)
			else:
				fx.flee_bird(w, bp[i].normalized() * randf_range(140.0, 260.0) + Vector2(0.0, -220.0), bh[i])
		ok[i] = 0
	if fx != null:
		fx.feathers(center, int(14.0 * Quality.gore()) + 4, Color("2a2c34"))
		fx.feathers(center, int(6.0 * Quality.gore()) + 2, Color("e8e6e0"))
	n_alive = 0
	heart = -1
	Particles.burst(m, center, "hit", Vector2.UP, int(16.0 * Quality.gore()))
	z._popup("THE FLOCK BREAKS", Color("c8d8e8"), 14, -120.0)
	var cam: Camera2D = z.get_viewport().get_camera_2d()
	if cam != null and cam.has_method("shake") and Art.on_screen(z, center):
		cam.shake(6.0, 0.25)


func wants_redraw() -> bool:
	return true


# ============================================================
#  ציור: כל הלהקה במערך משולשים אחד
# ============================================================
func draw() -> bool:
	if z.dead or n_alive <= 0:
		return true
	DrawBatch.set_transform_matrix(z, Transform2D.IDENTITY)
	var o := Vector2(0.0, -OFF)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var flash: bool = z._flash > 0.0
	var hp_heart := heart >= 0 and ok[heart] == 1
	var hpos: Vector2 = (bp[heart] + o) if hp_heart else o
	var burning: bool = z._burn_t > 0.0
	# חוטי נבגים: מהלב לכל ציפור
	if hp_heart:
		var pulse := 0.5 + 0.5 * sin(_t * 6.0)
		var fc := Color(0.7, 1.0, 0.6, 0.12 + 0.1 * pulse)
		var fc2 := Color(0.7, 1.0, 0.6, 0.0)
		for i in bp.size():
			if ok[i] == 1 and i != heart:
				var p: Vector2 = bp[i] + o
				var n := (p - hpos).orthogonal().normalized() * 0.6
				pts.append_array([hpos - n, hpos + n, p + n, hpos - n, p + n, p - n])
				cols.append_array([fc, fc, fc2, fc, fc2, fc2])
	# גידים של נבגים: כל ציפור מחוברת לשכנה שלה בצורה (ראש, ידיים, רגליים) - רואים את האדם
	if _form_k > 0.4:
		var sa := (_form_k - 0.4) / 0.6
		var sc2 := Color(0.72, 1.0, 0.58, 0.3 * sa)
		var prev := -1
		var lim := 30.0 * SCALE
		for i in bp.size():
			if ok[i] == 0 or i == heart:
				continue
			if prev >= 0:
				var a: Vector2 = bp[prev] + o
				var b: Vector2 = bp[i] + o
				if a.distance_squared_to(b) < lim * lim:
					var n := (b - a).orthogonal().normalized() * 0.8
					pts.append_array([a - n, a + n, b + n, a - n, b + n, b - n])
					cols.append_array([sc2, sc2, sc2, sc2, sc2, sc2])
			prev = i
	# ציפורים
	for i in bp.size():
		if ok[i] == 0 or i == heart:
			continue
		var h: float = bh[i]
		var v: Vector2 = bv[i]
		var dir := _face
		if absf(v.x) > 60.0:
			dir = signf(v.x)
		var flap := _t * (15.0 + 7.0 * h) + h * 20.0
		if state == SWOOP:
			flap = 1.2 + sin(_t * 30.0 + h * 9.0) * 0.2   # כנפיים מקופלות בצלילה
		var tint := Color(1.0, 0.45, 0.1, 0.55) if burning and fposmod(h * 5.3, 1.0) < 0.4 else Color(0, 0, 0, 0)
		var fl: bool = flash and bp[i].distance_squared_to(_flash_lp) < 900.0
		FX.bird(pts, cols, bp[i] + o, BIRD_S * (0.85 + 0.3 * h), flap, dir, h, tint, fl)
	if hp_heart:
		FX.bird(pts, cols, hpos, BIRD_S * 1.35, _t * 18.0, _face, bh[heart], Color(0, 0, 0, 0), flash and (hpos - o).distance_squared_to(_flash_lp) < 900.0, true)
	DrawBatch.tris(z, pts, cols)
	# הלב זוהר (חזק יותר לפני צלילה)
	if hp_heart and not flash:
		var g := 0.35 + 0.2 * sin(_t * 7.0) + (0.4 if state == WIND else 0.0)
		Art.glow(z, hpos, 16.0 + 8.0 * g, Color(1.0, 0.15, 0.1, g))
		Art.glow(z, hpos, 6.0, Color(1.0, 0.8, 0.5, 0.5 * g))
	if burning:
		for q in 3:
			var i: int = int(fposmod(float(q) * 7.0 + _t * 3.0, float(bp.size())))
			if ok[i] == 1:
				Art.glow(z, bp[i] + o, 10.0, Color(1.0, 0.5, 0.1, 0.35))
	return true


# ============================================================
#  ציפורים מתות שנופלות / נוצות / ציפורים שבורחות - צומת אחד לכל השלב, מערך משולשים אחד
# ============================================================
class FX extends Node2D:
	const CAP := 140
	const GRAV := 900.0
	var items: Array = []   # [pos, vel, rot, spin, life, type(0 מתה, 1 נוצה, 2 בורחת), h, col, ground, burning, heart]
	var ground := 630.0
	var _t := 0.0
	var landed := 0          # לבדיקות

	static func of(main: Node) -> Node:
		if main == null:
			return null
		if main.has_meta("s57_mm_fx"):
			var f = main.get_meta("s57_mm_fx")
			if is_instance_valid(f):
				return f
		var n := FX.new()
		n.z_index = 4
		var sb = main.get("_stage")
		if sb != null and sb.get("floor_y") != null:
			n.ground = float(sb.floor_y)
		main.add_child(n)
		main.set_meta("s57_mm_fx", n)
		return n

	static func species(h: float) -> int:
		return 0 if h < 0.58 else (1 if h < 0.84 else 2)   # 0 = קורמורן קיסרי, 1 = שחף אצות, 2 = חמסן


	static func wing(h: float) -> Color:
		match species(h):
			1:
				return Color("1c1e24")
			2:
				return Color("4a3424")
		return Color("14161e")


	static func bird(pts: PackedVector2Array, cols: PackedColorArray, p: Vector2, s: float, flap: float, dir: float, h: float, tint: Color, flash: bool, heart_bird := false) -> void:
		var sp := species(h)
		var back := wing(h)
		var belly := Color("e8e6de") if sp != 2 else Color("8a6a4a")
		var beak := Color("e8a030") if sp == 0 else (Color("e8c840") if sp == 1 else Color("2a2420"))
		if sp == 1:
			back = Color("e4e2dc")   # שחף: גוף לבן, כנפיים שחורות
		if heart_bird:
			back = Color("b01818")
			belly = Color("ff6a50")
		back = back.lerp(tint, tint.a)
		belly = belly.lerp(tint, tint.a)
		var wc := wing(h).lerp(tint, tint.a)
		if heart_bird:
			wc = Color("8a1010")
		if flash:
			back = Color.WHITE
			belly = Color.WHITE
			wc = Color(0.85, 0.85, 0.85)
		var up := sin(flap)
		var sh := p + Vector2(-0.4 * s * dir, -0.8 * s)
		var far_tip := p + Vector2(2.6 * s * dir, -up * 5.2 * s - 1.8 * s)
		var near_tip := p + Vector2(-5.2 * s * dir, -up * 6.0 * s - 1.0 * s)
		# כנף רחוקה
		pts.append_array([sh, sh + Vector2(2.4 * s * dir, 0.2 * s), far_tip])
		var wf := wc.darkened(0.3)
		cols.append_array([wf, wf, wf])
		# גוף (יהלום מהזנב לראש) + בטן
		var tail := p + Vector2(-4.6 * s * dir, 0.3 * s)
		var top := p + Vector2(0.0, -1.5 * s)
		var nose := p + Vector2(3.0 * s * dir, -0.9 * s)
		var bot := p + Vector2(0.4 * s * dir, 1.6 * s)
		pts.append_array([tail, top, nose, tail, nose, bot])
		cols.append_array([back, back, back, back, belly, belly])
		# זנב מפוצל
		pts.append_array([tail, tail + Vector2(-2.2 * s * dir, -0.9 * s), tail + Vector2(-2.0 * s * dir, 1.0 * s)])
		cols.append_array([back, back, back])
		# ראש + מקור
		var hd := p + Vector2(3.6 * s * dir, -1.6 * s)
		var hr := 1.35 * s
		pts.append_array([hd + Vector2(-hr, 0), hd + Vector2(0, -hr), hd + Vector2(hr, 0), hd + Vector2(-hr, 0), hd + Vector2(hr, 0), hd + Vector2(0, hr)])
		var hc := back if sp != 1 else Color("e4e2dc")
		if heart_bird:
			hc = Color("c02020")
		if flash:
			hc = Color.WHITE
		cols.append_array([hc, hc, hc, hc, hc, hc])
		pts.append_array([hd + Vector2(0.6 * s * dir, -0.5 * s), hd + Vector2(3.0 * s * dir, 0.3 * s), hd + Vector2(0.6 * s * dir, 0.6 * s)])
		cols.append_array([beak, beak, beak])
		# כנף קרובה
		pts.append_array([sh + Vector2(1.6 * s * dir, 0.0), sh + Vector2(-1.2 * s * dir, 0.2 * s), near_tip])
		cols.append_array([wc, wc, wc])
		if not flash:   # עין אדומה
			var ec := Color(1.0, 0.25, 0.15) if not heart_bird else Color(1.0, 0.9, 0.5)
			var e := hd + Vector2(0.5 * s * dir, -0.35 * s)
			pts.append_array([e + Vector2(-0.5 * s, 0), e + Vector2(0, -0.5 * s), e + Vector2(0.5 * s, 0)])
			cols.append_array([ec, ec, ec])
			if fposmod(h * 13.7, 1.0) < 0.35:   # ריקבון: נוצות חסרות, בשר אדום
				var rp := p + Vector2(-1.0 * s * dir, 0.6 * s)
				var rc := Color(0.62, 0.1, 0.1)
				pts.append_array([rp + Vector2(-0.9 * s, 0), rp + Vector2(0, -0.8 * s), rp + Vector2(1.0 * s, 0.2 * s)])
				cols.append_array([rc, rc, rc])

	func _add(it: Array) -> void:
		if items.size() >= CAP:
			items.remove_at(0)
		items.append(it)

	func dead_bird(p: Vector2, v: Vector2, h: float, burning: bool, heart_bird: bool) -> void:
		_add([p, v, randf() * TAU, randf_range(-9.0, 9.0), 4.5, 0, h, Color.WHITE, false, burning, heart_bird])

	func flee_bird(p: Vector2, v: Vector2, h: float) -> void:
		_add([p, v, 0.0, 0.0, 3.0, 2, h, Color.WHITE, false, false, false])

	func feathers(p: Vector2, n: int, c: Color) -> void:
		for i in n:
			var cc := c if randf() < 0.6 else Color("e8e6de")
			_add([p + Vector2(randf_range(-8, 8), randf_range(-8, 8)), Vector2(randf_range(-120, 120), randf_range(-160, 20)), randf() * TAU, randf_range(-4.0, 4.0), randf_range(1.6, 2.8), 1, randf(), cc, false, false, false])

	func _process(delta: float) -> void:
		_t += delta
		if items.is_empty():
			return
		var i := 0
		while i < items.size():
			var it: Array = items[i]
			it[4] -= delta
			if it[4] <= 0.0:
				items.remove_at(i)
				continue
			var p: Vector2 = it[0]
			var v: Vector2 = it[1]
			match int(it[5]):
				0:
					if not it[8]:
						v.y += GRAV * delta
						v.x *= exp(-0.8 * delta)
						it[2] += it[3] * delta
						p += v * delta
						if it[9] and Engine.get_process_frames() % 6 == 0 and Art.on_screen(self, p):
							Particles.burst(get_parent(), p, "fire", Vector2.UP, 1)
						if p.y >= ground - 2.0:
							p.y = ground - 2.0
							it[8] = true
							it[4] = minf(it[4], 3.0)
							landed += 1
							if Art.on_screen(self, p):
								Particles.burst(get_parent(), p, "hit", Vector2.UP, 2)
				1:
					v.y = move_toward(v.y, 50.0, 260.0 * delta)
					v.x *= exp(-1.6 * delta)
					p += v * delta + Vector2(sin(_t * 4.0 + float(it[6]) * 9.0) * 18.0 * delta, 0.0)
					it[2] += it[3] * delta
					if p.y > ground - 1.0:
						p.y = ground - 1.0
						v = Vector2.ZERO
				2:
					v.y -= 60.0 * delta
					p += v * delta
			it[0] = p
			it[1] = v
			i += 1
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for it in items:
			var p: Vector2 = it[0]
			var a := clampf(float(it[4]) / 0.6, 0.0, 1.0)
			match int(it[5]):
				0:   # ציפור מתה: מסתובבת, כנפיים פרושות, דם
					var s := 1.6 if not it[10] else 2.0
					var t := Transform2D(float(it[2]) if not it[8] else PI * 0.95, p)
					var tmp := PackedVector2Array()
					var tc := PackedColorArray()
					var tint := Color(0.2, 0.08, 0.04, 0.6) if it[9] else Color(0, 0, 0, 0)
					bird(tmp, tc, Vector2.ZERO, s, 2.2, 1.0, float(it[6]), tint, false, bool(it[10]))
					for q in tmp.size():
						pts.append(t * tmp[q])
						var c: Color = tc[q]
						c.a *= a
						cols.append(c)
					if it[8]:   # שלולית דם קטנה
						var bc := Color(0.45, 0.04, 0.04, 0.7 * a)
						pts.append_array([p + Vector2(-6, 2), p + Vector2(0, 0), p + Vector2(6, 2), p + Vector2(-6, 2), p + Vector2(6, 2), p + Vector2(0, 3)])
						cols.append_array([bc, bc, bc, bc, bc, bc])
				1:   # נוצה
					var r: float = it[2]
					var d := Vector2(cos(r), sin(r)) * 3.2
					var n := d.orthogonal() * 0.35
					var c: Color = it[7]
					c.a *= a
					pts.append_array([p - d, p + n, p + d, p - d, p + d, p - n])
					cols.append_array([c, c, c, c, c, c])
				2:   # בורחת
					var v: Vector2 = it[1]
					var tmp := PackedVector2Array()
					var tc := PackedColorArray()
					bird(tmp, tc, p, 1.4, _t * 22.0 + float(it[6]) * 9.0, signf(v.x) if v.x != 0.0 else 1.0, float(it[6]), Color(0, 0, 0, 0), false, false)
					for q in tc.size():
						var c: Color = tc[q]
						c.a *= a
						tc[q] = c
					pts.append_array(tmp)
					cols.append_array(tc)
		if not pts.is_empty():
			DrawBatch.tris(self, pts, cols)
