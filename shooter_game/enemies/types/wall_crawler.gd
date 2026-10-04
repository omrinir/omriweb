extends "res://enemies/zombie_type.gd"
# ============================================================
#  WALL CRAWLER (שלב 6) - זוחל על הקירות ועל התקרה, מחכה מעל השחקן ונופל עליו.
#  צללית: עכבישית - גוף שטוח ונמוך, ארבע גפיים ארוכות עם מפרקים גבוהים מעל הגוף,
#         שיער שחור ארוך שתמיד נופל למטה (גם כשהוא תלוי הפוך), חולצה לבנה קרועה.
#  צבעים: עור אפור-כחלחל, נקודות ציאן זוהרות לאורך עמוד השדרה, 4 עיניים ציאן.
#  תנועה: על הריצפה זוחל על ארבע. כשהוא רודף - מטפס על הקיר שמאחור עד התקרה
#         (התחתית של הקומה השנייה, או תקרת הקומה השנייה - קבוצת "s6_roof"),
#         זוחל הפוך לכיוון השחקן, ו"קופא" כשהשחקן מסתכל אליו מקרוב (מחכה).
#  התקפה: כשהוא בדיוק מעל השחקן - רעד קצר + צווחה (רמז הוגן), ואז צלילה עם הראש למטה.
#         אחרי הנחיתה: נושך פעם אחת, בורח קצת ומטפס בחזרה לתקרה.
#  ירייה בזמן שהוא על הקיר / תקרה = נופל ומתבלבל לרגע (וגם מקבל יותר נזק).
#  צלילים: "crawl_click" (קליקים של מפרקים), "crawl_shriek" (צווחה יורדת לפני הצלילה)
#  לשנות: CLIMB_SPEED, CRAWL_SPEED, TELL_TIME (זמן האזהרה לפני הצלילה).
# ============================================================

const SOUNDS := {
	"crawl_click": [["C", 0, 0, 0.0, 0.32, 0.0, 4.0, 0.8, 1.0, 0], ["S", 1800, 1650, 0.0, 0.025, 0.0, 110.0, 0.28, 1.0, 0], ["S", 1500, 1400, 0.08, 0.025, 0.0, 110.0, 0.25, 1.0, 0], ["S", 2000, 1850, 0.15, 0.025, 0.0, 110.0, 0.25, 1.0, 0], ["S", 1300, 1250, 0.24, 0.025, 0.0, 110.0, 0.2, 1.0, 0]],
	"crawl_shriek": {"drive": 2.6, "layers": [["V", 950, 280, 0.0, 0.55, 0.01, 3.2, 0.8, 1.0, 0.07, 0, [1400, 3100, 95]], ["N", 0, 0, 0.0, 0.4, 0.0, 6.0, 0.3, 0.9, 0, 0.45]]},
}

const CLIMB_SPEED := 210.0
const CRAWL_SPEED := 125.0
const TELL_TIME := 0.42

enum { GROUND, CLIMB, CEILING, TELL, DROP, LAND, HUNT, FLEE }
var state := GROUND
var ceil_y := 0.0
var wall := false        # true = אין תקרה: נצמד לקיר בגובה (לא זוחל הפוך)
var _x_min := -INF
var _x_max := INF
var _cd := 1.5
var _t := 0.0
var _away := 0.0         # כמה זמן השחקן לא מתחתיו
var _click := 0.0
var _hit := false        # כבר פגע בצלילה הזו
var _shot := false       # הופל ביריה
var drops := 0           # לבדיקות: כמה צלילות
var climbs := 0          # לבדיקות: כמה פעמים טיפס


