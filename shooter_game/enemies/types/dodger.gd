extends "res://enemies/zombie_type.gd"
# ============================================================
#  DODGER (שלב 8) - נבדק בחליפת מגן צהובה קרועה עם מסכת גז. רואה את הקנה שלך.
#  צללית: כפוף קדימה כמו אצן בזינוק, רגליים ארוכות, ברדס חליפה + מסכה עם 2 עדשות
#         כתומות זוהרות ומיכל פילטר. פסים שחורים על הגפיים.
#  תנועה: לא צפויה - דחיפות קצרות, עצירות, צעד אחורה, ואז שוב קדימה (כל 0.35-0.8 שנ').
#  התחמקות: כשאתה יורה והקנה מכוון אליו - לפעמים (DODGE_CHANCE) הוא מתחמק:
#    קו הירייה גבוה (ראש) -> נזרק לשכיבה ומחליק; נמוך/גוף -> סלטה מעל הקליע.
#    בזמן ההתחמקות (0.28 שנ') קליעים עוברים דרכו. אחר כך יש COOLDOWN - אז אפשר לפגוע בו!
#    (צרור קצר: הכדור הראשון מתפספס, השאר פוגעים). מכוונים אליו הרבה זמן -> מתחיל לזגזג.
#  התקפה: אחרי התחמקות - הסתערות נגדית מהירה ושריטה.
#  צליל: "dodge_whoosh" (שריקת אוויר חדה) + "dodger_chitter" (קליקים מהירים מאחורי המסכה).
#  לשנות: DODGE_CHANCE, DODGE_CD (כמה זמן עד ההתחמקות הבאה), IFRAMES.
# ============================================================

const SOUNDS := {
	"dodge_whoosh": [["N", 0, 0, 0.0, 0.22, 0.02, 14.0, 0.55, 0.55, 0, 0.25], ["S", 700, 1500, 0.0, 0.12, 0.0, 30.0, 0.12, 1.0, 0]],
	"dodger_chitter": [["C", 0, 0, 0.0, 0.35, 0.0, 6.0, 0.8, 1.0, 0], ["S", 1700, 1500, 0.0, 0.03, 0.0, 80.0, 0.2, 1.0, 0], ["S", 1800, 1600, 0.09, 0.03, 0.0, 80.0, 0.2, 1.0, 0], ["S", 1650, 1450, 0.18, 0.03, 0.0, 80.0, 0.2, 1.0, 0]],
}

const DODGE_CHANCE := 0.6
const DODGE_CD := Vector2(1.6, 2.4)
const IFRAMES := 0.28

enum { RUN, LEAP, DROP }
var state := RUN
var _t := 0.0                 # זמן במצב ההתחמקות
var _cd := 0.0
var _side := 1.0
var _last_shots := 0
var _move_t := 0.0
var _move_k := 1.0
var _aimed_t := 0.0
var _counter_t := 0.0
var _spin := 0.0
var _trail := []              # [מיקום בעולם, גיל]
var _chitter_t := 2.0
var dodges := 0               # לבדיקות


func stats() -> Dictionary:
	return {"name": "DODGER", "hp": 22, "walk": 70.0, "chase": 150.0, "damage": 1, "bite_delay": 0.6, "scale": 0.95, "width": 0.8,
		"duck": 0.0, "cover": 0.0, "skin": Color("a8b89a"), "shirt": Color("c9a62a"), "pants": Color("b8961e"), "shoe": Color("1c1c1c"), "points": 240}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.1, "flank_probability": 0.15, "hazard_awareness": 0.1}


func setup() -> void:
	_last_shots = PlayerMemory.shots_total


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_counter_t -= delta
	for tr in _trail:
		tr[1] += delta
	_trail = _trail.filter(func(tr: Array) -> bool: return float(tr[1]) < 0.3)
	if pl == null or pl.dead or z.dead:
		_end_iframes()
		state = RUN
		return false
	var shots: int = PlayerMemory.shots_total
	var fired := shots != _last_shots
	_last_shots = shots
	if state != RUN:
		return _dodging(delta)
	if fired and _cd <= 0.0 and z.is_on_floor():
		_try_dodge(pl)
		if state != RUN:
			return true
	return false


