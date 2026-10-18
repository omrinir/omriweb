extends "res://enemies/zombie_type.gd"
# ============================================================
#  HAZMAT (שלב 26, "THE BUNKER") - זומבי בחליפת מגן צהובה עם מסכת גז ומיכל גז על הגב, מרסס בצינור.
#    WALK  - מתקרב, תמיד פונה אליך (שלא תראה את המיכל!).
#    AIM   - עוצר ומכוון את הצינור (AIM_T, טפטוף ירוק = אזהרה).
#    SPRAY - מרסס ענן גז (GasCloud) לפניו (SPRAY_T). בזמן הריסוס הוא לא מסתובב = החלון לעקוף אותו.
#  נקודת תורפה: המיכל על הגב. פגיעה מאחור = x TANK_MULT, וכמה פגיעות (TANK_HP) -> המיכל מתפוצץ בענן רעל (גם לזומבים).
#  פיצוץ (רימון) תמיד פוגע במיכל.
#  לשנות: RANGE, AIM_T, SPRAY_T, TANK_HP, TANK_MULT, CD.
# ============================================================

const SOUNDS := {
	"hz_spray": [["N", 0, 0, 0.0, 1.0, 0.05, 1.5, 0.5, 0.35, 0, 0.3]],
	"hz_breath": [["N", 0, 0, 0.0, 0.5, 0.15, 3.0, 0.25, 0.15, 0], ["N", 0, 0, 0.6, 0.4, 0.1, 4.0, 0.2, 0.25, 0]],
}

const RANGE := 150.0
const AIM_T := 0.45
const SPRAY_T := 1.1
const TANK_HP := 3
const TANK_MULT := 2.5
const CD := Vector2(2.2, 3.2)

enum { WALK, AIM, SPRAY }
var state := WALK
var sprays := 0              # לבדיקות
var tank_hits := 0
var tank_burst := false
var _st := 0.0
var _cd := 1.0
var _puff := 0.0
var _breath := 2.0


