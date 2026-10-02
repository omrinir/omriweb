extends Node2D
# ============================================================
#  לבבות חיים, הנשק הנוכחי והודעת GAME OVER.
#  נוצר ע"י main.gd בתוך CanvasLayer (לא זז עם המצלמה).
# ============================================================

const Art := preload("res://art.gd")

var hearts_pos := Vector2(24, 46)
var heart_gap := 30.0

var _health := 5
var _max := 5
var _weapon := 0
var _game_over := false
var _pulse := 0.0
var difficulty := ""
var difficulty_color := Color.WHITE


func set_health(h: int, m: int) -> void:
	if h < _health:
		_pulse = 0.4
	_health = h
	_max = m
	queue_redraw()


func set_weapon(w: int) -> void:
	_weapon = w
	queue_redraw()


func show_game_over() -> void:
	_game_over = true
	queue_redraw()


func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse -= delta
		queue_redraw()


func _heart(c: Vector2, s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 28:
		var t := TAU * float(i) / 28.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(c + Vector2(x, y) * s)
	return pts


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in _max:
		var c := hearts_pos + Vector2(float(i) * heart_gap, 0.0)
		var full := i < _health
		var s := 0.62
		if full and i == _health - 1 and _pulse > 0.0:
			s *= 1.0 + _pulse * 0.5
		if full:
			Art.fill(self, _heart(c, s), Color("e0283a"), Color(0.1, 0.0, 0.0, 0.9), 2.0)
			Art.oval(self, c + Vector2(-4.5, -4.0), 2.6, 1.8, Color(1, 1, 1, 0.45), -0.6, Art.NONE)
		else:
			Art.fill(self, _heart(c, s), Color(0.15, 0.05, 0.07, 0.6), Color(0.6, 0.6, 0.6, 0.6), 1.5)
	var wname := "RIFLE" if _weapon == 0 else "GRENADE"
	var tx := hearts_pos + Vector2(float(_max) * heart_gap, 6.0)
	draw_string_outline(font, tx, wname, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.7))
	draw_string(font, tx, wname, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if difficulty != "":
		var dx := tx + Vector2(110, 0)
		draw_string_outline(font, dx, difficulty, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.7))
		draw_string(font, dx, difficulty, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, difficulty_color)
	if _game_over:
		var s := get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.55))
		draw_string_outline(font, Vector2(0, s.y / 2.0), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, s.x, 64, 8, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(0, s.y / 2.0), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, s.x, 64, Color("ff4040"))

