extends Node2D
# ============================================================
#  עיתונים שעפים ברוח ואפר שנופל לאט מהשריפות.
#  נמצא בשכבה קבועה (CanvasLayer) - לא זז עם המצלמה.
# ============================================================

@export var papers := 7                # כמה עיתונים באוויר
@export var ash := 45                  # כמה חלקיקי אפר
@export var wind := 60.0               # רוח (שלילי = שמאלה)

var _items: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	var s := get_viewport_rect().size
	for i in papers:
		_items.append(_new_paper(s, randf() * s.x))
	for i in ash:
		_items.append(_new_ash(s, randf() * s.y))


func _new_paper(s: Vector2, x: float) -> Dictionary:
	return {"type": 0, "pos": Vector2(x, randf_range(s.y * 0.45, s.y * 0.85)), "vel": Vector2(randf_range(40.0, 120.0), 0.0),
		"rot": randf() * TAU, "spin": randf_range(-4.0, 4.0), "flip": randf() * TAU, "size": randf_range(6.0, 10.0),
		"phase": randf() * TAU, "shade": randf_range(0.7, 0.9)}


func _new_ash(s: Vector2, y: float) -> Dictionary:
	return {"type": 1, "pos": Vector2(randf() * s.x, y), "speed": randf_range(12.0, 35.0), "size": randf_range(0.8, 2.0),
		"phase": randf() * TAU, "glow": randf() < 0.15}


func _process(delta: float) -> void:
	_t += delta
	var s := get_viewport_rect().size
	var gust := 1.0 + 0.8 * maxf(0.0, sin(_t * 0.35))   # משבי רוח
	for i in _items.size():
		var it: Dictionary = _items[i]
		var pos: Vector2 = it["pos"]
		if it["type"] == 0:
			var vel: Vector2 = it["vel"]
			it["phase"] += delta * 2.0
			pos += Vector2(vel.x * gust * (wind / 60.0), sin(it["phase"]) * 40.0) * delta
			it["rot"] += it["spin"] * delta * gust
			it["flip"] += delta * 5.0
			if pos.x > s.x + 30.0:
				_items[i] = _new_paper(s, -30.0)
				continue
		else:
			it["phase"] += delta
			pos += Vector2(wind * 0.3 * gust + sin(it["phase"]) * 10.0, it["speed"]) * delta
			if pos.y > s.y + 5.0 or pos.x > s.x + 5.0:
				_items[i] = _new_ash(s, -5.0)
				continue
		it["pos"] = pos
	queue_redraw()


func _draw() -> void:
	for it in _items:
		var pos: Vector2 = it["pos"]
		if it["type"] == 0:
			# עיתון: מלבן שמתהפך (מסתובב גם "לעומק")
			var sz: float = it["size"]
			var fl := absf(cos(float(it["flip"]))) * 0.8 + 0.2
			var xf := Transform2D(float(it["rot"]), Vector2(1.0, fl), 0.0, pos)
			var pts := xf * PackedVector2Array([Vector2(-sz, -sz * 0.7), Vector2(sz, -sz * 0.7), Vector2(sz, sz * 0.7), Vector2(-sz, sz * 0.7)])
			var c: float = it["shade"]
			draw_colored_polygon(pts, Color(c, c * 0.97, c * 0.9, 0.9))
			# שורות טקסט
			for k in 3:
				var y := -sz * 0.4 + float(k) * sz * 0.35
				draw_line(xf * Vector2(-sz * 0.7, y), xf * Vector2(sz * 0.7, y), Color(0.2, 0.2, 0.2, 0.5), 0.8)
		else:
			var col := Color(1.0, 0.55, 0.2, 0.8) if it["glow"] else Color(0.55, 0.52, 0.5, 0.6)
			draw_circle(pos, float(it["size"]), col)
