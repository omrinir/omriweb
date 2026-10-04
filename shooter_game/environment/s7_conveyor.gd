extends StaticBody2D
# ============================================================
#  S7 CONVEYOR - מסוע ריצפה (שלב 7)
#  StaticBody2D בשכבה 1 עם constant_linear_velocity: כל מי שעומד עליו
#  (שחקן / זומבים) נסחף לכיוון speed. מונח בתוך "חור" בכביש (stage_7 -> road_holes)
#  כך שהחגורה בדיוק בגובה הריצפה.
#  ציור: חגורת גומי עם פסים זזים, גלילים מסתובבים, ארגזים קטנים שנוסעים,
#  וחצים מהבהבים על הצד שמראים את הכיוון.
#  איך משנים: size (רוחב x עומק), speed (פיקסלים לשנייה, שלילי = שמאלה).
# ============================================================

const Art := preload("res://art.gd")

var size := Vector2(360, 90)
var speed := 70.0
var _t := 0.0


func _ready() -> void:
	add_to_group("s7_conveyors")
	collision_layer = 1
	collision_mask = 0
	constant_linear_velocity = Vector2(speed, 0.0)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = size * 0.5
	add_child(cs)
	z_index = 1


func _process(delta: float) -> void:
	_t += delta
	if Art.on_screen(self, global_position + Vector2(size.x * 0.5, 0.0), size.x * 0.5 + 60.0):
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var off := fposmod(_t * speed, 16.0)
	# גוף המסוע מתחת לחגורה
	draw_rect(Rect2(0, 0, w, size.y), Color("16161a"))
	draw_rect(Rect2(0, 10, w, 22), Color("34383e"))
	draw_rect(Rect2(0, 10, w, 2), Color(1, 1, 1, 0.12))
	# חצים על הצד (זזים עם החגורה)
	var dir := signf(speed)
	var ax := fposmod(_t * speed * 0.5, 48.0) - 48.0
	while ax < w:
		var c := Vector2(ax + 24.0, 21.0)
		if c.x > 8.0 and c.x < w - 8.0:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-5.0 * dir, -6), c + Vector2(5.0 * dir, 0), c + Vector2(-5.0 * dir, 6), c + Vector2(-1.0 * dir, 0)]), Color(0.85, 0.65, 0.15, 0.75))
		ax += 48.0
	# רגליים
	var lx := 30.0
	while lx < w - 20.0:
		draw_rect(Rect2(lx, 32, 8, size.y - 32), Color("24262a"))
		lx += 90.0
	# החגורה עצמה
	draw_rect(Rect2(0, 0, w, 10), Color("1e1e20"))
	var x := off - 16.0
	while x < w:
		if x > 0.0:
			draw_line(Vector2(x, 1), Vector2(x, 9), Color("38383c"), 2.0)
		x += 16.0
	draw_line(Vector2(0, 0.5), Vector2(w, 0.5), Color(0.6, 0.6, 0.65, 0.35), 1.0)
	# גלילים בקצוות (מסתובבים)
	for ex in [8.0, w - 8.0]:
		draw_circle(Vector2(ex, 6), 8.0, Color("2a2c30"))
		var a := _t * speed / 8.0
		for k in 3:
			draw_line(Vector2(ex, 6), Vector2(ex, 6) + Vector2.from_angle(a + float(k) * TAU / 3.0) * 7.0, Color("5a5e64"), 1.4)
		draw_circle(Vector2(ex, 6), 2.0, Color("8a9098"))
	# ארגזים / חלקים שנוסעים על המסוע (קישוט)
	for i in 3:
		var bx := fposmod(_t * speed + float(i) * w / 3.0, w - 40.0) + 12.0
		var bw := 16.0 + float(i % 2) * 6.0
		Art.fill_shaded(self, PackedVector2Array([Vector2(bx, -bw * 0.7), Vector2(bx + bw, -bw * 0.7), Vector2(bx + bw, 0), Vector2(bx, 0)]), Color("6a5a40") if i != 1 else Color("4a5058"), 0.2, 0.35)
		draw_line(Vector2(bx + 2, -bw * 0.35), Vector2(bx + bw - 2, -bw * 0.35), Color(0, 0, 0, 0.3), 1.0)
