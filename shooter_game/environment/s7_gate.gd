extends "res://environment/hazard.gd"
# ============================================================
#  S7 ROUTE GATE - תריס תחזוקה נעול שפותח "דרך חלופית" (שלב 7)
#  תריס סורג שחוסם מעבר (בדרך כלל על גשר / חדר תחזוקה סגור עם זומבים בפנים).
#  נפתח (פעם אחת, לתמיד) כש:
#    * זומבי ENGINEER מושך ידית בלוח בקרה מחובר -> הזומבים שבפנים פורצים החוצה ומאגפים.
#    * או שהשחקן יורה במנעול lock_hp פעמים (הדרך נפתחת גם לו).
#  * גוף פיזי בשכבה 1 עם take_damage() - קליעים "פוגעים" בו (ניצוצות).
#  * position = אמצע תחתית התריס. height = גובה.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")

var height := 118.0
var width := 14.0
var lock_hp := 4
var opened := false
var _k := 0.0                   # 0 = סגור, 1 = פתוח
var _t := 0.0
var _hit_flash := 0.0
var _body: StaticBody2D
var _cs: CollisionShape2D


func _ready() -> void:
	super._ready()
	add_to_group("s7_gates")
	triggerable = true
	active = false
	player_damage = 0
	rect = Rect2(-width * 0.5, -height, width, height)
	var gb := GateBody.new()
	gb.gate = self
	gb.collision_layer = 1
	gb.collision_mask = 0
	_body = gb
	_cs = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(width, height)
	_cs.shape = r
	_cs.position = Vector2(0.0, -height * 0.5)
	_body.add_child(_cs)
	add_child(_body)
	z_index = 2


func trigger() -> void:
	open()


func link_point() -> Vector2:
	return global_position + Vector2(0.0, -height - 8.0)


func open() -> void:
	if opened:
		return
	opened = true
	_cs.set_deferred("disabled", true)
	Sfx.play("s7_gate", global_position, 2.0, 0.05, 2)
	# הזומבים שמאחורי התריס "מתעוררים" ופורצים החוצה
	for z in get_tree().get_nodes_in_group("zombies"):
		if not z.dead and z.global_position.distance_to(global_position) < 360.0:
			z._alert_t = maxf(z._alert_t, 6.0)


# קליע פגע במנעול
func on_shot(hit_pos: Vector2) -> void:
	if opened:
		return
	lock_hp -= 1
	_hit_flash = 0.15
	Particles.burst(get_parent(), hit_pos, "fire", Vector2.UP, 5)
	Sfx.play("ricochet", hit_pos, -6.0, 0.2, 2)
	if lock_hp <= 0:
		open()


func _hazard_tick(delta: float) -> void:
	_t += delta
	_hit_flash -= delta
	if opened and _k < 1.0:
		_k = minf(1.0, _k + delta / 0.8)
	if Art.on_screen(self, global_position + Vector2(0, -height * 0.5), 140.0) and (Engine.get_physics_frames() % 6 == 0 or (opened and _k < 1.0) or _hit_flash > 0.0):
		queue_redraw()


func _draw() -> void:
	var dark := Color("1c1e22")
	var bar := Color("5a5e64")
	var w := width
	# מסגרת
	draw_rect(Rect2(-w * 0.5 - 6.0, -height - 12.0, w + 12.0, 12.0), dark)
	draw_rect(Rect2(-w * 0.5 - 6.0, -height, 4.0, height), dark)
	draw_rect(Rect2(w * 0.5 + 2.0, -height, 4.0, height), dark)
	# התריס עולה למעלה (רק החלק שעוד למטה מצויר)
	var bottom := -height * _k
	if bottom > -height + 2.0:
		var y := -height
		while y < bottom - 1.0:
			draw_line(Vector2(-w * 0.5, y), Vector2(w * 0.5, y), bar, 2.0)
			y += 7.0
		var x := -w * 0.5 + 2.0
		while x < w * 0.5:
			draw_line(Vector2(x, -height), Vector2(x, bottom), Color("3a3e44"), 1.2)
			x += 4.0
		draw_rect(Rect2(-w * 0.5, bottom - 5.0, w, 5.0), Color("b8901c"))
	# קופסת המנעול עם נורה (אדום = נעול, ירוק = פתוח)
	var lc := Vector2(w * 0.5 + 10.0, -height * 0.45)
	draw_rect(Rect2(lc.x - 6.0, lc.y - 9.0, 12.0, 18.0), Color("2a2c30") if _hit_flash <= 0.0 else Color("d0d0d0"))
	var led := Color(0.2, 1.0, 0.35) if opened else Color(1.0, 0.2, 0.15)
	draw_circle(lc + Vector2(0, -3), 2.2, led)
	Art.glow(self, lc + Vector2(0, -3), 8.0, Color(led, 0.5 + 0.3 * sin(_t * 5.0)))
	if not opened:
		for q in lock_hp:
			draw_rect(Rect2(lc.x - 4.0 + float(q) * 2.2, lc.y + 3.0, 1.4, 3.0), Color(1.0, 0.6, 0.2, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(-w * 0.5 - 4.0, -height - 2.0), "MAINT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.85, 0.75, 0.3, 0.7))


# הגוף הפיזי של התריס: קליעים קוראים ל-take_damage -> פוגעים במנעול
class GateBody extends StaticBody2D:
	var gate: Node = null

	func take_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
		if gate != null:
			gate.on_shot(hit_pos)
