extends "res://enemies/zombie_type.gd"
# ============================================================
#  BIKER (שלב 23, "HIGHWAY 7") - זומבי אופנוען במעיל עור ובנדנה, על אופנוע חלוד.
#  על האופנוע:
#    CRUISE - נוסע לאט ושומר מרחק (RANGE).
#    REV    - עוצר, מרים גלגל קדמי ומרעיש את המנוע (REV_T) + עשן = אזהרה!
#    CHARGE - דוהר אליך (CHARGE_V) וממשיך הלאה (OVERSHOOT). פגיעה = DAMAGE + הדף. קופץ מעל מכוניות בדרך.
#    SKID   - בולם ומסתובב (SKID_T) = החלון שלך.
#  ירית בו מספיק (DISMOUNT_AT) -> עף מהאופנוע: האופנוע מחליק ומתלקח, והוא ממשיך ברגל (זומבי רגיל).
#  התחמקות: קפיצה מעליו / גלגול / לעמוד מאחורי מכונית.
#  בוס: ROAD KING - גדול, מסתער פעמיים ברצף.
#  לשנות: RANGE, REV_T, CHARGE_V, OVERSHOOT, SKID_T, DISMOUNT_AT.
# ============================================================

const SOUNDS := {
	"bk_rev": {"drive": 2.2, "layers": [["S", 60, 140, 0.0, 0.6, 0.05, 2.5, 0.8, 1.0, 0], ["N", 0, 0, 0.0, 0.55, 0.05, 3.0, 0.45, 0.3, 0]]},
	"bk_skid": {"drive": 1.6, "layers": [["N", 0, 0, 0.0, 0.5, 0.0, 4.0, 0.6, 0.85, 0, 0.6]]},
}

const RANGE := 360.0
const REV_T := 0.75
const CHARGE_V := 520.0
const OVERSHOOT := 280.0
const SKID_T := 0.75
const DISMOUNT_AT := 0.5
const DAMAGE := 2

enum { CRUISE, REV, CHARGE, SKID, FOOT }
var state := CRUISE
var charges := 0         # לבדיקות
var hits := 0
var _st := 0.0
var _cd := 1.5
var _target_x := 0.0
var _hit_done := false
var _wheel := 0.0
var _chain := 0          # בוס: כמה הסתערויות ברצף


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "BIKER", "hp": 360, "walk": 50.0, "chase": 100.0, "damage": 2, "bite_delay": 0.9, "scale": 1.5, "width": 1.1,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9a80"), "shirt": Color("2a2226"), "pants": Color("2e3a50"), "shoe": Color("1a1612"),
			"points": 1100, "boss": true, "boss_name": "ROAD KING - JUMP OVER THE CHARGE"}
	return {"name": "BIKER", "hp": 34, "walk": 50.0, "chase": 104.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a80"), "shirt": Color("2a2226"), "pants": Color("2e3a50"), "shoe": Color("1a1612"), "points": 450}


func can_bite() -> bool:
	return state == FOOT


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.3 if state == SKID else 1.0


func on_damage(_amount: int, _hit_pos: Vector2, dir: Vector2, _src: Dictionary) -> bool:
	if state != FOOT:
		_check_dismount.call_deferred(dir)
	return true


func _check_dismount(dir: Vector2) -> void:
	if z == null or not is_instance_valid(z) or z.dead or state == FOOT:
		return
	if float(z.hp) / float(z.max_hp) <= DISMOUNT_AT:
		_dismount(dir)


func _dismount(dir: Vector2) -> void:
	state = FOOT
	var w := Wreck.new()
	w.face = z._dir
	w.sc = z.sc
	w.velocity = Vector2(z.velocity.x * 0.7 + signf(dir.x) * 60.0, -120.0)
	z.get_parent().add_child(w)
	w.global_position = z.global_position
	z.velocity = Vector2(signf(dir.x if dir.x != 0.0 else -z._dir) * 220.0, -260.0)
	z._popup("THROWN OFF!", Color("ffb070"), 14, -80.0)
	Sfx.play("bk_skid", z.global_position, 2.0, 0.1, 2)


func on_death() -> void:
	if state != FOOT:   # מת על האופנוע - האופנוע ממשיך להחליק
		_dismount(Vector2(z._dir, 0.0))


func physics(pl: Node, delta: float) -> bool:
	if z.dead or state == FOOT:
		return false
	_cd -= delta
	_st -= delta
	var has_pl: bool = pl != null and not pl.dead
	var d := Vector2.ZERO
	if has_pl:
		d = pl.global_position - z.global_position
	match state:
		CRUISE:
			var want := 0.0
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
				if absf(d.x) > RANGE + 60.0:
					want = z._dir * 160.0
				elif absf(d.x) < RANGE - 120.0:
					want = -z._dir * 120.0
				if _cd <= 0.0 and absf(d.x) < RANGE + 220.0 and absf(d.y) < 120.0 and z.is_on_floor():
					state = REV
					_st = REV_T
					Sfx.play("bk_rev", z.global_position, 2.0, 0.08, 2)
			z.velocity.x = move_toward(z.velocity.x, want, 500.0 * delta)
		REV:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if Engine.get_physics_frames() % 6 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 26.0, -10.0) * z.sc, "smoke", Vector2(-z._dir, -0.4), 1)
			if _st <= 0.0:
				_start_charge(pl)
		CHARGE:
			z.velocity.x = move_toward(z.velocity.x, z._dir * CHARGE_V * (1.1 if _boss() else 1.0), 1400.0 * delta)
			if z.is_on_wall() and z.is_on_floor():   # מכונית בדרך: קופץ מעליה
				z.velocity.y = -470.0
			if has_pl and not _hit_done:
				var r: Rect2 = pl.body_rect().grow(4.0)
				var b := Rect2(z.global_position + Vector2(-22.0, -46.0) * z.sc, Vector2(44.0, 46.0) * z.sc)
				if r.intersects(b):
					_hit_done = true
					hits += 1
					pl.hurt(DAMAGE + (1 if _boss() else 0), Vector2(z._dir * 2.4, -1.2))
			if (z._dir > 0.0 and z.global_position.x > _target_x) or (z._dir < 0.0 and z.global_position.x < _target_x):
				state = SKID
				_st = SKID_T
				Sfx.play("bk_skid", z.global_position, 0.0, 0.1, 2)
		SKID:
			z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			if Engine.get_physics_frames() % 4 == 0 and Art.on_screen(z, z.global_position) and absf(z.velocity.x) > 60.0:
				Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2(-z._dir, -0.3), 1)
			if _st <= 0.0:
				if _boss() and _chain < 1:   # בוס: מיד עוד הסתערות
					_chain += 1
					state = REV
					_st = REV_T * 0.6
				else:
					_chain = 0
					state = CRUISE
					_cd = randf_range(1.6, 2.6)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	z.global_position.x = clampf(z.global_position.x, 30.0, float(z.world_w) - 30.0)
	_wheel += z.velocity.x * delta / (9.0 * z.sc)
	return true


