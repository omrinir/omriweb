extends "res://enemies/zombie_type.gd"
# ============================================================
#  HARVESTER (שלב 46, "WINE VALLEY") - בוצר ענבים זומבי: כובע קש רחב וקרוע, פונצ'ו, סל ענבים על הגב,
#    ומגל בציר על שרשרת ארוכה.
#  שומר מרחק (KEEP), מסובב את השרשרת מעל הראש (WIND_T - אזהרה, זמזום) וזורק את המגל (Sickle).
#    המגל פגע בך -> נתפס (HOOKED): השרשרת מושכת אותך אליו (PULL_V) -> חיתוך (SLASH) כשאתה מגיע.
#    להשתחרר: לירות בשרשרת / במגל (גוף קטן על שכבה 4, כמו החבל של שלב 45) -> "CHAIN CUT": המגל נופל, ובלי מגל
#    הוא רק מתקרב ונושך עד שהוא מרים מגל חדש (REARM_T).
#  "THEY LEARN YOUR TIMING": המגל עבר מתחתיך כשקפצת -> הזריקה הבאה מכוונת גבוה יותר ("HE AIMS HIGH").
#    ברחת אחורה / הצידה מהזריקה -> הוא מקדים אותך יותר (lead - לאן שאתה רץ, "HE LEADS YOU").
#  צלילים: "hv_spin" (שרשרת מסתובבת), "hv_throw", "hv_hook" (נתפס), "hv_chain" (שרשרת נקרעת).
#  לשנות: KEEP, THROW_R, WIND_T, SICKLE_V, PULL_V, PULL_MAX, REARM_T, CD.
# ============================================================

const SOUNDS := {
	"hv_spin": [["N", 0, 0, 0.0, 0.12, 0.0, 25.0, 0.18, 0.5, 0, 0.7], ["S", 900, 1100, 0.0, 0.1, 0.0, 30.0, 0.08, 1.0, 0.05]],
	"hv_throw": [["N", 0, 0, 0.0, 0.2, 0.0, 12.0, 0.45, 0.6, 0, 0.6], ["S", 600, 300, 0.0, 0.15, 0.0, 16.0, 0.15, 1.0, 0]],
	"hv_hook": [["C", 0, 0, 0.0, 0.05, 0.0, 50.0, 0.5, 1.0, 0], ["S", 1700, 1500, 0.0, 0.12, 0.0, 30.0, 0.25, 1.0, 0.03], ["N", 0, 0, 0.0, 0.12, 0.0, 20.0, 0.3, 0.4, 0, 0.6]],
	"hv_chain": [["S", 2200, 1900, 0.0, 0.15, 0.0, 25.0, 0.3, 1.0, 0.04], ["N", 0, 0, 0.0, 0.18, 0.0, 18.0, 0.35, 0.6, 0, 0.6]],
}

const KEEP := Vector2(150.0, 330.0)
const THROW_R := 380.0
const WIND_T := 0.6
const SICKLE_V := 560.0
const PULL_V := 330.0
const PULL_MAX := 1.6         # כמה זמן לכל היותר הוא מושך
const SLASH_R := 46.0
const REARM_T := 7.0
const CD := Vector2(2.0, 3.0)

enum { IDLE, WIND, THROWN, PULL, SLASH, UNARMED }
var state := IDLE
var throws := 0              # לבדיקות
var hooks := 0
var slashes := 0
var cuts := 0
var aim_y := -28.0           # לאיזה גובה (מעל הרגליים שלך) הוא זורק - לומד
var lead := 0.15             # כמה הוא מקדים את התנועה שלך - לומד
var dodges := {"jump": 0, "run": 0}
var sickle: Node = null
var _st := 0.0
var _cd := 1.4
var _spin := 0.0


