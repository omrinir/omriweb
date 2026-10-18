extends Node2D
const DrawBatch := preload("res://effects/draw_batch.gd")
# ============================================================
#  COLLISION OUTLINES - מסגרת כהה ועבה סביב כל דבר שהשחקן מתנגש בו
#  (לבנים, מכוניות, מחסומים, ארגזים, שערים, דלתות, קומות, מכונות, מעליות...)
#  כדי שיהיה קל להבדיל בין הרקע לבין מה שאפשר לעמוד עליו / להיתקע בו.
#
#  עובד אוטומטית על כל StaticBody2D / AnimatableBody2D בשכבות 1 או 16 (גם על דברים
#  שיתווספו בעתיד) - לא צריך לגעת בכל נכס בנפרד.
#  * צלעות שנוגעות בגוף אחר (חתיכות כביש, לבנים צמודות) לא מצוירות - רק קו המתאר החיצוני.
#  * גוף שנשבר / דלת פתוחה (צורה מנוטרלת או שכבה 0) - אין מסגרת.
#  * קומה (one-way) עם world_rect() - המסגרת לפי הציור שלה.
#  איך משנים: WIDTH (עובי), COLOR (צבע). OUTLINE_ENABLED = false מכבה הכל.
# ============================================================

const OUTLINE_ENABLED := true
const WIDTH := 3.0
const COLOR := Color(0.02, 0.02, 0.03, 0.92)
const MASK := 1 | 16          # השכבות שהשחקן מתנגש בהן

var _bodies: Array = []
var _scan_t := 0.0
var _sig := 0
var _cam := Vector2.INF

const REDRAW_MOVE := 200.0
const VIEW_MARGIN := 420.0


func _ready() -> void:
	z_index = 2               # מעל רוב הנכסים, מתחת לזומבים (3) ולשחקן (4)
	z_as_relative = false


func _process(delta: float) -> void:
	_scan_t -= delta
	if _scan_t <= 0.0:        # רשימת הגופים מתעדכנת פעמיים בשנייה (נוספים / נשברים)
		_scan_t = 0.5
		_bodies.clear()
		_collect(get_parent())
	# ביצועים: מציירים מחדש רק כשמשהו השתנה (גוף זז / נשבר / נפתח) או שהמצלמה זזה מעל REDRAW_MOVE.
	# הציור מכסה את המסך + VIEW_MARGIN מכל צד, אז תזוזה קטנה של המצלמה לא צריכה ציור חדש.
	var sig := _signature()
	var cam := get_viewport().get_canvas_transform().affine_inverse() * (get_viewport().get_visible_rect().size * 0.5)
	if sig != _sig or cam.distance_to(_cam) > REDRAW_MOVE:
		_sig = sig
		_cam = cam
		queue_redraw()


# חתימה זולה של מצב כל הגופים: קיים, שכבה, נראה, מיקום, צורות פעילות
func _signature() -> int:
	var h := _bodies.size()
	for b in _bodies:
		if not is_instance_valid(b) or not b.is_inside_tree():
			h = h * 31 + 7
			continue
		h = h * 31 + (int(b.collision_layer) & MASK) + (2 if b.is_visible_in_tree() else 0)
		h = h * 31 + hash(b.global_position)
		for c in b.get_children():
			if c is CollisionShape2D or c is CollisionPolygon2D:
				h = h * 3 + (1 if c.disabled else 0)
	return h


func _collect(n: Node) -> void:
	for c in n.get_children():
		if (c is StaticBody2D or c is AnimatableBody2D):
			_bodies.append(c)
		if c.get_child_count() > 0 and not (c is CharacterBody2D) and not (c is CanvasLayer):
			_collect(c)


