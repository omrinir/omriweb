extends "res://enemies/zombie_type.gd"
# ============================================================
#  BLADES (שלב 19, ג'ונגל) - זומבי שבמקום ידיים יש לו שני להבים ארוכים (מצ'טות שהשתרשו לו בעצמות).
#  מחזור:
#    WALK    - מתקרב, הלהבים נגררים על הקרקע ומעלים ניצוצות.
#    WINDUP  - פותח את הלהבים לצדדים ומתכופף (WINDUP_T): ברק על הלהבים = אזהרה.
#    SPIN    - מסתובב מהר כמו מערבולת ודוהר קדימה (SPIN_T, SPIN_SPEED) עם הלהבים בצדדים.
#              נגיעה = פגיעה. כדורים שפוגעים בלהבים מסתובבים - חלק נהדפים (DEFLECT). קפוץ מעליו!
#    DIZZY   - אחרי הסיבוב מסוחרר ומתנודד (DIZZY_T): פגיעה = x1.5. החלון שלך.
#  בוס: "THE THRESHER" - ענק, מסתובב פעמיים ברצף, דהירה ארוכה.
#  צלילים: "bl_scrape" (להבים על הקרקע), "bl_spin" (מערבולת), "bl_shing" (שליפה), "metal_ping" (הדיפה).
#  לשנות: WINDUP_T, SPIN_T, SPIN_SPEED, DEFLECT, DIZZY_T, RANGE.
# ============================================================

const SOUNDS := {
	"bl_scrape": [["N", 0, 0, 0.0, 0.25, 0.02, 8.0, 0.25, 0.9, 0.3], ["S", 2600, 2400, 0.0, 0.2, 0.0, 12.0, 0.08, 1.0, 0]],
	"bl_spin": [["N", 0, 0, 0.0, 0.9, 0.05, 1.2, 0.45, 0.5, 0.6], ["Q", 180, 260, 0.0, 0.9, 0.05, 1.5, 0.15, 0.3, 0.3]],
	"bl_shing": [["S", 3200, 2600, 0.0, 0.35, 0.0, 7.0, 0.3, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.35, 1.0, 0]],
}

const RANGE := 380.0
const WINDUP_T := 0.5
const SPIN_T := 0.9
const SPIN_SPEED := 330.0
const DIZZY_T := 1.0
const DEFLECT := 0.5         # כמה מהכדורים נהדפים בזמן הסיבוב
const HIT_R := 30.0
const CD := Vector2(1.4, 2.4)

enum { WALK, WINDUP, SPIN, DIZZY }
var state := WALK
var spins := 0              # לבדיקות
var hits := 0
var deflects := 0
var _st := 0.0
var _cd := 1.2
var _ang := 0.0             # זווית הסיבוב
var _hit_done := false
var _left := 1              # כמה סיבובים נשארו ברצף (בוס: 2)
var _scrape := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "BLADES", "hp": 260, "walk": 44.0, "chase": 92.0, "damage": 2, "bite_delay": 1.0, "scale": 1.7, "width": 1.15,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9a7a"), "shirt": Color("3a2a22"), "pants": Color("2a2a24"), "shoe": Color("1a1612"),
			"points": 950, "boss": true, "boss_name": "THE THRESHER - JUMP OVER THE SPIN"}
	return {"name": "BLADES", "hp": 40, "walk": 46.0, "chase": 100.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 0.95,
		"duck": 0.0, "cover": 0.1, "skin": Color("8a9a7a"), "shirt": Color("3a2a22"), "pants": Color("2a2a24"), "shoe": Color("1a1612"), "points": 480}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func can_bite() -> bool:
	return state == WALK


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == DIZZY else 1.0


