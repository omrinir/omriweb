extends RefCounted
# ============================================================
#  DRAW BATCH - כל הציור של זומבי בקריאה אחת לכרטיס המסך (draw call אחד במקום ~120).
#  אותו רעיון כמו רימון הכבידה (weapons/gravity_grenade.gd): כל הצורות נאספות למערך משולשים אחד
#  ונשלחות ב-RenderingServer.canvas_item_add_triangle_array פעם אחת בסוף _draw.
#  למה: ב-Godot כל draw_circle / draw_colored_polygon / draw_polyline / draw_line עם עובי = draw call נפרד.
#  40 זומבים x 120 = ~5000 draw calls בפריים - זה מה שהאט את המשחק כשיש הרבה זומבים על המסך.
#
#  איך משתמשים: zombie.gd -> _draw(): DrawBatch.begin(self) ... DrawBatch.end(self).
#  כל קריאות הציור בקוד של הזומבים עברו ל-DrawBatch.line(ci, ...) / circle / polygon / ...
#  עם אותם פרמטרים כמו ב-Godot. אם אין batch פתוח לאותו ci - הקריאה הולכת ישר ל-Godot (שחקן, קישוטים).
#  טקסט / טקסטורות: ה-batch נשלח קודם (שהסדר יישאר נכון) ואז מצוירים כרגיל.
#  לכבות לבדיקה: ENABLED = false.
# ============================================================

const ENABLED := true
const FEATHER := 1.0              # רוחב השוליים הרכים של קו מוחלק (כמו ב-Godot)

static var _ci: CanvasItem = null
static var _rid := RID()
static var _xf := Transform2D.IDENTITY
static var _pts := PackedVector2Array()
static var _cols := PackedColorArray()
static var _fans := {}            # n -> משולשי מניפה של עיגול יחידה (מרכז, נקודה, הנקודה הבאה)
static var _quad := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)])
static var _tmpc := PackedColorArray()
static var flushes := 0           # לבדיקות


static func begin(ci: CanvasItem) -> void:
	if not ENABLED:
		return
	if _ci != null:
		end(_ci)
	_ci = ci
	_rid = ci.get_canvas_item()
	_xf = Transform2D.IDENTITY
	_pts.clear()
	_cols.clear()


static func end(ci: CanvasItem) -> void:
	if _ci != ci:
		return
	_flush()
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
	_ci = null


static func _flush() -> void:
	if not _pts.is_empty():
		RenderingServer.canvas_item_add_triangle_array(_rid, PackedInt32Array(), _pts, _cols)
		flushes += 1
		_pts.clear()
		_cols.clear()


static func _on(ci: CanvasItem) -> bool:
	return ci == _ci and _ci != null


static func _add(tris: PackedVector2Array, col: Color) -> void:
	_pts.append_array(tris)
	if _tmpc.size() != tris.size():   # מערך צבעים אחיד (בלי לולאה - פעולות מובנות)
		_tmpc.resize(tris.size())
	_tmpc.fill(col)
	_cols.append_array(_tmpc)


static func _fan(n: int) -> PackedVector2Array:
	if not _fans.has(n):
		var out := PackedVector2Array()
		for i in n:
			var a0 := TAU * float(i) / float(n)
			var a1 := TAU * float(i + 1) / float(n)
			out.append_array([Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1))])
		_fans[n] = out
	return _fans[n]


static func _seg(r: float) -> int:   # כמה צלעות לעיגול לפי הגודל על המסך
	var s := r * _xf.get_scale().abs().x
	return 8 if s < 2.0 else (12 if s < 4.0 else (16 if s < 9.0 else (24 if s < 20.0 else 32)))


# ---- ציור "חי" כשאין batch: הטרנספורם של הקנבס ----
static func set_transform(ci: CanvasItem, pos: Vector2, rot := 0.0, scale := Vector2.ONE) -> void:
	if _on(ci):
		_xf = Transform2D(rot, scale, 0.0, pos)
	else:
		ci.draw_set_transform(pos, rot, scale)


static func set_transform_matrix(ci: CanvasItem, xf: Transform2D) -> void:
	if _on(ci):
		_xf = xf
	else:
		ci.draw_set_transform_matrix(xf)


# אליפסה מלאה (מהיר: מניפה קבועה + טרנספורם אחד, בלי חישוב לכל נקודה)
static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot := 0.0, n := 0) -> void:
	if n <= 0:
		n = _seg(maxf(rx, ry))
	if not _on(ci):
		ci.draw_colored_polygon(Transform2D(rot, Vector2(rx, ry), 0.0, c) * _unit(n), col)
		return
	_add(_xf * Transform2D(rot, Vector2(rx, ry), 0.0, c) * _fan(n), col)