func stats() -> Dictionary:
	return {"name": "HARVESTER", "hp": 34, "walk": 42.0, "chase": 88.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.05,
		"duck": 0.3, "cover": 0.3, "skin": Color("94a284"), "shirt": Color("8a3a2a"), "pants": Color("4a4030"), "shoe": Color("3a2a1a"), "points": 480}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.25, "keep_range": KEEP.x}


func can_bite() -> bool:
	return state == UNARMED


func hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 8.0, -44.0) * z.sc


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_spin += delta * (16.0 if state == WIND else 0.0)
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		IDLE:
			if not has_pl or z.goal_x < INF:
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if absf(d.y) > 110.0 or absf(d.x) > 650.0:
				return false
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _cd <= 0.0 and absf(d.x) < THROW_R and absf(d.x) > 60.0 and _los(pl):
				state = WIND
				_st = WIND_T
				Sfx.play("hv_spin", z.global_position, -4.0, 0.1, 2)
				return _move(0.0, delta)
			if absf(d.x) < KEEP.x:   # קרוב מדי - נסוג
				return _move(-z._dir * float(z.walk_speed) * 1.4, delta)
			if absf(d.x) < KEEP.y:
				return _move(0.0, delta)
			return false
		WIND:
			if has_pl:
				z._dir = signf(pl.global_position.x - z.global_position.x) if absf(pl.global_position.x - z.global_position.x) > 4.0 else z._dir
			if Engine.get_physics_frames() % 10 == 0:
				Sfx.play("hv_spin", z.global_position, -8.0, 0.15, 2)
			if _st <= 0.0:
				if has_pl:
					_throw(pl)
				else:
					_reset(1.0)
			return _move(0.0, delta)
		THROWN:
			if sickle == null or not is_instance_valid(sickle):
				_reset(randf_range(CD.x, CD.y))
			return _move(0.0, delta)
		PULL:
			if not has_pl or sickle == null or not is_instance_valid(sickle) or _st <= 0.0:
				_free_sickle()
				_reset(randf_range(CD.x, CD.y))
				return false
			var d2: Vector2 = pl.global_position - z.global_position
			z._dir = signf(d2.x) if absf(d2.x) > 2.0 else z._dir
			if absf(d2.x) < SLASH_R:
				state = SLASH
				_st = 0.25
				_free_sickle()
				pl.velocity.x = 0.0
				return _move(0.0, delta)
			pl.velocity.x = -signf(d2.x) * PULL_V
			pl._push_t = maxf(float(pl._push_t), 0.12)
			if pl.is_on_floor():
				pl.velocity.y = minf(float(pl.velocity.y), -60.0)   # מקפץ קצת על הרצפה בזמן הגרירה
			return _move(0.0, delta)
		SLASH:
			if _st <= 0.0:
				slashes += 1
				Sfx.play("hv_throw", z.global_position, -2.0, 0.1, 2)
				if has_pl:
					var d3: Vector2 = pl.global_position - z.global_position
					if absf(d3.x) < SLASH_R + 30.0 and absf(d3.y) < 60.0:
						pl.hurt(z.damage, Vector2(z._dir * 1.6, -0.6))
				_reset(randf_range(CD.x, CD.y))
			return _move(0.0, delta)
		UNARMED:
			if _st <= 0.0:
				state = IDLE
				_cd = 0.6
				z._popup("NEW SICKLE", Color("e0c080"), 11, -70.0)
			return false   # המוח מוביל אותו - נושך
	return false


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall() and vx != 0.0:
		z.velocity.y = -380.0
	z.move_and_slide()
	return true


func _reset(cd: float) -> void:
	state = IDLE
	_cd = cd


func _throw(pl: Node) -> void:
	throws += 1
	state = THROWN
	var s := Sickle.new()
	s.owner_t = self
	var tgt: Vector2 = pl.global_position + Vector2(clampf(float(pl.velocity.x) * lead, -160.0, 160.0), aim_y)
	s.dir = (tgt - hand()).normalized()
	s.max_d = minf(hand().distance_to(tgt) + 90.0, THROW_R + 60.0)
	z.get_parent().add_child(s)
	s.global_position = hand()
	sickle = s
	Sfx.play("hv_throw", hand(), -1.0, 0.1, 3)