# הירייה מכוונת אליו? (מהכתף של השחקן לכיוון _aim)
func _try_dodge(pl: Node) -> void:
	var origin: Vector2 = pl.global_position + Vector2(0.0, -37.0)
	var aim: Vector2 = pl._aim
	var me: Vector2 = z.global_position + Vector2(0.0, -30.0 * z.sc)
	var to_me := me - origin
	var dist := to_me.length()
	if dist < 70.0 or dist > 720.0 or aim.dot(to_me.normalized()) < 0.96:
		return
	_cd = randf_range(DODGE_CD.x, DODGE_CD.y)   # גם אם לא הצליח - צריך זמן להתאושש
	if randf() > DODGE_CHANCE:
		return
	# באיזה גובה הקליע יעבור ליד הזומבי
	var line_y := origin.y + (aim.y / maxf(absf(aim.x), 0.05)) * absf(z.global_position.x - origin.x)
	var toward: float = signf(origin.x - z.global_position.x)
	_side = toward if randf() < 0.55 else -toward
	dodges += 1
	_t = 0.0
	z.collision_layer = 0   # הקליעים עוברים דרכו
	_trail.clear()
	Sfx.play("dodge_whoosh", z.global_position, 0.0, 0.15, 3)
	if line_y < z.global_position.y - 40.0 * z.sc:   # יורים לראש: נזרק לרצפה
		state = DROP
		z.velocity = Vector2(_side * 330.0, 0.0)
	else:   # יורים לגוף: סלטה מעל
		state = LEAP
		z.velocity = Vector2(_side * 190.0, -520.0)
		_spin = 0.0
	if Art.on_screen(z, z.global_position) and randf() < 0.5:
		z._popup("DODGE", Color(0.6, 0.95, 1.0), 12, -70.0)


func _dodging(delta: float) -> bool:
	_t += delta
	if _t >= IFRAMES:
		_end_iframes()
	if Engine.get_physics_frames() % 3 == 0:
		_trail.append([z.global_position, 0.0])
	z.velocity.y += z.gravity * delta
	if state == DROP:
		z.velocity.x = move_toward(z.velocity.x, 0.0, 700.0 * delta)
	else:
		_spin += delta * 15.0 * _side
	z.move_and_slide()
	if (_t > 0.2 and z.is_on_floor() and state == LEAP) or (state == DROP and _t > 0.5):
		state = RUN
		_end_iframes()
		_counter_t = 0.7   # הסתערות נגדית
		Sfx.play("dodger_chitter", z.global_position, -4.0, 0.15, 2)
	return true


func _end_iframes() -> void:
	if not z.dead and z.collision_layer == 0:
		z.collision_layer = 4


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_move_t -= delta
	_chitter_t -= delta
	var dist := absf(d.x)
	var toward: float = signf(d.x) if d.x != 0.0 else z._dir
	if _chitter_t <= 0.0:
		_chitter_t = randf_range(3.0, 6.0)
		if Art.on_screen(z, z.global_position):
			Sfx.play("dodger_chitter", z.global_position, -8.0, 0.2, 2)
	if _counter_t > 0.0:
		z._dir = toward
		return speed * 1.5
	# מכוונים אליו הרבה זמן: מזגזג (צפוי פחות)
	var me: Vector2 = z.global_position + Vector2(0.0, -30.0) - pl.global_position
	if pl._aim.dot(me.normalized()) > 0.95:
		_aimed_t += delta
	else:
		_aimed_t = maxf(_aimed_t - delta * 2.0, 0.0)
	if dist < 80.0:
		return speed
	if _move_t <= 0.0:
		_move_t = randf_range(0.35, 0.8) * (0.6 if _aimed_t > 0.45 else 1.0)
		var r := randf()
		_move_k = 1.55 if r < 0.45 else (0.0 if r < 0.7 else (-0.6 if r < 0.85 else 1.0))
		if _aimed_t > 0.45 and z.is_on_floor() and randf() < 0.35:
			z.velocity.y = z.jump_velocity * 0.5   # קפיצה קטנה הצידה
	if _move_k < 0.0:
		z._dir = -z._dir if z._dir == toward else z._dir
		return speed * 0.6
	return speed * _move_k


