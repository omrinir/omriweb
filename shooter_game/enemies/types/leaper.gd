extends "res://enemies/zombie_type.gd"
# ============================================================
#  LEAPER (שלב 7) - קופץ למרחקים ארוכים בין גשרים, מעליות וקומות.
#  צללית: רגליים ארוכות "הפוכות" (ברך לאחור, כמו צפרדע / ארבה), גוף נמוך ומוטה קדימה,
#         ידיים ארוכות ודקות שנגררות, ראש קטן עם לסת רחבה.
#  צבעים: עור אפור-לילך חיוור, שאריות סרבל עבודה כתום, גידים סגולים זוהרים ברגליים
#         (נדלקים חזק כשהוא נטען לקפיצה).
#  תנועה: על הקרקע רץ כפוף (המוח מזיז אותו). כל 1.5-3 שניות בוחר נקודת נחיתה:
#    * השחקן קרוב ובאותו גובה -> זינוק ישר עליו (pounce).
#    * השחקן בגובה אחר / רחוק -> קפיצה בקשת גדולה אל הקומה / הגשר / המעלית
#      הכי קרובים לשחקן (סורק קומות בקבוצה "platforms" + קרן אל הריצפה).
#    לפני כל קפיצה: כיווץ של 0.45 שנ' עם קרקור עולה (אזהרה הוגנת).
#  התקפה: נוחת על השחקן (נזק + הדיפה), נשיכה רגילה על הקרקע.
#  צלילים: "leap_charge" (קרקור עולה), "leap_land" (חבטת נחיתה).
# ============================================================

const SOUNDS := {
	"leap_charge": {"drive": 2.6, "layers": [["V", 110, 260, 0.0, 0.42, 0.03, 2.0, 0.85, 1.0, 0.05, 0, [520, 1300, 22]], ["N", 0, 0, 0.0, 0.42, 0.1, 3.0, 0.15, 0.3, 0, 0.1]]},
	"leap_land": [["S", 95, 40, 0.0, 0.2, 0.0, 16.0, 0.9, 1.0, 0], ["N", 0, 0, 0.0, 0.14, 0.0, 22.0, 0.6, 0.18, 0]],
}

enum { GROUND, CHARGE, AIR }
var state := GROUND
var leaps := 0             # לבדיקות
var platform_leaps := 0    # קפיצות שנחתו בגובה אחר
var _cd := 1.2
var _charge_t := 0.0
var _target := Vector2.ZERO
var _hit_done := false
var _start_y := 0.0


func stats() -> Dictionary:
	return {"name": "LEAPER", "hp": 22, "walk": 55.0, "chase": 120.0, "damage": 1, "bite_delay": 0.75, "scale": 0.95, "width": 0.85,
		"duck": 0.2, "cover": 0.1, "skin": Color("a49aac"), "shirt": Color("b0581e"), "pants": Color("6a3a1e"), "shoe": Color(0, 0, 0, 0), "points": 240}


func brain_overrides() -> Dictionary:
	return {"use_heights": -1.0, "aggression": 0.1, "flank_probability": 0.1}   # גבהים: הוא קופץ בעצמו


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	if pl == null or pl.dead:
		if state != AIR:
			state = GROUND
		if state == GROUND:
			return false
	match state:
		GROUND:
			if _cd <= 0.0 and z.is_on_floor() and z._chasing:
				var tg = _pick_target(pl)
				if tg != null:
					_target = tg
					state = CHARGE
					_charge_t = 0.45
					Sfx.play("leap_charge", z.global_position, -2.0, 0.08, 2)
				else:
					_cd = 0.6
			return false
		CHARGE:
			_charge_t -= delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1400.0 * delta)
			z.velocity.y += z.gravity * delta
			var tdx: float = _target.x - z.global_position.x
			if tdx != 0.0:
				z._dir = signf(tdx)
			z.move_and_slide()
			if _charge_t <= 0.0:
				_launch()
			return true
		AIR:
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if pl != null and not pl.dead and not _hit_done:
				var r: Rect2 = pl.body_rect()
				if r.grow(6.0).has_point(z.global_position + Vector2(0, -24.0 * z.sc)) or r.grow(4.0).has_point(z.global_position):
					_hit_done = true
					z._attack_t = z.bite_delay
					z._bite_anim = 0.3
					pl.hurt(z.damage, Vector2(signf(z.velocity.x), 0.0))
			if z.is_on_floor() and z.velocity.y >= 0.0:
				state = GROUND
				_cd = randf_range(1.5, 2.8)
				if absf(z.global_position.y - _start_y) > 60.0:
					platform_leaps += 1
				Sfx.play("leap_land", z.global_position, -2.0, 0.1, 2)
				if Art.on_screen(z, z.global_position):
					Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 5)
			return true
	return false


