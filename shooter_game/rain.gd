extends Node2D
# ============================================================
#  גשם + ברקים (שלב לילה). מצויר על המסך, מעל העולם.
# ============================================================
const Sfx := preload("res://sfx.gd")

var _drops := []
var _flash := 0.0
var _next := 6.0


func _ready() -> void:
	for i in 170:
		_drops.append([randf() * 1400.0, randf() * 760.0, randf_range(700.0, 1000.0), randf_range(10.0, 20.0)])


func _process(delta: float) -> void:
	for d in _drops:
		d[1] += d[2] * delta
		d[0] -= d[2] * 0.22 * delta
		if d[1] > 740.0:
			d[1] = -20.0
			d[0] = randf() * 1400.0
	_flash = maxf(_flash - delta * 2.5, 0.0)
	_next -= delta
	if _next <= 0.0:   # ברק + רעם
		_next = randf_range(8.0, 16.0)
		_flash = 1.0
		Sfx.play("thunder", null, 0.0, 0.15)
	queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	for d in _drops:
		var p := Vector2(d[0], d[1])
		draw_line(p, p + Vector2(-d[3] * 0.22, d[3]), Color(0.7, 0.78, 0.9, 0.35), 1.0)
	if _flash > 0.0:
		var a := _flash * (0.55 if int(_flash * 20.0) % 3 != 0 else 0.2)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.85, 0.9, 1.0, a * 0.5))
