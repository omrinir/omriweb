extends "res://enemies/zombie_type.gd"
# ============================================================
#  HARPOONER (שלב 22, "THE DAM") - צוללן זומבי: חליפת צלילה, מסכה ושנורקל, סנפירים, רובה צלצל עם גלגלת.
#  מחזור:
#    WALK  - מתקרב ושומר מרחק (המוח).
#    AIM   - מרים את הרובה, קו כוונה דק (AIM_T) = אזהרה. מכוון למרכז הגוף שלך (גם אם אתה כפוף).
#    SHOT  - הצלצל עף עם חבל (Spear). פגע בך -> נזק + "נתפסת": הוא מגלגל את החבל ומושך אותך אליו
#            (REEL_PULL) - רצים / קופצים נגד הכיוון כדי להאט. פגע בקיר / פספס -> הצלצל חוזר לבד.
#    REEL  - מגלגל את הצלצל בחזרה לרובה. בלי צלצל = לא יכול לירות -> החלון שלך.
#    RELOAD- טוען (RELOAD_T).
#  לשנות: RANGE, AIM_T, SPEAR_V, SPEAR_RANGE, REEL_V, REEL_PULL, HOLD_T, RELOAD_T.
# ============================================================

const SOUNDS := {
	"hp_shot": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.12, 0.0, 22.0, 0.8, 0.5, 0], ["S", 900, 300, 0.0, 0.15, 0.0, 16.0, 0.5, 1.0, 0]]},
	"hp_reel": {"drive": 1.2, "layers": [["C", 0, 0, 0.0, 0.03, 0.0, 40.0, 0.35, 1.0, 0], ["C", 0, 0, 0.07, 0.03, 0.0, 40.0, 0.35, 1.0, 0], ["C", 0, 0, 0.14, 0.03, 0.0, 40.0, 0.35, 1.0, 0], ["C", 0, 0, 0.21, 0.03, 0.0, 40.0, 0.35, 1.0, 0]]},
}

const RANGE := 520.0
const AIM_T := 0.6
const SPEAR_V := 820.0
const SPEAR_RANGE := 540.0
const REEL_V := 520.0
const REEL_PULL := 360.0       # כמה מהר הוא מושך אותך
const HOLD_T := 1.0            # הכי הרבה זמן שהוא מושך אותך
const RELOAD_T := 1.1
const CD := Vector2(1.4, 2.2)
const DAMAGE := 1

enum { WALK, AIM, SHOT, RELOAD }
var state := WALK
var shots := 0           # לבדיקות
var hooks := 0
var _st := 0.0
var _cd := 1.0
var _aim := 0.0
var spear: Node2D = null


func stats() -> Dictionary:
	return {"name": "HARPOONER", "hp": 30, "walk": 44.0, "chase": 88.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.2, "cover": 0.35, "skin": Color("8a9e98"), "shirt": Color("1e3a40"), "pants": Color("1a2e34"), "shoe": Color("e0b020"), "points": 420}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.35, "keep_range": 300.0}


func can_bite() -> bool:
	return state == WALK or state == RELOAD


func _pivot() -> Vector2:
	return z.global_position + Vector2(z._dir * 5.0, -35.0) * z.sc


func muzzle() -> Vector2:
	return _pivot() + Vector2.from_angle(_aim) * 26.0 * z.sc


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if _cd <= 0.0 and has_pl and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees
				if sees and absf(d.x) < RANGE and absf(d.y) < 200.0 and absf(d.x) > 60.0:
					state = AIM
					_st = AIM_T
					z._dir = signf(d.x)
					_aim = (_target(pl) - _pivot()).angle()
					return _stay(delta)
			return false
		AIM:
			if has_pl:
				z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
				_aim = lerp_angle(_aim, (_target(pl) - _pivot()).angle(), delta * 7.0)
			if _st <= 0.0:
				_fire()
			return _stay(delta)
		SHOT:
			if spear == null or not is_instance_valid(spear):   # הצלצל חזר
				state = RELOAD
				_st = RELOAD_T
			return _stay(delta)
		RELOAD:
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
				return false
			return _stay(delta)
	return false


func _target(pl: Node) -> Vector2:
	var r: Rect2 = pl.body_rect()
	return r.get_center()


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _fire() -> void:
	state = SHOT
	shots += 1
	var s := Spear.new()
	s.owner_z = z
	s.tm = self
	z.get_parent().add_child(s)
	s.global_position = muzzle()
	s.velocity = Vector2.from_angle(_aim) * SPEAR_V
	spear = s
	Sfx.play("hp_shot", muzzle(), 0.0, 0.1, 2)


