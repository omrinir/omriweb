extends "res://environment/hazard.gd"
# ============================================================
#  S7 STEAM PIPE - צינור קיטור שמתפרץ (שלב 7)
#  במצב רגיל דולפים ממנו אדים קטנים. לפני פרץ: גלגל השסתום מסתובב,
#  מחוג הלחץ קופץ לאדום ונשמעת שריקה עולה (אזהרה) - ואז סילון קיטור רותח.
#
#  * dir = כיוון הסילון: Vector2.LEFT / Vector2.RIGHT (מצינור על הריצפה), Vector2.DOWN (מתחת לגשר).
#  * position = פתח הצינור. height = כמה גבוה הפתח מעל הריצפה (לצינור אופקי - לציור העמוד).
#  * auto = מתפרץ לבד כל period שניות. trigger() = ENGINEER / לוח בקרה מפעיל מיד.
#  איך משנים: length (אורך הסילון), period, blast_time, player_damage / zombie_damage.
# ============================================================

const Art := preload("res://art.gd")
const Sfx := preload("res://sfx.gd")

enum { IDLE, WARN, BLAST }

var dir := Vector2.LEFT
var length := 120.0
var height := 34.0
var auto := true
var period := Vector2(6.0, 9.0)
var blast_time := 1.4
var state := IDLE
var blasts := 0                 # לבדיקות
var _st := 0.0
var _next := 4.0
var _t := 0.0
var _wheel := 0.0
var _puffs := []                # [מיקום, מהירות, גיל, חיים]


func _ready() -> void:
	super._ready()
	triggerable = true
	active = false
	player_damage = 1
	zombie_damage = 6
	tick = 0.45
	if dir == Vector2.DOWN:
		rect = Rect2(-16.0, 0.0, 32.0, length)
	else:
		rect = Rect2(0.0 if dir.x > 0.0 else -length, -18.0, length, 36.0)
	_next = randf_range(period.x, period.y) * randf_range(0.3, 1.0)
	z_index = 5


func trigger() -> void:
	if state == IDLE:
		_enter(WARN)


func link_point() -> Vector2:
	if dir == Vector2.DOWN:
		return global_position + Vector2(0.0, -24.0)
	return global_position + Vector2(-dir.x * 14.0, -22.0)


func _enter(s: int) -> void:
	state = s
	_st = 0.0
	if s == WARN:
		Sfx.play("s7_valve", global_position, -6.0, 0.1, 3)
	elif s == BLAST:
		blasts += 1
		Sfx.play("s7_steam", global_position, 0.0, 0.1, 3)


func _hazard_tick(delta: float) -> void:
	_t += delta
	_st += delta
	match state:
		IDLE:
			if auto:
				_next -= delta
				if _next <= 0.0:
					_enter(WARN)
		WARN:
			_wheel += delta * 14.0
			if _st >= 0.7:
				_enter(BLAST)
		BLAST:
			if _st >= blast_time:
				_enter(IDLE)
				_next = randf_range(period.x, period.y)
	active = state == BLAST and _st > 0.08
	var on := Art.on_screen(self, global_position, 220.0)
	# אדים: דליפה קטנה / סילון
	var blasting := state == BLAST
	if on and randf() < (1.0 if blasting else (0.5 if state == WARN else 0.18)):
		for i in (4 if blasting else 1):
			var spd := randf_range(250.0, 420.0) if blasting else randf_range(30.0, 70.0)
			_puffs.append([Vector2.ZERO, dir.rotated(randf_range(-0.18, 0.18)) * spd, 0.0, randf_range(0.35, 0.6) if blasting else randf_range(0.6, 1.1)])
	for pf in _puffs:
		pf[2] += delta
		pf[0] += pf[1] * delta
		pf[1] *= 0.94
		pf[1].y -= 30.0 * delta
	_puffs = _puffs.filter(func(q: Array) -> bool: return q[2] < q[3])
	if on:
		queue_redraw()


func _draw() -> void:
	var pipe := Color("4a5450")
	var dark := Color("262c2a")
	var back := -dir.x if dir != Vector2.DOWN else 0.0
	if dir == Vector2.DOWN:
		# צינור שיורד מהגשר: עמוד קצר למעלה + פתח
		draw_rect(Rect2(-7, -40, 14, 30), pipe)
		draw_rect(Rect2(-9, -12, 18, 8), dark)
		draw_rect(Rect2(-6, -4, 12, 4), Color("1a1e1c"))
		_valve(Vector2(14, -30))
		_gauge(Vector2(-16, -30))
	else:
		# עמוד צינור מהריצפה, מרפק, ופתח שפונה לצד
		var cx := back * 14.0
		draw_rect(Rect2(cx - 7.0, -10.0, 14.0, height + 10.0), pipe)
		draw_rect(Rect2(cx - 7.0, -10.0, 4.0, height + 10.0), Color(1, 1, 1, 0.08))
		for by in [height - 6.0, height * 0.4]:   # טבעות חיזוק
			draw_rect(Rect2(cx - 9.0, by, 18.0, 4.0), dark)
		draw_rect(Rect2(minf(cx, 0.0) - 4.0, -7.0, absf(cx) + 8.0, 14.0), pipe)
		draw_rect(Rect2(-dir.x * 2.0 - 4.0, -9.0, 8.0, 18.0), dark)   # פתח
		draw_rect(Rect2(cx - 11.0, height - 4.0, 22.0, 4.0), dark)   # בסיס
		_valve(Vector2(cx, -18.0))
		_gauge(Vector2(cx + back * 16.0, 12.0))
	# אדים
	for pf in _puffs:
		var k: float = pf[2] / pf[3]
		var r := 4.0 + k * (18.0 if state == BLAST else 12.0)
		draw_circle(pf[0], r, Color(0.88, 0.9, 0.92, (0.45 if state == BLAST else 0.25) * (1.0 - k)))
	if state == BLAST:   # ליבת הסילון הלבנה
		var e := dir * length * 0.8
		var n := dir.orthogonal()
		draw_colored_polygon(PackedVector2Array([n * 4.0, -n * 4.0, e - n * 16.0, e + n * 16.0]), Color(1.0, 1.0, 1.0, 0.18))


func _valve(c: Vector2) -> void:
	draw_circle(c, 7.0, Color("6a1e18"))
	draw_circle(c, 5.0, Color("8a2a20"))
	for i in 3:
		var a := _wheel + float(i) * TAU / 3.0
		draw_line(c, c + Vector2.from_angle(a) * 6.0, Color("2a0e0c"), 1.6)
	draw_circle(c, 1.5, Color("2a0e0c"))


func _gauge(c: Vector2) -> void:
	draw_circle(c, 5.5, Color("1a1c1e"))
	draw_circle(c, 4.5, Color("d8d4c4"))
	var p := 0.15
	if state == WARN:
		p = 0.5 + _st * 0.7 + sin(_t * 40.0) * 0.06
	elif state == BLAST:
		p = 0.95 + sin(_t * 50.0) * 0.04
	var a := lerpf(PI * 0.8, PI * 2.2, clampf(p, 0.0, 1.0))
	draw_arc(c, 3.6, PI * 1.85, PI * 2.2, 6, Color(0.8, 0.1, 0.1), 1.2)
	draw_line(c, c + Vector2.from_angle(a) * 3.8, Color(0.1, 0.1, 0.1), 1.0)
