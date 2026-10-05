extends "res://enemies/zombie_type.gd"
# ============================================================
#  GRAVEBORN (שלב 13, צפון-מזרח) - בא מתוך האדמה.
#  צללית: שלד-זומבי מכוסה חול, צלעות חשופות, ארובות עיניים ריקות עם נקודת אור, לסת שמוטה,
#    חול נשפך ממנו כל הזמן. כפות ידיים ארוכות עם אצבעות-עצם.
#  מחזור:
#    UNDER  - מתחת לחול: רואים רק תל חול שזז אליך + אדוות (אי אפשר לפגוע בו).
#    WARN   - מתחתיך: האדמה נסדקת, אבק עולה, רעש (ERUPT_WARN שניות) - זוז!
#    ERUPT  - פורץ החוצה (ידיים קודם): מי שעומד מעל נפגע ונזרק למעלה.
#    UP     - זומבי רגיל על הקרקע (רודף, נושך) למשך UP_T, או עד שאתה מתרחק.
#    BURROW - שוקע חזרה לחול -> UNDER.
#  בוס: "THE OSSUARY" - ענק, התפרצות רחבה, ונשאר יותר זמן למעלה.
#  צלילים: "gb_rumble" (רעם תת-קרקעי), "gb_burst" (התפרצות), "gb_rattle" (עצמות).
#  לשנות: UNDER_SPEED, ERUPT_WARN, ERUPT_R, UP_T.
# ============================================================

const SOUNDS := {
	"gb_rumble": [["S", 45, 35, 0.0, 0.7, 0.1, 2.0, 0.7, 1.0, 0.2], ["N", 0, 0, 0.0, 0.7, 0.1, 2.5, 0.45, 0.12, 0]],
	"gb_burst": [["N", 0, 0, 0.0, 0.45, 0.0, 6.0, 0.9, 0.35, 0], ["S", 80, 35, 0.0, 0.35, 0.0, 7.0, 0.8, 1.0, 0], ["C", 0, 0, 0.05, 0.4, 0.0, 6.0, 0.5, 1.0, 0]],
	"gb_rattle": [["C", 0, 0, 0.0, 0.4, 0.0, 6.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 10.0, 0.25, 0.8, 0]],
}

const UNDER_SPEED := 150.0
const ERUPT_WARN := 0.65
const ERUPT_R := 46.0
const UP_T := Vector2(6.0, 8.0)
const RISE_T := 0.4

enum { UNDER, WARN, ERUPT, UP, BURROW }
var state := UNDER
var erupts := 0             # לבדיקות
var hits := 0
var _st := 0.0
var _cd := 1.0
var _rip := 0.0
var _sand := []


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "GRAVEBORN", "hp": 150, "walk": 36.0, "chase": 72.0, "damage": 2, "bite_delay": 1.0, "scale": 1.55, "width": 1.25,
			"duck": 0.0, "cover": 0.0, "skin": Color("d8ccb0"), "shirt": Color("8a7458"), "pants": Color("6a5a44"), "shoe": Color("d8ccb0"),
			"points": 700, "boss": true, "boss_name": "THE OSSUARY"}
	return {"name": "GRAVEBORN", "hp": 30, "walk": 42.0, "chase": 96.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.9,
		"duck": 0.0, "cover": 0.0, "skin": Color("d8ccb0"), "shirt": Color("9a8466"), "pants": Color("7a6a50"), "shoe": Color("d8ccb0"), "points": 360}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.4}


func setup() -> void:
	_go_under()
	_cd = randf_range(0.5, 2.0)


func can_bite() -> bool:
	return state == UP


func can_groan() -> bool:
	return state == UP


func _go_under() -> void:
	state = UNDER
	z.collision_layer = 0   # אי אפשר לפגוע בו מתחת לחול


