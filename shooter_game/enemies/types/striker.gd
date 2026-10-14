extends "res://enemies/zombie_type.gd"
# ============================================================
#  STRIKER (שלב 39, "THE STADIUM") - חלוץ זומבי: חולצת נבחרת צהובה עם מספר 9, נעלי פקקים, כדור.
#  "THEY LEARNED TO SHOOT": שומר מרחק (KEEP) ובועט כדור (Ball) חזק אליך (מקדים לאן שאתה הולך).
#    הכדור קופץ על הקרקע ועל במות אמיתיות (גוף פיזיקלי) ונעצר בקירות. התחבאת מאחורי מחסה? הכדור נעצר בו - והוא לומד: מעכשיו מקפיץ "לוב" מעל המחסה.
#    ירייה בכדור באוויר -> הכדור עף בחזרה אליו (פוגע בו ומשתק אותו).
#  לשנות: KEEP, KICK_CD, BALL_V.
# ============================================================

const SOUNDS := {
	"sk_kick": [["N", 0, 0, 0.0, 0.1, 0.0, 30.0, 0.7, 0.3, 0], ["S", 200, 90, 0.0, 0.1, 0.0, 30.0, 0.5, 1.0, 0]],
	"sk_bounce": [["S", 300, 200, 0.0, 0.08, 0.0, 40.0, 0.3, 1.0, 0]],
	"sk_whistle": [["S", 2800, 2900, 0.0, 0.3, 0.02, 8.0, 0.15, 1.0, 0.06]],
}

const KEEP := Vector2(260.0, 460.0)
const KICK_CD := 2.6
const BALL_V := 620.0

enum { PLAY, WIND, STUN }
var state := PLAY
var kicks := 0               # לבדיקות
var ball_hits := 0
var returned := 0
var chip := false
var _st := 0.0
var _cd := 1.5


func stats() -> Dictionary:
	return {"name": "STRIKER", "hp": 30, "walk": 48.0, "chase": 92.0, "damage": 1, "bite_delay": 0.7, "scale": 1.0, "width": 1.0,
		"duck": 0.2, "cover": 0.1, "skin": Color("7a8a6c"), "shirt": Color("f0d020"), "pants": Color("2a4ab0"), "shoe": Color("1a1a1a"), "points": 480}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.25}


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == STUN else 1.0


func stun() -> void:   # הכדור חזר אליו
	returned += 1
	state = STUN
	_st = 1.6
	z._popup("OWN GOAL!", Color("ffe060"), 14, -80.0)


func blocked() -> void:   # הכדור נעצר במחסה - לומד
	if not chip:
		chip = true
		z._popup("HE WILL CHIP IT OVER", Color("ffe060"), 12, -80.0)


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		STUN:
			if _st <= 0.0:
				state = PLAY
			return _move(0.0, delta)
		WIND:
			if _st <= 0.0:
				_kick(pl)
				state = PLAY
				_cd = KICK_CD
			return _move(-z._dir * 40.0, delta)
	if absf(d.y) > 120.0 or absf(d.x) > 700.0:
		return false
	z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
	if _cd <= 0.0 and absf(d.x) < KEEP.y + 80.0:
		state = WIND
		_st = 0.45
		return _move(0.0, delta)
	if absf(d.x) < KEEP.x:
		return _move(-z._dir * float(z.walk_speed) * 1.5, delta)
	if absf(d.x) < KEEP.y:
		return _move(0.0, delta)
	return false


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 700.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall() and vx != 0.0:
		z.velocity.y = -380.0
	z.move_and_slide()
	return true


