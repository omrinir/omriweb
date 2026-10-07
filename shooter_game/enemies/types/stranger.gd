extends "res://enemies/zombie_type.gd"
# ============================================================
#  STRANGER - "החבר". הזומבי שמדבר איתך בסצנת הפתיחה של שלב 1 (ui/intro_cutscene.gd).
#  גבוה ורזה ("רוונאנט"): בשר פשוט-עור, גולגולת עם עיניים אדומות וחיוך שיניים, צלעות ומעיים חשופים,
#  סדי מתכת, תותח-יד עם צינורות אדומים, טפרי מתכת כפולים ביד השנייה, ציפורני מתכת ברגליים.
#  לא תוקף (הסצנה שולטת בו). שליטה מהסצנה: talking, tilt, smile (0-1), look_back (0-1), t (זמן אנימציה).
#  דמות חוזרת - אפשר להשתמש בו שוב בשלבים הבאים.
# ============================================================

var talking := false
var tilt := 0.0          # הטיית ראש (רדיאנים)
var smile := 0.0         # 0 = רציני, 1 = חיוך מצמרר
var look_back := 0.0     # 0 = מסתכל על השחקן, 1 = מסתכל מאחוריו
var t := 0.0

const METAL := Color("8a9098")
const METAL_D := Color("4a5058")
const METAL_L := Color("c8d0d8")
const EYE := Color(1.0, 0.18, 0.12)


func stats() -> Dictionary:
	return {"name": "???", "hp": 999, "walk": 0.0, "chase": 0.0, "damage": 0, "bite_delay": 9.0, "scale": 1.1, "width": 0.9,
		"duck": 0.0, "cover": 0.0, "skin": Color("c49a86"), "shirt": Color("8a3a32"), "pants": Color("6e2c28"), "shoe": Color("1a1612"),
		"points": 0, "ragdoll": false}


func can_bite() -> bool:
	return false


func can_groan() -> bool:
	return false


func physics(_pl: Node, delta: float) -> bool:   # עומד במקום (הסצנה מזיזה אותו)
	t += delta
	z.velocity = Vector2.ZERO
	return true


# ============================================================
#  ציור (בהשראת "רוונאנט"): גבוה ורזה, בשר פשוט-עור ורוד-אדום, שלד חשוף, צלעות ומעיים,
#  סד מתכת על החזה והאגן, תותח-יד עם צינורות אדומים, טפרי מתכת כפולים ביד השנייה,
#  סדים על הברכיים והשוקיים, ציפורני מתכת ברגליים. גולגולת עם עיניים אדומות זוהרות וחיוך שיניים.
# ============================================================
const BONE := Color("d8ccb0")
const MUSCLE := Color("8a3a32")
const FLESH := Color("c49a86")
const HOSE := Color("c0281e")


