extends "res://enemies/zombie_type.gd"
# ============================================================
#  AZUFRERO (שלב 33, "SULFUR CRATER") - סבל גופרית: סל קש ענק מלא גושי גופרית צהובים על הגב (מתנשא מעל הראש),
#  מטפחת על הפה, רצועת מצח.
#  הסל = נקודת התורפה: יריות מעל הראש (או בגב, או אש / פיצוץ) פוגעות בסל (BASKET_HP) -> הגופרית נדלקת כחול!
#    TORCH  - בוער בלהבה כחולה ורץ אליך מהר (TORCH_V). מגיע אליך / נגמר הזמן (TORCH_T) -> BURST:
#             פיצוץ להבה כחולה (BURST_R): נזק לך ולכל הזומבים מסביב, ואש כחולה על הרצפה.
#  טקטיקה: להצית אותו כשהוא בתוך קבוצת זומבים (הוא שורף אותם), או להרוג אותו לפני שהסל נדלק.
#  לשנות: BASKET_HP, TORCH_T, TORCH_V, BURST_R.
# ============================================================

const SOUNDS := {
	"az_ignite": [["N", 0, 0, 0.0, 0.5, 0.02, 4.0, 0.7, 0.35, 0, 0.2], ["S", 300, 900, 0.0, 0.3, 0.02, 6.0, 0.15, 1.0, 0.1]],
	"az_burst": {"drive": 2.0, "layers": [["N", 0, 0, 0.0, 0.8, 0.0, 4.0, 1.0, 0.25, 0], ["S", 120, 40, 0.0, 0.5, 0.0, 6.0, 0.8, 1.0, 0]]},
}

const BASKET_HP := 12
const TORCH_T := 4.0
const TORCH_V := 230.0
const BURST_R := 95.0

enum { WALK, TORCH }
var state := WALK
var basket := BASKET_HP
var ignites := 0             # לבדיקות
var bursts := 0
var _st := 0.0
var _fl := 0.0


func stats() -> Dictionary:
	return {"name": "AZUFRERO", "hp": 34, "walk": 36.0, "chase": 74.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 1.05,
		"duck": 0.0, "cover": 0.1, "skin": Color("8a8a6a"), "shirt": Color("6a5a3a"), "pants": Color("3a3228"), "shoe": Color("2a2018"), "points": 460}


func can_bite() -> bool:
	return state == WALK


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if state == TORCH:
		return true
	var s := str(src.get("source", "bullet"))
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	var back: bool = dir.x * z._dir > 0.0 and ly < -20.0 and ly > -52.0
	if s in ["fire", "grenade", "explosion", "laser", "rocket"] or ly < -54.0 or back:
		basket -= hit_damage(amount, hit_pos, src)
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 3)
		if basket <= 0:
			_ignite.call_deferred()
		return ly > -54.0   # ירייה בסל עצמו לא פוגעת בו
	return true


