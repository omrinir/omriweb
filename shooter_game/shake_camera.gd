extends Camera2D
# ============================================================
#  מצלמה שעוקבת אחרי השחקן ויודעת לרעוד (למשל בפיצוץ רימון).
#  נוצרת ע"י main.gd. כדי לרעוד מכל מקום במשחק:
#      get_viewport().get_camera_2d().shake(10.0, 0.3)
#  "זום קטן" (למשל בקפיצה):  ...get_camera_2d().punch_zoom(0.03)
#  "בעיטת ירייה":  ...get_camera_2d().fire_kick(כיוון הירייה, פיקסלים) - המסך נדחף קצת הפוך לכיוון הקנה
#  וחוזר מהר כמו קפיץ (לא רעידה אקראית - כל ירייה מרגישה כמו מכה). player.gd -> _screen_kick.
#  (0.03 = 3% זום פנימה, נכנס בעדינות ודועך חזרה לזום הרגיל)
#  הזום עובר דרך שני שלבי החלקה ברצף -> עקומת S: מתחיל לאט, מאיץ, ונרגע (בלי "קפיצה" בהתחלה).
#  שיא אחרי ~0.33 שנ' (כ-80% מהכמות), מחזיק רגע (punch_hold) ודועך חזרה תוך ~שנייה.
# ============================================================

## כמה מהר הזום הקטן נכנס (החלקה) / כמה זמן מחזיק בשיא / כמה מהר דועך חזרה
@export var punch_in_speed := 10.0
@export var punch_hold := 0.18
@export var punch_out_speed := 2.2
# ============================================================

## כמה מהר הרעידה נחלשת
@export var decay := 1.0

## בעיטת ירייה: קשיחות הקפיץ / ריסון (גבוה = חוזר מהר יותר) / מקסימום פיקסלים
@export var kick_stiffness := 650.0
@export var kick_damping := 30.0
@export var kick_max := 10.0

var _strength := 0.0
var _time_left := 0.0
var _duration := 0.0
var _base_zoom := Vector2.ONE
var _punch_target := 0.0
var _punch := 0.0
var _punch_mid := 0.0       # שלב ההחלקה הראשון (השני = _punch)
var _punch_hold_t := 0.0
var _anchor_off := Vector2.ZERO   # הזזה שמשאירה את השחקן במקום על המסך בזמן הזום
var base_offset := Vector2.ZERO   # הזזה קבועה (טלפון: השחקן ברבע השמאלי של המסך במקום באמצע)
var frame_target: Node2D = null   # בוס נייח ענק: המצלמה זזה כדי שגם הוא וגם השחקן ייראו (stationary_boss.gd)
var frame_half := 180.0           # חצי הרוחב של המטרה (בעולם)
var _frame_off := 0.0
var _kick := Vector2.ZERO         # בעיטת ירייה: הזזה נוכחית + מהירות (קפיץ מרוסן)
var _kick_v := Vector2.ZERO


func _ready() -> void:
	add_to_group("camera")
	_base_zoom = zoom


# amount = כמה זום להוסיף (0.03 = 3%). זום חזק יותר דורס חלש יותר
func punch_zoom(amount: float) -> void:
	if amount >= _punch_target:
		_punch_target = amount
		_punch_hold_t = punch_hold


# בעיטת ירייה: dir = כיוון הירייה, px = כמה פיקסלים בערך (השיא). המסך זז הפוך לקנה וחוזר
func fire_kick(dir: Vector2, px: float) -> void:
	if dir == Vector2.ZERO:
		return
	var d := dir.normalized()
	var side := Vector2(-d.y, d.x) * randf_range(-0.3, 0.3)   # קצת הצידה - שלא ירגיש מכני
	_kick_v += (-d + side) * px * 90.0


# strength = כמה פיקסלים המסך זז, duration = כמה שניות
func shake(strength := 8.0, duration := 0.25) -> void:
	if strength >= _strength * (_time_left / maxf(_duration, 0.001)):
		_strength = strength
		_duration = duration
		_time_left = duration


func _process(delta: float) -> void:
	# זום קטן: היעד מחזיק רגע ואז דועך; הזום עצמו עוקב אחריו דרך שתי החלקות (עקומת S רכה)
	if _punch_hold_t > 0.0:
		_punch_hold_t -= delta
	else:
		_punch_target *= exp(-punch_out_speed * delta)
	if _punch_target < 0.0005:
		_punch_target = 0.0
	var kp := 1.0 - exp(-punch_in_speed * delta)
	_punch_mid = lerpf(_punch_mid, _punch_target, kp)
	_punch = lerpf(_punch, _punch_mid, kp)
	if _punch > 0.0005 or _punch_mid > 0.0005 or _punch_target > 0.0:
		zoom = _base_zoom * (1.0 + _punch)
		# הזום "נכנס" אל השחקן (לא אל מרכז המסך): מזיזים את המצלמה כך שהשחקן נשאר באותה נקודה במסך
		var p := get_parent() as Node2D
		if p != null:
			var center := get_screen_center_position() - (offset - base_offset)
			var focus := p.global_position + Vector2(0.0, -40.0)
			_anchor_off = (focus - center) * (1.0 - 1.0 / (1.0 + _punch))
	else:
		_anchor_off = Vector2.ZERO
		if zoom != _base_zoom:
			zoom = _base_zoom
	var shake_off := Vector2.ZERO
	if _time_left > 0.0:
		_time_left -= delta
		var k := pow(clampf(_time_left / _duration, 0.0, 1.0), decay)
		shake_off = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength * k
	var want := 0.0
	var pl := get_parent() as Node2D
	if frame_target != null and is_instance_valid(frame_target) and pl != null:
		var half_w: float = get_viewport_rect().size.x * 0.5 / maxf(zoom.x, 0.01)
		var dx: float = frame_target.global_position.x - pl.global_position.x
		var need: float = absf(dx) + frame_half + 20.0 - half_w   # כמה חסר כדי שהבוס ייכנס למסך
		if need > 0.0:
			want = signf(dx) * minf(need, half_w - 110.0)   # (השחקן נשאר על המסך)
	_frame_off = lerpf(_frame_off, want, 1.0 - exp(-3.0 * delta))
	# בעיטת ירייה: קפיץ מרוסן שחוזר ל-0
	if _kick_v != Vector2.ZERO or _kick != Vector2.ZERO:
		var dt := minf(delta, 1.0 / 30.0)
		_kick_v += (-kick_stiffness * _kick - kick_damping * _kick_v) * dt
		_kick += _kick_v * dt
		if _kick.length() > kick_max:
			_kick = _kick.limit_length(kick_max)
		if _kick.length() < 0.05 and _kick_v.length() < 2.0:
			_kick = Vector2.ZERO
			_kick_v = Vector2.ZERO
	offset = base_offset + _anchor_off + shake_off + Vector2(_frame_off, 0.0) + _kick
