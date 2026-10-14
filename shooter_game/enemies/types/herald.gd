extends "res://enemies/zombie_type.gd"
# ============================================================
#  HERALD (משלב 45, "THE RED PALACE") - כרוז הקיסר: טוניקה אדומה-זהב, כובע נוצה, חצוצרה ארוכה עם דגלון הסמל.
#  "THEY LEARNED YOUR FIREPOWER": שומר מרחק (KEEP) ותוקע:
#    "BY ORDER OF THE EMPEROR!" - אתה יורה הרבה (BURST_SHOTS יריות תוך BURST_T שניות) -> צו: כל חייל אימפריה בטווח DECREE_R
#       מקבל x0.6 נזק ל-DECREE_T שניות (zombie.gd meta "morale_t"). ככל שאתה יורה יותר - הצו ארוך יותר.
#    "RALLY!" - חיילים מבולבלים בטווח -> מחזיר אותם לקרב (פקודת "rally").
#  הורגים אותו קודם - והצו נגמר.
#  לשנות: KEEP, BURST_SHOTS, BURST_T, DECREE_R, DECREE_T, DECREE_CD, RALLY_CD.
# ============================================================

const E := preload("res://enemies/empire_kit.gd")

const SOUNDS := {
	"hr_fanfare": {"drive": 1.3, "layers": [["S", 392, 392, 0.0, 0.25, 0.02, 4.0, 0.3, 1.0, 0.0], ["S", 523, 523, 0.25, 0.25, 0.02, 4.0, 0.3, 1.0, 0.0], ["S", 659, 659, 0.5, 0.6, 0.02, 2.0, 0.3, 1.0, 0.01]]},
}

const KEEP := 380.0
const BURST_SHOTS := 6
const BURST_T := 2.0
const DECREE_R := 450.0
const DECREE_T := 5.0
const DECREE_CD := 8.0
const RALLY_CD := 6.0

var decrees := 0             # לבדיקות
var rallies := 0
var heard := 0
var _shots := []
var _dcd := 1.0
var _rcd := 1.0
var _blow := 0.0
var _decree_left := 0.0


func stats() -> Dictionary:
	return {"name": "HERALD", "hp": 30, "walk": 40.0, "chase": 64.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 1.0,
		"duck": 0.3, "cover": 0.6, "skin": Color("7e8a74"), "shirt": Color("8a1a1a"), "pants": Color("2a1a1a"), "shoe": Color("1a1010"), "points": 520}


func setup() -> void:
	z.add_to_group("empire")


func brain_overrides() -> Dictionary:
	return {"aggression": 0.05, "retreat_probability": 0.4}


func on_shot(_from: Vector2, _dir: Vector2) -> void:   # שומע כל ירייה שלך
	if z == null or z.dead:
		return
	var pl := player()
	if pl == null or pl.global_position.distance_to(z.global_position) > 1100.0:
		return
	heard += 1
	_shots.append(float(z._time))


func on_death() -> void:
	if _decree_left > 0.0:   # הצו נגמר
		for o in z.get_tree().get_nodes_in_group("empire"):
			if o.has_meta("morale_t"):
				o.remove_meta("morale_t")
		z._popup("THE DECREE IS BROKEN", Color("e0e0e0"), 13, -90.0)


func physics(pl: Node, delta: float) -> bool:
	_dcd -= delta
	_rcd -= delta
	_blow = maxf(_blow - delta, 0.0)
	_decree_left -= delta
	if z.dead or pl == null or pl.dead or z.goal_x < INF:
		return false
	var now: float = z._time
	while _shots.size() > 0 and now - float(_shots[0]) > BURST_T:
		_shots.pop_front()
	if _decree_left > 0.0 and Engine.get_physics_frames() % 15 == 0:   # מחזיק את הצו
		for o in z.get_tree().get_nodes_in_group("empire"):
			if not o.dead and not o.is_boss() and o.global_position.distance_to(z.global_position) < DECREE_R:
				o.set_meta("morale_t", float(o._time) + 0.4)
	var d: Vector2 = pl.global_position - z.global_position
	if absf(d.x) > 1100.0:
		return false
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	if _dcd <= 0.0 and _shots.size() >= BURST_SHOTS:
		_dcd = DECREE_CD
		decrees += 1
		_decree_left = DECREE_T + 1.0 * float(mini(decrees - 1, 3))   # יורה יותר -> צו ארוך יותר
		_blow = 1.0
		_shots.clear()
		Sfx.play("hr_fanfare", z.global_position, 2.0, 0.02, 2)
		z._popup("BY ORDER OF THE EMPEROR!", Color("ffd040"), 14, -95.0)
	elif _rcd <= 0.0:
		var confused := 0
		for o in z.get_tree().get_nodes_in_group("empire"):
			if o != z and not o.dead and o.type_mod != null and o.type_mod.get("CONFUSED") != null and o.type_mod.state == o.type_mod.CONFUSED \
					and o.global_position.distance_to(z.global_position) < DECREE_R:
				confused += 1
		_rcd = 0.3   # בדיקה הבאה (לא כל פריים - חוסך סריקה של כל האימפריה)
		if confused > 0:
			_rcd = RALLY_CD
			rallies += 1
			_blow = 0.8
			Sfx.play("hr_fanfare", z.global_position, 0.0, 0.05, 2)
			z._popup("RALLY!", Color("ffd040"), 14, -95.0)
			E.order(z, "rally", DECREE_R)
	if absf(d.x) < KEEP and absf(d.y) < 90.0:
		z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.4, 600.0 * delta)
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		return true
	return false


# ============================================================
#  ציור: טוניקה אדומה עם עיטור זהב, כובע עם נוצה, חצוצרה ארוכה עם דגלון (מורמת כשהוא תוקע). צו פעיל - הילה זהובה
# ============================================================
func draw() -> bool:
	begin_draw()
	var up := _blow > 0.0
	var o: Dictionary = E.soldier(self, z, Vector2(10, -12) if up else Vector2(8, 4), "none", Color("8a1a1a"))
	var head: Vector2 = o.head
	var hf: Vector2 = o.hf
	var sh: Vector2 = o.sh
	z.draw_line(sh + Vector2(-7, 2), sh + Vector2(7, 2), col(Color("c8a040")), 1.4)   # עיטור
	z.draw_colored_polygon(PackedVector2Array([head + Vector2(-6, -3), head + Vector2(-4, -8), head + Vector2(6, -8), head + Vector2(7, -3)]), col(Color("2a1a1a")))   # כובע
	z.draw_line(head + Vector2(-3, -8), head + Vector2(-9, -18), col(Color("f0f0f0")), 2.4)   # נוצה
	var tip := hf + (Vector2(20, -8) if up else Vector2(12, 10))
	z.draw_line(hf, tip, col(Color("d8b040")), 1.8)   # חצוצרה
	z.draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -3), tip + Vector2(5, -5), tip + Vector2(5, 5), tip + Vector2(0, 3)]), col(Color("d8b040")))
	var mid := hf.lerp(tip, 0.5)
	z.draw_rect(Rect2(mid + Vector2(-4, 1), Vector2(9, 8)), col(E.RED))   # דגלון
	E.emblem(z, mid + Vector2(0.5, 5), 2.2)
	end_draw()
	if _decree_left > 0.0 and not z.dead:
		z.draw_arc(Vector2(0, -30), DECREE_R * 0.15 + 6.0 * sin(float(Engine.get_physics_frames()) * 0.2), 0.0, TAU, 20, Color(1.0, 0.85, 0.3, 0.35), 2.0)
	return true
