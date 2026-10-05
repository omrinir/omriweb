extends "res://enemies/zombie_type.gd"
# ============================================================
#  IRONWING (שלב 12, צפון-מזרח) - זומבי קשור למתקן כנפיים רובוטי: מסגרת מתכת על הגב,
#    בוכנות ומנועי סרוו שמניעים זרועות-כנף מפלדה עם בד מפרש קרוע (מדלתא-מצנח של דייגים),
#    נורית אדומה מהבהבת על המנוע, חוטי חשמל לתוך הגוף.
#  תנועה: עף מעל השחקן ובצדדים (FLY), הכנפיים מנפנפות עם קול מכני.
#  התקפה: אזהרה (WIND) - מרחף במקום, הכנפיים מתקפלות אחורה, הנורית נדלקת + צווחה ->
#    צלילה (DIVE) בקו ישר אל המקום שבו היית -> מטפס חזרה (CLIMB).
#  פגיעה בו עד חצי חיים = כנף נשברת -> נופל ומשתרך על הקרקע עם כנף גרורה (GROUNDED).
#  בוס (ליד היציאה): "THE IRON ANGEL" - ענק, צולל פעמיים ברצף.
#  צלילים: "iw_flap" (נפנוף מכני), "iw_screech" (אזהרה), "iw_break" (כנף נשברת).
#  לשנות: HOVER_H, DIVE_SPEED, WIND_T, DIVE_CD.
# ============================================================

const SOUNDS := {
	"iw_flap": [["N", 0, 0, 0.0, 0.18, 0.02, 8.0, 0.45, 0.25, 0], ["Q", 70, 50, 0.0, 0.12, 0.0, 14.0, 0.2, 0.4, 0]],
	"iw_screech": [["W", 1800, 2600, 0.0, 0.45, 0.02, 3.0, 0.3, 0.6, 0.3], ["Q", 300, 900, 0.0, 0.4, 0.02, 4.0, 0.15, 0.5, 0]],
	"iw_break": [["N", 0, 0, 0.0, 0.4, 0.0, 6.0, 0.8, 0.6, 0], ["C", 0, 0, 0.0, 0.4, 0.0, 6.0, 0.6, 1.0, 0], ["S", 400, 80, 0.0, 0.4, 0.0, 6.0, 0.4, 1.0, 0]],
}

const HOVER_H := 190.0
const DIVE_SPEED := 560.0
const WIND_T := 0.55
const DIVE_CD := Vector2(2.4, 3.4)

enum { FLY, WIND, DIVE, CLIMB, FALLING, GROUNDED }
var state := FLY
var dives := 0               # לבדיקות
var hits := 0
var broken := false
var _st := 0.0
var _cd := 2.0
var _side := 1.0
var _flap := 0.0
var _flap_snd := 0.0
var _hit_done := false
var _combo := 0
var _target := Vector2.ZERO


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "IRONWING", "hp": 150, "walk": 40.0, "chase": 80.0, "damage": 2, "bite_delay": 1.0, "scale": 1.5, "width": 1.2,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a8478"), "shirt": Color("3a3430"), "pants": Color("2a2624"), "shoe": Color("1a1614"),
			"points": 700, "boss": true, "boss_name": "THE IRON ANGEL"}
	return {"name": "IRONWING", "hp": 34, "walk": 40.0, "chase": 80.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("94907e"), "shirt": Color("4a4038"), "pants": Color("2e2a28"), "shoe": Color("1a1614"), "points": 380}


func setup() -> void:
	z.global_position.y -= HOVER_H   # מתחיל באוויר
	_side = -1.0 if randf() < 0.5 else 1.0
	_cd = randf_range(1.0, 2.5)


func use_brain_movement() -> bool:
	return broken


func can_bite() -> bool:
	return state == GROUNDED


