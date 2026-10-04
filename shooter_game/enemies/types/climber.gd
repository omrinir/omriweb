extends "res://enemies/zombie_type.gd"
# ============================================================
#  CLIMBER (שלב 5) - רזה וארוך-גפיים, מטפס על קירות של בניינים.
#  צללית: גוף צנום כפוף, ידיים ארוכות עם טפרים אדומים, עמוד שדרה בולט, בלי חולצה.
#  תנועה: על הקרקע רץ כפוף. מטפס על הקיר כדי להיות מעל השחקן,
#         זוחל על הקיר לכיוונו, ואז קופץ עליו מלמעלה (התקפת קפיצה).
#  צליל: שריטות על בטון + נשיפה חדה לפני הקפיצה ("climb_scrape", "climb_hiss").
#  ירייה בזמן שהוא על הקיר = נופל.
# ============================================================

const SOUNDS := {
	"climb_scrape": [["N", 0, 0, 0.0, 0.12, 0.01, 18.0, 0.35, 0.6, 0, 0.3], ["C", 0, 0, 0.0, 0.12, 0.0, 14.0, 0.4, 1.0, 0]],
	"climb_hiss": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.35, 0.02, 7.0, 0.6, 0.9, 0, 0.45], ["V", 380, 260, 0.0, 0.3, 0.01, 8.0, 0.4, 1.0, 0.1, 0, [900, 2100, 70]]]},
}

enum { GROUND, CLIMB, WALL, POUNCE }
var state := GROUND
var _cd := 2.5
var _target_y := 0.0
var _scrape := 0.0


