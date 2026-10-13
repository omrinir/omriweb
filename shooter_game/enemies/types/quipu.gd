extends "res://enemies/zombie_type.gd"
# ============================================================
#  QUIPU (שלב 36, "THE SUMMIT") - קיפוקמאיוק זומבי: שומר הרשומות של האינקה. גלימה, ובידו קיפו - חבל עם עשרות חוטים צבעוניים וקשרים.
#  "THEY LEARNED TO REMEMBER": סופר כל פגיעה של כל נשק שלך בזומבים בטווח OBSERVE_R (zombie.gd -> observe).
#    אחרי RECORD_N פגיעות מאותו נשק -> קושר קשר (TIE_T, ירייה בו קוטעת) -> כל הזומבים בטווח SHARE_R
#    "זוכרים" את הנשק: פגיעה ממנו = x0.4 (zombie.gd, meta "resist_weapon"), וקשר בצבע הנשק מעל הראש (KnotMark).
#    תחליף נשק - או תהרוג אותו: כשהוא מת כל הקשרים שלו נפרמים.
#    שומר מרחק (FLEE_R).
#  לשנות: OBSERVE_R, RECORD_N, TIE_T, SHARE_R, FLEE_R.
# ============================================================

const SOUNDS := {
	"qp_tie": [["S", 600, 900, 0.0, 0.3, 0.02, 6.0, 0.2, 1.0, 0.03], ["C", 0, 0, 0.3, 0.05, 0.0, 50.0, 0.4, 1.0, 0]],
	"qp_unravel": [["N", 0, 0, 0.0, 0.5, 0.0, 4.0, 0.3, 0.4, 0, 0.6], ["S", 900, 300, 0.0, 0.5, 0.0, 4.0, 0.2, 1.0, 0]],
}

const OBSERVE_R := 700.0
const RECORD_N := 10
const TIE_T := 1.0
const SHARE_R := 600.0
const FLEE_R := 230.0
const WDB := preload("res://weapons/weapon_db.gd")

var counts := {}
var recorded := -1           # הנשק האחרון שנרשם
var ties := 0                # לבדיקות
var interrupts := 0
var _tie := 0.0
var _pending := -1
var _marked := []


func stats() -> Dictionary:
	return {"name": "QUIPU", "hp": 26, "walk": 38.0, "chase": 62.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.5, "skin": Color("8a8274"), "shirt": Color("2a3a5a"), "pants": Color("2a2430"), "shoe": Color("4a3a2a"), "points": 520}


func setup() -> void:
	z.add_to_group("quipus")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.05, "retreat_probability": 0.5}


func can_bite() -> bool:
	return _tie <= 0.0


# zombie.gd: זומבי נפגע מנשק w במקום pos
func observe(w: int, pos: Vector2) -> void:
	if z == null or z.dead or pos.distance_to(z.global_position) > OBSERVE_R or w == recorded:
		return
	counts[w] = int(counts.get(w, 0)) + 1
	if int(counts[w]) >= RECORD_N and _tie <= 0.0:
		_pending = w
		_tie = TIE_T
		Sfx.play("qp_tie", z.global_position, -2.0, 0.05, 2)


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if _tie > 0.0:   # קשירת הקשר נקטעה
		interrupts += 1
		_tie = 0.0
		counts[_pending] = int(RECORD_N * 0.5)
		_pending = -1
		z._popup("KNOT CUT", Color("e0c080"), 12, -80.0)
	return true


func _tie_knot() -> void:
	var w := _pending
	_pending = -1
	if w < 0:
		return
	ties += 1
	recorded = w
	counts.clear()
	_clear_marks()
	var nm := str(WDB.val(w, "name", "WEAPON"))
	var c: Color = WDB.val(w, "color", Color(1, 0.8, 0.3))
	z._popup("IT RECORDED YOUR " + nm, Color("ffd070"), 15, -90.0)
	var pl := player()
	if pl != null and pl.has_method("_say"):
		pl._say("THEY REMEMBER MY " + nm + "...", Color("ffd070"))
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o.dead or o.is_boss() or o.global_position.distance_to(z.global_position) > SHARE_R:
			continue
		o.set_meta("resist_weapon", w)
		var mk := KnotMark.new()
		mk.col = c
		mk.name = "KnotMark"
		if o.has_node("KnotMark"):
			o.get_node("KnotMark").queue_free()
		o.add_child(mk)
		mk.position = Vector2(0, -78.0 * float(o.sc))
		_marked.append(o)


