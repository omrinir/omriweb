extends "res://environment/hazard.gd"
# ============================================================
#  S7 LIVE WIRE - כבל חשמל קרוע שתלוי לתוך שלולית שמן/מים (שלב 7)
#  במנוחה: הכבל מתנדנד ומדי פעם יורק ניצוץ קטן.
#  לפני מכה: זמזום חשמלי והכבל זוהר בכחול (אזהרה) -> קשתות חשמל על כל השלולית.
#  זומבים שעומדים בשלולית "מטוגנים" (zombie_damage) - זומבים חכמים מתרחקים.
#
#  * position = מרכז השלולית על הריצפה. drop = מאיפה הכבל יורד (כמה פיקסלים למעלה).
#  * auto = פריקה לבד כל period שניות. trigger() = ENGINEER / לוח בקרה (פריקה ארוכה יותר).
#  איך משנים: width (רוחב השלולית), period, surge_time, drop.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Ambient := preload("res://effects/ambient.gd")

enum { IDLE, CHARGE, SURGE }

var width := 96.0
var drop := 280.0
var auto := true
var period := Vector2(5.0, 8.0)
var surge_time := 1.2
var state := IDLE
var surges := 0                 # לבדיקות
var _st := 0.0
var _next := 3.0
var _t := 0.0
var _long := false


func _ready() -> void:
	super._ready()
	triggerable = true
	active = false
	player_damage = 1
	zombie_damage = 8
	tick = 0.4
	rect = Rect2(-width * 0.5, -26.0, width, 28.0)
	_next = randf_range(period.x, period.y) * randf_range(0.4, 1.0)
	z_index = 2
	var sp = Ambient.SparkEmitter.new()   # ניצוצות מקצה הכבל
	sp.period = 3.0
	sp.color = Color(0.6, 0.8, 1.0)
	sp.position = _tip()
	add_child(sp)


func trigger() -> void:
	if state == IDLE:
		_long = true
		_enter(CHARGE)


func link_point() -> Vector2:
	return global_position + Vector2(-width * 0.25, -drop)


func _tip() -> Vector2:
	return Vector2(width * 0.18 + sin(_t * 1.3) * 3.0, -6.0)


func _enter(s: int) -> void:
	state = s
	_st = 0.0
	if s == CHARGE:
		Sfx.play("s7_buzz", global_position, -3.0, 0.1, 3)
	elif s == SURGE:
		surges += 1
		Sfx.play("zap", global_position, 2.0, 0.2, 3)


func _hazard_tick(delta: float) -> void:
	_t += delta
	_st += delta
	match state:
		IDLE:
			if auto:
				_next -= delta
				if _next <= 0.0:
					_enter(CHARGE)
		CHARGE:
			if _st >= 0.75:
				_enter(SURGE)
		SURGE:
			if _st >= (surge_time * 1.8 if _long else surge_time):
				_enter(IDLE)
				_long = false
				_next = randf_range(period.x, period.y)
			elif Engine.get_physics_frames() % 20 == 0:
				Sfx.play("zap", global_position, -6.0, 0.25, 2)
	active = state == SURGE
	if Art.on_screen(self, global_position + Vector2(0.0, -drop * 0.5), 240.0):
		queue_redraw()


func _draw() -> void:
	# שלולית
	var pts := PackedVector2Array()
	for i in 18:
		var a := TAU * float(i) / 18.0
		pts.append(Vector2(cos(a) * width * 0.5 * (1.0 + 0.06 * sin(a * 3.0)), sin(a) * 3.5 - 1.0))
	var lit := state == SURGE
	draw_colored_polygon(pts, Color(0.08, 0.1, 0.14, 0.9) if not lit else Color(0.35, 0.55, 0.9, 0.75))
	draw_line(Vector2(-width * 0.3, -2.0), Vector2(width * 0.1, -2.5), Color(0.5, 0.6, 0.8, 0.35), 1.0)   # ברק של שמן
	# הכבל: יורד מלמעלה בקשת ומתנדנד
	var top := Vector2(-width * 0.25, -drop)
	var tip := _tip()
	var sway := sin(_t * 1.3) * 10.0
	var cable := PackedVector2Array()
	for i in 13:
		var u := float(i) / 12.0
		var p := top.lerp(tip, u) + Vector2(sin(u * PI) * (18.0 + sway), 0.0)
		cable.append(p)
	draw_polyline(cable, Color("101012"), 3.2)
	draw_circle(top, 4.0, Color("1a1a1c"))   # מחזיק
	var charging := state == CHARGE or state == SURGE
	if charging and fmod(_t * 14.0, 1.0) < 0.6:
		draw_polyline(cable, Color(0.5, 0.75, 1.0, 0.55), 1.4)
	# חוטי נחושת חשופים בקצה
	for i in 4:
		var a := -PI * 0.5 + (float(i) - 1.5) * 0.45
		draw_line(tip, tip + Vector2.from_angle(a + PI) * 6.0, Color("c87a3a"), 1.0)
	if charging:
		Art.glow(self, tip, 14.0 + 4.0 * sin(_t * 30.0), Color(0.5, 0.75, 1.0, 0.7))
	if lit:   # קשתות חשמל על השלולית
		for k in 4:
			var arc := PackedVector2Array([tip])
			var p := tip
			var target := Vector2(randf_range(-width * 0.5, width * 0.5), randf_range(-3.0, 1.0))
			for q in 6:
				p = p.lerp(target, 0.35) + Vector2(randf_range(-5, 5), randf_range(-9, 3))
				arc.append(p)
			draw_polyline(arc, Color(0.75, 0.88, 1.0, 0.9), 1.4)
		for k in 3:
			var up := Vector2(randf_range(-width * 0.45, width * 0.45), -2.0)
			draw_line(up, up + Vector2(randf_range(-6, 6), -randf_range(10, 24)), Color(0.7, 0.85, 1.0, 0.7), 1.0)
		Art.glow(self, Vector2(0, -6), width * 0.55, Color(0.45, 0.65, 1.0, 0.45))
