extends "res://enemies/zombie_type.gd"
# ============================================================
#  GUARDSMAN (משלב 41, "THE PARADE") - משמר הכבוד של אימפריית המתים: כובע שאקו גבוה אדום עם הסמל, רצועות לבנות מוצלבות,
#  רובה עם כידון ארוך.
#  "THEY LEARNED TO PROTECT EACH OTHER": נפצע מתחת לחצי? מחפש שומר בריא קרוב (SWAP_R) ומתחלף איתו -
#    הפצוע נסוג אחורה (goal_x) והבריא מסתער קדימה במקומו. "THEY LEARN TOGETHER": דקירת כידון (LUNGE) - הכנה (נצנוץ) ואז זינוק.
#    התחמקת בקפיצה / בהתכופפות? כל השומרים בשלב דוקרים מעכשיו גבוה / נמוך (main meta "guard_lunge").
#  לשנות: SWAP_R, SWAP_T, LUNGE_R, LUNGE_WIND, LUNGE_V, LUNGE_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"gd_lunge": [["N", 0, 0, 0.0, 0.18, 0.0, 14.0, 0.4, 0.8, 0, 0.6], ["S", 900, 400, 0.0, 0.12, 0.0, 20.0, 0.15, 1.0, 0]],
	"gd_stamp": [["S", 80, 50, 0.0, 0.15, 0.0, 20.0, 0.5, 1.0, 0], ["N", 0, 0, 0.0, 0.05, 0.0, 40.0, 0.2, 0.3, 0, 0.5]],
}

const SWAP_R := 260.0
const SWAP_T := 2.5
const LUNGE_R := 130.0
const LUNGE_WIND := 0.4
const LUNGE_V := 420.0
const LUNGE_T := 0.3
const LUNGE_CD := 2.2
# גובה הדקירה (מעל הרגליים) לפי מה שלמדו
const HEIGHTS := {"mid": Vector2(-40, -10), "high": Vector2(-90, -34), "low": Vector2(-26, 0)}

enum { MARCH, WIND, LUNGE }
var state := MARCH
var swaps := 0               # לבדיקות
var lunges := 0
var lunge_hits := 0
var swapped := false
var _st := 0.0
var _cd := 1.0
var _hit := false
var _back_t := 0.0


func stats() -> Dictionary:
	return {"name": "GUARDSMAN", "hp": 40, "walk": 34.0, "chase": 66.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 1.0,
		"duck": 0.0, "cover": 0.2, "skin": Color("7a8670"), "shirt": E.RED_D, "pants": Color("1e1e24"), "shoe": Color("101010"), "points": 520}


func setup() -> void:
	z.add_to_group("empire")
	z.add_to_group("guards")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.6}


func can_bite() -> bool:
	return state == MARCH


static func lunge_style(main: Node) -> String:
	return str(main.get_meta("guard_lunge")) if main.has_meta("guard_lunge") else "mid"


func on_order(kind: String, _from: Node) -> void:
	if z.dead:
		return
	match kind:
		"charge":
			z._alert_t = maxf(float(z._alert_t), 6.0)
			z._rush_t = 3.0
		"cover_me":   # שומר פצוע מבקש להתחלף - אני נכנס קדימה
			z._alert_t = maxf(float(z._alert_t), 6.0)
			z._rush_t = 2.5


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if not swapped and not z.dead:
		_check_swap.call_deferred()
	return true


func _check_swap() -> void:
	if swapped or z == null or not is_instance_valid(z) or z.dead or float(z.hp) > float(z.max_hp) * 0.5:
		return
	var pl := player()
	if pl == null:
		return
	var best: Node = null
	for o in z.get_tree().get_nodes_in_group("guards"):
		if o != z and not o.dead and o.type_mod != null and not o.type_mod.swapped and float(o.hp) > float(o.max_hp) * 0.6 \
				and o.global_position.distance_to(z.global_position) < SWAP_R:
			if best == null or float(o.hp) > float(best.hp):
				best = o
	if best == null:
		return
	swapped = true
	swaps += 1
	state = MARCH
	var away := -signf(pl.global_position.x - z.global_position.x + 0.01)
	z.goal_x = best.global_position.x + away * 90.0   # נסוג אל מאחורי החבר
	_back_t = SWAP_T
	best.type_mod.on_order("cover_me", z)
	Sfx.play("gd_stamp", z.global_position, 0.0, 0.1, 2)
	z._popup("GUARD - SWAP!", Color("ffd0a0"), 13, -90.0)


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if _back_t > 0.0:
		_back_t -= delta
		if _back_t <= 0.0:
			z.goal_x = INF
			z._alert_t = maxf(float(z._alert_t), 4.0)
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		WIND:
			if _st <= 0.0:
				state = LUNGE
				_st = LUNGE_T
				_hit = false
				lunges += 1
				Sfx.play("gd_lunge", z.global_position, 0.0, 0.1, 3)
			return _move(0.0, delta)
		LUNGE:
			var tip := _tip_rect()
			if not _hit and tip.intersects(pl.body_rect()):
				_hit = true
				lunge_hits += 1
				pl.hurt(1, Vector2(z._dir * 2.5, -1.0))
			if _st <= 0.0:
				state = MARCH
				_cd = LUNGE_CD
				if not _hit and absf(d.x) < LUNGE_R:   # התחמקת: לומדים איך
					_learn(pl)
				return _move(0.0, delta)
			return _move(z._dir * LUNGE_V, delta)
	if z.goal_x < INF:
		return false
	if _back_t <= 0.0 and _cd <= 0.0 and absf(d.x) < LUNGE_R and absf(d.y) < 80.0:
		state = WIND
		_st = LUNGE_WIND
		z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
		return _move(0.0, delta)
	return false


