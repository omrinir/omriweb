extends "res://enemies/zombie_type.gd"
# ============================================================
#  WASHER (שלב 38, "MEGACITY CORE") - שוטף חלונות של גורד שחקים: סרבל, רתמה, מגב ודלי. תלוי על חבל מלמעלה.
#  "THEY LEARNED TO WAIT ABOVE": תלוי HANG_H פיקסלים מעל הקרקע ומטפטף סבון -> שלולית סבון חלקה מתחתיו (player.slip_t).
#    אתה קרוב (SWING_R)? מתנדנד אליך. אתה מתחתיו (DROP_R)? משחרר את החבל ונוחת עליך (1 נזק + סחרחורת).
#    תלוי = חשוף (x1.5). אחרי הנחיתה - זומבי רגיל.
#  לשנות: HANG_H, DROP_R, SWING_R, SWING_MAX, SOAP_W.
# ============================================================

const SOUNDS := {
	"ws_creak": [["S", 300, 260, 0.0, 0.4, 0.05, 3.0, 0.12, 1.0, 0.05], ["N", 0, 0, 0.0, 0.3, 0.0, 6.0, 0.1, 0.4, 0, 0.6]],
	"ws_drop": [["S", 800, 200, 0.0, 0.35, 0.0, 6.0, 0.2, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 6.0, 0.2, 0.5, 0, 0.7]],
	"ws_land": [["N", 0, 0, 0.0, 0.25, 0.0, 10.0, 0.7, 0.2, 0], ["S", 100, 60, 0.0, 0.2, 0.0, 12.0, 0.4, 1.0, 0]],
}

const HANG_H := 230.0
const DROP_R := 40.0
const SWING_R := 260.0
const SWING_MAX := 90.0
const SOAP_W := 120.0

enum { HANG, DROP, WALK }
var state := HANG
var drops := 0               # לבדיקות
var landed_on := 0
var _anchor := Vector2.ZERO
var _swing := 0.0
var _amp := 0.0
var _mask := 1 | 16
var _soap: Node2D = null


func stats() -> Dictionary:
	return {"name": "WASHER", "hp": 30, "walk": 40.0, "chase": 78.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.0, "cover": 0.2, "skin": Color("8a9a80"), "shirt": Color("2a6aa0"), "pants": Color("2a6aa0"), "shoe": Color("2a2a2a"), "points": 470}


func setup() -> void:
	_hang.call_deferred()


func _hang() -> void:
	if z == null or not is_instance_valid(z) or z.dead:
		return
	_mask = z.collision_mask
	z.collision_mask = 0
	_anchor = z.global_position + Vector2(0, -HANG_H)
	z.global_position = _anchor
	_soap = Soap.new()
	_soap.w = SOAP_W
	z.get_parent().add_child(_soap)
	_soap.global_position = Vector2(_anchor.x, _anchor.y + HANG_H)


func can_bite() -> bool:
	return state == WALK


func can_groan() -> bool:
	return state != DROP


func damage_mult(_zone: String, _src: Dictionary) -> float:
	return 1.5 if state == HANG else 1.0


func on_death() -> void:
	if state == HANG:   # נופל
		z.collision_mask = _mask


func physics(pl: Node, delta: float) -> bool:
	if z.dead:
		return false
	match state:
		HANG:
			if _anchor == Vector2.ZERO:
				return true
			_swing += delta
			var has_pl: bool = pl != null and not pl.dead
			var dx: float = (pl.global_position.x - _anchor.x) if has_pl else 999.0
			if has_pl and absf(dx) < SWING_R:   # מתנדנד אליך
				_amp = move_toward(_amp, minf(absf(dx), SWING_MAX), 80.0 * delta)
				z._dir = signf(dx) if absf(dx) > 4.0 else z._dir
			else:
				_amp = move_toward(_amp, 8.0, 40.0 * delta)
			var off := sin(_swing * 2.2) * _amp
			if has_pl:
				off = lerpf(off, clampf(dx, -_amp, _amp), 0.5)
			z.global_position = Vector2(_anchor.x + off, _anchor.y + 0.0)
			z.velocity = Vector2.ZERO
			if Engine.get_physics_frames() % 50 == 0 and Art.on_screen(z, z.global_position):
				Sfx.play("ws_creak", z.global_position, -8.0, 0.1, 2)
				Particles.burst(z.get_parent(), z.global_position + Vector2(0, -10), "drop", Vector2.DOWN, 2)
			if has_pl and absf(pl.global_position.x - z.global_position.x) < DROP_R and pl.global_position.y > z.global_position.y + 60.0:
				state = DROP
				drops += 1
				z.collision_mask = _mask
				z.velocity = Vector2(0, 120.0)
				Sfx.play("ws_drop", z.global_position, 0.0, 0.1, 2)
				z._popup("FROM ABOVE!", Color("80d0ff"), 13, -60.0)
			return true
		DROP:
			z.velocity.y += z.gravity * 1.2 * delta
			z.move_and_slide()
			if z.is_on_floor():
				state = WALK
				Sfx.play("ws_land", z.global_position, 0.0, 0.1, 2)
				Particles.burst(z.get_parent(), z.global_position, "smoke", Vector2.UP, 5)
				if pl != null and not pl.dead and absf(pl.global_position.x - z.global_position.x) < 46.0 and absf(pl.global_position.y - z.global_position.y) < 50.0:
					landed_on += 1
					pl.hurt(1, Vector2(signf(pl.global_position.x - z.global_position.x + 0.01) * 1.5, -0.6))
					if pl.has_method("daze"):
						pl.daze(0.8)
			return true
	return false


