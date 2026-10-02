extends Node2D
# ============================================================
#  ערפל נמוך שזז לאט על הכביש (מצויר מעל העולם, מתחת ל-HUD).
# ============================================================

@export var color := Color(0.75, 0.68, 0.62)
@export var strength := 0.09
var y_screen := 600.0   # גובה הערפל על המסך (main.gd קובע)
var _t := 0.0
var _blobs := []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 16:
		_blobs.append([rng.randf_range(0.0, 1.0), rng.randf_range(-30.0, 25.0), rng.randf_range(90.0, 200.0), rng.randf_range(0.6, 1.4)])


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	var cx := cam.get_screen_center_position().x if cam != null else 0.0
	var span := s.x + 400.0
	for b in _blobs:
		var x := fposmod(float(b[0]) * span - cx * 1.15 + _t * 12.0 * float(b[3]), span) - 200.0
		var y := y_screen + float(b[1]) + sin(_t * 0.4 + float(b[0]) * 9.0) * 4.0
		var r: float = b[2]
		draw_colored_polygon(_ellipse(Vector2(x, y), r, r * 0.22), Color(color, strength))


func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * float(i) / 18.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
