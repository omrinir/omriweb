extends "res://enemies/zombie_type.gd"
# ============================================================
#  REVIVER (משלב 34 והלאה) - מרפא זומבי: כפוף, פונצ'ו ארוך, ורידים כחולים זוהרים, מקל עם גביש כחול בראשו.
#  "THEY LEARNED TO COME BACK": מחפש גופות של זומבים (קבוצה "corpses" - zombie.gd מוסיף בזמן המוות) בטווח SEEK_R,
#  הולך אליהן (ובורח ממך אם אתה מתקרב - FLEE_R), כורע ומתקשר REVIVE_T שניות (קרן כחולה) -> הזומבי קם מחדש,
#  מוקף חלקיקים כחולים (ReviveAura). זומבי שהוחזר לא חוזר פעם שנייה.
#  ירייה בו בזמן ההתקשרות = מפסיקה את הטקס (STUN). להרוג אותו ראשון!
#  לשנות: SEEK_R, FLEE_R, REVIVE_T, REVIVE_CD, NO_REVIVE.
# ============================================================

const SOUNDS := {
	"rv_chant": [["V", 160, 150, 0.0, 1.5, 0.3, 0.6, 0.5, 1.0, 0.05, 0, [400, 900, 6]], ["S", 520, 540, 0.0, 1.5, 0.3, 0.6, 0.1, 1.0, 0.03]],
	"rv_rise": [["S", 300, 1200, 0.0, 0.6, 0.02, 4.0, 0.25, 1.0, 0.05], ["N", 0, 0, 0.0, 0.5, 0.05, 5.0, 0.3, 0.5, 0, 0.4]],
}

const SEEK_R := 520.0
const FLEE_R := 210.0
const REVIVE_T := 1.6
const REVIVE_CD := 2.5

enum { WALK, SEEK, CHANNEL, STUN }
var state := WALK
var revives := 0             # לבדיקות
var interrupts := 0
var target: Node = null
var _st := 0.0
var _cd := 0.5
var _look := 0.0


# סוגים שלא קמים (צריכים הקשר מיוחד בשלב) - קמים כזומבי רגיל
static func _kind_for(k: int) -> int:
	var R := preload("res://enemies/zombie_registry.gd")
	if k in [5, 7, 10, 11, 12, 18, R.BALSERO, R.CLINGER, R.ENCASED, R.DROWNED, R.CINDER, R.STRANGER, R.MIRAGE_KING, R.BROODMOTHER]:
		return 0
	return k


func stats() -> Dictionary:
	return {"name": "REVIVER", "hp": 28, "walk": 40.0, "chase": 66.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.4, "skin": Color("8a8a7a"), "shirt": Color("4a3a5a"), "pants": Color("2a2430"), "shoe": Color("2a2026"), "points": 520}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.05, "retreat_probability": 0.4}


func can_bite() -> bool:
	return state == WALK


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == CHANNEL:   # הטקס נקטע
		interrupts += 1
		_release()
		state = STUN
		_st = 0.6
		_cd = REVIVE_CD
		z._popup("INTERRUPTED", Color("80c0ff"), 13, -80.0)
	return true


func _release() -> void:
	if target != null and is_instance_valid(target) and target.has_meta("reviver") and target.get_meta("reviver") == z:
		target.remove_meta("reviver")
	target = null


