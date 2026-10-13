extends "res://enemies/stationary_boss.gd"
# ============================================================
#  THE DISH (הבוס של שלב 34, "OBSERVATORY") - בוס נייח: זומבי ענק שהתמזג עם צלחת רדיו-טלסקופ.
#  הצלחת על הגב כמו קונכייה, המקלט (גביש כחול זוהר מעל הראש) = נקודת התורפה (x2, בשאר הגוף x0.6).
#  התקפות (stationary_boss.gd):
#    burst - 3 כדורי אות ברצף (מקדים אותך יותר אחרי כל פספוס)
#    fan   - מניפה של FAN_N כדורים (קופצים / מתכופפים בין הכדורים)
#    lob   - "למד" שאתה מתחבא -> פצצות פלזמה בקשת מעל המחסה
#    pound - צמוד אליו: מכת קרקע
#  לשנות: BURST_CD, FAN_CD, LOB_CD, FAN_N, ORB_V.
# ============================================================

const SOUNDS := {
	"ds_charge": [["S", 200, 900, 0.0, 0.7, 0.05, 1.0, 0.25, 1.0, 0.02], ["N", 0, 0, 0.0, 0.7, 0.3, 1.0, 0.15, 0.4, 0, 0.4]],
	"ds_shot": [["S", 1400, 300, 0.0, 0.18, 0.0, 14.0, 0.35, 1.0, 0], ["N", 0, 0, 0.0, 0.08, 0.0, 30.0, 0.2, 0.6, 0, 0.5]],
	"ds_static": [["N", 0, 0, 0.0, 0.8, 0.05, 2.0, 0.4, 1.0, 0, 0.6], ["Q", 120, 125, 0.0, 0.8, 0.05, 2.0, 0.08, 0.4, 0]],
}

const BURST_CD := 2.4
const FAN_CD := 6.5
const LOB_CD := 3.2
const FAN_N := 7
const ORB_V := 380.0
const ORB_COL := Color(0.4, 0.85, 1.0)

var _burst_cd := 2.0
var _fan_cd := 5.0
var _lob_cd := 2.0
var _left := 0
var _rate := 0.0
var _seq := ""


func stats() -> Dictionary:
	return {"name": "THE DISH", "hp": 380, "walk": 0.0, "chase": 0.0, "damage": 2, "bite_delay": 1.0, "scale": 2.6, "width": 1.5,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9088"), "shirt": Color("d8dce4"), "pants": Color("3a3e4a"), "shoe": Color("2a2a30"),
		"points": 1800, "boss": true, "boss_name": "THE GREAT DISH - SHOOT THE RECEIVER"}


func eye() -> Vector2:
	return z.global_position + Vector2(z._dir * 16.0 * z.wf, -76.0) * z.sc


func weak_rect() -> Rect2:
	return Rect2(8, -84, 18, 16)


func think(pl: Node, delta: float) -> void:
	_burst_cd -= delta
	_fan_cd -= delta
	_lob_cd -= delta
	_rate -= delta
	if _seq != "":   # רצף יריות פעיל
		if _rate <= 0.0 and _left > 0:
			_left -= 1
			_rate = 0.18 if _seq == "burst" else 0.0
			if _seq == "burst":
				fire_shot(eye(), aim_point(pl, ORB_V), ORB_V, 1, "orb", ORB_COL, 7.0)
				Sfx.play("ds_shot", eye(), -2.0, 0.1, 3)
		if _left <= 0:
			_seq = ""
		return
	var dx: float = absf(pl.global_position.x - z.global_position.x)
	if dx > 1100.0:
		return
	if learned_lob and _lob_cd <= 0.0 and (not _vis or randf() < 0.4):
		wind("lob", 0.7)
		return
	if _fan_cd <= 0.0:
		wind("fan", 1.0)
		return
	if _burst_cd <= 0.0:   # (מאחורי מחסה: יורה במחסה עד שהוא "לומד")
		wind("burst", 0.6)


func wind(name: String, t: float) -> void:
	super.wind(name, t)
	if name != "pound":
		Sfx.play("ds_charge", eye(), 0.0, 0.05, 2)


func attack(name: String, pl: Node) -> void:
	match name:
		"pound":
			do_pound(pl)
		"burst":
			_burst_cd = BURST_CD
			_seq = "burst"
			_left = 3
			_rate = 0.0
		"fan":
			_fan_cd = FAN_CD
			Sfx.play("ds_static", eye(), 2.0, 0.05, 2)
			var base: float = (aim_point(pl, ORB_V) - eye()).angle()
			for q in FAN_N:
				var a: float = base + (float(q) - float(FAN_N - 1) * 0.5) * 0.11
				fire_shot(eye(), eye() + Vector2.from_angle(a) * 100.0, ORB_V * 0.85, 1, "orb", ORB_COL, 6.0)
		"lob":
			_lob_cd = LOB_CD
			for q in 3:
				var tx: float = pl.global_position.x + float(q - 1) * 70.0 + pl.velocity.x * 0.3 * lead
				fire_lob(eye(), Vector2(tx, pl.global_position.y), 1.1 + 0.12 * float(q), 1, "plasma", 70.0, Color(0.5, 0.8, 1.0), 9.0)


