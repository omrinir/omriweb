extends "res://enemies/zombie_type.gd"
# ============================================================
#  FOREMAN (משלב 43, "WAR FACTORY") - מנהל העבודה של מפעל האימפריה: קסדת מגן לבנה עם פס אדום, לוח כתיבה, משרוקית.
#  "THEY LEARNED TO PRODUCE": שומר מרחק (KEEP) ומנהל את המפעל:
#    "OFF THE LINE!" - כל LINE_CD, אם יש לו פחות מ-CREW_MAX עובדים חיים - חייל חדש יוצא מקצה המסוע הקרוב (או מאחוריו).
#    "PRESS NOW!" - אתה מתחת למכבש (Press) בטווח PRESS_R? מפעיל אותו מוקדם (אזהרה קצרה - Press.RUSH_WARN).
#  "THEY LEARN THE LINE": כל פעם שעברת מתחת למכבש בלי להיפגע - כל מנהלי העבודה מפעילים אותו מהר יותר (main meta "press_dodge").
#  הורגים אותו -> הייצור נעצר (העובדים שלו מבולבלים - "leaderless").
#  לשנות: KEEP, LINE_CD, CREW_MAX, PRESS_R, PRESS_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"fm_whistle": [["S", 3000, 3100, 0.0, 0.25, 0.02, 6.0, 0.2, 1.0, 0.09], ["S", 3000, 3100, 0.3, 0.25, 0.02, 6.0, 0.2, 1.0, 0.09]],
	"fm_bell": [["S", 880, 870, 0.0, 0.9, 0.0, 3.0, 0.3, 1.0, 0.01], ["S", 1320, 1310, 0.0, 0.7, 0.0, 4.0, 0.15, 1.0, 0.01]],
}

const KEEP := 300.0
const LINE_CD := 12.0
const CREW_MAX := 2
const PRESS_R := 700.0
const PRESS_CD := 3.0

var crew := []
var produced := 0            # לבדיקות
var rushes := 0
var _line := 4.0
var _pcd := 0.5
var _raise := 0.0


func stats() -> Dictionary:
	return {"name": "FOREMAN", "hp": 32, "walk": 40.0, "chase": 70.0, "damage": 1, "bite_delay": 0.9, "scale": 1.05, "width": 1.0,
		"duck": 0.3, "cover": 0.6, "skin": Color("7e8a74"), "shirt": Color("4a3a2a"), "pants": Color("2a2a30"), "shoe": Color("141210"), "points": 560}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "retreat_probability": 0.3}


func on_death() -> void:
	var n := 0
	for c in crew:
		if is_instance_valid(c) and not c.dead and c.type_mod != null and c.type_mod.has_method("on_order"):
			c.type_mod.on_order("leaderless", z)
			n += 1
	if n > 0:
		z._popup("PRODUCTION STOPPED", Color("e0e0e0"), 13, -90.0)


func _spawn_point() -> Vector2:
	var best := Vector2(z.global_position.x - z._dir * 60.0, z.global_position.y)
	var bd := 700.0
	for c in z.get_tree().get_nodes_in_group("conveyors"):
		for ex in [c.global_position.x + 10.0, c.global_position.x + c.w - 10.0]:
			var dd: float = absf(ex - z.global_position.x)
			if dd < bd and absf(c.global_position.y - z.global_position.y) < 40.0:
				bd = dd
				best = Vector2(ex, c.global_position.y)
	return best


func physics(pl: Node, delta: float) -> bool:
	_line -= delta
	_pcd -= delta
	_raise = maxf(_raise - delta, 0.0)
	if z.dead or pl == null or pl.dead:
		return false
	if z.goal_x < INF:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	var near := absf(d.x) < 1000.0 and absf(d.y) < 300.0
	if not near:
		return false
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	# עובדים חדשים מפס הייצור
	if _line <= 0.0:
		_line = LINE_CD
		crew = crew.filter(func(c): return is_instance_valid(c) and not c.dead)
		if crew.size() < CREW_MAX:
			var sp := _spawn_point()
			var c: Node = z.get_parent()._spawn_zombie(sp.x, sp.y, preload("res://enemies/zombie_registry.gd").CONSCRIPT)
			if c != null:
				crew.append(c)
				produced += 1
				c._alert_t = 6.0
				_raise = 0.8
				Sfx.play("fm_bell", sp, 0.0, 0.05, 2)
				z._popup("OFF THE LINE!", Color("ffd060"), 13, -85.0)
	# מכבש מוקדם
	if _pcd <= 0.0:
		_pcd = 0.25
		for pr in z.get_tree().get_nodes_in_group("presses"):
			if absf(pr.global_position.x - z.global_position.x) < PRESS_R and pr.under(pl):
				var main: Node = z.get_parent()
				var learned_k: int = int(main.get_meta("press_dodge")) if main.has_meta("press_dodge") else 0
				if pr.state == 0 and pr.rush():
					if learned_k >= 2:   # למד: פחות זמן אזהרה
						pr._t = maxf(pr.RUSH_WARN - 0.15, 0.3)
					rushes += 1
					_pcd = PRESS_CD
					_raise = 0.8
					Sfx.play("fm_whistle", z.global_position, 2.0, 0.05, 2)
					z._popup("PRESS NOW!", Color("ff6040"), 14, -85.0)
				break
	if absf(d.x) < KEEP and absf(d.y) < 90.0:   # שומר מרחק
		z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.4, 600.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	return false


# ============================================================
#  ציור: קסדת מגן לבנה עם פס אדום והסמל, סרבל חום עם כיסים, לוח כתיבה ביד, משרוקית; יד מורמת כשהוא נותן הוראה
# ============================================================
func draw() -> bool:
	begin_draw()
	var raised := _raise > 0.0
	var o: Dictionary = E.soldier(self, z, Vector2(8, 2), "none", Color("4a3a2a"), Vector2(-2, -20) if raised else Vector2(999, 0))
	var head: Vector2 = o.head
	var hf: Vector2 = o.hf
	var sh: Vector2 = o.sh
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-7, -2), head + Vector2(-5, -8), head + Vector2(0, -10), head + Vector2(6, -8), head + Vector2(9, -2)]), col(Color("e8e4dc")))   # קסדת מגן
	DrawBatch.line(z, head + Vector2(-7, -2), head + Vector2(10, -2), col(Color("c8c4bc")), 1.6)
	DrawBatch.rect(z, Rect2(head + Vector2(-5, -6), Vector2(11, 1.6)), col(E.RED))
	E.emblem(z, head + Vector2(1, -7.5), 1.4)
	DrawBatch.rect(z, Rect2(hf + Vector2(-2, -8), Vector2(7, 10)), col(Color("8a6a40")))   # לוח כתיבה
	DrawBatch.rect(z, Rect2(hf + Vector2(-1, -6), Vector2(5, 7)), col(Color("e8e4dc")))
	DrawBatch.line(z, sh + Vector2(2, 2), sh + Vector2(4, 8), col(Color("c8a040")), 0.8)   # שרוך משרוקית
	DrawBatch.rect(z, Rect2(sh + Vector2(3, 8), Vector2(3, 2)), col(Color("c8c8c8")))
	end_draw()
	return true
