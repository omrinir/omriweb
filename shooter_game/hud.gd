extends Node2D
# ============================================================
#  בר חיים, הנשק הנוכחי והודעת GAME OVER.
#  נוצר ע"י main.gd בתוך CanvasLayer (לא זז עם המצלמה).
# ============================================================

var bar_pos := Vector2(12, 34)
var bar_size := Vector2(220, 16)

var _health := 10
var _max := 10
var _weapon := 0
var _game_over := false


func set_health(h: int, m: int) -> void:
	_health = h
	_max = m
	queue_redraw()


func set_weapon(w: int) -> void:
	_weapon = w
	queue_redraw()


func show_game_over() -> void:
	_game_over = true
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var k := clampf(float(_health) / float(maxi(_max, 1)), 0.0, 1.0)
	draw_rect(Rect2(bar_pos - Vector2(2, 2), bar_size + Vector2(4, 4)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(bar_pos, bar_size), Color("4a1010"))
	draw_rect(Rect2(bar_pos, Vector2(bar_size.x * k, bar_size.y)), Color("d03030").lerp(Color("40c040"), k))
	draw_string(font, bar_pos + Vector2(6, 13), "HP %d/%d" % [_health, _max], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	var wname := "GUN" if _weapon == 0 else "GRENADE"
	draw_string(font, bar_pos + Vector2(bar_size.x + 14, 13), "Weapon: " + wname, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	if _game_over:
		var s := get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.55))
		draw_string(font, Vector2(0, s.y / 2.0), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, s.x, 64, Color("ff4040"))
		draw_string(font, Vector2(0, s.y / 2.0 + 50), "press R to restart", HORIZONTAL_ALIGNMENT_CENTER, s.x, 22, Color.WHITE)
