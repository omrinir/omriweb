extends "res://enemies/zombie_type.gd"
# ============================================================
#  AVALANCHER (שלב 35, "SKULL GLACIER") - זומבי גדול עם פּוּטוּטוּ (חצוצרת קונכייה אנדית) ופונצ'ו כבד.
#  "THEY LEARNED THE MOUNTAIN": נשאר מאחור, תוקע בקונכייה (BLOW_T - אפשר לקטוע בירייה) -> מפולת שלג (Slide)
#    נופלת מלמעלה איפה שאתה תהיה (לפי המהירות שלך): צל + שלג מטפטף = אזהרה (WARN_T), ואז גושי שלג.
#    פוגע בך (1) וקובר אותך עד הברכיים (player.slow_t) + ערמת שלג (Pile) שמאטה לכמה שניות.
#    זומבים "למדו": הם יוצאים מהצל לפני שהשלג נופל.
#  לשנות: BLOW_T, SLIDE_CD, SLIDE_W, WARN_T, PILE_T.
# ============================================================

const SOUNDS := {
	"av_horn": {"drive": 1.4, "layers": [["S", 150, 160, 0.0, 1.1, 0.15, 0.8, 0.6, 1.0, 0.06], ["S", 300, 320, 0.0, 1.1, 0.15, 0.8, 0.25, 1.0, 0.06], ["N", 0, 0, 0.0, 1.0, 0.1, 1.0, 0.1, 0.3, 0, 0.3]]},
	"av_rumble": {"drive": 1.6, "layers": [["N", 0, 0, 0.0, 1.4, 0.4, 1.5, 0.9, 0.08, 0], ["S", 45, 35, 0.0, 1.4, 0.3, 1.5, 0.6, 1.0, 0]]},
	"av_thump": [["N", 0, 0, 0.0, 0.5, 0.0, 6.0, 1.0, 0.15, 0], ["S", 80, 40, 0.0, 0.4, 0.0, 8.0, 0.6, 1.0, 0]],
}

const BLOW_T := 1.0
const SLIDE_CD := 6.0
const SLIDE_W := 150.0
const WARN_T := 1.1
const PILE_T := 6.0

enum { WALK, BLOW }
var state := WALK
var slides := 0              # לבדיקות
var buried := 0
var interrupts := 0
var _st := 0.0
var _cd := 2.5


func stats() -> Dictionary:
	return {"name": "AVALANCHER", "hp": 60, "walk": 34.0, "chase": 58.0, "damage": 2, "bite_delay": 1.0, "scale": 1.3, "width": 1.25,
		"duck": 0.0, "cover": 0.2, "skin": Color("8a9480"), "shirt": Color("7a2a3a"), "pants": Color("3a3028"), "shoe": Color("2a2018"), "points": 560}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15}


func can_bite() -> bool:
	return state == WALK


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == BLOW and hit_pos.y < z.global_position.y - 36.0 * z.sc:   # פגיעה בראש / בקונכייה קוטעת
		interrupts += 1
		state = WALK
		_cd = 2.0
		z._popup("HORN CUT OFF", Color("ffe0c0"), 13, -90.0)
	return true


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if z.dead or pl == null or pl.dead:
		return false
	var d: Vector2 = pl.global_position - z.global_position
	match state:
		WALK:
			if _cd <= 0.0 and absf(d.x) < 650.0 and absf(d.x) > 120.0 and absf(d.y) < 260.0:
				state = BLOW
				_st = BLOW_T
				z._dir = signf(d.x)
				Sfx.play("av_horn", z.global_position, 2.0, 0.05, 2)
				return _stay(delta)
			if absf(d.x) < 200.0 and absf(d.y) < 80.0:   # נשאר מאחור
				z._dir = signf(d.x)
				z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.4, 500.0 * delta)
				if not z.is_on_floor():
					z.velocity.y += z.gravity * delta
				z.move_and_slide()
				return true
			return false
		BLOW:
			if _st <= 0.0:
				state = WALK
				_cd = SLIDE_CD
				_call_slide(pl)
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _call_slide(pl: Node) -> void:
	slides += 1
	var tx: float = pl.global_position.x + clampf(pl.velocity.x * (WARN_T * 0.8), -260.0, 260.0)
	# על איזה משטח זה ינחת (קרקע או מדף)
	var q := PhysicsRayQueryParameters2D.create(Vector2(tx, pl.global_position.y - 60.0), Vector2(tx, pl.global_position.y + 400.0), 1 | 16)
	var hit: Dictionary = z.get_world_2d().direct_space_state.intersect_ray(q)
	var gy: float = pl.global_position.y if hit.is_empty() else float(hit.position.y)
	var s := Slide.new()
	s.owner_t = self
	z.get_parent().add_child(s)
	s.global_position = Vector2(tx, gy)
	Sfx.play("av_rumble", s.global_position, 2.0, 0.05, 2)