func stats() -> Dictionary:
	return {"name": "WALL CRAWLER", "hp": 20, "walk": 55.0, "chase": 140.0, "damage": 1, "bite_delay": 0.6, "scale": 0.95, "width": 1.0,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a98a8"), "shirt": Color("c4c0b4"), "pants": Color("2a2e36"), "shoe": Color(0, 0, 0, 0), "points": 230}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "use_heights": -0.5, "flank_probability": -0.2}


# השלב יכול להתחיל אותו תלוי על התקרה (y = התקרה)
func start_on_ceiling(y: float) -> void:
	_find_ceiling(Vector2(z.global_position.x, y + 60.0))
	ceil_y = y
	wall = false
	_attach()


func on_ceiling_now() -> bool:
	return state == CEILING or state == TELL or state == CLIMB


func _attach() -> void:
	state = CEILING
	_away = 0.0
	z.global_position.y = ceil_y
	z.velocity = Vector2.ZERO
	z.collision_mask = 0
	z._shape.position.y = 33.0 * z.sc   # אזור הפגיעה תלוי מתחת לתקרה


func _detach() -> void:
	z.collision_mask = 1 | 16
	z._shape.position.y = -33.0 * z.sc


# התקרה הכי קרובה מעל נקודה: תחתית של קומה (platforms) או תקרת הבניין (s6_roof)
func _find_ceiling(p: Vector2) -> bool:
	var best := -INF
	for pl in z.get_tree().get_nodes_in_group("platforms"):
		var r: Rect2 = pl.world_rect()
		if p.x > r.position.x + 12.0 and p.x < r.end.x - 12.0 and r.end.y < p.y - 50.0 and r.end.y > best and p.y - r.end.y < 210.0:
			best = r.end.y
			_x_min = r.position.x + 12.0
			_x_max = r.end.x - 12.0
	for rf in z.get_tree().get_nodes_in_group("s6_roof"):
		var ry: float = rf.ceiling_at(p.x)
		if ry > best and ry < p.y - 50.0 and p.y - ry < 340.0:
			best = ry
			var span: Vector2 = rf.span()
			_x_min = span.x
			_x_max = span.y
	if best > -INF:
		ceil_y = best
		wall = false
		return true
	# אין תקרה: נצמד לקיר בגובה 150 ולא זוחל
	ceil_y = p.y - 150.0
	wall = true
	_x_min = p.x - 1.0
	_x_max = p.x + 1.0
	return true


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_t -= delta
	_click -= delta
	var alive_pl: bool = pl != null and not pl.dead
	var d := Vector2.ZERO
	if alive_pl:
		d = pl.global_position - z.global_position
	match state:
		GROUND:
			if alive_pl and _cd <= 0.0 and z.is_on_floor() and z._chasing and absf(d.x) > 110.0 and absf(d.x) < 520.0 and absf(d.y) < 200.0:
				_cd = randf_range(1.0, 2.0)
				if _find_ceiling(z.global_position):
					state = CLIMB
					climbs += 1
					z.collision_mask = 0
					z.velocity = Vector2.ZERO
					Sfx.play("crawl_click", z.global_position, -4.0, 0.2, 2)
			return false
		CLIMB:
			var top: float = ceil_y + 50.0 * z.sc
			z.global_position.y = move_toward(z.global_position.y, top, CLIMB_SPEED * z._speed_mul * delta)
			z._walk_phase += delta * 12.0
			_clicks()
			if z.global_position.y <= top + 0.5:
				_attach()
			return true
		CEILING:
			if not alive_pl:
				return true
			var under: bool = d.y > 0.0 and d.y < 240.0
			if not under or (wall and absf(d.x) > 200.0):
				_away += delta
			else:
				_away = maxf(_away - delta, 0.0)
			if _away > 3.5:   # השחקן לא מתחתיו כבר הרבה זמן: יורד ורודף ברגל
				_start_drop(false)
				return true
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if under and absf(d.x) < 24.0:
				state = TELL
				_t = TELL_TIME
				Sfx.play("crawl_shriek", z.global_position, 1.0)
				return true
			# מחכה: כשהשחקן מסתכל אליו מקרוב - קופא במקום
			var watched: bool = pl._face() == signf(-d.x) and absf(d.x) < 260.0
			var spd: float = 0.0 if watched or wall else CRAWL_SPEED * z._speed_mul
			if absf(d.x) > 320.0 and not wall:
				spd = CRAWL_SPEED * 1.3
			var nx := clampf(move_toward(z.global_position.x, pl.global_position.x, spd * delta), _x_min, _x_max)
			if spd > 0.0 and absf(nx - z.global_position.x) > 0.01:
				z._walk_phase += delta * 9.0
				_clicks()
			elif absf(d.x) > 60.0 and (nx <= _x_min + 0.5 or nx >= _x_max - 0.5):
				_away += delta * 0.7   # קצה התקרה: לא יכול להגיע
			z.global_position.x = nx
			return true
		TELL:   # רעד לפני הצלילה (רמז הוגן) + אבק נופל
			if Engine.get_physics_frames() % 6 == 0:
				Particles.burst(z.get_parent(), Vector2(z.global_position.x, ceil_y + 2.0), "smoke", Vector2.DOWN, 1)
			if _t <= 0.0:
				_start_drop(true)
			return true
		DROP:
			z.velocity.y += z.gravity * delta
			z.velocity.x = move_toward(z.velocity.x, 0.0, 200.0 * delta)
			z.move_and_slide()
			if alive_pl and not _hit and not _shot:
				var me := Rect2(z.global_position + Vector2(-14.0, -40.0 * z.sc), Vector2(28.0, 40.0 * z.sc))
				if me.intersects(pl.body_rect()):
					_hit = true
					z._attack_t = z.bite_delay
					z._bite_anim = 0.3
					pl.hurt(z.damage, Vector2(signf(d.x) if d.x != 0.0 else z._dir, 0.0))
			if z.is_on_floor():
				state = LAND
				_t = 0.9 if _shot else 0.3
				z.velocity.x = 0.0
				Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 4)
				if _shot:
					z._popup("?", Color(0.6, 0.95, 1.0), 16, -60.0)
			return true
		LAND:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			if _t <= 0.0:
				state = HUNT
				_t = 1.8
			return true
		HUNT:   # על הריצפה: מוח רגיל + נשיכה, לזמן קצר
			if _t <= 0.0:
				_flee()
			return false
		FLEE:   # בורח מהשחקן ואז חוזר לקיר / תקרה
			z.velocity.y += z.gravity * delta
			var away: float = -signf(d.x) if d.x != 0.0 else -z._dir
			z._dir = away
			z.velocity.x = move_toward(z.velocity.x, away * 180.0 * z._speed_mul, 900.0 * delta)
			z.move_and_slide()
			z._walk_phase += delta * 14.0
			if is_instance_valid(z) and z.is_on_wall() and z.is_on_floor():
				_t = 0.0
			if _t <= 0.0 and z.is_on_floor():
				state = GROUND
				_cd = 0.0   # מטפס שוב מיד
			return true
	return false