static var _units := {}
static func _unit(n: int) -> PackedVector2Array:
	if not _units.has(n):
		var pts := PackedVector2Array()
		for i in n:
			pts.append(Vector2.from_angle(TAU * float(i) / float(n)))
		_units[n] = pts
	return _units[n]


# אליפסה עם צבע לכל נקודה על ההיקף (הצללה). cols = צבע לכל אחת מ-n הנקודות, center_col = המרכז
static func ellipse_cols(ci: CanvasItem, c: Vector2, rx: float, ry: float, cols: PackedColorArray, center_col: Color, rot := 0.0) -> void:
	var n := cols.size()
	if not _on(ci):
		ci.draw_polygon(Transform2D(rot, Vector2(rx, ry), 0.0, c) * _unit(n), cols)
		return
	_pts.append_array(_xf * Transform2D(rot, Vector2(rx, ry), 0.0, c) * _fan(n))
	for i in n:
		_cols.append_array([center_col, cols[i], cols[(i + 1) % n]])


# ================= אותם פרמטרים כמו ב-Godot =================

static func circle(ci: CanvasItem, pos: Vector2, radius: float, color: Color, filled := true, width := -1.0, antialiased := false) -> void:
	if not _on(ci):
		ci.draw_circle(pos, radius, color, filled, width, antialiased)
		return
	if filled:
		_add(_xf * Transform2D(0.0, Vector2(radius, radius), 0.0, pos) * _fan(_seg(radius)), color)
	else:
		arc(ci, pos, radius, 0.0, TAU, _seg(radius) + 1, color, width, antialiased)


static func colored_polygon(ci: CanvasItem, points: PackedVector2Array, color: Color, uvs := PackedVector2Array(), texture: Texture2D = null) -> void:
	if not _on(ci) or texture != null:
		_pass(ci)
		ci.draw_colored_polygon(points, color, uvs, texture)
		return
	var n := points.size()
	if n < 3:
		return
	var idx: PackedInt32Array
	if n == 3:
		idx = PackedInt32Array([0, 1, 2])
	elif n == 4 and _convex4(points):
		idx = PackedInt32Array([0, 1, 2, 0, 2, 3])
	else:
		idx = Geometry2D.triangulate_polygon(points)
		if idx.is_empty():
			return
	var p := _xf * points
	var base := _pts.size()
	_pts.resize(base + idx.size())
	_cols.resize(base + idx.size())
	for i in idx.size():
		_pts[base + i] = p[idx[i]]
		_cols[base + i] = color


static func polygon(ci: CanvasItem, points: PackedVector2Array, colors: PackedColorArray, uvs := PackedVector2Array(), texture: Texture2D = null) -> void:
	if not _on(ci) or texture != null or colors.size() != points.size():
		if _on(ci) and texture == null and colors.size() == 1:
			colored_polygon(ci, points, colors[0])
			return
		_pass(ci)
		ci.draw_polygon(points, colors, uvs, texture)
		return
	var n := points.size()
	if n < 3:
		return
	var idx := Geometry2D.triangulate_polygon(points)
	if idx.is_empty():
		return
	var p := _xf * points
	var base := _pts.size()
	_pts.resize(base + idx.size())
	_cols.resize(base + idx.size())
	for i in idx.size():
		_pts[base + i] = p[idx[i]]
		_cols[base + i] = colors[idx[i]]


static func _convex4(p: PackedVector2Array) -> bool:
	var s0 := (p[1] - p[0]).cross(p[2] - p[1])
	var s1 := (p[2] - p[1]).cross(p[3] - p[2])
	var s2 := (p[3] - p[2]).cross(p[0] - p[3])
	var s3 := (p[0] - p[3]).cross(p[1] - p[0])
	return (s0 >= 0 and s1 >= 0 and s2 >= 0 and s3 >= 0) or (s0 <= 0 and s1 <= 0 and s2 <= 0 and s3 <= 0)


