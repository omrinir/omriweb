extends "res://enemies/zombie_type.gd"
# ============================================================
#  SANDBLASTER (שלב 13, צפון-מזרח) - פועל ניקוי-בחול מת עם המכשיר שלו:
#    מכל לחץ על הגב (עם שעון לחץ), צינור, ורומח-ריסוס ביד. מסכת נשימה ומשקפי מגן, סרבל חום.
#  התקפה: מנוע הלחץ מתניע (REV - נשיפות אוויר + רעש, אזהרה) -> זרם חול (BLAST) לכיוון שבו היית,
#    שמסתובב לאט אחריך. מי שבתוך הזרם: נפגע (כל TICK) ונדחף אחורה.
#    הזרם נעצר בקירות / דיונות (אפשר להסתתר מאחורי דיונה!). טווח: STREAM_LEN.
#  נקודת תורפה: המכל על הגב. פגיעה מאחור = נזק כפול. 3 פגיעות במכל = המכל מתפוצץ בענן חול:
#    הוא מסונוור ומבולבל לרגע ואין לו יותר זרם (הופך לזומבי רגיל).
#  צלילים: "sb_rev" (מדחס), "sb_blast" (זרם), "sb_pop" (המכל מתפוצץ).
#  לשנות: STREAM_LEN, BLAST_T, REV_T, TICK, TURN.
# ============================================================

const SOUNDS := {
	"sb_rev": [["Q", 60, 140, 0.0, 0.6, 0.05, 0.0, 0.25, 0.3, 0.1], ["N", 0, 0, 0.0, 0.6, 0.05, 0.0, 0.3, 0.3, 0]],
	"sb_blast": [["N", 0, 0, 0.0, 1.6, 0.05, 0.6, 0.6, 0.55, 0], ["N", 0, 0, 0.0, 1.6, 0.05, 0.6, 0.3, 1.0, 0]],
	"sb_pop": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.9, 0.5, 0], ["S", 120, 40, 0.0, 0.4, 0.0, 7.0, 0.6, 1.0, 0]],
}

const STREAM_LEN := 300.0
const BLAST_T := 1.6
const REV_T := 0.65
const TICK := 0.7
const TURN := 0.7           # כמה מהר הזרם מסתובב אחריך (רדיאנים לשנייה)
const CD := Vector2(2.4, 3.4)
const TANK_HP := 3

enum { WALK, REV, BLAST, STUN }
var state := WALK
var blasts := 0             # לבדיקות
var hits := 0
var tank := TANK_HP
var _st := 0.0
var _cd := 1.5
var _tick := 0.0
var _aim := Vector2.RIGHT
var _len := STREAM_LEN
var _grains := []


func stats() -> Dictionary:
	return {"name": "SANDBLASTER", "hp": 38, "walk": 38.0, "chase": 72.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.0,
		"duck": 0.1, "cover": 0.3, "skin": Color("9a9488"), "shirt": Color("a07a48"), "pants": Color("6a5034"), "shoe": Color("2a2018"), "points": 380}


func brain_overrides() -> Dictionary:
	return {"keep_range": 220.0, "aggression": -0.2}


func can_bite() -> bool:
	return state == WALK


