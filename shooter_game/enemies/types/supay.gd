extends "res://enemies/zombie_type.gd"
# ============================================================
#  SUPAY - "מלך השדים" של הדיאבלדה (הבוס של שלב 32 וגם של שלב 33).
#  מסכת שטן ענקית עם ארבע קרניים, גלימה אדומה-שחורה עם דרקונים מזהב, שריון חזה, קלשון.
#  הוא בעצמו "מנצח" - הרקדנים שלידו בסנכרון.
#    DANCE   - קופץ אליך בכל פעמה (קפיצות ענק). נחיתה לידך = STOMP_DMG.
#    ROCKETS - מרים את הקלשון (WIND) וזורק ROCKET_N זיקוקים בקשת שמתפוצצים.
#    CIRCLE  - "DANCE WITH ME!" - מזמן 4 רקדני DIABLO מסביבך (CIRCLE_CD).
#  שלב 32: ב-ESCAPE_AT מהחיים בורח למעלה, להר הגעש ("THE MOUNTAIN CALLS ME!") - בלתי פגיע, נעלם ימינה.
#  שלב 33 (הקרב האחרון): לא בורח. מתחת ל-RAGE_AT - הגלימה בוערת בלהבות גופרית כחולות:
#    כל נחיתה משאירה אש כחולה (fire_zone), והזיקוקים הופכים לכדורי אש כחולים.
#  לשנות: LEAP, STOMP_DMG, ROCKET_N, ROCKET_CD, CIRCLE_CD, ESCAPE_AT, RAGE_AT.
# ============================================================

const SOUNDS := {
	"sp_laugh": {"drive": 2.4, "layers": [["V", 95, 80, 0.0, 0.3, 0.02, 5.0, 0.9, 1.0, 0.03, 0, [300, 800, 30]], ["V", 100, 82, 0.35, 0.3, 0.02, 5.0, 0.9, 1.0, 0.03, 0, [300, 800, 30]], ["V", 105, 70, 0.7, 0.5, 0.02, 3.0, 1.0, 1.0, 0.03, 0, [300, 800, 30]]]},
	"sp_rocket": [["N", 0, 0, 0.0, 0.6, 0.02, 3.0, 0.4, 0.4, 0, 0.3], ["S", 600, 1600, 0.0, 0.5, 0.02, 3.0, 0.12, 1.0, 0.05]],
}

const LEAP := Vector2(230.0, -420.0)
const STOMP_DMG := 2
const ROCKET_N := 3
const ROCKET_CD := 5.5
const CIRCLE_CD := 13.0
const ESCAPE_AT := 0.35
const RAGE_AT := 0.5

enum { DANCE, WIND, ROCKETS, ESCAPE }
var state := DANCE
var leaps := 0               # לבדיקות
var stomps := 0
var rockets := 0
var circles := 0
var escaped := false
var raged := false
var _st := 0.0
var _rocket_cd := 3.0
var _circle_cd := 6.0
var _beat := -1
var _beat_t := 0.0
var _air := false
var _left := 0


func _final() -> bool:   # שלב 33 = הקרב האחרון
	return Game.level != 32


func stats() -> Dictionary:
	return {"name": "SUPAY", "hp": 360 if not _final() else 420, "walk": 46.0, "chase": 80.0, "damage": 2, "bite_delay": 0.9, "scale": 1.8, "width": 1.2,
		"duck": 0.0, "cover": 0.0, "skin": Color("7a8a6a"), "shirt": Color("a01820"), "pants": Color("1a1418"), "shoe": Color("e8e0c8"),
		"points": 1600, "boss": true, "boss_name": "SUPAY - THE DEVIL KING" if not _final() else "SUPAY - THE LAST DANCE"}


func setup() -> void:
	z.add_to_group("bandleaders")
	z.set_meta("pit_hop", true)


