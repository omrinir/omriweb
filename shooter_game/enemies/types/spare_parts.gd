extends "res://enemies/zombie_type.gd"
# ============================================================
#  SPARE PARTS (שלב 12, צפון-מזרח) - זומבי שמשתמש בגוף שלו כתחמושת.
#  צללית: דייג זקן ורזה, גופייה, מכנסיים קצרים מקופלים, תפרים גסים בכל המפרקים
#    (כאילו כבר "תפרו" אותו מחלקים).
#  רצף:
#    1. מתקרב (WALK). במרחק זריקה: תולש את כף היד שלו (RIP_HAND) וזורק אותה עליך בקשת.
#    2. מתיישב (SIT) ותולש רגל אחת (RIP_LEG) -> זורק. ואז את השנייה -> זורק.
#       הרגליים הן רגליים כרותות אמיתיות (severed_leg.gd): נוחתות, וזומבים אחרים יכולים להרים ולזרוק שוב!
#    3. זוחל אליך על יד אחת (CRAWL) - נראה מסכן וחלש, "פיתיון". כשאתה קרוב: תופס לך את הרגל
#       (player.grab -> A/D לסירוגין כדי להשתחרר) ונושך עד שתשתחרר.
#  כל תלישה = אזהרה ברורה (אנימציה + דם), ואפשר להרוג אותו באמצע.
#  צלילים: "sp_rip" (קריעה), "sp_throw", "sp_moan" (גניחה בזחילה).
#  לשנות: THROW_RANGE, RIP_T, CRAWL_SPEED, GRAB_RANGE.
# ============================================================

const LegScript := preload("res://severed_leg.gd")
const Hz := preload("res://environment/s12_hazards.gd")

const SOUNDS := {
	"sp_rip": [["N", 0, 0, 0.0, 0.35, 0.05, 6.0, 0.6, 0.35, 0], ["C", 0, 0, 0.1, 0.25, 0.0, 10.0, 0.6, 1.0, 0], ["S", 160, 70, 0.1, 0.25, 0.0, 10.0, 0.4, 1.0, 0]],
	"sp_throw": [["N", 0, 0, 0.0, 0.2, 0.0, 12.0, 0.5, 0.7, 0], ["S", 500, 200, 0.0, 0.15, 0.0, 14.0, 0.2, 1.0, 0]],
	"sp_moan": [["V", 110, 80, 0.0, 0.9, 0.1, 2.0, 0.35, 1.0, 0.05, 0, [300, 700, 10]], ["N", 0, 0, 0.0, 0.8, 0.1, 2.5, 0.15, 0.2, 0]],
}

const THROW_RANGE := 420.0
const RIP_T := 0.6
const CRAWL_SPEED := 62.0
const GRAB_RANGE := 34.0
const HOLD_MAX := 2.6

enum { WALK, RIP_HAND, SIT, RIP_LEG, CRAWL, HOLD, RECOVER }
var state := WALK
var has_hand := true
var legs := 2
var thrown := 0            # לבדיקות
var grabs := 0
var _st := 0.0
var _cd := 1.0
var _squeeze := 0.0
var _moan := 2.0


func stats() -> Dictionary:
	return {"name": "SPARE PARTS", "hp": 40, "walk": 40.0, "chase": 70.0, "damage": 1, "bite_delay": 1.0, "scale": 1.0, "width": 0.95,
		"duck": 0.0, "cover": 0.1, "skin": Color("a09a86"), "shirt": Color("c8c0a8"), "pants": Color("3a4a6a"), "shoe": Color("4a3a2a"), "points": 360}


func brain_overrides() -> Dictionary:
	return {"keep_range": 300.0, "aggression": -0.2}


func can_bite() -> bool:
	return false