func stats() -> Dictionary:
	return {"name": "HAZMAT", "hp": 46, "walk": 42.0, "chase": 84.0, "damage": 1, "bite_delay": 0.9, "scale": 1.08, "width": 1.1,
		"duck": 0.0, "cover": 0.2, "skin": Color("8a9a8a"), "shirt": Color("d8b830"), "pants": Color("c8a828"), "shoe": Color("2a2a2a"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.7}


func can_bite() -> bool:
	return state == WALK


func damage_mult(_zone: String, src: Dictionary) -> float:
	if str(src.get("source", "")) == "gas":
		return 0.0
	return 1.0


func on_damage(amount: int, hit_pos: Vector2, _dir: Vector2, src: Dictionary) -> bool:
	if tank_burst:
		return true
	var from_back: bool = signf(hit_pos.x - z.global_position.x) == -z._dir and absf(hit_pos.x - z.global_position.x) > 3.0
	var boom: bool = str(src.get("source", "")) in ["grenade", "explosion", "barrel", "mech"]
	if from_back or boom:
		tank_hits += 1
		z._popup("TANK!", Color("a0ff60"), 13, -70.0)
		Particles.burst(z.get_parent(), z.global_position + Vector2(-z._dir * 10.0, -36.0) * z.sc, "smoke", Vector2(-z._dir, -0.3), 4)
		if tank_hits >= TANK_HP or boom:
			_burst_tank.call_deferred()
		else:
			_extra.call_deferred(int(float(amount) * (TANK_MULT - 1.0)))
	return true


func _extra(n: int) -> void:
	if z != null and is_instance_valid(z) and not z.dead and n > 0:
		z.take_damage(n, z.global_position + Vector2(0, -30), Vector2.ZERO, false, {"source": "tank", "fixed": n})


func _burst_tank() -> void:
	if tank_burst or z == null or not is_instance_valid(z):
		return
	tank_burst = true
	var c: Vector2 = z.global_position + Vector2(-z._dir * 10.0, -36.0) * z.sc
	Sfx.play("explosion", c, -2.0, 0.1, 2)
	for i in 3:
		var g := GasCloud.new()
		g.life = 4.0
		g.radius = 60.0
		z.get_parent().add_child(g)
		g.global_position = z.global_position + Vector2((float(i) - 1.0) * 60.0, -20.0)
	if not z.dead:
		z.take_damage(999, c, Vector2(z._dir, -0.5), true, {"source": "explosion", "fixed": 999})


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_breath -= delta
	if z.dead:
		return false
	if _breath <= 0.0:
		_breath = randf_range(2.5, 4.0)
		if Art.on_screen(z, z.global_position):
			Sfx.play("hz_breath", z.global_position, -8.0, 0.1, 2)
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if not has_pl:
				return false
			var d: Vector2 = pl.global_position - z.global_position
			if absf(d.x) > 6.0:
				z._dir = signf(d.x)   # תמיד פונה אליך
			if _cd <= 0.0 and absf(d.x) < RANGE and absf(d.y) < 60.0 and z.is_on_floor():
				state = AIM
				_st = AIM_T
				return _stay(delta)
			return false
		AIM:
			if has_pl:
				var dx: float = pl.global_position.x - z.global_position.x
				if absf(dx) > 6.0:
					z._dir = signf(dx)
			if _st <= 0.0:
				state = SPRAY
				_st = SPRAY_T
				_puff = 0.0
				sprays += 1
				Sfx.play("hz_spray", z.global_position, 0.0, 0.1, 2)
			return _stay(delta)
		SPRAY:
			_puff -= delta
			if _puff <= 0.0:   # ענני גז לפניו
				_puff = 0.28
				var g := GasCloud.new()
				g.life = 2.6
				g.radius = 34.0
				g.drift = z._dir * 70.0
				z.get_parent().add_child(g)
				g.global_position = _nozzle() + Vector2(z._dir * randf_range(30.0, 70.0), randf_range(-6.0, 10.0))
			if _st <= 0.0:
				state = WALK
				_cd = randf_range(CD.x, CD.y)
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _nozzle() -> Vector2:
	return z.global_position + Vector2(z._dir * 22.0, -30.0) * z.sc


# ============================================================
#  ציור: חליפה צהובה תפוחה, מסכה עם 2 פילטרים וחלון, מיכל ירוק על הגב, צינור לידיים
# ============================================================
func draw() -> bool:
	begin_draw()
	var suit := col(z.shirt)
	var suit_d := col(Art.shade(z.shirt, 0.25))
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -38)
	var head := sh + Vector2(3.0, -8.5)
	z._leg(hip + Vector2(-3, 0), f[1], suit_d, suit_d, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], suit, suit, col(z.shoe))
	# מיכל על הגב
	if not tank_burst:
		var tc := sh + Vector2(-10, 7)
		Art.fill_shaded(z, PackedVector2Array([tc + Vector2(-5, -9), tc + Vector2(4, -9), tc + Vector2(5, 13), tc + Vector2(-5, 13)]), col(Color("4a7a3a")), 0.2, 0.4)
		DrawBatch.rect(z, Rect2(tc + Vector2(-3, -12), Vector2(4, 3)), col(Color("8a8e90")))
		var crack := clampf(float(tank_hits) / float(TANK_HP), 0.0, 1.0)
		if crack > 0.0:   # סדקים + דליפה
			DrawBatch.line(z, tc + Vector2(-2, -4), tc + Vector2(2, 2), Color(0.1, 0.1, 0.1), 1.0)
			if not z.dead:
				DrawBatch.circle(z, tc + Vector2(-5, 2), 2.0 + crack * 2.0, Color(0.6, 1.0, 0.3, 0.5))
		DrawBatch.circle(z, tc + Vector2(0, 4), 3.0, col(Color("d8c020")))   # סימן ביו
	z._arm(sh + Vector2(-4, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), suit_d, suit_d)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -2), sh + Vector2(7, -1), sh + Vector2(9, 8), hip + Vector2(7, 2), hip + Vector2(-7, 2), sh + Vector2(-9, 8)]), suit, 0.18, 0.35)
	DrawBatch.line(z, sh + Vector2(-2, 2), hip + Vector2(-1, 0), col(Color("8a7a20")), 1.2)   # רוכסן
	# ברדס + מסכה
	Art.oval_shaded(z, head, 6.8, 7.0, suit, 0.0)
	DrawBatch.rect(z, Rect2(head + Vector2(-1, -4), Vector2(7, 5)), col(Color("1a2a2a")))   # חלון
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -1.5), 1.0, Color(1.0, 0.5, 0.2))
	DrawBatch.circle(z, head + Vector2(5, 4), 2.6, col(Color("2a2a2a")))   # פילטר
	DrawBatch.circle(z, head + Vector2(1, 5), 2.2, col(Color("2a2a2a")))
	# יד קדמית + צינור + מרסס
	var hand := sh + (Vector2(16, 8) if state != WALK else Vector2(10.0 + sin(p) * 2.0, 12.0))
	z._arm(sh + Vector2(3, 1), hand, suit, suit)
	if not tank_burst:
		DrawBatch.polyline(z, PackedVector2Array([sh + Vector2(-10, 4), sh + Vector2(-4, 18), hand + Vector2(-4, 6), hand]), col(Color("2a2a2a")), 1.6)
	DrawBatch.line(z, hand, hand + Vector2(8, -1), col(Color("6a6e70")), 2.6)
	if state == AIM and not z.dead:
		DrawBatch.circle(z, hand + Vector2(9, 1 + fmod(z._time * 6.0, 1.0) * 6.0), 1.2, Color(0.6, 1.0, 0.3, 0.9))
	if state == SPRAY and not z.dead:
		for q in 4:
			var k := fmod(z._time * 4.0 + float(q) * 0.25, 1.0)
			DrawBatch.circle(z, hand + Vector2(10.0 + k * 40.0, sin(float(q) * 2.0) * k * 6.0), 2.0 + k * 7.0, Color(0.55, 0.9, 0.3, 0.5 * (1.0 - k)))
	end_draw()
	return true


