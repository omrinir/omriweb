extends "res://environment/hazard.gd"
# ============================================================
#  לוח רצפה מחושמל (שלב 8 - מעבדה). סכנה מחזורית והוגנת:
#    OFF  (OFF_TIME)  - כבוי, אפשר לעבור.
#    WARN (WARN_TIME) - אזהרה: נורות צהובות מהבהבות + ניצוצות קטנים + זמזום.
#    ON   (ON_TIME)   - קשתות חשמל: פוגע בשחקן (player_damage) ובזומבים (zombie_damage).
#  זומבים חכמים (hazard_awareness) לא נכנסים כשהוא ב-WARN/ON (danger_at).
#  מהנדס (ENGINEER) יכול להפעיל אותו מיד (trigger).
#  לשנות: width (רוחב), OFF_TIME / WARN_TIME / ON_TIME, phase (כדי שלא כולם יהבהבו ביחד).
# ============================================================
const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")

# הצלילים ("s8_zap", "s8_hum") מוגדרים ב-levels/stage_8.gd -> SOUNDS (נרשמים אוטומטית)

const OFF_TIME := 2.6
const WARN_TIME := 0.8
const ON_TIME := 1.3

var width := 120.0
var phase := 0.0
var _t := 0.0
var _state := 0          # 0 = OFF, 1 = WARN, 2 = ON
var _seed := 0


func setup(w: float, ph := 0.0) -> void:
	width = w
	phase = ph
	rect = Rect2(-w * 0.5, -10.0, w, 12.0)
	player_damage = 1
	zombie_damage = 6
	tick = 0.5
	triggerable = true


func _ready() -> void:
	super._ready()
	z_index = 1
	_t = phase
	_seed = int(position.x)
	active = false


func trigger() -> void:
	_t = OFF_TIME   # מיד לאזהרה


func danger_at(p: Vector2, margin := 0.0) -> bool:
	return _state > 0 and world_rect().grow(margin).has_point(p)


func _hazard_tick(delta: float) -> void:
	_t = fmod(_t + delta, OFF_TIME + WARN_TIME + ON_TIME)
	var st := 0 if _t < OFF_TIME else (1 if _t < OFF_TIME + WARN_TIME else 2)
	if st != _state:
		_state = st
		active = st == 2
		var vis := Art.on_screen(self, global_position)
		if st == 2 and vis:
			Sfx.play("s8_zap", global_position, -4.0, 0.15, 2)
		elif st == 1 and vis:
			Sfx.play("s8_hum", global_position, -10.0, 0.1, 2)
	if Art.on_screen(self, global_position, 200.0) and (_state > 0 or Engine.get_physics_frames() % 10 == 0):
		queue_redraw()


func _draw() -> void:
	var w := width
	var x0 := -w * 0.5
	# לוחות מתכת עם מסגרת אזהרה
	draw_rect(Rect2(x0, -3, w, 5), Color("2c3034"))
	var x := x0
	while x < x0 + w - 1.0:
		var sw := minf(8.0, x0 + w - x)
		draw_rect(Rect2(x, -4, sw * 0.5, 2), Color(0.85, 0.7, 0.1) if int((x - x0) / 8.0) % 2 == 0 else Color(0.08, 0.08, 0.08))
		x += sw * 0.5
	for i in int(w / 30.0) + 1:
		var px := x0 + float(i) * 30.0
		draw_line(Vector2(px, -2), Vector2(px, 2), Color("181a1c"), 1.0)
	# נורות בקצוות
	var lamp := Color(0.25, 0.3, 0.2)
	if _state == 1:
		lamp = Color(1.0, 0.85, 0.2) if int(_t * 10.0) % 2 == 0 else Color(0.35, 0.3, 0.1)
	elif _state == 2:
		lamp = Color(0.5, 0.8, 1.0)
	for e in [x0 + 3.0, x0 + w - 3.0]:
		var ex: float = e
		draw_circle(Vector2(ex, -6), 2.5, lamp)
		if _state > 0:
			Art.glow(self, Vector2(ex, -6), 8.0, Color(lamp, 0.5))
	if _state == 1:   # ניצוצות קטנים - אזהרה
		for i in 3:
			var sx := x0 + randf() * w
			draw_line(Vector2(sx, -3), Vector2(sx + randf_range(-4, 4), -3 - randf_range(3, 8)), Color(0.7, 0.85, 1.0, 0.8), 1.0)
	elif _state == 2:   # קשתות חשמל
		draw_rect(Rect2(x0, -12, w, 12), Color(0.4, 0.7, 1.0, 0.12))
		for k in 3:
			var pts := PackedVector2Array()
			var px := x0
			while px <= x0 + w:
				pts.append(Vector2(px, -2.0 - randf() * 18.0))
				px += randf_range(8.0, 16.0)
			draw_polyline(pts, Color(0.75, 0.9, 1.0, 0.9 - 0.25 * float(k)), 1.6 - 0.4 * float(k))
		Art.glow(self, Vector2(0, -6), w * 0.4, Color(0.4, 0.7, 1.0, 0.25))