# ============================================================
#  מפולת: צל + שלג מטפטף (אזהרה) -> גושי שלג נופלים -> ערמת שלג שמאטה (PILE_T)
# ============================================================
class Slide extends Node2D:
	const W := 150.0          # = SLIDE_W
	const WARN := 1.1         # = WARN_T
	const PILE := 6.0         # = PILE_T
	var owner_t = null
	var _t := 0.0
	var _fell := false
	var _chunks := []

	func _ready() -> void:
		z_index = 8
		add_to_group("hazards")
		for i in 9:
			_chunks.append([randf_range(-W * 0.5, W * 0.5), randf_range(-760.0, -560.0), randf_range(7.0, 15.0), randf_range(0.0, 0.25)])

	func world_rect() -> Rect2:
		return Rect2(global_position + Vector2(-W * 0.5, -90.0), Vector2(W, 90.0))

	func danger_at(p: Vector2, margin := 0.0) -> bool:
		return _t < WARN + 0.4 and world_rect().grow(margin).has_point(p)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t < WARN:
			if Engine.get_physics_frames() % 3 == 0:
				preload("res://particles.gd").burst(get_parent(), global_position + Vector2(randf_range(-W * 0.5, W * 0.5), -300.0), "snow", Vector2.DOWN, 1)
			# הזומבים "למדו": יוצאים מהצל
			for zz in get_tree().get_nodes_in_group("zombies"):
				if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - global_position.x) < W * 0.6 and absf(zz.global_position.y - global_position.y) < 40.0:
					zz.velocity.x = signf(zz.global_position.x - global_position.x + 0.01) * 160.0
		elif not _fell and _t >= WARN + 0.35:
			_fell = true
			preload("res://sfx.gd").play("av_thump", global_position, 2.0, 0.1, 2)
			preload("res://particles.gd").burst(get_parent(), global_position + Vector2(0, -10), "snow", Vector2.UP, 22)
			var cam: Camera2D = get_viewport().get_camera_2d()
			if cam != null and cam.has_method("shake"):
				cam.shake(6.0, 0.3)
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < W * 0.5 + 8.0 and absf(pl.global_position.y - global_position.y) < 60.0:
				pl.hurt(1, Vector2(0.0, -0.3))
				pl.slow_t = maxf(float(pl.slow_t), 2.5)
				pl._say("BURIED IN SNOW!", Color("e0f0ff"))
				if owner_t != null and is_instance_valid(owner_t.z):
					owner_t.buried += 1
			for zz in get_tree().get_nodes_in_group("zombies"):
				if not zz.dead and not zz.is_boss() and absf(zz.global_position.x - global_position.x) < W * 0.5 and absf(zz.global_position.y - global_position.y) < 40.0:
					zz.take_damage(10, zz.global_position + Vector2(0, -40), Vector2(0, 1), false, {"source": "snow", "fixed": 10})
		elif _fell:   # ערמת שלג: מאטה את מי שבתוכה
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and not pl.dead and absf(pl.global_position.x - global_position.x) < W * 0.4 and absf(pl.global_position.y - global_position.y) < 30.0:
				pl.slow_t = maxf(float(pl.slow_t), 0.2)
			if _t > WARN + 0.35 + PILE:
				queue_free()
				return
		queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		if _t < WARN + 0.35:
			var k := clampf(_t / WARN, 0.0, 1.0)
			DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -2), W * 0.5 * (0.5 + 0.5 * k), 6.0, 0.0, 16), Color(0.1, 0.2, 0.4, 0.15 + 0.3 * k))   # צל
			if _t > WARN:   # גושים נופלים
				var f := (_t - WARN) / 0.35
				for c in _chunks:
					var y: float = lerpf(float(c[1]), -float(c[2]), clampf(f + float(c[3]), 0.0, 1.0))
					DrawBatch.circle(self, Vector2(float(c[0]), y), float(c[2]), Color(0.95, 0.97, 1.0))
					DrawBatch.circle(self, Vector2(float(c[0]) + 2.0, y + 2.0), float(c[2]) * 0.6, Color(0.75, 0.85, 0.95))
		else:   # ערמה שנמסה לאט
			var k := clampf(1.0 - (_t - WARN - 0.35) / PILE, 0.0, 1.0)
			var h := 26.0 * (0.4 + 0.6 * k)
			var p := PackedVector2Array([Vector2(-W * 0.5, 0), Vector2(-W * 0.35, -h * 0.6), Vector2(-W * 0.15, -h), Vector2(W * 0.1, -h * 0.85), Vector2(W * 0.3, -h * 0.55), Vector2(W * 0.5, 0)])
			DrawBatch.colored_polygon(self, p, Color(0.93, 0.96, 1.0))
			DrawBatch.polyline(self, p, Color(0.7, 0.8, 0.92), 1.5)
			DrawBatch.colored_polygon(self, PackedVector2Array([Vector2(-W * 0.15, -h), Vector2(W * 0.1, -h * 0.85), Vector2(W * 0.05, -h * 0.5), Vector2(-W * 0.1, -h * 0.6)]), Color(0.78, 0.86, 0.96))


