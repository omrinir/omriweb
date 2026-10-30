extends "res://enemies/zombie_type.gd"
# ============================================================
#  LOBIZON (שלב 50, "TANGO CEMETERY") - הלוביזון מהפולקלור הארגנטינאי: הבן השביעי שהופך לזאב בירח מלא.
#  כאן הוא זומבי: בצורת אדם הוא שפוף ואיטי, עם פונצ'ו קרוע וידיים שעירות.
#    HUMAN  - כשהירח מכוסה בעננים: איטי (המוח מזיז אותו).
#    TURN   - העננים נפתחים / ירח מלא: מתקשת, מיילל (TURN_T) - אזהרה ברורה, והוא לא זז.
#    WOLF   - חיית-זאב גדולה: רץ מהר (WOLF_SPEED), קופץ אליך (LEAP), קומבו של שתי שריטות (CLAW), ומתרפא (REGEN לשנייה).
#             מקבל פחות נזק (WOLF_MULT).
#    REVERT - העננים חזרו: מתכווץ חזרה לאדם (REVERT_T) - חלון לירות בו (x REVERT_MULT).
#  הירח: effects/s50_decor.gd (MoonCycle). בשלב בלי ירח - מחזור משלו (OWN_CYCLE).
#  "THEY LEARN WHERE YOU HIDE": בירח מלא אתה על גג / במקום גבוה והוא לא מגיע (ABOVE_LEARN שניות מתחתיך) ->
#    מאותו רגע כל הלוביזונים קופצים לגגות ("IT LEARNED TO CLIMB", main meta "lobizon_climb").
#  לשנות: WOLF_SPEED, LEAP_R, LEAP_CD, CLAW_WIND, REGEN, WOLF_MULT, TURN_T, ABOVE_LEARN.
# ============================================================

const SOUNDS := {
	"lb_howl": [["S", 380, 620, 0.0, 0.5, 0.15, 2.5, 0.35, 1.0, 0.08], ["S", 620, 420, 0.5, 0.9, 0.0, 2.0, 0.3, 1.0, 0.06], ["N", 0, 0, 0.0, 1.2, 0.2, 2.0, 0.05, 0.6, 0, 0.3]],
	"lb_snarl": [["N", 0, 0, 0.0, 0.3, 0.0, 9.0, 0.5, 0.3, 0, 0.8], ["S", 120, 90, 0.0, 0.3, 0.0, 9.0, 0.4, 1.0, 0.2]],
	"lb_claw": [["N", 0, 0, 0.0, 0.12, 0.0, 22.0, 0.6, 0.6, 0, 0.6], ["S", 900, 300, 0.0, 0.1, 0.0, 30.0, 0.2, 1.0, 0]],
}

const WOLF_SPEED := 250.0
const LEAP_R := 260.0
const LEAP_V := Vector2(360.0, -430.0)
const LEAP_CD := 1.6
const CLAW_R := 46.0
const CLAW_WIND := 0.28
const CLAW_GAP := 0.22
const REGEN := 4.0           # חיים לשנייה בצורת זאב
const WOLF_MULT := 0.75
const REVERT_MULT := 1.5
const TURN_T := 1.3
const REVERT_T := 0.9
const ABOVE_LEARN := 2.5
const OWN_CYCLE := Vector2(18.0, 9.0)   # בלי MoonCycle: [שניות אדם, שניות זאב]

enum { HUMAN, TURN, WOLF, REVERT }
var state := HUMAN
var turns := 0               # לבדיקות
var leaps := 0
var claws := 0
var claw_hits := 0
var leap_hits := 0
var climb_leaps := 0
var regen_hp := 0.0
var _st := 0.0
var _cd := 0.6
var _claw := 0               # 0 = לא, 1-2 = איזו שריטה
var _ct := 0.0
var _air := false
var _air_hit := false
var _above := 0.0
var _own := 0.0
var _acc := 0.0
var _wk := 0.0               # 0 = אדם, 1 = זאב (לציור, חלק)


