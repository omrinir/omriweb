extends "res://enemies/zombie_type.gd"
# ============================================================
#  SAPPER (שלב 27, "PLATEAU GATE") - חבלן: כומתה, אפוד עם כיסים, תיק מוקשים, את חפירה.
#  חכם: מניח מוקשים בדרך שאתה הולך בה.
#    WALK  - שומר מרחק (KEEP), נסוג אם אתה מתקרב.
#    PLANT - כשאתה הולך לכיוונו: כורע וטומן מוקש (PLANT_T) במקום שבו הוא עומד, ואז נסוג.
#  Mine: חצי קבור, נורה אדומה קטנה מהבהבת. דורכים -> "קליק" ופיצוץ מיד (DELAY). לקפוץ מעליו! פוגע גם בזומבים.
#  MAX_MINES לכל חבלן. זומבים חכמים עוקפים מוקשים.
#  לשנות: KEEP, PLANT_T, MAX_MINES, Mine.DELAY, Mine.RADIUS.
# ============================================================

const SOUNDS := {
	"sp_dig": [["N", 0, 0, 0.0, 0.15, 0.01, 14.0, 0.5, 0.2, 0], ["N", 0, 0, 0.3, 0.15, 0.01, 14.0, 0.5, 0.2, 0]],
	"sp_click": [["S", 2200, 2000, 0.0, 0.04, 0.0, 80.0, 0.5, 1.0, 0], ["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.6, 1.0, 0]],
}

const KEEP := Vector2(260.0, 520.0)
const PLANT_T := 0.9
const MAX_MINES := 4
const CD := Vector2(2.5, 4.0)

enum { WALK, PLANT, BACK }
var state := WALK
var planted := 0             # לבדיקות
var _st := 0.0
var _cd := 1.2
var _prev_dx := 0.0


func stats() -> Dictionary:
	return {"name": "SAPPER", "hp": 32, "walk": 46.0, "chase": 92.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.2, "cover": 0.4, "skin": Color("8a9a88"), "shirt": Color("6a5a3e"), "pants": Color("4a4232"), "shoe": Color("2a2218"), "points": 450}


func can_bite() -> bool:
	return state == WALK


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	if not has_pl:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	var adx := absf(d.x)
	var closing := adx < _prev_dx - 0.5   # אתה מתקרב אליו
	_prev_dx = adx
	match state:
		WALK:
			z._dir = signf(d.x) if adx > 6.0 else z._dir
			if _cd <= 0.0 and planted < MAX_MINES and closing and adx > 190.0 and adx < 560.0 and absf(d.y) < 60.0 and z.is_on_floor() and _spot_free():
				state = PLANT
				_st = PLANT_T
				Sfx.play("sp_dig", z.global_position, -2.0, 0.1, 2)
				return _move(delta, 0.0)
			if adx < KEEP.x and absf(d.y) < 80.0 and not z.is_on_wall():   # קרוב מדי - נסוג
				return _move(delta, -z._dir * float(z.walk_speed) * 1.6)
			if adx > KEEP.y:
				return false   # המוח מביא אותו קרוב יותר
			return _move(delta, 0.0)
		PLANT:
			if _st <= 0.0:
				var m := Mine.new()
				z.get_parent().add_child(m)
				m.global_position = Vector2(z.global_position.x, z.global_position.y)
				planted += 1
				state = BACK
				_st = 1.0
				_cd = randf_range(CD.x, CD.y)
			return _move(delta, 0.0)
		BACK:   # נסוג מהמוקש שלו
			if _st <= 0.0 or z.is_on_wall():
				state = WALK
			return _move(delta, -z._dir * float(z.walk_speed) * 1.8)
	return false


func _spot_free() -> bool:   # לא מוקש על מוקש
	for h in z.get_tree().get_nodes_in_group("mines"):
		if absf(h.global_position.x - z.global_position.x) < 60.0:
			return false
	return true


func _move(delta: float, vx: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


# ============================================================
#  ציור: כומתה, אפוד כיסים, תיק על הגב, כורע עם את בזמן PLANT
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var vest := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var kneel: bool = state == PLANT and not z.dead
	var hip := Vector2(0, -15) if kneel else Vector2(0, -22)
	var sh := hip + Vector2(3 if kneel else 1, -14 if kneel else -15)
	var head := sh + Vector2(3.5, -7.5)
	if kneel:
		z._leg(hip + Vector2(-2, 0), Vector2(-9, 0), col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
		z._leg(hip + Vector2(2, 0), Vector2(7, 0), col(z.pants), sk, col(z.shoe))
	else:
		z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
		z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-12, 0), sh + Vector2(-5, 0), sh + Vector2(-5, 14), sh + Vector2(-12, 14)]), col(Color("4a4030")), 0.15, 0.4)   # תיק
	for q in 2:   # מוקשים בתיק
		z.draw_circle(sh + Vector2(-8.5, 3.0 + float(q) * 5.0), 2.2, col(Color("3a3e30")))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 14.0), Art.shade(sk, 0.25), Art.shade(vest, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), vest, 0.12, 0.4)
	for q in 4:   # כיסים
		z.draw_rect(Rect2(sh + Vector2(-4.0 + float(q % 2) * 5.0, 4.0 + float(q / 2) * 5.0), Vector2(4, 3)), col(Color("4a3e2a")))
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(-6, -2), head + Vector2(-3, -7), head + Vector2(5, -6), head + Vector2(7, -3), head + Vector2(-5, -1)]), col(Color("7a2a24")), Art.OUTLINE, 0.9)   # כומתה
	if not z.dead:
		z.draw_circle(head + Vector2(3.5, -0.5), 0.9, Color(1.0, 0.5, 0.2))
	var hand: Vector2
	if kneel:
		hand = hip + Vector2(14, 6 + sin(z._time * 14.0) * 2.0)
	else:
		hand = sh + Vector2(9.0 + sin(p) * 3.0, 13.0)
	z._arm(sh + Vector2(3, 1), hand, sk, vest)
	z.draw_line(hand, hand + Vector2(0, -8 if not kneel else 4), col(Color("5a4028")), 2.0)   # ידית את
	z.draw_rect(Rect2(hand + Vector2(-2.5, (-12 if not kneel else 4)), Vector2(5, 4)), col(Color("8a8e90")))
	end_draw()
	return true


