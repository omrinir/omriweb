extends "res://enemies/zombie_type.gd"
# ============================================================
#  TORCH (שלב 24, "BURNING FIELDS") - זומבי בוער: הראש והכתפיים באש, זורק בקבוקי תבערה.
#    WALK  - שומר מרחק (המוח, keep_range). קרוב מדי (BACKOFF) - נסוג אחורה.
#    WIND  - עוצר, מדליק בקבוק ומושך יד אחורה (WIND_T = אזהרה, להבה ביד).
#    THROW - בקבוק בקשת אל המקום שאתה הולך אליו (LEAD). נשבר -> שטח בוער (environment/fire_zone.gd, FIRE_W, FIRE_T).
#  אש לא פוגעת בו. מת -> מתפוצץ באש (שטח בוער סביבו) - לא להרוג אותו צמוד אליך!
#  בוס: THE PYRE - ענק, זורק 3 בקבוקים במניפה, ובמוות שלושה שטחים בוערים.
#  לשנות: RANGE, WIND_T, LEAD, FIRE_W, FIRE_T, CD.
# ============================================================

const FireZone := preload("res://environment/fire_zone.gd")
const Flame := preload("res://effects/flame_fx.gd")

const RANGE := 520.0
const WIND_T := 0.55
const LEAD := 0.45
const FIRE_W := 90.0
const FIRE_T := 3.5
const CD := Vector2(2.4, 3.4)
const GRAV := 1100.0
const BACKOFF := 130.0      # קרוב מזה - נסוג

enum { WALK, WIND }
var state := WALK
var throws := 0              # לבדיקות
var _st := 0.0
var _cd := 1.5
var _anim := 0.0


func _boss() -> bool:
	return z != null and float(z.chase_range) > 600.0


func stats() -> Dictionary:
	if _boss():
		return {"name": "TORCH", "hp": 380, "walk": 46.0, "chase": 88.0, "damage": 2, "bite_delay": 0.9, "scale": 1.7, "width": 1.15,
			"duck": 0.0, "cover": 0.0, "skin": Color("5a4636"), "shirt": Color("3a2620"), "pants": Color("2a221e"), "shoe": Color("161210"),
			"points": 1100, "boss": true, "boss_name": "THE PYRE - DON'T STAND IN THE FIRE"}
	return {"name": "TORCH", "hp": 38, "walk": 46.0, "chase": 92.0, "damage": 1, "bite_delay": 0.8, "scale": 1.05, "width": 0.95,
		"duck": 0.0, "cover": 0.3, "skin": Color("5a4636"), "shirt": Color("3a2620"), "pants": Color("2a221e"), "shoe": Color("161210"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.35, "keep_range": 280.0}


func damage_mult(_zone: String, src: Dictionary) -> float:
	return 0.0 if str(src.get("source", "")) == "fire" else 1.0


func can_bite() -> bool:
	return state == WALK


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	_anim -= delta
	if z.dead:
		return false
	z._burn_t = 0.0   # לא נשרף (כבר בוער)
	if Engine.get_physics_frames() % 9 == 0 and Art.on_screen(z, z.global_position):
		Particles.burst(z.get_parent(), z.global_position + Vector2(randf_range(-6, 6), -48.0 * z.sc), "fire", Vector2.UP, 1)
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if _cd <= 0.0 and has_pl and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				var sees: bool = z.brain == null or z.brain.sees or absf(d.x) < 340.0   # קשת - לא צריך קו ראייה ישר
				if sees and absf(d.x) < RANGE and absf(d.y) < 240.0:   # גם מקרוב: האש לא פוגעת בו
					state = WIND
					_st = WIND_T * (0.8 if _boss() else 1.0)
					z._dir = signf(d.x)
					Sfx.play("fire_whoosh", z.global_position, -6.0, 0.1, 2)
					return _stay(delta)
			if has_pl and z.is_on_floor():   # קרוב מדי: נסוג אחורה (ופונה אליך)
				var d: Vector2 = pl.global_position - z.global_position
				if absf(d.x) < BACKOFF and absf(d.y) < 60.0 and not z.is_on_wall():
					z._dir = signf(d.x) if d.x != 0.0 else z._dir
					z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.7, 700.0 * delta)
					z.velocity.y += z.gravity * delta
					z.move_and_slide()
					return true
			return false
		WIND:
			if has_pl:
				z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
			if _st <= 0.0:
				if has_pl:
					var pv: Vector2 = pl.velocity if pl.get("velocity") != null else Vector2.ZERO
					var tgt: Vector2 = pl.global_position + Vector2(clampf(pv.x, -380.0, 380.0) * LEAD, 0.0)
					if _boss():
						for k in [-90.0, 0.0, 90.0]:
							_throw(tgt + Vector2(k, 0.0))
					else:
						_throw(tgt)
				state = WALK
				_cd = randf_range(CD.x, CD.y)
				_anim = 0.35
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 6.0, -50.0) * z.sc