# המלבנים (בעולם) של גוף
func _rects_of(b: Node) -> Array:
	var out := []
	if (int(b.collision_layer) & MASK) == 0 or b.is_in_group("no_outline") or not b.is_visible_in_tree():   # מוסתר = אין מסגרת. no_outline = מצייר קו מתאר משלו (דיונות)
		return out
	if b.has_method("world_rect") and b.is_in_group("platforms"):
		out.append(b.world_rect())
		return out
	for s in b.get_children():
		if s is CollisionShape2D and not s.disabled and s.shape != null:
			var r := Rect2()
			if s.shape is RectangleShape2D:
				var sz: Vector2 = (s.shape as RectangleShape2D).size
				r = Rect2(-sz * 0.5, sz)
			else:
				r = s.shape.get_rect()
			var xf: Transform2D = s.global_transform
			var p0 := xf * r.position
			var p1 := xf * r.end
			out.append(Rect2(Vector2(minf(p0.x, p1.x), minf(p0.y, p1.y)), (p1 - p0).abs()))
		elif s is CollisionPolygon2D and not s.disabled:
			var pts: PackedVector2Array = s.global_transform * s.polygon
			var rr := Rect2(pts[0], Vector2.ZERO)
			for p in pts:
				rr = rr.expand(p)
			out.append(rr)
	return out


func _draw() -> void:
	DrawBatch.begin(self)
	_draw_b()
	DrawBatch.end(self)

func _draw_b() -> void:
	if not OUTLINE_ENABLED:
		return
	var vp := get_viewport()
	var view := (vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()).grow(VIEW_MARGIN)
	var rects := []
	for b in _bodies:
		if not is_instance_valid(b) or not b.is_inside_tree():
			continue
		for r in _rects_of(b):
			if r.size.x > 1.0 and r.size.y > 1.0 and view.intersects(r):
				rects.append(r)
	var h := WIDTH * 0.5
	for i in rects.size():
		var r: Rect2 = rects[i]
		# 4 צלעות; מדלגים על חלקים שמכוסים ע"י מלבן צמוד
		_edge(rects, i, Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(0, -1), h)   # למעלה
		_edge(rects, i, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Vector2(0, 1), h)             # למטה
		_edge(rects, i, Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y), Vector2(-1, 0), h)  # שמאל
		_edge(rects, i, Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y), Vector2(1, 0), h)             # ימין


# צלע אחת: מחלקים לקטעים ומדלגים על מה שצמוד למלבן אחר
func _edge(rects: Array, self_i: int, a: Vector2, b: Vector2, normal: Vector2, h: float) -> void:
	var horizontal := normal.x == 0.0
	var lo := a.x if horizontal else a.y
	var hi := b.x if horizontal else b.y
	var fixed := a.y if horizontal else a.x
	var cuts := []   # [מ, עד] חלקים מכוסים
	for j in rects.size():
		if j == self_i:
			continue
		var o: Rect2 = rects[j]
		# המלבן השני צמוד מהצד של הנורמל?
		var probe := Vector2(0, fixed + normal.y * 2.0) if horizontal else Vector2(fixed + normal.x * 2.0, 0)
		if horizontal:
			if probe.y < o.position.y or probe.y > o.end.y:
				continue
			cuts.append([maxf(lo, o.position.x), minf(hi, o.end.x)])
		else:
			if probe.x < o.position.x or probe.x > o.end.x:
				continue
			cuts.append([maxf(lo, o.position.y), minf(hi, o.end.y)])
	cuts.sort_custom(func(p, q): return p[0] < q[0])
	var cur := lo
	for c in cuts:
		if float(c[1]) <= float(c[0]):
			continue
		if float(c[0]) > cur:
			_seg(horizontal, fixed, cur, float(c[0]), normal, h)
		cur = maxf(cur, float(c[1]))
	if cur < hi:
		_seg(horizontal, fixed, cur, hi, normal, h)


func _seg(horizontal: bool, fixed: float, from: float, to: float, normal: Vector2, h: float) -> void:
	if to - from < 0.5:
		return
	var off := -normal * h   # הקו בתוך הגוף (לא בולט החוצה)
	if horizontal:
		DrawBatch.line(self, Vector2(from, fixed) + off, Vector2(to, fixed) + off, COLOR, WIDTH)
	else:
		DrawBatch.line(self, Vector2(fixed, from) + off, Vector2(fixed, to) + off, COLOR, WIDTH)