func _ignite() -> void:
	if z == null or not is_instance_valid(z) or z.dead or state == TORCH:
		return
	state = TORCH
	ignites += 1
	_st = TORCH_T
	Sfx.play("az_ignite", z.global_position, 2.0, 0.1, 2)
	z._popup("BLUE FIRE!", Color("80c0ff"), 15, -96.0)
	z._alert_t = 99.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_fl -= delta
	if z.dead or state != TORCH:
		return false
	if _fl <= 0.0 and Art.on_screen(z, z.global_position):
		_fl = 0.08
		Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 6.0, -62.0) * z.sc, "spark", Vector2.UP, 2)
	var has_pl: bool = pl != null and not pl.dead
	if has_pl:
		var dx: float = pl.global_position.x - z.global_position.x
		z._dir = signf(dx) if absf(dx) > 4.0 else z._dir
		if absf(dx) < 34.0 and absf(pl.global_position.y - z.global_position.y) < 50.0:
			_burst()
			return true
	z.velocity.x = move_toward(z.velocity.x, z._dir * TORCH_V, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall():
		z.velocity.y = -420.0
	z.move_and_slide()
	if _st <= 0.0:
		_burst()
	return true


func _burst() -> void:
	if z.dead:
		return
	bursts += 1
	var c: Vector2 = z.global_position + Vector2(0, -30)
	Sfx.play("az_burst", c, 4.0, 0.05, 2)
	for q in 3:
		Particles.burst(z.get_parent(), c, "spark", Vector2.ZERO, 10)
	var fz = preload("res://environment/fire_zone.gd").new()
	fz.setup(90.0, 3.5)
	z.get_parent().add_child(fz)
	fz.global_position = z.global_position
	fz.modulate = Color(0.5, 0.8, 1.6)
	var pl := player()
	if pl != null and not pl.dead and pl.global_position.distance_to(c) < BURST_R:
		pl.hurt(2, Vector2(signf(pl.global_position.x - c.x) * 2.0, -1.2))
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o != z and not o.dead and o.global_position.distance_to(c) < BURST_R:
			o.take_damage(28, o.global_position + Vector2(0, -30), (o.global_position - c).normalized(), true, {"source": "fire", "fixed": 28})
	z.hp = 1
	z.take_damage(5, c, Vector2.UP, true, {"source": "fire", "fixed": 5})


func on_death() -> void:
	pass


# ============================================================
#  ציור: סל קש גבוה עם גושי גופרית (בוער כחול ב-TORCH), מטפחת על הפה, רצועת מצח שמחזיקה את הסל
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0 if state == TORCH else 4.0, 2.5)
	var lean := 5.0 if state == TORCH else 2.0
	var hip := Vector2(0, -22)
	var sh := Vector2(1.0 + lean, -36)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# הסל על הגב (מתנשא מעל הראש)
	var bb := sh + Vector2(-12, 14)
	var bt := sh + Vector2(-16, -30)
	var basket_pts := PackedVector2Array([bb + Vector2(-8, 0), bb + Vector2(8, 0), bt + Vector2(12, 0), bt + Vector2(-10, 0)])
	Art.fill_shaded(z, basket_pts, col(Color("a08848")), 0.15, 0.35, Art.OUTLINE, 1.2)
	for q in 4:   # קליעת קש
		var u := float(q + 1) / 5.0
		DrawBatch.line(z, bb.lerp(bt, u) + Vector2(-9.0 - u * 2.0, 0), bb.lerp(bt, u) + Vector2(9.0 + u * 3.0, 0), Color(0.4, 0.3, 0.1, 0.6), 1.2)
	var dmg := 1.0 - float(basket) / float(BASKET_HP)
	for q in 4:   # גושי גופרית בראש הסל
		var gc := bt + Vector2(-6.0 + float(q) * 5.0, -3.0 - float(q % 2) * 3.0)
		DrawBatch.colored_polygon(z, Art.ellipse(gc, 4.0, 3.0, 0.3, 8), col(Color("e8d040").darkened(dmg * 0.3)))
	if state == TORCH and not z.dead:   # להבה כחולה מהסל
		for q in 4:
			var fp := bt + Vector2(-8.0 + float(q) * 5.0, -4.0)
			var fh := 14.0 + sin(z._time * 16.0 + float(q)) * 5.0
			DrawBatch.colored_polygon(z, PackedVector2Array([fp + Vector2(-3.5, 0), fp + Vector2(0, -fh), fp + Vector2(3.5, 0)]), Color(0.35 + float(q % 2) * 0.3, 0.65, 1.0, 0.85))
		Art.glow(z, bt + Vector2(0, -6), 34.0, Color(0.35, 0.65, 1.0, 0.25))
	DrawBatch.line(z, bt + Vector2(8, 4), head + Vector2(-2, -4), col(Color("5a4024")), 1.6)   # רצועת מצח
	var hb := sh + Vector2(-2, 12)
	var hf := sh + Vector2(9.0 + sin(p) * 3.0, 12.0)
	if state == TORCH:
		hb = sh + Vector2(-8, -4)
		hf = sh + Vector2(12, -2)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, 2), hip + Vector2(-6, 2)]), shirt, 0.12, 0.4)
	Art.oval_shaded(z, head, 5.0, 5.6, sk, 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(0, 1), head + Vector2(6, 0), head + Vector2(6, 5), head + Vector2(1, 6)]), col(Color("c03a2a")))   # מטפחת על הפה
	DrawBatch.line(z, head + Vector2(-5, -3), head + Vector2(5, -4), col(Color("5a4024")), 1.6)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -1.0), 1.0, Color(0.6, 0.85, 1.0) if state == TORCH else Color(0.85, 0.9, 0.5))
	z._arm(sh + Vector2(3, 1), hf, sk, shirt)
	end_draw()
	return true