func _launch() -> void:
	var from: Vector2 = z.global_position
	var dx := _target.x - from.x
	var dy := _target.y - from.y
	var g: float = z.gravity
	var rise := maxf(0.0, -dy)
	var t := maxf(maxf(absf(dx) / 520.0, 0.55), sqrt(2.0 * (rise + 30.0) / g) + 0.14)
	z.velocity = Vector2(dx / t, (dy - 0.5 * g * t * t) / t)
	z._dir = signf(dx) if dx != 0.0 else z._dir
	state = AIR
	_hit_done = false
	_start_y = from.y
	leaps += 1
	Sfx.play("whoosh", from, -2.0, 0.1, 2)


# בחירת נקודת נחיתה: עליו / קומה ליד השחקן / קרקע לכיוונו. null = אין קפיצה טובה
func _pick_target(pl: Node) -> Variant:
	var zp: Vector2 = z.global_position
	var pp: Vector2 = pl.global_position
	var d := pp - zp
	# זינוק ישר על השחקן
	if absf(d.x) < 300.0 and absf(d.x) > 60.0 and absf(d.y) < 50.0:
		return pp
	var best = null
	var best_score := absf(d.x) + absf(d.y) * 1.5 - 90.0   # צריך לשפר משמעותית
	# קומות / גשרים / מעליות
	for plat in z.get_tree().get_nodes_in_group("platforms"):
		var r: Rect2 = plat.world_rect()
		if r.size.x < 40.0:
			continue
		var tx := clampf(pp.x, r.position.x + 14.0, r.end.x - 14.0)
		var cand := Vector2(tx, r.position.y)
		if _reachable(zp, cand):
			var sc := absf(pp.x - cand.x) + absf(pp.y - cand.y) * 1.5
			if sc < best_score:
				best_score = sc
				best = cand
	# הקרקע / משטח בגובה של השחקן בכיוון שלו
	var gx := zp.x + clampf(d.x, -440.0, 440.0)
	var q := PhysicsRayQueryParameters2D.create(Vector2(gx, pp.y - 40.0), Vector2(gx, pp.y + 400.0), 1 | 16)
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		var hp: Vector2 = hit.position
		if _reachable(zp, hp):
			var sc := absf(pp.x - hp.x) + absf(pp.y - hp.y) * 1.5
			if sc < best_score:
				best = hp
	return best