func _clear_marks() -> void:
	for o in _marked:
		if is_instance_valid(o):
			if o.has_meta("resist_weapon"):
				o.remove_meta("resist_weapon")
			if o.has_node("KnotMark"):
				o.get_node("KnotMark").queue_free()
	_marked.clear()


func on_death() -> void:
	if not _marked.is_empty():
		Sfx.play("qp_unravel", z.global_position, 0.0, 0.05, 2)
		z._popup("THE KNOTS UNRAVEL", Color("ffd070"), 13, -90.0)
	_clear_marks()
	z.remove_from_group("quipus")


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	if _tie > 0.0:
		_tie -= delta
		if _tie <= 0.0:
			_tie_knot()
		z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	if pl != null and not pl.dead:
		var d: Vector2 = pl.global_position - z.global_position
		if absf(d.x) < FLEE_R and absf(d.y) < 80.0:   # שומר מרחק
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.6, 600.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			elif z.is_on_wall():
				z.velocity.y = -380.0
			z.move_and_slide()
			return true
	return false


# קשר צבעוני מעל ראש של זומבי ש"זוכר" נשק
class KnotMark extends Node2D:
	var col := Color(1, 0.8, 0.3)
	var _t := 0.0

	func _ready() -> void:
		z_index = 3

	func _process(delta: float) -> void:
		_t += delta
		if Engine.get_process_frames() % 3 == 0:
			queue_redraw()

	func _draw() -> void:
		var b := sin(_t * 3.0) * 2.0
		draw_line(Vector2(-6, b - 4), Vector2(6, b + 4), col.darkened(0.2), 2.5)
		draw_line(Vector2(-6, b + 4), Vector2(6, b - 4), col.darkened(0.2), 2.5)
		draw_circle(Vector2(0, b), 3.5, col)
		draw_circle(Vector2(0, b), 1.5, col.lightened(0.5))
		draw_line(Vector2(0, b + 3), Vector2(1, b + 10), Color(col, 0.7), 1.5)


# ============================================================
#  ציור: גלימה כחולה עם שוליים מצוירים, כיסוי ראש מאריג, וקיפו - חבל עליון עם 9 חוטים צבעוניים וקשרים
#  (בזמן קשירה: הידיים למעלה, החוט החדש זוהר בצבע הנשק)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var robe := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 2.0, 15.0), Art.shade(sk, 0.25), Art.shade(robe, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(10, 14), hip + Vector2(-10, 14)]), robe, 0.15, 0.4)   # גלימה ארוכה
	z.draw_line(hip + Vector2(-10, 12), hip + Vector2(10, 12), col(Color("e0c060")), 2.0)
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -2), head + Vector2(-5, -7), head + Vector2(5, -7), head + Vector2(6, -2), head + Vector2(-6, 0)]), col(Color("c03a2a")))   # כיסוי ראש
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.2, Color(1.0, 0.85, 0.4))
	# הקיפו
	var hf := sh + Vector2(10, -12) if _tie > 0.0 else sh + Vector2(13, 2)
	z._arm(sh + Vector2(3, 1), hf, sk, robe)
	var top_a := hf + Vector2(-4, 0)
	var top_b := hf + Vector2(10, 2)
	z.draw_line(top_a, top_b, col(Color("c8b898")), 2.0)
	var cols := [Color("c03a2a"), Color("e0c040"), Color("2a8a4a"), Color("2a5a9a"), Color("e0e0d0"), Color("6a3a8a"), Color("c03a2a"), Color("1a1a1a"), Color("e08030")]
	for q in 9:
		var a := top_a.lerp(top_b, float(q) / 8.0)
		var sway := sin(z._time * 3.0 + float(q)) * 1.5
		var ln := 12.0 + float((q * 5) % 4) * 2.0
		var c: Color = cols[q]
		if q == 4 and _tie > 0.0 and _pending >= 0:   # החוט החדש - בצבע הנשק שנרשם
			c = WDB.val(_pending, "color", Color(1, 0.8, 0.3))
			Art.glow(z, a + Vector2(sway, ln * 0.6), 6.0, Color(c, 0.5))
		z.draw_line(a, a + Vector2(sway, ln), col(c), 1.2)
		for kk in 2:   # קשרים
			z.draw_circle(a + Vector2(sway * (0.4 + 0.3 * float(kk)), ln * (0.35 + 0.35 * float(kk))), 1.3, col(c.darkened(0.3)))
	end_draw()
	return true
