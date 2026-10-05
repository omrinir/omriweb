extends RefCounted
# ============================================================
#  שלב 10 (צפון-מזרח, מישורי המלח) - חפצים משותפים לזומבים ולסכנות:
#   BloodGlob   - גוש דם שעף בקשת מהפצע של BLOODGATE ונוחת על הריצפה -> הופך לפורטל
#   BloodPortal - שלולית דם פועמת (כניסה / יציאה של BLOODGATE). רק קישוט + אזהרה, לא פוגעת
#   ShockBolt   - פריקת חשמל מהפה של LIVEWIRE (קליע זיגזג כחול)
#   LiveCable   - הכבל החי שמחובר ל-LIVEWIRE מעמוד חשמל. הקטע שעל הריצפה מחשמל את השחקן
#   DownedLine  - קו מתח שנפל על הכביש (סכנה מחזורית: שקט -> ניצוצות -> מכה)
#  לשנות: מהירויות / זמנים בקבועים של כל מחלקה.
# ============================================================


# ------------------------------------------------------------
#  גוש דם מעופף: נוחת -> פורטל יציאה (ומודיע לזומבי ששלח אותו)
# ------------------------------------------------------------
class BloodGlob extends Node2D:
	const GRAV := 980.0
	var velocity := Vector2.ZERO
	var owner_mod: RefCounted = null    # enemies/types/blood_gate.gd
	var life := 2.2
	var _trail := []

	func _ready() -> void:
		z_index = 8

	func _physics_process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			if owner_mod != null:
				owner_mod.portal_failed()
			queue_free()
			return
		velocity.y += GRAV * delta
		var to := global_position + velocity * delta
		if velocity.y > 0.0:   # נוחת רק בדרך למטה (עובר דרך קומות מלמטה)
			var q := PhysicsRayQueryParameters2D.create(global_position, to + Vector2(0, 4), 1 | 16)
			var hit := get_world_2d().direct_space_state.intersect_ray(q)
			if not hit.is_empty():
				var n: Vector2 = hit.normal
				if n.y < -0.5:
					_land(hit.position)
					return
				velocity.x *= -0.3   # פגע בקיר: מחליק למטה
		elif not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1)).is_empty():
			velocity.x *= -0.3
			velocity.y = 0.0
		_trail.push_front(global_position)
		if _trail.size() > 7:
			_trail.pop_back()
		global_position = to
		queue_redraw()

	func _land(p: Vector2) -> void:
		var portal := BloodPortal.new()
		portal.exit = true
		get_parent().add_child(portal)
		portal.global_position = p
		Sfx.play("bg_splat", p, -2.0, 0.12, 3)
		Particles.burst(get_parent(), p + Vector2(0, -4), "hit", Vector2.UP, 8)
		if owner_mod != null:
			owner_mod.portal_ready(portal)
		queue_free()

	func _draw() -> void:
		for i in _trail.size():
			var k := 1.0 - float(i) / float(_trail.size())
			draw_circle(to_local(_trail[i]), 2.0 + 3.0 * k, Color(0.55, 0.0, 0.05, 0.5 * k))
		draw_circle(Vector2.ZERO, 5.5, Color(0.45, 0.0, 0.04))
		draw_circle(Vector2(-1.5, -1.5), 2.2, Color(0.9, 0.2, 0.25))

	const Sfx := preload("res://sfx.gd")
	const Particles := preload("res://particles.gd")


