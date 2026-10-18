extends "res://enemies/zombie_type.gd"
# ============================================================
#  PANEL (שלב 34, "OBSERVATORY") - טכנאי זומבי שמחזיק מקטע מראה משושה של טלסקופ כמגן.
#  "THEY LEARNED TO REFLECT": יריות מלפנים בגוף / בראש פוגעות במראה ונורות חזרה אליך (Reflect)!
#    יורים ברגליים (מתחת למראה), מאחור, או רימון / אש. המראה נסדקת ונשברת אחרי MIRROR_HP נזק.
#  לשנות: MIRROR_HP, REFLECT_V, REFLECT_DMG.
# ============================================================

const SOUNDS := {
	"pn_ping": [["S", 2600, 2900, 0.0, 0.12, 0.0, 25.0, 0.3, 1.0, 0], ["S", 3900, 4100, 0.0, 0.08, 0.0, 30.0, 0.15, 1.0, 0]],
	"pn_shatter": [["N", 0, 0, 0.0, 0.4, 0.0, 8.0, 0.7, 0.9, 0, 0.4], ["S", 3000, 1200, 0.0, 0.3, 0.0, 10.0, 0.25, 1.0, 0]],
}

const MIRROR_HP := 90
const REFLECT_V := 560.0
const REFLECT_DMG := 1

var mirror := MIRROR_HP
var reflects := 0            # לבדיקות
var _flash := 0.0


func stats() -> Dictionary:
	return {"name": "PANEL", "hp": 34, "walk": 38.0, "chase": 72.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.1,
		"duck": 0.0, "cover": 0.0, "skin": Color("8a9080"), "shirt": Color("e0e0d8"), "pants": Color("3a4a6a"), "shoe": Color("2a2a2e"), "points": 480}


func on_damage(amount: int, hit_pos: Vector2, dir: Vector2, src: Dictionary) -> bool:
	if mirror <= 0:
		return true
	var s := str(src.get("source", "bullet"))
	var ly: float = (hit_pos.y - z.global_position.y) / z.sc
	if (s == "bullet" or s == "melee") and dir.x * z._dir < 0.0 and ly < -14.0:   # המראה
		mirror -= hit_damage(amount, hit_pos, src)
		_flash = 0.15
		reflects += 1
		Sfx.play("pn_ping", hit_pos, -4.0, 0.15, 3)
		if s == "bullet":
			_reflect(hit_pos)
		if mirror <= 0:
			Sfx.play("pn_shatter", hit_pos, 2.0, 0.1, 2)
			Particles.burst(z.get_parent(), hit_pos, "spark", Vector2.UP, 16)
			z._popup("MIRROR SHATTERED", Color("c0e0ff"), 13, -80.0)
		return false
	return true


func _reflect(at: Vector2) -> void:
	var pl := player()
	if pl == null:
		return
	var b := Reflect.new()
	z.get_parent().add_child(b)
	b.global_position = at + Vector2(z._dir * 6.0, 0)
	var tgt: Vector2 = pl.global_position + Vector2(randf_range(-20, 20), -26.0 + randf_range(-12, 12))
	b.velocity = (tgt - b.global_position).normalized() * REFLECT_V


func physics(_pl: Node, delta: float) -> bool:
	_flash -= delta
	return false


class Reflect extends Node2D:   # הכדור שחוזר
	var velocity := Vector2.ZERO
	var _t := 0.0

	func _ready() -> void:
		z_index = 9

	func _physics_process(delta: float) -> void:
		_t += delta
		var to := global_position + velocity * delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.body_rect().grow(3.0).has_point(to):
			pl.hurt(1, Vector2(signf(velocity.x), -0.4))   # = REFLECT_DMG
			queue_free()
			return
		var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, to, 1))
		if not hit.is_empty() or _t > 2.0:
			queue_free()
			return
		global_position = to
		queue_redraw()

	func _draw() -> void:
		var d := velocity.normalized()
		DrawBatch.line(self, -d * 14.0, Vector2.ZERO, Color(0.7, 0.9, 1.0, 0.5), 3.0)
		DrawBatch.line(self, -d * 8.0, Vector2.ZERO, Color(1, 1, 1), 1.5)


# ============================================================
#  ציור: סרבל טכנאי לבן, משקפי מגן, מקטע מראה משושה גדול לפניו (נסדק)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(10, 4), Art.shade(sk, 0.25), Art.shade(suit, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, 3), hip + Vector2(-7, 3)]), suit, 0.12, 0.4)
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	DrawBatch.rect(z, Rect2(head + Vector2(0, -2.5), Vector2(6, 3)), col(Color("2a3a4a")))   # משקפי מגן
	z._arm(sh + Vector2(3, 1), sh + Vector2(12, 8), sk, suit)
	if mirror > 0 and not z.dead:   # מראה משושה (מראה טלסקופ)
		var c := sh + Vector2(15, 4)
		var pts := PackedVector2Array()
		for q in 6:
			pts.append(c + Vector2.from_angle(float(q) * TAU / 6.0 + PI / 6.0) * Vector2(7.0, 22.0))
		var k := clampf(float(mirror) / float(MIRROR_HP), 0.0, 1.0)
		DrawBatch.colored_polygon(z, pts, Color(0.55, 0.62, 0.75) if _flash <= 0.0 else Color(1, 1, 1))
		DrawBatch.colored_polygon(z, PackedVector2Array([c + Vector2(-5, -18), c + Vector2(-1, -18), c + Vector2(3, 12), c + Vector2(-1, 12)]), Color(0.9, 0.95, 1.0, 0.45))   # ברק
		DrawBatch.polyline(z, pts + PackedVector2Array([pts[0]]), Color("1a1e28"), 1.4)
		if k < 0.66:   # סדקים
			DrawBatch.polyline(z, PackedVector2Array([c + Vector2(-4, -10), c + Vector2(0, -2), c + Vector2(-3, 6)]), Color(0.1, 0.1, 0.15), 1.0)
		if k < 0.33:
			DrawBatch.polyline(z, PackedVector2Array([c + Vector2(4, -14), c + Vector2(1, -4), c + Vector2(5, 10)]), Color(0.1, 0.1, 0.15), 1.0)
	end_draw()
	return true