func stats() -> Dictionary:
	return {"name": "CLIMBER", "hp": 22, "walk": 60.0, "chase": 150.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 0.75,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9aa8"), "shirt": Color("3a3a40"), "pants": Color("2a2830"), "shoe": Color(0, 0, 0, 0), "points": 180}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15, "use_heights": 0.4, "flank_probability": 0.1}


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	if pl == null or pl.dead:
		state = GROUND
		return false
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		GROUND:
			# מחליט לטפס: השחקן למעלה, או סתם כדי להגיע מעליו
			if _cd <= 0.0 and z.is_on_floor() and absf(d.x) < 420.0 and absf(d.x) > 90.0 and z._chasing:
				_cd = randf_range(4.0, 7.0)
				if d.y < -60.0 or randf() < 0.55:
					state = CLIMB
					_target_y = minf(pl.global_position.y - 130.0, z.global_position.y - 120.0)
					z.collision_mask &= ~16   # עובר דרך קומות בזמן טיפוס
					Sfx.play("climb_scrape", z.global_position, -6.0)
			return false
		CLIMB:
			z.velocity = Vector2(0.0, -150.0 * z._speed_mul)
			z.move_and_slide()
			_scrape -= delta
			if _scrape <= 0.0:
				_scrape = 0.35
				Sfx.play("climb_scrape", z.global_position, -10.0, 0.2, 2)
			z._walk_phase += delta * 10.0
			if z.global_position.y <= _target_y or z.is_on_ceiling():
				state = WALL
			return true
		WALL:   # נצמד לקיר ומתקרב לשחקן מלמעלה
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			z.velocity = Vector2(z._dir * 70.0, 0.0)
			if absf(d.x) < 30.0:
				z.velocity.x = 0.0
			z.move_and_slide()
			z._walk_phase += delta * 6.0
			if absf(d.x) < 170.0 and d.y > 40.0:   # מעליו: קפיצה!
				state = POUNCE
				var t := 0.55
				z.velocity = Vector2(d.x / t, (d.y - 0.5 * z.gravity * t * t) / t)
				z.velocity.x = clampf(z.velocity.x, -520.0, 520.0)
				z.collision_mask |= 16
				Sfx.play("climb_hiss", z.global_position, 0.0)
			elif _cd < -6.0:   # משעמם: יורד
				state = POUNCE
				z.velocity = Vector2(0.0, 0.0)
				z.collision_mask |= 16
			return true
		POUNCE:
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			var dd: Vector2 = pl.global_position - z.global_position
			if absf(dd.x) < 22.0 and absf(dd.y + 20.0) < 36.0 and z._attack_t <= 0.0:   # נחת עליו
				z._attack_t = z.bite_delay
				z._bite_anim = 0.3
				pl.hurt(z.damage, Vector2(signf(z.velocity.x), 0.0))
			if z.is_on_floor():
				state = GROUND
				_cd = randf_range(3.0, 6.0)
			return true
	return false


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == WALL or state == CLIMB:   # נפגע על הקיר: נופל
		state = POUNCE
		z.velocity = Vector2(_dir.x * 80.0, 0.0)
		z.collision_mask |= 16
	return true


func draw() -> bool:
	var on_wall: bool = (state == CLIMB or state == WALL) and not z.dead
	var sk := col(z.skin)
	var dark := col(Art.shade(z.skin, 0.35))
	var claw := col(Color("8a1a14"))
	var p: float = z._walk_phase
	if on_wall:
		# על הקיר: גוף אנכי, ידיים ורגליים נאחזות לסירוגין (מצויר "פונה למעלה")
		z.draw_set_transform(Vector2(0, -20.0 * z.sc), 0.0, Vector2(z._dir * z.sc, z.sc))
		var a := sin(p) * 6.0
		for side in [-1.0, 1.0]:
			var sh := Vector2(side * 5.0, -14.0)
			var hand := sh + Vector2(side * 9.0, -10.0 + a * side)
			Art.limb(z, PackedVector2Array([sh, sh + Vector2(side * 9.0, -2.0), hand]), 3.0, sk if side > 0.0 else dark)
			_claws(hand, Vector2(0, -1), claw)
			var hip := Vector2(side * 4.0, 6.0)
			var foot := hip + Vector2(side * 8.0, 10.0 - a * side)
			Art.limb(z, PackedVector2Array([hip, hip + Vector2(side * 9.0, 2.0), foot]), 3.4, sk if side > 0.0 else dark)
		Art.fill_shaded(z, PackedVector2Array([Vector2(-5, -16), Vector2(5, -16), Vector2(4, 8), Vector2(-4, 8)]), sk, 0.2, 0.4)
		for i in 6:   # עמוד שדרה
			z.draw_circle(Vector2(0, -13 + i * 4), 1.2, col(Color("d8d0c0")))
		Art.oval_shaded(z, Vector2(0, -22), 5.0, 6.0, sk, 0.0)
		z.draw_circle(Vector2(-2, -24), 1.0, Color(1.0, 0.2, 0.1))
		z.draw_circle(Vector2(2, -24), 1.0, Color(1.0, 0.2, 0.1))
		end_draw()
		return true
	begin_draw()
	var f: Array = feet(8.0, 4.0)
	var hunch := 9.0
	var hip := Vector2(-2.0, -22.0 + absf(sin(p)) * 1.5)
	var sh := Vector2(hunch, -36.0)
	var head := sh + Vector2(8.0, -2.0)
	if state == POUNCE and not z.dead:   # באוויר: גפיים פרושות קדימה
		f = [Vector2(-8, -10), Vector2(-12, -6)]
		head = sh + Vector2(10, -4)
	# רגל אחורית + יד אחורית
	z._leg(hip + Vector2(-1, 0), f[1], dark, dark, Color(0, 0, 0, 0))
	var reach := 22.0 if z._bite_anim > 0.0 or state == POUNCE else 14.0
	var bh := sh + Vector2(reach - 4.0, 14.0 + sin(p) * 4.0)
	Art.limb(z, PackedVector2Array([sh, sh + Vector2(4, 9), bh]), 3.0, dark)
	_claws(bh, Vector2(1, 0.3), claw)
	z._leg(hip + Vector2(1, 0), f[0], sk, sk, Color(0, 0, 0, 0))
	# גוף צנום כפוף עם צלעות
	Art.fill_shaded(z, PackedVector2Array([hip + Vector2(-4, 2), hip + Vector2(4, 1), sh + Vector2(4, 3), sh + Vector2(-3, -2)]), sk, 0.2, 0.4)
	for i in 4:
		var rp: Vector2 = hip.lerp(sh, 0.35 + float(i) * 0.15)
		z.draw_line(rp + Vector2(-2, 0), rp + Vector2(4, 1), col(Color(0.3, 0.32, 0.36, 0.7)), 0.8)
	for i in 6:   # חוליות בולטות על הגב
		z.draw_circle(hip.lerp(sh, float(i) / 5.0) + Vector2(-3.5, -1.0), 1.3, col(Color("d8d0c0")))
	# ראש קטן ומוארך
	Art.oval_shaded(z, head, 5.5, 6.5, sk, 0.4)
	z.draw_line(head + Vector2(2, 2), head + Vector2(6, 3), Color(0.2, 0.0, 0.0), 1.2)
	z.draw_circle(head + Vector2(3.0, -1.5), 1.2, Color(1.0, 0.2, 0.1))
	Art.glow(z, head + Vector2(3.0, -1.5), 3.0, Color(1.0, 0.1, 0.05, 0.6))
	# יד קדמית ארוכה עם טפרים
	var fh := sh + Vector2(reach, 10.0 - sin(p) * 4.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(2, 1), sh + Vector2(9, 7), fh]), 3.2, sk)
	_claws(fh, Vector2(1, 0.2), claw)
	end_draw()
	return true


func _claws(at: Vector2, dir: Vector2, c: Color) -> void:
	for i in 3:
		var a := dir.rotated(-0.5 + float(i) * 0.5)
		z.draw_line(at, at + a * 5.0, c, 1.2, true)
