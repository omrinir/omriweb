extends "res://enemies/zombie_type.gd"
# ============================================================
#  SPOTTER (שלב 34, "OBSERVATORY") - אסטרונום זומבי: מעיל פוך, פנס ראש אדום, ופנס חיפוש ענק ביד.
#  "THEY LEARNED TO WATCH": שומר מרחק (BACKOFF) ומכוון את אלומת הפנס אליך (LOCK_T = אזהרה: האלומה נצמדת).
#  ננעל עליך -> SPOTTED: כל הזומבים בטווח RALLY_R יודעים איפה אתה ומסתערים (alert + rush).
#  ירייה בפנס (ביד שלו) שוברת אותו -> נשאר זומבי חלש שבורח.
#  לשנות: RANGE, LOCK_T, SPOT_CD, RALLY_R, BACKOFF.
# ============================================================

const SOUNDS := {
	"sp_click": [["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.6, 1.0, 0], ["S", 1800, 1700, 0.0, 0.05, 0.0, 60.0, 0.2, 1.0, 0]],
	"sp_alarm": [["Q", 880, 880, 0.0, 0.18, 0.01, 6.0, 0.18, 0.6, 0], ["Q", 660, 660, 0.2, 0.18, 0.01, 6.0, 0.18, 0.6, 0], ["Q", 880, 880, 0.4, 0.18, 0.01, 6.0, 0.18, 0.6, 0]],
	"sp_break": [["N", 0, 0, 0.0, 0.2, 0.0, 15.0, 0.6, 0.8, 0, 0.3], ["S", 2400, 900, 0.0, 0.15, 0.0, 20.0, 0.25, 1.0, 0]],
}

const RANGE := 650.0
const LOCK_T := 0.9
const SPOT_CD := 5.5
const RALLY_R := 800.0
const BACKOFF := 260.0

enum { WALK, AIM }
var state := WALK
var lamp := true
var spots := 0               # לבדיקות
var _st := 0.0
var _cd := 1.0
var _beam := 0.0             # כמה האלומה "חזקה" (לציור)


func stats() -> Dictionary:
	return {"name": "SPOTTER", "hp": 28, "walk": 40.0, "chase": 74.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.05,
		"duck": 0.0, "cover": 0.4, "skin": Color("8a9080"), "shirt": Color("c05a2a"), "pants": Color("2a2c36"), "shoe": Color("1e1e24"), "points": 460}


func can_bite() -> bool:
	return state == WALK


func lamp_pos() -> Vector2:
	return z.global_position + Vector2(z._dir * 14.0 * z.wf, -38.0) * z.sc


func on_damage(_amount: int, hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if lamp and hit_pos.distance_to(lamp_pos()) < 10.0 * z.sc:   # הפנס נשבר
		lamp = false
		state = WALK
		Sfx.play("sp_break", hit_pos, 0.0, 0.1, 2)
		Particles.burst(z.get_parent(), hit_pos, "spark", Vector2.UP, 10)
		z._popup("LAMP BROKEN", Color("e0e8ff"), 13, -80.0)
	return true


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	_beam = move_toward(_beam, 1.0 if state == AIM else 0.0, delta * 3.0)
	if z.dead or not lamp:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var d := Vector2.ZERO
	if has_pl:
		d = pl.global_position - z.global_position
	match state:
		WALK:
			if has_pl and _cd <= 0.0 and absf(d.x) < RANGE and absf(d.y) < 140.0:
				state = AIM
				_st = LOCK_T
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				Sfx.play("sp_click", z.global_position, -2.0, 0.1, 2)
				return _stay(delta)
			if has_pl and absf(d.x) < BACKOFF and absf(d.y) < 90.0:   # שומר מרחק
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
				z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.5, 600.0 * delta)
				if not z.is_on_floor():
					z.velocity.y += z.gravity * delta
				elif z.is_on_wall():
					z.velocity.y = -380.0
				z.move_and_slide()
				return true
			return false
		AIM:
			if has_pl:
				z._dir = signf(d.x) if absf(d.x) > 4.0 else z._dir
			if _st <= 0.0:
				state = WALK
				_cd = SPOT_CD
				if has_pl and absf(d.x) < RANGE * 1.1:
					_spot(pl)
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 800.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _spot(pl: Node) -> void:
	spots += 1
	Sfx.play("sp_alarm", z.global_position, 2.0, 0.0, 1)
	z._popup("SPOTTED!", Color("fff0a0"), 16, -90.0)
	pl._say("THEY SEE ME!", Color("fff0a0"))
	for o in z.get_tree().get_nodes_in_group("zombies"):
		if o != z and not o.dead and not o.is_boss() and o.global_position.distance_to(pl.global_position) < RALLY_R:
			o._alert_t = maxf(float(o._alert_t), 7.0)
			o._rush_t = 2.5
			if o.dormant:
				o._wake()


# ============================================================
#  ציור: מעיל פוך כתום, פנס ראש אדום, פנס חיפוש ביד + אלומה אליך
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(4.0, 2.0)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 2.0, 15.0), Art.shade(sk, 0.25), Art.shade(coat, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-9, -1), sh + Vector2(9, 0), hip + Vector2(8, 3), hip + Vector2(-8, 3)]), coat, 0.15, 0.4)
	for q in 3:   # תפרי פוך
		DrawBatch.line(z, sh + Vector2(-8, 4.0 + float(q) * 5.0), sh + Vector2(8, 4.0 + float(q) * 5.0), col(Art.shade(z.shirt, 0.3)), 1.0)
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	face(head, Vector2(3.0, -0.5))
	DrawBatch.rect(z, Rect2(head + Vector2(-5.5, -6), Vector2(11, 3.5)), col(Color("2a2a34")))   # כובע צמר
	DrawBatch.line(z, head + Vector2(-5, -2), head + Vector2(5, -2.5), col(Color("1a1a1a")), 1.0)   # רצועת פנס ראש
	if not z.dead:
		DrawBatch.circle(z, head + Vector2(5, -2.5), 1.6, Color(1.0, 0.2, 0.15))
		DrawBatch.circle(z, head + Vector2(3.0, 0.5), 1.0, Color(0.85, 0.9, 0.5))
	var hf := sh + Vector2(13, -1)
	z._arm(sh + Vector2(3, 1), hf, sk, coat)
	if lamp:   # פנס חיפוש
		DrawBatch.rect(z, Rect2(hf + Vector2(-3, -5), Vector2(9, 9)), col(Color("3a3e48")))
		DrawBatch.colored_polygon(z, PackedVector2Array([hf + Vector2(6, -6), hf + Vector2(9, -7), hf + Vector2(9, 6), hf + Vector2(6, 5)]), Color(1.0, 0.98, 0.85) if _beam > 0.1 else col(Color("8a8e98")))
	else:
		DrawBatch.rect(z, Rect2(hf + Vector2(-3, -4), Vector2(8, 7)), col(Color("2a2a30")))
	end_draw()
	if _beam > 0.05 and lamp and not z.dead:   # האלומה (עולם)
		var pl := player()
		if pl != null:
			var a: Vector2 = lamp_pos() - z.global_position
			var b: Vector2 = pl.global_position + Vector2(0, -26) - z.global_position
			var nrm := (b - a).normalized().orthogonal()
			var k := _beam * (1.0 if state == AIM else 0.6)
			DrawBatch.colored_polygon(z, PackedVector2Array([a + nrm * 3.0, b + nrm * 34.0, b - nrm * 34.0, a - nrm * 3.0]), Color(1.0, 0.97, 0.8, 0.12 * k))
			DrawBatch.colored_polygon(z, Art.ellipse(b, 30.0, 34.0, 0.0, 14), Color(1.0, 0.97, 0.8, 0.14 * k))
	return true
