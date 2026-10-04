extends "res://enemies/zombie_type.gd"
# ============================================================
#  KRAKEN (שלב 10, צפון-מזרח) - דייג "ז'נגדה" טבוע: כובע קש קרוע, חולצת פסים רטובה,
#    מכנסיים מקופלים, יחף. מהגב יוצאות 2 זרועות דיונון ענקיות (סגול-ורוד עם כפתורי יניקה),
#    ומהלסת 4 זרועות קטנות שמתפתלות כל הזמן. עור אפור-כחלחל רטוב.
#  התקפה (טווח בינוני, REACH): שתי מכות שונות עם אזהרה ברורה (WIND):
#    * SWEEP - הזרוע נמשכת אחורה ונמוך -> מטאטאת לאורך הריצפה. להתחמק: לקפוץ.
#    * SLAM  - הזרוע מתרוממת גבוה -> מוטחת על המקום שבו עמדת. להתחמק: לזוז הצידה.
#    השחקן מעליו (על קומה) -> תמיד SLAM. מקרוב מאוד הוא גם נושך.
#  בוס (ליד היציאה, chase_range > 600): "THE DROWNED FISHERMAN" - גדול, 3 זרועות, טווח ארוך,
#    ולפעמים קומבו: SWEEP ומיד SLAM.
#  צלילים: "kr_wet" (זרוע נמשכת, רטוב), "kr_whip" (הצלפה), "kr_slam" (מכה בריצפה).
#  לשנות: REACH / BOSS_REACH, WIND_T, CD.
# ============================================================

const SOUNDS := {
	"kr_wet": [["N", 0, 0, 0.0, 0.4, 0.05, 5.0, 0.4, 0.18, 0], ["S", 180, 120, 0.0, 0.35, 0.05, 5.0, 0.3, 1.0, 0.4]],
	"kr_whip": [["N", 0, 0, 0.0, 0.18, 0.0, 16.0, 0.8, 0.6, 0], ["S", 900, 200, 0.0, 0.12, 0.0, 20.0, 0.35, 1.0, 0]],
	"kr_slam": [["N", 0, 0, 0.0, 0.35, 0.0, 9.0, 0.8, 0.3, 0], ["S", 90, 40, 0.0, 0.3, 0.0, 9.0, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.4, 0.12, 0]],
}

const REACH := 175.0
const BOSS_REACH := 250.0
const WIND_T := 0.55
const STRIKE_T := 0.2
const RECOVER_T := 0.45
const CD := Vector2(1.5, 2.3)

enum { IDLE, WIND, STRIKE, RECOVER }
enum { SWEEP, SLAM }
var state := IDLE
var attack := SWEEP
var strikes := 0           # לבדיקות
var hits := 0
var _st := 0.0
var _cd := 1.0
var _tx := 0.0             # SLAM: איפה המכה נוחתת (x גלובלי)
var _hit_done := false
var _combo := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "KRAKEN", "hp": 170, "walk": 34.0, "chase": 70.0, "damage": 2, "bite_delay": 1.2, "scale": 1.55, "width": 1.35,
			"duck": 0.0, "cover": 0.0, "skin": Color("7a8c98"), "shirt": Color("2a4a7a"), "pants": Color("4a5a6a"), "shoe": Color("7a8c98"),
			"points": 700, "boss": true, "boss_name": "THE DROWNED FISHERMAN"}
	return {"name": "KRAKEN", "hp": 40, "walk": 40.0, "chase": 88.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.05,
		"duck": 0.1, "cover": 0.2, "skin": Color("8a9ca6"), "shirt": Color("3a5a8a"), "pants": Color("5a6a7a"), "shoe": Color("8a9ca6"), "points": 360}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.25, "keep_range": REACH * 0.7}


func reach() -> float:
	return BOSS_REACH if _boss() else REACH


func can_bite() -> bool:
	return state == IDLE


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_cd -= delta
	if state == IDLE:
		var sees: bool = z.brain == null or z.brain.sees
		if _cd <= 0.0 and sees and absf(d.x) < reach() and d.y > -190.0 and d.y < 60.0 and not pl.dead:
			_start(pl, SLAM if d.y < -50.0 or randf() < 0.45 else SWEEP)
			return 0.0
		return speed
	z._dir = signf(d.x) if state == WIND and d.x != 0.0 else z._dir
	_st -= delta
	match state:
		WIND:
			if _st <= 0.0:
				state = STRIKE
				_st = STRIKE_T
				_hit_done = false
				strikes += 1
				Sfx.play("kr_whip", z.global_position, 0.0, 0.1, 3)
		STRIKE:
			if not _hit_done and _st < STRIKE_T - 0.05:
				_hit_done = true
				_resolve(pl)
			if _st <= 0.0:
				state = RECOVER
				_st = RECOVER_T
		RECOVER:
			if _st <= 0.0:
				state = IDLE
				_cd = randf_range(CD.x, CD.y) * (0.75 if _boss() else 1.0)
				if _combo:
					_combo = false
					_start(pl, SLAM if attack == SWEEP else SWEEP)
					_st = 0.4
	return 0.0