func physics(pl: Node, delta: float) -> bool:
	if state == GROUNDED:
		return false
	_cd -= delta
	_st -= delta
	if not broken and z.hp < z.max_hp / 2:
		_break_wing()
	var has_pl: bool = pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < 1000.0
	match state:
		FLY:
			_flap += delta * 9.0
			var tgt: Vector2 = z.global_position + Vector2(sin(z._time * 0.7) * 40.0, sin(z._time * 1.3) * 20.0)
			if has_pl:
				tgt = pl.global_position + Vector2(_side * 170.0 + sin(z._time * 0.9) * 50.0, -HOVER_H + sin(z._time * 1.7) * 25.0)
				z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
				if _cd <= 0.0 and absf(pl.global_position.x - z.global_position.x) < 420.0:
					state = WIND
					_st = WIND_T
					_target = pl.global_position + Vector2(0.0, -26.0)
					Sfx.play("iw_screech", z.global_position, 1.0, 0.1, 3)
			_steer(tgt, 520.0, delta)
		WIND:   # מרחף, כנפיים מתקפלות, ננעל על המטרה
			_flap += delta * 3.0
			z.velocity = z.velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if has_pl:
				_target = _target.lerp(pl.global_position + Vector2(0.0, -26.0), delta * 3.0)
			if _st <= 0.0:
				state = DIVE
				_st = 0.9
				Game.story.emit("flyer", {"z": z})
				_hit_done = false
				dives += 1
				z.velocity = (_target - z.global_position).normalized() * DIVE_SPEED
		DIVE:
			if not _hit_done and pl != null and not pl.dead:
				var me := Rect2(z.global_position + Vector2(-18.0, -50.0 * z.sc), Vector2(36.0, 50.0 * z.sc))
				if me.intersects(pl.body_rect()):
					_hit_done = true
					hits += 1
					pl.hurt(z.damage, Vector2(signf(z.velocity.x), -0.4))
			if _st <= 0.0 or z.is_on_floor() or z.global_position.distance_to(_target) < 20.0 or _hit_done:
				state = CLIMB
				_st = 0.8
				z.velocity = Vector2(z.velocity.x * 0.4, -280.0)
				_combo += 1
		CLIMB:
			_flap += delta * 14.0
			z.velocity = z.velocity.move_toward(Vector2(0.0, -260.0), 800.0 * delta)
			if _st <= 0.0:
				if _boss() and _combo < 2 and has_pl:   # בוס: צלילה שנייה מיד
					state = WIND
					_st = WIND_T * 0.8
					_target = pl.global_position + Vector2(0.0, -26.0)
					Sfx.play("iw_screech", z.global_position, 1.0, 0.1, 3)
				else:
					state = FLY
					_combo = 0
					_cd = randf_range(DIVE_CD.x, DIVE_CD.y) * (0.8 if _boss() else 1.0)
					_side = -_side
		FALLING:
			z.velocity.y += z.gravity * delta
			if z.is_on_floor():
				state = GROUNDED
				z.velocity.x = 0.0
				return false
	_flap_snd -= delta
	if state != FALLING and _flap_snd <= 0.0 and Art.on_screen(z, z.global_position):
		_flap_snd = 0.35 if state != CLIMB else 0.2
		Sfx.play("iw_flap", z.global_position, -8.0, 0.15, 2)
	z.move_and_slide()
	return true


func _steer(tgt: Vector2, accel: float, delta: float) -> void:
	var to: Vector2 = tgt - z.global_position
	z.velocity += to.normalized() * accel * delta * clampf(to.length() / 100.0, 0.25, 1.0)
	z.velocity *= 1.0 - 1.8 * delta


func _break_wing() -> void:
	broken = true
	state = FALLING
	z.velocity = Vector2(z.velocity.x * 0.3, 0.0)
	Sfx.play("iw_break", z.global_position, 2.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 14.0, -40.0), "spark", Vector2.UP, 14)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0.0, -40.0), "smoke", Vector2.UP, 8)
	z._popup("WING BROKEN", Color("ffb040"), 14, -90.0)