func _clicks() -> void:
	if _click <= 0.0:
		_click = randf_range(0.5, 0.9)
		Sfx.play("crawl_click", z.global_position, -12.0, 0.25, 2)


func _start_drop(attack: bool) -> void:
	state = DROP
	if attack:
		drops += 1
	_hit = not attack   # ירידה בלי התקפה: לא פוגע
	_shot = false
	_detach()
	z.velocity = Vector2(0.0, 60.0 if attack else 0.0)


func _flee() -> void:
	state = FLEE
	_t = 0.7


func on_bite(_pl: Node) -> void:
	if state == HUNT:
		_t = minf(_t, 0.15)


func on_damage(_amount: int, _hit_pos: Vector2, dir: Vector2, _src: Dictionary) -> bool:
	if state == CEILING or state == TELL or state == CLIMB:   # הופל מהתקרה
		_start_drop(false)
		_shot = true
		z.velocity = Vector2(dir.x * 90.0, 0.0)
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.6 if on_ceiling_now() else 1.0


func on_death() -> void:
	_detach()


# ============================================================
#  ציור: גוף "עכביש" אחד, מצויר במנח של ריצפה (ראש ל-+x),
#  ומסובב/הפוך לפי המצב: ריצפה / קיר / תקרה / צלילה.
# ============================================================
func draw() -> bool:
	if z.dead:
		begin_draw()
		_body(Vector2.DOWN)
		end_draw()
		return true
	var xf: Transform2D
	var s: float = z.sc
	match state:
		CEILING, TELL:
			var shake := Vector2(randf_range(-1.2, 1.2), 0.0) if state == TELL else Vector2.ZERO
			xf = Transform2D(0.0, Vector2(z._dir * z.wf * s, -s), 0.0, shake)
		CLIMB:
			xf = Transform2D(-PI / 2.0, Vector2(s, s), 0.0, Vector2(0.0, 0.0))
		DROP:
			if _shot:
				xf = Transform2D(z._time * 9.0, Vector2(z._dir * s, s), 0.0, Vector2(0.0, -16.0 * s)) * Transform2D(0.0, Vector2(0.0, 16.0))
			else:
				xf = Transform2D(PI / 2.0 * z._dir, Vector2(z._dir * s, s), 0.0, Vector2(0.0, -40.0 * s))
		_:
			if z.is_on_floor():
				Art.ground_shadow(z, Vector2.ZERO, 18.0 * z.wf * s)
			xf = Transform2D(0.0, Vector2(z._dir * z.wf * s, s), 0.0, Vector2.ZERO)
	z.draw_set_transform_matrix(xf)
	_body(xf.basis_xform_inv(Vector2.DOWN).normalized())
	end_draw()
	return true


