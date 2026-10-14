extends Node2D
# ============================================================
#  PARALLAX BACKDROP - מערכת רקע עם שכבות שזזות במהירויות שונות.
#  נמצא בתוך CanvasLayer (layer -10), כלומר מצויר בקואורדינטות מסך.
#
#  שימוש (levels/stage_N.gd -> build_background):
#    var bg = ParallaxBackdrop.new()
#    bg.sky = func(ci, vp, t): ...                 # שמיים (לא זזים)
#    bg.add_layer(0.10, func(ci, scroll, vp, t): ...)   # רחוק
#    bg.add_layer(0.30, ...)                       # אמצע
#    bg.add_layer(0.60, ...)                       # קרוב
#  scroll = כמה פיקסלים השכבה זזה (מיקום המצלמה x factor). t = זמן (לאנימציות
#  שזזות בלי קשר לשחקן: עננים, מסוקים, ציפורים, עשן, ברקים...)
#  עזרים מוכנים לציור: effects/backdrop_kit.gd
#
#  מהירויות מומלצות: רחוק 0.10, אמצע 0.30, קרוב 0.60 (לא יותר - זה מסיח)
#
#  ביצועים: כל שכבה מצוירת ב-node משלה (_Layer). כשהמשחק איטי (quality.gd -> bg_every) שכבה מצוירת מחדש
#  רק כל כמה פריימים - ובפריימים שבינתיים היא רק זזה (position) לפי המצלמה, כך שהגלילה נשארת חלקה.
#  אם המצלמה זזה יותר מ-MAX_SHIFT פיקסלים מאז הציור האחרון - מציירים מיד (שלא ייפתח רווח בקצה המסך).
#  פונקציות הציור מקבלות את ה-node של השכבה כ-ci (אותן פקודות draw_*), לא את הרקע עצמו.
# ============================================================

var level_w := 10240.0
var sky: Callable
var layers := []          # [factor, callable]
var overlay: Callable     # מעל כל השכבות (למשל הבזק ברק / ערפל)
var t := 0.0
var _cam_x := 0.0
var _cam_y := 0.0
var _nodes := []          # _Layer לכל: שמיים, שכבות, overlay
var _built := -1
var _frame := 0

const MAX_SHIFT := 4.0


func add_layer(factor: float, draw_fn: Callable) -> void:
	layers.append([factor, draw_fn])


func _build() -> void:
	for n in _nodes:
		n.queue_free()
	_nodes.clear()
	var list := []
	if sky.is_valid():
		list.append([0.0, sky, 0])
	for l in layers:
		list.append([float(l[0]), l[1], 1])
	if overlay.is_valid():
		list.append([0.0, overlay, 2])
	for i in list.size():
		var n := _Layer.new()
		n.bg = self
		n.factor = list[i][0]
		n.fn = list[i][1]
		n.mode = list[i][2]
		n.slot = i
		add_child(n)
		_nodes.append(n)
	_built = layers.size() * 4 + (1 if sky.is_valid() else 0) + (2 if overlay.is_valid() else 0)


func _process(delta: float) -> void:
	t += delta
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var c := cam.get_screen_center_position()
		_cam_x = c.x
		_cam_y = c.y
	if _built != layers.size() * 4 + (1 if sky.is_valid() else 0) + (2 if overlay.is_valid() else 0):
		_build()
	_frame += 1
	var every := Quality.bg_every()
	var dy := cam_dy()
	for n in _nodes:
		n.step(_cam_x, dy, t, every <= 1 or (_frame + n.slot) % every == 0)


# כמה המצלמה זזה אנכית מהמצב הרגיל (שלבים עם תת-קרקע / גגות)
func cam_dy() -> float:
	return _cam_y - get_viewport_rect().size.y * 0.5


# שכבה אחת של הרקע: מציירת עם מצב המצלמה של הציור האחרון, וזזה בינתיים
class _Layer extends Node2D:
	var bg: Node2D
	var factor := 0.0
	var fn: Callable
	var mode := 1          # 0 שמיים, 1 שכבה, 2 overlay
	var slot := 0
	var _dx := 0.0         # מצב המצלמה בציור האחרון
	var _dy := 0.0
	var _t := 0.0
	var _drawn := false

	func step(cx: float, dy: float, t: float, due: bool) -> void:
		var sx := -(cx - _dx) * factor
		var sy := -(dy - _dy) * factor * 0.5
		if due or not _drawn or absf(sx) > MAX_SHIFT or absf(sy) > MAX_SHIFT:
			_dx = cx
			_dy = dy
			_t = t
			_drawn = true
			position = Vector2.ZERO
			queue_redraw()
		else:
			position = Vector2(sx, sy)

	func _draw() -> void:
		var vp := get_viewport_rect().size
		if mode == 1:   # שכבות קרובות זזות גם קצת אנכית כשהמצלמה יורדת/עולה
			draw_set_transform(Vector2(0.0, -_dy * factor * 0.5), 0.0, Vector2.ONE)
			fn.call(self, _dx * factor, vp, _t)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		else:
			fn.call(self, vp, _t)