func _start(pl: Node, kind: int) -> void:
	attack = kind
	state = WIND
	_st = WIND_T
	var px: float = pl.global_position.x + clampf(float(pl.velocity.x) * 0.2, -60.0, 60.0)
	var r := reach()
	_tx = clampf(px, z.global_position.x - r, z.global_position.x + r)
	z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	_combo = _boss() and randf() < 0.4
	Sfx.play("kr_wet", z.global_position, -2.0, 0.12, 3)


# הרגע של המכה: מי בתוך האזור נפגע
func _resolve(pl: Node) -> void:
	var zp: Vector2 = z.global_position
	var area: Rect2
	if attack == SWEEP:
		var r := reach()
		area = Rect2(zp.x if z._dir > 0.0 else zp.x - r, zp.y - 24.0, r, 24.0)
	else:
		var w := 70.0 if _boss() else 56.0
		area = Rect2(_tx - w * 0.5, zp.y - 150.0, w, 150.0)
		Sfx.play("kr_slam", Vector2(_tx, zp.y), 2.0, 0.1, 3)
		Particles.burst(z.get_parent(), Vector2(_tx, zp.y - 4.0), "smoke", Vector2.UP, 8)
		var cam: Node = z.get_viewport().get_camera_2d()
		if cam != null and cam.has_method("shake") and Art.on_screen(z, Vector2(_tx, zp.y)):
			cam.shake(6.0 if not _boss() else 10.0, 0.25)
	if pl != null and not pl.dead and area.intersects(pl.body_rect()):
		hits += 1
		pl.hurt(z.damage, Vector2(z._dir * 1.6, -0.4))


# ============================================================
#  ציור
# ============================================================
# fwd = מרחק קדימה (בכיוון שהוא פונה), בפיקסלים של העולם -> קואורדינטות ציור
func _local(fwd: Vector2) -> Vector2:
	return Vector2(fwd.x / (z.wf * z.sc), fwd.y / z.sc)