func hooked(pl: Node) -> void:   # נקרא מהמגל
	hooks += 1
	state = PULL
	_st = PULL_MAX
	Sfx.play("hv_hook", pl.global_position, 2.0, 0.1, 2)
	pl._say("HOOKED! SHOOT THE CHAIN", Color("ff6050"))


func missed(pl: Node, how: String) -> void:   # המגל פספס: איך התחמקת
	if pl == null or z.dead:
		return
	dodges[how] = int(dodges[how]) + 1
	if how == "jump":
		aim_y = maxf(aim_y - 14.0, -70.0)
		z._popup("HE AIMS HIGH", Color("ffd080"), 11, -75.0)
	else:
		lead = minf(lead + 0.18, 0.75)
		z._popup("HE LEADS YOU", Color("ffd080"), 11, -75.0)


func chain_cut() -> void:   # ירו בשרשרת
	cuts += 1
	Sfx.play("hv_chain", sickle.global_position if sickle != null and is_instance_valid(sickle) else z.global_position, 0.0, 0.1, 2)
	z._popup("CHAIN CUT", Color("e0e0e0"), 13, -75.0)
	_free_sickle()
	state = UNARMED
	_st = REARM_T


func sickle_back() -> void:
	sickle = null
	if state == THROWN:
		_reset(randf_range(CD.x, CD.y))


func _free_sickle() -> void:
	if sickle != null and is_instance_valid(sickle):
		sickle.drop()
	sickle = null


func on_death() -> void:
	_free_sickle()