# ------------------------------------------------------------
#  שלולית-פורטל. exit = שלולית שהזומבי יוצא ממנה (פועמת חזק יותר)
# ------------------------------------------------------------
class BloodPortal extends Node2D:
	var exit := false
	var t := 0.0
	var life := 4.0
	var open_k := 0.0      # 0..1 נפתח
	var closing := false
	var used := false

	func _ready() -> void:
		z_index = 2
		add_to_group("s10_portals")

	func close() -> void:
		closing = true

	func _process(delta: float) -> void:
		t += delta
		life -= delta
		if life <= 0.0:
			closing = true
		open_k = move_toward(open_k, 0.0 if closing else 1.0, delta * (2.5 if closing else 5.0))
		if closing and open_k <= 0.0:
			queue_free()
			return
		if Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		var r := 30.0 * open_k
		var pulse := 1.0 + 0.08 * sin(t * (12.0 if exit else 7.0))
		draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, r * 1.25 * pulse, Color(0.9, 0.05, 0.1, 0.18))
		draw_circle(Vector2.ZERO, r * pulse, Color(0.32, 0.0, 0.03, 0.95))
		draw_circle(Vector2.ZERO, r * 0.72 * pulse, Color(0.12, 0.0, 0.02))
		for i in 6:   # טבעת סימנים מסתובבת
			var a := t * (2.4 if exit else -1.6) + float(i) * TAU / 6.0
			draw_circle(Vector2.from_angle(a) * r * 0.86, 2.6 * open_k, Color(1.0, 0.25, 0.25, 0.9))
		draw_arc(Vector2.ZERO, r * 0.9, 0.0, TAU, 28, Color(1.0, 0.2, 0.2, 0.6), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if exit and not used:   # עמוד אור אדום = "משהו יוצא מכאן"
			var h := 70.0 * open_k * (0.8 + 0.2 * sin(t * 15.0))
			draw_rect(Rect2(-r * 0.5, -h, r, h), Color(1.0, 0.1, 0.15, 0.13))
			for i in 3:
				var bx := sin(t * 3.0 + float(i) * 2.1) * r * 0.4
				var by := -fposmod(t * 60.0 + float(i) * 23.0, 60.0)
				draw_circle(Vector2(bx, by), 2.0, Color(0.8, 0.05, 0.1, 0.8))

	const Art := preload("res://art.gd")


# ------------------------------------------------------------
#  פריקת חשמל מהפה (LIVEWIRE)
# ------------------------------------------------------------
class ShockBolt extends Node2D:
	var velocity := Vector2.ZERO
	var life := 1.6
	var _pts := PackedVector2Array()

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		var to := global_position + velocity * delta
		if not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1)).is_empty():
			Particles.burst(get_parent(), global_position, "spark", -velocity.normalized(), 6)
			queue_free()
			return
		var p := get_tree().get_first_node_in_group("player")
		if p != null and not p.dead:
			var r: Rect2 = p.body_rect().grow(3.0)
			for i in 3:
				if r.has_point(global_position.lerp(to, float(i) / 2.0)):
					p.hurt(1, Vector2(signf(velocity.x), -0.3))
					Sfx.play("lw_hit", global_position, 0.0, 0.1, 3)
					Game.story.emit("shock", {})
					Particles.burst(get_parent(), global_position, "spark", Vector2.UP, 10)
					queue_free()
					return
		global_position = to
		rotation = velocity.angle()
		_pts.clear()   # זיגזג חדש בכל פריים
		for i in 7:
			_pts.append(Vector2(-float(i) * 9.0, randf_range(-5.0, 5.0) if i > 0 else 0.0))
		queue_redraw()

	func _draw() -> void:
		Art.glow(self, Vector2.ZERO, 16.0, Color(0.4, 0.75, 1.0, 0.55))
		if _pts.size() > 1:
			draw_polyline(_pts, Color(0.45, 0.75, 1.0, 0.6), 5.0)
			draw_polyline(_pts, Color(0.9, 0.97, 1.0), 2.0)
		draw_circle(Vector2.ZERO, 4.0, Color(0.95, 1.0, 1.0))

	const Art := preload("res://art.gd")
	const Sfx := preload("res://sfx.gd")
	const Particles := preload("res://particles.gd")