# זרוע דיונון: עקומת בזייה עבה-דקה עם כפתורי יניקה
func _tentacle(base: Vector2, ctrl: Vector2, tip: Vector2, w: float, c: Color) -> void:
	var n := 14
	var pts := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / float(n)
		pts.append(base.lerp(ctrl, u).lerp(ctrl.lerp(tip, u), u))
	for i in n:   # קו מתאר
		var k := 1.0 - float(i) / float(n)
		z.draw_line(pts[i], pts[i + 1], Art.OUTLINE, w * (0.25 + 0.75 * k) + 2.0, true)
	for i in n:
		var k := 1.0 - float(i) / float(n)
		z.draw_line(pts[i], pts[i + 1], col(c), w * (0.25 + 0.75 * k), true)
		z.draw_line(pts[i], pts[i + 1], col(Art.shade(c, -0.25)), w * (0.25 + 0.75 * k) * 0.35, true)
	for i in range(2, n, 2):   # כפתורי יניקה בצד הפנימי
		var dirv := (pts[i + 1] - pts[i - 1]).normalized()
		var nrm := Vector2(-dirv.y, dirv.x)
		var k := 1.0 - float(i) / float(n)
		z.draw_circle(pts[i] + nrm * w * 0.38 * (0.25 + 0.75 * k), maxf(0.6, w * 0.16 * k + 0.4), col(Color("f0c0d0")))


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.0)
	var t: float = z._time
	var hip := Vector2(0.0, -21.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(2.0, -37.0)
	var head := sh + Vector2(5.0, -7.0)
	var tc := Color("a04a8a")
	var r := reach()
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	# זרועות הדיונון (מאחורי הגוף)
	var big := 3 if _boss() else 2
	var wind_k := 0.0
	if state == WIND:
		wind_k = 1.0 - clampf(_st / WIND_T, 0.0, 1.0)
	for i in big:
		var base := sh + Vector2(-5.0 + float(i) * 2.0, 2.0 + float(i) * 3.0)
		var ph := t * 2.0 + float(i) * 1.9
		var tip := base + Vector2(16.0 + sin(ph) * 5.0 - float(i) * 30.0, -22.0 + cos(ph * 0.8) * 6.0 + float(i) * 34.0)
		var ctrl := base + Vector2(-16.0, -18.0 + float(i) * 14.0)
		tip.y = minf(tip.y, -4.0)   # לא נכנסת לריצפה
		if i == 0 and not z.dead and state != IDLE:   # הזרוע שתוקפת
			var tr := Vector2(sin(t * 40.0), cos(t * 37.0)) * 1.5 * wind_k
			var wind_tip := base + (Vector2(-36.0, 24.0) if attack == SWEEP else Vector2(-8.0, -54.0)) + tr
			var wind_ctrl := base + (Vector2(-22.0, -10.0) if attack == SWEEP else Vector2(-28.0, -30.0))
			var hit_tip := _local(Vector2(r, -8.0)) if attack == SWEEP else _local(Vector2(absf(_tx - z.global_position.x), -4.0))
			var hit_ctrl := base + Vector2(40.0, 26.0) if attack == SWEEP else Vector2(hit_tip.x * 0.45, -90.0)
			match state:
				WIND:
					tip = tip.lerp(wind_tip, minf(wind_k * 2.5, 1.0))
					ctrl = ctrl.lerp(wind_ctrl, minf(wind_k * 2.5, 1.0))
				STRIKE:
					var sk2 := clampf(1.0 - _st / STRIKE_T, 0.0, 1.0)
					var e := minf(sk2 * 3.0, 1.0)
					tip = wind_tip.lerp(hit_tip, e)
					ctrl = wind_ctrl.lerp(hit_ctrl, e)
				RECOVER:
					var rk := clampf(_st / RECOVER_T, 0.0, 1.0)
					tip = tip.lerp(hit_tip, rk * rk)
					ctrl = ctrl.lerp(hit_ctrl, rk * rk)
		elif z.dead:
			tip = base + Vector2(-26.0 + float(i) * 8.0, 18.0)
			ctrl = base + Vector2(-14.0, 8.0)
		_tentacle(base, ctrl, tip, 6.5 if i == 0 else 5.0, tc if i == 0 else Art.shade(tc, 0.15))
	# אזהרת SLAM: צל על הריצפה במקום שבו המכה תנחת
	if state == WIND and attack == SLAM and not z.dead:
		var gx := _local(Vector2(absf(_tx - z.global_position.x), 0.0)).x
		var a := 0.15 + 0.35 * wind_k
		Art.oval(z, Vector2(gx, -1.0), 22.0, 4.0, Color(0.1, 0.0, 0.1, a), 0.0, Art.NONE)
	# יד אחורית
	z._arm(sh + Vector2(-3, 2), sh + Vector2(-2.0 - sin(p) * 4.0, 15.0), col(Art.shade(z.skin, 0.25)), col(Art.shade(z.shirt, 0.3)))
	# חולצת פסים רטובה
	var body := PackedVector2Array([sh + Vector2(-7, -2), sh + Vector2(7, -1), hip + Vector2(7, -1), hip + Vector2(5, 3), hip + Vector2(-6, 3), sh + Vector2(-8, 5)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.35)
	for i in 4:
		var y := sh.y + 4.0 + float(i) * 4.5
		z.draw_line(Vector2(-7.0 + float(i) * 0.3, y), Vector2(6.5, y - 0.5), col(Color("d8dce0")), 1.4)
	z.draw_line(hip + Vector2(-7, -1), hip + Vector2(7, -2), col(Color("6a5030")), 2.0, true)   # חבל במקום חגורה
	# ראש: לסת עם זרועות קטנות
	Art.oval_shaded(z, head, 6.0, 6.6, sk, 0.1)
	for i in 4:
		var mp := head + Vector2(1.5 + float(i) * 1.6, 3.5)
		var wig := sin(t * 5.0 + float(i) * 1.3)
		var mt := mp + Vector2(wig * 2.5 + 1.0, 8.0 + float(i % 2) * 2.5)
		_tentacle(mp, mp + Vector2(-wig * 2.0, 4.0), mt, 2.2, tc)
	var eye := head + Vector2(3.0, -1.5)
	z.draw_circle(eye, 2.0, col(Color("e8e0a0")) if not z.dead else Color("3a3a2a"))
	z.draw_line(eye + Vector2(-1.2, 0), eye + Vector2(1.2, 0), Color("1a1a1a"), 1.0)   # אישון אופקי כמו של דיונון
	# כובע קש קרוע
	Art.fill_shaded(z, PackedVector2Array([head + Vector2(-12, -4), head + Vector2(12, -5), head + Vector2(9, -2), head + Vector2(-9, -1)]), col(Color("c8a860")), 0.2, 0.3)
	Art.fill_shaded(z, PackedVector2Array([head + Vector2(-6, -4), head + Vector2(-4, -11), head + Vector2(5, -11), head + Vector2(6, -4)]), col(Color("b89850")), 0.2, 0.3)
	z.draw_line(head + Vector2(-5, -6), head + Vector2(5, -6), col(Color("7a3a2a")), 1.4)
	# יד קדמית
	z._arm(sh + Vector2(2, 2), sh + Vector2(11.0, 8.0 + sin(p) * 2.0), sk, shirt)
	# טיפות מים
	if not z.dead and fmod(t, 0.9) < 0.3:
		z.draw_circle(hip + Vector2(-4.0, 6.0 + fmod(t, 0.9) * 40.0), 1.0, Color(0.6, 0.8, 1.0, 0.7))
	end_draw()
	return true
