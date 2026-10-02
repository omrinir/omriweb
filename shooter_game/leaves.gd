extends Node2D
# ============================================================
#  עלים שנופלים לאט על המסך ומתנדנדים ברוח.
#  נמצא בשכבה קבועה (CanvasLayer) - העלים לא זזים עם המצלמה.
#  אפשר לשנות כמות, צבעים ומהירות כאן.
# ============================================================

@export var count := 28                    # כמה עלים יש על המסך
@export var fall_speed := Vector2(20.0, 45.0)   # מהירות נפילה (מינימום, מקסימום)
@export var wind := 18.0                   # רוח קבועה ימינה (שלילי = שמאלה)
@export var colors: Array[Color] = [Color("d9822b"), Color("c4512f"), Color("e0b040"), Color("8a6a2a")]

var _leaves: Array[Dictionary] = []


func _ready() -> void:
	var s := get_viewport_rect().size
	for i in count:
		_leaves.append(_new_leaf(s, randf() * s.y))


func _new_leaf(s: Vector2, y: float) -> Dictionary:
	return {
		"pos": Vector2(randf() * s.x, y),
		"speed": randf_range(fall_speed.x, fall_speed.y),
		"sway": randf_range(15.0, 40.0),     # כמה רחוק העלה מתנדנד לצדדים
		"phase": randf() * TAU,
		"freq": randf_range(1.0, 2.2),
		"rot": randf() * TAU,
		"spin": randf_range(-2.0, 2.0),
		"size": randf_range(3.0, 6.0),
		"color": colors[randi() % colors.size()],
	}


func _process(delta: float) -> void:
	var s := get_viewport_rect().size
	for i in _leaves.size():
		var l: Dictionary = _leaves[i]
		var pos: Vector2 = l["pos"]
		l["phase"] += l["freq"] * delta
		pos.y += l["speed"] * delta
		pos.x += (wind + cos(l["phase"]) * l["sway"]) * delta
		l["rot"] += l["spin"] * delta
		if pos.x > s.x + 10.0:
			pos.x = -10.0
		elif pos.x < -10.0:
			pos.x = s.x + 10.0
		l["pos"] = pos
		if pos.y > s.y + 10.0:   # יצא מלמטה - חוזר למעלה
			_leaves[i] = _new_leaf(s, -10.0)
	queue_redraw()


func _draw() -> void:
	for l in _leaves:
		var sz: float = l["size"]
		var pts := PackedVector2Array([
			Vector2(-sz, 0.0), Vector2(0.0, -sz * 0.5), Vector2(sz, 0.0), Vector2(0.0, sz * 0.5)
		])
		var xf := Transform2D(float(l["rot"]), Vector2(l["pos"]))
		draw_colored_polygon(xf * pts, l["color"])