# ------------------------------------------------------------
#  עמוד חשמל + כבל חי שמחובר לגב של LIVEWIRE.
#  position = בסיס העמוד על הריצפה. הקטע של הכבל שמונח על הריצפה מחשמל (1 נזק כל 0.7 שנ').
#  הזומבי מת -> הכבל "מת" (אפור, בלי ניצוצות, לא פוגע).
# ------------------------------------------------------------
class LiveCable extends "res://environment/hazard.gd":
	const POLE_H := 150.0
	var owner_z: Node2D = null
	var charge := 0.0          # 0..1: הזומבי טוען פריקה (פולסים חזקים יותר בכבל)
	var dead_line := false
	var _t := 0.0
	var _end := Vector2.ZERO    # נקודת החיבור בגב (גלובלי)

	func _ready() -> void:
		super._ready()
		story_kind = "shock"
		player_damage = 1
		tick = 0.7
		z_index = 1
		rect = Rect2(0, -8, 1, 8)

	func _hazard_tick(delta: float) -> void:
		_t += delta
		var alive: bool = owner_z != null and is_instance_valid(owner_z) and not owner_z.dead
		if not alive and not dead_line:
			dead_line = true
			Sfx.play("zap", global_position + Vector2(0, -POLE_H), -6.0, 0.2, 2)
		active = not dead_line
		if alive:
			var d: float = owner_z._dir
			_end = owner_z.global_position + Vector2(-d * 9.0 * owner_z.sc, -34.0 * owner_z.sc)
		var zx := _end.x - global_position.x
		var a := minf(0.0, zx) + (6.0 if zx < 0.0 else 10.0)
		var b := maxf(0.0, zx) - (10.0 if zx < 0.0 else 6.0)
		rect = Rect2(minf(a, b), -8.0, absf(b - a), 9.0)
		if Art.on_screen(self, global_position, 600.0) or Art.on_screen(self, _end, 200.0):
			queue_redraw()

	func points() -> PackedVector2Array:
		var top := Vector2(0, -POLE_H + 14.0)
		var e := to_local(_end) if _end != Vector2.ZERO else Vector2(40, -30)
		var pts := PackedVector2Array([top])
		var drop := Vector2(signf(e.x) * 22.0 if e.x != 0.0 else 22.0, -2.0)
		for i in range(1, 6):   # מהעמוד אל הריצפה (קשת)
			var u := float(i) / 6.0
			pts.append(top.lerp(drop, u) + Vector2(signf(drop.x) * sin(u * PI) * 16.0, 0.0))
		pts.append(drop)
		var gx := e.x - signf(e.x - drop.x) * 12.0
		var n := maxi(2, int(absf(gx - drop.x) / 24.0))
		for i in range(1, n + 1):   # על הריצפה (גלי קטן)
			var u := float(i) / float(n)
			pts.append(Vector2(lerpf(drop.x, gx, u), -2.0 - absf(sin(u * 9.0 + 1.3)) * 2.0))
		pts.append(e + Vector2(-signf(e.x - drop.x) * 6.0, 10.0))   # עולה אל הגב
		pts.append(e)
		return pts

	func _draw() -> void:
		# עמוד עץ + שנאי
		draw_rect(Rect2(-5, -POLE_H, 10, POLE_H), Color("4a3424"))
		draw_rect(Rect2(-5, -POLE_H, 3, POLE_H), Color("5e4430"))
		draw_rect(Rect2(-24, -POLE_H + 8, 48, 6), Color("3a2a1c"))
		Art.fill_shaded(self, PackedVector2Array([Vector2(6, -POLE_H + 22), Vector2(26, -POLE_H + 22), Vector2(26, -POLE_H + 56), Vector2(6, -POLE_H + 56)]), Color("6a7470"), 0.2, 0.3)
		draw_rect(Rect2(10, -POLE_H + 30, 12, 3), Color(1.0, 0.8, 0.1) if not dead_line else Color("3a3a3a"))
		for x in [-20.0, 0.0, 20.0]:
			draw_rect(Rect2(x - 2, -POLE_H + 2, 4, 6), Color("d8d8d0"))
		var pts := points()
		var c := Color("1a1a1e")
		draw_polyline(pts, Color(0, 0, 0, 0.9), 5.0)
		draw_polyline(pts, c if dead_line else Color("26262e"), 3.0)
		if dead_line:
			return
		# פולסי חשמל זורמים אל הזומבי (חזקים יותר כשהוא טוען)
		var total := 0.0
		for i in range(1, pts.size()):
			total += pts[i].distance_to(pts[i - 1])
		var n := 4 + int(charge * 8.0)
		for k in n:
			var s := fposmod(_t * (220.0 + charge * 500.0) + float(k) * total / float(n), total)
			var p := _at(pts, s)
			Art.glow(self, p, 6.0 + charge * 5.0, Color(0.4, 0.75, 1.0, 0.5 + charge * 0.4))
			draw_circle(p, 1.6 + charge, Color(0.9, 0.97, 1.0))
		if randf() < 0.25 + charge * 0.6:   # ניצוץ קטן על הקטע שבריצפה
			var q := _at(pts, randf() * total)
			draw_line(q, q + Vector2(randf_range(-6, 6), randf_range(-8, -2)), Color(0.8, 0.95, 1.0), 1.2)
		Art.glow(self, Vector2(16, -POLE_H + 39), 10.0, Color(0.4, 0.75, 1.0, 0.25 + 0.2 * sin(_t * 9.0)))

	func _at(pts: PackedVector2Array, s: float) -> Vector2:
		for i in range(1, pts.size()):
			var l := pts[i].distance_to(pts[i - 1])
			if s <= l:
				return pts[i - 1].lerp(pts[i], s / maxf(l, 0.001))
			s -= l
		return pts[pts.size() - 1]

	const Art := preload("res://art.gd")
	const Sfx := preload("res://sfx.gd")


