extends Node2D
# ============================================================
#  רקע: שמיים של שקיעה, כוכבים, שמש, עננים והרים.
#  הכל מצויר בקוד. אפשר לשנות צבעים ומיקומים כאן.
# ============================================================

@export var sky_top := Color("2a2468")
@export var sky_mid := Color("b2517e")
@export var sky_bottom := Color("ffb878")
@export var sun_color := Color("fff0b8")
@export var sun_pos := Vector2(0.78, 0.58)   # יחסי למסך (0..1)
@export var sun_radius := 62.0
@export var far_mountains := Color("7a5a9a")
@export var mid_mountains := Color("523b7c")
@export var near_hills := Color("2f2352")


func _draw() -> void:
	var s := get_viewport_rect().size
	# שמיים (שני פסי גרדיאנט)
	_gradient(0.0, s.y * 0.5, s.x, sky_top, sky_mid)
	_gradient(s.y * 0.5, s.y, s.x, sky_mid, sky_bottom)
	# כוכבים
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		var p := Vector2(rng.randf() * s.x, rng.randf() * s.y * 0.4)
		draw_circle(p, rng.randf_range(0.6, 1.6), Color(1, 1, 1, rng.randf_range(0.25, 0.8)))
	# שמש
	var sp := Vector2(s.x * sun_pos.x, s.y * sun_pos.y)
	for i in 5:
		draw_circle(sp, sun_radius + float(5 - i) * 28.0, Color(1.0, 0.85, 0.6, 0.05))
	draw_circle(sp, sun_radius, sun_color)
	# עננים
	_cloud(Vector2(s.x * 0.18, s.y * 0.22), 1.0)
	_cloud(Vector2(s.x * 0.52, s.y * 0.14), 0.7)
	_cloud(Vector2(s.x * 0.86, s.y * 0.30), 0.9)
	# הרים (רחוק -> קרוב)
	_ridge(s, s.y * 0.66, 70.0, 0.006, 0.5, far_mountains)
	_ridge(s, s.y * 0.74, 55.0, 0.009, 2.0, mid_mountains)
	_ridge(s, s.y * 0.82, 38.0, 0.013, 4.0, near_hills)


func _gradient(y0: float, y1: float, w: float, c0: Color, c1: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, y1), Vector2(0, y1)]),
		PackedColorArray([c0, c0, c1, c1]))


func _cloud(c: Vector2, k: float) -> void:
	var col := Color(1.0, 0.82, 0.85, 0.32)
	draw_circle(c, 26.0 * k, col)
	draw_circle(c + Vector2(30, 6) * k, 32.0 * k, col)
	draw_circle(c + Vector2(66, 10) * k, 24.0 * k, col)
	draw_circle(c + Vector2(30, 18) * k, 26.0 * k, col)


func _ridge(s: Vector2, base_y: float, amp: float, freq: float, phase: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= s.x + 16.0:
		var h := amp * (0.5 + 0.5 * sin(x * freq + phase)) + amp * 0.4 * sin(x * freq * 2.3 + phase * 1.7)
		pts.append(Vector2(x, base_y - h))
		x += 16.0
	pts.append(Vector2(s.x + 16.0, s.y))
	pts.append(Vector2(0.0, s.y))
	draw_colored_polygon(pts, col)