# ============================================================
#  ציור: גדול, פונצ'ו בורדו עם פסים, כובע צ'ולו, קונכיית פוטוטו ביד (בפה בזמן תקיעה)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var pon := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -38)
	var head := sh + Vector2(4, -8)
	z._leg(hip + Vector2(-3, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(3, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-6.0 - sin(p) * 2.0, 15.0), Art.shade(sk, 0.25), Art.shade(pon, 0.3))
	var pp := PackedVector2Array([sh + Vector2(-12, -1), sh + Vector2(12, -1), hip + Vector2(14, 6), hip + Vector2(-14, 6)])
	Art.fill_shaded(z, pp, pon, 0.15, 0.4)
	for q in 3:   # פסים
		var yy := -30.0 + float(q) * 5.0
		DrawBatch.line(z, Vector2(-12.0 + float(q), yy), Vector2(12.0 + float(q) * 0.5, yy), col([Color("e0b030"), Color("2a6a4a"), Color("e0e0d0")][q]), 1.5)
	Art.oval_shaded(z, head, 5.6, 6.0, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	DrawBatch.colored_polygon(z, PackedVector2Array([head + Vector2(-6, -2), head + Vector2(0, -10), head + Vector2(6, -2)]), col(Color("c04a2a")))   # צ'ולו
	DrawBatch.line(z, head + Vector2(-6, -2), head + Vector2(-6, 6), col(Color("c04a2a")), 2.0)
	DrawBatch.line(z, head + Vector2(6, -2), head + Vector2(6, 6), col(Color("c04a2a")), 2.0)
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.5, -1.0), 1.1, Color(0.8, 0.95, 1.0))
	var hf := head + Vector2(7, 2) if state == BLOW else sh + Vector2(13, 6)
	z._arm(sh + Vector2(3, 1), hf, sk, pon)
	# קונכיית הפוטוטו
	var cc := hf + Vector2(5, 0)
	DrawBatch.colored_polygon(z, PackedVector2Array([cc + Vector2(-5, -3), cc + Vector2(8, -6), cc + Vector2(12, 0), cc + Vector2(8, 6), cc + Vector2(-5, 3)]), col(Color("e8d0b0")))
	DrawBatch.arc(z, cc + Vector2(6, 0), 3.5, 0.0, TAU, 8, col(Color("b07a5a")), 1.2)
	if state == BLOW and not z.dead:   # גלי קול
		var k := 1.0 - clampf(_st / BLOW_T, 0.0, 1.0)
		for q in 3:
			var r := 8.0 + fposmod(k * 30.0 + float(q) * 10.0, 30.0)
			DrawBatch.arc(z, cc + Vector2(12, 0), r, -0.7, 0.7, 8, Color(1, 1, 1, 0.5 * (1.0 - r / 38.0)), 1.5)
	end_draw()
	return true