func _start_charge(pl: Node) -> void:
	state = CHARGE
	charges += 1
	_hit_done = false
	var px: float = pl.global_position.x if pl != null else z.global_position.x + z._dir * 300.0
	_target_x = px + z._dir * OVERSHOOT
	z.velocity.x = z._dir * 200.0


# ============================================================
#  ציור: אופנוע (גלגלים מסתובבים, מיכל, פנס, אגזוז) + רוכב רכון קדימה
# ============================================================
func draw() -> bool:
	if z.dead or state == FOOT:
		return _draw_foot()
	var s := Vector2(z._dir * z.wf * z.sc, z.sc)
	var lift := 0.0
	if state == REV:
		lift = -0.28 + sin(z._time * 30.0) * 0.03   # גלגל קדמי באוויר
	elif state == SKID:
		lift = 0.06
	var rear := Vector2(-15, -9)
	DrawBatch.set_transform_matrix(z, Transform2D(0.0, s, 0.0, Vector2.ZERO) * Transform2D(lift, rear) * Transform2D(0.0, -rear))
	if z.is_on_floor() and lift > -0.1:
		Art.ground_shadow(z, Vector2.ZERO, 26.0)
	var sk := col(z.skin)
	var jacket := col(z.shirt)
	var metal := col(Color("6a6e74"))
	var red := col(Color("8a2a22"))
	# גלגלים
	for wc in [Vector2(-15, -9), Vector2(17, -9)]:
		DrawBatch.circle(z, wc, 9.0, Art.OUTLINE)
		DrawBatch.circle(z, wc, 7.5, col(Color("2a2a2c")))
		DrawBatch.circle(z, wc, 4.5, metal)
		for k in 4:
			var a := _wheel + float(k) * PI / 4.0
			DrawBatch.line(z, wc - Vector2.from_angle(a) * 4.0, wc + Vector2.from_angle(a) * 4.0, col(Color("3a3a3e")), 1.0)
	# שלדה, מיכל, מושב, מזלג קדמי, אגזוז
	DrawBatch.line(z, Vector2(-15, -9), Vector2(-2, -18), metal, 3.0)
	DrawBatch.line(z, Vector2(-2, -18), Vector2(12, -20), metal, 3.0)
	DrawBatch.line(z, Vector2(12, -24), Vector2(17, -9), col(Color("8a8e94")), 2.4)   # מזלג
	Art.fill(z, PackedVector2Array([Vector2(-1, -19), Vector2(13, -22), Vector2(12, -15), Vector2(0, -14)]), red, Art.OUTLINE, 1.0)   # מיכל
	Art.fill(z, PackedVector2Array([Vector2(-14, -19), Vector2(-1, -19), Vector2(-2, -16), Vector2(-14, -16)]), col(Color("1e1a18")), Art.OUTLINE, 0.8)   # מושב
	DrawBatch.line(z, Vector2(-6, -12), Vector2(-22, -14), col(Color("9a9aa0")), 2.4)   # אגזוז
	DrawBatch.line(z, Vector2(12, -24), Vector2(9, -28), col(Color("2a2a2c")), 2.0)   # כידון
	DrawBatch.circle(z, Vector2(18, -21), 2.4, col(Color("d8d0a0")))   # פנס
	if not z.dead:
		Art.glow(z, Vector2(22, -21), 7.0 if state == CHARGE else 4.0, Color(1.0, 0.95, 0.7, 0.5))
	# רוכב: רגליים על הדוושות, גוף רכון קדימה, ידיים לכידון
	var hip := Vector2(-6, -21)
	var sh := Vector2(4, -33) if state == CHARGE else Vector2(1, -35)
	var head := sh + Vector2(5, -6)
	z._leg(hip, Vector2(2, -12), col(z.pants), sk, col(z.shoe))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(5, 0), hip + Vector2(5, 1), hip + Vector2(-5, 1)]), jacket, 0.12, 0.4)
	DrawBatch.line(z, sh + Vector2(-3, 1), hip + Vector2(0, -1), col(Color("6a6a70")), 1.0)   # רוכסן
	Art.oval_shaded(z, head, 5.2, 5.6, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-6, -1), head + Vector2(-4, -6), head + Vector2(4, -6.5), head + Vector2(6, -2)]), red, Art.OUTLINE, 0.9)   # בנדנה
	DrawBatch.line(z, head + Vector2(-5, -2), head + Vector2(-9 - sin(z._time * 14.0) * 2.0, 1), red, 1.4)   # קצה מתנופף
	DrawBatch.rect(z, Rect2(head + Vector2(0.5, -2.5), Vector2(5.5, 2.0)), col(Color("101014")))   # משקפיים
	z._arm(sh + Vector2(2, 1), Vector2(10, -27), sk, jacket)
	end_draw()
	return true


