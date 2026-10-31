extends "res://enemies/zombie_type.gd"
# ============================================================
#  HANDLER (שלב 27, "PLATEAU GATE") - מאלף כלבים: מעיל ארוך, כפפה עבה, שרוקית, שני כלבי זומבי ברצועה.
#    LEASH   - הולך עם הכלבים קשורים (מצוירים לידו).
#    RELEASE - אתה מתקרב (RELEASE_R) והוא רואה אותך: "SIC 'EM!" -> משחרר את הכלבים (זומבי DOG רגילים, מסתערים).
#    FREE    - שומר מרחק (BACKOFF), ושורק כל WHISTLE_CD: כל הכלבים באזור מסתערים עליך שוב.
#  הרגת אותו לפני שהוא שחרר = הכלבים לא משתחררים (לצלוף בו מרחוק!).
#  לשנות: RELEASE_R, DOGS, WHISTLE_CD, BACKOFF.
# ============================================================

const SOUNDS := {
	"hd_whistle": [["S", 3000, 3300, 0.0, 0.18, 0.01, 4.0, 0.3, 1.0, 0.08], ["S", 3300, 2700, 0.22, 0.25, 0.0, 4.0, 0.3, 1.0, 0.08]],
}

const DOG_KIND := 15         # זומבי DOG (zombie.gd)
const RELEASE_R := 480.0
const DOGS := 2
const WHISTLE_CD := 6.0
const BACKOFF := 240.0

enum { LEASH, FREE }
var state := LEASH
var released := 0            # לבדיקות
var whistles := 0
var _cd := 0.0
var _anim := 0.0


func stats() -> Dictionary:
	return {"name": "HANDLER", "hp": 40, "walk": 44.0, "chase": 90.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 1.0,
		"duck": 0.1, "cover": 0.3, "skin": Color("8a9a88"), "shirt": Color("4a3e30"), "pants": Color("3a3428"), "shoe": Color("1e1a14"), "points": 500}


func can_bite() -> bool:
	return true


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_anim -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	if not has_pl:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		LEASH:
			var sees: bool = (z.brain == null or z.brain.sees) or absf(d.x) < 360.0
			if sees and absf(d.x) < RELEASE_R and absf(d.y) < 120.0 and z.is_on_floor():
				_release(pl)
				return _stay(delta)
			return false
		FREE:
			if _cd <= 0.0:
				_cd = WHISTLE_CD
				_whistle(pl)
			if absf(d.x) < BACKOFF and absf(d.y) < 80.0 and not z.is_on_wall() and z.is_on_floor():
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.5, 700.0 * delta)
				z.velocity.y += z.gravity * delta
				z.move_and_slide()
				return true
			return false
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _release(pl: Node) -> void:
	state = FREE
	_cd = WHISTLE_CD
	_anim = 0.5
	z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
	z._popup("SIC 'EM!", Color("ff8040"), 16, -80.0)
	Sfx.play("hd_whistle", z.global_position, 2.0, 0.05, 2)
	var main: Node = z.get_parent()
	if main == null or not main.has_method("_spawn_zombie"):
		return
	for i in DOGS:
		var dog: Node = main._spawn_zombie(z.global_position.x + z._dir * (14.0 + float(i) * 14.0), z.global_position.y, DOG_KIND)
		if dog != null:
			dog.dormant = false
			dog.position.y = z.global_position.y
			dog._dir = z._dir
			dog._alert_t = 6.0
			dog._rush_t = 3.0
			released += 1
	Sfx.play("growl", z.global_position, 2.0, 0.1, 2)


func _whistle(pl: Node) -> void:
	whistles += 1
	_anim = 0.4
	Sfx.play("hd_whistle", z.global_position, 0.0, 0.05, 2)
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o.dead or o.kind != DOG_KIND or o.global_position.distance_to(z.global_position) > 900.0:
			continue
		o._alert_t = maxf(float(o._alert_t), 5.0)
		o._rush_t = 2.5
		o.hear_noise(pl.global_position, 99999.0)


# ============================================================
#  ציור: מעיל ארוך, כפפה, שרוקית. LEASH = שני כלבים קשורים לידו (צלליות עם עיניים אדומות)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -38)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(8, 9), hip + Vector2(-8, 9)]), coat, 0.15, 0.4)
	DrawBatch.rect(z, Rect2(hip + Vector2(-7, -3), Vector2(15, 3)), col(Color("2a2018")))
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	face(head)
	Art.fill(z, PackedVector2Array([head + Vector2(-6, -2), head + Vector2(-5, -6), head + Vector2(4, -7), head + Vector2(7, -3)]), col(Color("3a3226")), Art.OUTLINE, 0.9)   # כובע צמר
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -0.5), 0.9, Color(1.0, 0.5, 0.2))
	var hand: Vector2
	if _anim > 0.0 and not z.dead:   # שורק: יד לפה
		hand = head + Vector2(5, 3)
		DrawBatch.line(z, hand, hand + Vector2(3, 0), col(Color("c8c8cc")), 2.0)
	else:
		hand = sh + Vector2(10.0 + sin(p) * 2.0, 12.0)
	z._arm(sh + Vector2(3, 1), hand, sk, coat)
	DrawBatch.circle(z, hand, 2.6, col(Color("5a4030")))   # כפפה
	if state == LEASH and not z.dead:   # הכלבים ברצועה
		for i in DOGS:
			var dp := Vector2(16.0 + float(i) * 15.0 + sin(z._time * 3.0 + float(i)) * 2.0, 0)
			var bob := absf(sin(p + float(i) * 1.7)) * 1.5
			var body := PackedVector2Array([dp + Vector2(-9, -7 - bob), dp + Vector2(4, -9 - bob), dp + Vector2(7, -6 - bob), dp + Vector2(5, -3), dp + Vector2(-9, -3)])
			Art.fill(z, body, col(Color("4a4440")), Art.OUTLINE, 1.0)
			Art.fill(z, PackedVector2Array([dp + Vector2(4, -12 - bob), dp + Vector2(11, -11 - bob), dp + Vector2(12, -8 - bob), dp + Vector2(5, -7 - bob)]), col(Color("4a4440")), Art.OUTLINE, 1.0)   # ראש
			DrawBatch.line(z, dp + Vector2(5, -12 - bob), dp + Vector2(6, -15 - bob), col(Color("3a3430")), 1.6)   # אוזן
			for lx in [-7.0, -3.0, 2.0, 5.0]:
				DrawBatch.line(z, dp + Vector2(lx, -3), dp + Vector2(lx + sin(p * 2.0 + lx) * 1.5, 0), col(Color("3a3430")), 1.6)
			DrawBatch.circle(z, dp + Vector2(9, -10 - bob), 0.9, Color(1.0, 0.25, 0.15))
			DrawBatch.line(z, hand, dp + Vector2(4, -9 - bob), col(Color("2a2018")), 1.0)   # רצועה
	end_draw()
	return true
