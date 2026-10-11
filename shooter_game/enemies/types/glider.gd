extends "res://enemies/zombie_type.gd"
# ============================================================
#  GLIDER (שלב 21, "CLIFFSIDE") - זומבי טייס בחליפת כנפיים (wingsuit) קרועה, כובע עור ומשקפי טיסה.
#  מחזור:
#    WALK    - הולך כמו זומבי רגיל (המוח). כשמוכן (CD) ויש קומה שנייה קרובה -> CLIMB.
#    CLIMB   - קפיצה בליסטית אל הקומה השנייה (מחושבת כך שינחת עליה).
#    PERCH   - כורע על הקצה ומחכה. השחקן מתחתיו בטווח (LAUNCH) -> קופץ ודואה.
#    GLIDE   - דאייה איטית אליך: נופל לאט (GLIDE_FALL), מכוון לאן שאתה *הולך* (LEAD).
#              כשהוא קרוב (HOP_DIST) -> HOP: קפיצה קטנה ונחיתה עליך (DAMAGE).
#    RECOVER - נחת: מסוחרר רגע (וקל לפגוע בו), ואז חוזר ללכת ולטפס שוב.
#  נגד: יורים בו באוויר -> הכנפיים נקרעות והוא נופל (כל פגיעה בזמן דאייה). נזק x1.5 בזמן דאייה.
#  צליל: "gl_whoosh" (רוח בכנפיים), "gl_screech" (צווחה כשהוא קופץ עליך).
#  לשנות: GLIDE_SPEED, GLIDE_FALL, LAUNCH, HOP_DIST, LEAD, CD, CLIMB_RANGE.
# ============================================================

const SOUNDS := {
	"gl_whoosh": {"drive": 1.2, "layers": [["N", 0, 0, 0.0, 0.7, 0.2, 2.5, 0.45, 0.25, 0, 0.05]]},
	"gl_screech": {"drive": 2.6, "layers": [["V", 420, 900, 0.0, 0.35, 0.01, 5.0, 0.8, 1.0, 0.06, 0, [900, 2400, 50]], ["N", 0, 0, 0.0, 0.25, 0.0, 9.0, 0.4, 0.6, 0, 0.25]]},
}

const GLIDE_SPEED := 270.0
const GLIDE_FALL := 70.0          # מהירות נפילה מקסימלית בדאייה
const LAUNCH := Vector2(110.0, 560.0)   # טווח אופקי לשחקן שבו הוא קופץ מהקצה
const HOP_DIST := 85.0
const LEAD := 0.45                # כמה שניות קדימה הוא מנחש איפה תהיה
const DAMAGE := 1
const CD := Vector2(2.5, 4.0)
const CLIMB_RANGE := 460.0        # כמה רחוק הוא מחפש קומה לטפס אליה
const RECOVER_T := 0.8

