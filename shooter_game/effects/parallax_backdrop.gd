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
# ============================================================

var level_w := 10240.0
var sky: Callable
var layers := []          # [factor, callable]
var overlay: Callable     # מעל כל השכבות (למשל הבזק ברק / ערפל)
var t := 0.0
var _cam_x := 0.0
var _cam_y := 0.0


func add_layer(factor: float, draw_fn: Callable) -> void:
	layers.append([factor, draw_fn])


func _process(delta: float) -> void:
	t += delta
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var c := cam.get_screen_center_position()
		_cam_x = c.x
		_cam_y = c.y
	queue_redraw()


# כמה המצלמה זזה אנכית מהמצב הרגיל (שלבים עם תת-קרקע / גגות)
func cam_dy() -> float:
	return _cam_y - get_viewport_rect().size.y * 0.5


func _draw() -> void:
	var vp := get_viewport_rect().size
	if sky.is_valid():
		sky.call(self, vp, t)
	for l in layers:
		var f: float = l[0]
		var fn: Callable = l[1]
		# שכבות קרובות זזות גם קצת אנכית כשהמצלמה יורדת/עולה
		draw_set_transform(Vector2(0.0, -cam_dy() * f * 0.5), 0.0, Vector2.ONE)
		fn.call(self, _cam_x * f, vp, t)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if overlay.is_valid():
		overlay.call(self, vp, t)
