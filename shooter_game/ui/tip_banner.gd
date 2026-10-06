extends CanvasLayer
# ============================================================
#  TIP BANNER - טיפ קצר על המסך (למשל בשלבים חשוכים: "TIP: USE YOUR FLASHLIGHT").
#  מופיע אחרי delay שניות, נשאר seconds שניות (נכנס ויוצא בהדרגה), ואז נעלם.
#  main.gd מוסיף אותו כשהשלב חשוך (Game.is_night / is_subway / stage.dark_level()).
# ============================================================

const Monologue := preload("res://ui/monologue.gd")

var text := "TIP: USE YOUR FLASHLIGHT"
var sub := ""
var delay := 4.5
var seconds := 4.0
var _t := 0.0
var _ui: Node2D


func _ready() -> void:
	layer = 5
	_ui = Node2D.new()
	add_child(_ui)
	_ui.draw.connect(_draw_tip)


func _process(delta: float) -> void:
	_t += delta
	if _t > delay + seconds + 0.5:
		queue_free()
		return
	_ui.queue_redraw()


func _draw_tip() -> void:
	var k := _t - delay
	if k < 0.0 or k > seconds:
		return
	var a := clampf(k / 0.35, 0.0, 1.0) * clampf((seconds - k) / 0.5, 0.0, 1.0)
	var vs := _ui.get_viewport().get_visible_rect().size
	var f := Monologue.font()
	var fs := 30
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var sw := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x if sub != "" else 0.0
	var bw := maxf(w, sw) + 48.0
	var bh := 52.0 + (24.0 if sub != "" else 0.0)
	var c := Vector2(vs.x * 0.5, vs.y * 0.74 + (1.0 - clampf(k / 0.35, 0.0, 1.0)) * 14.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.07, 0.8 * a)
	sb.border_color = Color(1.0, 0.9, 0.62, a)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	_ui.draw_style_box(sb, Rect2(c.x - bw * 0.5, c.y - bh * 0.5, bw, bh))
	var tp := Vector2(c.x - w * 0.5, c.y - bh * 0.5 + 38.0)
	f.draw_string_outline(_ui.get_canvas_item(), tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, a))
	f.draw_string(_ui.get_canvas_item(), tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.93, 0.7, a))
	if sub != "":
		var sp := Vector2(c.x - sw * 0.5, tp.y + 24.0)
		f.draw_string(_ui.get_canvas_item(), sp, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85, 0.85, 0.9, 0.9 * a))