func _kick(pl: Node) -> void:
	kicks += 1
	Sfx.play("sk_kick", z.global_position, 0.0, 0.1, 3)
	var b := Ball.new()
	b.owner_s = self
	b.position = z.global_position + Vector2(z._dir * 14.0, -12.0)   # (לפני add_child: _ready בודק שהוא לא בתוך מכשול)
	z.get_parent().add_child(b)
	var tgt: Vector2 = pl.global_position + Vector2(pl.velocity.x * 0.35, -24.0)
	if chip:   # לוב מעל המחסה
		var fl := clampf(absf(tgt.x - b.global_position.x) / 420.0, 0.6, 1.3)
		b.vel = Vector2((tgt.x - b.global_position.x) / fl, (tgt.y - b.global_position.y) / fl - 0.5 * Ball.GRAV * fl)
	else:   # בעיטה חזקה ישירה (עם קשת קטנה שמפצה על הכובד)
		var dx: float = tgt.x - b.global_position.x
		var t: float = maxf(absf(dx) / BALL_V, 0.15)
		b.vel = Vector2(signf(dx) * BALL_V, (tgt.y - b.global_position.y) / t - 0.5 * Ball.GRAV * t)


# ============================================================
#  הכדור: גוף פיזיקלי אמיתי (CharacterBody2D + move_and_collide) - קופץ על רצפה, במות ומכשולים אמיתיים,
#  נעצר בקירות, מתגלגל ונעצר. פוגע בשחקן פעם אחת (רק כשהוא מהיר). ירייה בו = עף בחזרה אל הבועט (מתביית עליו).
#  נעלם: אחרי LIFE שניות, או כשהוא שוכב בלי לזוז REST_T שניות (דוהה), או כשנפל מחוץ לעולם.
# ============================================================
class Ball extends CharacterBody2D:
	const GRAV := 900.0
	const R := 8.0
	const LIFE := 4.0
	const REST_T := 0.8
	const BACK_V := 720.0
	var owner_s = null
	var vel := Vector2.ZERO
	var floor_y := 630.0          # (לא בשימוש יותר - נשאר בשביל קוד ישן)
	var back := false
	var _t := 0.0
	var _hit := false
	var _spin := 0.0
	var _rest := 0.0
	var _back_t := 0.0
	var _fade := 1.0

	func _ready() -> void:
		z_index = 8
		collision_layer = 4          # קליעים פוגעים בו (take_damage)
		collision_mask = 1 | 16      # עולם + במות (one-way: נוחת עליהן מלמעלה)
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = R
		cs.shape = sh
		add_child(cs)
		if test_move(global_transform, Vector2.ZERO):   # נבעט מתוך מכשול - מרימים אותו מעליו
			for k in 6:
				global_position.y -= 8.0
				if not test_move(global_transform, Vector2.ZERO):
					break

	func _owner_ok() -> bool:
		return owner_s != null and is_instance_valid(owner_s.z) and not owner_s.z.dead

	func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
		if back or not _owner_ok():
			return
		back = true   # עף בחזרה אל הבועט
		_back_t = 0.0
		_rest = 0.0
		vel = (owner_s.z.global_position + Vector2(0, -30) - global_position).normalized() * BACK_V
		preload("res://sfx.gd").play("sk_bounce", global_position, 0.0, 0.1, 2)

	func _physics_process(delta: float) -> void:
		_t += delta
		if back:
			_back_t += delta
			if not _owner_ok() or _back_t > 1.4:   # הבועט מת / ברח - הכדור פשוט נופל
				back = false
			else:   # מתביית על הבועט (גם אם זז)
				var to_o: Vector2 = owner_s.z.global_position + Vector2(0, -30) - global_position
				vel = vel.lerp(to_o.normalized() * BACK_V, minf(1.0, 8.0 * delta))
				if to_o.length() < 26.0:
					owner_s.stun()
					owner_s.z.take_damage(10, global_position, vel.normalized(), false, {"source": "ball", "fixed": 10})
					queue_free()
					return
		else:
			vel.y += GRAV * delta
		_spin += vel.x * delta * 0.12
		if back:   # עף בחזרה: ישר אל הבועט, דרך מכשולים (OWN GOAL בטוח)
			global_position += vel * delta
			queue_redraw()
			return
		var col := move_and_collide(vel * delta)
		if col != null:
			var n := col.get_normal()
			if n.y < -0.6:   # רצפה / במה / ראש מכשול
				vel.y = -absf(vel.y) * 0.55
				vel.x *= 0.82
				if absf(vel.y) < 70.0:   # מתגלגל
					vel.y = 0.0
				elif absf(vel.y) > 90.0:
					preload("res://sfx.gd").play("sk_bounce", global_position, -6.0, 0.1, 3)
			elif n.y > 0.6:   # תקרה
				vel.y = absf(vel.y) * 0.4
			else:   # קיר / מחסה
				if not _hit and _owner_ok():
					owner_s.blocked()
				vel.x = -vel.x * 0.4
			move_and_collide(col.get_remainder().slide(n) * 0.5)
		# פוגע בשחקן
		var pl := get_tree().get_first_node_in_group("player")
		if not back and not _hit and vel.length() > 160.0 and pl != null and not pl.dead and pl.body_rect().grow(R - 2.0).has_point(global_position):
			_hit = true
			if _owner_ok():
				owner_s.ball_hits += 1
			pl.hurt(1, Vector2(signf(vel.x) * 1.8, -0.8))
			vel = Vector2(-vel.x * 0.3, -220.0)
		# מתגלגל לאט על הרצפה -> נעצר ונעלם
		if absf(vel.y) < 1.0 and absf(vel.x) < 25.0 and test_move(global_transform, Vector2(0, 2)):
			vel.x = move_toward(vel.x, 0.0, 200.0 * delta)
			_rest += delta
		elif test_move(global_transform, Vector2(0, 2)):
			vel.x = move_toward(vel.x, 0.0, 60.0 * delta)   # חיכוך גלגול
		if _t > LIFE or _rest > REST_T:
			_fade -= delta * 3.0
			if _fade <= 0.0:
				queue_free()
				return
		if global_position.y > 3000.0:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := clampf(_fade, 0.0, 1.0)
		draw_circle(Vector2.ZERO, R + 0.5, Color(0.1, 0.1, 0.1, a))
		draw_circle(Vector2.ZERO, R - 0.5, Color(0.97, 0.97, 0.97, a))
		for q in 5:
			draw_circle(Vector2.from_angle(_spin + float(q) * TAU / 5.0) * 4.5, 1.8, Color(0.1, 0.1, 0.1, a))
		if vel.length() > 400.0:
			draw_line(-vel.normalized() * 22.0, -vel.normalized() * 9.0, Color(1, 1, 1, 0.35 * a), 5.0)


