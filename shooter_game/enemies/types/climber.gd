extends "res://enemies/zombie_type.gd"
# ============================================================
#  CLIMBER (שלב 5) - רזה וארוך-גפיים, רץ כפוף. כבר לא מטפס (טיפס על אוויר כשלא היה קיר).
#  נפגע (ולא מת): "נפתח" - 4 רגלי עכביש ארוכות פורצות לו מהגב (TRANSFORM, ~0.5 שנ', צווחה + דם).
#  צורת עכביש: רץ מהר יותר על הרגליים, וכל 1.2-2.2 שניות מתכווץ (אזהרה: צווחה, 0.32 שנ')
#  וקופץ גבוה מאוד (LEAP_H) בקשת אל השחקן. נוחת עליו = נזק.
#  צלילים (קיימים, בלי חדשים): "climb_hiss" (צווחה), "climb_scrape" (רגליים), "leap_land", "whoosh".
#  לשנות: LEAP_H (גובה הקפיצה), SPIDER_SPEED, LEG_LEN, TRANSFORM_T.  בדיקה: devtools/t_spider.gd
# ============================================================

const SOUNDS := {
	"climb_scrape": [["N", 0, 0, 0.0, 0.12, 0.01, 18.0, 0.35, 0.6, 0, 0.3], ["C", 0, 0, 0.0, 0.12, 0.0, 14.0, 0.4, 1.0, 0]],
	"climb_hiss": {"drive": 2.4, "layers": [["N", 0, 0, 0.0, 0.35, 0.02, 7.0, 0.6, 0.9, 0, 0.45], ["V", 380, 260, 0.0, 0.3, 0.01, 8.0, 0.4, 1.0, 0.1, 0, [900, 2100, 70]]]},
}

enum { HUMAN, TRANSFORM, SPIDER, CROUCH, AIR }
const TRANSFORM_T := 0.5
const CROUCH_T := 0.32
const LEAP_H := 300.0            # גובה הקפיצה (פיקסלי עולם)
const LEAP_MAX_X := 460.0
const SPIDER_SPEED := 1.45       # מהירות הריצה בצורת עכביש (כפול הרגיל)
const LEG_LEN := 1.0
var state := HUMAN
var grow := 0.0                  # 0..1 כמה הרגליים יצאו
var transforms := 0              # לבדיקות
var leaps := 0                   # לבדיקות
var _t := 0.0
var _cd := 0.0
var _hp0 := -1
var _hit_done := false
var _scrape := 0.0
var _gait := 0.0                 # מחזור הצעדים של רגלי העכביש (לפי מהירות)
var _move := 0.0                 # 0..1 כמה הוא הולך עכשיו


func stats() -> Dictionary:
	return {"name": "CLIMBER", "hp": 28, "walk": 60.0, "chase": 150.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 0.75,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9aa8"), "shirt": Color("3a3a40"), "pants": Color("2a2830"), "shoe": Color(0, 0, 0, 0), "points": 180}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15, "use_heights": 0.2, "flank_probability": 0.1}


func is_spider() -> bool:
	return state != HUMAN


func physics(pl: Node, delta: float) -> bool:
	if _hp0 < 0:
		_hp0 = z.hp
	_cd -= delta
	_t -= delta
	match state:
		HUMAN:
			if z.hp < _hp0 and not z.dead:   # נפגע ונשאר חי: נפתח לעכביש
				_start_transform()
				return true
			return false
		TRANSFORM:
			grow = clampf(1.0 - _t / TRANSFORM_T, 0.0, 1.0)
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1500.0 * delta)
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			z._walk_phase += delta * 30.0   # רעד
			if _t <= 0.0:
				grow = 1.0
				state = SPIDER
				_cd = randf_range(0.5, 1.0)
			return true
		SPIDER:
			if pl != null and not pl.dead and _cd <= 0.0 and z.is_on_floor() and z._chasing:
				var dx: float = pl.global_position.x - z.global_position.x
				if absf(dx) < 620.0 and absf(pl.global_position.y - z.global_position.y) < 260.0:
					state = CROUCH
					_t = CROUCH_T
					z._dir = signf(dx) if dx != 0.0 else z._dir
					Sfx.play("climb_hiss", z.global_position, -2.0, 0.1, 2)
					return true
			var spd := absf(z.velocity.x)
			_move = move_toward(_move, clampf(spd / 120.0, 0.0, 1.0), delta * 4.0)
			_gait += delta * (1.5 + spd * 0.075)
			_scrape -= delta
			if _scrape <= 0.0 and absf(z.velocity.x) > 40.0:
				_scrape = 0.3
				Sfx.play("climb_scrape", z.global_position, -12.0, 0.2, 2)
			return false   # המוח מזיז אותו (מהר יותר: logic)
		CROUCH:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 1800.0 * delta)
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if _t <= 0.0:
				_leap(pl)
			return true
		AIR:
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			z._walk_phase += delta * 4.0
			if pl != null and not pl.dead and not _hit_done:
				var r: Rect2 = pl.body_rect()
				if r.grow(6.0).has_point(z.global_position + Vector2(0, -20.0 * z.sc)) or r.grow(4.0).has_point(z.global_position):
					_hit_done = true
					z._attack_t = z.bite_delay
					z._bite_anim = 0.3
					pl.hurt(z.damage, Vector2(signf(z.velocity.x), 0.0))
			if z.is_on_floor() and z.velocity.y >= 0.0:
				state = SPIDER
				_cd = randf_range(1.2, 2.2)
				Sfx.play("leap_land", z.global_position, -3.0, 0.1, 2)
				if Art.on_screen(z, z.global_position):
					Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 5)
			return true
	return false