func on_death() -> void:
	if spear != null and is_instance_valid(spear):
		spear.release()


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.0)
	var hip := Vector2(0.0, -21.0 + absf(sin(p)) * 0.8)
	var sh := Vector2(1.0, -36.0)
	var head := sh + Vector2(3.5, -8.0)
	# בלון חמצן על הגב
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-11, -2), sh + Vector2(-5, -3), hip + Vector2(-5, -4), hip + Vector2(-11, -3)]), col(Color("c8c040")), 0.15, 0.4)
	DrawBatch.line(z, sh + Vector2(-8, -3), head + Vector2(-3, -3), col(Color("2a2a2a")), 1.4)   # צינור
	_leg_flipper(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)))
	_leg_flipper(hip + Vector2(2, 0), f[0], col(z.pants))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 2.0, 14.0), Art.shade(suit, 0.2), Art.shade(suit, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), suit, 0.12, 0.4)
	DrawBatch.line(z, sh + Vector2(-5, 3), hip + Vector2(4, 0), col(Color("e0b020")), 1.2)   # פס צהוב
	DrawBatch.rect(z, Rect2(hip + Vector2(-5, -2), Vector2(10, 2)), col(Color("2a2a2a")))     # חגורת משקולות
	# ראש: מסכת צלילה + שנורקל
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(0, -4), head + Vector2(6.5, -4), head + Vector2(6.5, 1.5), head + Vector2(0, 1.5)]), col(Color("3a3a40")), Art.OUTLINE, 1.0)
	DrawBatch.rect(z, Rect2(head + Vector2(1, -3), Vector2(4.8, 3.6)), Color(0.55, 0.8, 0.9, 0.85))
	DrawBatch.line(z, head + Vector2(1.5, -2.5), head + Vector2(3, -2.5), Color(1, 1, 1, 0.8), 1.0)   # ברק
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -1.2), 0.8, Color(1.0, 0.45, 0.2))
	DrawBatch.line(z, head + Vector2(-5, -1), head + Vector2(5, -1), col(Color("2a2a2a")), 1.0)   # רצועה
	DrawBatch.line(z, head + Vector2(-4, 2), head + Vector2(-5, -9), col(Color("e0b020")), 1.6)   # שנורקל
	# רובה הצלצל
	var a := _aim if state == AIM or state == SHOT else (0.3 if z._dir > 0.0 else PI - 0.3)
	var la := Vector2(cos(a) * z._dir, sin(a)).normalized()
	var piv := Vector2(5.0, -35.0)
	var hand := piv + la * 8.0
	var tr := Transform2D(la.angle(), hand)
	Art.fill(z, tr * PackedVector2Array([Vector2(-6, -1.5), Vector2(20, -1.5), Vector2(20, 1.5), Vector2(-6, 1.5)]), col(Color("3a3a3e")), Art.OUTLINE, 1.0)   # קנה
	Art.fill(z, tr * PackedVector2Array([Vector2(-1, 1.5), Vector2(3, 1.5), Vector2(1, 7), Vector2(-3, 6.5)]), col(Color("2a2a2a")), Art.OUTLINE, 0.8)   # ידית
	DrawBatch.circle(z, tr * Vector2(-4, 3.5), 2.8, col(Color("8a8a90")))   # גלגלת
	DrawBatch.circle(z, tr * Vector2(-4, 3.5), 1.2, col(Color("4a4a50")))
	if state != SHOT:   # הצלצל טעון
		DrawBatch.line(z, tr * Vector2(4, -2.4), tr * Vector2(27, -2.4), col(Color("c8ccd4")), 1.4)
		DrawBatch.colored_polygon(z, PackedVector2Array([tr * Vector2(27, -4.4), tr * Vector2(32, -2.4), tr * Vector2(27, -0.4)]), col(Color("e0e4ec")))
	if state == AIM and not z.dead:
		var m := tr * Vector2(32, -2.4)
		DrawBatch.line(z, m, m + la * 110.0, Color(1.0, 0.2, 0.1, 0.3), 1.0)
		if int(z._time * 12.0) % 2 == 0:
			Art.glow(z, m, 4.0, Color(1.0, 0.3, 0.1, 0.8))
	z._arm(sh + Vector2(3, 1), hand, sk, suit)
	end_draw()
	return true