func stats() -> Dictionary:
	return {"name": "LOBIZON", "hp": 55, "walk": 30.0, "chase": 58.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.1,
		"duck": 0.1, "cover": 0.2, "skin": Color("8a8070"), "shirt": Color("6a3a24"), "pants": Color("3a3028"), "shoe": Color("2a2018"),
		"points": 620, "ragdoll": false}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.4}


func can_bite() -> bool:
	return state == HUMAN


func death_sound() -> String:
	return "zdeath"


func damage_mult(_zone: String, _src: Dictionary) -> float:
	if state == WOLF or state == TURN:
		return WOLF_MULT
	if state == REVERT:
		return REVERT_MULT
	return 1.0


func _moon_full() -> bool:
	var D = preload("res://effects/s50_decor.gd")
	if D.active:
		return D.moon_full() or D.moon_rising() and D.moon_warn < TURN_T
	return _own > OWN_CYCLE.x


func _climb_learned() -> bool:
	var m: Node = z.get_parent()
	return m != null and m.has_meta("lobizon_climb")


func physics(pl: Node, delta: float) -> bool:
	_own = fposmod(_own + delta, OWN_CYCLE.x + OWN_CYCLE.y)
	_wk = move_toward(_wk, 1.0 if state == WOLF or (state == TURN and _st < TURN_T * 0.5) else (0.0 if state == HUMAN or (state == REVERT and _st < REVERT_T * 0.5) else _wk), delta * 3.0)
	if z.dead:
		return false
	var full := _moon_full()
	match state:
		HUMAN:
			if full:
				state = TURN
				_st = TURN_T
				turns += 1
				Sfx.play("lb_howl", z.global_position, 3.0, 0.06, 2, 0.9)
				z._popup("AWOOOO", Color("d8e0ff"), 14, -80.0 * z.sc)
				return _move(delta, 0.0)
			return false
		TURN:
			_st -= delta
			if _st <= 0.0:
				state = WOLF
				_cd = 0.3
			return _move(delta, 0.0)
		REVERT:
			_st -= delta
			if _st <= 0.0:
				state = HUMAN
			return _move(delta, 0.0)
		WOLF:
			if not full:
				state = REVERT
				_st = REVERT_T
				_claw = 0
				Sfx.play("lb_snarl", z.global_position, 0.0, 0.1, 2, 1.2)
				return _move(delta, 0.0)
			_acc += REGEN * delta
			if _acc >= 1.0 and z.hp < z.max_hp:
				var n := int(_acc)
				_acc -= float(n)
				z.hp = mini(z.hp + n, z.max_hp)
				regen_hp += float(n)
			return _wolf(pl, delta)
	return false