func _throw(target: Vector2) -> void:
	throws += 1
	var from := _hand()
	var t := clampf(absf(target.x - from.x) / 420.0, 0.5, 1.15)
	var v := Vector2((target.x - from.x) / t, (target.y - 4.0 - from.y - 0.5 * GRAV * t * t) / t)
	var b := Bottle.new()
	b.velocity = v
	b.gravity = GRAV
	b.owner_z = z
	b.fire_w = FIRE_W * (1.3 if _boss() else 1.0)
	b.fire_t = FIRE_T
	z.get_parent().add_child(b)
	b.global_position = from
	Sfx.play("throw", z.global_position, 0.0, 0.1, 3)


func on_death() -> void:
	var n := 3 if _boss() else 1
	for i in n:
		var fz = FireZone.new()
		fz.setup(110.0 if i == 0 else 90.0, 3.0)
		z.get_parent().add_child(fz)
		fz.global_position = z.global_position + Vector2([0.0, -120.0, 120.0][i], 0.0)
	Particles.burst(z.get_parent(), z.global_position + Vector2(0, -30), "fire", Vector2.UP, 26)
	Sfx.play("fire_whoosh", z.global_position, 2.0)
	var pl := player()   # צמוד אליו כשהוא מתפוצץ = נכווה
	if pl != null and not pl.dead and pl.global_position.distance_to(z.global_position) < 60.0 * z.sc:
		pl.hurt(1, Vector2(signf(pl.global_position.x - z.global_position.x), -0.8))


# ============================================================
#  ציור: גוף חרוך, בגדים קרועים, להבות על הראש והכתפיים, בקבוק ביד בזמן WIND
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 15.0), Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(1, -2), hip + Vector2(-5, 2)]), shirt, 0.12, 0.4)
	for q in 3:   # סדקים זוהרים בעור
		var c := sh + Vector2(-3.0 + float(q) * 3.0, 6.0 + float(q) * 3.0)
		DrawBatch.line(z, c, c + Vector2(2, 3), col(Color(1.0, 0.5, 0.15, 0.8)), 1.0)
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -1.0), 1.1, Color(1.0, 0.85, 0.3))
		DrawBatch.line(z, head + Vector2(1, 3), head + Vector2(5, 3), Color(1.0, 0.5, 0.1), 1.0)   # פה זוהר
	# יד קדמית: בזמן WIND מושכת אחורה עם בקבוק דולק, אחרי זריקה קדימה
	var hand: Vector2
	if state == WIND:
		hand = sh + Vector2(-9, -9)
	elif _anim > 0.0:
		hand = sh + Vector2(13, -4)
	else:
		hand = sh + Vector2(9.0 + sin(p) * 3.0, 13.0)
	z._arm(sh + Vector2(3, 1), hand, sk, shirt)
	if state == WIND:
		DrawBatch.colored_polygon(z, PackedVector2Array([hand + Vector2(-2, 2), hand + Vector2(2, 2), hand + Vector2(2, -6), hand + Vector2(1, -9), hand + Vector2(-1, -9), hand + Vector2(-2, -6)]), col(Color(0.35, 0.55, 0.3)))
		if not z.dead:
			_flame(hand + Vector2(0, -10), 5.0, 0.0)
	# להבות על הראש והכתפיים (מונפשות)
	if not z.dead:
		_flame(head + Vector2(-1, -5), 9.0, 0.0)
		_flame(sh + Vector2(-5, -1), 6.0, 1.7)
		_flame(sh + Vector2(5, -1), 5.0, 3.1)
		Flame.glow(z, head + Vector2(0, -4), Vector2(22.0, 24.0), Color(1.0, 0.5, 0.15, 0.3))
	end_draw()
	return true


