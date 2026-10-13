extends "res://enemies/zombie_type.gd"
# ============================================================
#  THE GENERAL - מפקד הזומבים של הרמה המרכזית. הבוס של שלב 26 וגם של שלב 27 (הסיפור ממשיך):
#    מעיל צבאי, כובע מצחייה עם סרט אדום, מדליות, אקדח. בשלב 27 - שריון, יד חבושה (מהבריחה) וחרב.
#
#  שלב 26 ("THE BUNKER"):
#    COMMAND - שומר מרחק (KEEP), יורה צרורות (AIM -> 3 כדורים), ובכל ORDER_CD שורק: כל הזומבים סביבו מסתערים.
#    ESCAPE  - כשנשאר לו ESCAPE_AT מהחיים: "RETREAT! TO THE GATE!" - בלתי פגיע, השער נפתח, והוא בורח ימינה במנהרה.
#
#  שלב 27 ("PLATEAU GATE") - LAST STAND:
#    שלב א' - כמו קודם + ARTILLERY: מזמין 3 פגזים סביבך (Shell: עיגול אזהרה + שריקה + פיצוץ).
#    שלב ב' (מתחת ל-RAGE_AT) - "NO MORE RETREAT!": שולף חרב ומסתער (WIND -> DASH -> TIRED = החלון, נזק x1.5).
#
#  לשנות: KEEP, BURST, ORDER_CD, ESCAPE_AT, SHELL_CD, RAGE_AT, DASH_V.
# ============================================================

const Slug := preload("res://enemies/types/revolver.gd").Slug

const SOUNDS := {
	"gn_whistle": [["S", 2600, 2900, 0.0, 0.35, 0.02, 2.0, 0.35, 1.0, 0.06], ["S", 2900, 2400, 0.4, 0.3, 0.0, 3.0, 0.3, 1.0, 0.06]],
	"gn_shell": [["S", 1800, 500, 0.0, 0.9, 0.05, 0.5, 0.25, 1.0, 0], ["N", 0, 0, 0.0, 0.9, 0.3, 1.0, 0.1, 0.3, 0]],
}

const KEEP := Vector2(320.0, 460.0)
const BURST := 3
const AIM_T := 0.55
const ORDER_CD := 7.0
const ESCAPE_AT := 0.35
const SHELL_CD := 5.0
const RAGE_AT := 0.5
const DASH_V := 460.0

enum { COMMAND, AIM, ESCAPE, WIND, DASH, TIRED }
var state := COMMAND
var escaped := false         # לבדיקות
var shots := 0
var orders := 0
var shells := 0
var dashes := 0
var rage := false
var _st := 0.0
var _shoot_cd := 1.5
var _order_cd := 3.0
var _shell_cd := 2.5
var _left := 0
var _burst_t := 0.0
var _aim := 0.0
var _hit := false


func _final() -> bool:   # שלב 27 = הקרב האחרון
	return Game.level != 26


func stats() -> Dictionary:
	if _final():
		return {"name": "GENERAL", "hp": 520, "walk": 50.0, "chase": 96.0, "damage": 2, "bite_delay": 0.9, "scale": 1.6, "width": 1.1,
			"duck": 0.0, "cover": 0.0, "skin": Color("8a9a88"), "shirt": Color("3a4630"), "pants": Color("2e3626"), "shoe": Color("161612"),
			"points": 1600, "boss": true, "boss_name": "THE GENERAL - NO MORE RETREAT"}
	return {"name": "GENERAL", "hp": 420, "walk": 50.0, "chase": 96.0, "damage": 2, "bite_delay": 0.9, "scale": 1.5, "width": 1.05,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9a88"), "shirt": Color("3a4630"), "pants": Color("2e3626"), "shoe": Color("161612"),
		"points": 1200, "boss": true, "boss_name": "THE GENERAL - HE COMMANDS THEM"}


func can_bite() -> bool:
	return state == COMMAND


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == TIRED else 1.0


