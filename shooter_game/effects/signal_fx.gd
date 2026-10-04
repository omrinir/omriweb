extends Node2D
# ============================================================
#  טבעת "קריאה" של זומבי (תקשורת / פקודה): טבעת שמתרחבת + טקסט קטן.
#  ai/squad_director.gd יוצר אותה. text = "!" / "?" / "FLANK"...
# ============================================================
var text := "!"
var color := Color(1.0, 0.45, 0.3)
var _t := 0.0
const LIFE := 1.1


func _ready() -> void:
	z_index = 20


func _process(delta: float) -> void:
	_t += delta
	if _t > LIFE:
		queue_free()
		return
	position.y -= 14.0 * delta
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var a := 1.0 - k
	for i in 2:
		var r := 8.0 + (k + float(i) * 0.25) * 40.0
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(color, 0.5 * a * (1.0 - float(i) * 0.4)), 1.6, true)
	var f := ThemeDB.fallback_font
	var fs := 13 if text.length() > 2 else 20
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string_outline(f, Vector2(-w * 0.5, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.8 * a))
	draw_string(f, Vector2(-w * 0.5, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(color, a))
