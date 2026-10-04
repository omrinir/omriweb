extends "res://enemies/zombie_type.gd"
# ============================================================
#  HUNTER (שלב 8) - טורף חכם שזוכר איפה היית ונעלם בתעלות האוורור.
#  צללית: הולך על ארבע - גוף אופקי, ידיים ארוכות שנוגעות ברצפה, ראש מוארך ונמוך עם לסת,
#         עדשה אדומה אחת זוהרת (שתל), סמרטוטים שחורים ורכס חוליות על הגב.
#  זיכרון: דוגם את המיקום של השחקן כל 0.25 שנ' (3 שניות אחורה) ומחשב לאן הוא זז.
#  התנהגות: מתגנב (המוח מזיז אותו). כשמכוונים אליו / פוגעים בו / סתם כשהוא מוכן -
#    VANISH: צולל לפתח אוורור ונעלם (לא ניתן לפגוע בו).
#    HIDDEN: 2-3.5 שניות לא נראה.
#    TELL:   "אזהרה הוגנת" - סורג אוורור רועד + עין אדומה מבהיקה + צליל מתכת, 0.9 שנ'
#            מאחורי השחקן (לפי הכיוון שהוא מסתכל + לאן שהוא זז).
#    EMERGE: קופץ מהפתח על השחקן מהצד השני.
#  התקפה: זינוק מהמארב + נשיכה רגילה.
#  צליל: "hunter_vent" (קרקוש סורג מתכת), "hunter_purr" (נהמת קליקים נמוכה), "hunter_pounce".
#  לשנות: HIDE_TIME, TELL_TIME, VANISH_CD.
# ============================================================

const SOUNDS := {
	"hunter_vent": [["C", 0, 0, 0.0, 0.6, 0.0, 3.0, 1.0, 1.0, 0], ["S", 340, 330, 0.0, 0.5, 0.0, 6.0, 0.25, 1.0, 0], ["S", 910, 900, 0.05, 0.4, 0.0, 8.0, 0.15, 1.0, 0], ["N", 0, 0, 0.0, 0.5, 0.0, 5.0, 0.25, 0.4, 0]],
	"hunter_purr": {"drive": 2.4, "layers": [["V", 70, 64, 0.0, 0.8, 0.05, 2.5, 0.8, 1.0, 0.03, 0, [420, 1200, 34]], ["C", 0, 0, 0.0, 0.8, 0.0, 3.0, 0.5, 1.0, 0]]},
	"hunter_pounce": {"drive": 2.8, "layers": [["V", 300, 160, 0.0, 0.35, 0.01, 6.0, 0.9, 1.0, 0.06, 0, [900, 1900, 70]], ["N", 0, 0, 0.0, 0.25, 0.0, 12.0, 0.4, 0.5, 0, 0.2]]},
}

enum { STALK, VANISH, HIDDEN, TELL, POUNCE }
const HIDE_TIME := Vector2(2.0, 3.4)
const TELL_TIME := 0.9
const VANISH_CD := Vector2(6.0, 9.0)

var state := STALK
var _t := 0.0
var _cd := 3.0
var _hist := []               # מיקומים אחרונים של השחקן
var _hist_t := 0.0
var _hurt_t := 0.0
var _purr_t := 2.0
var _vent_pos := Vector2.ZERO
var _hide_dur := 2.5
var vanishes := 0             # לבדיקות
var emerges := 0
var last_emerge_side := 0.0   # בצד של השחקן שהוא יצא (-1/1)


func stats() -> Dictionary:
	return {"name": "HUNTER", "hp": 26, "walk": 60.0, "chase": 165.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 0.85,
		"duck": 0.35, "cover": 0.2, "skin": Color("5e5a6e"), "shirt": Color("1e2228"), "pants": Color("1a1c22"), "shoe": Color(0, 0, 0, 0), "points": 320}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "flank_probability": 0.3}


