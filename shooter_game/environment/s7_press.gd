extends "res://environment/hazard.gd"
# ============================================================
#  S7 HYDRAULIC PRESS - מכבש הידראולי (שלב 7: "THEY WATCH")
#  ראש פלדה כבד שיורד בבת אחת ומועך כל מה שמתחתיו (שחקן וזומבים!).
#
#  מחזור: IDLE (למעלה) -> WARN (נורה כתומה מהבהבת + שריקה, הראש רועד)
#         -> SLAM (נופל) -> HOLD (למטה = פוגע) -> RISE (עולה לאט)
#  * auto = true: עובד לבד כל period שניות (פס ייצור).
#  * trigger(): זומבי ENGINEER (או לוח בקרה) מפעיל אותו מיד - עם אזהרה ארוכה יותר (הוגן).
#  * position = נקודת הפגיעה על הריצפה / על המסוע (מרכז הראש).
#
#  איך משנים: width (רוחב הראש), stroke (כמה גבוה הראש בהמתנה), top_h (גובה המסגרת),
#  period (זמן בין מחזורים), player_damage / zombie_damage (בהגדרות ב-_ready).
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")
const Particles := preload("res://particles.gd")

enum { IDLE, WARN, SLAM, HOLD, RISE }

var width := 74.0
var stroke := 150.0              # כמה פיקסלים מעל הריצפה הראש מחכה
var top_h := 250.0               # גובה המסגרת
var auto := true
var period := Vector2(4.5, 7.5)  # טווח זמן בין מחזורים אוטומטיים
var anvil := true                # בסיס פלדה על הריצפה (לא על מסוע)
var state := IDLE
var slams := 0                   # לבדיקות: כמה פעמים נחת
var _st := 0.0
var _next := 3.0
var _head := 0.0                 # 0 = למעלה, 1 = למטה
var _t := 0.0
var _big_warn := false


func _ready() -> void:
	super._ready()
	triggerable = true
	active = false
	player_damage = 2
	zombie_damage = 60   # זומבים נמעכים
	tick = 0.3
	rect = Rect2(-width * 0.5 + 4.0, -64.0, width - 8.0, 64.0)
	_next = randf_range(period.x, period.y)
	z_index = 2


# ENGINEER / לוח בקרה מפעיל את המכבש
func trigger() -> void:
	if state == IDLE:
		_big_warn = true
		_enter(WARN)


# נקודה שאליה מתחבר כבל מלוח הבקרה
func link_point() -> Vector2:
	return global_position + Vector2(0.0, -top_h + 10.0)


func _enter(s: int) -> void:
	state = s
	_st = 0.0
	match s:
		WARN:
			Sfx.play("s7_press_hiss", global_position + Vector2(0.0, -stroke), -2.0 if _big_warn else -6.0, 0.1, 3)
		HOLD:
			slams += 1
			Sfx.play("s7_press_slam", global_position, 2.0, 0.08, 3)
			if Art.on_screen(self, global_position):
				Particles.burst(get_parent(), global_position + Vector2(-width * 0.4, -4.0), "smoke", Vector2.LEFT, 4)
				Particles.burst(get_parent(), global_position + Vector2(width * 0.4, -4.0), "smoke", Vector2.RIGHT, 4)
				Particles.burst(get_parent(), global_position + Vector2(0.0, -4.0), "fire", Vector2.UP, 6)
			var pl := get_tree().get_first_node_in_group("player")
			var cam := get_viewport().get_camera_2d()
			if pl != null and cam != null and cam.has_method("shake"):
				var dd: float = absf(pl.global_position.x - global_position.x)
				if dd < 500.0:
					cam.shake(6.0 * (1.0 - dd / 500.0) + 1.0, 0.18)


func _hazard_tick(delta: float) -> void:
	_t += delta
	_st += delta
	match state:
		IDLE:
			_head = 0.0
			if auto:
				_next -= delta
				if _next <= 0.0:
					_enter(WARN)
		WARN:   # הראש רועד קצת - סימן ברור שהוא עומד ליפול
			_head = 0.03 * absf(sin(_st * 45.0))
			if _st >= (1.0 if _big_warn else 0.75):
				_enter(SLAM)
		SLAM:
			_head = minf(1.0, _st / 0.11)
			if _head >= 1.0:
				_enter(HOLD)
		HOLD:
			_head = 1.0
			if _st >= 0.4:
				_enter(RISE)
		RISE:
			_head = 1.0 - clampf(_st / 1.1, 0.0, 1.0)
			if _st >= 1.1:
				_enter(IDLE)
				_big_warn = false
				_next = randf_range(period.x, period.y)
	active = state == HOLD or (state == SLAM and _head > 0.55)
	if Art.on_screen(self, global_position + Vector2(0.0, -120.0), 200.0):
		queue_redraw()