# ============================================================
#  ציור: גוף ענק בחלוק מעבדה קרוע, צלחת רדיו לבנה ענקית על הגב (עם תמוכות), זרוע המקלט מעל הראש
#  וגביש המקלט הכחול (נקודת התורפה) - זוהר חזק בזמן טעינה
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var k := wind_k()
	var hip := Vector2(0, -26)
	var sh := Vector2(2, -50)
	var head := sh + Vector2(6, -9)
	# הצלחת על הגב: קערה פרבולית שפונה קדימה-למעלה אל המקלט (המוקד)
	var dc := sh + Vector2(-14, -8)
	var rc := Vector2(17, -76)
	var ax := (dc - rc).normalized()        # מהפתח אחורה
	var pp := ax.orthogonal()
	var bowl := PackedVector2Array()
	for q in 21:
		var t := float(q) / 10.0 - 1.0
		bowl.append(dc + pp * 42.0 * t + ax * 15.0 * t * t)
	Art.fill_shaded(z, bowl, col(Color("c8ccd6")), 0.25, 0.4, Art.OUTLINE, 1.4)   # גב הצלחת
	z.draw_colored_polygon(Art.ellipse(dc + ax * 15.0, 42.0, 5.5, pp.angle(), 18), col(Color("eef2f8")))   # פנים הקערה
	for q in 5:   # לוחות
		var t := float(q) / 2.0 - 1.0
		z.draw_line(dc + ax * 15.0 + pp * 42.0 * t, dc + pp * 40.0 * t * 0.92 + ax * 14.0 * t * t, Color(0.45, 0.5, 0.6, 0.5), 1.0)
	z.draw_line(dc + ax * 15.0 + pp * 42.0, dc + ax * 15.0 - pp * 42.0, col(Color("8a8e9a")), 1.6)   # שפה
	z.draw_line(dc + ax * 4.0, dc + Vector2(-8, 34), col(Color("5a5e6a")), 3.5)   # תמוכה לגב
	z.draw_line(dc + ax * 4.0, dc + Vector2(4, 30), col(Color("5a5e6a")), 2.5)
	# כבלים תלויים מהצלחת
	for q in 3:
		var c0 := dc + pp * (14.0 - float(q) * 12.0) + ax * 6.0
		z.draw_polyline(PackedVector2Array([c0, c0 + Vector2(-3, 14), c0 + Vector2(1.0 + sin(z._time * 2.0 + float(q)) * 2.0, 26)]), Color("2a2a34"), 1.3)
	# רגליים עבות (נטועות בקרקע + כבלים)
	z._leg(hip + Vector2(-5, 0), Vector2(-9, 0), col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(5, 0), Vector2(8, 0), col(z.pants), sk, col(z.shoe))
	for q in 3:
		z.draw_line(Vector2(-14.0 + float(q) * 6.0, 0), hip + Vector2(-8.0 + float(q) * 4.0, 4), Color("2a2a34"), 1.6)
	z._arm(sh + Vector2(-5, 2), sh + Vector2(-10, 22), Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-11, -3), sh + Vector2(-4, -5), sh + Vector2(9, -2), sh + Vector2(12, 3), hip + Vector2(14, 6), hip + Vector2(10, 12), hip + Vector2(6, 8), hip + Vector2(1, 13), hip + Vector2(-4, 8), hip + Vector2(-9, 12), hip + Vector2(-14, 6)]), coat, 0.12, 0.4)   # חלוק מעבדה קרוע
	z.draw_line(sh + Vector2(-4, -4), sh + Vector2(2, 6), col(Color("9aa0aa")), 1.0)   # צווארון
	z.draw_rect(Rect2(sh + Vector2(4, 6), Vector2(5, 4)), col(Color("9aa0aa")))   # כיס
	for q in 3:   # כתמי דם / חלודה
		z.draw_circle(sh + Vector2(-6.0 + float(q) * 6.0, 14.0 + float(q % 2) * 6.0), 1.8, col(Color("5a2a24")))
	z.draw_line(sh + Vector2(2, 0), hip + Vector2(3, 3), col(Color("b0b4bc")), 1.2)
	Art.oval_shaded(z, head, 7.0, 7.5, sk, 0.0)
	if not z.dead:
		z.draw_circle(head + Vector2(4.0, -1.0), 1.6, Color(0.5, 0.85, 1.0))
		z.draw_line(head + Vector2(1, 4), head + Vector2(6, 4.5), col(Color("1a1a1a")), 1.4)
	# זרוע המקלט: מהצלחת מעל הראש קדימה
	for q in 3:   # שלוש זרועות המוקד מהשפה אל המקלט
		var e := dc + ax * 15.0 + pp * 38.0 * (float(q) - 1.0)
		z.draw_line(e, rc + Vector2(-4, 0), col(Color("8a8e9a")), 2.2)
	Art.fill(z, PackedVector2Array([rc + Vector2(-6, -5), rc + Vector2(4, -5), rc + Vector2(6, 5), rc + Vector2(-6, 5)]), col(Color("5a5e6a")), Art.OUTLINE, 1.0)
	if not z.dead:   # גביש המקלט (נקודת תורפה)
		var g := 0.6 + 0.4 * sin(z._time * 4.0) + k * 1.2
		Art.glow(z, rc + Vector2(5, 0), 10.0 + 8.0 * k, Color(0.4, 0.85, 1.0, 0.25 * g))
		z.draw_colored_polygon(PackedVector2Array([rc + Vector2(2, -6), rc + Vector2(9, 0), rc + Vector2(2, 6), rc + Vector2(-1, 0)]), Color(0.5, 0.9, 1.0).lightened(0.3 * k))
	var hf := sh + Vector2(16, 18) if winding != "lob" else sh + Vector2(14, -18)
	z._arm(sh + Vector2(5, 2), hf, sk, coat)
	end_draw()
	return true