# קו עבה = מלבן (width <= 0 = קו דק של פיקסל אחד במסך)
static func line(ci: CanvasItem, from: Vector2, to: Vector2, color: Color, width := -1.0, antialiased := false) -> void:
	if not _on(ci):
		ci.draw_line(from, to, color, width, antialiased)
		return
	var w := width if width > 0.0 else 1.0 / maxf(_xf.get_scale().abs().x, 0.001)
	var d := to - from
	var l := d.length()
	if l < 0.0001:
		return
	var nrm := Vector2(-d.y, d.x) / l * (w * 0.5)
	var a := from + nrm
	var b := to + nrm
	var c := to - nrm
	var e := from - nrm
	_add(_xf * PackedVector2Array([a, b, c, a, c, e]), color)


static func polyline(ci: CanvasItem, points: PackedVector2Array, color: Color, width := -1.0, antialiased := false) -> void:
	if not _on(ci):
		ci.draw_polyline(points, color, width, antialiased)
		return
	var n := points.size()
	if n < 2:
		return
	var w := width if width > 0.0 else 1.0 / maxf(_xf.get_scale().abs().x, 0.001)
	var h := w * 0.5
	var out := PackedVector2Array()
	out.resize((n - 1) * 6)
	# נורמל בכל נקודה (ממוצע של שני הקטעים) - החיבורים בלי חורים
	var nr := PackedVector2Array()
	nr.resize(n)
	for i in n:
		var d0 := points[i] - points[maxi(i - 1, 0)]
		var d1 := points[mini(i + 1, n - 1)] - points[i]
		var d := d0.normalized() + d1.normalized()
		if d.length_squared() < 0.0001:
			d = d1 if d1.length_squared() > 0.0 else d0
		d = d.normalized()
		var m := Vector2(-d.y, d.x)
		var seg := (d1 if d1.length_squared() > 0.0 else d0).normalized()
		var cosv := absf(m.dot(Vector2(-seg.y, seg.x)))
		nr[i] = m * (h / maxf(cosv, 0.35))   # miter, מוגבל
	for i in n - 1:
		var a := points[i] + nr[i]
		var b := points[i + 1] + nr[i + 1]
		var c := points[i + 1] - nr[i + 1]
		var e := points[i] - nr[i]
		var j := i * 6
		out[j] = a
		out[j + 1] = b
		out[j + 2] = c
		out[j + 3] = a
		out[j + 4] = c
		out[j + 5] = e
	_add(_xf * out, color)
	if antialiased:   # כמו Godot: שוליים רכים (FEATHER) משני הצדדים, שקופים בקצה
		var fo := PackedVector2Array()
		fo.resize((n - 1) * 12)
		var fc := PackedColorArray()
		fc.resize((n - 1) * 12)
		var clear := Color(color, 0.0)
		for i in n - 1:
			var k0 := nr[i].normalized() * FEATHER
			var k1 := nr[i + 1].normalized() * FEATHER
			for side in 2:
				var sg := 1.0 if side == 0 else -1.0
				var p0 := points[i] + nr[i] * sg
				var p1 := points[i + 1] + nr[i + 1] * sg
				var q0 := p0 + k0 * sg
				var q1 := p1 + k1 * sg
				var j := i * 12 + side * 6
				fo[j] = p0
				fo[j + 1] = p1
				fo[j + 2] = q1
				fo[j + 3] = p0
				fo[j + 4] = q1
				fo[j + 5] = q0
				fc[j] = color
				fc[j + 1] = color
				fc[j + 2] = clear
				fc[j + 3] = color
				fc[j + 4] = clear
				fc[j + 5] = clear
		_pts.append_array(_xf * fo)
		_cols.append_array(fc)


static func arc(ci: CanvasItem, center: Vector2, radius: float, start_angle: float, end_angle: float, point_count: int, color: Color, width := -1.0, antialiased := false) -> void:
	if not _on(ci):
		ci.draw_arc(center, radius, start_angle, end_angle, point_count, color, width, antialiased)
		return
	if point_count < 2:
		return
	var pts := PackedVector2Array()
	pts.resize(point_count)
	for i in point_count:
		var a := lerpf(start_angle, end_angle, float(i) / float(point_count - 1))
		pts[i] = center + Vector2(cos(a), sin(a)) * radius
	polyline(ci, pts, color, width, antialiased)


static func rect(ci: CanvasItem, r: Rect2, color: Color, filled := true, width := -1.0, antialiased := false) -> void:
	if not _on(ci):
		ci.draw_rect(r, color, filled, width, antialiased)
		return
	if filled:
		_add(_xf * Transform2D(0.0, r.size, 0.0, r.position) * _quad, color)
	else:
		var p := r.position
		var s := r.size
		polyline(ci, PackedVector2Array([p, p + Vector2(s.x, 0), p + s, p + Vector2(0, s.y), p]), color, width, antialiased)