func _find(pl: Node) -> Node:
	var best: Node = null
	var bd := SEEK_R
	for c in z.get_tree().get_nodes_in_group("corpses"):
		if not is_instance_valid(c) or c.has_meta("revived") or c.is_queued_for_deletion():
			continue
		var by = c.get_meta("reviver") if c.has_meta("reviver") else null
		if by != null and by != z and is_instance_valid(by) and not by.dead:
			continue
		if float(c._dead_t) > float(c.corpse_time) - 1.5:   # כבר נעלמת
			continue
		var d: float = absf(c.global_position.x - z.global_position.x) + absf(c.global_position.y - z.global_position.y) * 2.0
		if pl != null and absf(c.global_position.x - pl.global_position.x) < 120.0:
			d += 400.0   # לא הולך לגופה שלידך
		if d < bd:
			bd = d
			best = c
	return best


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_look -= delta
	if z.dead:
		_release()
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if _cd <= 0.0 and _look <= 0.0:
				_look = 0.3
				var c := _find(pl if has_pl else null)
				if c != null:
					target = c
					c.set_meta("reviver", z)
					state = SEEK
			return false
		SEEK:
			if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
				_release()
				state = WALK
				return false
			target._dead_t = minf(float(target._dead_t), 1.0)   # הגופה לא נעלמת בזמן שהוא בדרך
			var dx: float = target.global_position.x - z.global_position.x
			if has_pl and absf(pl.global_position.x - z.global_position.x) < FLEE_R and signf(pl.global_position.x - z.global_position.x) == signf(dx):
				_release()   # אתה בדרך - בורח
				state = WALK
				_cd = 1.2
				return false
			if absf(dx) < 18.0 and z.is_on_floor():
				state = CHANNEL
				_st = REVIVE_T
				Sfx.play("rv_chant", z.global_position, 0.0, 0.05, 2)
				return _stay(delta)
			z._dir = signf(dx)
			z.velocity.x = move_toward(z.velocity.x, z._dir * float(z.walk_speed) * 1.7, 500.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			elif z.is_on_wall():
				z.velocity.y = -400.0
			z.move_and_slide()
			return true
		CHANNEL:
			if target == null or not is_instance_valid(target):
				_release()
				state = WALK
				return false
			target._dead_t = minf(float(target._dead_t), 1.0)
			if Engine.get_physics_frames() % 5 == 0 and Art.on_screen(z, z.global_position):
				Particles.burst(z.get_parent(), target.global_position + Vector2(randf_range(-14, 14), -8.0), "spark", Vector2.UP, 2)
			if _st <= 0.0:
				_revive()
				state = WALK
				_cd = REVIVE_CD
			return _stay(delta)
		STUN:
			if _st <= 0.0:
				state = WALK
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _revive() -> void:
	var c: Node = target
	_release()
	if c == null or not is_instance_valid(c):
		return
	var pos: Vector2 = c.global_position
	var k := _kind_for(int(c.kind))
	var main: Node = z.get_parent()
	var nz: Node = main._spawn_zombie(pos.x, pos.y, k)
	if nz == null:
		return
	nz.set_meta("revived", true)
	nz._alert_t = 8.0
	nz.velocity = Vector2(0, -160.0)
	nz.add_child(ReviveAura.new())
	revives += 1
	Sfx.play("rv_rise", pos, 2.0, 0.05, 2)
	Particles.burst(main, pos + Vector2(0, -20), "spark", Vector2.UP, 14)
	nz._popup("RISE!", Color("80c8ff"), 15, -80.0)
	if c.get("_rag") != null:
		c._rag.release()
	c.remove_from_group("corpses")
	c.queue_free()


func on_death() -> void:
	_release()


# ============================================================
#  הילה כחולה סביב זומבי שהוחזר לחיים: כדורי אור כחולים שמסתובבים ועולים + זוהר
# ============================================================
class ReviveAura extends Node2D:
	var _t := 0.0
	var _sp := 0.0

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_t += delta
		_sp -= delta
		var zz := get_parent()
		if zz == null or zz.dead:
			modulate.a = maxf(modulate.a - delta * 2.0, 0.0)
		if not Art.on_screen(self, global_position):
			return
		if Engine.get_process_frames() % 2 == 0:
			queue_redraw()
		if _sp <= 0.0 and zz != null and not zz.dead:
			_sp = 0.35
			Particles.burst(zz.get_parent(), global_position + Vector2(randf_range(-12, 12), randf_range(-50, -10)) * Vector2(1.0, float(zz.sc)), "spark", Vector2.UP, 1)

	func _draw() -> void:
		var zz := get_parent()
		var sc: float = float(zz.sc) if zz != null else 1.0
		var c := Vector2(0, -30.0 * sc)
		Art.glow(self, c, 30.0 * sc, Color(0.3, 0.6, 1.0, 0.18))
		for q in 7:
			var a := _t * 2.2 + float(q) * TAU / 7.0
			var rise := fposmod(_t * 0.6 + float(q) * 0.31, 1.0)
			var p := c + Vector2(cos(a) * 16.0 * sc, sin(a) * 6.0 * sc + (0.5 - rise) * 44.0 * sc)
			var al := sin(rise * PI)
			draw_circle(p, 2.6 * sc, Color(0.35, 0.65, 1.0, 0.35 * al))
			draw_circle(p, 1.3 * sc, Color(0.75, 0.9, 1.0, 0.9 * al))


# ============================================================
#  ציור: כפוף, פונצ'ו ארוך, ורידים כחולים, מקל עם גביש כחול. בזמן הטקס כורע וקרן כחולה יורדת לגופה
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var robe := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(3.5, 2.0)
	var kneel: bool = state == CHANNEL and not z.dead
	var hip := Vector2(0, -20 if not kneel else -12)
	var sh := Vector2(4, -33 if not kneel else -26)   # כפוף קדימה
	var head := sh + Vector2(5, -6)
	if kneel:
		f = [Vector2(8, 0), Vector2(-8, -1)]
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var hb := sh + Vector2(-4.0 - sin(p) * 2.0, 14.0)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(robe, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -2), sh + Vector2(7, -1), hip + Vector2(9, 10), hip + Vector2(-11, 10)]), robe, 0.12, 0.4)
	for q in 4:   # רקמה בפונצ'ו
		z.draw_line(sh + Vector2(-6.0 + float(q) * 4.0, 6), hip + Vector2(-7.0 + float(q) * 5.0, 8), col(Color(0.4, 0.6, 1.0, 0.45)), 1.0)
	Art.oval_shaded(z, head, 5.0, 5.6, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-6, 4), head + Vector2(-5, -5), head + Vector2(1, -8), head + Vector2(6, -5), head + Vector2(2, -3), head + Vector2(-1, 5)]), col(Art.shade(z.shirt, 0.2)), Art.OUTLINE, 0.9)   # ברדס
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.2, Color(0.5, 0.8, 1.0))
		z.draw_line(sh + Vector2(2, 2), sh + Vector2(6, 9), Color(0.4, 0.7, 1.0, 0.7), 1.0)   # ורידים כחולים
	# המקל עם הגביש
	var hf := sh + Vector2(11, 6) if not kneel else sh + Vector2(12, 0)
	var top := hf + Vector2(4, -26) if not kneel else hf + Vector2(10, -22)
	z.draw_line(hf + Vector2(-2, 16), top, col(Color("5a4030")), 2.2)
	z._arm(sh + Vector2(3, 1), hf, sk, robe)
	var glow := 0.6 + 0.4 * sin(z._time * (12.0 if kneel else 3.0))
	z.draw_colored_polygon(PackedVector2Array([top + Vector2(0, -7), top + Vector2(3.5, 0), top + Vector2(0, 4), top + Vector2(-3.5, 0)]), Color(0.5, 0.8, 1.0, 0.9))
	Art.glow(z, top, 10.0 + glow * 6.0, Color(0.4, 0.7, 1.0, 0.25 * glow))
	end_draw()
	if kneel and target != null and is_instance_valid(target):   # קרן כחולה לגופה (בקואורדינטות העולם)
		var from: Vector2 = Vector2(top.x * z._dir * z.wf * z.sc, top.y * z.sc)
		var to: Vector2 = target.global_position - z.global_position + Vector2(0, -6)
		z.draw_line(from, to, Color(0.4, 0.7, 1.0, 0.5 * glow), 3.0)
		z.draw_line(from, to, Color(0.85, 0.95, 1.0, 0.8 * glow), 1.0)
		Art.glow(z, to, 22.0, Color(0.4, 0.7, 1.0, 0.3 * glow))
	return true
