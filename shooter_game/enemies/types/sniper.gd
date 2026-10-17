extends "res://enemies/zombie_type.gd"
# ============================================================
#  SNIPER (שלב 27, "PLATEAU GATE") - צלף במגדלי השמירה: קסדה, כיסוי הסוואה, רובה ארוך עם כוונת.
#    WATCH - מחכה וסורק.
#    AIM   - לייזר אדום מהכוונת אליך + ניצוץ בעדשה. הלייזר עוקב אחריך באיחור (TRACK) ל-LOCK_T שניות.
#    FIRE  - ב-FREEZE השניות האחרונות הלייזר ננעל ומהבהב, ואז ירייה חזקה (DAMAGE) בכיוון שלו - זוז עכשיו והיא מפספסת.
#    DUCK  - חכם: כשאתה מכוון אליו (הכוונת שלך קרובה אליו) הוא מתכופף מאחורי שקי החול (DUCK_T, כמעט לא נפגע).
#            "דיכוי": כל עוד אתה מכוון אליו הוא לא יורה - אבל אז קשה לפגוע בו. תכוון הצידה ותפתיע.
#  לשנות: RANGE, LOCK_T, TRACK, DAMAGE, DUCK_T, DUCK_R.
# ============================================================

const RANGE := 1000.0
const LOCK_T := 1.3
const TRACK := 2.6           # כמה מהר הלייזר עוקב (קטן = איטי)
const FREEZE := 0.3          # השניות האחרונות: הלייזר ננעל במקום (ומהבהב)
const DAMAGE := 2
const DUCK_T := 1.1
const DUCK_R := 70.0         # כמה קרוב הכוונת שלך צריכה להיות כדי שיתכופף
const CD := Vector2(1.6, 2.4)

enum { WATCH, AIM, DUCK }
var state := WATCH
var shots := 0               # לבדיקות
var hits := 0
var ducks := 0
var _st := 0.0
var _cd := 1.5
var _duck_cd := 0.0
var _tgt := Vector2.ZERO     # לאן הלייזר מכוון (עולם)
var _flash := 0.0


func stats() -> Dictionary:
	return {"name": "SNIPER", "hp": 32, "walk": 40.0, "chase": 80.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a80"), "shirt": Color("5a6040"), "pants": Color("4a5034"), "shoe": Color("2a2418"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "keep_range": 600.0}


func can_bite() -> bool:
	return state == WATCH


func damage_mult(_zone: String, src: Dictionary) -> float:
	if state == DUCK and str(src.get("source", "")) == "bullet":
		return 0.15   # מאחורי שקי החול
	return 1.0


func _eye() -> Vector2:
	return z.global_position + Vector2(z._dir * 6.0, (-24.0 if state == DUCK else -40.0)) * z.sc


func _aimed_at(pl: Node) -> bool:
	if not pl.has_method("aim_world"):
		return false
	var a: Vector2 = pl.aim_world()
	return a.distance_to(z.global_position + Vector2(0, -36.0) * z.sc) < DUCK_R


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_duck_cd -= delta
	_flash -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	if has_pl and state != DUCK and _duck_cd <= 0.0 and _aimed_at(pl) and absf(pl.global_position.x - z.global_position.x) > 150.0:
		state = DUCK   # אתה מכוון אליו - מתכופף
		_st = DUCK_T
		ducks += 1
		return _stay(delta)
	match state:
		WATCH:
			if not has_pl:
				return _stay(delta)
			var d: Vector2 = pl.global_position - z.global_position
			if absf(d.x) > 8.0:
				z._dir = signf(d.x)
			if _cd <= 0.0 and absf(d.x) < RANGE and absf(d.y) < 400.0 and absf(d.x) > 90.0:
				if _clear(pl.global_position + Vector2(0, -30)):
					state = AIM
					_st = LOCK_T
					_tgt = pl.global_position + Vector2(-z._dir * 80.0, -30.0)   # מתחיל קצת לפניך
					Sfx.play("rv_cock", z.global_position, -2.0, 0.08, 2)
			if absf(d.x) < 120.0:   # קרוב מדי - נלחם רגיל
				return false
			return _stay(delta)
		AIM:
			if not has_pl:
				state = WATCH
				return _stay(delta)
			var want: Vector2 = pl.global_position + Vector2(0, -30)
			if _st > FREEZE:   # ברגע האחרון הלייזר ננעל ומהבהב - זה הזמן לזוז
				_tgt = _tgt.lerp(want, clampf(delta * TRACK, 0.0, 1.0))
			z._dir = signf(_tgt.x - z.global_position.x) if absf(_tgt.x - z.global_position.x) > 4.0 else z._dir
			if _st <= 0.0:
				_fire(pl)
				state = WATCH
				_cd = randf_range(CD.x, CD.y)
			return _stay(delta)
		DUCK:
			if _st <= 0.0:
				state = WATCH
				_duck_cd = 0.6
				_cd = maxf(_cd, 0.5)
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _clear(to: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(_eye(), to, 1)
	return z.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _fire(pl: Node) -> void:
	shots += 1
	_flash = 0.12
	Sfx.play("sniper", z.global_position, 0.0, 0.05, 2)
	var from := _eye()
	var dir := (_tgt - from).normalized()
	var to := from + dir * 1600.0
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, 1))
	if hit:
		to = hit.position
	var r: Rect2 = pl.body_rect()
	r.size.y *= 0.7   # מכוון לחזה: קליע שרק מגרד את הרגליים לא נחשב
	var c := Geometry2D.get_closest_point_to_segment(r.get_center(), from, to)
	if r.grow(2.0).has_point(c):
		hits += 1
		pl.hurt(DAMAGE, Vector2(dir.x * 1.6, -0.4))
	var tr := Tracer.new()
	tr.a = from
	tr.b = to
	z.get_parent().add_child(tr)