# ---- דברים שאי אפשר לאסוף (טקסט, טקסטורה): שולחים את מה שנאסף, ומציירים כרגיל עם הטרנספורם הנוכחי ----
static func _pass(ci: CanvasItem) -> void:
	if _on(ci):
		_flush()
		ci.draw_set_transform_matrix(_xf)


static func _unpass(ci: CanvasItem) -> void:
	if _on(ci):
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func texture_rect(ci: CanvasItem, texture: Texture2D, r: Rect2, tile: bool, modulate := Color.WHITE, transpose := false) -> void:
	_pass(ci)
	ci.draw_texture_rect(texture, r, tile, modulate, transpose)
	_unpass(ci)


static func texture_rect_region(ci: CanvasItem, texture: Texture2D, r: Rect2, src_rect: Rect2, modulate := Color.WHITE, transpose := false, clip_uv := true) -> void:
	_pass(ci)
	ci.draw_texture_rect_region(texture, r, src_rect, modulate, transpose, clip_uv)
	_unpass(ci)


static func string(ci: CanvasItem, font: Font, pos: Vector2, text: String, alignment := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, font_size := 16, modulate := Color.WHITE, justification_flags := 3, direction := 0, orientation := 0) -> void:
	_pass(ci)
	ci.draw_string(font, pos, text, alignment, width, font_size, modulate, justification_flags, direction, orientation)
	_unpass(ci)


static func string_outline(ci: CanvasItem, font: Font, pos: Vector2, text: String, alignment := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, font_size := 16, size := 1, modulate := Color.WHITE, justification_flags := 3, direction := 0, orientation := 0) -> void:
	_pass(ci)
	ci.draw_string_outline(font, pos, text, alignment, width, font_size, size, modulate, justification_flags, direction, orientation)
	_unpass(ci)


static func multiline_string(ci: CanvasItem, font: Font, pos: Vector2, text: String, alignment := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, font_size := 16, max_lines := -1, modulate := Color.WHITE, brk_flags := 3, justification_flags := 3, direction := 0, orientation := 0) -> void:
	_pass(ci)
	ci.draw_multiline_string(font, pos, text, alignment, width, font_size, max_lines, modulate, brk_flags, justification_flags, direction, orientation)
	_unpass(ci)


static func multiline_string_outline(ci: CanvasItem, font: Font, pos: Vector2, text: String, alignment := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, font_size := 16, max_lines := -1, size := 1, modulate := Color.WHITE, brk_flags := 3, justification_flags := 3, direction := 0, orientation := 0) -> void:
	_pass(ci)
	ci.draw_multiline_string_outline(font, pos, text, alignment, width, font_size, max_lines, size, modulate, brk_flags, justification_flags, direction, orientation)
	_unpass(ci)


static func style_box(ci: CanvasItem, sb: StyleBox, r: Rect2) -> void:
	_pass(ci)
	ci.draw_style_box(sb, r)
	_unpass(ci)


static func texture(ci: CanvasItem, tex: Texture2D, pos: Vector2, modulate := Color.WHITE) -> void:
	_pass(ci)
	ci.draw_texture(tex, pos, modulate)
	_unpass(ci)


# קווים נפרדים: כל זוג נקודות = קו
static func multiline(ci: CanvasItem, points: PackedVector2Array, color: Color, width := -1.0) -> void:
	if not _on(ci):
		ci.draw_multiline(points, color, width)
		return
	for i in range(0, points.size() - 1, 2):
		line(ci, points[i], points[i + 1], color, width)


static func polyline_colors(ci: CanvasItem, points: PackedVector2Array, colors: PackedColorArray, width := -1.0, antialiased := false) -> void:
	_pass(ci)
	ci.draw_polyline_colors(points, colors, width, antialiased)
	_unpass(ci)


# משולשים מוכנים (כמו RenderingServer.canvas_item_add_triangle_array): נכנסים ל-batch עם הטרנספורם הנוכחי
static func tris(ci: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray) -> void:
	if not _on(ci):
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), PackedInt32Array(), pts, cols)
		return
	if cols.size() == pts.size():
		_pts.append_array(_xf * pts)
		_cols.append_array(cols)
	elif cols.size() == 1:
		_add(_xf * pts, cols[0])
	else:
		_flush()
		ci.draw_set_transform_matrix(_xf)
		RenderingServer.canvas_item_add_triangle_array(_rid, PackedInt32Array(), pts, cols)
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