func _start_transform() -> void:
	state = TRANSFORM
	_t = TRANSFORM_T
	grow = 0.0
	transforms += 1
	Sfx.play("climb_hiss", z.global_position, 2.0, 0.05, 2)
	if Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), z.global_position + Vector2(-4.0, -30.0 * z.sc), "hit", Vector2.UP, 10)


# קפיצה גבוהה בקשת אל השחקן (או לכיוונו, עד LEAP_MAX_X)
func _leap(pl: Node) -> void:
	var g: float = z.gravity
	var vy := -sqrt(2.0 * g * LEAP_H)
	var t_up := -vy / g
	var dx: float = 0.0
	var dy: float = 0.0
	if pl != null and not pl.dead:
		dx = clampf(pl.global_position.x - z.global_position.x, -LEAP_MAX_X, LEAP_MAX_X)
		if absf(dx) < 110.0:   # צמוד לשחקן: קופץ מעליו לצד השני
			dx = (signf(dx) if dx != 0.0 else z._dir) * 230.0
		dy = clampf(pl.global_position.y - z.global_position.y, -LEAP_H * 0.8, 200.0)
	var t := t_up + sqrt(2.0 * maxf(LEAP_H + dy, 10.0) / g)   # עד שנוחת בגובה של השחקן
	z.velocity = Vector2(dx / t, vy)
	z._dir = signf(dx) if dx != 0.0 else z._dir
	state = AIR
	_hit_done = false
	leaps += 1
	Sfx.play("whoosh", z.global_position, -2.0, 0.1, 2)


func logic(_pl: Node, _d: Vector2, _delta: float, speed: float) -> float:
	if state == SPIDER:
		return speed * SPIDER_SPEED
	return speed


func draw() -> bool:
	if state == HUMAN or z.dead:
		return _draw_human()
	return _draw_spider()


func _draw_human() -> bool:
	var sk := col(z.skin)
	var dark := col(Art.shade(z.skin, 0.35))
	var claw := col(Color("8a1a14"))
	var p: float = z._walk_phase
	begin_draw()
	var f: Array = feet(8.0, 4.0)
	var hip := Vector2(-2.0, -22.0 + absf(sin(p)) * 1.5)
	var sh := Vector2(9.0, -36.0)
	var head := sh + Vector2(8.0, -2.0)
	z._leg(hip + Vector2(-1, 0), f[1], dark, dark, Color(0, 0, 0, 0))
	var reach := 22.0 if z._bite_anim > 0.0 else 14.0
	var bh := sh + Vector2(reach - 4.0, 14.0 + sin(p) * 4.0)
	Art.limb(z, PackedVector2Array([sh, sh + Vector2(4, 9), bh]), 3.0, dark)
	_claws(bh, Vector2(1, 0.3), claw)
	z._leg(hip + Vector2(1, 0), f[0], sk, sk, Color(0, 0, 0, 0))
	_torso(hip, sh, sk)
	_head(head, sk)
	var fh := sh + Vector2(reach, 10.0 - sin(p) * 4.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(2, 1), sh + Vector2(9, 7), fh]), 3.2, sk)
	_claws(fh, Vector2(1, 0.2), claw)
	end_draw()
	return true


func _torso(hip: Vector2, sh: Vector2, sk: Color) -> void:
	Art.fill_shaded(z, PackedVector2Array([hip + Vector2(-4, 2), hip + Vector2(4, 1), sh + Vector2(4, 3), sh + Vector2(-3, -2)]), sk, 0.2, 0.4)
	for i in 4:
		var rp: Vector2 = hip.lerp(sh, 0.35 + float(i) * 0.15)
		DrawBatch.line(z, rp + Vector2(-2, 0), rp + Vector2(4, 1), col(Color(0.3, 0.32, 0.36, 0.7)), 0.8)
	for i in 6:   # חוליות בולטות על הגב
		DrawBatch.circle(z, hip.lerp(sh, float(i) / 5.0) + Vector2(-3.5, -1.0), 1.3, col(Color("d8d0c0")))


func _head(head: Vector2, sk: Color) -> void:
	Art.oval_shaded(z, head, 5.5, 6.5, sk, 0.4)
	DrawBatch.line(z, head + Vector2(2, 2), head + Vector2(6, 3), Color(0.2, 0.0, 0.0), 1.2)
	DrawBatch.circle(z, head + Vector2(3.0, -1.5), 1.2, Color(1.0, 0.2, 0.1))
	Art.glow(z, head + Vector2(3.0, -1.5), 3.0, Color(1.0, 0.1, 0.05, 0.6))