# ---- מוקש ----
class Mine extends Node2D:
	const DELAY := 0.15
	const RADIUS := 92.0
	const ARM_T := 0.3
	var triggered := false       # לבדיקות
	var _t := 0.0
	var _click := -1.0

	func _ready() -> void:
		z_index = 2
		add_to_group("hazards")
		add_to_group("mines")

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-12, -10), Vector2(24, 12))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _t > ARM_T and absf(p.x - global_position.x) < 14.0 + margin and absf(p.y - global_position.y) < 40.0

	func _physics_process(delta: float) -> void:
		_t += delta
		if _click >= 0.0:
			_click -= delta
			if _click < 0.0:
				preload("res://explosion.gd").blast(get_parent(), global_position + Vector2(0, -8), RADIUS, 40.0, 45, 2, "mine")
				queue_free()
			return
		if _t < ARM_T:
			return
		var pl := get_tree().get_first_node_in_group("player")
		var step := false
		if pl != null and not pl.dead and pl.is_on_floor():
			var r: Rect2 = pl.body_rect()
			step = absf(r.get_center().x - global_position.x) < 14.0 and absf(r.end.y - global_position.y) < 8.0
		if not step and Engine.get_physics_frames() % 3 == 0:
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.dead or not z.is_on_floor() or (z.type_mod != null and z.type_mod.has_method("_spot_free")):
					continue
				if absf(z.global_position.x - global_position.x) < 12.0 and absf(z.global_position.y - global_position.y) < 8.0:
					step = true
					break
		if step:
			triggered = true
			_click = DELAY
			preload("res://sfx.gd").play("sp_click", global_position, 4.0, 0.0, 3)
			queue_redraw()
		elif Engine.get_physics_frames() % 15 == 0 and Art.on_screen(self, global_position):
			queue_redraw()

	func _draw() -> void:
		draw_colored_polygon(Art.ellipse(Vector2(0, -1), 11.0, 3.5, 0.0, 14), Color("3a3e30"))
		draw_rect(Rect2(-3, -5, 6, 3), Color("5a5e50"))
		var on := _click >= 0.0 or fmod(_t, 1.2) < 0.15
		draw_circle(Vector2(5, -3), 1.4, Color(1.0, 0.15, 0.1) if on else Color(0.35, 0.08, 0.06))
		if on:
			draw_circle(Vector2(5, -3), 4.0, Color(1.0, 0.2, 0.1, 0.35))
		for q in 3:   # עפר מעליו
			draw_line(Vector2(-10.0 + float(q) * 8.0, -1), Vector2(-7.0 + float(q) * 8.0, -3), Color("6a5a44"), 1.5)
