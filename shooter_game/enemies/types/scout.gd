extends "res://enemies/zombie_type.gd"
# ============================================================
#  SCOUT (שלב 5) - הזומבי הראשון ש"מדבר" עם האחרים.
#  צללית: קטן ורזה, ברדס/צעיף קרוע, עיניים צהובות זוהרות, ראש מוטה בסקרנות.
#  התנהגות: לא תוקף מיד. שומר מרחק (~320), צופה, מטה את הראש.
#    כל כמה שניות שהוא רואה אותך - "מדווח" (טבעת + צליל קליקים) וכל הזומבים
#    הקרובים יודעים איפה אתה. נפגע = בורח וזועק לעזרה.
#  התקפה: נשיכה חלשה רק כשהוא נלכד.
#  צליל: קליקים מהירים ("scout_click") + צווחה גבוהה כשהוא בורח ("scout_shriek").
# ============================================================

const SOUNDS := {
	"scout_click": [["C", 0, 0, 0.0, 0.3, 0.0, 6.0, 0.7, 1.0, 0], ["S", 2400, 2200, 0.0, 0.04, 0.0, 60.0, 0.15, 1.0, 0], ["S", 2600, 2400, 0.12, 0.04, 0.0, 60.0, 0.15, 1.0, 0]],
	"scout_shriek": {"drive": 2.2, "layers": [["V", 520, 760, 0.0, 0.5, 0.01, 4.0, 0.7, 1.0, 0.08, 0, [1100, 2500, 40]]]},
}

var _report_t := 2.0
var _flee_t := 0.0
var _tilt := 0.0
var _arm_up := 0.0


func stats() -> Dictionary:
	return {"name": "SCOUT", "hp": 14, "walk": 60.0, "chase": 125.0, "damage": 1, "bite_delay": 1.0, "scale": 0.82, "width": 0.8,
		"duck": 0.3, "cover": 0.5, "skin": Color("9aa070"), "shirt": Color("5a4a36"), "pants": Color("3a3428"), "shoe": Color("2a2218"), "points": 220}


func brain_overrides() -> Dictionary:
	return {"keep_range": 320.0, "aggression": -0.3, "communication": 1, "retreat_probability": 0.5}


func use_brain_movement() -> bool:
	return false   # תנועה משלו (תצפית)


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_report_t -= delta
	_flee_t -= delta
	_arm_up -= delta
	_tilt = sin(z._time * 1.7) * 0.25
	var dist := absf(d.x)
	z._dir = signf(d.x) if d.x != 0.0 else z._dir
	if _flee_t > 0.0:   # בורח
		z._dir = -signf(d.x)
		return speed * 1.3
	# מדווח על השחקן לחברים
	if _report_t <= 0.0 and z.brain != null and z.brain.sees:
		_report_t = randf_range(5.0, 7.0)
		_arm_up = 0.8
		var dr := director()
		if dr != null:
			_force_broadcast(dr, pl)
		Sfx.play("scout_click", z.global_position, 0.0)
	# שומר מרחק: מתקרב עד ~320, נסוג כשהשחקן מתקרב
	if dist > 360.0:
		return speed * 0.8
	if dist < 260.0:
		if dist < 70.0:   # נלכד: נלחם
			return speed * 0.6
		z._dir = -signf(d.x)
		return speed * 0.9
	z._dir = signf(d.x)
	return 0.0


# הסקאוט מדווח גם בשלבים שבהם אין "תקשורת" לשאר
func _force_broadcast(dr: Node, pl: Node) -> void:
	var radius := 520.0
	var n := 0
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.brain == null:
			continue
		var dd: float = o.global_position.distance_to(z.global_position)
		if dd < radius:
			o.brain.hear_call(pl.global_position, 0.3 + dd / 800.0)
			o._alert_t = maxf(o._alert_t, 5.0)
			n += 1
	dr.calls_made += 1
	dr._signal(z.global_position + Vector2(0, -60.0 * z.sc), "!", Color(1.0, 0.85, 0.3))


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if _flee_t <= 0.0:
		_flee_t = 3.0
		_report_t = 0.0   # בורח וזועק
		Sfx.play("scout_shriek", z.global_position, 2.0)
		var pl := player()
		var dr := director()
		if dr != null and pl != null:
			_force_broadcast(dr, pl)
	return true


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var cloth := col(z.shirt)
	var dark := col(Art.shade(z.shirt, 0.35))
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 3.0)
	var hip := Vector2(0.0, -20.0 + absf(sin(p)) * 1.2)
	var sh := Vector2(3.0, -34.0)
	var head := sh + Vector2(3.0, -8.0)
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	# גלימה/צעיף קרוע
	var cape := PackedVector2Array([sh + Vector2(-6, -2), sh + Vector2(5, -2), hip + Vector2(5, 4), hip + Vector2(2, 9), hip + Vector2(-2, 6), hip + Vector2(-6, 10), hip + Vector2(-8, 3)])
	Art.fill_shaded(z, cape, cloth, 0.15, 0.4)
	for i in 3:   # קרעים
		var tp: Vector2 = hip + Vector2(-6 + i * 4, 6 + (i % 2) * 3)
		z.draw_line(tp, tp + Vector2(sin(z._time * 4.0 + float(i)) * 1.5, 5), dark, 1.2)
	# יד מורמת כשהוא "מדווח" / יד שמצביעה
	var hand := sh + (Vector2(4, -18) if _arm_up > 0.0 else Vector2(13, 6))
	Art.limb(z, PackedVector2Array([sh + Vector2(2, 1), sh + Vector2(6, 4) if _arm_up <= 0.0 else sh + Vector2(6, -8), hand]), 3.4, sk)
	if _arm_up > 0.0:
		Art.glow(z, hand, 6.0, Color(1.0, 0.85, 0.3, 0.6 * _arm_up))
	# ברדס + עיניים צהובות + ראש מוטה
	Art.oval_shaded(z, head, 6.0, 6.5, sk, _tilt)
	var hood := PackedVector2Array([head + Vector2(-8, 4), head + Vector2(-7, -6), head + Vector2(0, -10), head + Vector2(7, -6), head + Vector2(5, -2), head + Vector2(-2, -4), head + Vector2(-3, 6)])
	Art.fill_shaded(z, hood, cloth, 0.2, 0.45)
	var eye := Color(1.0, 0.85, 0.2)
	for e in [Vector2(3.0, -1.0), Vector2(5.5, -0.5)]:
		Art.glow(z, head + e, 3.0, Color(eye, 0.7))
		z.draw_circle(head + e, 1.0, eye)
	end_draw()
	return true