# ============================================================
#  ציור
# ============================================================
func _wing(root: Vector2, ang: float, span: float, broken_w: bool) -> void:
	var metal := col(Color("5a5e66"))
	var dark := col(Color("33363c"))
	var cloth := Color(0.78, 0.72, 0.6, 0.9) if z._flash <= 0.0 else Color.WHITE
	var elbow := root + Vector2.from_angle(ang) * span * 0.45
	var tip_a := ang - 0.8 if not broken_w else ang + 1.5   # הזרוע החיצונית פונה אחורה (שבורה: תלויה)
	var ribs := []
	for i in 4:   # מניפה של מוטות מתכת: מהקצה אחורה ולמטה
		ribs.append(elbow + Vector2.from_angle(tip_a - 0.32 * float(i)) * span * (0.62 - 0.1 * float(i)))
	# בד המפרש: משולשים בין המוטות (לא מצולע אחד - שלא יתהפך)
	z.draw_colored_polygon(PackedVector2Array([root, elbow, ribs[0]]), cloth)
	for i in 3:
		z.draw_colored_polygon(PackedVector2Array([elbow, ribs[i], ribs[i + 1]]), cloth.darkened(0.06 * float(i)))
	z.draw_colored_polygon(PackedVector2Array([root, ribs[3], elbow]), cloth.darkened(0.15))
	for i in 3:   # קרעים בבד
		var hp: Vector2 = (ribs[i] as Vector2).lerp(elbow, 0.4)
		z.draw_line(hp, hp + Vector2(3, 5), Color(0.2, 0.18, 0.15, 0.8), 1.2)
	Art.limb(z, PackedVector2Array([root, elbow, ribs[0]]), 3.2, metal)
	for i in range(1, 4):
		z.draw_line(elbow, ribs[i], dark, 1.8)
		z.draw_circle(ribs[i], 1.2, dark)
	Art.disc(z, elbow, 2.8, dark)   # מנוע סרוו
	z.draw_line(root + Vector2(2, 3), elbow.lerp(root, 0.4) + Vector2(0, 4), col(Color("8a8e96")), 1.4)   # בוכנה


func draw() -> bool:
	begin_draw(false)
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var flying: bool = state != GROUNDED and not z.dead
	var flap := sin(_flap) if flying else 0.0
	var fold := 0.0
	if state == WIND or state == DIVE:
		fold = 1.0
	var hip := Vector2(-1.0, -22.0)
	var sh := Vector2(2.0, -38.0)
	var head := sh + Vector2(5.0, -7.0)
	var f: Array = feet(5.0, 2.5) if not flying else [Vector2(2, -2), Vector2(-4, 0)]
	if state == DIVE:   # צולל: גוף אלכסוני
		f = [Vector2(-8, -12), Vector2(-12, -8)]
	var wroot := sh + Vector2(-6.0, 0.0)
	# כנף אחורית (כהה) ואז הגוף ואז הכנף הקדמית
	var a_back := -PI * 0.5 - 0.6 + flap * 0.7 + fold * 1.5
	_wing(wroot + Vector2(-2, -1), a_back - 0.3, 48.0 * (1.0 - 0.35 * fold), false)
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 2), sh + Vector2(-6.0, 14.0), col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)))
	var body := PackedVector2Array([sh + Vector2(-7, -2), sh + Vector2(6, -1), hip + Vector2(6, -1), hip + Vector2(4, 3), hip + Vector2(-5, 3), sh + Vector2(-8, 5)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.35)
	# רתמה + מנוע על הגב
	z.draw_line(sh + Vector2(-6, 0), hip + Vector2(5, -2), col(Color("2a2420")), 2.4)
	z.draw_line(sh + Vector2(4, 0), hip + Vector2(-5, -2), col(Color("2a2420")), 2.4)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-13, -4), sh + Vector2(-5, -4), sh + Vector2(-5, 12), sh + Vector2(-13, 12)]), col(Color("4a4e56")), 0.2, 0.3)
	var led_on := state == WIND or fmod(z._time, 0.8) < 0.15
	if not z.dead:
		z.draw_circle(sh + Vector2(-9, -1), 1.6, Color(1.0, 0.2, 0.15) if led_on else Color(0.35, 0.1, 0.1))
		if led_on:
			Art.glow(z, sh + Vector2(-9, -1), 6.0, Color(1.0, 0.2, 0.15, 0.6))
	z.draw_line(sh + Vector2(-9, 10), head + Vector2(-5, 3), col(Color("8a2a2a")), 1.0)   # חוטים לתוך הגוף
	# ראש עם משקפי טיסה
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.1)
	z.draw_line(head + Vector2(-6, -2), head + Vector2(6, -2), col(Color("3a2a20")), 2.0)
	Art.disc(z, head + Vector2(3.5, -2.0), 2.4, Color(0.9, 0.3, 0.2, 0.9) if state == WIND else col(Color("6a8a9a")), Art.OUTLINE, 0.9)
	z.draw_line(head + Vector2(1, 3), head + Vector2(5, 3.5), col(Color("2a0a10")), 1.2)
	z._arm(sh + Vector2(2, 2), sh + Vector2(12.0, 8.0) if state != DIVE else sh + Vector2(14.0, 2.0), sk, shirt)
	var a_front := -PI * 0.5 - 0.3 + flap * 0.8 + fold * 1.4
	_wing(wroot, a_front, 54.0 * (1.0 - 0.35 * fold), broken)
	end_draw()
	return true