# ------------------------------------------------------------
#  קו מתח שנפל על הכביש: עמוד שבור + כבל לאורך הכביש.
#  מחזור: שקט -> אזהרה (ניצוצות + פצפוץ) -> מכה (קשתות על כל הכבל, פוגע בשחקן ובזומבים)
# ------------------------------------------------------------
class DownedLine extends "res://environment/hazard.gd":
	const IDLE_T := Vector2(2.4, 3.6)
	const WARN_T := 0.7
	const SHOCK_T := 1.0
	var width := 120.0
	var shocks := 0
	var _phase := 0
	var _pt := 1.5
	var _t := 0.0
	var _arcs := []

	func _ready() -> void:
		super._ready()
		story_kind = "shock"
		rect = Rect2(-width * 0.5, -14.0, width, 15.0)
		player_damage = 1
		zombie_damage = 5
		tick = 0.5
		triggerable = true
		active = false
		z_index = 1
		_pt = randf_range(0.6, IDLE_T.y)

	func trigger() -> void:
		_phase = 1
		_pt = 0.2

	func _hazard_tick(delta: float) -> void:
		_t += delta
		_pt -= delta
		if _pt <= 0.0:
			_phase = (_phase + 1) % 3
			var vis := Art.on_screen(self, global_position)
			match _phase:
				0:
					_pt = randf_range(IDLE_T.x, IDLE_T.y)
				1:
					_pt = WARN_T
					if vis:
						Sfx.play("zap", global_position, -9.0, 0.2, 2)
				2:
					_pt = SHOCK_T
					shocks += 1
					_tick_t = 0.0
					if vis:
						Sfx.play("lw_hit", global_position, -3.0, 0.15, 2)
						Particles.burst(get_parent(), global_position + Vector2(0, -4), "spark", Vector2.UP, 10)
		active = _phase == 2
		if Art.on_screen(self, global_position):
			_arcs.clear()
			if _phase == 2:
				for i in 3:
					_arcs.append(_bolt(Vector2(randf_range(-width * 0.5, width * 0.5), -3.0), Vector2(randf_range(-width * 0.5, width * 0.5), -3.0)))
			queue_redraw()

	func _bolt(a: Vector2, b: Vector2) -> PackedVector2Array:
		var pts := PackedVector2Array([a])
		for i in range(1, 6):
			pts.append(a.lerp(b, float(i) / 6.0) + Vector2(randf_range(-3, 3), randf_range(-14, 2)))
		pts.append(b)
		return pts

	func _draw() -> void:
		var hw := width * 0.5
		# עמוד שבור ששוכב באלכסון בקצה
		Art.fill_shaded(self, PackedVector2Array([Vector2(hw - 4, -2), Vector2(hw + 6, -6), Vector2(hw + 60, -58), Vector2(hw + 52, -62)]), Color("4a3424"), 0.15, 0.3)
		draw_line(Vector2(hw + 44, -58), Vector2(hw + 70, -40), Color("3a2a1c"), 4.0)
		# הכבל המפותל על הריצפה
		var pts := PackedVector2Array()
		for i in 13:
			var u := float(i) / 12.0
			pts.append(Vector2(lerpf(-hw, hw + 50.0 * (1.0 if i == 12 else 0.0), u), -3.0 - absf(sin(u * 11.0)) * 3.0))
		pts[12] = Vector2(hw + 54, -56)
		draw_polyline(pts, Color(0, 0, 0, 0.9), 5.0)
		draw_polyline(pts, Color("2a2a30"), 3.0)
		var hot := _phase == 1 or _phase == 2
		var end := Vector2(-hw, -4)
		if hot or fmod(_t, 1.4) < 0.08:   # קצה קרוע מנצנץ
			Art.glow(self, end, 12.0 if _phase == 2 else 7.0, Color(0.4, 0.75, 1.0, 0.6))
			for i in 3:
				draw_line(end, end + Vector2(randf_range(-10, 4), randf_range(-12, 2)), Color(0.85, 0.95, 1.0), 1.2)
		if _phase == 1:
			for i in 2:
				var p := Vector2(randf_range(-hw, hw), -4.0)
				draw_line(p, p + Vector2(randf_range(-4, 4), -randf_range(4, 10)), Color(0.8, 0.95, 1.0, 0.8), 1.0)
		for a in _arcs:
			draw_polyline(a, Color(0.45, 0.75, 1.0, 0.55), 5.0)
			draw_polyline(a, Color(0.92, 0.98, 1.0), 1.8)
		if _phase == 2:
			draw_rect(Rect2(-hw, -16, width, 16), Color(0.4, 0.7, 1.0, 0.12))

	const Art := preload("res://art.gd")
	const Sfx := preload("res://sfx.gd")
	const Particles := preload("res://particles.gd")