func _learn(pl: Node) -> void:
	var how := ""
	if not pl.is_on_floor():
		how = "high"
	elif pl._crouching:
		how = "low"
	var main: Node = z.get_parent()
	if how == "" or lunge_style(main) == how:
		return
	main.set_meta("guard_lunge", how)
	z._popup("THE GUARD LEARNED - " + ("THRUST HIGH" if how == "high" else "THRUST LOW"), Color("ff8060"), 13, -90.0)


# קצה הכידון (עולם): מלבן לפי הגובה שהשומרים למדו
func _tip_rect() -> Rect2:
	var hy: Vector2 = HEIGHTS[lunge_style(z.get_parent())]
	var x0: float = z.global_position.x + z._dir * 8.0 * z.sc
	var x1: float = z.global_position.x + z._dir * 46.0 * z.sc
	return Rect2(Vector2(minf(x0, x1), z.global_position.y + hy.x), Vector2(absf(x1 - x0), hy.y - hy.x))


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 2400.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: מעיל אדום כהה, רצועות לבנות מוצלבות, שאקו גבוה עם הסמל, רובה עם כידון (מכוון לפי הגובה הנלמד).
#  נצנוץ על הכידון בהכנה.
# ============================================================
func draw() -> bool:
	begin_draw()
	var style := lunge_style(z.get_parent())
	var aim := Vector2(1, 0)
	if style == "high":
		aim = Vector2(1, -0.55)
	elif style == "low":
		aim = Vector2(1, 0.45)
	var reach := 0.0
	if state == WIND:
		reach = -5.0
	elif state == LUNGE:
		reach = 8.0
	var hf_off := Vector2(10, -2) + aim * reach if state != MARCH else Vector2(9, 4)
	var o: Dictionary = E.soldier(self, z, hf_off, "none", E.RED_D)
	var head: Vector2 = o.head
	var sh: Vector2 = o.sh
	var hip: Vector2 = o.hip
	var hf: Vector2 = o.hf
	var white := col(Color("e8e4d8"))
	z.draw_line(sh + Vector2(-7, 0), hip + Vector2(6, 3), white, 1.6)   # רצועות מוצלבות
	z.draw_line(sh + Vector2(7, 0), hip + Vector2(-6, 3), white, 1.6)
	# שאקו
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-5.5, -3), head + Vector2(-5, -17), head + Vector2(6, -18), head + Vector2(6.5, -3)]), col(E.RED))
	z.draw_rect(Rect2(head + Vector2(-5.5, -18.5), Vector2(12, 2)), col(Color("141414")))
	z.draw_rect(Rect2(head + Vector2(-5.5, -4.5), Vector2(12, 1.6)), col(E.BRASS))
	z.draw_rect(Rect2(head + Vector2(2, -3), Vector2(7, 1.4)), col(Color("141414")))
	E.emblem(z, head + Vector2(0.5, -10), 2.6)
	z.draw_line(head + Vector2(-5, -18), head + Vector2(-4, -24), col(Color("f0f0f0")), 2.0)   # נוצה
	# רובה + כידון
	var rifle_aim := aim if state != MARCH else Vector2(0.3, -1)
	E.rifle(z, hf, rifle_aim)
	var dn := rifle_aim.normalized()
	z.draw_line(hf + dn * 17.0, hf + dn * 29.0, col(Color("c8ccd4")), 1.3)
	if state == WIND and not z.dead:
		var k := 1.0 - clampf(_st / LUNGE_WIND, 0.0, 1.0)
		Art.glow(z, hf + dn * 29.0, 3.0 + 5.0 * k, Color(1.0, 1.0, 0.9, 0.3 + 0.5 * k))
	if swapped and _back_t > 0.0 and not z.dead:
		z.draw_string(ThemeDB.fallback_font, head + Vector2(-3, -28), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.8, 0.7, 0.9))
	end_draw()
	return true
