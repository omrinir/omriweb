extends AnimatableBody2D
# ============================================================
#  S7 LIFT - מעלית משא פתוחה (שלב 7)
#  משטח one-way (שכבה 16, כמו קומה) שנוסע למעלה ולמטה בין low_y ל-high_y,
#  מחכה wait שניות בכל קצה. AnimatableBody2D "סוחב" את מי שעומד עליו (שחקן / זומבים).
#  נמצא בקבוצה "platforms" (עם world_rect) - כך אפשר לרדת ממנו (S+W) וזומבים
#  ו-LEAPER מזהים אותו כקומה.
#  * position.x = הקצה השמאלי, low_y / high_y = גובה המשטח (עולם).
#  * Shaft (למטה) = פיר המעלית: מסילות, גלגלת וכבלים - מצויר פעם אחת מאחור.
#  איך משנים: width, low_y, high_y, wait, travel (שניות לנסיעה).
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")

var width := 110.0
var low_y := 630.0
var high_y := 330.0
var wait := 1.6
var travel := 2.6
var _t := 0.0
var _moving := false
var _prev_moving := false


func _ready() -> void:
	add_to_group("platforms")
	add_to_group("s7_lifts")
	collision_layer = 16
	collision_mask = 0
	sync_to_physics = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(width, 8.0)
	cs.shape = r
	cs.position = Vector2(width * 0.5, 4.0)
	cs.one_way_collision = true
	cs.one_way_collision_margin = 8.0
	add_child(cs)
	position.y = low_y
	z_index = 1


func world_rect() -> Rect2:
	return Rect2(global_position, Vector2(width, 10.0))


# 0 = למטה, 1 = למעלה (תנועה רכה)
func _level_k() -> float:
	var cyc := 2.0 * (wait + travel)
	var c := fposmod(_t, cyc)
	var k := 0.0
	if c < wait:
		k = 0.0
	elif c < wait + travel:
		k = (c - wait) / travel
	elif c < 2.0 * wait + travel:
		k = 1.0
	else:
		k = 1.0 - (c - 2.0 * wait - travel) / travel
	_moving = k > 0.0 and k < 1.0
	return k * k * (3.0 - 2.0 * k)


func _physics_process(delta: float) -> void:
	_t += delta
	position.y = lerpf(low_y, high_y, _level_k())
	if _moving and not _prev_moving and Art.on_screen(self, global_position):
		Sfx.play("s7_lift", global_position, -6.0, 0.05, 2)
	_prev_moving = _moving
	if Art.on_screen(self, global_position + Vector2(width * 0.5, 0.0), 200.0):
		queue_redraw()


func _draw() -> void:
	var w := width
	# כבלים עד הגלגלת (מעל הקצה העליון)
	var top := high_y - position.y - 70.0
	draw_line(Vector2(10, 0), Vector2(10, top), Color("1a1a1c"), 2.0)
	draw_line(Vector2(w - 10, 0), Vector2(w - 10, top), Color("1a1a1c"), 2.0)
	# משטח עם פסי אזהרה בקצוות
	Art.fill_shaded(self, PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 10), Vector2(0, 10)]), Color("464a50"), 0.25, 0.4)
	var x := 0.0
	while x < w:
		draw_line(Vector2(x, 1), Vector2(x + 5, 9), Color("2e3136"), 1.0)
		x += 7.0
	for ex in [0.0, w - 12.0]:
		for k in 3:
			draw_rect(Rect2(ex + float(k) * 4.0, 0, 2.0, 10.0), Color("b8901c"))
	draw_line(Vector2(0, 0), Vector2(w, 0), Color(0.8, 0.85, 0.9, 0.4), 1.0)
	# מעקה צד (רק ויזואלי) + נורה מהבהבת בזמן נסיעה
	draw_line(Vector2(2, 0), Vector2(2, -26), Color("30333a"), 2.0)
	draw_line(Vector2(w - 2, 0), Vector2(w - 2, -26), Color("30333a"), 2.0)
	draw_line(Vector2(2, -26), Vector2(18, -26), Color("30333a"), 2.0)
	draw_line(Vector2(w - 18, -26), Vector2(w - 2, -26), Color("30333a"), 2.0)
	var lamp := Color(1.0, 0.6, 0.15) if _moving and fmod(_t * 4.0, 1.0) < 0.5 else Color(0.3, 0.2, 0.1)
	draw_circle(Vector2(w - 2, -30), 3.0, lamp)
	if _moving:
		Art.glow(self, Vector2(w - 2, -30), 12.0, Color(1.0, 0.6, 0.15, 0.5))


# פיר המעלית: מסילות, קורות וגלגלת למעלה (סטטי, z מאחור)
class Shaft extends Node2D:
	var width := 110.0
	var low_y := 630.0
	var high_y := 330.0

	func _ready() -> void:
		z_index = -2

	func _draw() -> void:
		var top := high_y - low_y - 90.0   # יחסי ל-position (= תחתית)
		var dark := Color("1a1c20")
		var steel := Color("2e3238")
		for sx in [-6.0, width + 2.0]:
			draw_rect(Rect2(sx, top, 4.0, -top), steel)
		var y := 0.0
		while y > top + 20.0:   # הצלבות
			draw_line(Vector2(-6, y), Vector2(width + 6, y - 40.0), Color(0.12, 0.13, 0.15, 0.9), 1.5)
			draw_line(Vector2(width + 6, y), Vector2(-6, y - 40.0), Color(0.12, 0.13, 0.15, 0.9), 1.5)
			y -= 40.0
		draw_rect(Rect2(-14, top - 10.0, width + 28.0, 14.0), dark)
		for gx in [10.0, width - 10.0]:   # גלגלות
			draw_circle(Vector2(gx, top - 3.0), 9.0, steel)
			draw_circle(Vector2(gx, top - 3.0), 3.0, Color("6a6e74"))
		draw_rect(Rect2(-10, -4, width + 20.0, 6.0), Color("101012"))   # פתח בריצפה