func on_damage(amount: int, _hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if state == ESCAPE:
		return false
	if not _final():   # שלב 26: לא מת - בורח כשהחיים נמוכים
		var dmg := maxi(amount, int(src.get("fixed", 0))) * 2
		if float(z.hp - dmg) <= float(z.max_hp) * ESCAPE_AT:
			_escape.call_deferred()
			return false
	elif not rage and float(z.hp - amount) <= float(z.max_hp) * RAGE_AT:
		_rage.call_deferred()
	return true


func _rage() -> void:
	if rage or z == null or not is_instance_valid(z) or z.dead:
		return
	rage = true
	z._popup("NO MORE RETREAT!", Color("ff5040"), 20, -130.0)
	Sfx.play("roar", z.global_position, 4.0, 0.05, 2, 0.8)
	state = COMMAND
	_shoot_cd = 1.0


func _escape() -> void:
	if escaped or z == null or not is_instance_valid(z) or z.dead:
		return
	escaped = true
	state = ESCAPE
	z.hp = maxi(z.hp, int(float(z.max_hp) * ESCAPE_AT))
	z._popup("RETREAT!  TO THE GATE!", Color("ffb040"), 20, -130.0)
	Sfx.play("gn_whistle", z.global_position, 4.0, 0.0, 2)
	z._drop(3)   # BOOST
	z._drop(2)   # SUPPLY
	z.get_tree().call_group("level_exit", "on_boss_dead")
	var pl := player()
	if pl != null:
		pl._say("HE'S RUNNING... AFTER HIM!", Color("ffd080"))


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_shoot_cd -= delta
	_order_cd -= delta
	_shell_cd -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	if state == ESCAPE:
		z._dir = 1.0
		z.velocity.x = move_toward(z.velocity.x, 300.0, 900.0 * delta)
		if z.is_on_wall() and z.is_on_floor():
			z.velocity.y = -480.0
		if not z.is_on_floor():
			z.velocity.y += z.gravity * delta
		z.move_and_slide()
		if z.global_position.x > float(z.world_w) - 40.0 or (has_pl and z.global_position.x - pl.global_position.x > 1100.0):
			z.remove_from_group("zombies")
			z.queue_free()   # נעלם במנהרה (נפגוש אותו בשער - שלב 27)
		return true
	if not _final() and float(z.hp) <= float(z.max_hp) * ESCAPE_AT:
		_escape()
		return true
	if not has_pl:
		return _move(delta, 0.0)
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		COMMAND:
			z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if _order_cd <= 0.0:   # שריקה: כולם מסתערים
				_order_cd = ORDER_CD
				_order()
			if _final() and _shell_cd <= 0.0 and absf(d.x) < 900.0:   # ארטילריה
				_shell_cd = SHELL_CD * (1.6 if rage else 1.0)
				_artillery(pl)
			if rage and _shoot_cd <= 0.0 and absf(d.x) < 420.0 and absf(d.y) < 80.0:
				state = WIND
				_st = 0.5
				return _move(delta, 0.0)
			if not rage and _shoot_cd <= 0.0 and absf(d.x) < 700.0 and absf(d.y) < 200.0:
				state = AIM
				_st = AIM_T
				_aim = (pl.global_position + Vector2(0, -30) - _hand()).angle()
				Sfx.play("rv_cock", z.global_position, 0.0, 0.08, 2)
				return _move(delta, 0.0)
			# שומר מרחק (בזעם - מתקרב)
			var want := 0.0
			if rage:
				want = z._dir * float(z.chase_speed)
			elif absf(d.x) < KEEP.x:
				want = -z._dir * float(z.walk_speed) * 1.4
			elif absf(d.x) > KEEP.y:
				want = z._dir * float(z.chase_speed)
			if z.is_on_wall() and z.is_on_floor() and want != 0.0:
				z.velocity.y = -460.0
			return _move(delta, want)
		AIM:
			z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			_aim = lerp_angle(_aim, (pl.global_position + Vector2(0, -30) - _hand()).angle(), delta * 5.0)
			if _st <= 0.0 and _left == 0:
				_left = BURST
				_burst_t = 0.0
			if _left > 0:
				_burst_t -= delta
				if _burst_t <= 0.0:
					_fire()
					_left -= 1
					_burst_t = 0.16
					if _left == 0:
						state = COMMAND
						_shoot_cd = randf_range(1.8, 2.6)
			return _move(delta, 0.0)
		WIND:   # מרים חרב
			z._dir = signf(d.x) if absf(d.x) > 6.0 else z._dir
			if _st <= 0.0:
				state = DASH
				_st = 0.45
				_hit = false
				dashes += 1
				Sfx.play("whoosh", z.global_position, 2.0, 0.1, 2)
			return _move(delta, 0.0)
		DASH:
			if not _hit and absf(d.x) < 44.0 * z.sc and absf(d.y) < 60.0:
				_hit = true
				pl.hurt(2, Vector2(z._dir * 2.2, -1.0))
			if _st <= 0.0 or z.is_on_wall():
				state = TIRED
				_st = 0.8
				return _move(delta, 0.0)
			z.velocity.x = z._dir * DASH_V
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			return true
		TIRED:
			if _st <= 0.0:
				state = COMMAND
				_shoot_cd = randf_range(1.2, 2.0)
			return _move(delta, 0.0)
	return false


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	z.global_position.x = clampf(z.global_position.x, 30.0, float(z.world_w) - 30.0)
	return true


func _hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 8.0, -38.0) * z.sc