func can_bite() -> bool:
	return state == DANCE


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == ESCAPE:
		return false
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.3 if state == WIND else 1.0


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_rocket_cd -= delta
	_circle_cd -= delta
	_beat_t -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	if state == ESCAPE:
		z._dir = 1.0
		z.velocity.x = move_toward(z.velocity.x, 340.0, 900.0 * delta)
		if z.is_on_floor() and (z.is_on_wall() or randf() < 0.02):
			z.velocity.y = -520.0
		_move(delta)
		if z.global_position.x > float(z.world_w) - 40.0 or (has_pl and z.global_position.x - pl.global_position.x > 1100.0):
			z.remove_from_group("zombies")
			z.remove_from_group("bandleaders")
			z.queue_free()   # נעלם... להר הגעש (שלב 33)
		return true
	if not _final() and float(z.hp) <= float(z.max_hp) * ESCAPE_AT:
		_escape()
		return true
	if _final() and not raged and float(z.hp) <= float(z.max_hp) * RAGE_AT:
		raged = true
		z._popup("THE FIRE OF THE MOUNTAIN!", Color("80c0ff"), 18, -150.0)
		Sfx.play("sp_laugh", z.global_position, 4.0, 0.0, 1, 0.8)
	if not has_pl:
		return _settle(delta)
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		DANCE:
			if z.is_on_floor() and _air:   # נחיתה
				_air = false
				_land(pl)
			if _circle_cd <= 0.0 and z.is_on_floor() and absf(d.x) < 700.0:
				_circle(pl)
				return _settle(delta)
			if _rocket_cd <= 0.0 and z.is_on_floor() and absf(d.x) < 800.0:
				state = WIND
				_st = 0.6
				z._dir = signf(d.x)
				return _settle(delta)
			if _new_beat() and z.is_on_floor():   # קפיצה אליך (קרוב: קפיצה במקום = רקיעה עליך)
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				leaps += 1
				_air = true
				var vx: float = clampf(absf(d.x) * 1.4, 0.0, LEAP.x * (1.25 if raged else 1.0))
				z.velocity = Vector2(z._dir * vx, LEAP.y * (1.0 if absf(d.x) > 80.0 else 0.7))
			elif z.is_on_floor():
				z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
			_move(delta)
			return true
		WIND:
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				state = ROCKETS
				_left = ROCKET_N
				_st = 0.0
			return _settle(delta)
		ROCKETS:
			if _st <= 0.0:
				_fire(pl)
				_left -= 1
				_st = 0.25
				if _left <= 0:
					state = DANCE
					_rocket_cd = ROCKET_CD * (0.75 if raged else 1.0)
			return _settle(delta)
	return false


func _new_beat() -> bool:
	var band: Node = preload("res://effects/s32_decor.gd").band()
	if band != null:
		var nb: bool = band.beat_id != _beat
		_beat = band.beat_id
		return nb
	if _beat_t <= 0.0:   # בלי תזמורת (שלב 33): הקצב שלו
		_beat_t = 0.62
		return true
	return false


func _settle(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	_move(delta)
	return true


func _move(delta: float) -> void:
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	z.global_position.x = clampf(z.global_position.x, 30.0, float(z.world_w) - 30.0)


func _land(pl: Node) -> void:
	if Art.on_screen(z, z.global_position):
		Sfx.play("dv_stomp", z.global_position, 2.0, 0.1, 2, 0.7)
		Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 4)
	if absf(pl.global_position.x - z.global_position.x) < 70.0 * z.sc * 0.6 and absf(pl.global_position.y - z.global_position.y) < 40.0:
		stomps += 1
		pl.hurt(STOMP_DMG, Vector2(signf(pl.global_position.x - z.global_position.x) * 2.4, -1.4))
	if raged:   # אש גופרית כחולה במקום הנחיתה
		var fz = preload("res://environment/fire_zone.gd").new()
		fz.setup(70.0, 3.0)
		z.get_parent().add_child(fz)
		fz.global_position = z.global_position
		fz.modulate = Color(0.5, 0.8, 1.6)


func _fire(pl: Node) -> void:
	rockets += 1
	var r := Rocket.new()
	r.blue = raged
	z.get_parent().add_child(r)
	r.global_position = z.global_position + Vector2(z._dir * 20.0, -90.0) * Vector2(1.0, z.sc / 1.8)
	var tx: float = pl.global_position.x + randf_range(-60.0, 60.0) + pl.velocity.x * 0.4
	var flight := clampf(absf(tx - r.global_position.x) / 380.0, 0.6, 1.4)
	r.velocity = Vector2((tx - r.global_position.x) / flight, (pl.global_position.y - r.global_position.y) / flight - 0.5 * r.gravity * flight)
	Sfx.play("sp_rocket", r.global_position, -2.0, 0.15, 3)


