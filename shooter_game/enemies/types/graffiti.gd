extends "res://enemies/zombie_type.gd"
# ============================================================
#  GRAFFITI (שלב 37, "FAVELA HEIGHTS") - "פישאדור" זומבי: קפוצ'ון, בנדנה על הפנים, תיק מלא פחיות ספריי, פחית בכל יד.
#  "THEY LEARNED TO WAIT FOR THE RELOAD": מסתובב במרחק (KEEP) ומחכה. אתה טוען? מסתער פנימה!
#    קרוב (SPRAY_R) -> מרסס צבע בפנים שלך (SPRAY_T): כתמי צבע על המסך (BLIND_T), וכל הזומבים בטווח MARK_R
#    יודעים איפה אתה (סימון). ירייה בפחית שביד בזמן הריסוס = הפחית מתפוצצת לו בפנים (ענן צבע, x2).
#  לשנות: KEEP, SPRAY_R, SPRAY_T, BLIND_T, MARK_R.
# ============================================================

const SOUNDS := {
	"gf_rattle": [["C", 0, 0, 0.0, 0.04, 0.0, 60.0, 0.4, 1.0, 0], ["C", 0, 0, 0.07, 0.04, 0.0, 60.0, 0.4, 1.0, 0], ["C", 0, 0, 0.14, 0.04, 0.0, 60.0, 0.4, 1.0, 0]],
	"gf_spray": [["N", 0, 0, 0.0, 0.7, 0.03, 2.0, 0.45, 0.85, 0, 0.9]],
	"gf_pop": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.8, 0.6, 0, 0.5], ["S", 300, 120, 0.0, 0.2, 0.0, 12.0, 0.4, 1.0, 0]],
}

const KEEP := 260.0
const SPRAY_R := 130.0
const SPRAY_T := 0.7
const BLIND_T := 3.5
const MARK_R := 700.0
const PAINTS := [Color("ff3a8a"), Color("30e0a0"), Color("ffd020"), Color("3a8aff"), Color("ff6a20")]

enum { PROWL, RUSH, SPRAY, POPPED }
var state := PROWL
var sprays := 0              # לבדיקות
var blinded := 0
var rushes := 0
var _st := 0.0
var _cd := 1.0
var _paint := Color.RED


func stats() -> Dictionary:
	return {"name": "GRAFFITI", "hp": 28, "walk": 44.0, "chase": 92.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.3, "cover": 0.3, "skin": Color("7a8470"), "shirt": Color("2a2a34"), "pants": Color("4a4a5a"), "shoe": Color("e0e0e0"), "points": 480}


func setup() -> void:
	_paint = PAINTS[randi() % PAINTS.size()]


func brain_overrides() -> Dictionary:
	return {"aggression": 0.2}


func can_bite() -> bool:
	return state == PROWL or state == POPPED


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == SPRAY and hit_pos.distance_to(can_pos()) < 10.0 * z.sc:   # הפחית מתפוצצת
		state = POPPED
		_st = 1.5
		Sfx.play("gf_pop", hit_pos, 0.0, 0.1, 2)
		Particles.burst(z.get_parent(), hit_pos, "smoke", Vector2.UP, 8)
		z._popup("CAN POPPED", _paint, 13, -80.0)
	return true


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 2.0 if state == POPPED else 1.0


func can_pos() -> Vector2:
	return z.global_position + Vector2(z._dir * 14.0 * z.wf, -38.0) * z.sc


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	var near: bool = absf(d.y) < 90.0
	match state:
		PROWL:
			var weak: bool = pl.is_reloading()
			if near and absf(d.x) < 600.0 and weak and _cd <= 0.0:
				state = RUSH
				rushes += 1
				Sfx.play("gf_rattle", z.global_position, -2.0, 0.1, 2)
				z._popup("YOU'RE RELOADING...", Color("ffe080"), 12, -80.0)
				return false
			if near and absf(d.x) < KEEP:   # שומר מרחק
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				return _move(-z._dir * float(z.walk_speed) * 1.4, delta)
			return false
		RUSH:
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if absf(d.x) < SPRAY_R and near:
				state = SPRAY
				_st = SPRAY_T
				sprays += 1
				Sfx.play("gf_spray", z.global_position, 0.0, 0.1, 2)
				return _move(0.0, delta)
			if absf(d.x) > 700.0:
				state = PROWL
				return false
			return _move(z._dir * float(z.chase_speed) * 1.5, delta)
		SPRAY:
			z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if Engine.get_physics_frames() % 3 == 0:
				_puff(can_pos() + Vector2(z._dir * 10.0, 0))
			if _st <= SPRAY_T * 0.4 and _st + delta > SPRAY_T * 0.4:   # הצבע מגיע לפנים
				if absf(d.x) < SPRAY_R + 20.0 and near and signf(d.x) == z._dir:
					_blind(pl)
			if _st <= 0.0:
				state = PROWL
				_cd = 3.0
			return _move(0.0, delta)
		POPPED:
			if _st <= 0.0:
				state = PROWL
				_cd = 2.0
			return _move(0.0, delta)
	return false