# ============================================================
#  המגל על השרשרת: עף בקו ישר עד max_d, נתפס בשחקן או חוזר. גוף קטן לאורך השרשרת (שכבה 4) - ירייה בו קורעת אותה.
# ============================================================
class Sickle extends Node2D:
	var owner_t = null
	var dir := Vector2.RIGHT
	var max_d := 360.0
	var back := false
	var hooked_pl: Node = null
	var _d := 0.0
	var _t := 0.0
	var _passed := false
	var _drop := false
	var _vy := 0.0
	var _body: StaticBody2D = null
	var _shape: CollisionShape2D = null

	class Link extends StaticBody2D:
		var s = null
		func hit_by_bullet(_p: Vector2, _n: Vector2, _d: Vector2) -> void:
			if s != null and not s._drop and s.owner_t != null and is_instance_valid(s.owner_t.z) and not s.owner_t.z.dead:
				s.owner_t.chain_cut()

	func _ready() -> void:
		z_index = 9
		var b := Link.new()
		b.s = self
		b.collision_layer = 4
		b.collision_mask = 0
		_shape = CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = Vector2(10, 10)
		_shape.shape = sh
		b.add_child(_shape)
		add_child(b)
		_body = b

	func _owner_ok() -> bool:
		return owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead

	func drop() -> void:
		if _drop:
			return
		_drop = true
		hooked_pl = null
		if is_instance_valid(_body):
			_body.queue_free()

	func _physics_process(delta: float) -> void:
		_t += delta
		if _drop:   # נופל לרצפה ונעלם
			_vy += 1400.0 * delta
			var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, _vy * delta + 2.0), 1))
			if hit.is_empty():
				global_position.y += _vy * delta
			else:
				_vy = 0.0
			if _t > 6.0:
				queue_free()
			elif Engine.get_physics_frames() % 4 == 0:
				queue_redraw()
			return
		if not _owner_ok():
			drop()
			return
		var pl := get_tree().get_first_node_in_group("player")
		var hand: Vector2 = owner_t.hand()
		if hooked_pl != null:   # תפוס: נשאר על השחקן
			if owner_t.state != owner_t.PULL:
				queue_free()
				return
			global_position = hooked_pl.global_position + Vector2(0, -30)
		elif not back:
			var step := dir * 560.0 * delta   # = SICKLE_V
			_d += step.length()
			var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1))
			global_position += step
			if pl != null and not pl.dead and pl.body_rect().grow(4.0).has_point(global_position):
				hooked_pl = pl
				owner_t.hooked(pl)
			elif _d >= max_d or not hit.is_empty():
				back = true
			if hooked_pl == null and pl != null and not pl.dead and not _passed and absf(global_position.x - pl.global_position.x) < 12.0:
				_passed = true
				if not pl.is_on_floor():
					owner_t.missed(pl, "jump")
			if back and not _passed and pl != null and not pl.dead:   # לא הגיע אליך - ברחת
				_passed = true
				owner_t.missed(pl, "run")
		else:
			var to: Vector2 = hand - global_position
			if to.length() < 16.0:
				owner_t.sickle_back()
				queue_free()
				return
			global_position += to.normalized() * 560.0 * 1.15 * delta
		# גוף הפגיעה של השרשרת: באמצע בין היד למגל
		var mid := (hand + global_position) * 0.5
		var ln := hand.distance_to(global_position)
		_body.global_position = mid
		_body.rotation = (global_position - hand).angle()
		(_shape.shape as RectangleShape2D).size = Vector2(maxf(ln, 10.0), 8.0)
		if _t > 4.0 and hooked_pl == null:
			owner_t.sickle_back()
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var hand_l := Vector2.ZERO
		if not _drop and _owner_ok():
			hand_l = to_local(owner_t.hand())
			var n := 12
			var sag := minf(hand_l.length() * 0.12, 26.0) * (0.3 if hooked_pl != null else 1.0)
			var prev := hand_l
			for i in range(1, n + 1):   # שרשרת: חוליות
				var u := float(i) / float(n)
				var pt := hand_l.lerp(Vector2.ZERO, u) + Vector2(0, sin(u * PI) * sag)
				draw_line(prev, pt, Color("2a2a2e"), 2.6)
				draw_line(prev, pt, Color("8a8a90"), 1.2)
				prev = pt
		var a := (_t * 22.0) if (not back and hooked_pl == null and not _drop) else 0.6
		if _drop:
			a = 0.2
		var hd := Vector2.from_angle(a)
		var hn := hd.orthogonal()
		draw_line(-hd * 6.0, hd * 2.0, Color("5a3a22"), 3.0)   # ידית
		var pts := PackedVector2Array()   # להב מעוקל (חצי סהר)
		for i in 9:
			var u := float(i) / 8.0
			var ang := a - 0.2 + u * 2.6
			pts.append(hd * 2.0 + Vector2.from_angle(ang) * 11.0 - hd * 9.0 + hn * 0.0)
		for i in range(8, -1, -1):
			var u := float(i) / 8.0
			var ang := a - 0.2 + u * 2.6
			pts.append(hd * 2.0 + Vector2.from_angle(ang) * (8.0 + u * 2.5) - hd * 9.0)
		draw_colored_polygon(pts, Color("b8bec4"))
		draw_polyline(pts, Color("1a1a1e"), 1.0)
		if hooked_pl != null:
			draw_circle(Vector2.ZERO, 3.0, Color(0.6, 0.05, 0.05, 0.8))


