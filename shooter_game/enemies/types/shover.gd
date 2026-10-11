extends "res://enemies/zombie_type.gd"
# ============================================================
#  SHOVER (שלב 23, "HIGHWAY 7") - נהג משאית ענק: כובע מצחייה, זקן, חולצה משובצת, אפוד.
#  חכם: משתמש במכוניות הנטושות כנשק.
#    WALK  - מתקרב רגיל (המוח).
#    GO    - אם יש מכונית בינו לבינך (ואתה על הכביש) - הולך מאחוריה.
#    PUSH  - נשען ודוחף אותה אליך (Car.push) - המכונית מחליקה ופוגעת במי שבדרך. דחיפה של מכונית עם אזעקה = אזעקה!
#    SHOVE - אין מכונית ואתה צמוד אליו: מושך ידיים אחורה (אזהרה) ודוחף אותך חזק אחורה (נזק קטן, הדף גדול).
#  התחמקות: לקפוץ על המכונית / מעליה, לא לעמוד מול מכונית כשהוא מאחוריה.
#  לשנות: SEEK_R, PUSH_V, PUSH_T, SHOVE_WIND, SHOVE_KNOCK, CD.
# ============================================================

const SEEK_R := 340.0       # כמה רחוק הוא מחפש מכונית
const PUSH_V := 300.0
const PUSH_T := 0.9
const SHOVE_WIND := 0.4
const SHOVE_KNOCK := 3.4
const CD := 3.5

enum { WALK, GO, PUSH, SHOVE, REST }
var state := WALK
var shoving: Node = null     # המכונית שהוא דוחף (s23_decor.gd Car) - היא לא פוגעת בו
var pushes := 0              # לבדיקות
var shoves := 0
var _st := 0.0
var _cd := 1.0
var _look := 0.0
var _car: Node = null
var _tx := 0.0
var _hit := false


func stats() -> Dictionary:
	return {"name": "SHOVER", "hp": 70, "walk": 44.0, "chase": 84.0, "damage": 2, "bite_delay": 1.0, "scale": 1.3, "width": 1.25,
		"duck": 0.0, "cover": 0.0, "skin": Color("8aa07a"), "shirt": Color("9a2a26"), "pants": Color("2e3e5a"), "shoe": Color("2a1e14"), "points": 500}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func can_bite() -> bool:
	return false


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_look -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if not has_pl or not z.is_on_floor():
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if _cd <= 0.0 and _look <= 0.0:
				_look = 0.3
				var c := _find_car(pl)
				if c != null:
					_car = c
					var cx: float = c.global_position.x
					var w: float = c.size.x
					_tx = cx - 16.0 * z.sc if z.global_position.x < cx + w * 0.5 else cx + w + 16.0 * z.sc
					state = GO
					_st = 3.0
					z._popup("!", Color("ffb070"), 16, -70.0 * z.sc)
					return _move(delta, 0.0)
			if _cd <= 0.0 and absf(d.x) < 48.0 * z.sc and absf(d.y) < 50.0:   # צמוד אליו: דחיפה
				state = SHOVE
				_st = SHOVE_WIND
				_hit = false
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				Sfx.play("groan", z.global_position, 2.0, 0.1, 2, 0.7)
				return _move(delta, 0.0)
			return false
		GO:
			if _car == null or not is_instance_valid(_car) or _car.moving() or _st <= 0.0:
				_reset(1.5)
				return false
			var dx: float = _tx - z.global_position.x
			if absf(dx) < 8.0:
				var dir := 1.0 if _tx < _car.global_position.x else -1.0
				z._dir = dir
				if has_pl and signf(pl.global_position.x - z.global_position.x) == dir and _car.push(dir, PUSH_V, PUSH_T):
					state = PUSH
					shoving = _car
					pushes += 1
					_st = PUSH_T + 1.0
					Sfx.play("groan", z.global_position, 4.0, 0.1, 2, 0.6)
				else:
					_reset(1.5)
					return false
				return _move(delta, 0.0)
			z._dir = signf(dx)
			return _move(delta, signf(dx) * float(z.chase_speed) * 1.25)
		PUSH:
			if shoving == null or not is_instance_valid(shoving) or not shoving.moving() or _st <= 0.0:
				shoving = null
				state = REST
				_st = 0.7
				_cd = CD
				return _move(delta, 0.0)
			var edge: float = shoving.global_position.x - 14.0 * z.sc if z._dir > 0.0 else shoving.global_position.x + float(shoving.size.x) + 14.0 * z.sc
			z.velocity.x = (edge - z.global_position.x) / maxf(delta, 0.001)
			z.velocity.x = clampf(z.velocity.x, -PUSH_V * 1.5, PUSH_V * 1.5)
			return _move(delta, z.velocity.x)
		SHOVE:
			if _st <= 0.0 and not _hit:
				_hit = true
				shoves += 1
				if has_pl:
					var d: Vector2 = pl.global_position - z.global_position
					if absf(d.x) < 64.0 * z.sc and absf(d.y) < 60.0 and signf(d.x) == z._dir:
						pl.hurt(1, Vector2(z._dir * SHOVE_KNOCK, -1.4))
						pl._push_t = maxf(float(pl._push_t), 0.45)
						Sfx.play("punch" if Sfx.has_sound("punch") else "land", pl.global_position, 3.0)
			if _st <= -0.3:
				_reset(CD * 0.5)
				return false
			return _move(delta, 0.0)
		REST:
			if _st <= 0.0:
				state = WALK
				return false
			return _move(delta, 0.0)
	return false