func _fire() -> void:
	shots += 1
	var s := Slug.new()
	s.damage = 1
	s.velocity = Vector2.from_angle(_aim + randf_range(-0.04, 0.04)) * 1100.0
	z.get_parent().add_child(s)
	s.global_position = _hand() + Vector2.from_angle(_aim) * 14.0 * z.sc
	Sfx.play("pistol", z.global_position, 0.0, 0.08, 3)


func _order() -> void:
	orders += 1
	z._popup("ATTACK!", Color("ff6040"), 16, -110.0 * z.sc / 1.5)
	Sfx.play("gn_whistle", z.global_position, 2.0, 0.05, 2)
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o == z or o.dead or o.is_boss():
			continue
		if o.global_position.distance_to(z.global_position) < 800.0:
			o._alert_t = maxf(float(o._alert_t), 5.0)
			o._rush_t = 3.0
			if o.dormant:
				o._wake()


func _artillery(pl: Node) -> void:
	z._popup("FIRE FOR EFFECT!", Color("ffb040"), 15, -120.0)
	var mv := signf(pl.velocity.x) if absf(pl.velocity.x) > 20.0 else (1.0 if randf() < 0.5 else -1.0)
	var offs := [0.0, mv * 150.0, -mv * 120.0]
	for i in offs.size():
		var x: float = pl.global_position.x + float(offs[i])
		var top := Vector2(x, pl.global_position.y - 60.0)
		var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(top, top + Vector2(0, 600), 1 | 16))
		var s := Shell.new()
		s.delay = 1.1 + float(i) * 0.35
		z.get_parent().add_child(s)
		s.global_position = hit.position if hit else Vector2(x, pl.global_position.y)
		shells += 1


