extends "res://enemies/zombie_type.gd"
# ============================================================
#  SHIELDED (שלב 7) - משתמש בחתיכת מכונה (דלת פלדה של תא מכבש) כמחסה מאולתר.
#  צללית: רחב ושפוף מאחורי לוח פלדה גדול עם פסי אזהרה, אשנב עגול ושריטות קליעים.
#         רק קצה הראש מציץ מעל הלוח. סינר ריתוך מעור.
#  צבעים: לוח צהוב-שחור + חלודה כתומה, עור אפור-כחלחל, סינר חום.
#  התנהגות:
#    * מתקדם לאט כשהלוח מגן עליו: קליעים מלפנים = ניצוצות + "קלאנג", בלי נזק.
#      מאחור / מלמעלה (מגשר!) / פיצוץ = נזק רגיל. (נושא השלב: איגוף)
#    * הלוח כבד: כשהשחקן עובר לצד השני לוקח לו 0.8 שנ' להסתובב - הגב חשוף.
#    * חושף את עצמו: כל כמה שניות "מציץ" (מוריד את הלוח לרגע), ולפני מכה
#      הוא מרים את הלוח הצידה (wind-up) - חלון לירות בו.
#    * התקפה: מכת לוח (bash) שהודפת את השחקן חזק.
#    * נפגע כשהוא חשוף -> נסוג אחורה (עדיין פונה אליך עם הלוח) ואז חוזר.
#  צלילים: "shd_clang" (פגיעה בפלדה), "shd_bash" (מכת לוח עמומה + חריקה).
# ============================================================

const SOUNDS := {
	"shd_clang": {"drive": 1.8, "layers": [["S", 610, 600, 0.0, 0.5, 0.0, 7.0, 0.45, 1.0, 0], ["S", 1660, 1640, 0.0, 0.35, 0.0, 10.0, 0.3, 1.0, 0], ["S", 2930, 2900, 0.0, 0.2, 0.0, 16.0, 0.18, 1.0, 0], ["N", 0, 0, 0.0, 0.02, 0.0, 140.0, 0.7, 1.0, 0, 0.3]]},
	"shd_bash": {"drive": 2.4, "layers": [["S", 120, 50, 0.0, 0.25, 0.0, 14.0, 1.0, 1.0, 0], ["N", 0, 0, 0.0, 0.18, 0.0, 18.0, 0.7, 0.3, 0], ["W", 420, 300, 0.02, 0.22, 0.02, 10.0, 0.15, 0.4, 0.05]]},
}

enum { ADVANCE, PEEK, WINDUP, BASH, RECOVER, RETREAT }
var state := ADVANCE
var blocked := 0           # לבדיקות: כמה קליעים נחסמו
var _st := 0.0
var _peek_cd := 3.0
var _clang_cd := 0.0
var _scars := []           # סימני פגיעה על הלוח (נקודות מקומיות)
var _bash_hit := false
var _face := 1.0           # לאן הלוח פונה (מסתובב לאט - הלוח כבד!)
var _turn_t := 0.0


