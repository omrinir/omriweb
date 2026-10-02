extends Control
# ============================================================
#  כפתור מונפש בסגנון המשחק: לוח כהה עם קצוות קרועים,
#  שמתמלא בדם כשהעכבר עליו (עם טפטופים), גדל קצת, ומהבהב בלחיצה.
#  עובד גם עם המקלדת (חיצים + Enter).
# ============================================================

signal pressed

@export var text := "PLAY"
@export var font_size := 34
@export var accent := Color("b3121a")
## כפתור "נבחר" (למשל רמת הקושי הנוכחית)
@export var selected := false
## אחרי כמה שניות הכפתור נכנס למסך (אנימציית כניסה)
@export var appear_delay := 0.0

var _hover := 0.0
var _press := 0.0
var _appear := 0.0
var _t := 0.0
var _mouse_in := false
var _seed := 0
var _shake := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): _mouse_in = true; grab_focus())
	mouse_exited.connect(func(): _mouse_in = false)
	_seed = hash(text)
	process_mode = Node.PROCESS_MODE_ALWAYS   # עובד גם כשהמשחק בהשהיה


func _process(delta: float) -> void:
	_t += delta
	var target := 1.0 if (_mouse_in or has_focus()) else 0.0
	_hover = move_toward(_hover, target, delta * 5.0)
	_press = move_toward(_press, 0.0, delta * 4.0)
	_shake = move_toward(_shake, 0.0, delta * 3.0)
	if _t > appear_delay:
		_appear = move_toward(_appear, 1.0, delta * 3.0)
	modulate.a = 1.0 - pow(1.0 - _appear, 3.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click()
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		_click()
		accept_event()


func _click() -> void:
	if _appear < 0.3:
		return
	_press = 1.0
	_shake = 1.0
	pressed.emit()


# צורת הלוח: מלבן עם קצוות קרועים ופינה חתוכה
func _slab(w: float, h: float) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var pts := PackedVector2Array()
	var n := maxi(4, int(w / 22.0))
	for i in n + 1:   # קצה עליון
		pts.append(Vector2(w * float(i) / float(n), rng.randf_range(-1.5, 1.5)))
	pts.append(Vector2(w + 6.0, h * 0.5))      # חוד בצד ימין
	for i in range(n, -1, -1):   # קצה תחתון
		pts.append(Vector2(w * float(i) / float(n) - (6.0 if i == n else 0.0), h + rng.randf_range(-2.0, 2.0)))
	pts.append(Vector2(-4.0, h * 0.55))
	return pts


func _draw() -> void:
	var w := size.x
	var h := size.y
	var k := _hover * _hover * (3.0 - 2.0 * _hover)   # תנועה רכה
	var ap := 1.0 - pow(1.0 - _appear, 3.0)
	if ap <= 0.0:
		return
	var s := 1.0 + 0.06 * k - 0.06 * _press
	var off := Vector2(-260.0 * (1.0 - ap), 0.0) + Vector2(sin(_t * 70.0), cos(_t * 63.0)) * 3.0 * _shake
	var rot := sin(_t * 2.5) * 0.008 * k
	draw_set_transform(size / 2.0 + off, rot, Vector2(s, s))
	var o := -size / 2.0
	var slab := Transform2D(0.0, o) * _slab(w, h)
	# צל
	draw_colored_polygon(Transform2D(0.0, Vector2(5, 6)) * slab, Color(0, 0, 0, 0.45))
	# גוף הכפתור
	draw_colored_polygon(slab, Color(0.07, 0.06, 0.07, 0.9))
	# דם שממלא את הכפתור משמאל לימין
	if k > 0.01:
		var fill_w := (w + 12.0) * k
		var wave := PackedVector2Array([o + Vector2(-8, -6), o + Vector2(fill_w, -6)])
		for i in 7:   # קצה גלי של הדם
			var y := h * float(i) / 6.0
			wave.append(o + Vector2(fill_w + sin(_t * 6.0 + float(i) * 1.3) * 5.0, y))
		wave.append(o + Vector2(fill_w, h + 6.0))
		wave.append(o + Vector2(-8, h + 6.0))
		for poly in Geometry2D.intersect_polygons(slab, wave):
			var cols := PackedColorArray()
			for p in poly:
				cols.append(accent.lerp(accent.darkened(0.5), clampf((p.y - o.y) / h, 0.0, 1.0)))
			draw_polygon(poly, cols)
		# טפטופים מתחת לכפתור
		var rng := RandomNumberGenerator.new()
		rng.seed = _seed + 7
		for i in 5:
			var dx := rng.randf_range(10.0, w - 20.0)
			if dx > fill_w:
				continue
			var dl := rng.randf_range(6.0, 20.0) * k * (0.7 + 0.3 * sin(_t * 1.5 + float(i)))
			var p0 := o + Vector2(dx, h - 1.0)
			draw_line(p0, p0 + Vector2(0, dl), accent.darkened(0.3), 3.0, true)
			draw_circle(p0 + Vector2(0, dl), 2.4, accent.darkened(0.3))
	# קו אור לבן למעלה (כמו במנגה) + פס צבע משמאל
	var top := PackedVector2Array()
	for i in int(maxf(4.0, w / 22.0)) + 1:
		top.append(slab[i])
	draw_polyline(top, Color(1, 1, 1, 0.35 + 0.4 * k), 1.4, true)
	draw_rect(Rect2(o + Vector2(0, 4), Vector2(4, h - 8)), accent if not selected else accent.lightened(0.3))
	var closed := PackedVector2Array(slab)
	closed.append(slab[0])
	if selected:   # מסגרת אדומה שפועמת
		var pulse := 0.6 + 0.4 * sin(_t * 4.0)
		draw_polyline(closed, Color(accent.lightened(0.25), pulse), 2.5, true)
	else:
		draw_polyline(closed, Color(0, 0, 0, 0.8), 1.5, true)
	# טקסט
	var f := ThemeDB.fallback_font
	var ts := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var tp := o + Vector2((w - ts.x) / 2.0 + 6.0 * k, h / 2.0 + ts.y * 0.32)
	draw_string_outline(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0, 0, 0, 0.9))
	draw_string(f, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1).lerp(Color(1.0, 0.92, 0.85), k))
	if selected:   # חץ קטן שמסמן את הבחירה
		var a := o + Vector2(-16.0 - 3.0 * sin(_t * 5.0), h / 2.0)
		draw_colored_polygon(PackedVector2Array([a + Vector2(-8, -7), a + Vector2(2, 0), a + Vector2(-8, 7)]), accent.lightened(0.2))
	# הבזק לבן בלחיצה
	if _press > 0.0:
		draw_colored_polygon(slab, Color(1, 1, 1, 0.55 * _press))
	draw_set_transform_matrix(Transform2D.IDENTITY)