func _low_shape(on: bool) -> void:
	var r := z._shape.shape as RectangleShape2D
	if on:
		r.size = Vector2(46.0, 26.0) * z.sc
		z._shape.position = Vector2(0.0, -13.0 * z.sc)
	else:
		r.size = Vector2(38.0 * z.wf, 66.0 * z.sc)
		z._shape.position = Vector2(0.0, -33.0 * z.sc)


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if state == WALK:
		if has_hand and _cd <= 0.0 and pl != null and not pl.dead and z.is_on_floor():
			var d: Vector2 = pl.global_position - z.global_position
			var sees: bool = z.brain == null or z.brain.sees
			if sees and absf(d.x) < THROW_RANGE and absf(d.y) < 160.0:
				state = RIP_HAND
				_st = RIP_T
				z._dir = signf(d.x) if d.x != 0.0 else z._dir
				Sfx.play("sp_rip", z.global_position, 0.0, 0.1, 3)
				return _stay(delta)
		return false
	if pl != null and state != HOLD and state != CRAWL:
		z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	match state:
		RIP_HAND:
			if _st <= 0.0:
				has_hand = false
				_throw_hand(pl)
				state = SIT
				_st = 0.7
		SIT:
			if _st <= 0.0:
				if legs > 0:
					state = RIP_LEG
					_st = RIP_T
					_low_shape(true)
					Sfx.play("sp_rip", z.global_position, 0.0, 0.1, 3)
				else:
					state = CRAWL
		RIP_LEG:
			if _st <= 0.0:
				legs -= 1
				_throw_leg(pl)
				state = SIT
				_st = 0.75
		CRAWL:
			_moan -= delta
			if _moan <= 0.0:
				_moan = randf_range(2.5, 4.0)
				Sfx.play("sp_moan", z.global_position, -4.0, 0.1, 2)
			if pl != null and not pl.dead:
				var dx: float = pl.global_position.x - z.global_position.x
				z._dir = signf(dx) if dx != 0.0 else z._dir
				var pull := 0.4 + 0.6 * maxf(0.0, sin(z._time * 5.0))   # משיכות על היד
				z.velocity.x = z._dir * CRAWL_SPEED * pull
				if _cd <= 0.0 and absf(dx) < GRAB_RANGE and absf(pl.global_position.y - z.global_position.y) < 30.0 \
						and pl.grabbed_by == null and pl._roll_t <= 0.0 and not pl._climbing:
					_grab(pl)
			else:
				z.velocity.x = 0.0
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			z._walk_phase += delta * 5.0
			return true
		HOLD:
			z.velocity.x = 0.0
			if pl == null or pl.dead or pl.grabbed_by != z:
				_let_go()
			else:
				pl.global_position.x = move_toward(pl.global_position.x, z.global_position.x + z._dir * 16.0, 300.0 * delta)
				pl.velocity.x = 0.0
				_squeeze -= delta
				if _squeeze <= 0.0:
					_squeeze = 0.9
					pl.hurt(z.damage, Vector2.ZERO)
				if _st <= 0.0:
					_let_go()
		RECOVER:
			if _st <= 0.0:
				state = CRAWL
	return _stay(delta)


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _aim_vel(from: Vector2, pl: Node, t: float) -> Vector2:
	var to: Vector2 = pl.global_position + Vector2(0.0, -24.0) if pl != null else from + Vector2(z._dir * 200.0, 0.0)
	var g := 1100.0
	return Vector2((to.x - from.x) / t, (to.y - from.y - 0.5 * g * t * t) / t)


func _throw_hand(pl: Node) -> void:
	var from: Vector2 = z.global_position + Vector2(z._dir * 10.0, -44.0 * z.sc)
	var h := Hz.ThrownHand.new()
	h.skin = z.skin
	z.get_parent().add_child(h)
	h.global_position = from
	var t := clampf(absf((pl.global_position.x if pl != null else from.x) - from.x) / 420.0, 0.45, 1.0)
	h.velocity = _aim_vel(from, pl, t)
	thrown += 1
	Sfx.play("sp_throw", from, 0.0, 0.1, 3)
	Particles.burst(z.get_parent(), from, "hit", Vector2(z._dir, -0.5), 6)


func _throw_leg(pl: Node) -> void:
	var from: Vector2 = z.global_position + Vector2(z._dir * 6.0, -30.0 * z.sc)
	var leg = LegScript.new()
	z.get_parent().add_child(leg)
	leg.setup(from, Vector2.ZERO, z.pants, z.skin, z.shoe, z.sc)
	var t := clampf(absf((pl.global_position.x if pl != null else from.x) - from.x) / 420.0, 0.5, 1.0)
	leg.throw_at(from, _aim_vel(from, pl, t))
	thrown += 1
	Sfx.play("sp_throw", from, 0.0, 0.1, 3)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -6), "hit", Vector2.UP, 10)


