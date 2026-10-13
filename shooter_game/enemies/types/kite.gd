extends "res://enemies/zombie_type.gd"
# ============================================================
#  KITE (שלב 37, "FAVELA HEIGHTS") - "פיפֵּירו" זומבי: גופייה, כובע מצחייה, פחית-סליל ביד ועפיפון (פיפה) באוויר
#  על חוט "סרול" (מצופה זכוכית) - חוט שחותך.
#  "THEY LEARNED TO PLAY": שומר מרחק (KEEP) ומחזיק את העפיפון מעליך. כל DIVE_CD: העפיפון רועד ושורק (WARN_T) ואז צולל -
#    החוט עובר דרכך כמו להב (1 נזק). אחרי כל פספוס הוא מכוון לאן שאתה הולך (lead).
#    ירייה בעפיפון (מטרה קטנה באוויר) חותכת את החוט -> העפיפון עף, והוא זומבי רגיל וכועס.
#  לשנות: KEEP, DIVE_CD, WARN_T, DIVE_T, LINE_DMG.
# ============================================================

const SOUNDS := {
	"kt_whistle": [["S", 1600, 2400, 0.0, 0.5, 0.05, 3.0, 0.15, 1.0, 0.04]],
	"kt_swish": [["N", 0, 0, 0.0, 0.3, 0.0, 6.0, 0.4, 0.6, 0, 0.8], ["S", 900, 400, 0.0, 0.25, 0.0, 8.0, 0.15, 1.0, 0]],
	"kt_cut": [["C", 0, 0, 0.0, 0.05, 0.0, 60.0, 0.5, 1.0, 0], ["S", 2400, 1800, 0.0, 0.1, 0.0, 30.0, 0.2, 1.0, 0]],
}

const KEEP := Vector2(220.0, 420.0)
const DIVE_CD := 3.2
const WARN_T := 0.6
const DIVE_T := 0.55
const LINE_DMG := 1
const COLS := [Color("e04040"), Color("40a0e0"), Color("e0c030"), Color("50c060"), Color("c060c0")]

enum { FLY, WARN, DIVE, CUT }
var state := FLY
var dives := 0               # לבדיקות
var line_hits := 0
var lead := 0.0
var kite_pos := Vector2.ZERO  # (עולם)
var _st := 0.0
var _cd := 2.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _hit := false
var _col := Color.RED
var _body: StaticBody2D = null
var _fall := Vector2.ZERO


func stats() -> Dictionary:
	return {"name": "KITE", "hp": 26, "walk": 40.0, "chase": 78.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 1.0,
		"duck": 0.2, "cover": 0.2, "skin": Color("7a8a70"), "shirt": Color("e0e0d0"), "pants": Color("2a4a8a"), "shoe": Color("e0e0e0"), "points": 460}


func setup() -> void:
	_col = COLS[randi() % COLS.size()]
	kite_pos = z.global_position + Vector2(60, -260)
	_body = KiteBody.new()
	_body.owner_k = self
	_body.collision_layer = 4
	_body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 11.0
	cs.shape = sh
	_body.add_child(cs)
	z.get_parent().add_child.call_deferred(_body)


func brain_overrides() -> Dictionary:
	return {"aggression": 0.15}


func hand() -> Vector2:
	return z.global_position + Vector2(z._dir * 10.0, -36.0) * z.sc


func cut_line() -> void:   # ירו בעפיפון
	if state == CUT or z == null or z.dead:
		return
	state = CUT
	_fall = Vector2(randf_range(-60, 60), -40)
	Sfx.play("kt_cut", kite_pos, 0.0, 0.1, 2)
	Particles.burst(z.get_parent(), kite_pos, "leaf", Vector2.UP, 6)
	z._popup("LINE CUT", Color("ffe080"), 13, -80.0)
	z._alert_t = 8.0
	z._rush_t = 2.0
	if _body != null and is_instance_valid(_body):
		_body.queue_free()


func on_death() -> void:
	if _body != null and is_instance_valid(_body):
		_body.queue_free()


func physics(pl: Node, delta: float) -> bool:
	_st -= delta
	_cd -= delta
	if state == CUT:   # העפיפון עף לו
		_fall.y += 60.0 * delta
		kite_pos += (_fall + Vector2(40, 0)) * delta
		return false
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	var hover: Vector2 = z.global_position + Vector2(z._dir * 120.0, -280.0)
	if has_pl:
		hover = pl.global_position + Vector2(-z._dir * 30.0 + sin(z._time * 0.9) * 40.0, -250.0)
	match state:
		FLY:
			kite_pos = kite_pos.lerp(hover, 1.0 - exp(-2.0 * delta))
			if has_pl and _cd <= 0.0 and absf(pl.global_position.x - z.global_position.x) < 520.0 and absf(pl.global_position.y - z.global_position.y) < 200.0:
				state = WARN
				_st = WARN_T
				Sfx.play("kt_whistle", kite_pos, -2.0, 0.1, 2)
		WARN:
			kite_pos = hover + Vector2(sin(z._time * 40.0) * 5.0, -20.0)
			if _st <= 0.0 and has_pl:
				state = DIVE
				_st = DIVE_T
				dives += 1
				_hit = false
				# הצלילה: מלמעלה-מאחוריך אל הקרקע לפניך, כך שהחוט חותך את המקום שבו תהיה
				var px: float = pl.global_position.x + pl.velocity.x * 0.45 * lead
				var side := signf(px - z.global_position.x)
				_from = kite_pos
				_to = Vector2(px + side * 170.0, pl.global_position.y - 10.0)
				Sfx.play("kt_swish", kite_pos, 0.0, 0.1, 2)
		DIVE:
			var k := 1.0 - clampf(_st / DIVE_T, 0.0, 1.0)
			kite_pos = _from.lerp(_to, k * k)
			if has_pl and not _hit and _line_hits(pl.body_rect()):
				_hit = true
				line_hits += 1
				pl.hurt(LINE_DMG, Vector2(signf(pl.global_position.x - z.global_position.x) * 0.8, -0.6))
				Particles.burst(z.get_parent(), pl.global_position + Vector2(0, -30), "hit", Vector2.UP, 4)
			if _st <= 0.0:
				if not _hit:
					lead = minf(lead + 0.34, 1.0)   # פספס - לומד להקדים
				state = FLY
				_cd = DIVE_CD
	if _body != null and is_instance_valid(_body):
		_body.global_position = kite_pos
	# שומר מרחק
	if has_pl:
		var dx: float = pl.global_position.x - z.global_position.x
		if absf(dx) < KEEP.x and absf(pl.global_position.y - z.global_position.y) < 90.0:
			z._dir = signf(dx) if absf(dx) > 4.0 else z._dir
			z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.5, 600.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			elif z.is_on_wall():
				z.velocity.y = -380.0
			z.move_and_slide()
			return true
		if absf(dx) < KEEP.y and state != FLY:
			z._dir = signf(dx)
			z.velocity.x = move_toward(z.velocity.x, 0.0, 600.0 * delta)
			if not z.is_on_floor():
				z.velocity.y += z.gravity * delta
			z.move_and_slide()
			return true
	return false