func _radius() -> float:
	return ERUPT_R * (1.8 if _boss() else 1.0)


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_rip += delta
	_tick_sand(delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	match state:
		UNDER:
			var near: bool = pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < 900.0
			var spd := 0.0
			if near:
				var dx: float = pl.global_position.x - z.global_position.x
				z._dir = signf(dx) if dx != 0.0 else z._dir
				spd = UNDER_SPEED * (0.75 if _boss() else 1.0)
				if absf(dx) < 14.0 and _cd <= 0.0 and pl.is_on_floor() and absf(pl.global_position.y - z.global_position.y) < 40.0:
					state = WARN
					_st = ERUPT_WARN
					spd = 0.0
					Sfx.play("gb_rumble", z.global_position, 2.0, 0.1, 3)
					var cam: Node = z.get_viewport().get_camera_2d()
					if cam != null and cam.has_method("shake"):
						cam.shake(3.0, ERUPT_WARN)
				elif absf(dx) < 14.0:
					spd = 0.0
			z.velocity.x = move_toward(z.velocity.x, z._dir * spd, 500.0 * delta)
		WARN:
			z.velocity.x = 0.0
			if randf() < delta * 20.0:
				Particles.burst(z.get_parent(), z.global_position + Vector2(randf_range(-20, 20), -2), "smoke", Vector2.UP, 2)
			if _st <= 0.0:
				_erupt(pl)
		ERUPT:
			z.velocity.x = 0.0
			if _st <= 0.0:
				state = UP
				_st = randf_range(UP_T.x, UP_T.y) * (1.6 if _boss() else 1.0)
		UP:
			var far: bool = pl == null or pl.dead or absf(pl.global_position.x - z.global_position.x) > 420.0
			if (_st <= 0.0 or far) and z.is_on_floor():
				state = BURROW
				_st = RISE_T * 1.5
				Sfx.play("gb_rattle", z.global_position, -2.0, 0.1, 2)
				return _hold()
			return false   # על הקרקע: תנועה רגילה (המוח)
		BURROW:
			z.velocity.x = 0.0
			if _st <= 0.0:
				_go_under()
				_cd = randf_range(1.5, 2.5)
	return _hold()


func _hold() -> bool:
	z.move_and_slide()
	if z.is_on_floor():
		z._walk_phase += absf(z.velocity.x) * 0.075 / z.sc / 60.0
	return true


func _erupt(pl: Node) -> void:
	state = ERUPT
	_st = RISE_T
	erupts += 1
	z.collision_layer = 4
	Sfx.play("gb_burst", z.global_position, 3.0, 0.1, 3)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -6), "smoke", Vector2.UP, 16)
	for i in 10:
		_sand.append([Vector2(randf_range(-14, 14), -4.0), Vector2(randf_range(-90, 90), randf_range(-260, -120)), 0.0])
	if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < _radius() and absf(pl.global_position.y - z.global_position.y) < 50.0:
		hits += 1
		pl.hurt(z.damage, Vector2(signf(pl.global_position.x - z.global_position.x), -1.2))
		pl.velocity.y = minf(pl.velocity.y, -420.0)
	z._voice("zscream", 0.8, 3.0)