func _wolf(pl: Node, delta: float) -> bool:
	_cd -= delta
	if pl == null or pl.dead:
		return _move(delta, 0.0)
	var d: Vector2 = pl.global_position - z.global_position
	if not _air:
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	# באוויר: פגיעה בזינוק
	if _air:
		if not _air_hit and z.is_on_floor() == false:
			var r := Rect2(z.global_position + Vector2(-24.0, -60.0) * z.sc, Vector2(48.0, 60.0) * z.sc)
			if r.intersects(pl.body_rect()):
				_air_hit = true
				leap_hits += 1
				pl.hurt(z.damage, Vector2(z._dir * 1.8, -0.6))
		if z.is_on_floor() and z.velocity.y >= 0.0:
			_air = false
			_cd = LEAP_CD
		z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	# קומבו שריטות
	if _claw > 0:
		_ct -= delta
		if _ct <= 0.0:
			claws += 1
			Sfx.play("lb_claw", z.global_position, 0.0, 0.1, 3)
			if absf(d.x) < CLAW_R * z.sc + 12.0 and absf(d.y) < 50.0:
				claw_hits += 1
				pl.hurt(z.damage, Vector2(z._dir * 1.2, -0.3))
			if _claw >= 2:
				_claw = 0
				_cd = 0.9
			else:
				_claw = 2
				_ct = CLAW_GAP
		return _move(delta, 0.0)
	# השחקן מעליך (גג): לומד לקפוץ לגגות
	var above: bool = d.y < -90.0 and absf(d.x) < 220.0 and pl.is_on_floor()
	if above and not _climb_learned():
		_above += delta
		if _above >= ABOVE_LEARN:
			z.get_parent().set_meta("lobizon_climb", true)
			z._popup("IT LEARNED TO CLIMB", Color("d8e0ff"), 13, -90.0 * z.sc)
			Sfx.play("lb_howl", z.global_position, 2.0, 0.06, 2, 1.0)
		# מסתובב מתחת ומיילל
		var pace := sin(z._time * 2.0) * 0.6
		return _move(delta, pace * WOLF_SPEED * 0.5)
	if _cd <= 0.0 and z.is_on_floor():
		if above and _climb_learned():
			_leap(pl, d, true)
			return true
		if absf(d.x) < CLAW_R * z.sc and absf(d.y) < 50.0:
			_claw = 1
			_ct = CLAW_WIND
			Sfx.play("lb_snarl", z.global_position, 0.0, 0.1, 2, 0.9)
			return _move(delta, 0.0)
		if absf(d.x) < LEAP_R and absf(d.x) > CLAW_R and d.y > -60.0:
			_leap(pl, d, false)
			return true
	return _move(delta, z._dir * WOLF_SPEED * float(z.speed_mult))


func _leap(pl: Node, d: Vector2, climb: bool) -> void:
	_air = true
	_air_hit = false
	leaps += 1
	if climb:
		climb_leaps += 1
		var h := maxf(-d.y + 40.0, 80.0)
		z.velocity.y = -sqrt(2.0 * z.gravity * h)
		var t_air: float = -z.velocity.y / z.gravity * 1.6
		z.velocity.x = clampf(d.x / maxf(t_air, 0.3), -LEAP_V.x, LEAP_V.x)
	else:
		z.velocity = Vector2(clampf(d.x * 1.6, -LEAP_V.x, LEAP_V.x), LEAP_V.y)
		z.velocity.x += float(pl.velocity.x) * 0.25
	Sfx.play("lb_snarl", z.global_position, 2.0, 0.1, 2, 0.8)


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 1400.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall() and absf(vx) > 1.0:
		z.velocity.y = -460.0
	z.move_and_slide()
	return true


func logic(_pl: Node, _d: Vector2, _delta: float, speed: float) -> float:
	return speed