func _flame(base: Vector2, h: float, ph: float) -> void:   # לשון אש אמיתית (effects/flame_fx.gd)
	var t: float = z._time
	var hh := h * 1.6 * (0.7 + 0.5 * Flame.wobble(t * 1.2, ph))
	Flame.tongue(z, base + Vector2(0, 1), h * 0.42, hh, sin(t * 5.0 + ph) * 2.5 - z.velocity.x * 0.015 * z._dir, Flame.PALETTE, 0.92, h > 6.0)


# ---- בקבוק תבערה של הזומבי (לא נשבר על זומבים, כן על השחקן) ----
class Bottle extends Node2D:
	var velocity := Vector2.ZERO
	var gravity := 1100.0
	var owner_z: Node = null
	var fire_w := 90.0
	var fire_t := 3.5
	var _t := 0.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		velocity.y += gravity * delta
		var to := global_position + velocity * delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.body_rect().grow(4.0).has_point(to):
			pl.hurt(1, Vector2(signf(velocity.x), -0.6))
			_shatter(Vector2(to.x, pl.global_position.y))
			return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1 | 16))
		if hit or _t > 4.0:
			_shatter(hit.position if hit else to)
			return
		global_position = to
		rotation += 12.0 * delta * signf(velocity.x)
		queue_redraw()

	func _shatter(at: Vector2) -> void:
		var Sfx := preload("res://sfx.gd")
		Sfx.play("bottle_break", at, 0.0)
		Sfx.play("fire_whoosh", at, -2.0)
		preload("res://particles.gd").burst(get_parent(), at, "fire", Vector2.UP, 14)
		var q := PhysicsRayQueryParameters2D.create(at + Vector2(0, -6), at + Vector2(0, 400), 1 | 16)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		var fz = preload("res://environment/fire_zone.gd").new()
		fz.setup(fire_w, fire_t)
		get_parent().add_child(fz)
		fz.global_position = hit.position if hit else at
		queue_free()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		var Fl := preload("res://effects/flame_fx.gd")
		# בקבוק זכוכית ירוק עם נוזל, סמרטוט בפתח
		DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-6, -3), Vector2(3, -3), Vector2(5, -1.5), Vector2(10, -1.2), Vector2(10, 1.2), Vector2(5, 1.5), Vector2(3, 3), Vector2(-6, 3)]), Color(0.22, 0.42, 0.2, 0.95))
		DrawBatch.rect(self, Rect2(Vector2(-5, 0), Vector2(8, 2.5)), Color(0.75, 0.5, 0.15, 0.8))   # דלק
		DrawBatch.line(self, Vector2(-4, -2), Vector2(2, -2), Color(1, 1, 1, 0.35), 1.0)   # ברק זכוכית
		DrawBatch.line(self, Vector2(10, 0), Vector2(13, -1.5), Color("d8c8a0"), 1.8)
		# הסמרטוט בוער: הלהבה נמשכת אחורה (הפוך לכיוון התנועה)
		var back := (-velocity.normalized()).rotated(-rotation) if velocity.length() > 1.0 else Vector2.UP
		var tip := Vector2(14, -2)
		Fl.glow(self, tip, Vector2(14, 14), Color(1.0, 0.55, 0.15, 0.45))
		for q in 3:
			var k := fmod(_t * 6.0 + float(q) / 3.0, 1.0)
			var c: Color = Fl.PALETTE[q + 1]
			c.a = 0.95 * (1.0 - k * 0.7)
			DrawBatch.circle(self, tip + back * (k * 12.0 + float(q)), (4.0 - float(q)) * (1.0 - k * 0.5), c)