# שלולית סבון חלקה (נשארת מתחת לחבל גם אחרי שהוא נפל - מתייבשת לאט)
class Soap extends Node2D:
	var w := 120.0
	var _t := 0.0

	func _ready() -> void:
		z_index = 2

	func _physics_process(delta: float) -> void:
		_t += delta
		var pl := get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and pl.is_on_floor() and absf(pl.global_position.x - global_position.x) < w * 0.5 and absf(pl.global_position.y - global_position.y) < 8.0:
			pl.slip_t = 0.15
		if _t > 40.0:
			queue_free()
			return
		if Engine.get_physics_frames() % 6 == 0:
			queue_redraw()

	func _draw() -> void:
		DrawBatch.begin(self)
		_draw_b()
		DrawBatch.end(self)

	func _draw_b() -> void:
		DrawBatch.colored_polygon(self, Art.ellipse(Vector2(0, -1), w * 0.5, 4.0, 0.0, 16), Color(0.85, 0.92, 1.0, 0.55))
		for q in 7:   # בועות
			var bx := (fposmod(float(q) * 37.0, w) - w * 0.5)
			var bs := 1.5 + fposmod(float(q) * 1.7 + _t, 2.0)
			DrawBatch.arc(self, Vector2(bx, -3.0 - fposmod(float(q) * 3.0, 4.0)), bs, 0.0, TAU, 8, Color(1, 1, 1, 0.7), 1.0)


# ============================================================
#  ציור: סרבל כחול, רתמה צהובה, קסדה לבנה, מגב ביד; תלוי = רגליים מתנדנדות, חבל עד למעלה
# ============================================================
func draw() -> bool:
	if state == HANG and not z.dead:   # החבל
		DrawBatch.line(z, Vector2(0, -40), Vector2(_anchor.x - z.global_position.x, -900.0), Color(0.85, 0.85, 0.8), 1.4)
	begin_draw()
	var sk := col(z.skin)
	var suit := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	if state != WALK:
		f = [Vector2(4.0 + sin(z._time * 3.0) * 2.0, 2.0), Vector2(-3.0, 0.0)]
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	var hb := sh + Vector2(-2, -12) if state == HANG else sh + Vector2(-5.0 - sin(p) * 2.0, 15.0)
	z._arm(sh + Vector2(-3, 1), hb, Art.shade(sk, 0.25), Art.shade(suit, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-8, -1), sh + Vector2(8, 0), hip + Vector2(7, 3), hip + Vector2(-7, 3)]), suit, 0.12, 0.4)
	DrawBatch.line(z, sh + Vector2(-6, 0), hip + Vector2(5, 2), col(Color("e0c020")), 2.0)   # רתמה
	DrawBatch.line(z, sh + Vector2(6, 0), hip + Vector2(-5, 2), col(Color("e0c020")), 2.0)
	DrawBatch.rect(z, Rect2(hip + Vector2(-7, -1), Vector2(14, 3)), col(Color("e0c020")))
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	DrawBatch.colored_polygon(z, Art.ellipse(head + Vector2(0, -3), 6.0, 3.6, 0.0, 10), col(Color("e8e8e8")))   # קסדה
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(3.0, -0.5), 1.1, Color(1.0, 0.85, 0.4))
	var hf := sh + Vector2(12, 4)
	z._arm(sh + Vector2(3, 1), hf, sk, suit)
	DrawBatch.line(z, hf, hf + Vector2(4, -10), col(Color("6a6a6a")), 1.6)   # מגב
	DrawBatch.line(z, hf + Vector2(0, -12), hf + Vector2(8, -8), col(Color("2a2a2a")), 2.5)
	if state == HANG:   # דלי תלוי
		DrawBatch.rect(z, Rect2(hip + Vector2(-9, 6), Vector2(7, 7)), col(Color("e0c020")))
	end_draw()
	return true