# ============================================================
#  ציור: מעיל ארוך ירוק-זית, חגורה, מדליות, כובע מצחייה עם סרט אדום ותג, משקפי שמש.
#  שלב 27: לוח שריון על החזה, יד חבושה, חרב.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var coat_d := col(Art.shade(z.shirt, 0.3))
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -38)
	var head := sh + Vector2(3.5, -8.5)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), Art.shade(sk, 0.25), coat_d)
	if _final():   # יד חבושה
		z.draw_line(sh + Vector2(-5, 8), sh + Vector2(-6, 12), col(Color("d8d0c0")), 3.0)
	# מעיל ארוך עם כנפיים
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(8, 10), hip + Vector2(-8, 10)]), coat, 0.15, 0.4)
	z.draw_rect(Rect2(hip + Vector2(-7, -3), Vector2(15, 3)), col(Color("3a2a1a")))   # חגורה
	z.draw_rect(Rect2(hip + Vector2(0, -3.5), Vector2(3, 4)), col(Color("c8a040")))
	z.draw_rect(Rect2(sh + Vector2(-9, -2), Vector2(6, 3)), col(Color("c8a040")))   # כותפות
	z.draw_rect(Rect2(sh + Vector2(4, -2), Vector2(6, 3)), col(Color("c8a040")))
	if _final():   # שריון
		Art.fill(z, PackedVector2Array([sh + Vector2(-5, 2), sh + Vector2(6, 2), sh + Vector2(5, 12), sh + Vector2(-4, 12)]), col(Color("5a5e60")), Art.OUTLINE, 1.0)
	else:
		for q in 3:   # מדליות
			z.draw_rect(Rect2(sh + Vector2(-4.0 + float(q) * 3.0, 4), Vector2(2, 3)), col([Color("c03030"), Color("3060c0"), Color("e0c040")][q]))
			z.draw_circle(sh + Vector2(-3.0 + float(q) * 3.0, 8.5), 1.0, col(Color("e0c040")))
	# ראש + כובע
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.0)
	z.draw_rect(Rect2(head + Vector2(0, -2.5), Vector2(7, 2.2)), col(Color("101010")))   # משקפי שמש
	if not z.dead:
		z.draw_circle(head + Vector2(4.5, -1.5), 0.8, Color(1.0, 0.3, 0.2))
	Art.fill(z, PackedVector2Array([head + Vector2(-7, -4), head + Vector2(-6, -9), head + Vector2(5, -11), head + Vector2(8, -6), head + Vector2(7, -4)]), coat, Art.OUTLINE, 1.0)
	z.draw_rect(Rect2(head + Vector2(-6.5, -6), Vector2(14, 2.4)), col(Color("b02020")))
	z.draw_circle(head + Vector2(1, -8), 1.6, col(Color("e0c040")))
	z.draw_line(head + Vector2(4, -4), head + Vector2(11, -3), col(Color("101010")), 2.0)   # מצחייה
	# יד קדמית: אקדח / חרב
	var hand: Vector2
	if rage:
		if state == WIND:
			hand = sh + Vector2(-2, -12)
		elif state == DASH:
			hand = sh + Vector2(16, 2)
		else:
			hand = sh + Vector2(9.0 + sin(p) * 2.0, 10.0)
		z._arm(sh + Vector2(3, 1), hand, sk, coat)
		var ang := -2.2 if state == WIND else (0.1 if state == DASH else -0.9)
		var tip := hand + Vector2.from_angle(ang) * 26.0
		z.draw_line(hand, tip, Art.OUTLINE, 3.2)
		z.draw_line(hand, tip, col(Color("c8ccd0")), 1.8)
		z.draw_line(hand + Vector2.from_angle(ang + 1.57) * 3.0, hand - Vector2.from_angle(ang + 1.57) * 3.0, col(Color("c8a040")), 2.0)
	else:
		if state == AIM:   # כיוון בעולם -> מקומי (מוראה לפי הכיוון)
			var la: float = _aim if z._dir > 0.0 else PI - _aim
			hand = sh + Vector2.from_angle(la) * 14.0
		else:
			hand = sh + Vector2(9.0 + sin(p) * 2.0, 13.0)
		z._arm(sh + Vector2(3, 1), hand, sk, coat)
		var ga: float = 0.0
		if state == AIM:
			ga = _aim if z._dir > 0.0 else PI - _aim
		z.draw_line(hand, hand + Vector2.from_angle(ga) * 8.0, col(Color("2a2a2c")), 3.0)
	end_draw()
	return true


# ---- פגז ארטילריה: עיגול אזהרה + שריקה, ואז פיצוץ (גם בשלב 27 מהזרקורים) ----
class Shell extends Node2D:
	var delay := 1.1
	var radius := 70.0
	var _t := 0.0
	var _done := false
	var _whistled := false

	func _ready() -> void:
		z_index = 8
		add_to_group("hazards")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-radius, -60.0), Vector2(radius * 2.0, 62.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return not _done and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not _whistled and _t > delay - 0.9:
			_whistled = true
			preload("res://sfx.gd").play("gn_shell", global_position, 0.0, 0.1, 4)
		if not _done and _t >= delay:
			_done = true
			preload("res://explosion.gd").blast(get_parent(), global_position + Vector2(0, -10), radius, 50.0, 40, 2, "artillery")
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / delay, 0.0, 1.0)
		var blink := fmod(_t * 8.0, 1.0) < 0.6
		draw_colored_polygon(preload("res://art.gd").ellipse(Vector2.ZERO, radius, radius * 0.2, 0.0, 20), Color(1.0, 0.4, 0.1, 0.12 + 0.18 * k))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.2))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(1.0, 0.5, 0.2, 0.9 if blink else 0.5), 3.0)
		draw_arc(Vector2.ZERO, radius * (1.0 - k) + 4.0, 0, TAU, 20, Color(1, 0.9, 0.7, 0.7), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var sy := -600.0 * (1.0 - k)   # הפגז שנופל
		if k > 0.6:
			draw_line(Vector2(0, sy - 14.0), Vector2(0, sy), Color(0.2, 0.2, 0.2, 0.9), 3.0)
