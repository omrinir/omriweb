extends Control
# ============================================================
#  VOLUME SLIDERS - שני סרגלים: MUSIC ו-SOUND FX (0-100%).
#  משנים את ערוצי השמע "Music" / "SFX" דרך Settings (נשמר בקובץ settings.cfg).
#  בשימוש בתפריט ההשהיה (ESC) ובתפריט הראשי. position = הפינה השמאלית-עליונה.
# ============================================================
const Sfx := preload("res://sfx.gd")

var width := 280.0
var _sl := {}
var _lbl := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(width, 80)
	var y := 0.0
	for kind in ["music", "sfx"]:
		var l := Label.new()
		l.position = Vector2(0, y)
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", Color(0.9, 0.86, 0.8))
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		add_child(l)
		_lbl[kind] = l
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 100.0
		s.step = 1.0
		s.position = Vector2(110, y + 2)
		s.size = Vector2(width - 110.0, 20)
		s.value = (Settings.music_volume if kind == "music" else Settings.sfx_volume) * 100.0
		s.focus_mode = Control.FOCUS_NONE
		s.value_changed.connect(_changed.bind(kind))
		add_child(s)
		_sl[kind] = s
		_update_label(kind)
		y += 34.0


func _changed(v: float, kind: String) -> void:
	Settings.set_volume(kind, v / 100.0)
	_update_label(kind)
	if kind == "sfx":
		Sfx.play("ui", null)   # שומעים מיד כמה חזק


func _update_label(kind: String) -> void:
	var v := int(_sl[kind].value) if _sl.has(kind) else 0
	_lbl[kind].text = ("MUSIC  " if kind == "music" else "SOUND FX  ") + "%d%%" % v
