extends "res://enemies/zombie_type.gd"
# ============================================================
#  SWINGER (שלב 19, ג'ונגל) - זומבי שמתנדנד על ליאנה כמו ספיידרמן.
#  מחזור:
#    WALK   - זומבי רגיל ומהיר (המוח).
#    THROW  - זורק ליאנה למעלה אל צמרת העצים (THROW_T): הוא מכופף ברכיים, החבל עף למעלה.
#    SWING  - קופץ למעלה, ובשיא נתפס בליאנה. מטוטלת אמיתית: עיגון באמצע הדרך, בגובה שבו תחתית הקשת CLEAR מעל הקרקע. מתנדנד בקשת
#             ונעזב בשיא השני של הקשת - שזה בדיוק ליד השחקן (LAND_GAP לפניו).
#    DROP   - צונח ישר למטה ליד השחקן. נוחת: אבק, רעידה קטנה, ואם נחת עליך - פגיעה.
#    ואז חוזר להיות זומבי רגיל, ואם התרחקת שוב (SWING_RANGE) - שוב ליאנה.
#  באוויר אפשר לירות בו (פגיעה בזמן התנדנדות = x1.5).
#  צלילים: "sw_whip" (זריקת ליאנה), "sw_whoosh" (רוח בהתנדנדות), "sw_land" (נחיתה).
#  לשנות: SWING_RANGE, JUMP_V, CLEAR, LAND_GAP, CD.
# ============================================================

