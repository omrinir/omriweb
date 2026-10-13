extends "res://enemies/zombie_type.gd"
# ============================================================
#  WELDER (משלב 43, "WAR FACTORY") - רתך של אימפריית המתים: מסכת ריתוך, סרבל, מבער, בלוני גז על הגב.
#  "THEY LEARNED TO REPAIR": מחפש את חייל האימפריה הכי פגוע בטווח SEEK_R (כולל טנקטות והבוס PROTOTYPE) - ומרתך אותו:
#    HEAL חיים כל TICK עד שהוא שלם. "THEY LEARN YOUR TARGET": במי שאתה יורה הכי הרבה - אותו הוא מתקן קודם.
#    בזמן ריתוך המסכה למטה: יריות בראש נבלעות במסכה. ואם אתה מכוון אליו בזמן ריתוך (קרוב) - הבזק הקשת מסנוור אותך (ARC FLASH).
#    תפוס אותו כשהוא הולך (המסכה למעלה).
#  לשנות: SEEK_R, HEAL, TICK, FLASH_R, FLASH_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"wd_arc": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 0.25, 0.9, 0, 0.9], ["S", 3000, 2600, 0.0, 0.4, 0.0, 6.0, 0.05, 1.0, 0.3]],
	"wd_mask": [["C", 0, 0, 0.0, 0.03, 0.0, 60.0, 0.4, 1.0, 0], ["S", 700, 600, 0.0, 0.06, 0.0, 40.0, 0.2, 1.0, 0]],
}

const SEEK_R := 520.0
const HEAL := 4
const TICK := 0.5
const FLASH_R := 650.0
const FLASH_CD := 4.0
const REACH := 34.0

var welding := false
var healed := 0              # לבדיקות
var flashes := 0
var masked_hits := 0
var _patient: Node = null
var _scan := 0.3
var _tick := 0.0
var _fcd := 1.0
var _spark := 0.0


func stats() -> Dictionary:
	return {"name": "WELDER", "hp": 34, "walk": 42.0, "chase": 74.0, "damage": 1, "bite_delay": 0.9, "scale": 1.0, "width": 1.05,
		"duck": 0.2, "cover": 0.4, "skin": Color("7a8670"), "shirt": Color("3a4a5a"), "pants": Color("3a4a5a"), "shoe": Color("1a1816"), "points": 480}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.2}


func can_bite() -> bool:
	return not welding