func draw() -> bool:
	var suit := col(z.shirt)
	var suit_d := col(Art.shade(z.shirt, 0.3))
	var stripe := col(Color(0.08, 0.08, 0.08))
	var lens := Color(1.0, 0.55, 0.1)
	# שובל רפאים בזמן התחמקות (בעולם, לפני הטרנספורם)
	for tr in _trail:
		var tp: Vector2 = tr[0]
		var a: float = 0.35 * (1.0 - float(tr[1]) / 0.3)
		var lp: Vector2 = tp - z.global_position
		Art.oval(z, lp + Vector2(0, -24.0 * z.sc), 8.0 * z.sc, 18.0 * z.sc, Color(1.0, 0.85, 0.3, a), 0.0, Art.NONE)
	if state == LEAP and not z.dead:   # סלטה: מסתובב סביב המרכז
		var s := Vector2(z._dir * z.wf * z.sc, z.sc)
		z.draw_set_transform_matrix(Transform2D(_spin, Vector2(0.0, -26.0 * z.sc)) * Transform2D(0.0, s, 0.0, Vector2(0.0, 26.0 * z.sc)))
	elif state == DROP and not z.dead:   # שוכב ומחליק
		var s2 := Vector2(z._dir * z.wf * z.sc, z.sc)
		var ang := -PI / 2.0 * signf(z._dir) * 0.92
		z.draw_set_transform_matrix(Transform2D(ang, Vector2(0.0, -8.0 * z.sc)) * Transform2D(0.0, s2, 0.0, Vector2(0.0, 8.0 * z.sc)))
	else:
		begin_draw()
	var p: float = z._walk_phase
	var f: Array = feet(7.5, 4.0)
	if state != RUN and not z.dead:
		f = [Vector2(6, -10), Vector2(-6, -8)]
	var hip := Vector2(-3.0, -21.0 + absf(sin(p)) * 1.5)
	var sh := Vector2(8.0, -35.0)
	var head := sh + Vector2(7.0, -3.0)
	# רגליים ארוכות עם פסים
	for i in 2:
		var fp: Vector2 = f[1 - i]
		var hp := hip + Vector2(-1.5 + 3.0 * float(i), 0.0)
		var c := suit_d if i == 0 else suit
		z._leg(hp, fp, c, c, col(z.shoe))
		var knee := Art.joint(hp, fp + Vector2(0, -3), 11.5, 11.5, 1.0)
		z.draw_line(knee + Vector2(-2.5, 1), knee + Vector2(2.5, 2), stripe, 1.6)
	# יד אחורית
	var bh := sh + Vector2(-6.0 + sin(p) * 8.0, 13.0)
	if z._bite_anim > 0.0:
		bh = sh + Vector2(17.0, 2.0)
	z._arm(sh + Vector2(-2, 1), bh, suit_d, suit_d)
	# גוף: חליפה כפופה
	var body := PackedVector2Array([hip + Vector2(-6, 3), hip + Vector2(5, 2), sh + Vector2(5, 4), sh + Vector2(1, -3), sh + Vector2(-6, -2)])
	Art.fill_shaded(z, body, suit, 0.2, 0.35)
	z.draw_line(hip.lerp(sh, 0.5) + Vector2(-5, 0), hip.lerp(sh, 0.5) + Vector2(4, -1), stripe, 2.0)   # פס מחזיר
	z.draw_line(hip.lerp(sh, 0.62) + Vector2(-5, 0), hip.lerp(sh, 0.62) + Vector2(4, -1), col(Color(0.85, 0.85, 0.8)), 1.0)
	# קרע בחליפה: עור חשוף
	Art.oval(z, hip.lerp(sh, 0.3) + Vector2(1, 0), 2.5, 1.8, col(z.skin), 0.4, Art.NONE)
	# מיכל חמצן קטן על הגב
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, 0), sh + Vector2(-4, -2), sh + Vector2(-3, 10), sh + Vector2(-8, 11)]), col(Color("5a6066")), 0.2, 0.3, Art.OUTLINE, 1.0)
	# ברדס + מסכת גז
	Art.oval_shaded(z, head, 6.5, 6.0, suit, 0.3)
	Art.fill_shaded(z, PackedVector2Array([head + Vector2(0, -4), head + Vector2(7, -3), head + Vector2(8, 3), head + Vector2(2, 5)]), col(Color("2a2c30")), 0.2, 0.3, Art.OUTLINE, 1.0)
	for e in [Vector2(3.5, -1.5), Vector2(6.5, -1.0)]:
		var ev: Vector2 = e
		z.draw_circle(head + ev, 1.8, col(Color("101010")))
		z.draw_circle(head + ev, 1.2, lens)
		Art.glow(z, head + ev, 3.5, Color(lens, 0.5))
	Art.disc(z, head + Vector2(6.5, 4.5), 2.3, col(Color("4a4e54")), Art.OUTLINE, 0.9)   # פילטר
	z.draw_line(head + Vector2(5.5, 4.5), head + Vector2(7.5, 4.5), col(Color("2a2a2a")), 0.8)
	# יד קדמית (פרושה לאיזון)
	var fh := sh + Vector2(10.0 - sin(p) * 8.0, 11.0)
	if z._bite_anim > 0.0 or _counter_t > 0.0:
		fh = sh + Vector2(19.0, 0.0)
	z._arm(sh + Vector2(2, 1), fh, col(z.skin), suit)
	z.draw_line(sh.lerp(fh, 0.55) + Vector2(-1, -2), sh.lerp(fh, 0.55) + Vector2(1, 2), stripe, 1.5)
	end_draw()
	return true
