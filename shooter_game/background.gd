extends Node2D
# ============================================================
#  רקע: עיר הרוסה אחרי שהזומבים השתלטו.
#  שמיים מעושנים, שמש אדומה, עמודי עשן, ובניינים שבורים
#  בכמה שכבות שזזות במהירויות שונות (פרלקסה) - נוצר עומק.
#  main.gd קובע את level_w לפני שהרקע נוצר.
# ============================================================

@export var sky_top := Color("1c1820")
@export var sky_mid := Color("47302f")
@export var sky_bottom := Color("b8663a")
@export var sun_color := Color("e8603a")
@export var sun_pos := Vector2(0.72, 0.5)   # יחסי למסך (0..1)

var level_w := 10240.0
var _layers: Array[Node2D] = []
var _factors: Array[float] = []


func _ready() -> void:
	var s := get_viewport_rect().size
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	# שכבה רחוקה (זזה לאט), אמצעית, וקרובה (זזה הכי מהר)
	_add_layer(rng, 0.08, Color("5c4048"), 230.0, 380.0, 40.0, 110.0, s.y * 0.86, false, true)
	_add_layer(rng, 0.18, Color("3e2d33"), 150.0, 300.0, 60.0, 140.0, s.y * 0.9, true, false)
	_add_layer(rng, 0.32, Color("261c22"), 90.0, 230.0, 80.0, 170.0, s.y * 0.95, true, false)


func _add_layer(rng: RandomNumberGenerator, factor: float, col: Color, h_min: float, h_max: float,
		w_min: float, w_max: float, base_y: float, windows: bool, smoke: bool) -> void:
	var s := get_viewport_rect().size
	var layer := Node2D.new()
	add_child(layer)
	_layers.append(layer)
	_factors.append(factor)
	var total := level_w * factor + s.x + 200.0
	# מחלקים לחתיכות של 1024 פיקסלים - כך מציירים רק את מה שעל המסך
	var x := -100.0
	var chunk: Node2D = null
	var chunk_end := -INF
	while x < total:
		if x >= chunk_end:
			chunk = Skyline.new()
			chunk.color = col
			chunk.windows = windows
			chunk.base_y = base_y
			layer.add_child(chunk)
			chunk_end = x + 1024.0
		var w := rng.randf_range(w_min, w_max)
		var h := rng.randf_range(h_min, h_max)
		chunk.buildings.append([x, w, h, rng.randi()])
		if rng.randf() < 0.18 and windows:   # עמוד חשמל עם כבלים
			chunk.poles.append(x + w + rng.randf_range(5.0, 20.0))
		if smoke and rng.randf() < 0.12:     # עמוד עשן משריפה
			var sm := SmokeColumn.new()
			sm.position = Vector2(x + w * 0.5, base_y - h)
			sm.seed_offset = rng.randf() * 10.0
			layer.add_child(sm)
		x += w + rng.randf_range(-10.0, 30.0)
	# ערפל אובך מעל השכבה (מרחיק אותה)
	var haze := Haze.new()
	haze.base_y = base_y
	haze.strength = 0.28 if factor < 0.1 else (0.18 if factor < 0.2 else 0.1)
	add_child(haze)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var cx := cam.get_screen_center_position().x
	for i in _layers.size():
		_layers[i].position.x = -cx * _factors[i]


func _draw() -> void:
	var s := get_viewport_rect().size
	_gradient(0.0, s.y * 0.55, s.x, sky_top, sky_mid)
	_gradient(s.y * 0.55, s.y, s.x, sky_mid, sky_bottom)
	# שמש אדומה דרך העשן
	var sp := Vector2(s.x * sun_pos.x, s.y * sun_pos.y)
	for i in 6:
		draw_circle(sp, 50.0 + float(6 - i) * 30.0, Color(0.95, 0.4, 0.2, 0.045))
	draw_circle(sp, 46.0, Color(sun_color, 0.85))
	# פסי עשן על השמש
	for i in 3:
		var y := sp.y - 20.0 + float(i) * 18.0
		draw_rect(Rect2(sp.x - 80.0, y, 160.0, 5.0 + float(i) * 2.0), Color(0.25, 0.17, 0.17, 0.35))
	# עננים כבדים של עשן למעלה
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 18:
		var c := Vector2(rng.randf() * s.x, rng.randf_range(10.0, s.y * 0.3))
		var rx := rng.randf_range(90.0, 220.0)
		var pts := PackedVector2Array()
		for k in 20:
			var a := TAU * float(k) / 20.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * rx * 0.28))
		draw_colored_polygon(pts, Color(0.1, 0.08, 0.09, 0.12))


func _gradient(y0: float, y1: float, w: float, c0: Color, c1: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, y1), Vector2(0, y1)]),
		PackedColorArray([c0, c0, c1, c1]))