enum { WALK, CLIMB, PERCH, GLIDE, HOP, RECOVER }
var state := WALK
var glides := 0          # לבדיקות
var hits := 0
var climbs := 0
var _st := 0.0
var _cd := 1.0
var _hit_done := false
var _wind_t := 0.0
var _started := false


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	return {"name": "GLIDER", "hp": 28, "walk": 48.0, "chase": 108.0, "damage": 1, "bite_delay": 0.8, "scale": 0.98, "width": 0.9,
		"duck": 0.1, "cover": 0.1, "skin": Color("8fa088"), "shirt": Color("5a4630"), "pants": Color("3e3426"), "shoe": Color("2a1e14"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func can_bite() -> bool:
	return state == WALK


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == GLIDE or state == HOP else 1.0


func _ground_y() -> float:
	var p := player()
	return float(p.get_meta("ground_y", 630.0)) if p != null else 630.0


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	_cd -= delta
	_st -= delta
	var has_pl: bool = pl != null and not pl.dead
	if not _started:   # נולד על קומה שנייה -> מחכה שם
		_started = true
		if z.global_position.y < _ground_y() - 40.0:
			state = PERCH
	match state:
		WALK:
			if _cd <= 0.0 and has_pl and z.is_on_floor():
				var t := _platform_target(pl)
				if t != Vector2.INF:
					_climb_to(t)
					return true
			return false
		CLIMB:
			if not z.is_on_floor() or _st > 0.0:   # (רגע אחרי הקפיצה הוא עוד "על הקרקע")
				z.velocity.y += z.gravity * delta
				z.move_and_slide()
				return true
			if z.global_position.y < _ground_y() - 40.0:
				state = PERCH
			else:
				state = WALK
				_cd = 1.0
			return _stay(delta)
		PERCH:
			z._duck_t = 0.3
			if has_pl:
				var d: Vector2 = pl.global_position - z.global_position
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				var sees: bool = z.brain == null or z.brain.sees or absf(d.x) < 400.0
				if sees and absf(d.x) > LAUNCH.x and absf(d.x) < LAUNCH.y and d.y > 40.0:
					_launch()
					return true
				if absf(d.x) <= LAUNCH.x and d.y > 40.0:   # השחקן ממש מתחת: נופל עליו
					_launch()
					return true
			if not z.is_on_floor():   # הקומה נגמרה מתחתיו
				state = WALK
			return _stay(delta)
		GLIDE:
			_wind_t -= delta
			if _wind_t <= 0.0:
				_wind_t = 0.6
				if Art.on_screen(z, z.global_position):
					Sfx.play("gl_whoosh", z.global_position, -8.0, 0.1, 2)
			var tx: float = z.global_position.x + z._dir * 200.0
			if has_pl:
				var pv: Vector2 = pl.velocity if pl.get("velocity") != null else Vector2.ZERO
				tx = pl.global_position.x + clampf(pv.x, -400.0, 400.0) * LEAD
				var dx: float = tx - z.global_position.x
				if absf(dx) > 6.0:
					z._dir = signf(dx)
				var dist := absf(pl.global_position.x - z.global_position.x)
				if dist < HOP_DIST and pl.global_position.y - z.global_position.y < 150.0:
					_hop(pl)
					return true
			z.velocity.x = move_toward(z.velocity.x, z._dir * GLIDE_SPEED * (1.15 if _boss() else 1.0), 420.0 * delta)
			# יורד בדיוק כך שיגיע אליך בגובה החזה (חכם: מכוון את המסלול, לא סתם נופל)
			var want_vy := GLIDE_FALL
			if has_pl:
				var dist2: float = maxf(absf(pl.global_position.x - z.global_position.x) - HOP_DIST * 0.6, 20.0)
				var tt: float = dist2 / GLIDE_SPEED
				var drop: float = (pl.global_position.y - 26.0) - z.global_position.y
				want_vy = clampf(drop / maxf(tt, 0.15), 30.0, 260.0)
			z.velocity.y = move_toward(z.velocity.y, want_vy, z.gravity * 0.5 * delta)
			z.move_and_slide()
			_check_hit(pl)
			if z.is_on_floor():
				_land()
			return true
		HOP:
			z.velocity.y += z.gravity * delta
			z.move_and_slide()
			_check_hit(pl)
			if z.is_on_floor() and z.velocity.y >= 0.0:
				_land()
			return true
		RECOVER:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
				return false
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# הקומה השנייה הכי קרובה שהוא יכול לקפוץ אליה (נקודת נחיתה), או INF
func _platform_target(pl: Node) -> Vector2:
	var best := Vector2.INF
	var bd := CLIMB_RANGE
	for p in z.get_tree().get_nodes_in_group("platforms"):
		var r: Rect2 = p.world_rect()
		var h: float = z.global_position.y - r.position.y
		if h < 70.0 or h > 300.0 or r.size.x < 80.0:
			continue
		# נקודה על הקומה, בצד שקרוב לשחקן (משם הוא יקפוץ עליו)
		var lx := clampf(pl.global_position.x, r.position.x + 30.0, r.end.x - 30.0)
		var d := absf(lx - z.global_position.x)
		if d < bd:
			bd = d
			best = Vector2(lx, r.position.y)
	return best


# קפיצה בליסטית שנוחתת על הקומה: שיא 40 פיקסלים מעליה
func _climb_to(t: Vector2) -> void:
	var g: float = z.gravity
	var h1: float = z.global_position.y - (t.y - 40.0)
	var vy := -sqrt(2.0 * g * h1)
	var t_up := -vy / g
	var t_down := sqrt(2.0 * 40.0 / g)
	z.velocity = Vector2((t.x - z.global_position.x) / (t_up + t_down), vy)
	z._dir = signf(z.velocity.x) if z.velocity.x != 0.0 else z._dir
	z.collision_mask |= 16
	state = CLIMB
	_st = 0.2
	climbs += 1
	Sfx.play("jump", z.global_position, -2.0)


func _launch() -> void:
	state = GLIDE
	glides += 1
	_hit_done = false
	z.velocity = Vector2(z._dir * 200.0, -170.0)
	z.collision_mask &= ~16   # עובר דרך קומות בדרך למטה
	Sfx.play("gl_whoosh", z.global_position, -2.0, 0.1, 2)


# קפיצה קטנה שנוחתת בדיוק עליך (לפי איפה שאתה הולך להיות)
func _hop(pl: Node) -> void:
	state = HOP
	var vy := -170.0
	var g: float = z.gravity
	var drop: float = (pl.global_position.y - 20.0) - z.global_position.y   # כמה למטה לנחות
	var t := (-vy + sqrt(maxf(vy * vy + 2.0 * g * drop, 0.0))) / g
	var pv: Vector2 = pl.velocity if pl.get("velocity") != null else Vector2.ZERO
	var tx: float = pl.global_position.x + clampf(pv.x, -400.0, 400.0) * t
	z.velocity = Vector2(clampf((tx - z.global_position.x) / maxf(t, 0.1), -320.0, 320.0), vy)
	Sfx.play("gl_screech", z.global_position, 2.0, 0.1, 2)


func _land() -> void:
	z.collision_mask |= 16
	state = RECOVER
	_st = RECOVER_T
	z.velocity.x *= 0.3
	if Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 4)


func _check_hit(pl: Node) -> void:
	if _hit_done or pl == null or pl.dead:
		return
	var r: Rect2 = pl.body_rect().grow(10.0)
	var b := Rect2(z.global_position + Vector2(-10.0 * z.sc, -40.0 * z.sc), Vector2(20.0 * z.sc, 40.0 * z.sc))
	if r.intersects(b):
		_hit_done = true
		hits += 1
		pl.hurt(DAMAGE + (1 if _boss() else 0), Vector2(z._dir, -0.5))
		z.velocity = Vector2(-z._dir * 160.0, -180.0)   # נהדף ממך


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == GLIDE:   # הכנפיים נקרעות - נופל
		state = HOP
		_hit_done = true
		z.velocity = Vector2(z.velocity.x * 0.4, 60.0)
		if Art.on_screen(z, z.global_position):
			z._popup("WINGS TORN", Color("ffd34a"), 12, -70.0)
	return true


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	if not z.dead and (state == GLIDE or state == HOP):
		return _draw_glide()
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var memb := col(Color("6a2e22"))
	var p: float = z._walk_phase
	var crouch := 5.0 if state == PERCH or state == RECOVER else 0.0
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(-1.0, -22.0 + crouch)
	var sh := Vector2(2.0, -37.0 + crouch * 1.4)
	var head := sh + Vector2(4.0, -8.0)
	if state == PERCH:
		f = [Vector2(6, 0), Vector2(-5, 0)]
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	# כנף מקופלת מאחור (בד מהיד לירך, קרוע)
	var bh := sh + Vector2(-6.0 - sin(p) * 2.0, 14.0)
	z.draw_colored_polygon(PackedVector2Array([sh + Vector2(-3, 1), bh, hip + Vector2(-6, 4), hip + Vector2(-9, -2), sh + Vector2(-9, 6)]), Color(memb, 0.95))
	z._arm(sh + Vector2(-3, 1), bh, Art.shade(sk, 0.25), Art.shade(suit, 0.3))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), suit, 0.12, 0.4)
	z.draw_line(sh + Vector2(0, 2), hip + Vector2(0, 0), col(Color("2a2016")), 1.2)   # רוכסן
	_head(head, sk)
	var fh := sh + Vector2(8.0 + sin(p) * 2.0, 12.0)
	if state == PERCH:   # ידיים פרושות קצת, מוכן לקפוץ
		fh = sh + Vector2(13.0, 2.0)
		z.draw_colored_polygon(PackedVector2Array([sh + Vector2(3, 1), fh, hip + Vector2(4, 0)]), Color(memb, 0.9))
	z._arm(sh + Vector2(3, 1), fh, sk, suit)
	end_draw()
	return true