# ============================================================
#  ציור: קסדה עם רשת, מעיל הסוואה, רובה צלפים ארוך עם כוונת. AIM = לייזר אדום + ניצוץ.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var cam := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var ducked: bool = state == DUCK and not z.dead
	var hip := Vector2(0, -14) if ducked else Vector2(0, -22)
	var sh := hip + Vector2(2, -14 if ducked else -15)
	var head := sh + Vector2(3.5, -7.5)
	if ducked:
		z._leg(hip + Vector2(-2, 0), Vector2(-8, 0), col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
		z._leg(hip + Vector2(2, 0), Vector2(6, 0), col(z.pants), sk, col(z.shoe))
	else:
		z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
		z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(6, 4), hip + Vector2(-6, 4)]), cam, 0.12, 0.4)
	for q in 4:   # כתמי הסוואה
		z.draw_circle(sh + Vector2(-3.0 + float(q % 2) * 5.0, 3.0 + float(q) * 3.0), 1.8, col(Color("3a4028")))
	Art.oval_shaded(z, head, 5.2, 5.6, sk, 0.0)
	face(head)
	Art.fill(z, PackedVector2Array([head + Vector2(-6, -1), head + Vector2(-5, -6), head + Vector2(3, -7), head + Vector2(7, -3), head + Vector2(6, -1)]), col(Color("4a5034")), Art.OUTLINE, 1.0)   # קסדה
	for q in 3:
		z.draw_line(head + Vector2(-5.0 + float(q) * 4.0, -6), head + Vector2(-4.0 + float(q) * 4.0, -1), col(Color("2a2e1a")), 0.8)
	if not z.dead:
		z.draw_circle(head + Vector2(3.5, -0.5), 0.9, Color(1.0, 0.5, 0.2))
	# רובה
	var la := 0.0
	if state == AIM:
		var wd := _tgt - _eye()
		la = atan2(wd.y, wd.x * z._dir)
	var hand := sh + Vector2(6, 3)
	var tip := hand + Vector2.from_angle(la) * 30.0
	var butt := hand - Vector2.from_angle(la) * 10.0
	z.draw_line(butt, tip, Art.OUTLINE, 4.0)
	z.draw_line(butt, tip, col(Color("3a3226")), 2.4)
	var sc_p := hand + Vector2.from_angle(la) * 8.0 + Vector2.from_angle(la - 1.57) * 3.0   # כוונת
	z.draw_line(sc_p, sc_p + Vector2.from_angle(la) * 9.0, col(Color("1a1a1a")), 3.0)
	z._arm(sh + Vector2(-3, 1), hand + Vector2.from_angle(la) * 12.0, Art.shade(sk, 0.2), Art.shade(cam, 0.25))
	z._arm(sh + Vector2(3, 1), hand, sk, cam)
	if _flash > 0.0:
		z.draw_circle(tip + Vector2.from_angle(la) * 4.0, 6.0, Color(1.0, 0.85, 0.4, 0.9))
	end_draw()
	if state == AIM and not z.dead:   # לייזר בקואורדינטות עולם
		var from: Vector2 = _eye() - z.global_position
		var to: Vector2 = _tgt - z.global_position
		var k := 1.0 - clampf(_st / LOCK_T, 0.0, 1.0)
		if _st < FREEZE and fmod(z._time * 20.0, 1.0) < 0.5:   # ננעל - מהבהב
			k = 0.2
		z.draw_line(from, to, Color(1.0, 0.1, 0.1, 0.35 + 0.45 * k), 1.0 + k)
		z.draw_circle(to, 3.0 + k * 2.0, Color(1.0, 0.15, 0.1, 0.8))
		z.draw_circle(from, 3.0 + sin(z._time * 30.0), Color(1.0, 1.0, 0.9, 0.9))   # ניצוץ בעדשה
	return true


# ---- קו הירייה ----
class Tracer extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var _t := 0.2

	func _ready() -> void:
		z_index = 9

	func _process(delta: float) -> void:
		_t -= delta
		if _t <= 0.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.2
		draw_line(a - global_position, b - global_position, Color(1.0, 0.9, 0.6, 0.8 * k), 2.0)