func _reachable(from: Vector2, to: Vector2) -> bool:
	var dx := absf(to.x - from.x)
	var rise := from.y - to.y
	return dx <= 470.0 and dx >= 40.0 and rise <= 250.0 and rise >= -320.0


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == CHARGE:   # נפגע בזמן כיווץ: הקפיצה מתבטלת
		state = GROUND
		_cd = 1.0
	return true


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var skd := col(Art.shade(z.skin, 0.3))
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var t: float = z._time
	var charging: bool = state == CHARGE and not z.dead
	var air: bool = state == AIR and not z.dead
	var squash := 0.0
	if charging:
		squash = clampf(1.0 - _charge_t / 0.45, 0.0, 1.0)
	var glow_k := 0.35 + 0.15 * sin(t * 4.0) + 0.6 * squash + (0.3 if air else 0.0)
	var tendon := Color(0.85, 0.3, 1.0)
	var hip := Vector2(-4.0, lerpf(-26.0, -14.0, squash) + absf(sin(p)) * 1.5)
	var sh := hip + Vector2(14.0, lerpf(-10.0, -6.0, squash))
	var head := sh + Vector2(7.0, -3.0)
	if air:
		hip = Vector2(-6.0, -26.0)
		sh = hip + Vector2(18.0, -6.0)
		head = sh + Vector2(8.0, -1.0)
	# רגליים הפוכות: ירך קדימה, ברך-הפוכה מאחור, כף ארוכה
	for side in [-1.0, 1.0]:
		var c: Color = sk if side > 0.0 else skd
		var ph: float = p + (0.0 if side > 0.0 else PI)
		var foot := Vector2(sin(ph) * 7.0 + side * 2.0, -maxf(0.0, cos(ph)) * 3.0)
		if not z.is_on_floor() and not z.dead:
			foot = Vector2(-16.0 + side * 3.0, -10.0)
		if charging:
			foot = Vector2(-2.0 + side * 4.0, 0.0)
		var knee := hip + Vector2(lerpf(9.0, 11.0, squash), lerpf(9.0, 4.0, squash))
		var hock := foot + Vector2(lerpf(-6.0, -9.0, squash), lerpf(-10.0, -5.0, squash))
		if air:
			knee = hip + Vector2(6.0, 8.0)
			hock = foot + Vector2(8.0, -3.0)
		Art.limb(z, PackedVector2Array([hip + Vector2(0, side), knee]), 5.2 if side > 0.0 else 4.6, c)   # ירך שרירית
		Art.limb(z, PackedVector2Array([knee, hock, foot]), 3.2 if side > 0.0 else 2.8, c)
		# גידים זוהרים
		z.draw_line(knee, hock, Color(tendon, clampf(glow_k, 0.0, 1.0) * (1.0 if side > 0.0 else 0.6)), 1.2)
		if glow_k > 0.6:
			Art.glow(z, hock, 4.0 + squash * 3.0, Color(tendon, 0.4 * glow_k))
		for k in 3:   # אצבעות ארוכות
			z.draw_line(foot, foot + Vector2(4.0 + float(k), -1.0 + float(k)), c, 1.2)
	# גוף נמוך עם שאריות סרבל
	Art.fill_shaded(z, PackedVector2Array([hip + Vector2(-4, 4), hip + Vector2(3, 5), sh + Vector2(3, 4), sh + Vector2(-2, -4), hip + Vector2(-5, -3)]), suit, 0.15, 0.4)
	z.draw_line(hip.lerp(sh, 0.3) + Vector2(0, -3), hip.lerp(sh, 0.3) + Vector2(1, 4), col(Color(0.9, 0.9, 0.8, 0.6)), 1.0)   # פס מחזיר אור
	for i in 5:   # עמוד שדרה בולט
		z.draw_circle(hip.lerp(sh, float(i) / 4.0) + Vector2(0, -4.5), 1.1, col(Color("d8ccd8")))
	# ידיים ארוכות שנגררות / מושטות קדימה באוויר
	var reach: bool = air or z._bite_anim > 0.0
	for side in [-1.0, 1.0]:
		var c2: Color = sk if side > 0.0 else skd
		var hand := sh + (Vector2(20.0, -2.0 + side * 3.0) if reach else Vector2(6.0 + side * 3.0 + sin(p + side) * 3.0, 20.0 - squash * 6.0))
		Art.limb(z, PackedVector2Array([sh + Vector2(0, side), sh.lerp(hand, 0.5) + Vector2(-2, 3), hand]), 2.6, c2)
		for k in 3:
			z.draw_line(hand, hand + Vector2.from_angle(0.3 + float(k) * 0.4 - (0.0 if reach else -1.0)) * 4.0, col(Color("3a2a30")), 1.0)
	# ראש קטן עם לסת רחבה
	Art.oval_shaded(z, head, 5.5, 5.0, sk, 0.0)
	var jaw := 2.0 + (3.5 if reach or charging else sin(t * 5.0))
	Art.fill(z, PackedVector2Array([head + Vector2(0, 1.5), head + Vector2(8, 1.0), head + Vector2(7, 2.5 + jaw), head + Vector2(0.5, 3.5 + jaw * 0.6)]), Color("2a0a14"), Art.OUTLINE, 0.8)
	for i in 3:
		z.draw_line(head + Vector2(2.0 + i * 2.0, 1.4), head + Vector2(2.4 + i * 2.0, 2.8), Color("e0d8c8"), 0.7)
	z.draw_circle(head + Vector2(3.0, -1.8), 1.1, Color(1.0, 0.25, 0.2))
	Art.glow(z, head + Vector2(3.0, -1.8), 3.0, Color(1.0, 0.2, 0.2, 0.5))
	end_draw()
	return true