func _reset(cd: float) -> void:
	state = WALK
	_car = null
	shoving = null
	_cd = cd


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 900.0 * delta) if state != PUSH else vx
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# מכונית שעומדת בינו לבין השחקן (השחקן על הכביש, לא עליה)
func _find_car(pl: Node) -> Node:
	var zx: float = z.global_position.x
	var px: float = pl.global_position.x
	var best: Node = null
	var bd := INF
	for c in z.get_tree().get_nodes_in_group("cars"):
		if c.moving():
			continue
		var cx: float = c.global_position.x + float(c.size.x) * 0.5
		var top: float = c.global_position.y - float(c.size.y) * 0.82
		if pl.global_position.y < top + 10.0 or absf(pl.global_position.y - c.global_position.y) > 40.0:
			continue   # השחקן על המכונית / בקומה אחרת
		if absf(z.global_position.y - c.global_position.y) > 30.0:
			continue
		if signf(px - cx) != signf(cx - zx):
			continue   # המכונית לא באמצע
		var dz := absf(cx - zx)
		if dz > SEEK_R or absf(px - cx) > 560.0 or absf(px - cx) < float(c.size.x) * 0.5 + 10.0:
			continue
		if dz < bd:
			bd = dz
			best = c
	return best


# ============================================================
#  ציור: גוף רחב, כתפיים גדולות, כובע מצחייה, זקן, חולצה משובצת + אפוד ג'ינס
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var vest := col(Color("3a4a62"))
	var p: float = z._walk_phase
	var f: Array = feet(5.5, 2.5)
	var lean := 0.0
	if state == PUSH or (state == GO and absf(z.velocity.x) > 20.0):
		lean = 7.0 if state == PUSH else 3.0
	elif state == SHOVE:
		lean = -3.0 if _st > 0.0 else 6.0
	var hip := Vector2(0, -22)
	var sh := Vector2(2.0 + lean, -40.0 + absf(lean) * 0.2)
	var head := sh + Vector2(4.0 + lean * 0.2, -8.5)
	if state == PUSH:
		f = [Vector2(4.0 + sin(p * 1.4) * 3.0, 0), Vector2(-9.0 + sin(p * 1.4 + PI) * 3.0, 0)]
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית
	var hb: Vector2
	var hf: Vector2
	if state == PUSH:
		hb = sh + Vector2(13, 4)
		hf = sh + Vector2(14, 8)
	elif state == SHOVE:
		hb = sh + (Vector2(-8, 10) if _st > 0.0 else Vector2(18, 2))
		hf = sh + (Vector2(-6, 13) if _st > 0.0 else Vector2(19, 5))
	else:
		hb = sh + Vector2(-5.0 - sin(p) * 3.0, 16.0)
		hf = sh + Vector2(9.0 + sin(p) * 3.0, 15.0)
	z._arm(sh + Vector2(-4, 1), hb, Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	# גוף: בטן גדולה, חולצה משובצת, אפוד
	var torso := PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(8, 0), sh + Vector2(10, 10), hip + Vector2(8, 2), hip + Vector2(-7, 2), sh + Vector2(-10, 10)])
	Art.fill_shaded(z, torso, shirt, 0.12, 0.4)
	for q in 3:   # משבצות
		var yy := sh.y + 5.0 + float(q) * 6.0
		z.draw_line(Vector2(sh.x - 8.0, yy), Vector2(sh.x + 9.0, yy), col(Color(0.1, 0.05, 0.05, 0.45)), 1.2)
	for q in 3:
		var xx := sh.x - 5.0 + float(q) * 6.0
		z.draw_line(Vector2(xx, sh.y + 1.0), Vector2(xx - 1.0, hip.y), col(Color(0.1, 0.05, 0.05, 0.35)), 1.0)
	Art.fill(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(-3, 0), hip + Vector2(-2, 2), hip + Vector2(-7, 2), sh + Vector2(-10, 10)]), vest, Art.OUTLINE, 0.9)
	Art.fill(z, PackedVector2Array([sh + Vector2(4, 0), sh + Vector2(8, 0), sh + Vector2(10, 10), hip + Vector2(8, 2), hip + Vector2(4, 2)]), vest, Art.OUTLINE, 0.9)
	z.draw_rect(Rect2(hip + Vector2(-7, -1), Vector2(15, 3)), col(Color("3a2a1a")))   # חגורה
	z.draw_rect(Rect2(hip + Vector2(-1, -1.5), Vector2(4, 4)), col(Color("c8a040")))  # אבזם
	# ראש: זקן + כובע מצחייה
	Art.oval_shaded(z, head, 6.0, 6.4, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-4, 1), head + Vector2(6, 1), head + Vector2(5, 7), head + Vector2(0, 9), head + Vector2(-4, 5)]), col(Color("4a3424")), Art.OUTLINE, 0.8)
	Art.fill(z, PackedVector2Array([head + Vector2(-6.5, -2), head + Vector2(-5, -7.5), head + Vector2(4, -8), head + Vector2(6.5, -3)]), col(Color("e8e0d0")), Art.OUTLINE, 0.9)
	z.draw_rect(Rect2(head + Vector2(-5, -6), Vector2(10, 3)), col(Color("2a5a8a")))   # פס על הכובע
	z.draw_line(head + Vector2(5, -2.5), head + Vector2(11, -1.5), col(Color("2a5a8a")), 2.2)   # מצחייה
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.0, Color(1.0, 0.45, 0.2))
	z._arm(sh + Vector2(5, 1), hf, sk, shirt)
	end_draw()
	return true