func _circle(pl: Node) -> void:
	circles += 1
	_circle_cd = CIRCLE_CD
	var R := preload("res://enemies/zombie_registry.gd")
	var alive := 0
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if not o.dead and o.kind == R.DIABLO:
			alive += 1
	z._popup("DANCE WITH ME!", Color("ff6050"), 18, -150.0)
	Sfx.play("sp_laugh", z.global_position, 2.0, 0.05, 1)
	for off in [-340.0, -220.0, 220.0, 340.0]:
		if alive >= 6:
			break
		var x: float = clampf(pl.global_position.x + float(off), 60.0, float(z.world_w) - 60.0)
		var zz: Node = z.get_parent()._spawn_zombie(x, z.global_position.y if z.is_on_floor() else pl.global_position.y, R.DIABLO)
		if zz != null:
			zz.velocity = Vector2(0, -300.0)
			Particles.burst(z.get_parent(), Vector2(x, zz.global_position.y - 20.0), "fire", Vector2.UP, 8)
			alive += 1


func _escape() -> void:
	if escaped or z.dead:
		return
	escaped = true
	state = ESCAPE
	z.hp = maxi(z.hp, int(float(z.max_hp) * ESCAPE_AT))
	z._popup("THE MOUNTAIN CALLS ME!", Color("ff8040"), 20, -150.0)
	Sfx.play("sp_laugh", z.global_position, 4.0, 0.0, 1)
	z._drop(3)
	z._drop(2)
	z.get_tree().call_group("level_exit", "on_boss_dead")
	var pl := player()
	if pl != null:
		pl._say("HE'S RUNNING TO THE VOLCANO...", Color("ffd080"))


# ============================================================
#  זיקוק: עף בקשת עם זנב ניצוצות, מתפוצץ (פיצוץ קטן). כחול כשהוא זועם (שלב 33)
# ============================================================
class Rocket extends Node2D:
	var velocity := Vector2.ZERO
	var gravity := 700.0
	var blue := false
	var _t := 0.0
	var _sp := 0.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		_sp -= delta
		velocity.y += gravity * delta
		var to := global_position + velocity * delta
		if _sp <= 0.0:
			_sp = 0.04
			preload("res://particles.gd").burst(get_parent(), global_position, "spark" if blue else "fire", -velocity.normalized(), 2)
		var pl := get_tree().get_first_node_in_group("player")
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
		if (pl != null and not pl.dead and pl.body_rect().grow(6.0).has_point(to)) or not hit.is_empty() or _t > 3.0:
			var at: Vector2 = hit.position if not hit.is_empty() else to
			preload("res://explosion.gd").blast(get_parent(), at, 64.0, 20.0, 18, 1, "rocket")
			if blue:
				var fz = preload("res://environment/fire_zone.gd").new()
				fz.setup(60.0, 2.5)
				get_parent().add_child(fz)
				fz.global_position = at
				fz.modulate = Color(0.5, 0.8, 1.6)
			queue_free()
			return
		global_position = to
		rotation = velocity.angle()
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(-8, -2.5, 14, 5), Color("c02a2a") if not blue else Color("2a6ac0"))
		draw_colored_polygon(PackedVector2Array([Vector2(6, -3), Vector2(11, 0), Vector2(6, 3)]), Color("e0c040"))
		draw_line(Vector2(-8, 0), Vector2(-20, 0), Color("8a6a3a"), 1.2)
		draw_circle(Vector2(-9, 0), 3.0 + sin(_t * 40.0), Color(1.0, 0.7, 0.2, 0.9) if not blue else Color(0.4, 0.7, 1.0, 0.9))


