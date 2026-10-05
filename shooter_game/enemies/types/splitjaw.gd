extends "res://enemies/zombie_type.gd"
# ============================================================
#  SPLITJAW (שלב 11, צפון-מזרח) - פיתיון. שוכב על הריצפה כמו גופה (FEIGN): לא זז, לא נוהם.
#    מתקרבים אליו (או יורים בו) -> קופץ על הרגליים, הראש נפתח לשניים כמו מלכודת
#    ומבפנים יוצאות שורות שיניים ולשון (SPRING) -> זינוק על השחקן (LEAP).
#    אחרי זינוק הראש נסגר לאט (RECOVER) - זה הרגע לירות בו.
#  אחר כך הוא רודף ומזנק שוב מקרוב, תמיד עם אזהרה: הראש נפתח לפני כל זינוק (OPEN_T).
#  צללית: רזה וארוך, חולצת כותנה דהויה, ראש מוארך עם תפר אדום באמצע (הקו שבו הוא נפתח).
#  צלילים: "sj_crack" (הראש נפתח), "sj_shriek" (זינוק), "sj_snap" (נסגר).
#  לשנות: BAIT_RANGE, LEAP_RANGE, OPEN_T, LEAP_T, LEAP_CD.
# ============================================================

const SOUNDS := {
	"sj_crack": [["N", 0, 0, 0.0, 0.18, 0.0, 14.0, 0.7, 0.5, 0], ["C", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.6, 1.0, 0], ["S", 220, 120, 0.0, 0.2, 0.0, 12.0, 0.4, 1.0, 0]],
	"sj_shriek": [["W", 900, 1500, 0.0, 0.35, 0.02, 5.0, 0.35, 0.5, 0.4], ["N", 0, 0, 0.0, 0.35, 0.02, 6.0, 0.3, 0.6, 0]],
	"sj_snap": [["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.8, 0.7, 0], ["S", 400, 150, 0.0, 0.08, 0.0, 30.0, 0.5, 1.0, 0]],
}

const BAIT_RANGE := 170.0      # כמה קרוב צריך להגיע לגופה כדי שתקפוץ
const LEAP_RANGE := 240.0
const OPEN_T := 0.42           # אזהרה: הראש נפתח לפני הזינוק
const LEAP_T := 0.5            # זמן הטיסה של הזינוק
const RECOVER_T := 0.9
const LEAP_CD := Vector2(2.6, 3.6)

enum { FEIGN, SPRING, LEAP, RECOVER, HUNT }
var state := FEIGN
var leaps := 0                 # לבדיקות
var bites := 0
var _st := 0.0
var _cd := 0.0
var _bit := false
var _open := 0.0               # 0 = ראש סגור, 1 = פתוח לגמרי
var _side := 1.0
var _base := Transform2D.IDENTITY   # טרנספורם הציור של הגוף (הראש מצויר מוגדל סביב הציר)


func stats() -> Dictionary:
	return {"name": "SPLITJAW", "hp": 30, "walk": 40.0, "chase": 92.0, "damage": 2, "bite_delay": 0.9, "scale": 1.05, "width": 0.9,
		"duck": 0.0, "cover": 0.1, "skin": Color("b0a49a"), "shirt": Color("c8bea8"), "pants": Color("4a4a58"), "shoe": Color("2a2420"), "points": 330}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.3}


func setup() -> void:
	_side = -1.0 if randf() < 0.5 else 1.0
	_set_lying(true)


func _set_lying(on: bool) -> void:
	var r := z._shape.shape as RectangleShape2D
	if on:
		r.size = Vector2(52, 18) * z.sc
		z._shape.position = Vector2(0.0, -9.0 * z.sc)
	else:
		r.size = Vector2(38.0 * z.wf, 66.0 * z.sc)
		z._shape.position = Vector2(0.0, -33.0 * z.sc)


func can_bite() -> bool:
	return state == HUNT


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == FEIGN:   # נפגע בזמן שהוא "מת" -> קופץ מיד
		_spring(0.25)
	return true


func _spring(open_t: float) -> void:
	if state == FEIGN:
		_set_lying(false)
	state = SPRING
	_st = open_t
	var pl := player()
	if pl != null:
		z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	Sfx.play("sj_crack", z.global_position, 2.0, 0.1, 3)
	if Art.on_screen(z, z.global_position):
		z._popup("!", Color("ff4040"), 24, -80.0)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	var target_open := 0.0
	match state:
		FEIGN:
			z.velocity = Vector2(0.0, z.velocity.y + z.gravity * delta) if not z.is_on_floor() else Vector2.ZERO
			z.move_and_slide()
			var wr := BAIT_RANGE * (0.6 if pl != null and pl._crouching else 1.0)   # מתכופף = מתגנב קרוב יותר
			if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < wr and absf(pl.global_position.y - z.global_position.y) < 90.0:
				_spring(0.3)
			return true
		SPRING:
			target_open = 1.0
			z.velocity.x = 0.0
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if pl != null:
				z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
			if _st <= 0.0:
				_leap(pl)
		LEAP:
			target_open = 1.0
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if not _bit and pl != null and not pl.dead:
				var me := Rect2(z.global_position + Vector2(-16.0, -56.0 * z.sc), Vector2(32.0, 56.0 * z.sc))
				if me.intersects(pl.body_rect()):
					_bit = true
					bites += 1
					pl.hurt(z.damage, Vector2(z._dir * 1.4, -0.3))
					Sfx.play("sj_snap", z.global_position, 2.0, 0.1, 3)
			if _st <= 0.0 and (z.is_on_floor() or _st < -1.5):
				state = RECOVER
				_st = RECOVER_T
				z.velocity.x = 0.0
				Sfx.play("sj_snap", z.global_position, -2.0, 0.1, 3)
		RECOVER:
			target_open = clampf(_st / RECOVER_T, 0.0, 1.0) * 0.6
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if _st <= 0.0:
				state = HUNT
				_cd = randf_range(LEAP_CD.x, LEAP_CD.y)
		HUNT:
			_open = move_toward(_open, 0.0, delta * 5.0)
			if pl != null and not pl.dead and _cd <= 0.0 and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees
				if sees and absf(d.x) < LEAP_RANGE and absf(d.x) > 50.0 and absf(d.y) < 120.0:
					_spring(OPEN_T)
					return true
			return false   # בין זינוקים: תנועה רגילה (המוח)
	_open = move_toward(_open, target_open, delta * 7.0)
	return true


func _leap(pl: Node) -> void:
	state = LEAP
	_st = LEAP_T * 0.6
	_bit = false
	leaps += 1
	var to: Vector2 = pl.global_position if pl != null else z.global_position + Vector2(z._dir * 150.0, 0.0)
	var dx := clampf(to.x - z.global_position.x, -LEAP_RANGE * 1.1, LEAP_RANGE * 1.1)
	var dy := clampf(to.y - z.global_position.y, -140.0, 60.0)
	var g: float = z.gravity
	z.velocity = Vector2(dx / LEAP_T, (dy - 0.5 * g * LEAP_T * LEAP_T) / LEAP_T)
	Sfx.play("sj_shriek", z.global_position, 2.0, 0.12, 3)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	var lying: bool = state == FEIGN and not z.dead
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	if lying:   # שוכב כמו גופה
		_base = Transform2D(PI / 2.0 * _side, Vector2(0.0, -9.0 * z.sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 28.0 * z.sc))
		z.draw_set_transform_matrix(_base)
	else:
		begin_draw()
		_base = Transform2D(0.0, s, 0.0, Vector2.ZERO)
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5) if not lying else [Vector2(4, 0), Vector2(-3, 0)]
	if state == LEAP:   # באוויר: רגליים מקופלות, ידיים קדימה
		f = [Vector2(8, -10), Vector2(-6, -6)]
	var hip := Vector2(0.0, -23.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(3.0 + (5.0 if state == LEAP or state == SPRING else 0.0), -40.0)
	var neck := sh + Vector2(3.0, -3.0)
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	var back_hand := sh + Vector2(-2.0 - sin(p) * 3.0, 16.0)
	if state == LEAP:
		back_hand = sh + Vector2(14, 2)
	z._arm(sh + Vector2(-3, 2), back_hand, col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)))
	var body := PackedVector2Array([sh + Vector2(-6, -2), sh + Vector2(6, -1), hip + Vector2(6, -1), hip + Vector2(4, 3), hip + Vector2(-5, 3), sh + Vector2(-7, 5)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.35)
	z.draw_line(sh + Vector2(1, 2), hip + Vector2(0, -3), col(Art.shade(z.shirt, 0.3)), 1.0)   # כפתורים / קרע
	_head(neck, sk)
	var hand := sh + Vector2(11.0, 8.0 + sin(p) * 2.0)
	if state == SPRING or state == LEAP:   # טפרים קדימה
		hand = sh + Vector2(17.0, -2.0)
	z._arm(sh + Vector2(2, 2), hand, sk, shirt)
	if state == SPRING or state == LEAP:
		for i in 3:
			z.draw_line(hand, hand + Vector2(4.0, -2.0 + float(i) * 2.0), col(Color("e8e0c0")), 1.0)
	end_draw()
	return true


# הראש: שני חצאים על ציר בעורף. פתוח = הלסת העליונה עולה אחורה והתחתונה יורדת, ובפנים שיניים
func _head(neck: Vector2, sk: Color) -> void:
	var o := _open
	var hinge := neck + Vector2(-3.0, -6.0)
	var hs := 1.3   # הראש גדול מהרגיל (רואים את השיניים)
	z.draw_set_transform_matrix(_base * Transform2D(0.0, Vector2(hs, hs), 0.0, hinge - hinge * hs))
	var a_top := -o * 1.05
	var a_bot := o * 0.75
	if o > 0.05:   # פנים הפה: אדום כהה, שורות שיניים, לשון
		var inner := PackedVector2Array([hinge, hinge + Vector2(12, -2).rotated(a_top), hinge + Vector2(14, 3).rotated(a_top * 0.3 + a_bot * 0.7), hinge + Vector2(11, 6).rotated(a_bot)])
		Art.fill(z, inner, col(Color("4a0812")), Art.NONE)
		for i in 5:   # שיניים בחצי העליון והתחתון
			var u := 0.25 + float(i) * 0.17
			var tt := hinge + Vector2(13.0 * u, -1.0).rotated(a_top)
			var tb := hinge + Vector2(13.0 * u, 4.0).rotated(a_bot)
			z.draw_colored_polygon(PackedVector2Array([tt + Vector2(-1.2, 0), tt + Vector2(1.2, 0), tt + Vector2(0, 3.5).rotated(a_top)]), col(Color("f0e8d0")))
			z.draw_colored_polygon(PackedVector2Array([tb + Vector2(-1.2, 0), tb + Vector2(1.2, 0), tb + Vector2(0, -3.5).rotated(a_bot)]), col(Color("f0e8d0")))
		var tongue := PackedVector2Array()
		for i in 6:
			var u := float(i) / 5.0
			tongue.append(hinge + Vector2(4.0 + u * (8.0 + 8.0 * o), 2.0 + sin(z._time * 14.0 + u * 4.0) * 2.0 * u))
		z.draw_polyline(tongue, col(Color("c0405a")), 2.2)
	# חצי עליון (גולגולת)
	var top := PackedVector2Array()
	for i in 9:
		var a := lerpf(PI, TAU, float(i) / 8.0)
		top.append(hinge + (Vector2(6.0, 1.0) + Vector2(cos(a) * 7.5, sin(a) * 7.0)).rotated(a_top))
	top.append(hinge + Vector2(13.0, 1.0).rotated(a_top))
	top.append(hinge + Vector2(0.0, 1.0).rotated(a_top))
	Art.fill_shaded(z, top, sk, 0.15, 0.3)
	var eye := hinge + Vector2(9.0, -2.5).rotated(a_top)
	z.draw_circle(eye, 1.4, Color(1.0, 0.85, 0.3) if not z.dead and state != FEIGN else col(Color("2a2020")))
	# חצי תחתון (לסת)
	var bot := PackedVector2Array([hinge + Vector2(0.0, 1.5).rotated(a_bot), hinge + Vector2(12.5, 1.5).rotated(a_bot), hinge + Vector2(10.0, 7.0).rotated(a_bot), hinge + Vector2(1.0, 6.5).rotated(a_bot)])
	Art.fill_shaded(z, bot, Art.shade(sk, 0.1), 0.1, 0.3)
	if o < 0.05:   # התפר האדום באמצע הראש - הרמז שהוא נפתח
		z.draw_line(hinge + Vector2(0.5, 1.2), hinge + Vector2(13.0, 1.2), Color(0.55, 0.05, 0.08), 1.0)
		for i in 4:
			var sx := hinge + Vector2(2.0 + float(i) * 3.0, 1.2)
			z.draw_line(sx + Vector2(0, -1.2), sx + Vector2(0, 1.2), Color(0.3, 0.05, 0.05), 0.8)
	z.draw_set_transform_matrix(_base)
