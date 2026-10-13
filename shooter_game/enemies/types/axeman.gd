extends "res://enemies/zombie_type.gd"
# ============================================================
#  AXEMAN (שלב 35, "SKULL GLACIER") - מדריך הרים זומבי: קסדה, חבל מגולגל על הכתף, שני גרזני קרח.
#  "THEY LEARNED TO AIM": שומר מרחק (KEEP) וזורק גרזן קרח מסתובב (Axe) שעף אליך וחוזר אליו כמו בומרנג -
#    פוגע גם בדרך הלוך וגם בדרך חזור. יש לו שני גרזנים: כששניהם באוויר - הוא פגיע ובורח.
#    לומד איך אתה מתחמק: קפצת מעל הגרזן -> הבא עף גבוה יותר. התכופפת -> הבא עף נמוך.
#  לשנות: KEEP, THROW_CD, AXE_V, AXE_R.
# ============================================================

const SOUNDS := {
	"ax_throw": [["N", 0, 0, 0.0, 0.18, 0.0, 12.0, 0.4, 0.5, 0, 0.6], ["S", 500, 260, 0.0, 0.15, 0.0, 18.0, 0.2, 1.0, 0]],
	"ax_spin": [["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.15, 0.4, 0, 0.7]],
	"ax_catch": [["C", 0, 0, 0.0, 0.06, 0.0, 50.0, 0.5, 1.0, 0], ["S", 1500, 1400, 0.0, 0.08, 0.0, 40.0, 0.2, 1.0, 0]],
}

const KEEP := Vector2(240.0, 430.0)
const THROW_CD := 2.4
const AXE_V := 430.0
const AXE_R := 520.0

var axes := 2
var throws := 0              # לבדיקות
var axe_hits := 0
var aim_y := -26.0           # לאיזה גובה (מעל הרגליים שלך) לזרוק - לומד מההתחמקויות
var dodges := {"jump": 0, "duck": 0}
var _cd := 1.2
var _wind := 0.0


func stats() -> Dictionary:
	return {"name": "AXEMAN", "hp": 30, "walk": 42.0, "chase": 80.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 1.05,
		"duck": 0.3, "cover": 0.3, "skin": Color("8a9a88"), "shirt": Color("d0a020"), "pants": Color("2a3a5a"), "shoe": Color("4a2a1a"), "points": 470}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.2}


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.4 if axes == 0 else 1.0


func learn(how: String) -> void:   # נקרא מהגרזן: איך השחקן התחמק
	dodges[how] = int(dodges[how]) + 1
	if how == "jump":
		aim_y = maxf(aim_y - 18.0, -64.0)   # לזרוק גבוה (איפה שאתה נוחת / קופץ)
		z._popup("HE READS YOUR JUMP", Color("ffd080"), 12, -80.0)
	else:
		aim_y = minf(aim_y + 12.0, -10.0)
		z._popup("HE AIMS LOW", Color("ffd080"), 12, -80.0)


func catch_axe() -> void:
	axes = mini(axes + 1, 2)
	Sfx.play("ax_catch", z.global_position, -4.0, 0.1, 3)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if absf(d.y) > 120.0 or absf(d.x) > 700.0:
		return false
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	if _wind > 0.0:   # תנופה לזריקה
		_wind -= delta
		if _wind <= 0.0:
			_throw(pl)
		return _move(0.0, delta)
	if axes == 0:   # בלי גרזנים - בורח
		return _move(-z._dir * float(z.chase_speed), delta)
	if absf(d.x) < KEEP.x:   # שומר מרחק
		return _move(-z._dir * float(z.walk_speed) * 1.6, delta)
	if absf(d.x) < AXE_R and _cd <= 0.0:
		_wind = 0.35
		return _move(0.0, delta)
	if absf(d.x) > KEEP.y:
		return false
	return _move(0.0, delta)


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 700.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall() and vx != 0.0:
		z.velocity.y = -380.0
	z.move_and_slide()
	return true


func hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 10.0, -40.0) * z.sc


func _throw(pl: Node) -> void:
	if axes <= 0:
		return
	axes -= 1
	throws += 1
	_cd = THROW_CD
	var a := Axe.new()
	a.owner_t = self
	a.home = z
	var tgt: Vector2 = pl.global_position + Vector2(pl.velocity.x * 0.25, aim_y)
	a.dir = (tgt - hand()).normalized()
	a.max_d = minf(hand().distance_to(tgt) + 140.0, AXE_R + 120.0)
	a.aim_y = aim_y
	z.get_parent().add_child(a)
	a.global_position = hand()
	Sfx.play("ax_throw", hand(), -2.0, 0.1, 3)


func on_death() -> void:
	axes = 0