func draw() -> bool:
	begin_draw()
	var fl := col(FLESH)
	var fl_d := col(FLESH.darkened(0.3))
	var mu := col(MUSCLE)
	var br := sin(t * 1.8) * 0.7   # נשימה
	var hip := Vector2(0.0, -27.0)
	var sh := Vector2(1.0, -45.0 - br * 0.4)
	# רגל אחורית
	_leg(hip + Vector2(-2.5, 0.0), Vector2(-4.0, 0.0), fl_d, true)
	# יד אחורית: טפרי מתכת
	_claw_arm(sh + Vector2(-6.0, 2.0), sh + Vector2(-8.0, 22.0 + br * 0.3))
	# גו: צר וארוך, כלוב צלעות
	var torso := PackedVector2Array([sh + Vector2(-8.0, -1.0), sh + Vector2(8.0, -1.0), sh + Vector2(6.5, 9.0), hip + Vector2(4.0, -1.0),
		hip + Vector2(-4.5, -1.0), sh + Vector2(-7.0, 9.0)])
	Art.fill_shaded(z, torso, fl, 0.15, 0.45)
	var cav := PackedVector2Array([sh + Vector2(-5.0, 4.0), sh + Vector2(5.5, 4.0), sh + Vector2(4.5, 11.0), sh + Vector2(-4.5, 11.0)])
	z.draw_colored_polygon(cav, col(Color("3a1414")))   # חלל החזה
	for k in 4:   # צלעות
		var ry := sh.y + 4.5 + float(k) * 1.8
		z.draw_polyline(PackedVector2Array([Vector2(-5.5, ry + 0.8), Vector2(-1.0, ry - 0.6), Vector2(0.0, ry), Vector2(1.0, ry - 0.6), Vector2(6.0, ry + 0.8)]), col(BONE), 0.9)
	# מעיים חשופים בבטן
	for k in 3:
		var c := Vector2(-2.0 + float(k) * 2.2, sh.y + 14.5 + float(k % 2) * 1.6)
		z.draw_arc(c, 1.8, 0.0, TAU, 8, mu, 1.4)
	z.draw_line(sh + Vector2(-6.0, 12.5), sh + Vector2(6.0, 12.5), col(Color("5a1a16")), 0.8)
	# סד מתכת: עצם חזה + חגורת אגן
	Art.fill(z, PackedVector2Array([sh + Vector2(-1.6, 1.0), sh + Vector2(1.6, 1.0), sh + Vector2(1.2, 11.5), sh + Vector2(-1.2, 11.5)]), col(METAL), Art.OUTLINE, 0.8)
	z.draw_circle(sh + Vector2(0.0, 3.0), 0.7, col(METAL_D))
	z.draw_circle(sh + Vector2(0.0, 9.0), 0.7, col(METAL_D))
	Art.fill(z, PackedVector2Array([hip + Vector2(-5.0, -3.5), hip + Vector2(5.0, -3.5), hip + Vector2(4.0, 0.5), hip + Vector2(1.5, 3.5), hip + Vector2(-1.5, 3.5), hip + Vector2(-4.5, 0.5)]),
		col(METAL), Art.OUTLINE, 1.0)
	z.draw_line(hip + Vector2(-4.0, -2.4), hip + Vector2(4.0, -2.4), col(METAL_L), 0.8)
	# צינור אדום מהחזה לתותח
	z.draw_polyline(PackedVector2Array([sh + Vector2(3.0, 6.0), sh + Vector2(8.0, 9.0), sh + Vector2(10.0, 14.0)]), col(HOSE), 1.3)
	# רגל קדמית
	_leg(hip + Vector2(2.5, 0.0), Vector2(4.0, 0.0), fl, false)
	# ראש: גולגולת
	var head := sh + Vector2(3.0 - look_back * 1.5, -8.5)
	_skull(head, tilt - look_back * 0.25)
	# יד קדמית: תותח
	var gun_at := sh + Vector2(9.0, 17.0 + br * 0.3)
	if talking:   # מחווה קטנה כשהוא מדבר
		gun_at += Vector2(2.0, -3.0 + sin(t * 3.0))
	_cannon_arm(sh + Vector2(6.5, 1.0), gun_at)
	end_draw()
	return true


func _leg(h: Vector2, foot: Vector2, c: Color, back: bool) -> void:
	var knee := h.lerp(foot, 0.5) + Vector2(2.0, 0.0)
	Art.limb(z, PackedVector2Array([h, knee]), 3.6, c)
	Art.limb(z, PackedVector2Array([knee, foot + Vector2(0.0, -2.5)]), 3.0, c)
	z.draw_line(h.lerp(knee, 0.3), h.lerp(knee, 0.8), col(MUSCLE), 0.8)   # שריר חשוף
	# סד ברך + לוח שוק
	Art.disc(z, knee, 2.4, col(METAL_D if back else METAL), Art.OUTLINE, 0.8)
	var s0 := knee.lerp(foot, 0.3)
	Art.fill(z, PackedVector2Array([s0 + Vector2(1.4, 0.0), s0 + Vector2(2.4, 0.0), foot + Vector2(2.4, -4.0), foot + Vector2(1.2, -4.0)]), col(METAL_D if back else METAL), Art.OUTLINE, 0.7)
	# כף רגל עם ציפורני מתכת
	for k in 3:
		var tp := foot + Vector2(-1.0 + float(k) * 2.4, 0.0)
		z.draw_line(foot + Vector2(0.0, -1.6), tp + Vector2(2.0, 0.0), col(METAL_L if not back else METAL), 1.0)