# מיקום חזוי של השחקן (לפי 3 השניות האחרונות)
func predicted(pl: Node, ahead := 0.9) -> Vector2:
	var pp: Vector2 = pl.global_position
	if _hist.size() < 2:
		return pp
	var a: Vector2 = _hist[0]
	var b: Vector2 = _hist[_hist.size() - 1]
	var span := 0.25 * float(_hist.size() - 1)
	var v := (b - a) / span
	return pp + Vector2(clampf(v.x * ahead, -250.0, 250.0), 0.0)


func move_dir(pl: Node) -> float:
	var px: float = predicted(pl).x - float(pl.global_position.x)
	return signf(px) if absf(px) > 30.0 else 0.0


func physics(pl: Node, delta: float) -> bool:
	_t += delta
	_cd -= delta
	_hurt_t -= delta
	if pl == null or pl.dead:
		if state != STALK and state != POUNCE:
			_appear()
			state = STALK
		return false
	_hist_t -= delta
	if _hist_t <= 0.0:
		_hist_t = 0.25
		_hist.append(pl.global_position)
		if _hist.size() > 12:
			_hist.pop_front()
	match state:
		VANISH:
			z.velocity = Vector2.ZERO
			z.modulate.a = 1.0 - clampf(_t / 0.5, 0.0, 1.0)
			if _t > 0.25:
				z.collision_layer = 0
			if _t >= 0.5:
				state = HIDDEN
				_t = 0.0
				z.collision_mask = 0
				z.modulate.a = 0.0
			return true
		HIDDEN:
			z.velocity = Vector2.ZERO
			if _t >= _hide_dur:
				_start_tell(pl)
			return true
		TELL:
			z.velocity = Vector2.ZERO
			z.modulate.a = 1.0
			if _t >= TELL_TIME:
				_emerge(pl)
			return true
		POUNCE:
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			var dd: Vector2 = pl.global_position - z.global_position
			if absf(dd.x) < 24.0 and absf(dd.y) < 50.0 and z._attack_t <= 0.0:
				z._attack_t = z.bite_delay
				z._bite_anim = 0.3
				pl.hurt(z.damage, Vector2(signf(z.velocity.x), 0.0))
			if z.is_on_floor() and _t > 0.15:
				state = STALK
				_cd = randf_range(VANISH_CD.x, VANISH_CD.y)
			return true
	return false


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_purr_t -= delta
	if _purr_t <= 0.0:
		_purr_t = randf_range(4.0, 7.0)
		if Art.on_screen(z, z.global_position):
			Sfx.play("hunter_purr", z.global_position, -6.0, 0.15, 2)
	var dist := absf(d.x)
	if _cd <= 0.0 and z.is_on_floor() and dist > 110.0 and dist < 560.0 and z.brain != null and z.brain.sees:
		var me: Vector2 = z.global_position + Vector2(0.0, -20.0) - pl.global_position
		var aimed: bool = pl._aim.dot(me.normalized()) > 0.9
		if aimed or _hurt_t > 0.0 or randf() < delta * 0.25:
			start_vanish()
			return 0.0
	return speed


func start_vanish() -> void:
	state = VANISH
	_t = 0.0
	vanishes += 1
	_vent_pos = z.global_position
	_hide_dur = randf_range(HIDE_TIME.x, HIDE_TIME.y)
	var dr := director()
	if dr != null:
		dr.release_slot(z)
	Sfx.play("hunter_vent", z.global_position, -2.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -6), "smoke", Vector2.UP, 6)


# בוחר מאיפה לצאת: מאחורי השחקן (לפי הכיוון שהוא מסתכל / זז), בודק שיש רצפה ואין קיר
func _start_tell(pl: Node) -> void:
	var pp: Vector2 = pl.global_position
	var behind: float = -float(pl._face())
	var md := move_dir(pl)
	if md != 0.0 and randf() < 0.5:
		behind = -md
	var base_x: float = predicted(pl, 0.5).x
	var spot := Vector2.INF
	for side in [behind, -behind]:
		var sd: float = side
		var x: float = base_x + sd * randf_range(170.0, 230.0)
		var gy := _floor_at(x, pp.y)
		if gy < INF:
			spot = Vector2(x, gy)
			break
	if spot == Vector2.INF:
		spot = _vent_pos
	z.global_position = spot
	last_emerge_side = signf(spot.x - pp.x)
	state = TELL
	_t = 0.0
	Sfx.play("hunter_vent", spot, 2.0, 0.1, 2)