func _tick_sand(delta: float) -> void:
	if state == UP and randf() < delta * 6.0:   # חול נשפך ממנו
		_sand.append([Vector2(randf_range(-6, 6), randf_range(-50, -20)), Vector2(randf_range(-10, 10), 0.0), 0.0])
	for q in _sand:
		q[2] += delta
		q[1].y += 600.0 * delta
		q[0] += q[1] * delta
	_sand = _sand.filter(func(q: Array) -> bool: return q[2] < 0.8 and q[0].y < 2.0)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	if state == UNDER or state == WARN:   # מתחת לחול: תל + אדוות (+ סדקים באזהרה)
		var s: float = z.sc
		var mound: float = 6.0 * s + sin(_rip * 8.0) * 1.0
		var pts := PackedVector2Array()
		for i in 11:
			var u := float(i) / 10.0
			pts.append(Vector2((u - 0.5) * 40.0 * s, -sin(u * PI) * mound))
		z.draw_colored_polygon(pts, Color("c8b48e"))
		z.draw_polyline(pts, Color(0.45, 0.35, 0.22, 0.8), 1.2)
		z.draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.18))   # אדוות שטוחות על הקרקע
		for k in 2:
			var rr: float = fposmod(_rip * 30.0 + float(k) * 16.0, 32.0) * s
			z.draw_arc(Vector2.ZERO, rr + 14.0, PI, TAU, 14, Color(0.45, 0.35, 0.22, 0.5 * (1.0 - rr / (32.0 * s))), 4.0)
		z.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if state == WARN:
			var k2 := 1.0 - clampf(_st / ERUPT_WARN, 0.0, 1.0)
			var rad := _radius()
			for i in 7:   # סדקים מתרחבים
				var a := -PI + float(i) * PI / 6.0
				var len := rad * (0.3 + 0.7 * k2)
				z.draw_line(Vector2(0, -1), Vector2(cos(a) * len, -1.0 + absf(sin(a)) * -3.0), Color(0.25, 0.15, 0.08, 0.9), 1.6)
			z.draw_rect(Rect2(-rad, -3.0, rad * 2.0, 3.0), Color(0.3, 0.2, 0.1, 0.25 + 0.3 * k2))
			if k2 > 0.5:   # קצות אצבעות עצם מבצבצות
				for i in 3:
					z.draw_line(Vector2(-6.0 + float(i) * 6.0, 0), Vector2(-6.0 + float(i) * 6.0 + 1.0, -6.0 * (k2 - 0.5) * 2.0), Color("efe8d6"), 1.6)
		return true
	var k := 1.0
	if state == ERUPT:
		k = 1.0 - clampf(_st / RISE_T, 0.0, 1.0)
	elif state == BURROW:
		k = clampf(_st / (RISE_T * 1.5), 0.0, 1.0)
	begin_draw(k > 0.9)
	if k < 1.0:   # עולה מתוך החול: צומח מהרגליים למעלה
		z.draw_set_transform(Vector2.ZERO, 0.0, Vector2(z._dir * z.wf * z.sc, z.sc * maxf(k, 0.08)))
	var bone := col(z.skin)
	var cloth := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0.0, -22.0)
	var sh := Vector2(3.0, -38.0)
	var head := sh + Vector2(5.0, -7.0)
	# רגליים של עצם
	for i in 2:
		var hp := hip + Vector2(-1.5 + float(i) * 3.0, 0)
		var foot: Vector2 = f[1 - i]
		var knee := Art.joint(hp, foot + Vector2(0, -3), 11.5, 11.5, 1.0)
		var c := bone if i == 1 else Art.shade(bone, 0.25)
		z.draw_line(hp, knee, Art.OUTLINE, 4.6, true)
		z.draw_line(knee, foot, Art.OUTLINE, 4.2, true)
		z.draw_line(hp, knee, c, 2.6, true)
		z.draw_line(knee, foot, c, 2.2, true)
		Art.disc(z, knee, 2.2, c)
		z.draw_line(foot + Vector2(-2, 0), foot + Vector2(5, 0), c, 2.0)
	z._arm(sh + Vector2(-3, 2), sh + Vector2(-3.0 - sin(p) * 3.0, 16.0), Art.shade(bone, 0.25), Art.shade(cloth, 0.3))
	# כלוב צלעות + שאריות בד
	Art.fill(z, PackedVector2Array([sh + Vector2(-6, 0), sh + Vector2(6, 0), hip + Vector2(4, -4), hip + Vector2(-5, -4)]), Color(0.15, 0.1, 0.08, 0.9), Art.OUTLINE, 1.2)
	for i in 4:
		var y := sh.y + 3.0 + float(i) * 3.5
		z.draw_arc(Vector2(sh.x - 0.5, y), 5.5 - float(i) * 0.3, -2.6, 0.4, 8, bone, 1.6)
	z.draw_line(sh + Vector2(-1, 0), hip + Vector2(-1, -2), bone, 2.0)   # עמוד שדרה
	Art.fill(z, PackedVector2Array([hip + Vector2(-6, -5), hip + Vector2(6, -5), hip + Vector2(5, 3), hip + Vector2(-1, 1), hip + Vector2(-6, 3)]), cloth, Art.OUTLINE, 1.0)   # סחבה
	# גולגולת
	Art.oval_shaded(z, head, 5.6, 6.0, bone, 0.1)
	z.draw_circle(head + Vector2(2.6, -1.0), 1.8, Color(0.08, 0.05, 0.04))
	z.draw_circle(head + Vector2(-1.4, -1.0), 1.5, Color(0.08, 0.05, 0.04))
	if not z.dead:
		z.draw_circle(head + Vector2(2.6, -1.0), 0.6, Color(1.0, 0.85, 0.4))
	var jaw := head + Vector2(2.0, 5.5 + sin(z._time * 3.0) * 0.8)
	Art.fill(z, PackedVector2Array([head + Vector2(-2, 3.5), head + Vector2(5, 3.0), jaw + Vector2(3, 1), jaw + Vector2(-3, 1)]), bone, Art.OUTLINE, 0.8)
	for i in 4:
		z.draw_line(head + Vector2(-1.0 + float(i) * 1.6, 3.5), head + Vector2(-1.0 + float(i) * 1.6, 5.0), Color(0.15, 0.1, 0.08), 0.6)
	var hand := sh + Vector2(12.0, 7.0 + sin(p) * 2.0)
	if state == ERUPT:   # ידיים למעלה בהתפרצות
		hand = sh + Vector2(8.0, -14.0)
	z._arm(sh + Vector2(2, 2), hand, bone, cloth)
	for i in 3:   # אצבעות עצם
		z.draw_line(hand, hand + Vector2(4.0, -2.0 + float(i) * 2.0), bone, 1.0)
	for q in _sand:
		z.draw_circle(q[0], 1.2, Color(0.85, 0.72, 0.5, 1.0 - q[2] / 0.8))
	end_draw()
	return true