# צורת עכביש: גוף נמוך ואופקי שתלוי בין 4 רגליים ארוכות שיוצאות מהגב (ברכיים גבוהות מעל הגוף),
# רגלי האדם מקופלות מתחת. TRANSFORM: הרגליים גדלות (grow) והגוף רועד. CROUCH: הכל מתכווץ. AIR: רגליים פרושות.
func _draw_spider() -> bool:
	var sk := col(z.skin)
	var dark := col(Art.shade(z.skin, 0.35))
	var leg_c := col(Color("3a3236"))
	var leg_hi := col(Color("6a2a26"))
	var claw := col(Color("8a1a14"))
	var p: float = z._walk_phase
	var g := grow
	var squash := 0.0
	if state == CROUCH:
		squash = 1.0 - clampf(_t / CROUCH_T, 0.0, 1.0)
	var walk := _move if state == SPIDER else 0.0
	var lift := lerpf(22.0, 27.0, g) - 12.0 * squash + sin(_gait * 2.0) * 1.8 * walk   # גובה הגוף מעל הריצפה (מתנדנד בהליכה)
	var shake := Vector2(sin(p * 1.7) * 1.5, cos(p * 2.3) * 1.0) if state == TRANSFORM else Vector2.ZERO
	begin_draw()
	var hip := Vector2(-10.0, -lift) + shake
	var sh := Vector2(10.0, -lift - 6.0) + shake
	var air := state == AIR
	# 4 רגלי עכביש: 2 אחוריות (כהות) ואז 2 קדמיות
	for pass_i in 2:
		for k in 2:
			var i := k * 2 + pass_i   # 0,2 אחוריות; 1,3 קדמיות
			var front := pass_i == 1
			var root: Vector2 = hip.lerp(sh, 0.25 + 0.5 * float(k))
			var side := -1.0 if k == 0 else 1.0                       # רגל אחורית/קדמית בכיוון התנועה
			# הליכה: זוגות אלכסוניים (אחורית+קדמית מנוגדות) צועדים יחד. כף הרגל זזה קדימה באוויר ואחורה על הריצפה.
			var ph := _gait + (0.0 if i == 0 or i == 3 else PI)
			var reach := (24.0 + 8.0 * float(k)) * LEG_LEN * g
			var step := sin(ph) * (2.0 + 12.0 * walk) * g
			var up := maxf(0.0, cos(ph)) * (1.0 + 10.0 * walk) * g
			var knee := Vector2(root.x + side * reach * 0.8 + step * 0.45, -lift - 34.0 * g + 8.0 * squash - up * 0.6)   # ברך גבוהה מעל הגוף
			var ankle := Vector2(root.x + side * reach * 1.2 + step * 0.6, -14.0 * g - up)
			var foot := Vector2(root.x + side * reach * 1.3 + step, -up)
			if air:   # באוויר: רגליים פרושות למטה ולצדדים
				knee = Vector2(root.x + side * reach * 0.8, -lift - 16.0 * g)
				ankle = Vector2(root.x + side * reach * 1.25, -lift + 6.0 * g)
				foot = Vector2(root.x + side * reach * 1.3, -lift + 22.0 * g)
			if g < 0.98:   # עוד גדלות: יוצאות מהגב
				foot = root.lerp(foot, g)
				ankle = root.lerp(ankle, g)
				knee = root.lerp(knee, g)
			var c := leg_c if front else col(Art.shade(Color("3a3236"), 0.35))
			Art.limb(z, PackedVector2Array([root, knee, ankle]), 3.0 if front else 2.4, c)
			Art.limb(z, PackedVector2Array([ankle, foot]), 1.8 if front else 1.5, c)
			DrawBatch.circle(z, knee, 1.8, leg_hi)   # מפרק אדום
			_claws(foot, Vector2(side * 0.3, 1.0).normalized(), claw)
	# רגלי האדם מקופלות מתחת לגוף
	Art.limb(z, PackedVector2Array([hip, hip + Vector2(-4, 9), hip + Vector2(5, 13)]), 3.0, dark)
	# גוף אופקי, ראש קדימה ונמוך, פה פתוח
	_torso(hip, sh, sk)
	var head := sh + Vector2(8.0, 3.0 + 2.0 * squash)
	_head(head, sk)
	if state == CROUCH or air or state == TRANSFORM:
		DrawBatch.line(z, head + Vector2(1, 3), head + Vector2(6, 5), Color(0.35, 0.0, 0.0), 2.0)
	# ידיים: טפרים קדימה
	var fh := sh + Vector2(16.0, 10.0 + sin(p) * 2.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(2, 1), sh + Vector2(9, 6), fh]), 3.0, sk)
	_claws(fh, Vector2(1, 0.3), claw)
	end_draw()
	return true


func _claws(at: Vector2, dir: Vector2, c: Color) -> void:
	for i in 3:
		var a := dir.rotated(-0.5 + float(i) * 0.5)
		DrawBatch.line(z, at, at + a * 5.0, c, 1.2, true)