# ============================================================
#  ציור: כובע קש רחב קרוע, פונצ'ו אדום עם פסים, סל ענבים על הגב, שרשרת + מגל ביד (או מסתובבים מעל הראש)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var poncho := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -21)
	var sh := Vector2(0.5, -37)
	var head := sh + Vector2(3.0, -8.0)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# סל על הגב עם ענבים
	var bk := sh + Vector2(-12, 2)
	Art.fill(z, PackedVector2Array([bk + Vector2(-5, -6), bk + Vector2(6, -6), bk + Vector2(5, 16), bk + Vector2(-4, 16)]), col(Color("9a7a4a")), Art.OUTLINE, 1.0)
	for q in 4:
		z.draw_line(bk + Vector2(-5, -2.0 + float(q) * 5.0), bk + Vector2(6, -2.0 + float(q) * 5.0), col(Color("6a502a")), 0.9)
	for q in 6:
		z.draw_circle(bk + Vector2(-3.0 + float(q % 3) * 3.0, -7.0 - float(q / 3) * 2.5), 2.0, col(Color("4a1a4a") if q % 2 == 0 else Color("6a2a6a")))
	var hb := sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(poncho, 0.3))
	# פונצ'ו
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -2), sh + Vector2(8, -2), hip + Vector2(11, -1), hip + Vector2(-11, -1)]), poncho, 0.15, 0.35)
	for q in 2:
		z.draw_line(sh + Vector2(-8.0 - float(q) * 1.5, 6.0 + float(q) * 6.0), sh + Vector2(9.0 + float(q) * 1.5, 6.0 + float(q) * 6.0), col(Color("e0b040")), 1.4)
	z.draw_line(sh + Vector2(-8, 2), sh + Vector2(7, 3), col(Color("2a1a14")), 1.0)
	# ראש + כובע קש
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.2, -0.6))
	if not z.dead:
		z.draw_circle(head + Vector2(2.5, -0.5), 1.0, Color(1.0, 0.75, 0.3))
	z.draw_line(head + Vector2(1, 3.5), head + Vector2(5, 3), col(Color("3a1a1a")), 1.0)
	z.draw_colored_polygon(Art.ellipse(head + Vector2(0, -4), 12.0, 2.4, 0.08, 14), col(Color("d8b870")))   # שוליים
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-5, -4.5), head + Vector2(-4, -10), head + Vector2(4, -10), head + Vector2(5, -4.5)]), col(Color("c8a860")))
	z.draw_line(head + Vector2(-5, -5.5), head + Vector2(5, -5.5), col(Color("8a2a20")), 1.4)
	z.draw_line(head + Vector2(9, -3), head + Vector2(12, -1), col(Color("2a2010")), 1.0)   # קרע בשוליים
	# יד קדמית: שרשרת + מגל
	var hf: Vector2
	if state == WIND:
		hf = sh + Vector2(4, -12)
		var c := hf + Vector2(0, -6)
		var a := _spin
		var tip := c + Vector2(cos(a) * 18.0, sin(a) * 6.0)   # המגל מסתובב מעל הראש
		z.draw_line(hf, tip, col(Color("6a6a70")), 1.3)
		_draw_sickle(tip, a)
		z.draw_arc(c, 18.0, 0.0, TAU, 16, Color(1, 1, 1, 0.15), 1.0)
	elif state == THROWN or state == PULL:
		hf = sh + Vector2(13, 2)
	else:
		hf = sh + Vector2(9.0 + sin(p) * 2.0, 14.0)
		if state != UNARMED:
			z.draw_line(hf, hf + Vector2(1, 10), col(Color("6a6a70")), 1.2)
			_draw_sickle(hf + Vector2(1, 12), 0.6)
	z._arm(sh + Vector2(3, 1), hf, sk, poncho)
	end_draw()
	return true


func _draw_sickle(c: Vector2, a: float) -> void:
	var hd := Vector2.from_angle(a)
	z.draw_line(c - hd * 4.0, c + hd * 1.0, col(Color("5a3a22")), 2.0)
	z.draw_arc(c + hd * 1.0 + hd.orthogonal() * 4.0, 5.0, a - 1.6, a + 1.4, 8, col(Color("c0c6cc")), 1.6)


# קו ראייה פשוט (בלי קירות באמצע) - המוח לא רץ כשהסוג שולט בתנועה בעצמו
func _los(pl: Node) -> bool:
	var a: Vector2 = z.global_position + Vector2(0, -52.0 * z.sc)
	var b: Vector2 = pl.global_position + Vector2(0, -38.0)
	return z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(a, b, 1)).is_empty()
