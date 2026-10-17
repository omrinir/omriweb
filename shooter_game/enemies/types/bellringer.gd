extends "res://enemies/zombie_type.gd"
# ============================================================
#  BELLRINGER (שלב 30, "FROZEN VILLAGE") - שמש הכנסייה הזומבי: גלימה חומה עם ברדס, חבל ביד.
#  במגדל הפעמון (effects/s30_decor.gd BellTower): כל RING_CD כשאתה קרוב (RANGE) - מושך בחבל (PULL_T = אזהרה) ->
#    הפעמון מצלצל: הסופה מתחזקת ל-whiteout (WHITE_T) וכל הזומבים באזור (RUSH_R) מסתערים עליך.
#  על הקרקע (בלי מגדל): פעמון יד - אותו דבר, חלש יותר.
#  לירות בו מוקדם = שקט. בזמן whiteout - הזומבים רואים אותך, אתה כמעט לא.
#  לשנות: RING_CD, PULL_T, RANGE, RUSH_R, WHITE_T.
# ============================================================

const SOUNDS := {
	"s30_bell": [["S", 196, 196, 0.0, 2.2, 0.004, 1.2, 0.55, 1.0, 0.0], ["S", 466, 466, 0.0, 1.6, 0.004, 1.8, 0.25, 1.0, 0.0], ["S", 784, 784, 0.0, 0.9, 0.004, 3.0, 0.12, 1.0, 0.0], ["S", 196, 196, 0.7, 2.0, 0.004, 1.3, 0.45, 1.0, 0.0], ["S", 466, 466, 0.7, 1.4, 0.004, 2.0, 0.2, 1.0, 0.0]],
	"s30_handbell": [["S", 880, 880, 0.0, 0.5, 0.002, 6.0, 0.3, 1.0, 0.02], ["S", 1320, 1320, 0.0, 0.4, 0.002, 8.0, 0.15, 1.0, 0.02], ["S", 880, 880, 0.25, 0.5, 0.002, 6.0, 0.3, 1.0, 0.02]],
}

const RING_CD := 8.0
const PULL_T := 0.8
const RANGE := 900.0
const RUSH_R := 1000.0
const WHITE_T := 3.5

enum { WAIT, PULL }
var state := WAIT
var rings := 0               # לבדיקות
var _cd := 3.0
var _st := 0.0
var _tower: Node = null
var _anim := 0.0


func stats() -> Dictionary:
	return {"name": "BELLRINGER", "hp": 34, "walk": 40.0, "chase": 86.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.3, "skin": Color("a0a898"), "shirt": Color("5a4030"), "pants": Color("4a3428"), "shoe": Color("2a1e16"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.2, "keep_range": 380.0}


func setup() -> void:
	_find_tower.call_deferred()


func _find_tower() -> void:
	if z == null or not is_instance_valid(z):
		return
	for b in z.get_tree().get_nodes_in_group("bells"):
		if absf(b.global_position.x + float(b.w) * 0.5 - z.global_position.x) < 120.0 and z.global_position.y < b.global_position.y - 100.0:
			_tower = b


func can_bite() -> bool:
	return state == WAIT and _tower == null


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == PULL:   # ירייה בזמן המשיכה - עוצר
		state = WAIT
		_cd = RING_CD * 0.5
		z._popup("SILENCED", Color("c0d0ff"), 13, -70.0)
	return true


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_anim -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WAIT:
			if has_pl and _cd <= 0.0 and absf(pl.global_position.x - z.global_position.x) < RANGE * (1.0 if _tower != null else 0.75):
				state = PULL
				_st = PULL_T
				z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
				return _stay(delta)
			if _tower != null:   # במגדל: לא זז
				return _stay(delta)
			return false
		PULL:
			if _st <= 0.0:
				_ring(pl)
				state = WAIT
				_cd = RING_CD
				_anim = 1.0
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _ring(pl: Node) -> void:
	rings += 1
	var big := _tower != null and is_instance_valid(_tower)
	if big:
		_tower.ring()
	else:
		Sfx.play("s30_handbell", z.global_position, 4.0, 0.05, 2)
	var bl: Node = preload("res://effects/s30_decor.gd").blizzard()
	if bl != null:
		bl.whiteout(WHITE_T * (1.0 if big else 0.55))
	var rr := RUSH_R * (1.0 if big else 0.7)
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.is_boss():
			continue
		if absf(o.global_position.x - z.global_position.x) < rr:
			o._alert_t = maxf(float(o._alert_t), 6.0)
			o._rush_t = 3.0
			if o.dormant:
				o._wake()
	z._popup("DONG!", Color("ffe0a0"), 16, -80.0)
	if pl != null and pl.has_method("_say") and big:
		pl._say("THE BELL...", Color("e0e8ff"))


# ============================================================
#  ציור: גלימה עם ברדס, חבל עבה (במגדל - נמשך למעלה) או פעמון יד
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var robe := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var pulling: bool = state == PULL and not z.dead
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37) + (Vector2(0, 3) if pulling else Vector2.ZERO)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(9, 16), hip + Vector2(-9, 16)]), robe, 0.12, 0.4)   # גלימה ארוכה
	z.draw_line(hip + Vector2(-6, -2), hip + Vector2(6, -2), col(Color("c8b890")), 1.6)   # חבל חגורה
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	Art.fill(z, PackedVector2Array([head + Vector2(-7, 4), head + Vector2(-6, -5), head + Vector2(0, -8), head + Vector2(6, -6), head + Vector2(6, -2), head + Vector2(-1, -3), head + Vector2(-2, 5)]), robe, Art.OUTLINE, 1.0)   # ברדס
	if not z.dead:
		z.draw_circle(head + Vector2(3.5, -0.5), 0.9, Color(1.0, 0.5, 0.2))
	var hb: Vector2
	var hf: Vector2
	if _tower != null:   # חבל הפעמון
		var top_y := -140.0
		hb = sh + (Vector2(3, -6) if pulling else Vector2(2, -16))
		hf = sh + (Vector2(5, -2) if pulling else Vector2(4, -10))
		z.draw_line(Vector2(hf.x, top_y), hf + Vector2(0, 8), col(Color("a08a60")), 2.2)
	else:
		hb = sh + Vector2(-5.0 - sin(p) * 2.0, 14.0)
		var swing := sin(z._time * 20.0) * 0.6 if (pulling or _anim > 0.0) else 0.2
		hf = sh + Vector2(10, 6 if pulling else 12)
		var bp := hf + Vector2.from_angle(PI * 0.5 + swing) * 6.0
		z.draw_line(hf, bp, col(Color("5a4030")), 2.0)
		Art.fill(z, PackedVector2Array([bp + Vector2(-3, 0), bp + Vector2(3, 0), bp + Vector2(5, 7), bp + Vector2(-5, 7)]), col(Color("c8a040")), Art.OUTLINE, 0.9)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(robe, 0.3))
	z._arm(sh + Vector2(3, 1), hf, sk, robe)
	end_draw()
	return true