func _nozzle() -> Vector2:
	return z.global_position + Vector2(z._dir * 22.0 * z.wf * z.sc, -30.0 * z.sc)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_tick_grains(delta)
	if state == WALK:
		if tank > 0 and _cd <= 0.0 and pl != null and not pl.dead and z.is_on_floor():
			var d: Vector2 = pl.global_position - z.global_position
			var sees: bool = z.brain == null or z.brain.sees
			if sees and absf(d.x) < STREAM_LEN * 0.9 and absf(d.y) < 150.0:
				state = REV
				_st = REV_T
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				Sfx.play("sb_rev", z.global_position, 0.0, 0.1, 3)
				return _stay(delta)
		return false
	match state:
		REV:
			if randf() < delta * 14.0:   # נשיפות אוויר מהמכל
				Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 12.0, -40.0 * z.sc), "smoke", Vector2.UP, 1)
			if _st <= 0.0:
				state = BLAST
				_st = BLAST_T
				_tick = 0.1
				blasts += 1
				var tgt: Vector2 = pl.global_position + Vector2(0, -24) if pl != null else _nozzle() + Vector2(z._dir * 100.0, 0.0)
				_aim = (tgt - _nozzle()).normalized()
				Sfx.play("sb_blast", z.global_position, 0.0, 0.05, 2)
		BLAST:
			if pl != null and not pl.dead:   # מסתובב לאט אחריך
				var want: Vector2 = (pl.global_position + Vector2(0, -24) - _nozzle()).normalized()
				var a := _aim.angle()
				var b := want.angle()
				_aim = Vector2.from_angle(a + clampf(wrapf(b - a, -PI, PI), -TURN * delta, TURN * delta))
				if signf(_aim.x) != 0.0 and signf(_aim.x) != z._dir:
					_aim.x = absf(_aim.x) * z._dir
			_stream(pl, delta)
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
		STUN:
			if _st <= 0.0:
				state = WALK
	return _stay(delta)


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# הזרם: עד קיר/דיונה, פוגע ודוחף
func _stream(pl: Node, delta: float) -> void:
	var from := _nozzle()
	var to := from + _aim * STREAM_LEN
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, 1))
	_len = STREAM_LEN if hit.is_empty() else from.distance_to(hit.position)
	for i in 3:   # גרגרים לציור
		_grains.append([randf_range(0.0, 20.0), randf_range(-4.0, 4.0), randf_range(700.0, 900.0)])
	_tick -= delta
	if pl == null or pl.dead:
		return
	var r: Rect2 = pl.body_rect()
	var c := r.get_center()
	var rel: Vector2 = c - from
	var along := rel.dot(_aim)
	var side := absf(rel.cross(_aim))
	if along > 0.0 and along < _len and side < 10.0 + along * 0.08 + r.size.x * 0.5:
		pl.velocity.x += _aim.x * 900.0 * delta   # נדחף אחורה
		if _tick <= 0.0:
			_tick = TICK
			hits += 1
			pl.hurt(z.damage, Vector2(signf(_aim.x), 0.0))


func _tick_grains(delta: float) -> void:
	for g in _grains:
		g[0] += g[2] * delta
	_grains = _grains.filter(func(g: Array) -> bool: return g[0] < _len)


# נקודת תורפה: המכל על הגב
func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.0


func on_damage(_amount: int, _hit_pos: Vector2, dir: Vector2, _src: Dictionary) -> bool:
	if tank > 0 and dir.x * z._dir > 0.0:   # פגיעה מאחור = במכל
		tank -= 1
		z.hp -= 10   # נזק נוסף (כמו נזק כפול)
		Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 12.0, -40.0 * z.sc), "smoke", Vector2.UP, 4)
		if tank <= 0:
			_pop()
	return true