func _move(vx: float, delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, vx, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	elif z.is_on_wall() and vx != 0.0:
		z.velocity.y = -380.0
	z.move_and_slide()
	return true


func _puff(at: Vector2) -> void:
	var p := Puff.new()
	p.col = _paint
	p.vel = Vector2(z._dir * randf_range(160, 240), randf_range(-30, 30))
	z.get_parent().add_child(p)
	p.global_position = at


func _blind(pl: Node) -> void:
	blinded += 1
	pl._say("MY EYES!", _paint)
	var old: Node = z.get_tree().root.get_node_or_null("PaintSplats")
	if old != null:
		old.add_splats(_paint)
	else:
		var ps := PaintSplats.new()
		ps.name = "PaintSplats"
		z.get_tree().root.add_child(ps)
		ps.add_splats(_paint)
	for o in z.get_tree().get_nodes_in_group("zombies"):   # כולם יודעים איפה אתה
		if o != z and not o.dead and not o.is_boss() and o.global_position.distance_to(pl.global_position) < MARK_R:
			o._alert_t = maxf(float(o._alert_t), 6.0)
			if o.dormant:
				o._wake()


class Puff extends Node2D:   # ענן ספריי
	var col := Color.RED
	var vel := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 9

	func _process(delta: float) -> void:
		_t += delta
		position += vel * delta
		vel *= 1.0 - 2.5 * delta
		if _t > 0.6:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.circle(self, Vector2.ZERO, 4.0 + _t * 22.0, Color(col, 0.45 * (1.0 - _t / 0.6)))


# כתמי צבע על המסך (שכבה מעל הכל)
class PaintSplats extends CanvasLayer:
	const T := 3.5   # = BLIND_T
	var _sp := []    # [מיקום, רדיוס, צבע, זרע]
	var _t := 0.0
	var _node: Node2D = null

	func _ready() -> void:
		layer = 60
		_node = Node2D.new()
		add_child(_node)
		_node.draw.connect(_draw_splats)

	func add_splats(c: Color) -> void:
		_t = 0.0
		var vs: Vector2 = get_viewport().get_visible_rect().size
		for i in 5:
			_sp.append([Vector2(randf_range(vs.x * 0.2, vs.x * 0.8), randf_range(vs.y * 0.15, vs.y * 0.8)), randf_range(70.0, 150.0), c, randi()])

	func _process(delta: float) -> void:
		_t += delta
		if _t > T:
			queue_free()
			return
		_node.queue_redraw()

	func _draw_splats() -> void:
		var a := clampf((T - _t) / 1.0, 0.0, 1.0)
		for s in _sp:
			var r := RandomNumberGenerator.new()
			r.seed = int(s[3])
			var c: Color = s[2]
			var p: Vector2 = s[0]
			var rad: float = s[1]
			DrawBatch.circle(_node, p, rad, Color(c, 0.85 * a))
			for q in 7:   # טיפות ונזילות
				var ang := r.randf() * TAU
				DrawBatch.circle(_node, p + Vector2.from_angle(ang) * rad * r.randf_range(0.9, 1.3), rad * r.randf_range(0.12, 0.25), Color(c, 0.85 * a))
			for q in 3:
				var dx := r.randf_range(-rad * 0.6, rad * 0.6)
				DrawBatch.line(_node, p + Vector2(dx, rad * 0.5), p + Vector2(dx, rad + 30.0 + 60.0 * minf(_t, 1.0)), Color(c, 0.8 * a), 8.0)


# ============================================================
#  ציור: קפוצ'ון כהה עם כובע, בנדנה צבעונית על הפנים, תיק גב עם פחיות, פחית ספריי ביד (מורמת בריסוס)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var hood := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	DrawBatch.rect(z, Rect2(sh + Vector2(-12, 0), Vector2(6, 14)), col(Color("3a5a3a")))   # תיק
	for q in 3:
		DrawBatch.rect(z, Rect2(sh + Vector2(-11.0 + float(q) * 2.0, -4), Vector2(1.6, 5)), col(PAINTS[q]))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 2.0, 15.0), Art.shade(sk, 0.25), Art.shade(hood, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, 3), hip + Vector2(-7, 3)]), hood, 0.12, 0.4)
	DrawBatch.colored_polygon(z, PackedVector2Array([sh + Vector2(-3, 8), sh + Vector2(4, 9), sh + Vector2(1, 14)]), col(_paint))   # כתם צבע על הקפוצ'ון
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-7, 2), head + Vector2(-6, -6), head + Vector2(2, -8), head + Vector2(6, -4), head + Vector2(-2, -4), head + Vector2(-4, 3)]), hood)   # כובע קפוצ'ון
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-2, 0), head + Vector2(6, 0), head + Vector2(5, 5), head + Vector2(-1, 5)]), col(_paint.darkened(0.2)))   # בנדנה
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -2.0), 1.1, Color(1.0, 0.85, 0.4))
	var hf := sh + Vector2(13, -2) if state == SPRAY or state == RUSH else sh + Vector2(11, 6)
	z._arm(sh + Vector2(3, 1), hf, sk, hood)
	if state != POPPED:   # פחית
		DrawBatch.rect(z, Rect2(hf + Vector2(-2, -6), Vector2(5, 9)), col(Color("c0c4cc")))
		DrawBatch.rect(z, Rect2(hf + Vector2(-2, -8), Vector2(5, 2)), col(_paint))
	end_draw()
	return true