# ============================================================
#  ציור: אדם שפוף בפונצ'ו קרוע -> חיית זאב (חוטם, אוזניים, פרווה, רגלי זאב, טפרים, זנב). _wk = כמה זאב
# ============================================================
func draw() -> bool:
	begin_draw()
	var k := _wk
	var sk := col(z.skin)
	var fur := col(Color("4a4038").lerp(Color("2e2824"), k))
	var fur_l := col(Color("6a5a4a"))
	var p: float = z._walk_phase
	var big := 1.0 + 0.35 * k
	var shake := 0.0
	if state == TURN or state == REVERT:
		shake = sin(z._time * 50.0) * 1.2
	var f: Array = feet(4.0 + 3.0 * k, 2.0 + 2.0 * k)
	if _air:
		f = [Vector2(12, -10), Vector2(-12, -6)]
	var hip := Vector2(0, -21.0 * big)
	var hunch := 6.0 + 10.0 * k
	var sh := Vector2(hunch + shake, -38.0 * big + 6.0 * k)
	if state == TURN:   # מתקשת ומיילל לירח
		sh = Vector2(2.0 + shake, -44.0 * big)
	var head := sh + Vector2(6.0 + 4.0 * k, -6.0 - 2.0 * k)
	if state == TURN:
		head = sh + Vector2(4.0, -10.0)
	# זנב
	if k > 0.3:
		var tb := hip + Vector2(-8, -2)
		var sw := sin(z._time * 6.0) * 4.0
		Art.limb(z, PackedVector2Array([tb, tb + Vector2(-10, -4 + sw * 0.5), tb + Vector2(-20, 2 + sw)]), 4.5 * k, fur)
	# רגליים: באדם - רגילות; בזאב - ברך אחורה (רגלי זאב)
	for i in 2:
		var hp: Vector2 = hip + Vector2(-3.0 + 6.0 * float(i), 0)
		var ft: Vector2 = f[1 - i]
		var pa := col(Art.shade(z.pants, 0.25 if i == 0 else 0.0))
		if k < 0.5:
			z._leg(hp, ft, pa, sk, col(z.shoe))
		else:
			var knee := hp.lerp(ft, 0.45) + Vector2(5.0, -2.0)
			var hock := hp.lerp(ft, 0.75) + Vector2(-6.0, 0.0)
			Art.limb(z, PackedVector2Array([hp, knee, hock, ft]), 5.0, fur if i == 1 else Art.shade(fur, 0.2))
			for c in 3:   # טפרים ברגל
				DrawBatch.line(z, ft + Vector2(float(c) * 2.0 - 1.0, 0), ft + Vector2(float(c) * 2.0 + 3.0, 1.5), col(Color("e8e0c8")), 1.0)
	# יד אחורית
	var claw_up := _claw > 0 and _ct > 0.0
	var hb := sh + Vector2(-4.0 - sin(p) * 3.0, 15.0)
	var hf := sh + Vector2(10.0 + sin(p) * 3.0, 14.0 + 4.0 * k)
	if claw_up:
		hb = sh + Vector2(-8, -10) if _claw == 1 else sh + Vector2(16, 10)
		hf = sh + Vector2(18, 8) if _claw == 1 else sh + Vector2(-6, -12)
	elif _claw > 0:
		hf = sh + Vector2(22, 6)
	elif state == TURN:
		hb = sh + Vector2(-12, 6)
		hf = sh + Vector2(14, -2)
	elif _air:
		hb = sh + Vector2(16, -6)
		hf = sh + Vector2(20, 2)
	_arm(sh + Vector2(-4, 2), hb, true, k)
	# גוף: בפונצ'ו (אדם) / חזה שעיר ורחב (זאב)
	var w := 9.0 + 4.0 * k
	var torso := PackedVector2Array([sh + Vector2(-w, -2), sh + Vector2(w - 1.0, 0), hip + Vector2(8, 2), hip + Vector2(-8, 2)])
	Art.fill_shaded(z, torso, fur, 0.12, 0.35)
	for q in 6:   # פרווה פרועה על הגב
		var a := sh.lerp(hip, float(q) / 6.0) + Vector2(-w + 1.0, 0)
		DrawBatch.colored_polygon(z, PackedVector2Array([a, a + Vector2(-3.0 - 3.0 * k, -2.0), a + Vector2(0, 3.0)]), fur)
	if k < 0.85:   # פונצ'ו קרוע (נעלם כשהוא נהיה זאב)
		var pc := col(z.shirt)
		pc.a = 1.0 - k
		var po := PackedVector2Array([sh + Vector2(-11, -3), sh + Vector2(10, -1), sh + Vector2(14, 18), sh + Vector2(8, 15), sh + Vector2(4, 21), sh + Vector2(-2, 16), sh + Vector2(-8, 22), sh + Vector2(-13, 15)])
		DrawBatch.colored_polygon(z, po, pc)
		for q in 3:
			DrawBatch.line(z, sh + Vector2(-8.0 + float(q) * 7.0, 2), sh + Vector2(-9.0 + float(q) * 8.0, 16), Color(0.9, 0.75, 0.4, 0.6 * (1.0 - k)), 1.2)
	if k > 0.3:   # חזה בהיר
		DrawBatch.colored_polygon(z, Art.ellipse(sh + Vector2(5, 8), 5.0 * k, 7.0 * k, 0.3, 10), fur_l)
	# ראש: אדם עם זיפים -> ראש זאב עם חוטם ארוך ואוזניים
	_head_wolf(head, k, sk, fur)
	_arm(sh + Vector2(5, 2), hf, false, k)
	end_draw()
	return true