# ---- ענן גז: פוגע בשחקן שבתוכו, וגם בזומבים (חוץ מ-HAZMAT) ----
class GasCloud extends Node2D:
	var life := 2.6
	var radius := 34.0
	var drift := 0.0
	var _t := 0.0
	var _tick := 0.0
	var _seed := 0.0

	func _ready() -> void:
		z_index = 7
		add_to_group("hazards")
		_seed = randf() * 10.0

	func world_rect() -> Rect2:
		return Rect2(global_position - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return p.distance_to(global_position) < radius + margin

	func _physics_process(delta: float) -> void:
		_t += delta
		global_position.x += drift * delta
		drift = move_toward(drift, 0.0, 80.0 * delta)
		radius += 8.0 * delta
		_tick -= delta
		if _t >= life:
			queue_free()
			return
		if _tick <= 0.0:
			_tick = 0.6
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and pl.body_rect().grow(-4.0).intersects(world_rect().grow(-radius * 0.3)):
				pl.hurt(1, Vector2.ZERO)
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or (z.type_mod != null and z.type_mod.has_method("_nozzle")):
					continue
				if (z.global_position + Vector2(0, -25)).distance_to(global_position) < radius:
					z.take_damage(4, z.global_position + Vector2(0, -25), Vector2.ZERO, false, {"source": "gas", "fixed": 4})
		queue_redraw()

	func _draw() -> void:
		var a := clampf(minf(_t / 0.3, (life - _t) / 0.8), 0.0, 1.0)
		for i in 5:
			var o := Vector2(sin(_seed + float(i) * 1.7 + _t * 0.8), cos(_seed + float(i) * 2.3 + _t * 0.6)) * radius * 0.45
			DrawBatch.circle(self, o, radius * (0.55 + 0.1 * float(i % 3)), Color(0.45, 0.8, 0.25, 0.16 * a))
		DrawBatch.circle(self, Vector2.ZERO, radius * 0.4, Color(0.6, 0.95, 0.35, 0.15 * a))