# ---- חתיכה של קו רקיע: בניינים שבורים ----
class Skyline extends Node2D:
	var color := Color.BLACK
	var windows := false
	var base_y := 600.0
	var buildings := []   # [x, רוחב, גובה, seed]
	var poles := []

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		for b in buildings:
			var x: float = b[0]
			var w: float = b[1]
			var h: float = b[2]
			rng.seed = b[3]
			var top := base_y - h
			# גג שבור: שיניים ומדרגות אקראיות
			var pts := PackedVector2Array([Vector2(x, base_y + 200.0), Vector2(x, top + rng.randf_range(0.0, 30.0))])
			# גג שבור: מדרגות של קומות שקרסו (ולפעמים שבר באלכסון)
			var steps := rng.randi_range(2, 4)
			var level := top
			for i in steps:
				var px := x + w * float(i + 1) / float(steps + 1)
				if rng.randf() < 0.5:
					level = top + rng.randf_range(0.0, h * 0.18)
					pts.append(Vector2(px - rng.randf_range(0.0, 6.0), pts[pts.size() - 1].y))
				pts.append(Vector2(px, level))
			pts.append(Vector2(x + w, top + rng.randf_range(0.0, 40.0)))
			pts.append(Vector2(x + w, base_y + 200.0))
			draw_colored_polygon(pts, color)
			# ברזלים שבולטים מהגג השבור
			for i in rng.randi_range(0, 3):
				var rx := x + rng.randf_range(4.0, w - 4.0)
				var ry := top + rng.randf_range(8.0, h * 0.3)
				draw_line(Vector2(rx, ry + 6.0), Vector2(rx + rng.randf_range(-6.0, 6.0), ry - rng.randf_range(8.0, 18.0)), color.darkened(0.2), 1.5, true)
			if rng.randf() < 0.2:   # אנטנה
				draw_line(Vector2(x + w * 0.3, top), Vector2(x + w * 0.32, top - rng.randf_range(20.0, 45.0)), color, 2.0, true)
			if windows:
				var win := color.lightened(0.08)
				var ww := 6.0 if w < 110.0 else 8.0
				var row := top + 40.0
				while row < base_y - 10.0:
					var col_x := x + 8.0
					while col_x < x + w - ww - 4.0:
						var r := rng.randf()
						if r < 0.06:     # חלון עם אש
							draw_rect(Rect2(col_x, row, ww, 9.0), Color(0.95, 0.45, 0.15, 0.85))
							draw_circle(Vector2(col_x + ww / 2.0, row + 4.0), 9.0, Color(1.0, 0.5, 0.2, 0.12))
						elif r < 0.55:   # חלון שבור / כהה
							draw_rect(Rect2(col_x, row, ww, 9.0), win if r < 0.4 else color.darkened(0.3))
						col_x += ww + 6.0
					row += 17.0
				# חור גדול בקיר
				if rng.randf() < 0.35:
					var hc := Vector2(x + rng.randf_range(w * 0.2, w * 0.8), top + rng.randf_range(h * 0.3, h * 0.7))
					var hole := PackedVector2Array()
					for i in 9:
						var a := TAU * float(i) / 9.0
						hole.append(hc + Vector2(cos(a), sin(a)) * rng.randf_range(10.0, 22.0))
					draw_colored_polygon(hole, color.darkened(0.45))
		# עמודי חשמל וכבלים שמשתלשלים
		for i in poles.size():
			var px: float = poles[i]
			var ph := base_y - 120.0
			draw_line(Vector2(px, base_y + 50.0), Vector2(px + 3.0, ph), color.darkened(0.15), 4.0, true)
			draw_line(Vector2(px - 14.0, ph + 8.0), Vector2(px + 18.0, ph + 4.0), color.darkened(0.15), 3.0, true)
			if i + 1 < poles.size() and float(poles[i + 1]) - px < 600.0:
				var nx: float = poles[i + 1]
				for k in 2:
					var a := Vector2(px - 10.0 + float(k) * 24.0, ph + 7.0)
					var b := Vector2(nx - 10.0 + float(k) * 24.0, ph + 7.0)
					var cable := PackedVector2Array()
					for j in 13:
						var t := float(j) / 12.0
						cable.append(a.lerp(b, t) + Vector2(0.0, sin(t * PI) * 30.0))
					draw_polyline(cable, Color(0.05, 0.03, 0.05, 0.8), 1.2, true)
			else:   # כבל קרוע שמשתלשל
				draw_polyline(PackedVector2Array([Vector2(px + 14.0, ph + 6.0), Vector2(px + 24.0, ph + 30.0), Vector2(px + 20.0, ph + 60.0)]), Color(0.05, 0.03, 0.05, 0.8), 1.2, true)


# ---- עמוד עשן משריפה רחוקה ----
class SmokeColumn extends Node2D:
	var seed_offset := 0.0
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 14.0, Color(1.0, 0.45, 0.15, 0.25))   # האש למטה
		for i in 14:
			var k := fmod(float(i) / 14.0 + (t + seed_offset) * 0.04, 1.0)
			var y := -k * 260.0
			var x := k * k * 90.0 + sin(k * 6.0 + t * 0.5 + seed_offset) * 8.0
			var r := 10.0 + k * 38.0
			var a := 0.35 * (1.0 - k) * clampf(k * 8.0, 0.0, 1.0)
			draw_circle(Vector2(x, y), r, Color(0.16, 0.12, 0.13, a))


# ---- אובך (ערפל) בין השכבות ----
class Haze extends Node2D:
	var base_y := 600.0
	var strength := 0.2

	func _draw() -> void:
		var s := get_viewport_rect().size
		var c0 := Color(0.72, 0.4, 0.25, 0.0)
		var c1 := Color(0.72, 0.4, 0.25, strength)
		draw_polygon(PackedVector2Array([Vector2(0, base_y - 260.0), Vector2(s.x, base_y - 260.0), Vector2(s.x, s.y), Vector2(0, s.y)]),
			PackedColorArray([c0, c0, c1, c1]))