func _grab(pl: Node) -> void:
	state = HOLD
	_st = HOLD_MAX
	_squeeze = 0.5
	grabs += 1
	pl.grab(z)
	Sfx.play("grab_crush", z.global_position, 0.0, 0.1, 2)
	z._popup("GOT YOU", Color("ff6050"), 15, -40.0)


func _let_go() -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null
	state = RECOVER
	_st = 1.2
	_cd = 2.5
	z.velocity.x = -z._dir * 60.0


func on_release() -> void:
	state = RECOVER
	_st = 1.3
	_cd = 2.5
	z._popup("SHAKEN OFF", Color(1.0, 0.75, 0.4), 13, -40.0)


func on_death() -> void:
	var pl := player()
	if pl != null and pl.grabbed_by == z:
		pl.grabbed_by = null


# ============================================================
#  ציור
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var pa := col(z.pants)
	var blood := Color(0.5, 0.03, 0.05)
	var t: float = z._time
	var rip_k := clampf(1.0 - _st / RIP_T, 0.0, 1.0)
	if state == WALK or state == RIP_HAND:
		_draw_standing(sk, shirt, pa, blood, rip_k)
	elif state == SIT or state == RIP_LEG:
		_draw_sitting(sk, shirt, pa, blood, rip_k)
	else:
		_draw_crawling(sk, shirt, pa, blood, t)
	end_draw()
	return true


func _stitches(a: Vector2, b: Vector2) -> void:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	for i in 3:
		var c := a.lerp(b, 0.3 + float(i) * 0.2)
		z.draw_line(c - n * 2.0, c + n * 2.0, Color(0.15, 0.1, 0.1), 0.8)