# ============================================================
#  ציור: חולצה צהובה עם 9 (פס ירוק), מכנסיים כחולים, גרביים לבנות; בהכנה לבעיטה - רגל אחורה
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	if state == WIND:
		f = [Vector2(-10, -6), Vector2(-2, 0)]
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Color("f0f0f0")), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(Color("f0f0f0")), sk, col(z.shoe))
	z.draw_rect(Rect2(hip + Vector2(-6, -2), Vector2(12, 8)), col(z.pants))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-6.0 - sin(p) * 2.0, 14.0), Art.shade(sk, 0.25), Art.shade(z.shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, -1), hip + Vector2(-7, -1)]), col(z.shirt), 0.12, 0.4)
	z.draw_line(sh + Vector2(-7, -1), sh + Vector2(7, 0), col(Color("2a8a3a")), 2.0)   # צווארון ירוק
	z.draw_arc(sh + Vector2(0, 6), 2.2, 0.0, TAU, 8, col(Color("2a8a3a")), 1.2)   # 9
	z.draw_line(sh + Vector2(2.2, 6), sh + Vector2(1.5, 12), col(Color("2a8a3a")), 1.2)
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	z.draw_colored_polygon(Art.ellipse(head + Vector2(-1, -3), 5.0, 3.0, 0.0, 10), col(Color("1a1410")))
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.1, Color(1.0, 0.85, 0.4))
		if state == STUN:
			for q in 3:
				var a: float = z._time * 6.0 + float(q) * TAU / 3.0
				z.draw_circle(head + Vector2(cos(a) * 7.0, -9.0 + sin(a) * 2.0), 1.2, Color(1.0, 0.95, 0.5))
	z._arm(sh + Vector2(3, 1), sh + Vector2(10, 6 + sin(p) * 2.0), sk, col(z.shirt))
	end_draw()
	return true