func _claw_arm(s: Vector2, h: Vector2) -> void:
	var el := s.lerp(h, 0.5) + Vector2(-2.5, 0.0)
	Art.limb(z, PackedVector2Array([s, el]), 3.0, col(FLESH.darkened(0.3)))
	Art.limb(z, PackedVector2Array([el, h]), 2.6, col(FLESH.darkened(0.3)))
	Art.disc(z, el, 1.8, col(METAL_D), Art.OUTLINE, 0.6)   # מפרק מתכת
	Art.disc(z, h, 2.2, col(METAL), Art.OUTLINE, 0.8)
	for k in 2:   # שני טפרים ארוכים מעוקלים
		var a := 1.2 + float(k) * 0.55
		var p1 := h + Vector2.from_angle(a) * 4.0
		var p2 := p1 + Vector2.from_angle(a + 0.9) * 4.0
		var p3 := p2 + Vector2.from_angle(a + 1.9) * 3.0
		z.draw_polyline(PackedVector2Array([h, p1, p2, p3]), Art.OUTLINE, 2.2)
		z.draw_polyline(PackedVector2Array([h, p1, p2, p3]), col(METAL_L), 1.2)


func _cannon_arm(s: Vector2, h: Vector2) -> void:
	var el := s.lerp(h, 0.45) + Vector2(1.5, -1.0)
	Art.limb(z, PackedVector2Array([s, el]), 3.4, col(FLESH))
	z.draw_line(s + Vector2(0.5, 1.0), el, col(MUSCLE), 0.9)
	Art.disc(z, s, 2.6, col(METAL_D), Art.OUTLINE, 0.8)   # כתפייה
	# התותח: גוף מתכת מלבני לאורך האמה, קנה, צינורות אדומים, קצה זוהר
	var d := (h - el).normalized()
	var n := d.orthogonal()
	var a0 := el - d * 1.0
	var a1 := h + d * 5.0
	var body := PackedVector2Array([a0 + n * 3.4, a1 + n * 3.0, a1 - n * 3.0, a0 - n * 3.4])
	Art.fill_shaded(z, body, col(METAL), 0.2, 0.45, Art.OUTLINE, 1.1)
	z.draw_line(a0 + n * 1.8, a1 + n * 1.6, col(METAL_L), 0.8)
	for k in 2:   # לוחות
		var m := a0.lerp(a1, 0.35 + 0.3 * float(k))
		z.draw_line(m + n * 3.2, m - n * 3.2, Art.OUTLINE, 0.8)
	var tip := a1 + d * 2.5
	Art.limb(z, PackedVector2Array([a1, tip]), 2.0, col(METAL_D))
	Art.glow(z, tip, 4.0, Color(HOSE, 0.7))
	z.draw_circle(tip, 1.2, Color(1.0, 0.35, 0.2))
	z.draw_polyline(PackedVector2Array([el + n * 2.0, a0.lerp(a1, 0.5) + n * 4.4, a1 + n * 3.4]), col(HOSE), 1.2)   # צינורות
	z.draw_polyline(PackedVector2Array([el - n * 2.0, a0.lerp(a1, 0.6) - n * 4.2, a1 - n * 3.2]), col(HOSE), 1.0)


