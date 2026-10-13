extends "res://enemies/zombie_type.gd"
# ============================================================
#  COMMISSAR (משלב 45, "THE RED PALACE") - הקומיסר של אימפריית המתים: מעיל עור שחור, כובע מצחייה עם פס אדום, אקדח.
#  "THEY LEARNED YOU KILL THE LEADERS FIRST":
#    אין קצין חי בטווח COMMAND_R? הוא לוקח פיקוד: "VOLLEY!" לרובאים (כמו OFFICER).
#    חיילים מבולבלים סביבו (הרגת קצין / הפלת דגל / שברת תוף) -> "NO RETREAT!": מחזיר אותם לקרב (פקודת "rally").
#    כל מנהיג שהרגת בשלב (empire_kit leaders_killed) -> הוא שומר מרחק גדול יותר (KEEP + KEEP_PER_LEADER) ומתחבא מאחורי משמר הקיסר.
#  לשנות: COMMAND_R, ORDER_CD, KEEP, KEEP_PER_LEADER, KEEP_MAX.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"cm_shout": {"drive": 1.6, "layers": [["V", 120, 95, 0.0, 0.5, 0.02, 4.0, 0.55, 1.0, 0.04, 0, [500, 1100, 4]]]},
}

const COMMAND_R := 600.0
const ORDER_CD := 4.5
const KEEP := 260.0
const KEEP_PER_LEADER := 90.0
const KEEP_MAX := 620.0
const PISTOL_CD := 2.8

var volleys := 0             # לבדיקות
var rallies := 0
var _cd := 1.5
var _pcd := 2.0
var _raise := 0.0


func stats() -> Dictionary:
	return {"name": "COMMISSAR", "hp": 36, "walk": 40.0, "chase": 66.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.0,
		"duck": 0.4, "cover": 0.6, "skin": Color("7e8a74"), "shirt": Color("161414"), "pants": Color("161414"), "shoe": Color("0a0a0a"), "points": 640}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "retreat_probability": 0.3}


func keep_dist() -> float:
	return minf(KEEP + KEEP_PER_LEADER * float(E.leaders_killed(z.get_parent())), KEEP_MAX)


func on_death() -> void:
	E.leader_down(z.get_parent())


func _officer_alive() -> bool:
	for o in z.get_tree().get_nodes_in_group("empire"):
		if o != z and not o.dead and o.type_mod != null and o.type_mod.get("charges") != null and o.global_position.distance_to(z.global_position) < COMMAND_R:
			return true
	return false


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_pcd -= delta
	_raise = maxf(_raise - delta, 0.0)
	if z.dead or pl == null or pl.dead or z.goal_x < INF:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	if absf(d.x) > 1000.0 or absf(d.y) > 300.0:
		return false
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	if _cd <= 0.0:
		var confused := 0
		for o in z.get_tree().get_nodes_in_group("empire"):
			if o != z and not o.dead and o.type_mod != null and o.type_mod.get("state") != null and o.type_mod.get("CONFUSED") != null \
					and o.type_mod.state == o.type_mod.CONFUSED and o.global_position.distance_to(z.global_position) < COMMAND_R:
				confused += 1
		if confused > 0:
			_cd = ORDER_CD
			rallies += 1
			_raise = 0.8
			Sfx.play("cm_shout", z.global_position, 2.0, 0.05, 2)
			z._popup("NO RETREAT!", Color("ff4030"), 15, -85.0)
			E.order(z, "rally", COMMAND_R)
		elif not _officer_alive() and E.clear_shot(z, z.global_position + Vector2(0, -60), pl.global_position + Vector2(0, -14)):
			_cd = ORDER_CD
			volleys += 1
			_raise = 0.8
			Sfx.play("of_whistle", z.global_position, 2.0, 0.05, 2)
			z._popup("VOLLEY!", Color("ffd040"), 15, -85.0)
			E.order(z, "volley", COMMAND_R)
	if _pcd <= 0.0 and absf(d.x) < 560.0 and E.clear_shot(z, z.global_position + Vector2(0, -36), pl.global_position + Vector2(0, -24)):
		_pcd = PISTOL_CD
		var from: Vector2 = z.global_position + Vector2(z._dir * 16.0, -36.0) * z.sc
		E.fire(z, from, pl.global_position + Vector2(randf_range(-12, 12), -26.0 + randf_range(-8, 8)), 580.0)
		Sfx.play("of_pistol", from, -4.0, 0.1, 3)
	# מתחבא מאחורי משמר הקיסר / שומר מרחק
	var keep := keep_dist()
	var best: Node = null
	var bd := 500.0
	for g in z.get_tree().get_nodes_in_group("praetorians"):
		if not g.dead and absf(g.global_position.y - z.global_position.y) < 40.0:
			var dd: float = absf(g.global_position.x - z.global_position.x)
			if dd < bd and signf(g.global_position.x - pl.global_position.x) == signf(z.global_position.x - pl.global_position.x):
				bd = dd
				best = g
	var tx: float
	if best != null and absf(best.global_position.x - pl.global_position.x) + 60.0 < keep + 200.0:
		tx = best.global_position.x - signf(d.x) * 60.0
		tx = pl.global_position.x - signf(d.x) * maxf(absf(tx - pl.global_position.x), keep)
	else:
		tx = pl.global_position.x - signf(d.x) * keep
	if absf(z.global_position.x - tx) > 30.0 and absf(d.x) < keep + 120.0:
		z.velocity.x = move_toward(z.velocity.x, signf(tx - z.global_position.x) * float(z.walk_speed) * 1.5, 600.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	return false


# ============================================================
#  ציור: מעיל עור שחור ארוך, כובע מצחייה גבוה עם פס אדום והסמל, אקדח; יד מורמת בפקודה
# ============================================================
func draw() -> bool:
	begin_draw()
	var raised := _raise > 0.0
	var o: Dictionary = E.soldier(self, z, Vector2(13, -2), "cap", Color("161414"), Vector2(-2, -20) if raised else Vector2(999, 0))
	var hf: Vector2 = o.hf
	var hip: Vector2 = o.hip
	var sh: Vector2 = o.sh
	z.draw_colored_polygon(PackedVector2Array([hip + Vector2(-8, 4), hip + Vector2(8, 4), hip + Vector2(10, 16), hip + Vector2(-10, 16)]), col(Color("161414")))
	z.draw_line(sh + Vector2(-6, 0), hip + Vector2(6, 2), col(Color("3a2a1a")), 1.6)   # רצועת כתף
	z.draw_rect(Rect2(hf + Vector2(0, -2), Vector2(8, 3)), col(Color("1a1a1a")))
	z.draw_rect(Rect2(sh + Vector2(-2, 3), Vector2(4, 3)), col(E.RED))   # סמל על החזה
	end_draw()
	return true