func _arm(s: Vector2, h: Vector2, back: bool, k: float) -> void:
	var fur := col(Color("4a4038").lerp(Color("2e2824"), k))
	var c := Art.shade(fur, 0.25) if back else fur
	var el := Art.joint(s, h, 9.0 + 2.0 * k, 9.0 + 2.0 * k, -1.0)
	Art.limb(z, PackedVector2Array([s, el, h]), 3.6 + 1.6 * k, c)
	for q in 3:   # טפרים
		var a := (h - el).normalized().rotated(-0.5 + float(q) * 0.5)
		DrawBatch.line(z, h, h + a * (3.0 + 4.0 * k), col(Color("e8e0c8")), 1.1)
	if _claw > 0 and _ct <= 0.05 and not back:
		DrawBatch.arc(z, h, 14.0, -1.2, 1.2, 8, Color(1, 1, 1, 0.45), 2.0)


func _head_wolf(c: Vector2, k: float, sk: Color, fur: Color) -> void:
	# אוזניים
	if k > 0.15:
		for e in [Vector2(-3, -5), Vector2(1, -6)]:
			DrawBatch.colored_polygon(z, PackedVector2Array([c + e, c + e + Vector2(-2, -8.0 * k), c + e + Vector2(3, -1)]), fur)
	Art.oval_shaded(z, c, 5.5 + 1.0 * k, 5.5 + 0.5 * k, sk.lerp(fur, k), 0.0)
	# חוטם
	var mlen := 3.0 + 9.0 * k
	var tilt := -0.6 if state == TURN else 0.0
	var md := Vector2.from_angle(tilt)
	var m0 := c + Vector2(3, 1)
	Art.fill(z, PackedVector2Array([m0 + md.orthogonal() * 3.0, m0 + md * mlen + md.orthogonal() * 1.5, m0 + md * mlen - md.orthogonal() * 2.0, m0 - md.orthogonal() * 3.5]), sk.lerp(fur, k * 0.8), Art.OUTLINE, 0.9)
	DrawBatch.circle(z, m0 + md * mlen + md.orthogonal() * 0.2, 1.4, Color(0.05, 0.05, 0.05))
	# פה פעור עם שיניים
	var open := 2.5 if state == TURN or _claw > 0 or _air else 1.0
	DrawBatch.line(z, m0 + md * 1.0 - md.orthogonal() * 2.0, m0 + md * (mlen - 1.0) - md.orthogonal() * (2.0 + open), Color(0.25, 0.05, 0.05), 1.6)
	if k > 0.4:
		for q in 3:
			var tp := m0 + md * (2.0 + float(q) * mlen * 0.28) - md.orthogonal() * 2.2
			DrawBatch.line(z, tp, tp - md.orthogonal() * 2.0, Color(0.95, 0.92, 0.8), 0.9)
	# עיניים צהובות זוהרות
	if not z.dead:
		var ep := c + Vector2(1.5, -1.5)
		var ec := Color(1.0, 0.85, 0.2).lerp(Color(1.0, 0.95, 0.5), k)
		DrawBatch.circle(z, ep, 1.3 + 0.4 * k, ec)
		if k > 0.5:
			Art.glow(z, ep, 6.0, Color(1.0, 0.9, 0.3, 0.35))
	# זיפים / שיער פרוע
	for q in 5:
		var hp := c + Vector2(-5.0 + float(q) * 2.0, -4.5)
		DrawBatch.line(z, hp, hp + Vector2(-2.0, -2.0 - k * 2.0), fur, 1.2)
