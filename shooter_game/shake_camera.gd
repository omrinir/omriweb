extends Camera2D
# ============================================================
#  מצלמה שעוקבת אחרי השחקן ויודעת לרעוד (למשל בפיצוץ רימון).
#  נוצרת ע"י main.gd. כדי לרעוד מכל מקום במשחק:
#      get_viewport().get_camera_2d().shake(10.0, 0.3)
#  "זום קטן" (למשל בקפיצה):  ...get_camera_2d().punch_zoom(0.03)
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


func _ready() -> void:
	add_to_group("camera")
	_base_zoom = zoom


# amount = כמה זום להוסיף (0.03 = 3%). זום חזק יותר דורס חלש יותר
func punch_zoom(amount: float) -> void:
	if amount >= _punch_target:
		_punch_target = amount
		_punch_hold_t = punch_hold


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
	offset = base_offset + _anchor_off + shake_off