func _line_hits(r: Rect2) -> bool:
	var a := hand()
	for q in 20:
		if r.grow(2.0).has_point(a.lerp(kite_pos, float(q) / 19.0)):
			return true
	return false


class KiteBody extends StaticBody2D:   # העפיפון - מטרה לירי
	var owner_k = null

	func take_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _explosive := false, _src := {}) -> void:
		if owner_k != null:
			owner_k.cut_line()


# ============================================================
#  ציור: גופייה לבנה, מכנסיים קצרים, כפכפים, כובע מצחייה הפוך, פחית-סליל; החוט והעפיפון (בעולם)
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var p: float = z._walk_phase
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(0, -22)
	var sh := Vector2(1, -37)
	var head := sh + Vector2(3.5, -8)
	z._leg(hip + Vector2(-2, 0), f[1], sk.darkened(0.2), sk, col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], sk, sk, col(z.shoe))
	z.draw_rect(Rect2(hip + Vector2(-6, -2), Vector2(12, 9)), col(z.pants))   # מכנסיים קצרים
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 2.0, 15.0), Art.shade(sk, 0.25), Art.shade(sk, 0.25))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-7, -1), sh + Vector2(7, 0), hip + Vector2(6, -1), hip + Vector2(-6, -1)]), col(z.shirt), 0.12, 0.4)   # גופייה
	Art.oval_shaded(z, head, 5.2, 5.8, sk, 0.0)
	z.draw_colored_polygon(Art.ellipse(head + Vector2(0, -3.5), 5.6, 3.0, 0.0, 10), col(Color("e04040")))   # כובע
	z.draw_rect(Rect2(head + Vector2(-9, -4), Vector2(5, 2)), col(Color("e04040")))   # מצחייה אחורה
	if not z.dead:
		z.draw_circle(head + Vector2(3.0, -0.5), 1.1, Color(1.0, 0.85, 0.4))
	var hf := sh + Vector2(11, -3)
	z._arm(sh + Vector2(3, 1), hf, sk, sk)
	z.draw_rect(Rect2(hf + Vector2(-3, -3), Vector2(6, 7)), col(Color("b0b8c0")))   # פחית-סליל
	end_draw()
	if state != CUT and not z.dead:   # החוט והעפיפון (בעולם)
		var a: Vector2 = hand() - z.global_position
		var b: Vector2 = kite_pos - z.global_position
		var mid: Vector2 = (a + b) * 0.5 + Vector2(0, 24.0 if state == FLY else 4.0)
		var pts := PackedVector2Array()
		for q in 9:
			var u := float(q) / 8.0
			pts.append(a.lerp(mid, u).lerp(mid.lerp(b, u), u))
		z.draw_polyline(pts, Color(0.95, 0.95, 1.0, 0.55 if state != DIVE else 0.9), 1.0 if state != DIVE else 1.6)
		if state == WARN:
			z.draw_polyline(pts, Color(1.0, 0.3, 0.2, 0.4 + 0.4 * sin(z._time * 30.0)), 2.0)
	if state != CUT or kite_pos.y < z.global_position.y + 200.0:
		var kp: Vector2 = kite_pos - z.global_position
		var ang := (kite_pos - hand()).angle() + PI * 0.5 if state == DIVE else sin(z._time * 2.0) * 0.3
		var pts2 := PackedVector2Array()
		for q in [Vector2(0, -12), Vector2(9, 0), Vector2(0, 14), Vector2(-9, 0)]:
			pts2.append(kp + q.rotated(ang))
		z.draw_colored_polygon(pts2, _col)
		z.draw_colored_polygon(PackedVector2Array([pts2[0], pts2[1], kp]), _col.lightened(0.3))
		z.draw_line(pts2[0], pts2[2], _col.darkened(0.4), 1.0)
		var tail := PackedVector2Array()
		for q in 6:
			tail.append(pts2[2] + Vector2(sin(z._time * 5.0 + float(q)) * 4.0, float(q) * 6.0).rotated(ang))
		z.draw_polyline(tail, _col.lightened(0.4), 1.2)
	return true
