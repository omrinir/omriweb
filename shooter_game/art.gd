extends RefCounted
# ============================================================
#  כלי ציור משותפים: צורות חלקות עם קו מתאר, הצללה ותאורה.
#  משמש את player.gd, zombie.gd ו-severed_leg.gd.
# ============================================================

const OUTLINE := Color(0.04, 0.03, 0.05, 0.9)
const NONE := Color(0, 0, 0, 0)

static var _circles := {}


# עיגול יחידה (נשמר בזיכרון כדי לא לחשב כל פריים)
static func _unit(n: int) -> PackedVector2Array:
	if not _circles.has(n):
		var pts := PackedVector2Array()
		for i in n:
			var a := TAU * float(i) / float(n)
			pts.append(Vector2(cos(a), sin(a)))
		_circles[n] = pts
	return _circles[n]


# נקודות של אליפסה (rx = רוחב, ry = גובה, rot = סיבוב)
static func ellipse(c: Vector2, rx: float, ry: float, rot := 0.0, n := 20) -> PackedVector2Array:
	return Transform2D(rot, Vector2(rx, ry), 0.0, c) * _unit(n)


static func _outline(ci: CanvasItem, pts: PackedVector2Array, outline: Color, width: float) -> void:
	if outline.a > 0.0:
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		ci.draw_polyline(closed, outline, width, true)


# צורה מלאה + קו מתאר חלק
static func fill(ci: CanvasItem, pts: PackedVector2Array, col: Color, outline := OUTLINE, width := 1.3) -> void:
	ci.draw_colored_polygon(pts, col)
	_outline(ci, pts, outline, width)


# צורה עם הצללה: בהיר למעלה, כהה למטה (נראה תלת-ממדי)
static func fill_shaded(ci: CanvasItem, pts: PackedVector2Array, col: Color, light := 0.18, dark := 0.3, outline := OUTLINE, width := 1.3) -> void:
	var y0 := INF
	var y1 := -INF
	for p in pts:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	var h := maxf(y1 - y0, 0.001)
	var top := col.lightened(light)
	var bottom := col.darkened(dark)
	var cols := PackedColorArray()
	cols.resize(pts.size())
	for i in pts.size():
		cols[i] = top.lerp(bottom, (pts[i].y - y0) / h)
	ci.draw_polygon(pts, cols)
	_outline(ci, pts, outline, width)


static func disc(ci: CanvasItem, c: Vector2, r: float, col: Color, outline := OUTLINE, width := 1.3) -> void:
	fill(ci, ellipse(c, r, r, 0.0, 16 if r > 2.5 else 10), col, outline, width)


static func oval(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0, outline := OUTLINE, width := 1.3) -> void:
	fill(ci, ellipse(c, rx, ry, rot), col, outline, width)


static func oval_shaded(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0, outline := OUTLINE, width := 1.3) -> void:
	fill_shaded(ci, ellipse(c, rx, ry, rot, 22), col, 0.2, 0.3, outline, width)


# גפה עגולה ועבה (יד / רגל) שעוברת דרך כמה נקודות, עם אור מלמעלה
static func limb(ci: CanvasItem, pts: PackedVector2Array, w: float, col: Color, outline := OUTLINE) -> void:
	if outline.a > 0.0:
		var ow := w + 2.6
		ci.draw_polyline(pts, outline, ow, true)
		for p in pts:
			ci.draw_circle(p, ow / 2.0, outline)
	ci.draw_polyline(pts, col, w, true)
	for p in pts:
		ci.draw_circle(p, w / 2.0, col)
	if w >= 3.0:
		var off := Vector2(-0.22, -0.22) * w
		ci.draw_polyline(Transform2D(0.0, off) * pts, Color(col.lightened(0.2), 0.3), w * 0.28, true)


# הילה רכה (עיניים זוהרות, להבות)
static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	for i in 3:
		var k := 1.0 - float(i) / 3.0
		ci.draw_circle(c, r * k, Color(col, col.a * 0.28))


# צל על הריצפה
static func ground_shadow(ci: CanvasItem, c: Vector2, rx: float) -> void:
	ci.draw_colored_polygon(ellipse(c, rx, rx * 0.18, 0.0, 16), Color(0, 0, 0, 0.28))


# מיקום הברך / המרפק (IK של שתי עצמות). bend = 1 ברך קדימה, -1 מרפק למטה
static func joint(a: Vector2, b: Vector2, l1: float, l2: float, bend := 1.0) -> Vector2:
	var d := clampf(a.distance_to(b), 0.01, l1 + l2 - 0.01)
	var ang := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	return a + Vector2.from_angle((b - a).angle() - ang * bend) * l1


# אותו צבע, כהה / בהיר יותר
static func shade(c: Color, k: float) -> Color:
	return c.lightened(-k) if k < 0.0 else c.darkened(k)


# האם נקודה בעולם נמצאת על המסך (כדי לא לצייר דמויות שלא רואים)
static func on_screen(ci: CanvasItem, pos: Vector2, margin := 120.0) -> bool:
	var vp := ci.get_viewport()
	var r := vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()
	return r.grow(margin).has_point(pos)
