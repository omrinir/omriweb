extends "res://enemies/zombie_type.gd"
# ============================================================
#  OFFICER (משלב 40, "HARBOR OF WAR") - קצין של אימפריית המתים: כובע מצחייה עם פס אדום, מעיל ארוך, אקדח, משרוקית.
#  "THEY LEARNED TO COMMAND": נשאר מאחורי היחידה (KEEP) ונותן פקודות לכל החיילים בטווח ORDER_R:
#    "VOLLEY!" - כשאתה בשטח פתוח ויש לפחות VOLLEY_MIN רובאים - כולם יורים יחד (שריקה = אזהרה).
#    "CHARGE!" - כשאתה טוען / נשאר בלי כדורים במחסנית - כולם מסתערים.
#    יורה באקדח מדי פעם. הורגים אותו -> "leaderless": החיילים מבולבלים כמה שניות. תהרוג קודם את הקצין!
#  לשנות: ORDER_R, ORDER_CD, VOLLEY_MIN, KEEP.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"of_whistle": [["S", 2600, 2700, 0.0, 0.35, 0.02, 6.0, 0.2, 1.0, 0.07]],
	"of_shout": {"drive": 1.4, "layers": [["V", 140, 110, 0.0, 0.45, 0.02, 4.0, 0.5, 1.0, 0.04, 0, [500, 1200, 4]]]},
	"of_pistol": [["N", 0, 0, 0.0, 0.08, 0.0, 40.0, 0.6, 0.6, 0, 0.5], ["S", 300, 120, 0.0, 0.07, 0.0, 40.0, 0.3, 1.0, 0]],
}

const ORDER_R := 560.0
const ORDER_CD := 4.5
const VOLLEY_MIN := 2
const KEEP := 320.0
const PISTOL_CD := 3.0

var volleys := 0             # לבדיקות
var charges := 0
var _cd := 2.0
var _pcd := 2.0
var _raise := 0.0


func stats() -> Dictionary:
	return {"name": "IMPERIAL OFFICER", "hp": 34, "walk": 38.0, "chase": 64.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.0,
		"duck": 0.4, "cover": 0.6, "skin": Color("7e8a74"), "shirt": E.UNIFORM_D, "pants": E.UNIFORM_D, "shoe": Color("141210"), "points": 600}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "retreat_probability": 0.3}


func _troops(pl: Node) -> int:
	var n := 0
	for o in z.get_tree().get_nodes_in_group("empire"):
		if o != z and not o.dead and o.type_mod != null and o.type_mod.get("volleys") != null and o.global_position.distance_to(z.global_position) < ORDER_R:
			n += 1
	return n


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_pcd -= delta
	_raise = maxf(_raise - delta, 0.0)
	if z.dead or pl == null or pl.dead:
		return false
	if z.goal_x < INF:   # פקודת תנועה (למשל לצאת מנתיב הטנקים בשלב 41) - קודם מצייתים
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if absf(d.x) < 900.0 and absf(d.y) < 300.0:
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		if _cd <= 0.0:
			if pl.is_reloading():   # טוען? הסתערות!
				_cd = ORDER_CD
				charges += 1
				_raise = 0.6
				Sfx.play("of_shout", z.global_position, 2.0, 0.05, 2)
				z._popup("CHARGE!", Color("ff5040"), 15, -85.0)
				E.order(z, "charge", ORDER_R)
			elif _troops(pl) >= VOLLEY_MIN and E.clear_shot(z, z.global_position + Vector2(0, -60), pl.global_position + Vector2(0, -14)):
				_cd = ORDER_CD
				volleys += 1
				_raise = 0.8
				Sfx.play("of_whistle", z.global_position, 2.0, 0.05, 2)
				z._popup("VOLLEY!", Color("ffd040"), 15, -85.0)
				E.order(z, "volley", ORDER_R)
		if _pcd <= 0.0 and absf(d.x) < 520.0 and E.clear_shot(z, z.global_position + Vector2(0, -36), pl.global_position + Vector2(0, -24)):
			_pcd = PISTOL_CD
			var from: Vector2 = z.global_position + Vector2(z._dir * 16.0, -36.0) * z.sc
			E.fire(z, from, pl.global_position + Vector2(randf_range(-14, 14), -26.0 + randf_range(-10, 10)), 560.0)
			Sfx.play("of_pistol", from, -4.0, 0.1, 3)
	if absf(d.x) < KEEP and absf(d.y) < 90.0:   # נשאר מאחור
		z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.4, 600.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	return false


func on_death() -> void:
	E.leader_down(z.get_parent())
	var n := E.order(z, "leaderless", ORDER_R)
	if n > 0:
		z._popup("THE OFFICER IS DOWN", Color("e0e0e0"), 13, -90.0)


# ============================================================
#  ציור: מעיל קצינים ארוך כהה עם כפתורי פליז, כובע מצחייה, אקדח; יד מורמת כשהוא נותן פקודה
# ============================================================
func draw() -> bool:
	begin_draw()
	var raised := _raise > 0.0
	var o: Dictionary = E.soldier(self, z, Vector2(13, -2), "cap", E.UNIFORM_D, Vector2(-2, -20) if raised else Vector2(999, 0))
	var hf: Vector2 = o.hf
	var hip: Vector2 = o.hip
	z.draw_colored_polygon(PackedVector2Array([hip + Vector2(-8, 4), hip + Vector2(8, 4), hip + Vector2(9, 12), hip + Vector2(-9, 12)]), col(E.UNIFORM_D))   # שולי המעיל
	z.draw_rect(Rect2(hf + Vector2(0, -2), Vector2(8, 3)), col(Color("1a1a1a")))   # אקדח
	z.draw_rect(Rect2(hf + Vector2(0, 0), Vector2(3, 4)), col(Color("1a1a1a")))
	var sh: Vector2 = o.sh
	z.draw_line(sh + Vector2(-7, -1), sh + Vector2(-3, -1), col(E.BRASS), 2.0)   # כותפת
	end_draw()
	return true
