extends "res://enemies/zombie_type.gd"
# ============================================================
#  HUNTER ELITE (שלב 9) - טורף שקט שתמיד מנסה להגיע מאחוריך.
#  צללית: נמוך ושפוף כמו חיה, ברדס-גלימה קרועה בצבעי הסוואה שמתנופפת מאחור,
#    משקפת לילה אחת גדולה שזוהרת ירוק, להבי עצם שבולטים מהאמות.
#  תנועה (STALK): כשאתה מכוון אליו - קופא, כורע ומחפש מחסה (ארגזים / הריסות).
#    כשאתה מסתכל לכיוון אחר - רץ מהר. כשהוא קרוב מלפנים - קופץ מעליך
#    (VAULT) ונוחת מאחוריך. אם אתה "מצמיד" אותו יותר מדי זמן - מסתער בזיגזג.
#  התקפה: מאחור - עוצר, המשקפת מהבהבת + קליק (אזהרה הוגנת 0.35 שנ'), ואז
#    זינוק עם הלהבים (LUNGE). פגיעה בגב = נזק כפול. אחרי זה נסוג וחוזר (hit & run).
#  צלילים: קליקים של "סונאר" ("hunt_click"), זינוק עם נהמה ("hunt_lunge"), נשימה ("hunt_rattle").
#  איך משנים: VAULT_CD, WINDUP_T, LUNGE_SPEED, PIN_TIME (כמה זמן הוא מוכן להיות "מוצמד").
# ============================================================

const SOUNDS := {
	"hunt_click": [["S", 3300, 3100, 0.0, 0.02, 0.0, 80.0, 0.3, 1.0, 0], ["S", 3500, 3300, 0.07, 0.02, 0.0, 80.0, 0.3, 1.0, 0], ["S", 3100, 2900, 0.14, 0.02, 0.0, 80.0, 0.3, 1.0, 0],
		["C", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.5, 1.0, 0]],
	"hunt_lunge": {"drive": 2.6, "layers": [["N", 0, 0, 0.0, 0.25, 0.02, 10.0, 0.5, 0.4, 0, 0.2], ["V", 260, 170, 0.0, 0.32, 0.01, 7.0, 0.85, 1.0, 0.04, 0, [700, 1600, 80]]]},
	"hunt_rattle": {"drive": 2.2, "layers": [["V", 70, 64, 0.0, 0.7, 0.1, 2.5, 0.55, 1.0, 0.02, 0, [420, 900, 18]], ["N", 0, 0, 0.0, 0.7, 0.1, 3.0, 0.08, 0.2, 0]]},
}

enum { STALK, VAULT, WINDUP, LUNGE, RECOVER }
const VAULT_CD := 2.6
const WINDUP_T := 0.35
const LUNGE_SPEED := 520.0
const PIN_TIME := 2.2

var state := STALK
var behind_time := 0.0      # כמה זמן הוא היה מאחורי השחקן (לבדיקות)
var vaults := 0
var lunges := 0
var _t := 0.0
var _vault_cd := 0.0
var _lunge_cd := 1.0
var _pinned := 0.0
var _hit := false
var _lunge_back := false
var _lunge_dir := 1.0
var _air_t := 0.0
var _rattle_t := 2.0
var _cape := 0.0