func _draw() -> void:
	var w := width
	var steel := Color("3a3e44")
	var dark := Color("1e2024")
	var hz := Color("b8901c")
	var top := -top_h
	# צל על הריצפה שגדל כשהראש יורד
	Art.ground_shadow(self, Vector2(0, 0), w * (0.35 + 0.35 * _head))
	# בסיס (סדן)
	if anvil:
		draw_rect(Rect2(-w * 0.5 - 8.0, -7.0, w + 16.0, 7.0), Color("2a2c30"))
		draw_line(Vector2(-w * 0.5 - 8.0, -7.0), Vector2(w * 0.5 + 8.0, -7.0), Color(0.7, 0.72, 0.75, 0.35), 1.0)
	# עמודי I מהצדדים
	for sx in [-1.0, 1.0]:
		var px: float = sx * (w * 0.5 + 10.0)
		draw_rect(Rect2(px - 5.0, top, 10.0, top_h - 7.0), dark)
		draw_rect(Rect2(px - 2.0, top, 4.0, top_h - 7.0), steel)
		var y := top + 30.0
		while y < -20.0:   # ברגים
			draw_circle(Vector2(px, y), 1.5, Color("5a5e64"))
			y += 34.0
	# קורה עליונה עם פסי אזהרה
	draw_rect(Rect2(-w * 0.5 - 16.0, top - 6.0, w + 32.0, 24.0), dark)
	var x := -w * 0.5 - 14.0
	var i := 0
	while x < w * 0.5 + 12.0:
		if i % 2 == 0:
			draw_colored_polygon(PackedVector2Array([Vector2(x, top + 16), Vector2(x + 8, top + 16), Vector2(x + 14, top), Vector2(x + 6, top)]), hz)
		x += 8.0
		i += 1
	# צילינדר הידראולי
	Art.fill_shaded(self, PackedVector2Array([Vector2(-15, top + 18), Vector2(15, top + 18), Vector2(15, top + 62), Vector2(-15, top + 62)]), Color("4a4e54"), 0.25, 0.4)
	draw_rect(Rect2(-17, top + 58, 34, 5), dark)
	# נורת אזהרה
	var warn := state == WARN or state == SLAM
	var lamp_on := warn and fmod(_t * 10.0, 1.0) < 0.55
	draw_circle(Vector2(0, top - 10.0), 5.0, dark)
	draw_circle(Vector2(0, top - 10.0), 3.6, Color(1.0, 0.6, 0.15) if lamp_on else Color(0.35, 0.22, 0.1))
	if lamp_on:
		Art.glow(self, Vector2(0, top - 10.0), 26.0, Color(1.0, 0.55, 0.15, 0.7))
		draw_colored_polygon(PackedVector2Array([Vector2(-3, top - 8), Vector2(3, top - 8), Vector2(w * 0.6, 0), Vector2(-w * 0.6, 0)]), Color(1.0, 0.6, 0.2, 0.06))
	# מוט הבוכנה + הראש
	var hb := -stroke * (1.0 - _head)   # תחתית הראש
	var ht := hb - 30.0
	draw_rect(Rect2(-6, top + 62, 12, ht - (top + 62)), Color("8a9098"))
	draw_rect(Rect2(-6, top + 62, 3, ht - (top + 62)), Color(1, 1, 1, 0.25))
	Art.fill_shaded(self, PackedVector2Array([Vector2(-w * 0.5, ht), Vector2(w * 0.5, ht), Vector2(w * 0.5, hb), Vector2(-w * 0.5, hb)]), Color("4e5258"), 0.2, 0.45)
	# פסי אזהרה על הראש (שברונים)
	var cx := -w * 0.5 + 4.0
	while cx < w * 0.5 - 10.0:
		draw_colored_polygon(PackedVector2Array([Vector2(cx, hb - 3), Vector2(cx + 6, hb - 3), Vector2(cx + 12, hb - 11), Vector2(cx + 6, hb - 11)]), hz)
		cx += 13.0
	draw_rect(Rect2(-w * 0.5, hb - 2.0, w, 2.0), Color("16181a"))
	if state == HOLD and _st < 0.12:   # הבזק מכה
		Art.glow(self, Vector2(0, -6), w * 0.7, Color(1.0, 0.8, 0.5, 0.5))