func _floor_at(x: float, py: float) -> float:
	var ww: float = z.world_w
	if x < 60.0 or x > ww - 60.0:
		return INF
	var space: PhysicsDirectSpaceState2D = z.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, py - 40.0), Vector2(x, py + 40.0), 1 | 16)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return INF
	var gy: float = hit.position.y
	var pq := PhysicsPointQueryParameters2D.new()
	pq.collision_mask = 1
	for yy in [12.0, 30.0, 50.0]:
		pq.position = Vector2(x, gy - float(yy))
		if not space.intersect_point(pq, 1).is_empty():
			return INF
	return gy


func _emerge(pl: Node) -> void:
	_appear()
	emerges += 1
	state = POUNCE
	_t = 0.0
	var dx: float = float(pl.global_position.x) - z.global_position.x
	z._dir = signf(dx) if dx != 0.0 else 1.0
	z.velocity = Vector2(clampf(dx / 0.5, -420.0, 420.0), -430.0)
	Sfx.play("hunter_pounce", z.global_position, 2.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -6), "smoke", Vector2.UP, 6)


func _appear() -> void:
	z.modulate.a = 1.0
	if not z.dead:
		z.collision_layer = 4
		z.collision_mask = 1 | 16


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == HIDDEN or state == TELL:
		return false
	_hurt_t = 1.5   # נפגע: רוצה להיעלם
	return true


func on_death() -> void:
	z.modulate.a = 1.0


func draw() -> bool:
	if z.dead:
		pass
	elif state == HIDDEN:
		return true   # לא נראה בכלל
	elif state == TELL:
		_draw_tell()
		return true
	begin_draw()
	var sk := col(z.skin)
	var dark := col(Art.shade(z.skin, 0.35))
	var rag := col(z.shirt)
	var p: float = z._walk_phase
	var air: bool = state == POUNCE and not z.dead
	var f: Array = feet(6.0, 3.0)
	var hip := Vector2(-6.0, -22.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(12.0, -24.0 + absf(cos(p)) * 1.0)
	var head := sh + Vector2(10.0, -2.0)
	if air:
		hip = Vector2(-8.0, -26.0)
		sh = Vector2(12.0, -30.0)
		head = sh + Vector2(11.0, -3.0)
		f = [Vector2(-18, -18), Vector2(-22, -14)]
	# רגל אחורית + יד אחורית (רגל קדמית)
	z._leg(hip + Vector2(-1, 0), f[1], dark, dark, Color(0, 0, 0, 0))
	var bh := sh + Vector2(4.0 + sin(p + PI) * 6.0, 24.0 - maxf(0.0, cos(p + PI)) * 3.0)
	if air:
		bh = sh + Vector2(16.0, 6.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(-1, 1), sh.lerp(bh, 0.5) + Vector2(-3, 0), bh]), 3.2, dark)
	_claws(bh, dark)
	z._leg(hip + Vector2(1, 0), f[0], sk, sk, Color(0, 0, 0, 0))
	# גוף אופקי עם סמרטוטים ורכס חוליות
	var body := PackedVector2Array([hip + Vector2(-5, 4), hip + Vector2(-4, -5), sh + Vector2(2, -6), sh + Vector2(5, 3), hip + Vector2(6, 6)])
	Art.fill_shaded(z, body, sk, 0.2, 0.4)
	Art.fill(z, PackedVector2Array([hip + Vector2(-4, -4), sh + Vector2(1, -5), sh + Vector2(-2, 2), hip.lerp(sh, 0.5) + Vector2(0, 6), hip + Vector2(-2, 6)]), rag, Art.OUTLINE, 1.0)
	for i in 3:   # קרעים תלויים
		var tp: Vector2 = hip.lerp(sh, 0.2 + 0.3 * float(i)) + Vector2(0, 5)
		z.draw_line(tp, tp + Vector2(sin(z._time * 3.0 + float(i)) * 1.5, 5), rag, 1.4)
	for i in 6:   # חוליות
		var vp: Vector2 = hip.lerp(sh, float(i) / 5.0) + Vector2(0, -5.5)
		z.draw_colored_polygon(PackedVector2Array([vp + Vector2(-1.5, 0.5), vp + Vector2(0, -2.5), vp + Vector2(1.5, 0.5)]), col(Color("c8c0b0")))
	# ראש מוארך עם לסת ועדשה אדומה
	var jaw := 2.5 if z._bite_anim > 0.0 or air else 0.8
	Art.fill_shaded(z, PackedVector2Array([head + Vector2(-6, -4), head + Vector2(4, -5), head + Vector2(10, -1), head + Vector2(9, 1), head + Vector2(-5, 3)]), sk, 0.2, 0.35, Art.OUTLINE, 1.2)
	Art.fill(z, PackedVector2Array([head + Vector2(-3, 3), head + Vector2(8, 1.5 + jaw), head + Vector2(6, 3.5 + jaw), head + Vector2(-3, 5)]), dark, Art.OUTLINE, 1.0)
	for i in 3:   # שיניים
		z.draw_line(head + Vector2(2.0 + float(i) * 2.0, 1.2), head + Vector2(2.0 + float(i) * 2.0, 1.2 + jaw * 0.8), col(Color("e8e0c8")), 0.8)
	var eye := head + Vector2(3.5, -2.0)
	z.draw_circle(eye, 1.9, Color(0.1, 0.0, 0.0))
	z.draw_circle(eye, 1.2, Color(1.0, 0.12, 0.1))
	Art.glow(z, eye, 4.5, Color(1.0, 0.1, 0.05, 0.6))
	# יד קדמית
	var fh := sh + Vector2(6.0 + sin(p) * 6.0, 24.0 - maxf(0.0, cos(p)) * 3.0)
	if air or z._bite_anim > 0.0:
		fh = sh + Vector2(20.0, 4.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(1, 1), sh.lerp(fh, 0.5) + Vector2(-2, 1), fh]), 3.4, sk)
	_claws(fh, sk)
	end_draw()
	return true