# בזמן הסיבוב חלק מהכדורים פוגעים בלהבים ונהדפים (ניצוצות + צליל מתכת)
func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if state == SPIN and str(src.get("source", "")) == "bullet" and randf() < DEFLECT:
		deflects += 1
		Sfx.play("metal_ping", hit_pos, -2.0, 0.2, 4)
		Particles.burst(z.get_parent(), hit_pos, "fire", Vector2(-_dir.x, -0.5), 5)
		return false
	return true


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			_ang = lerp_angle(_ang, 0.0, delta * 8.0)
			_scrape -= delta
			if absf(z.velocity.x) > 20.0 and z.is_on_floor() and _scrape <= 0.0 and Art.on_screen(z, z.global_position):   # הלהבים נגררים
				_scrape = 0.5
				Particles.burst(z.get_parent(), z.global_position + Vector2(z._dir * 16.0, -2.0) * z.sc, "fire", Vector2(-z._dir, -0.4), 2)
				Sfx.play("bl_scrape", z.global_position, -10.0, 0.15, 2)
			if _cd <= 0.0 and has_pl and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees
				if sees and absf(d.x) < RANGE * (1.3 if _boss() else 1.0) and absf(d.y) < 80.0:
					state = WINDUP
					_st = WINDUP_T
					_left = 2 if _boss() else 1
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					Sfx.play("bl_shing", z.global_position, 0.0, 0.1, 2)
					return _hold(delta, 0.0)
			return false
		WINDUP:
			if _st <= 0.0:
				_start_spin(pl)
			return _hold(delta, 0.0)
		SPIN:
			_ang += delta * 26.0
			var spd := SPIN_SPEED * (1.15 if _boss() else 1.0)
			if has_pl and not _hit_done:
				var d2: Vector2= pl.global_position - z.global_position
				if absf(d2.x) < HIT_R * z.sc and absf(d2.y) < 44.0 * z.sc:
					_hit_done = true
					hits += 1
					pl.hurt(z.damage, Vector2(z._dir, -0.5))
			if randf() < delta * 14.0 and z.is_on_floor():
				Particles.burst(z.get_parent(), z.global_position + Vector2(randf_range(-14, 14), -2), "smoke", Vector2.UP, 1)
			if _st <= 0.0 or z.is_on_wall():
				_left -= 1
				if _left > 0 and has_pl:   # בוס: סיבוב שני מיד, לכיוון השחקן
					_start_spin(pl)
				else:
					state = DIZZY
					_st = DIZZY_T * (0.7 if _boss() else 1.0)
			return _hold(delta, z._dir * spd, 2000.0)
		DIZZY:
			_ang = lerp_angle(_ang, 0.0, delta * 3.0)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y) * (0.7 if _boss() else 1.0)
			return _hold(delta, 0.0)
	return false


func _start_spin(pl: Node) -> void:
	state = SPIN
	_st = SPIN_T * (1.2 if _boss() else 1.0)
	spins += 1
	_hit_done = false
	if pl != null:
		var dx: float = pl.global_position.x - z.global_position.x
		z._dir = signf(dx) if dx != 0.0 else z._dir
	Sfx.play("bl_spin", z.global_position, 0.0, 0.08, 2)


func _hold(delta: float, vx: float, acc := 900.0) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, acc * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	if z.is_on_floor():
		z._walk_phase += absf(z.velocity.x) * 0.075 / z.sc / 60.0
	return true