# ============================================================
#  גרזן קרח מסתובב: עף בקו ישר עד max_d, ואז חוזר אל הזורק (מתעקל אליו). פוגע פעם בכל כיוון.
# ============================================================
class Axe extends Node2D:
	var owner_t = null
	var home: Node = null
	var dir := Vector2.RIGHT
	var max_d := 400.0
	var aim_y := -26.0
	var back := false
	var _d := 0.0
	var _t := 0.0
	var _hit_out := false
	var _hit_back := false
	var _passed := false

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		var v := 430.0   # = AXE_V
		var pl := get_tree().get_first_node_in_group("player")
		if not back:
			var step := dir * v * delta
			_d += step.length()
			var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1))
			global_position += step
			if _d >= max_d or not hit.is_empty():
				back = true
		else:
			if home == null or not is_instance_valid(home) or home.dead:
				_drop()
				return
			var to: Vector2 = home.global_position + Vector2(0, -40) - global_position
			if to.length() < 18.0:
				if owner_t != null:
					owner_t.catch_axe()
				queue_free()
				return
			global_position += to.normalized() * v * 1.1 * delta
		if pl != null and not pl.dead:
			var hit_now: bool = pl.body_rect().grow(5.0).has_point(global_position)
			if hit_now and ((not back and not _hit_out) or (back and not _hit_back)):
				if back:
					_hit_back = true
				else:
					_hit_out = true
				if owner_t != null and is_instance_valid(owner_t.z):
					owner_t.axe_hits += 1
				pl.hurt(1, Vector2(signf(dir.x) * 1.2, -0.6))
			# עבר את השחקן בלי לפגוע -> הזורק לומד איך התחמקת
			if not back and not _passed and not _hit_out and absf(global_position.x - pl.global_position.x) < 10.0:
				_passed = true
				if owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead:
					if not pl.is_on_floor():
						owner_t.learn("jump")
					elif pl._crouching:
						owner_t.learn("duck")
		if Engine.get_physics_frames() % 9 == 0:
			preload("res://sfx.gd").play("ax_spin", global_position, -10.0, 0.2, 2)
		if _t > 4.0:
			_drop()
			return
		queue_redraw()

	func _drop() -> void:
		if owner_t != null and is_instance_valid(owner_t.z) and not owner_t.z.dead:
			owner_t.catch_axe()   # (נאבד) - מקבל חדש מהתרמיל כדי לא להיתקע
		queue_free()

	func _draw() -> void:
		var a := _t * 18.0
		var hd := Vector2.from_angle(a)
		draw_line(-hd * 12.0, hd * 12.0, Color("5a3a22"), 3.0)   # ידית
		draw_line(-hd * 12.0, -hd * 15.0, Color("8a8a90"), 2.0)   # חוד תחתון
		var hn := hd.orthogonal()
		draw_colored_polygon(PackedVector2Array([hd * 12.0 - hn * 3.0, hd * 12.0 + hn * 12.0, hd * 9.0 + hn * 10.0, hd * 10.0 - hn * 3.0]), Color("b8c0c8"))   # להב
		draw_line(hd * 12.0 - hn * 3.0, hd * 12.0 - hn * 8.0, Color("b8c0c8"), 3.0)   # את
		draw_arc(Vector2.ZERO, 14.0, a + 2.0, a + 3.6, 6, Color(1, 1, 1, 0.3), 2.0)


# ============================================================
#  ציור: מעיל צהוב, קסדת טיפוס כתומה, חבל מגולגל, גרזני קרח (כמה שנשארו בידיים)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var hb := sh + Vector2(-6.0 - sin(p) * 2.0, 14.0)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	if axes >= 2:   # גרזן ביד האחורית
		z.draw_line(hb + Vector2(0, -4), hb + Vector2(0, 10), col(Color("5a3a22")), 2.0)
		z.draw_line(hb + Vector2(-4, -4), hb + Vector2(5, -5), col(Color("a8b0b8")), 2.5)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(8, 3), hip + Vector2(-8, 3)]), coat, 0.15, 0.4)
	z.draw_arc(sh + Vector2(-2, 6), 6.0, 0.0, TAU, 10, col(Color("c03a2a")), 2.0)   # חבל מגולגל
	z.draw_line(sh + Vector2(-6, -1), hip + Vector2(6, 0), col(Color("c03a2a")), 1.5)
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	z.draw_colored_polygon(Art.ellipse(head + Vector2(0, -2.5), 6.2, 4.6, 0.0, 12), col(Color("e06a1a")))   # קסדה
	z.draw_rect(Rect2(head + Vector2(-6, -1), Vector2(12, 1.5)), col(Color("2a2a2a")))
	z.draw_rect(Rect2(head + Vector2(1, -0.5), Vector2(5, 2.5)), col(Color("2a3a4a")))   # משקפיים
	var hf := sh + Vector2(10, -8) if _wind > 0.0 else sh + Vector2(12, 6)
	z._arm(sh + Vector2(3, 1), hf, sk, coat)
	if axes >= 1:
		z.draw_line(hf + Vector2(0, 4), hf + Vector2(0, -12), col(Color("5a3a22")), 2.0)
		z.draw_colored_polygon(PackedVector2Array([hf + Vector2(-2, -12), hf + Vector2(9, -14), hf + Vector2(8, -11), hf + Vector2(-2, -9)]), col(Color("b8c0c8")))
		z.draw_line(hf + Vector2(-2, -11), hf + Vector2(-6, -12), col(Color("b8c0c8")), 2.0)
	end_draw()
	return true
