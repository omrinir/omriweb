extends "res://environment/hazard.gd"
# ============================================================
#  שלולית חומצה (מהיריקה של SPITTER משלב 6, ומ-INFECTOR). פוגעת בשחקן שעומד בה.
#  זומבים חכמים עוקפים אותה (ai/zombie_brain.gd -> hazard_awareness).
# ============================================================
var width := 46.0
var tint := Color(0.5, 0.95, 0.2)   # צבע (RETCHER: קיא צהוב-ירוק)
var _t := 0.0
var _max_life := 4.0


func setup(w: float, seconds: float) -> void:
	width = w
	life = seconds
	_max_life = seconds
	rect = Rect2(-w * 0.5, -10.0, w, 12.0)
	player_damage = 1
	tick = 0.7


func _ready() -> void:
	super._ready()
	z_index = 2


func _hazard_tick(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var a := clampf(life / 1.0, 0.0, 1.0) if life > 0.0 else 1.0
	var g := tint
	var pts := PackedVector2Array()
	for i in 16:
		var t := TAU * float(i) / 16.0
		pts.append(Vector2(cos(t) * width * 0.5 * (1.0 + 0.08 * sin(t * 3.0 + _t)), sin(t) * 3.5))
	draw_colored_polygon(pts, Color(g, 0.55 * a))
	for i in 4:   # בועות
		var k := fmod(_t * 0.9 + float(i) * 0.27, 1.0)
		var bx := (float(i) / 3.0 - 0.5) * width * 0.7
		draw_circle(Vector2(bx, -k * 10.0), 2.0 * (1.0 - k), Color(g.lerp(Color.WHITE, 0.4), a * (1.0 - k)))
	draw_circle(Vector2(0, -6), width * 0.6, Color(g, 0.05 * a))