func _skull(c: Vector2, ang: float) -> void:
	var xf := Transform2D(ang, c)
	var p := func(v: Vector2) -> Vector2: return xf * v
	# צוואר: חוליות + כבלים + צווארון מתכת
	Art.limb(z, PackedVector2Array([c + Vector2(-1.5, 8.0), c + Vector2(0.0, 2.5)]), 2.4, col(BONE.darkened(0.2)))
	z.draw_line(c + Vector2(-3.5, 9.0), c + Vector2(-2.5, 2.0), col(Color("2a2e34")), 0.9)
	z.draw_line(c + Vector2(1.5, 9.0), c + Vector2(2.0, 3.0), col(HOSE), 0.9)
	Art.fill(z, PackedVector2Array([c + Vector2(-5.0, 7.5), c + Vector2(4.0, 7.5), c + Vector2(3.0, 10.0), c + Vector2(-4.0, 10.0)]), col(METAL_D), Art.OUTLINE, 0.8)
	# גולגולת
	var skull := PackedVector2Array([p.call(Vector2(-6.0, -2.5)), p.call(Vector2(-3.5, -7.5)), p.call(Vector2(2.0, -8.0)), p.call(Vector2(6.0, -4.5)),
		p.call(Vector2(7.0, -0.5)), p.call(Vector2(6.0, 2.0)), p.call(Vector2(3.0, 3.0)), p.call(Vector2(-2.0, 2.5)), p.call(Vector2(-5.5, 1.0))])
	Art.fill_shaded(z, skull, col(BONE), 0.0, 0.4)
	z.draw_polyline(PackedVector2Array([p.call(Vector2(-3.0, -7.0)), p.call(Vector2(-4.5, -3.0))]), col(BONE.darkened(0.35)), 0.8)   # סדק
	z.draw_circle(p.call(Vector2(-4.5, -1.5)), 1.0, col(METAL_D))   # בורג בעורף
	# ארובת עין + עין אדומה זוהרת
	var sock: Vector2 = p.call(Vector2(3.6 - look_back * 2.0, -3.2))
	z.draw_colored_polygon(Art.ellipse(sock, 2.3, 1.9, ang, 10), Color(0.08, 0.02, 0.02))
	var pulse := 0.75 + 0.25 * sin(t * 4.0) + 0.3 * smile
	Art.glow(z, sock, 5.5, Color(1.0, 0.1, 0.05, 0.55 * pulse))
	z.draw_circle(sock, 1.0, Color(1.0, 0.3, 0.2))
	z.draw_circle(sock + Vector2(0.25, -0.25), 0.35, Color(1, 1, 1, 0.9))
	z.draw_colored_polygon(Art.ellipse(p.call(Vector2(6.3, -0.8)), 0.8, 0.6, ang, 6), Color(0.1, 0.03, 0.03))   # חור האף
	# לסת: שיניים חשופות (בלי שפתיים). מדבר = נפתחת, חיוך = רחב יותר
	var jaw := (absf(sin(t * 14.0)) * 1.6 if talking else 0.0) + smile * 0.4
	var j0: Vector2 = p.call(Vector2(0.5, 2.6))
	var j1: Vector2 = p.call(Vector2(6.0 + smile * 0.6, 1.6 - smile * 0.8))
	var low := PackedVector2Array([j0, j1, p.call(Vector2(5.5, 4.2 + jaw)), p.call(Vector2(0.5, 5.0 + jaw))])
	z.draw_colored_polygon(PackedVector2Array([j0, j1, p.call(Vector2(5.5, 1.8 + jaw)), p.call(Vector2(0.5, 2.8 + jaw))]), Color(0.12, 0.02, 0.02))
	Art.fill(z, low, col(BONE.darkened(0.12)), Art.OUTLINE, 0.8)
	for k in 6:   # שיניים קטנות עליונות + תחתונות
		var tp: Vector2 = j0.lerp(j1, 0.12 + 0.15 * float(k))
		z.draw_line(tp, tp + Vector2(0.0, 0.55), Color(0.95, 0.92, 0.8), 0.45)
		z.draw_line(tp + Vector2(0.0, 1.0 + jaw), tp + Vector2(0.0, 0.5 + jaw), Color(0.9, 0.87, 0.75), 0.4)