func _claws(at: Vector2, c: Color) -> void:
	for i in 3:
		z.draw_line(at, at + Vector2(4.0, -1.0 + float(i) * 1.5), c, 1.0, true)


# האזהרה: סורג אוורור שרועד + עין אדומה מבצבצת
func _draw_tell() -> void:
	var k := clampf(_t / TELL_TIME, 0.0, 1.0)
	var shake := sin(_t * 60.0) * 1.5 * k
	var g := Vector2(shake, -2.0)
	z.draw_rect(Rect2(g + Vector2(-20, -4), Vector2(40, 6)), Color(0.08, 0.08, 0.1))
	for i in 6:
		z.draw_line(g + Vector2(-18 + i * 7, -4), g + Vector2(-18 + i * 7, 2), Color(0.55, 0.58, 0.62), 2.0)
	z.draw_rect(Rect2(g + Vector2(-21, -5), Vector2(42, 8)), Color(0.4, 0.42, 0.46), false, 1.5)
	var a := clampf(k * 1.6, 0.0, 1.0) * (0.6 + 0.4 * sin(_t * 14.0))
	Art.glow(z, g + Vector2(0, -9), 10.0 + 8.0 * k, Color(1.0, 0.1, 0.05, 0.7 * a))
	z.draw_circle(g + Vector2(-3, -8), 1.6, Color(1.0, 0.2, 0.1, a))
	z.draw_circle(g + Vector2(3, -8), 1.6, Color(1.0, 0.2, 0.1, a))
	if k > 0.5:   # ניצוץ של "ברק" בעין - glint
		var gl := (k - 0.5) * 2.0
		z.draw_line(g + Vector2(-9 * gl, -8), g + Vector2(9 * gl, -8), Color(1.0, 0.9, 0.8, 0.8 * (1.0 - gl * 0.5)), 1.0)
		z.draw_line(g + Vector2(0, -8 - 7 * gl), g + Vector2(0, -8 + 7 * gl), Color(1.0, 0.9, 0.8, 0.8 * (1.0 - gl * 0.5)), 1.0)