func _pop() -> void:
	state = STUN
	_st = 2.0
	Sfx.play("sb_pop", z.global_position, 2.0, 0.1, 2)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -40), "smoke", Vector2.UP, 18)
	z._popup("TANK BURST", Color("ffd34a"), 15, -90.0)
	z.stagger(2.0)


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.0)
	var hip := Vector2(0.0, -22.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(2.0, -38.0)
	var head := sh + Vector2(5.0, -7.0)
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	# המכל על הגב
	var tk := sh + Vector2(-12.0, 4.0)
	if tank > 0:
		Art.fill_shaded(z, PackedVector2Array([tk + Vector2(-6, -10), tk + Vector2(4, -10), tk + Vector2(5, 14), tk + Vector2(-7, 14)]), col(Color("7a3a2a")), 0.2, 0.35)
		Art.disc(z, tk + Vector2(-1, -12), 3.0, col(Color("5a5a5a")))
		Art.disc(z, tk + Vector2(-1, 0), 2.6, col(Color("e8e0c8")), Art.OUTLINE, 0.8)   # שעון לחץ
		z.draw_line(tk + Vector2(-1, 0), tk + Vector2(-1, 0) + Vector2.from_angle(-PI * 0.5 + (1.4 if state == BLAST else (0.6 if state == REV else -0.6))) * 2.2, Color("c02020"), 0.8)
		for i in tank:   # מד: כמה פגיעות המכל עוד יכול לספוג
			z.draw_rect(Rect2(tk.x - 6.0 + float(i) * 4.0, tk.y + 16.0, 3.0, 2.0), Color(1.0, 0.8, 0.2))
	else:
		Art.fill(z, PackedVector2Array([tk + Vector2(-6, 2), tk + Vector2(4, 0), tk + Vector2(5, 14), tk + Vector2(-7, 14)]), col(Color("3a2a20")), Art.OUTLINE, 1.0)   # מכל קרוע
	z._arm(sh + Vector2(-3, 2), sh + Vector2(12.0, 10.0), col(Art.shade(z.skin, 0.25)), Art.shade(suit, 0.3))
	var body := PackedVector2Array([sh + Vector2(-7, -2), sh + Vector2(6, -1), hip + Vector2(6, -1), hip + Vector2(4, 3), hip + Vector2(-5, 3), sh + Vector2(-8, 5)])
	Art.fill_shaded(z, body, suit, 0.15, 0.35)
	z.draw_line(sh + Vector2(-6, 0), hip + Vector2(-5, -2), col(Color("2a2018")), 2.0)   # רצועה
	# ראש: מסכת נשימה + משקפי מגן
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.1)
	Art.fill_shaded(z, PackedVector2Array([head + Vector2(-6, -3), head + Vector2(6, -4), head + Vector2(6, 0), head + Vector2(-6, 0)]), col(Color("6a5a40")), 0.2, 0.3)   # כובע בד
	Art.disc(z, head + Vector2(3.0, -1.0), 2.2, Color(0.75, 0.55, 0.25, 0.9) if not z.dead else Color("3a3a3a"), Art.OUTLINE, 0.8)
	Art.fill(z, PackedVector2Array([head + Vector2(1, 2), head + Vector2(7, 1.5), head + Vector2(7, 6), head + Vector2(1, 6)]), col(Color("3a3a3e")), Art.OUTLINE, 0.8)   # מסכה
	Art.disc(z, head + Vector2(6.5, 5.0), 2.0, col(Color("5a5a5e")))   # מסנן
	# הצינור והרומח
	var hand := sh + Vector2(12.0, 6.0)
	var noz := hand + Vector2(14.0, -2.0)
	if state == BLAST or state == REV:
		var la := Vector2(_aim.x * z._dir, _aim.y)
		noz = hand + la * 16.0
	var hose := PackedVector2Array([tk + Vector2(-1, 12), tk + Vector2(2, 20), hip + Vector2(6, 2), hand])
	z.draw_polyline(hose, Art.OUTLINE, 4.0)
	z.draw_polyline(hose, col(Color("2a2a2e")), 2.4)
	z.draw_line(hand, noz, Art.OUTLINE, 4.6, true)
	z.draw_line(hand, noz, col(Color("8a8e96")), 2.6, true)
	z._arm(sh + Vector2(2, 2), hand, sk, suit)
	if state == BLAST:   # הזרם
		var la := Vector2(_aim.x * z._dir, _aim.y)
		var nrm := Vector2(-la.y, la.x)
		var lenl: float = _len / z.sc
		z.draw_colored_polygon(PackedVector2Array([noz + nrm * 2.0, noz + la * lenl + nrm * (6.0 + lenl * 0.08), noz + la * lenl - nrm * (6.0 + lenl * 0.08), noz - nrm * 2.0]), Color(0.9, 0.78, 0.55, 0.45))
		for g in _grains:
			var gp: Vector2 = noz + la * (float(g[0]) / z.sc) + nrm * float(g[1]) * (1.0 + float(g[0]) * 0.01)
			z.draw_circle(gp, 1.3, Color(0.95, 0.85, 0.6, 0.9))
	elif state == REV and fmod(z._time, 0.15) < 0.07:
		Art.glow(z, noz, 5.0, Color(1.0, 0.9, 0.6, 0.6))
	end_draw()
	return true