# ============================================================
#  ציור
# ============================================================
func _blade(root: Vector2, tip_dir: Vector2, length: float, flat: float) -> void:
	# מצ'טה גדולה וברורה: ידית עטופה, להב פלדה בהיר רחב שמתעקל לחוד, גב כהה, קצה לבן מבריק, דם בקצה.
	# flat = 0..1 כמה הוא "פונה אלינו" (בסיבוב הלהב נראה צר יותר כשהוא בצד)
	var w := 4.6 * maxf(flat, 0.3)
	var n := tip_dir.orthogonal()
	var grip := root - tip_dir * 3.0
	z.draw_line(grip, root + tip_dir * 4.0, Art.OUTLINE, 5.0)   # ידית
	z.draw_line(grip, root + tip_dir * 4.0, col(Color("5a3a22")), 3.2)
	z.draw_line(root + tip_dir * 3.5 - n * 4.0, root + tip_dir * 3.5 + n * 4.0, col(Color("3a3a40")), 2.4)   # מגן
	var b0 := root + tip_dir * 4.0
	var tip := root + tip_dir * length + n * w * 0.6
	var belly := b0 + tip_dir * length * 0.62 + n * w * 1.5
	var poly := PackedVector2Array([b0 + n * w * 0.5, belly, tip, b0 + tip_dir * length * 0.7 - n * w * 0.35, b0 - n * w * 0.5])
	Art.fill(z, poly, col(Color("e6eaf0").lerp(Color("9aa2ac"), 1.0 - flat)), Art.OUTLINE, 1.5)
	z.draw_line(b0 - n * w * 0.25, b0 + tip_dir * length * 0.68 - n * w * 0.2, col(Color("6a727c")), 1.2)   # גב הלהב
	z.draw_line(b0 + n * w * 0.6, belly, Color(1, 1, 1, 0.85 * flat + 0.15), 1.0)   # קצה חד מבריק
	z.draw_line(belly, tip, Color(1, 1, 1, 0.85 * flat + 0.15), 1.0)
	z.draw_line(tip - tip_dir * 6.0 + n * w * 0.5, tip, col(Color("8a1010")), 2.0)   # דם בקצה
	var gl := 0.5 + 0.5 * sin(z._time * 3.0 + root.x)
	if gl > 0.92 and flat > 0.5:   # ברק שעובר על הלהב
		Art.glow(z, b0 + tip_dir * length * 0.45 + n * w, 4.0, Color(1, 1, 1, 0.8))


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var crouch := 4.0 if state == WINDUP else (2.0 if state == SPIN else 0.0)
	var wob := sin(z._time * 9.0) * 3.0 if state == DIZZY else 0.0
	var hip := Vector2(wob * 0.3, -22.0 + crouch + absf(sin(p)) * 0.8)
	var sh := Vector2(1.0 + wob, -38.0 + crouch)
	var head := sh + Vector2(3.0, -8.0)
	if state == SPIN:   # רגליים צמודות על קצות האצבעות
		f = [Vector2(2.0, 0.0), Vector2(-2.0, 0.0)]
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var blen := 32.0
	if state == SPIN:
		# מערבולת: שני להבים מסתובבים סביב הגוף (בצד: האורך שלהם "מתקצר" כשהם פונים אלינו)
		z.draw_arc(Vector2(0, -32.0), blen + 2.0, 0.0, TAU, 24, Color(0.85, 0.9, 1.0, 0.12), 6.0)
		for k in 6:   # טשטוש תנועה
			var a := _ang - float(k) * 0.35
			var c := cos(a)
			z.draw_line(Vector2(0, -32.0), Vector2(c * (blen + 4.0), -32.0 + sin(a * 2.0) * 2.0), Color(0.9, 0.95, 1.0, 0.07 * float(6 - k)), 3.0)
	# גוף: חולצה קרועה, צלעות, כתפיים עם חיבור עצם-להב
	var body := PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)])
	Art.fill_shaded(z, body, shirt, 0.12, 0.4)
	for i in 3:
		z.draw_arc(Vector2(sh.x, sh.y + 5.0 + float(i) * 3.5), 4.0, -2.4, -0.7, 6, col(Color("c8c0a8")), 1.2)
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.0)
	z.draw_line(head + Vector2(-5, -3), head + Vector2(-1, 1), col(Color("4a1010")), 1.2)   # צלקת
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.8), 1.1, Color(1.0, 0.25, 0.15) if state != DIZZY else Color(1.0, 0.9, 0.3))
	Art.fill(z, PackedVector2Array([head + Vector2(1, 2.5), head + Vector2(6, 2), head + Vector2(5.5, 5), head + Vector2(1.5, 5)]), col(Color("2a0a0a")), Art.OUTLINE, 0.7)
	if state == DIZZY:   # כוכבים מעל הראש
		for i in 3:
			var a2: float = z._time * 5.0 + float(i) * TAU / 3.0
			z.draw_circle(head + Vector2(cos(a2) * 8.0, -10.0 + sin(a2) * 2.0), 1.3, Color(1.0, 0.95, 0.4, 0.9))
	# הלהבים (במקום ידיים)
	var shoulder_f := sh + Vector2(3, 1)
	var shoulder_b := sh + Vector2(-4, 1)
	if state == SPIN:
		for k in 2:
			var a3 := _ang + float(k) * PI
			var c3 := cos(a3)
			var dirv := Vector2(signf(c3) if c3 != 0.0 else 1.0, 0.04 * sin(a3)).normalized()
			_blade(Vector2(c3 * 5.0, -33.0), dirv, blen * maxf(absf(c3), 0.2), absf(sin(a3)))
	elif state == WINDUP:   # פתוחים לצדדים, ברק
		_blade(shoulder_f + Vector2(4, 0), Vector2(1.0, 0.15).normalized(), blen, 1.0)
		_blade(shoulder_b + Vector2(-4, 0), Vector2(-1.0, 0.15).normalized(), blen, 0.7)
		if int(z._time * 16.0) % 2 == 0:
			Art.glow(z, shoulder_f + Vector2(4 + blen, 4), 6.0, Color(1, 1, 1, 0.9))
	else:   # עמידת לוחם: להב קדמי מכוון קדימה, אחורי מאחור - ברור שיש לו חרבות
		var sw := sin(p) * 0.12
		var hb := shoulder_b + Vector2(-5, 8)
		z._arm(shoulder_b, hb, Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
		_blade(hb, Vector2(-0.85, 0.45 + sw).normalized(), blen * 0.95, 0.7)
		var hf := shoulder_f + Vector2(7, 6)
		z._arm(shoulder_f, hf, sk, shirt)
		_blade(hf, Vector2(1.0, 0.18 - sw).normalized(), blen, 1.0)
	end_draw()
	return true