func _leg_flipper(hip: Vector2, foot: Vector2, c: Color) -> void:
	Art.limb(z, PackedVector2Array([hip, hip.lerp(foot, 0.5) + Vector2(1, 0), foot]), 3.4, c)
	Art.fill(z, PackedVector2Array([foot + Vector2(-2, -1), foot + Vector2(10, 0), foot + Vector2(11, 2.5), foot + Vector2(-2, 2)]), col(z.shoe), Art.OUTLINE, 0.8)   # סנפיר


# ---- הצלצל: עף, נתקע / תופס אותך, וחוזר עם החבל ----
class Spear extends Node2D:
	var owner_z: Node = null
	var tm = null
	var velocity := Vector2.ZERO
	var hooked: Node = null
	var _phase := 0          # 0 = עף, 1 = נתקע, 2 = חוזר
	var _t := 0.0
	var _hold := 0.0
	var _dist := 0.0
	var _reel_snd := 0.0

	func _ready() -> void:
		z_index = 9

	func release() -> void:
		hooked = null
		queue_free()

	func _muzzle() -> Vector2:
		if owner_z != null and is_instance_valid(owner_z) and not owner_z.dead and tm != null:
			return tm.muzzle()
		return global_position

	func _physics_process(delta: float) -> void:
		if owner_z == null or not is_instance_valid(owner_z) or owner_z.dead:
			queue_free()
			return
		var H = tm   # הקבועים של HARPOONER
		match _phase:
			0:
				var to := global_position + velocity * delta
				_dist += velocity.length() * delta
				var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))
				if not hit.is_empty():
					global_position = hit.position
					_phase = 1
					_t = 0.3
					Sfx.play("clink", global_position, -2.0)
					queue_redraw()
					return
				var p := get_tree().get_first_node_in_group("player")
				if p != null and not p.dead:
					var r: Rect2 = p.body_rect()
					for i in 3:
						if r.has_point(global_position.lerp(to, float(i) / 2.0)):
							hooked = p
							tm.hooks += 1
							p.hurt(H.DAMAGE, Vector2(signf(velocity.x), 0.0))
							p._say("HOOKED!", Color("ff6050"))
							_phase = 2
							_hold = H.HOLD_T
							break
				global_position = to
				rotation = velocity.angle()
				if _dist > H.SPEAR_RANGE:
					_phase = 2
			1:
				_t -= delta
				if _t <= 0.0:
					_phase = 2
			2:
				var m := _muzzle()
				var dv := m - global_position
				_reel_snd -= delta
				if _reel_snd <= 0.0:
					_reel_snd = 0.3
					Sfx.play("hp_reel", m, -6.0, 0.1, 2)
				if hooked != null and is_instance_valid(hooked) and not hooked.dead:
					_hold -= delta
					var dx: float = m.x - hooked.global_position.x
					if _hold <= 0.0 or absf(dx) < 46.0:
						hooked = null   # שוחרר
					else:   # מושך אותך אליו (השליטה שלך חלשה בזמן הזה)
						hooked._push_t = 0.12
						hooked.velocity.x = signf(dx) * H.REEL_PULL
						global_position = hooked.global_position + Vector2(0, -30)
						rotation = (-dv).angle()
						queue_redraw()
						return
				if dv.length() < 14.0:
					queue_free()
					return
				global_position += dv.normalized() * minf(H.REEL_V * delta, dv.length())
				rotation = (-dv).angle()
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var m := _muzzle() - global_position
		var mid := m * 0.5 + Vector2(0, 8.0 if _phase != 2 else 2.0)
		var rope := PackedVector2Array([Vector2.ZERO, mid, m])
		DrawBatch.set_transform(self, Vector2.ZERO, -rotation, Vector2.ONE)   # החבל במרחב העולם
		DrawBatch.polyline(self, rope, Color(0.85, 0.82, 0.7, 0.9), 1.2, true)
		DrawBatch.set_transform(self, Vector2.ZERO, 0.0, Vector2.ONE)
		DrawBatch.line(self, Vector2(-22, 0), Vector2(0, 0), Color("c8ccd4"), 1.6)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(0, -2.5), Vector2(7, 0), Vector2(0, 2.5)]), Color("e8ecf4"))
		DrawBatch.line(self, Vector2(-2, 0), Vector2(-6, -3), Color("c8ccd4"), 1.2)   # חוד חוזר
		DrawBatch.line(self, Vector2(-2, 0), Vector2(-6, 3), Color("c8ccd4"), 1.2)