func _body(down: Vector2) -> void:
	var sk := col(z.skin)
	var dark := col(Art.shade(z.skin, 0.35))
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var tense := 2.0 if state == TELL else 0.0
	var hip := Vector2(-11.0, -15.0 - tense)
	var chest := Vector2(8.0, -19.0 - tense)
	var head := Vector2(18.0, -17.0 - tense)
	if state == LAND or (state == HUNT and z._bite_anim > 0.0):
		head += Vector2(3.0, 3.0)
	# גפיים: מפרק גבוה מעל הגוף, כף על הריצפה (רחוקות = כהות)
	var limbs := [
		[chest + Vector2(-2, 0), Vector2(12, 0), Vector2(6, -29), 0.0, dark],
		[hip + Vector2(2, 0), Vector2(-22, 0), Vector2(-7, -27), PI, dark],
		[hip, Vector2(-15, 0), Vector2(-19, -25), 0.0, sk],
		[chest, Vector2(27, 0), Vector2(17, -30), PI, sk],
	]
	for i in limbs.size():
		var l: Array = limbs[i]
		var root: Vector2 = l[0]
		var ph: float = p + float(l[3])
		var foot: Vector2 = l[1] + Vector2(sin(ph) * 5.0, -maxf(0.0, cos(ph)) * 3.0)
		var knee: Vector2 = l[2] + Vector2(sin(ph) * 2.0, 0.0)
		var c: Color = l[4]
		var mid: Vector2 = knee.lerp(foot, 0.45) + Vector2(2.0 if l[1].x > l[0].x else -2.0, 0.0)
		Art.limb(z, PackedVector2Array([root, knee, mid, foot]), 3.6 if i >= 2 else 3.0, c)
		for q in 3:   # אצבעות ארוכות
			z.draw_line(foot, foot + Vector2(-3.0 + float(q) * 3.0, 1.5), Art.OUTLINE, 1.0)
		z.draw_circle(knee, 1.6, col(Color("d8d4c8")))   # מפרק בולט
	# גו שטוח עם חולצה לבנה קרועה
	var mid_back := hip.lerp(chest, 0.5) + Vector2(0, -10)   # גב מקושת
	var torso := PackedVector2Array([hip + Vector2(-5, 3), hip + Vector2(-3, -5), mid_back, chest + Vector2(4, -6), chest + Vector2(5, 3), chest + Vector2(-6, 6), hip + Vector2(6, 6)])
	Art.fill_shaded(z, torso, shirt, 0.15, 0.35)
	for i in 3:   # קרעים בחולצה (רואים עור)
		var tp: Vector2 = hip.lerp(chest, 0.25 + float(i) * 0.25) + Vector2(0, 3)
		Art.fill(z, PackedVector2Array([tp + Vector2(-2, -1), tp + Vector2(2, -2), tp + Vector2(1, 2)]), sk, Art.NONE)
	# נקודות ציאן זוהרות לאורך עמוד השדרה
	var glow_c := Color(0.35, 0.95, 1.0)
	for i in 5:
		var u := float(i) / 4.0
		var sp: Vector2 = (hip + Vector2(-2, -5)).lerp(mid_back, u * 2.0) if u < 0.5 else mid_back.lerp(chest + Vector2(3, -6), u * 2.0 - 1.0)
		var pulse := 0.5 + 0.5 * sin(z._time * 4.0 + float(i) * 1.3)
		z.draw_circle(sp, 1.1, Color(glow_c, 0.5 + 0.5 * pulse))
		if i % 2 == 0:
			Art.glow(z, sp, 3.5, Color(glow_c, 0.35 * pulse))
	# שיער שחור ארוך - תמיד נופל למטה (בעולם)
	var hair_root := head + Vector2(-1, -4)
	Art.oval_shaded(z, head, 7.0, 6.0, sk, 0.2)
	var side := Vector2(-down.y, down.x)
	for i in 6:
		var off := Vector2(-5.0 + float(i) * 2.0, float(i % 2))
		var sway := sin(z._time * 2.0 + float(i) * 0.9) * 2.0
		var hl := 16.0 + float(i % 3) * 5.0
		var tip := hair_root + off + down * hl + side * (sway + (float(i) - 2.5) * 1.6)
		var midp := (hair_root + off).lerp(tip, 0.5) + side * sway * 0.5
		z.draw_polyline(PackedVector2Array([hair_root + off, midp, tip]), Color(0.05, 0.04, 0.06, 0.9), 1.3, true)
	# לסת שמתפצלת לצדדים
	var jaw := 2.0 + (3.5 if state == TELL or z._bite_anim > 0.0 else 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(3, 1), head + Vector2(8, 0), head + Vector2(7, 2.0 + jaw), head + Vector2(3, 3.0 + jaw * 0.6)]), Color("200810"), Art.OUTLINE, 0.8)
	# 4 עיניים ציאן
	for e in [Vector2(2.0, -2.0), Vector2(4.5, -2.4), Vector2(3.0, -0.2), Vector2(5.5, -0.6)]:
		z.draw_circle(head + e, 0.8, glow_c)
	Art.glow(z, head + Vector2(4.0, -1.5), 5.0, Color(glow_c, 0.45 if state != TELL else 0.9))