func stats() -> Dictionary:
	return {"name": "HUNTER ELITE", "hp": 38, "walk": 70.0, "chase": 175.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 0.9,
		"duck": 0.0, "cover": 0.55, "skin": Color("8a9488"), "shirt": Color("2e3a3a"), "pants": Color("252b28"), "shoe": Color("15181a"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"awareness": 0.2, "flank_probability": 0.3, "aggression": 0.1}


func use_brain_movement() -> bool:
	return false


func can_bite() -> bool:
	return false   # תוקף רק בזינוק


func _aimed_at(pl: Node) -> bool:
	var to: Vector2 = z.global_position + Vector2(0, -30) - (pl.global_position + Vector2(0, -36))
	if to.length() > 750.0:
		return false
	var aim: Vector2 = pl._aim
	return aim.dot(to.normalized()) > 0.9


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_t -= delta
	_vault_cd -= delta
	_lunge_cd -= delta
	_rattle_t -= delta
	_cape += delta * (6.0 if absf(z.velocity.x) > 60.0 else 2.0)
	var px: float = pl.global_position.x
	var dist := absf(d.x)
	var toward: float = signf(d.x) if d.x != 0.0 else z._dir
	var back_side: float = -pl._face()
	var behind: bool = signf(z.global_position.x - px) == back_side
	if behind and dist < 400.0:
		behind_time += delta
	if _rattle_t <= 0.0:
		_rattle_t = randf_range(4.0, 7.0)
		Sfx.play("hunt_rattle", z.global_position, -8.0, 0.15, 2)
	match state:
		STALK:
			if behind:
				_pinned = 0.0
				z._dir = toward
				if dist < 95.0 and _lunge_cd <= 0.0 and absf(d.y) < 40.0 and z.is_on_floor():
					state = WINDUP
					_t = WINDUP_T
					Sfx.play("hunt_click", z.global_position, 0.0, 0.1, 2)
					return 0.0
				return speed * (1.15 if dist > 160.0 else 0.6)
			# מלפנים: לא הולך ישר לתוך הרובה
			z._dir = toward
			if _aimed_at(pl) and dist > 150.0 and _pinned < PIN_TIME:
				_pinned += delta
				if z._cover_state == 0 and randf() < 0.03:
					z._try_cover(pl)
				z._duck_t = maxf(z._duck_t, 0.2)
				return 0.0
			if _pinned >= PIN_TIME:   # הוצמד יותר מדי: מסתער בזיגזג (קפיצות קטנות)
				_pinned = maxf(_pinned - delta * 0.6, 0.0)
				if z.is_on_floor() and randf() < 0.04:
					z.velocity.y = -330.0
			if dist < 150.0 and z.is_on_floor() and _vault_cd <= 0.0:
				_vault(pl, dist)
				return absf(z.velocity.x) / z._speed_mul
			return speed * 1.3
		VAULT:
			_air_t += delta
			if z.velocity.x != 0.0:
				z._dir = signf(z.velocity.x)
			if z.is_on_floor() and _air_t > 0.15:
				state = STALK
				_pinned = 0.0
			return absf(z.velocity.x) / z._speed_mul
		WINDUP:   # עוצר רגע (אזהרה): המשקפת מהבהבת
			z._dir = toward
			if _t <= 0.0:
				state = LUNGE
				_t = 0.32
				_hit = false
				_lunge_back = behind
				_lunge_dir = toward
				lunges += 1
				z.velocity = Vector2(z._dir * LUNGE_SPEED, -170.0)
				Sfx.play("hunt_lunge", z.global_position, 2.0, 0.1, 2)
			return 0.0
		LUNGE:
			z._dir = _lunge_dir
			if not _hit and dist < 30.0 and absf(d.y + 10.0) < 50.0:
				_hit = true
				z._attack_t = z.bite_delay
				z._bite_anim = 0.3
				pl.hurt(z.damage + (1 if _lunge_back else 0), Vector2(z._dir * 1.5, 0.0))
				if _lunge_back:
					z._popup("BACKSTAB", Color(0.6, 1.0, 0.4), 15, -80.0)
			if _t <= 0.0:
				state = RECOVER
				_t = 0.8
			return LUNGE_SPEED / z._speed_mul
		RECOVER:   # פוגע ובורח
			z._dir = -toward
			if _t <= 0.0:
				state = STALK
				_lunge_cd = 2.4
			return speed * 1.2
	return speed


# קפיצה גבוהה מעל השחקן אל הגב שלו
func _vault(_pl: Node, dist: float) -> void:
	state = VAULT
	_air_t = 0.0
	_vault_cd = VAULT_CD
	vaults += 1
	var air: float = 2.0 * 680.0 / z.gravity
	z.velocity = Vector2(z._dir * clampf((dist + 130.0) / air, 200.0, 430.0), -680.0)
	Sfx.play("hunt_lunge", z.global_position, -6.0, 0.2, 2)


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == WINDUP:   # נפגע בזמן ההכנה: מוותר ונסוג
		state = RECOVER
		_t = 0.6
	return true


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var cloak := col(z.shirt)
	var cloak_d := col(Art.shade(z.shirt, 0.35))
	var bone := col(Color("dcd4bc"))
	var p: float = z._walk_phase
	var f: Array = feet(7.0, 3.5)
	var low: float = 3.0 if (z._duck_t > 0.0 or state == WINDUP) else 0.0
	var hip := Vector2(-3.0, -19.0 + low + absf(sin(p)) * 1.2)
	var sh := Vector2(9.0, -29.0 + low * 1.4)
	var head := sh + Vector2(8.0, -1.0)
	var lunging: bool = (state == LUNGE or state == VAULT) and not z.dead
	if lunging:
		f = [Vector2(-6, -9), Vector2(-12, -5)]
		sh += Vector2(3, -2)
		head = sh + Vector2(9, -2)
	# גלימה קרועה שמתנופפת מאחור (פסי הסוואה)
	var flow := sin(_cape) * 3.0
	var tail := PackedVector2Array([sh + Vector2(-2, -5), sh + Vector2(-8, -3), hip + Vector2(-10, -2), hip + Vector2(-18 + flow, 7), hip + Vector2(-8, 6), hip + Vector2(-2, 4), sh + Vector2(2, 2)])
	Art.fill_shaded(z, tail, cloak, 0.12, 0.4)
	for i in 4:   # רצועות קרועות בקצה הגלימה
		var a := hip + Vector2(-8.0 - float(i) * 3.0, 4.0 + float(i) * 0.8)
		z.draw_line(a, a + Vector2(-3.0 + flow * 0.6, 5.0 + float(i % 2) * 2.0), col(Color("3e4a3a") if i % 2 == 0 else Color("2a3330")), 2.0, true)
	# רגל אחורית + יד אחורית עם להב
	z._leg(hip + Vector2(-1, 0), f[1], col(Art.shade(z.pants, 0.2)), col(Art.shade(z.skin, 0.25)), col(z.shoe))
	var bh := sh + Vector2(6.0 + sin(p) * 3.0, 12.0)
	z._arm(sh + Vector2(-1, 1), bh, col(Art.shade(z.skin, 0.25)), cloak_d)
	_blade(sh.lerp(bh, 0.6), Vector2(1, 0.3), 9.0, bone)
	z._leg(hip + Vector2(1, 0), f[0], col(z.pants), sk, col(z.shoe))
	# מגני ברכיים
	z.draw_circle(Art.joint(hip + Vector2(1, 0), f[0] + Vector2(0, -3), 11.5, 11.5, 1.0), 2.4, col(Color("3a4040")))
	# גוף שפוף + רצועות
	var body := PackedVector2Array([hip + Vector2(-6, 2), hip + Vector2(5, 3), sh + Vector2(6, 4), sh + Vector2(3, -4), sh + Vector2(-5, -3)])
	Art.fill_shaded(z, body, cloak, 0.15, 0.4)
	z.draw_line(sh + Vector2(-3, -2), hip + Vector2(4, 1), col(Color("1a1e1c")), 1.6, true)
	z.draw_line(hip.lerp(sh, 0.5) + Vector2(-5, 0), hip.lerp(sh, 0.5) + Vector2(6, 2), col(Color("1a1e1c")), 1.6, true)
	# ראש בברדס + משקפת לילה
	Art.oval_shaded(z, head, 6.0, 6.0, sk, 0.2)
	var hood := PackedVector2Array([head + Vector2(-8, 4), head + Vector2(-8, -4), head + Vector2(-2, -8.5), head + Vector2(5, -7.5), head + Vector2(7, -3), head + Vector2(2, -4), head + Vector2(-3, 6)])
	Art.fill_shaded(z, hood, cloak, 0.2, 0.45)
	Art.fill(z, PackedVector2Array([head + Vector2(2, 2.5), head + Vector2(7.5, 2.0), head + Vector2(7.0, 5.0), head + Vector2(2.5, 5.0)]), col(Color("2a0a0c")), Art.OUTLINE, 0.8)
	for i in 3:   # שיניים חדות
		z.draw_line(head + Vector2(3.0 + float(i) * 1.5, 2.3), head + Vector2(3.5 + float(i) * 1.5, 3.6), col(Color("e8e0c0")), 0.7)
	z.draw_line(head + Vector2(-4, -3), head + Vector2(4, -1.5), col(Color("101010")), 1.4, true)   # רצועת משקפת
	var lens := head + Vector2(4.5, -1.5)
	var flash := 1.0
	if state == WINDUP and not z.dead:
		flash = 1.6 + 0.6 * sin(z._time * 40.0)
	Art.disc(z, lens, 2.8, col(Color("1a2018")), Art.OUTLINE, 1.0)
	Art.glow(z, lens, 6.0 * flash, Color(0.5, 1.0, 0.3, minf(0.85, 0.5 * flash)))
	z.draw_circle(lens, 1.6, Color(0.7, 1.0, 0.5) if not z.dead else Color(0.2, 0.3, 0.2))
	# יד קדמית עם להב עצם גדול (מורם בזינוק)
	var reach: float = 16.0 if lunging or z._bite_anim > 0.0 else 11.0
	var fh := sh + Vector2(reach, 6.0 - sin(p) * 3.0 - (6.0 if lunging else 0.0))
	z._arm(sh + Vector2(2, 1), fh, sk, cloak)
	_blade(sh.lerp(fh, 0.55), (Vector2(1, -0.5) if lunging else Vector2(1, 0.15)).normalized(), 14.0, bone)
	end_draw()
	return true


# להב עצם שיוצא מהאמה
func _blade(at: Vector2, dir: Vector2, length: float, c: Color) -> void:
	var n := Vector2(-dir.y, dir.x)
	Art.fill(z, PackedVector2Array([at + n * 1.6, at + dir * (length * 0.7) + n * 1.5, at + dir * (length + 2.0), at - n * 1.4]), c, Art.OUTLINE, 0.9)
	z.draw_line(at, at + dir * (length - 1.0), col(Color(0.6, 0.55, 0.45)), 0.6, true)