func stats() -> Dictionary:
	return {"name": "SHIELDED", "hp": 30, "walk": 38.0, "chase": 72.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.15,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8a90"), "shirt": Color("5a3e26"), "pants": Color("2c2a28"), "shoe": Color("1a1612"), "points": 280}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "flank_probability": -0.5, "cover_usage": -0.5}


func use_brain_movement() -> bool:
	return false


func setup() -> void:
	_face = z._dir


# כשהוא לא רודף (משוטט) - הלוח פונה לאן שהוא הולך
func physics(_pl: Node, _delta: float) -> bool:
	if not z._chasing:
		_face = z._dir
	return false


func can_bite() -> bool:
	return false   # תוקף רק עם הלוח


# חשוף = הלוח לא מגן (מציץ / מניף / מתאושש)
func exposed() -> bool:
	return state == PEEK or state == WINDUP or state == BASH or state == RECOVER


func _enter(s: int) -> void:
	state = s
	_st = 0.0


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_st += delta
	_peek_cd -= delta
	_clang_cd -= delta
	var dist := absf(d.x)
	# מסתובב לאט: השחקן עבר לצד השני -> 0.8 שנ' שבהן הגב חשוף (חלון לאגף אותו)
	var want := signf(d.x) if d.x != 0.0 else _face
	if want != _face and state != BASH:
		_turn_t += delta
		if _turn_t >= 0.8:
			_face = want
			_turn_t = 0.0
	else:
		_turn_t = 0.0
	z._dir = _face
	if _turn_t > 0.0:
		return 0.0
	match state:
		ADVANCE:
			if dist < 46.0 and absf(d.y) < 50.0 and z._attack_t <= 0.0:
				_enter(WINDUP)
				return 0.0
			if _peek_cd <= 0.0 and dist > 110.0 and dist < 420.0:
				_enter(PEEK)
				_peek_cd = randf_range(2.6, 4.2)
				return 0.0
			return speed * (0.9 if dist > 60.0 else 0.0)
		PEEK:   # מוריד את הלוח ומסתכל
			if _st >= 0.75:
				_enter(ADVANCE)
			return 0.0
		WINDUP:   # מרים את הלוח הצידה - מוכן להכות
			if _st >= 0.5:
				_enter(BASH)
				_bash_hit = false
				Sfx.play("shd_bash", z.global_position, 0.0, 0.1, 2)
			return 0.0
		BASH:
			if not _bash_hit and dist < 62.0 and absf(d.y) < 50.0:
				_bash_hit = true
				z._attack_t = z.bite_delay
				z._bite_anim = 0.25
				pl.hurt(z.damage, Vector2(z._dir * 1.8, 0.0))
				pl.velocity.x += z._dir * 220.0
			if _st >= 0.22:
				_enter(RECOVER)
			return speed * 1.6
		RECOVER:
			if _st >= 0.6:
				_enter(ADVANCE)
			return 0.0
		RETREAT:   # נסוג אחורה כשהלוח עדיין מכוון לשחקן (מהירות שלילית = הליכה לאחור)
			if _st >= 1.4:
				_enter(ADVANCE)
				_peek_cd = randf_range(1.5, 3.0)
			return -speed * 0.85
	return speed


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var source: String = src.get("source", "bullet")
	var frontal: bool = dir.x * _face < 0.0
	var steep := absf(dir.y) > 0.72   # יורים מלמעלה (מגשר) - הלוח לא מכסה
	if (source == "bullet" or source == "melee") and frontal and not steep and not exposed():
		blocked += 1
		if Art.on_screen(z, hit_pos):
			Particles.burst(z.get_parent(), hit_pos, "fire", Vector2(-dir.x, -0.4), 7)
		if _clang_cd <= 0.0:
			_clang_cd = 0.12
			Sfx.play("shd_clang", hit_pos, -2.0, 0.12, 3)
			z._popup("CLANG", Color("ffd060"), 13, -78.0)
		Game.on_zombie_hit({"source": "bullet", "zone": "shield"})
		if _scars.size() < 8:
			_scars.append(Vector2(randf_range(9.0, 15.0), clampf((hit_pos.y - z.global_position.y) / z.sc, -46.0, -6.0)))
		return false
	# הפגיעה עברה: אם היה חשוף - נסוג
	if state != RETREAT and state != BASH:
		_enter(RETREAT)
	return true


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var apron := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(-3.0, -20.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(1.0, -36.0)
	var head := sh + Vector2(3.0, -6.0)
	# מיקום ומצב הלוח
	var plate_c := Vector2(12.0, -24.0)
	var plate_rot := 0.0
	match state:
		PEEK:   # הלוח מוטה קדימה ולמטה - הראש והחזה חשופים
			plate_c = Vector2(16.0, -23.0)
			plate_rot = 0.45
			head = sh + Vector2(5.0, -9.0)
		WINDUP:
			plate_c = Vector2(-2.0, -34.0)
			plate_rot = -1.2
			head = sh + Vector2(3.0, -8.0)
		BASH:
			plate_c = Vector2(20.0, -26.0)
			plate_rot = 0.25
		RECOVER:
			plate_c = Vector2(16.0, -20.0)
			plate_rot = 0.35
	if z.dead:
		plate_c = Vector2(16.0, -8.0)
		plate_rot = 1.4
	# רגליים רחבות
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.2)), col(Art.shade(z.skin, 0.25)), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# גוף רחב + סינר עור
	Art.fill_shaded(z, PackedVector2Array([hip + Vector2(-8, 3), hip + Vector2(7, 3), sh + Vector2(8, 1), sh + Vector2(-8, -2)]), sk, 0.15, 0.4)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-2, 2), sh + Vector2(7, 2), hip + Vector2(8, 8), hip + Vector2(-2, 8)]), apron, 0.15, 0.4)
	z.draw_line(sh + Vector2(-4, -1), sh + Vector2(6, 6), col(Art.shade(z.shirt, 0.4)), 1.0)   # רצועה
	# ראש (מוסתר מאחורי הלוח כשהוא מגן)
	Art.oval_shaded(z, head, 6.8, 7.0, sk, 0.0)
	z.draw_circle(head + Vector2(3.5, -1.0), 1.1, Color(1.0, 0.75, 0.3))
	Art.glow(z, head + Vector2(3.5, -1.0), 3.5, Color(1.0, 0.6, 0.2, 0.5))
	Art.fill(z, PackedVector2Array([head + Vector2(1, 3), head + Vector2(6.5, 2.5), head + Vector2(6, 5.5), head + Vector2(1.5, 5.5)]), Color("2a0a0c"), Art.OUTLINE, 0.8)
	# ידיים אוחזות בלוח
	var grip_a: Vector2 = plate_c + Vector2(-4, -10).rotated(plate_rot)
	var grip_b: Vector2 = plate_c + Vector2(-4, 8).rotated(plate_rot)
	Art.limb(z, PackedVector2Array([sh + Vector2(-2, 1), sh.lerp(grip_a, 0.5) + Vector2(0, 3), grip_a]), 4.4, col(Art.shade(z.skin, 0.2)))
	Art.limb(z, PackedVector2Array([sh + Vector2(3, 2), sh.lerp(grip_b, 0.5) + Vector2(2, 4), grip_b]), 4.6, sk)
	# הלוח (דלת פלדה של מכונה)
	var tr := Transform2D(plate_rot, plate_c)
	var steel := col(Color("6a6e70"))
	Art.fill_shaded(z, tr * PackedVector2Array([Vector2(-4, -26), Vector2(5, -24), Vector2(5, 24), Vector2(-4, 26)]), steel, 0.25, 0.45, Art.OUTLINE, 1.4)
	for i in 5:   # פסי אזהרה בחלק העליון
		var y := -24.0 + float(i) * 3.2
		z.draw_colored_polygon(tr * PackedVector2Array([Vector2(-4, y), Vector2(5, y - 1.5), Vector2(5, y + 1.5), Vector2(-4, y + 3)]), col(Color("d0a020")) if i % 2 == 0 else col(Color("1a1a1a")))
	Art.disc(z, tr * Vector2(0.5, 2.0), 3.6, col(Color("2a3034")), Art.OUTLINE, 1.0)   # אשנב
	z.draw_circle(tr * Vector2(-0.5, 1.0), 1.2, Color(0.7, 0.85, 0.9, 0.5))
	for rv in [Vector2(-2.5, -6), Vector2(3.5, -6), Vector2(-2.5, 18), Vector2(3.5, 18)]:
		z.draw_circle(tr * rv, 0.8, col(Color("9a9ea0")))
	Art.oval(z, tr * Vector2(1.0, 12.0), 2.5, 3.5, Color(0.5, 0.25, 0.08, 0.6), 0.0, Art.NONE)   # חלודה
	for sp in _scars:   # שריטות מקליעים (נוצצות)
		var sv: Vector2 = sp
		var lp := Vector2((sv.x - plate_c.x) * 0.4, sv.y - plate_c.y)
		z.draw_circle(tr * lp, 1.0, Color(0.95, 0.9, 0.75, 0.8))
	end_draw()
	return true