func _draw_standing(sk: Color, shirt: Color, pa: Color, blood: Color, rip_k: float) -> void:
	var f: Array = feet(4.5, 2.0)
	var hip := Vector2(0.0, -22.0 + absf(sin(z._walk_phase)) * 1.0)
	var sh := Vector2(2.0, -38.0)
	var head := sh + Vector2(5.0, -7.0)
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.25)), col(Art.shade(z.skin, 0.2)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], pa, sk, col(z.shoe))
	_stitches(hip + Vector2(1.5, 0), hip + Vector2(3, 8))
	var front_hand := sh + Vector2(11.0, 8.0)
	var back_hand := sh + Vector2(-3.0, 15.0)
	if state == RIP_HAND:   # היד האחורית תופסת את הקדמית ומושכת
		front_hand = sh + Vector2(9.0, 4.0 - rip_k * 4.0)
		back_hand = front_hand + Vector2(2.0 + rip_k * 6.0, 1.0)
	z._arm(sh + Vector2(-3, 2), back_hand, col(Art.shade(z.skin, 0.25)), shirt)
	var body := PackedVector2Array([sh + Vector2(-6, -2), sh + Vector2(6, -1), hip + Vector2(6, -1), hip + Vector2(4, 3), hip + Vector2(-5, 3), sh + Vector2(-7, 5)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.35)
	_stitches(sh + Vector2(-5, 2), sh + Vector2(5, 3))
	_head(head, sk)
	if has_hand:
		z._arm(sh + Vector2(2, 2), front_hand, sk, shirt)
		if state == RIP_HAND and rip_k > 0.4:
			for i in 3:
				z.draw_line(front_hand, front_hand + Vector2(randf_range(-2, 4), randf_range(1, 6)), blood, 1.2)
	else:
		_stump(sh + Vector2(2, 2), sh + Vector2(9.0, 7.0), sk, blood)


func _draw_sitting(sk: Color, shirt: Color, pa: Color, blood: Color, rip_k: float) -> void:
	var hip := Vector2(0.0, -6.0)
	var sh := Vector2(-2.0, -22.0)
	var head := sh + Vector2(5.0, -7.0)
	var pulling := state == RIP_LEG
	for i in 2:   # רגליים קדימה (מה שנשאר)
		var have := i < legs
		if not have:
			_stitches(hip + Vector2(2.0 + float(i) * 2.0, 0), hip + Vector2(6.0 + float(i) * 2.0, 2))
			Art.disc(z, hip + Vector2(4.0 + float(i) * 2.0, 0.0), 2.4, blood, Art.NONE)
			continue
		var foot := hip + Vector2(22.0 - float(i) * 3.0, 6.0)
		if pulling and i == legs - 1:   # הרגל שנתלשת מורמת למעלה
			foot = hip + Vector2(16.0 - rip_k * 8.0, -10.0 - rip_k * 12.0)
		var knee := hip.lerp(foot, 0.5) + Vector2(0.0, -4.0)
		Art.limb(z, PackedVector2Array([hip + Vector2(2, 0), knee, foot]), 6.0, pa if i == 0 else Art.shade(pa, 0.2))
		Art.fill(z, PackedVector2Array([foot + Vector2(-2, -4), foot + Vector2(3, -4), foot + Vector2(4, 1), foot + Vector2(-2, 1)]), col(z.shoe), Art.OUTLINE, 1.0)
		if pulling and i == legs - 1 and rip_k > 0.5:
			for q in 3:
				z.draw_line(hip + Vector2(3, 0), hip + Vector2(3, 0) + Vector2(randf_range(-3, 5), randf_range(-1, 5)), blood, 1.2)
	var body := PackedVector2Array([sh + Vector2(-6, -2), sh + Vector2(6, -1), hip + Vector2(6, -1), hip + Vector2(4, 3), hip + Vector2(-5, 3), sh + Vector2(-7, 5)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.35)
	_head(head, sk)
	var hand := hip + Vector2(14.0, 2.0)
	if pulling and legs > 0:
		hand = hip + Vector2(16.0 - rip_k * 8.0, -10.0 - rip_k * 12.0)
	z._arm(sh + Vector2(-2, 2), hand + Vector2(-2, 1), col(Art.shade(z.skin, 0.25)), shirt)
	_stump(sh + Vector2(2, 2), sh + Vector2(8.0, 6.0), sk, blood)


func _draw_crawling(sk: Color, shirt: Color, pa: Color, blood: Color, t: float) -> void:
	var pull := sin(t * 5.0)
	var hip := Vector2(-14.0, -6.0)
	var sh := Vector2(6.0, -10.0 - maxf(0.0, pull) * 2.0)
	var head := sh + Vector2(8.0, -6.0)
	if state == HOLD:   # נצמד ונושך
		sh += Vector2(4.0, -6.0)
		head = sh + Vector2(6.0, -4.0)
	Art.disc(z, hip + Vector2(-4, 2), 3.0, blood, Art.NONE)   # גדמים
	Art.disc(z, hip + Vector2(-1, 3), 3.0, blood, Art.NONE)
	var body := PackedVector2Array([hip + Vector2(-5, -5), sh + Vector2(2, -5), sh + Vector2(3, 5), hip + Vector2(-5, 5)])
	Art.fill_shaded(z, body, shirt, 0.15, 0.35)
	z.draw_line(hip + Vector2(-5, -1), hip + Vector2(-20, 0), Color(0.45, 0.03, 0.05, 0.7), 2.0)   # שובל דם
	_stump(sh + Vector2(0, 3), sh + Vector2(-3, 8), sk, blood)
	var hand := sh + Vector2(14.0 + pull * 5.0, 9.0)
	if state == HOLD:
		hand = sh + Vector2(14.0, -2.0)
	z._arm(sh + Vector2(2, 2), hand, sk, shirt)
	_head(head, sk)


func _head(head: Vector2, sk: Color) -> void:
	Art.oval_shaded(z, head, 5.6, 6.2, sk, 0.1)
	z.draw_line(head + Vector2(-5, -1), head + Vector2(-1, -5), Color(0.15, 0.1, 0.1), 0.8)   # תפר בקרקפת
	_stitches(head + Vector2(-5, -1), head + Vector2(-1, -5))
	z.draw_circle(head + Vector2(3.0, -1.0), 1.1, Color(0.9, 0.85, 0.5) if not z.dead else Color("2a2a2a"))
	z.draw_line(head + Vector2(1, 3), head + Vector2(5, 3.5), Color(0.2, 0.05, 0.05), 1.2)


func _stump(shoulder: Vector2, end: Vector2, sk: Color, blood: Color) -> void:
	Art.limb(z, PackedVector2Array([shoulder, end]), 4.6, sk)
	Art.disc(z, end, 2.6, blood, Art.NONE)