func on_damage(_amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	var s := str(src.get("source", "bullet"))
	if welding and (s == "bullet" or s == "melee") and (hit_pos.y - z.global_position.y) / z.sc < -42.0:   # המסכה
		masked_hits += 1
		Sfx.play("wd_mask", hit_pos, -2.0, 0.1, 3)
		Particles.burst(z.get_parent(), hit_pos, "spark", -dir, 3)
		if masked_hits == 1:
			z._popup("WELDING MASK", Color("c0d0e0"), 12, -85.0)
		return false
	return true


func _damage(o: Node) -> float:   # כמה חסר לו (הבוס נספר במספר נקודות, לא באחוזים)
	return float(o.max_hp - o.hp) if o.is_boss() else (1.0 - float(o.hp) / float(maxi(o.max_hp, 1))) * 100.0


func _find() -> Node:
	var best: Node = null
	var bd := 8.0
	for o in z.get_tree().get_nodes_in_group("empire"):
		if o == z or o.dead or absf(o.global_position.y - z.global_position.y) > 60.0 or absf(o.global_position.x - z.global_position.x) > SEEK_R:
			continue
		var dm := _damage(o)
		if dm > bd:
			bd = dm
			best = o
	return best


func physics(pl: Node, delta: float) -> bool:
	_scan -= delta
	_tick -= delta
	_fcd -= delta
	_spark += delta
	if z.dead:
		return false
	if not is_instance_valid(_patient) or _patient.dead or _patient.hp >= _patient.max_hp:
		if welding:
			welding = false
			Sfx.play("wd_mask", z.global_position, -4.0, 0.1, 2)
		_patient = null
	if _patient == null:
		if z.goal_x < INF and not z.has_meta("welder_goal"):
			return false
		z.remove_meta("welder_goal")
		if _scan <= 0.0:
			_scan = 0.5
			_patient = _find()
		if _patient == null:
			z.goal_x = INF
			return false
	# הולך אל הפצוע ומרתך
	var side: float = signf(z.global_position.x - _patient.global_position.x + 0.01)
	var reach: float = REACH + (float(_patient.wf) * 19.0 if _patient.is_boss() else 0.0)
	var spot: float = _patient.global_position.x + side * reach
	if absf(z.global_position.x - spot) > 14.0:
		welding = false
		z.goal_x = spot
		z.set_meta("welder_goal", true)
		return false
	z.goal_x = INF
	z.remove_meta("welder_goal")
	if not welding:
		welding = true
		Sfx.play("wd_mask", z.global_position, -4.0, 0.1, 2)
	z._dir = -side
	if _tick <= 0.0:
		_tick = TICK
		var n: int = mini(HEAL, _patient.max_hp - _patient.hp)
		_patient.hp += n
		healed += n
		Sfx.play("wd_arc", z.global_position, -8.0, 0.2, 3)
		if _patient.is_boss() and healed % 20 < HEAL:
			_patient._popup("REPAIRING", Color("a0d0ff"), 13, -60.0 - 70.0 * _patient.sc)
	# הבזק קשת: אתה מכוון אליו מקרוב בזמן שהוא מרתך
	if pl != null and not pl.dead and _fcd <= 0.0 and pl.global_position.distance_to(z.global_position) < FLASH_R \
			and (z.global_position + Vector2(0, -30) - pl.global_position - Vector2(0, -36)).normalized().dot(pl._aim.normalized()) > 0.985:   # מכוון אליו
		_fcd = FLASH_CD
		flashes += 1
		pl.daze(0.7, "ARC FLASH - MY EYES!")
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: סרבל כחול, בלוני גז על הגב, מסכת ריתוך (למטה בריתוך, למעלה בהליכה), מבער עם להבה כחולה / קשת לבנה
# ============================================================
func draw() -> bool:
	begin_draw()
	var o: Dictionary = E.soldier(self, z, Vector2(14, 2) if welding else Vector2(9, 6), "none", Color("3a4a5a"))
	var head: Vector2 = o.head
	var sh: Vector2 = o.sh
	var hf: Vector2 = o.hf
	for q in 2:   # בלוני גז
		z.draw_rect(Rect2(sh + Vector2(-13.0 + float(q) * 4.0, -2), Vector2(4, 20)), col(Color("6a2a2a") if q == 0 else Color("3a5a3a")))
	if welding:   # מסכה למטה
		z.draw_colored_polygon(PackedVector2Array([head + Vector2(-5, -7), head + Vector2(7, -6), head + Vector2(8, 5), head + Vector2(-4, 6)]), col(Color("2a2a2a")))
		z.draw_rect(Rect2(head + Vector2(2, -2), Vector2(5, 2.5)), Color(0.3, 0.5, 0.3, 0.9))
	else:   # מסכה מורמת
		z.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -6), head + Vector2(6, -10), head + Vector2(8, -7), head + Vector2(-4, -3)]), col(Color("2a2a2a")))
	z.draw_line(hf, hf + Vector2(9, 3), col(Color("8a8a80")), 2.0)   # מבער
	if not z.dead:
		if welding and fposmod(_spark * 9.0, 1.0) < 0.6:
			Art.glow(z, hf + Vector2(11, 4), 10.0, Color(0.85, 0.95, 1.0, 0.9))
		else:
			Art.glow(z, hf + Vector2(10, 3), 3.0, Color(0.4, 0.6, 1.0, 0.8))
	end_draw()
	return true
