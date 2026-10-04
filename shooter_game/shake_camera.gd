extends Camera2D
# ============================================================
#  מצלמה שעוקבת אחרי השחקן ויודעת לרעוד (למשל בפיצוץ רימון).
#  נוצרת ע"י main.gd. כדי לרעוד מכל מקום במשחק:
#      get_viewport().get_camera_2d().shake(10.0, 0.3)
#  "זום קטן" (למשל בקפיצה):  ...get_camera_2d().punch_zoom(0.03)
#  (0.03 = 3% זום פנימה, נכנס בעדינות ודועך חזרה לזום הרגיל)
# ============================================================

## כמה מהר הזום הקטן נכנס / דועך חזרה
@export var punch_in_speed := 18.0
@export var punch_out_speed := 3.0
# ============================================================

## כמה מהר הרעידה נחלשת
@export var decay := 1.0

var _strength := 0.0
var _time_left := 0.0
var _duration := 0.0
var _base_zoom := Vector2.ONE
var _punch_target := 0.0
var _punch := 0.0


func _ready() -> void:
	add_to_group("camera")
	_base_zoom = zoom


# amount = כמה זום להוסיף (0.03 = 3%). זום חזק יותר דורס חלש יותר
func punch_zoom(amount: float) -> void:
	_punch_target = maxf(_punch_target, amount)


# strength = כמה פיקסלים המסך זז, duration = כמה שניות
func shake(strength := 8.0, duration := 0.25) -> void:
	if strength >= _strength * (_time_left / maxf(_duration, 0.001)):
		_strength = strength
		_duration = duration
		_time_left = duration


func _process(delta: float) -> void:
	# זום קטן: נכנס מהר אל היעד, והיעד דועך חזרה לאפס
	_punch = lerpf(_punch, _punch_target, 1.0 - exp(-punch_in_speed * delta))
	_punch_target *= exp(-punch_out_speed * delta)
	if _punch_target < 0.0005:
		_punch_target = 0.0
	if _punch > 0.0005 or _punch_target > 0.0:
		zoom = _base_zoom * (1.0 + _punch)
	elif zoom != _base_zoom:
		zoom = _base_zoom
	if _time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_time_left -= delta
	var k := pow(clampf(_time_left / _duration, 0.0, 1.0), decay)
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength * k