func _draw_foot() -> bool:   # בלי אופנוע: זומבי עם מעיל עור (הציור הרגיל + בנדנה)
	begin_draw()
	var sk := col(z.skin)
	var jacket := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), Art.shade(sk, 0.25), Art.shade(jacket, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), jacket, 0.12, 0.4)
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-6, -1), head + Vector2(-4, -6), head + Vector2(4, -6.5), head + Vector2(6, -2)]), col(Color("8a2a22")), Art.OUTLINE, 0.9)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -1.0), 0.9, Color(1.0, 0.5, 0.2))
	z._arm(sh + Vector2(3, 1), sh + Vector2(9.0 + sin(p) * 3.0, 13.0), sk, jacket)
	end_draw()
	return true


# ---- האופנוע אחרי שהרוכב עף: מחליק, מתהפך, נדלק לרגע ----
class Wreck extends Node2D:
	var velocity := Vector2.ZERO
	var face := 1.0
	var sc := 1.0
	var life := 6.0
	var _fire := 1.5
	var _rot := 0.0

	func _ready() -> void:
		z_index = 2

	func _physics_process(delta: float) -> void:
		life -= delta
		_fire -= delta
		if life <= 0.0:
			queue_free()
			return
		velocity.y += 1000.0 * delta
		var to := global_position + velocity * delta
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 2), 1 | 16))
		if hit:
			global_position = hit.position + Vector2(0, -1)
			velocity.y = 0.0
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			_rot = move_toward(_rot, PI * 0.5 * face, 6.0 * delta)
		else:
			global_position = to
		if _fire > 0.0 and Engine.get_physics_frames() % 5 == 0:
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -12), "fire", Vector2.UP, 2)
		queue_redraw()

	func _draw() -> void:
		var a := clampf(life, 0.0, 1.0)
		DrawBatch.set_transform(self, Vector2.ZERO, _rot * 0.6, Vector2(face * sc, sc))
		for wc in [Vector2(-15, -9), Vector2(17, -9)]:
			DrawBatch.circle(self, wc, 8.5, Color(0.1, 0.1, 0.1, a))
			DrawBatch.circle(self, wc, 4.0, Color(0.4, 0.4, 0.42, a))
		DrawBatch.line(self, Vector2(-15, -9), Vector2(12, -20), Color(0.35, 0.35, 0.38, a), 3.0)
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-1, -19), Vector2(13, -22), Vector2(12, -15), Vector2(0, -14)]), Color(0.45, 0.15, 0.12, a))
