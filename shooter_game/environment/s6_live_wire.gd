extends "res://environment/hazard.gd"
# ============================================================
#  שלולית מחושמלת (שלב 6): כבל קרוע תלוי מהתקרה ונוגע בשלולית מים.
#  מחזור: שקט (IDLE) -> אזהרה (WARN: ניצוצות בקצה הכבל + פצפוץ) -> מכה (SHOCK:
#  קשתות חשמל על כל השלולית, פוגע בשחקן ובזומבים שעומדים בה).
#  זומבים חכמים לא נכנסים אליה כשהיא פעילה (danger_at), ומהנדס יכול להפעיל אותה (trigger).
#  position = מרכז השלולית על הריצפה. cable_h = כמה גבוה התקרה (מאיפה הכבל תלוי).
#  לשנות: IDLE_T / WARN_T / SHOCK_T, width.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")

const IDLE_T := Vector2(2.6, 3.8)
const WARN_T := 0.65
const SHOCK_T := 1.1

var width := 110.0
var cable_h := 146.0
var _phase := 0          # 0 = שקט, 1 = אזהרה, 2 = מכה
var _pt := 0.0
var _t := 0.0
var _arcs := []
var shocks := 0          # לבדיקות


func _ready() -> void:
	super._ready()
	rect = Rect2(-width * 0.5, -26.0, width, 28.0)
	player_damage = 1
	zombie_damage = 6
	tick = 0.45
	triggerable = true
	active = false
	z_index = 1
	_pt = randf_range(0.5, IDLE_T.y)


func trigger() -> void:
	_phase = 1
	_pt = 0.2


func _hazard_tick(delta: float) -> void:
	_t += delta
	_pt -= delta
	if _pt <= 0.0:
		_phase = (_phase + 1) % 3
		match _phase:
			0:
				_pt = randf_range(IDLE_T.x, IDLE_T.y)
			1:
				_pt = WARN_T
				if Art.on_screen(self, global_position):
					Sfx.play("zap", global_position + Vector2(0, -cable_h * 0.3), -10.0, 0.2, 2)
			2:
				_pt = SHOCK_T
				shocks += 1
				_tick_t = 0.0
				if Art.on_screen(self, global_position):
					Sfx.play("s6_shock", global_position, -2.0, 0.15, 2)
					Particles.burst(get_parent(), global_position + Vector2(0, -4), "fire", Vector2.UP, 8)
	active = _phase == 2
	if Art.on_screen(self, global_position):
		if _phase == 2 or Engine.get_physics_frames() % 3 == 0:
			_arcs.clear()
			if _phase == 2:
				for i in 3:
					_arcs.append(_bolt(Vector2(randf_range(-width * 0.45, width * 0.45), -2.0), Vector2(randf_range(-width * 0.45, width * 0.45), -2.0)))
				_arcs.append(_bolt(Vector2(6, -cable_h * 0.28), Vector2(randf_range(-20, 20), -2.0)))
			queue_redraw()


func _bolt(a: Vector2, b: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array([a])
	for i in range(1, 6):
		var u := float(i) / 6.0
		pts.append(a.lerp(b, u) + Vector2(randf_range(-3, 3), randf_range(-9, 3)))
	pts.append(b)
	return pts


func _draw() -> void:
	# שלולית עם השתקפות
	var water := Color(0.3, 0.38, 0.5, 0.55)
	var pts := Art.ellipse(Vector2(0, 0), width * 0.5, 5.0, 0.0, 24)
	draw_colored_polygon(pts, water)
	draw_line(Vector2(-width * 0.3, -1), Vector2(width * 0.15, -1), Color(0.7, 0.8, 1.0, 0.35), 1.5)
	for i in 2:   # אדוות
		var k := fmod(_t * 0.6 + float(i) * 0.5, 1.0)
		var rp := Art.ellipse(Vector2(width * (0.15 - 0.3 * float(i)), 0), 4.0 + k * 16.0, 1.0 + k * 2.5, 0.0, 16)
		rp.append(rp[0])
		draw_polyline(rp, Color(0.8, 0.9, 1.0, 0.35 * (1.0 - k)), 1.0)
	# כבל תלוי מהתקרה (מתנדנד קצת), קצה חשוף
	var sway := sin(_t * 1.3) * 4.0
	var top := Vector2(14, -cable_h)
	var tip := Vector2(6 + sway, -cable_h * 0.28)
	var mid := top.lerp(tip, 0.5) + Vector2(10 + sway * 0.5, 0)
	var cp := PackedVector2Array()
	for i in 9:
		var u := float(i) / 8.0
		cp.append(top.lerp(mid, u).lerp(mid.lerp(tip, u), u))
	draw_polyline(cp, Color("141414"), 3.0, true)
	draw_line(tip, tip + Vector2(-2, 5), Color("c87a30"), 1.5)   # נחושת חשופה
	draw_line(tip, tip + Vector2(2, 5), Color("c87a30"), 1.5)
	if _phase == 1:   # אזהרה: ניצוצות בקצה
		Art.glow(self, tip + Vector2(0, 5), 9.0, Color(0.6, 0.8, 1.0, 0.6))
		for i in 3:
			var a := randf() * TAU
			draw_line(tip + Vector2(0, 5), tip + Vector2(0, 5) + Vector2.from_angle(a) * randf_range(4, 9), Color(1.0, 0.95, 0.6, 0.9), 1.0)
	if _phase == 2:   # מכה: קשתות + זוהר על כל השלולית
		Art.glow(self, Vector2(0, -6), width * 0.45, Color(0.45, 0.7, 1.0, 0.35))
		for arc in _arcs:
			draw_polyline(arc, Color(0.55, 0.8, 1.0, 0.5), 4.0, true)
			draw_polyline(arc, Color(0.95, 0.98, 1.0, 1.0), 1.5, true)
	elif _phase == 0:
		# שקט: ניצוץ קטן מדי פעם
		if fmod(_t, 1.7) < 0.08:
			Art.glow(self, tip + Vector2(0, 5), 5.0, Color(0.6, 0.8, 1.0, 0.5))