func _head(head: Vector2, sk: Color) -> void:
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	# כובע טייס מעור + משקפי טיסה
	Art.fill(z, PackedVector2Array([head + Vector2(-6, 1), head + Vector2(-5, -5), head + Vector2(2, -7.5), head + Vector2(6, -3), head + Vector2(4, -1), head + Vector2(-2, -2), head + Vector2(-3, 4)]), col(Color("6a4a2a")), Art.OUTLINE, 1.0)
	z.draw_line(head + Vector2(-5, 3), head + Vector2(-6, 8), col(Color("4a3220")), 1.4)   # רצועה
	for gx in [1.5, 5.0]:
		z.draw_circle(head + Vector2(gx, -2.2), 1.8, col(Color("2a2a2e")))
		z.draw_circle(head + Vector2(gx, -2.2), 1.1, Color(0.85, 0.75, 0.3, 0.9) if not z.dead else Color(0.3, 0.3, 0.3))
	Art.fill(z, PackedVector2Array([head + Vector2(1, 2.5), head + Vector2(5.5, 2.0), head + Vector2(5, 4.6), head + Vector2(1.5, 4.6)]), col(Color("2a0a0a")), Art.OUTLINE, 0.7)


# דאייה: גוף אופקי, ידיים קדימה, כנפיים פרושות בין היד לרגל, קצה קרוע שמתנפנף
func _draw_glide() -> bool:
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	var tilt := -0.12 if state == GLIDE else 0.35
	z.draw_set_transform_matrix(Transform2D(tilt * z._dir, Vector2(0, -26.0 * z.sc)) * Transform2D(0.0, s, 0.0, Vector2.ZERO))
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var memb := col(Color("6a2e22"))
	var t: float = z._time
	var flap := sin(t * 18.0) * 2.0
	var head := Vector2(15, -3)
	var nk := Vector2(9, -1)
	var hip := Vector2(-9, 1)
	var hand := Vector2(22, -8 + flap * 0.5) if state == GLIDE else Vector2(18, 6)
	var foot := Vector2(-24, 3)
	# כנף אחורית (כהה)
	z.draw_colored_polygon(PackedVector2Array([hand + Vector2(-3, -2), nk, hip, foot + Vector2(2, -3), Vector2(-14, -10 + flap), Vector2(0, -15 - flap), Vector2(12, -14)]), Art.shade(memb, 0.35))
	Art.limb(z, PackedVector2Array([hip, hip + Vector2(-8, 1), foot]), 3.0, col(z.pants))
	Art.limb(z, PackedVector2Array([nk, nk + Vector2(6, -3), hand]), 2.8, Art.shade(sk, 0.2))
	# גוף
	Art.fill_shaded(z, PackedVector2Array([nk + Vector2(1, -4), nk + Vector2(1, 4), hip + Vector2(0, 4), hip + Vector2(0, -4)]), suit, 0.12, 0.4)
	_head(head, sk)
	# כנף קדמית עם קצה מסורק וקרוע
	var wing := PackedVector2Array([hand, nk + Vector2(0, 3), hip + Vector2(0, 4), foot, Vector2(-16, 12 + flap), Vector2(-9, 9), Vector2(-4, 14 - flap), Vector2(2, 9), Vector2(8, 13 + flap), Vector2(13, 6)])
	Art.fill(z, wing, Color(memb, 0.92), Art.OUTLINE, 1.0)
	z.draw_line(hand, hip + Vector2(0, 4), Color(0, 0, 0, 0.25), 1.0)   # קפל
	Art.limb(z, PackedVector2Array([hip + Vector2(0, 3), hip + Vector2(-8, 4), foot + Vector2(1, 2)]), 3.2, col(Art.shade(z.pants, -0.1)))
	Art.limb(z, PackedVector2Array([nk + Vector2(1, 3), nk + Vector2(7, 2), hand + Vector2(0, 2)]), 3.0, sk)
	end_draw()
	return true