const SOUNDS := {
	"sw_whip": [["N", 0, 0, 0.0, 0.12, 0.0, 22.0, 0.5, 0.6, 0], ["S", 900, 300, 0.0, 0.1, 0.0, 25.0, 0.25, 1.0, 0]],
	"sw_whoosh": [["N", 0, 0, 0.0, 0.7, 0.25, 3.0, 0.4, 0.35, 0.2]],
	"sw_land": [["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.7, 0.25, 0], ["S", 90, 45, 0.0, 0.2, 0.0, 14.0, 0.6, 1.0, 0]],
}

const SWING_RANGE := Vector2(230.0, 760.0)   # מאיזה מרחק מהשחקן הוא זורק ליאנה

const LAND_GAP := 46.0      # כמה לפני השחקן הוא נוחת
const THROW_T := 0.32
const JUMP_V := 470.0       # קופץ למעלה לפני ההתנדנדות (כמו ספיידרמן) - הליאנה נתפסת בשיא
const CLEAR := 62.0         # היד בתחתית הקשת: כמה מעל הקרקע (הרגליים לא נוגעות)
const CD := Vector2(2.5, 4.0)
const SWING_G := 1250.0     # "כבידה" של המטוטלת (מהירות ההתנדנדות)

enum { WALK, THROW, SWING, DROP }
var state := WALK
var swings := 0             # לבדיקות
var landed_near := 0
var _st := 0.0
var _cd := 1.5
var _anchor := Vector2.ZERO
var _len := 100.0
var _th := 0.0              # זווית המטוטלת (0 = ישר למטה)
var _w := 0.0               # מהירות זוויתית
var _th0 := 0.0
var _rope_fade := 0.0       # אחרי שעזב: הליאנה עוד מתנדנדת ונעלמת
var _rope_end := Vector2.ZERO
var _ground := 0.0
var _land_x := 0.0


func stats() -> Dictionary:
	return {"name": "SWINGER", "hp": 28, "walk": 60.0, "chase": 135.0, "damage": 1, "bite_delay": 0.7, "scale": 0.95, "width": 0.85,
		"duck": 0.2, "cover": 0.0, "skin": Color("7f9a5e"), "shirt": Color("5a6a2a"), "pants": Color("4a3a24"), "shoe": Color("2a1e14"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func setup() -> void:
	_cd = randf_range(0.6, 2.0)


func can_bite() -> bool:
	return state == WALK


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == SWING else 1.0


func _hand() -> Vector2:   # היד שמחזיקה בליאנה (בעולם)
	return z.global_position + Vector2(z._dir * 3.0, -50.0) * z.sc


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_rope_fade -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if _cd <= 0.0 and has_pl and z.is_on_floor():
				var dx: float = pl.global_position.x - z.global_position.x
				var sees: bool = z.brain == null or z.brain.sees
				if sees and absf(dx) > SWING_RANGE.x and absf(dx) < SWING_RANGE.y and absf(pl.global_position.y - z.global_position.y) < 260.0:
					_start_throw(pl)
					return _hold(delta)
			return false   # הליכה רגילה (המוח)
		THROW:   # קפיצה למעלה; בשיא הליאנה נתפסת
			z.velocity.x = 0.0
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if _st <= 0.0 and z.velocity.y >= 0.0:
				_attach()
				state = SWING
				swings += 1
				Sfx.play("sw_whoosh", z.global_position, -2.0, 0.1, 2)
			return true
		SWING:
			var acc := -SWING_G / _len * sin(_th)
			_w += acc * delta
			_th += _w * delta
			z.global_position = _anchor + Vector2(sin(_th), cos(_th)) * _len - Vector2(z._dir * 3.0, -50.0) * z.sc
			z.velocity = Vector2(cos(_th), -sin(_th)) * _w * _len
			# עוזב בשיא השני של הקשת (המהירות מתהפכת) - בדיוק ליד השחקן
			var fwd := -signf(_th0)   # הכיוון שבו הוא עף
			if signf(_th) == fwd and (signf(_w) != fwd or absf(_th) >= absf(_th0) * 0.97):
				_release()
			return true
		DROP:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 300.0 * delta)
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if z.is_on_floor():
				_land(pl)
			return true
	return _hold(delta)


func _hold(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _start_throw(pl: Node) -> void:
	var dx: float = pl.global_position.x - z.global_position.x
	z._dir = signf(dx) if dx != 0.0 else z._dir
	_ground = z.global_position.y
	_land_x = pl.global_position.x - z._dir * LAND_GAP
	var apex := _hand() - Vector2(0.0, JUMP_V * JUMP_V / (2.0 * z.gravity))   # איפה היד תהיה בשיא הקפיצה
	_anchor = _anchor_for(apex)
	z.velocity = Vector2(0.0, -JUMP_V)
	state = THROW
	_st = THROW_T
	Sfx.play("sw_whip", z.global_position, 0.0, 0.1, 2)


# נקודת עיגון באמצע הדרך (השיא השני של הקשת = סימטרי = ליד השחקן), בגובה כזה שתחתית הקשת
# נשארת CLEAR מעל הקרקע: (B - ay)^2 = a^2 + (C - ay)^2
func _anchor_for(h: Vector2) -> Vector2:
	var a := absf(_land_x - h.x) * 0.5
	var b := _ground - CLEAR
	var c := minf(h.y, b - 20.0)
	var ay := (b + c) * 0.5 - a * a / (2.0 * (b - c))
	return Vector2((h.x + _land_x) * 0.5, minf(ay, c - 40.0))


func _attach() -> void:
	var h := _hand()
	_anchor = _anchor_for(h)
	_len = h.distance_to(_anchor)
	_th0 = atan2(h.x - _anchor.x, h.y - _anchor.y)
	_th = _th0
	_w = 0.0


func _release() -> void:
	state = DROP
	_rope_fade = 0.6
	_rope_end = _hand()
	z.velocity = Vector2(z.velocity.x * 0.25, maxf(z.velocity.y, 0.0))


func _land(pl: Node) -> void:
	state = WALK
	_cd = randf_range(CD.x, CD.y)
	Sfx.play("sw_land", z.global_position, 0.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -3), "smoke", Vector2.UP, 6)
	z._voice("zscream", 0.7, 3.0)
	if pl != null and not pl.dead:
		var d: float = absf(pl.global_position.x - z.global_position.x)
		if d < 140.0:
			landed_near += 1
		if d < 26.0 * z.sc and absf(pl.global_position.y - z.global_position.y) < 40.0:   # נחת עליך
			pl.hurt(z.damage, Vector2(signf(pl.global_position.x - z.global_position.x), -0.6))


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	# הליאנה (בקואורדינטות מקומיות לא הפוכות)
	var rope_from := Vector2.ZERO
	var rope_to := Vector2.ZERO
	var rope_a := 0.0
	if state == THROW:
		var k := minf(1.0, 1.0 - _st / THROW_T)
		rope_from = _hand() - z.global_position
		rope_to = rope_from.lerp(_anchor - z.global_position, k)
		rope_a = 1.0
	elif state == SWING:
		rope_from = _hand() - z.global_position
		rope_to = _anchor - z.global_position
		rope_a = 1.0
	elif _rope_fade > 0.0:   # עזב: הליאנה נשארת תלויה ומתנדנדת
		rope_to = _anchor - z.global_position
		rope_from = rope_to + Vector2(sin(_rope_fade * 9.0) * 30.0, _len * 0.9)
		rope_a = _rope_fade / 0.6
	if rope_a > 0.0:
		var mid := (rope_from + rope_to) * 0.5 + Vector2(0, 6)
		z.draw_polyline(PackedVector2Array([rope_from, mid, rope_to]), Color(0.18, 0.28, 0.1, rope_a), 3.2, true)
		z.draw_polyline(PackedVector2Array([rope_from, mid, rope_to]), Color(0.36, 0.5, 0.2, rope_a), 1.6, true)
		for i in 4:   # עלים על הליאנה
			var lp := rope_to.lerp(rope_from, 0.15 + 0.2 * float(i))
			z.draw_colored_polygon(PackedVector2Array([lp, lp + Vector2(5, -2), lp + Vector2(2, 3)]), Color(0.3, 0.55, 0.2, rope_a))
	if state == SWING:   # גוף נוטה לפי המטוטלת
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		var ang: float = -_th * 0.6 * z._dir
		z.draw_set_transform_matrix(Transform2D(ang, Vector2(0, -48.0 * z.sc)) * Transform2D(0.0, s, 0.0, Vector2(0, 48.0 * z.sc)))
	else:
		begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.5, 3.0)
	if state == SWING or state == DROP:   # רגליים מתנדנדות באוויר
		var kick := sin(z._time * 9.0) * 4.0
		f = [Vector2(4.0 + kick, -4.0), Vector2(-3.0 - kick, -2.0)]
	elif state == THROW:   # מכופף לפני הקפיצה
		f = [Vector2(5.0, 0.0), Vector2(-4.0, 0.0)]
	var crouch := 4.0 if state == THROW else 0.0
	var hip := Vector2(0.0, -22.0 + crouch + absf(sin(p)) * 0.8)
	var sh := Vector2(1.0, -38.0 + crouch)
	var head := sh + Vector2(3.0, -8.0)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית
	var back_hand := sh + Vector2(-6.0, 12.0) if state != SWING else sh + Vector2(-9.0, 6.0 + sin(z._time * 9.0) * 3.0)
	z._arm(sh + Vector2(-3, 1), back_hand, Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	# גופייה קרועה + חבל ליאנות על הכתף
	var body := PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)])
	Art.fill_shaded(z, body, shirt, 0.12, 0.4)
	z.draw_line(sh + Vector2(-5, 0), hip + Vector2(5, 0), col(Color("3e5a22")), 2.2)
	for i in 3:
		z.draw_circle(sh.lerp(hip, 0.2 + 0.3 * float(i)) + Vector2(-2.0 + float(i) * 3.5, 0), 1.2, col(Color("5a7a2e")))
	# ראש: שיער פרוע עם עלים, צבע מלחמה
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	for i in 5:
		var a := -PI * 0.9 + float(i) * 0.35
		z.draw_line(head + Vector2.from_angle(a) * 4.5, head + Vector2.from_angle(a) * 9.0, col(Color("2a2016")), 2.0)
	z.draw_line(head + Vector2(0.5, -1.0), head + Vector2(5.5, -1.5), col(Color("b03a20")), 1.4)
	if not z.dead:
		z.draw_circle(head + Vector2(3.2, -0.6), 1.0, Color(1.0, 0.85, 0.3))
	Art.fill(z, PackedVector2Array([head + Vector2(1, 2.5), head + Vector2(5.5, 2.2), head + Vector2(5, 4.8), head + Vector2(1.5, 4.8)]), col(Color("2a0a0a")), Art.OUTLINE, 0.7)
	# יד קדמית: למעלה על הליאנה כשמתנדנד / זורק
	var front_hand := sh + Vector2(11.0, 6.0 + sin(p) * 2.0)
	if state == SWING or state == THROW:
		front_hand = sh + Vector2(2.0, -14.0)
	z._arm(sh + Vector2(2, 1), front_hand, sk, shirt)
	end_draw()
	return true