# ============================================================
#  ציור: מסכת שטן עם 4 קרניים וכתר, גלימה אדומה-שחורה עם דרקון זהב, שריון חזה, קלשון.
#  זועם (שלב 33): להבות כחולות על הגלימה.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var cape := col(z.shirt)
	var gold := col(Color("e0b030"))
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -39)
	var head := sh + Vector2(3.5, -10)
	var winding: bool = state == WIND or state == ROCKETS
	# גלימה מאחור
	var flap := sin(z._time * 4.0) * 2.0
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -2), sh + Vector2(2, -2), hip + Vector2(-4, 22), hip + Vector2(-20 + flap, 20), hip + Vector2(-16, 4)]), Art.shade(cape, 0.3), 0.1, 0.3)
	z.draw_polyline(PackedVector2Array([hip + Vector2(-14, 6), hip + Vector2(-10, 12), hip + Vector2(-15, 16), hip + Vector2(-9, 18)]), gold, 1.4)   # דרקון זהב
	if raged and not z.dead:   # להבות גופרית כחולות
		for q in 6:
			var fp := hip + Vector2(-18.0 + float(q) * 4.0, 18.0 - float(q % 2) * 4.0)
			var fh := 8.0 + sin(z._time * 14.0 + float(q)) * 3.0
			z.draw_colored_polygon(PackedVector2Array([fp + Vector2(-2.5, 0), fp + Vector2(0, -fh), fp + Vector2(2.5, 0)]), Color(0.4, 0.7, 1.0, 0.8))
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	var hb := sh + Vector2(-6.0 - sin(p) * 2.0, 16.0)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(cape, 0.3))
	# שריון חזה
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(8, 3), hip + Vector2(-8, 3)]), cape, 0.15, 0.4)
	Art.fill(z, PackedVector2Array([sh + Vector2(-7, 1), sh + Vector2(7, 1), sh + Vector2(5, 12), sh + Vector2(-5, 12)]), gold, Art.OUTLINE, 1.0)
	z.draw_circle(sh + Vector2(0, 6), 2.2, col(Color("2a8a3a")))
	# מסכה + קרניים + כתר
	var m := head
	Art.fill_shaded(z, PackedVector2Array([m + Vector2(-8, 7), m + Vector2(-9, -4), m + Vector2(-4, -9), m + Vector2(4, -9), m + Vector2(9, -4), m + Vector2(9, 7), m + Vector2(3, 11), m + Vector2(-3, 11)]), col(Color("8a1018")), 0.15, 0.35, Art.OUTLINE, 1.3)
	for k in 2:
		for sgn in [-1.0, 1.0]:
			var o := float(k) * 5.0
			Art.fill(z, PackedVector2Array([m + Vector2(sgn * (3.0 + o), -8), m + Vector2(sgn * (10.0 + o * 1.5), -18 - o), m + Vector2(sgn * (8.0 + o), -28 - o * 1.6), m + Vector2(sgn * (13.0 + o * 1.5), -31 - o * 1.4), m + Vector2(sgn * (14.0 + o * 1.4), -19 - o), m + Vector2(sgn * (6.0 + o), -7)]), gold if k == 0 else col(Color("c0a060")), Art.OUTLINE, 1.0)
	z.draw_rect(Rect2(m + Vector2(-6, -12), Vector2(12, 4)), gold)   # כתר
	for q in 3:
		z.draw_colored_polygon(PackedVector2Array([m + Vector2(-6.0 + float(q) * 5.0, -12), m + Vector2(-4.0 + float(q) * 5.0, -16), m + Vector2(-2.0 + float(q) * 5.0, -12)]), gold)
	if not z.dead:
		var ec := Color(1.0, 0.25, 0.1) if not raged else Color(0.5, 0.8, 1.0)
		z.draw_circle(m + Vector2(-3, -2), 3.4, Color("f4f0e0"))
		z.draw_circle(m + Vector2(5, -2), 3.4, Color("f4f0e0"))
		z.draw_circle(m + Vector2(-2.5, -2), 1.7, ec)
		z.draw_circle(m + Vector2(5.5, -2), 1.7, ec)
		z.draw_line(m + Vector2(-5, 6), m + Vector2(7, 6), col(Color("1a0505")), 2.2)
		for q in 4:
			z.draw_colored_polygon(PackedVector2Array([m + Vector2(-5.0 + float(q) * 3.5, 6), m + Vector2(-4.0 + float(q) * 3.5, 10), m + Vector2(-3.0 + float(q) * 3.5, 6)]), Color("f4f0e0"))
	# יד עם קלשון
	var hf := sh + Vector2(10.0, 8.0) if not winding else sh + Vector2(6, -16)
	z._arm(sh + Vector2(3, 1), hf, sk, cape)
	var shaft_top := hf + Vector2(2, -26) if not winding else hf + Vector2(10, -20)
	var shaft_bot := hf + Vector2(-2, 22) if not winding else hf + Vector2(-8, 20)
	z.draw_line(shaft_bot, shaft_top, col(Color("4a3a2a")), 2.4)
	var tdir := (shaft_top - shaft_bot).normalized()
	var perp := Vector2(-tdir.y, tdir.x)
	z.draw_line(shaft_top - perp * 5.0, shaft_top + perp * 5.0, gold, 2.0)
	for q in 3:
		var base := shaft_top + perp * (float(q) - 1.0) * 5.0
		z.draw_line(base, base + tdir * 9.0, gold, 2.0)
	if winding:
		z.draw_circle(shaft_top + tdir * 10.0, 3.0 + sin(z._time * 30.0), Color(1.0, 0.6, 0.2, 0.7))
	end_draw()
	return true
