extends Camera2D
# ============================================================
#  מצלמה שעוקבת אחרי השחקן ויודעת לרעוד (למשל בפיצוץ רימון).
#  נוצרת ע"י main.gd. כדי לרעוד מכל מקום במשחק:
#      get_viewport().get_camera_2d().shake(10.0, 0.3)
# ============================================================

## כמה מהר הרעידה נחלשת
@export var decay := 1.0

var _strength := 0.0
var _time_left := 0.0
var _duration := 0.0


func _ready() -> void:
	add_to_group("camera")


# strength = כמה פיקסלים המסך זז, duration = כמה שניות
func shake(strength := 8.0, duration := 0.25) -> void:
	if strength >= _strength * (_time_left / maxf(_duration, 0.001)):
		_strength = strength
		_duration = duration
		_time_left = duration


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_time_left -= delta
	var k := pow(clampf(_time_left / _duration, 0.0, 1.0), decay)
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _strength * k
