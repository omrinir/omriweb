extends RefCounted
# ============================================================
#  כלי ציור משותפים: צורות חלקות עם קו מתאר (במקום ריבועים/פיקסלים).
#  משמש את player.gd, zombie.gd ו-severed_leg.gd.
# ============================================================

const OUTLINE := Color(0.04, 0.03, 0.05, 0.9)
const NONE := Color(0, 0, 0, 0)


# נקודות של אליפסה (rx = רוחב, ry = גובה, rot = סיבוב)
static func ellipse(c: Vector2, rx: float, ry: float, rot := 0.0, n := 22) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


# צורה מלאה + קו מתאר חלק
static func fill(ci: CanvasItem, pts: PackedVector2Array, col: Color, outline := OUTLINE, width := 1.3) -> void:
	ci.draw_colored_polygon(pts, col)
	if outline.a > 0.0:
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		ci.draw_polyline(closed, outline, width, true)


static func disc(ci: CanvasItem, c: Vector2, r: float, col: Color, outline := OUTLINE, width := 1.3) -> void:
	fill(ci, ellipse(c, r, r, 0.0, clampi(int(r * 3.0), 10, 28)), col, outline, width)


static func oval(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0, outline := OUTLINE, width := 1.3) -> void:
	fill(ci, ellipse(c, rx, ry, rot), col, outline, width)


# גפה עגולה ועבה (יד / רגל) שעוברת דרך כמה נקודות
static func limb(ci: CanvasItem, pts: PackedVector2Array, w: float, col: Color, outline := OUTLINE) -> void:
	if outline.a > 0.0:
		var ow := w + 2.6
		ci.draw_polyline(pts, outline, ow, true)
		for p in pts:
			_dot(ci, p, ow / 2.0, outline)
	ci.draw_polyline(pts, col, w, true)
	for p in pts:
		_dot(ci, p, w / 2.0, col)


static func _dot(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(ellipse(c, r, r, 0.0, 14), col)
	ci.draw_arc(c, maxf(r - 0.4, 0.1), 0.0, TAU, 14, col, 0.9, true)


# הילה רכה (עיניים זוהרות וכו')
static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	for i in 4:
		var k := 1.0 - float(i) / 4.0
		ci.draw_colored_polygon(ellipse(c, r * k, r * k, 0.0, 16), Color(col, col.a * 0.25))


# מיקום הברך / המרפק (IK של שתי עצמות). bend = 1 ברך קדימה, -1 מרפק למטה
static func joint(a: Vector2, b: Vector2, l1: float, l2: float, bend := 1.0) -> Vector2:
	var d := clampf(a.distance_to(b), 0.01, l1 + l2 - 0.01)
	var ang := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	return a + Vector2.from_angle((b - a).angle() - ang * bend) * l1


# אותו צבע, כהה / בהיר יותר
static func shade(c: Color, k: float) -> Color:
	return c.lightened(-k) if k < 0.0 else c.darkened(k)
