extends "res://enemies/zombie_type.gd"
# ============================================================
#  SIGNALER (שלב 25, "RADIO TOWER") - זומבי קשר: תרמיל רדיו עם אנטנה ארוכה, אוזניות.
#    WALK     - שומר מרחק (keep_range), בורח אם אתה קרוב.
#    TRANSMIT - כשהוא רואה אותך מרחוק: כורע ומשדר (TRANSMIT_T) - האנטנה מהבהבת וגלי רדיו יוצאים = אזהרה.
#               הצליח -> CALL_N זומבים רצים אליך משני הצדדים + כל הזומבים באזור שומעים (Game.make_noise).
#               ירית בו בזמן השידור -> "SIGNAL LOST" והשידור נקטע.
#  מקסימום MAX_CALLS שידורים לכל זומבי. CD בין שידורים.
#  לשנות: RANGE, TRANSMIT_T, CALL_N, MAX_CALLS, LEVEL_CAP, CD.
# ============================================================

const SOUNDS := {
	"sg_radio": [["Q", 1200, 1200, 0.0, 0.08, 0.0, 0.0, 0.12, 0.5, 0], ["N", 0, 0, 0.0, 0.5, 0.02, 2.0, 0.35, 0.5, 0, 0.4], ["Q", 900, 900, 0.3, 0.08, 0.0, 0.0, 0.12, 0.5, 0]],
	"sg_lost": [["S", 900, 200, 0.0, 0.3, 0.0, 8.0, 0.3, 1.0, 0], ["N", 0, 0, 0.0, 0.3, 0.0, 8.0, 0.4, 0.4, 0, 0.3]],
}

const RANGE := Vector2(160.0, 680.0)   # (BACKOFF גדול מ-RANGE.x - נסוג ואז משדר)
const TRANSMIT_T := 2.0
const CALL_N := 3
const MAX_CALLS := 2
const LEVEL_CAP := 15        # כמה זומבי תגבורת לכל היותר בכל השלב
const CD := 8.0
const BACKOFF := 200.0      # קרוב מזה - נסוג (צריך מרחק כדי לשדר)

enum { WALK, TRANSMIT }
var state := WALK
var calls := 0               # לבדיקות
var interrupted := 0
var _st := 0.0
var _cd := 2.0
var _beep := 0.0


func stats() -> Dictionary:
	return {"name": "SIGNALER", "hp": 30, "walk": 48.0, "chase": 96.0, "damage": 1, "bite_delay": 0.8, "scale": 1.0, "width": 0.95,
		"duck": 0.2, "cover": 0.5, "skin": Color("8a9a8a"), "shirt": Color("4a5238"), "pants": Color("3a3e2e"), "shoe": Color("1e1a14"), "points": 450}


func brain_overrides() -> Dictionary:
	return {"aggression": 0.2, "keep_range": 420.0}


func can_bite() -> bool:
	return state == WALK


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state == TRANSMIT:
		state = WALK
		interrupted += 1
		_cd = CD * 0.6
		z._popup("SIGNAL LOST", Color("80d0ff"), 14, -80.0)
		Sfx.play("sg_lost", z.global_position, 2.0, 0.05, 2)
	return true


func physics(pl: Node, delta: float) -> bool:
	_cd -= delta
	_st -= delta
	if z.dead:
		return false
	var has_pl: bool = pl != null and not pl.dead
	match state:
		WALK:
			if has_pl and _cd <= 0.0 and calls < MAX_CALLS and z.is_on_floor():
				var d: Vector2 = pl.global_position - z.global_position
				if absf(d.x) > RANGE.x and absf(d.x) < RANGE.y and absf(d.y) < 260.0:
					state = TRANSMIT
					_st = TRANSMIT_T
					_beep = 0.0
					z._dir = signf(d.x)
					return _stay(delta)
			if has_pl and z.is_on_floor():   # קרוב מדי: נסוג אחורה (ופונה אליך)
				var dd: Vector2 = pl.global_position - z.global_position
				if absf(dd.x) < BACKOFF and absf(dd.y) < 60.0 and not z.is_on_wall():
					z._dir = signf(dd.x) if dd.x != 0.0 else z._dir
					z.velocity.x = move_toward(z.velocity.x, -z._dir * float(z.walk_speed) * 1.7, 700.0 * delta)
					z.velocity.y += z.gravity * delta
					z.move_and_slide()
					return true
			return false
		TRANSMIT:
			_beep -= delta
			if _beep <= 0.0:
				_beep = 0.5
				Sfx.play("sg_radio", z.global_position, 0.0, 0.05, 2)
			if has_pl:
				z._dir = signf(pl.global_position.x - z.global_position.x) if pl.global_position.x != z.global_position.x else z._dir
			if _st <= 0.0:
				_call(pl)
				state = WALK
				_cd = CD
			return _stay(delta)
	return false


func _stay(delta: float) -> bool:
	z.velocity.x = move_toward(z.velocity.x, 0.0, 900.0 * delta)
	if not z.is_on_floor():
		z.velocity.y += z.gravity * delta
	z.move_and_slide()
	return true


func _call(pl: Node) -> void:
	calls += 1
	z._popup("BACKUP INCOMING!", Color("ff8060"), 14, -80.0)
	Game.make_noise(z.global_position, 1100.0)
	var main: Node = z.get_parent()
	if main == null or not main.has_method("_spawn_zombie") or pl == null:
		return
	var total: int = int(main.get_meta("signal_backup", 0))   # תקרה לכל השלב (שלא יהיו אינסוף)
	if total >= LEVEL_CAP:
		return
	main.set_meta("signal_backup", total + CALL_N)
	var px: float = pl.global_position.x
	var fy: float = float(main._stage.floor_y) if main.get("_stage") != null else z.global_position.y
	for i in CALL_N:
		var side := 1.0 if i % 2 == 0 else -1.0
		var x := clampf(px + side * randf_range(720.0, 860.0), 300.0, float(z.world_w) - 200.0)
		var zz: Node = main._spawn_zombie(x, fy, 1 if i == 0 else 0)
		if zz != null:
			zz.dormant = false
			zz.hear_noise(pl.global_position, 100000.0)


# ============================================================
#  ציור: מדים, אוזניות, תרמיל רדיו על הגב עם אנטנה גמישה. משדר = כורע, יד לאוזן, גלים.
# ============================================================
func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var shirt := col(z.shirt)
	var p: float = z._walk_phase
	var f: Array = feet(5.0, 2.5)
	var kneel: bool = state == TRANSMIT and not z.dead
	var hip := Vector2(0, -16) if kneel else Vector2(0, -22)
	var sh := hip + Vector2(1, -15)
	var head := sh + Vector2(3.5, -8)
	if kneel:
		z._leg(hip + Vector2(-2, 0), Vector2(-9, 0), col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
		z._leg(hip + Vector2(2, 0), Vector2(7, 0), col(z.pants), sk, col(z.shoe))
	else:
		z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.25)), sk, col(z.shoe))
		z._leg(hip + Vector2(2, 0), f[0], col(z.pants), sk, col(z.shoe))
	# תרמיל רדיו + אנטנה
	var pack := sh + Vector2(-11, -1)
	Art.fill_shaded(z, PackedVector2Array([pack, pack + Vector2(7, 0), pack + Vector2(7, 16), pack + Vector2(0, 16)]), col(Color("3a4230")), 0.15, 0.4)
	z.draw_rect(Rect2(pack + Vector2(1.5, 3), Vector2(4, 3)), col(Color("1a1e16")))
	z.draw_circle(pack + Vector2(3.5, 10), 1.3, Color(0.3, 1.0, 0.4) if state == WALK else Color(1.0, 0.3, 0.2))
	var sway: float = sin(z._time * 5.0) * 3.0 + z.velocity.x * -0.02
	var ant := PackedVector2Array([pack + Vector2(2, 0), pack + Vector2(1.0 + sway * 0.3, -12), pack + Vector2(sway * 0.7, -24), pack + Vector2(sway, -34)])
	z.draw_polyline(ant, col(Color("2a2a2c")), 1.4)
	var tip: Vector2 = ant[3]
	if kneel:
		var blink := fmod(z._time * 6.0, 1.0) < 0.5
		z.draw_circle(tip, 2.2, Color(1.0, 0.3, 0.2) if blink else Color(0.5, 0.1, 0.1))
		for q in 3:   # גלי רדיו
			var k := fmod(z._time * 1.5 + float(q) / 3.0, 1.0)
			z.draw_arc(tip, 4.0 + k * 22.0, -2.4, -0.7, 10, Color(0.5, 0.85, 1.0, 0.7 * (1.0 - k)), 1.4)
		var prog := clampf(1.0 - _st / TRANSMIT_T, 0.0, 1.0)   # בר התקדמות קטן מעל הראש
		z.draw_rect(Rect2(head + Vector2(-8, -16), Vector2(16, 3)), Color(0, 0, 0, 0.6))
		z.draw_rect(Rect2(head + Vector2(-8, -16), Vector2(16.0 * prog, 3)), Color(1.0, 0.4, 0.3))
	else:
		z.draw_circle(tip, 1.4, col(Color("4a4a4c")))
	z._arm(sh + Vector2(-3, 1), sh + Vector2(-5.0 - sin(p) * 3.0, 14.0), Art.shade(sk, 0.25), Art.shade(shirt, 0.3))
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(5, 2), hip + Vector2(-5, 2)]), shirt, 0.12, 0.4)
	z.draw_line(sh + Vector2(-5, 0), hip + Vector2(3, 0), col(Color("2a2e20")), 1.6)   # רצועה
	Art.oval_shaded(z, head, 5.4, 5.8, sk, 0.0)
	z.draw_arc(head + Vector2(0, -1), 6.2, PI * 1.05, TAU * 0.98, 10, col(Color("1e1e20")), 1.8)   # אוזניות
	z.draw_circle(head + Vector2(-4.5, 0), 2.4, col(Color("2a2a2c")))
	z.draw_line(head + Vector2(-3, 2), head + Vector2(4, 4), col(Color("2a2a2c")), 1.0)   # מיקרופון
	if not z.dead:
		z.draw_circle(head + Vector2(3.5, -1.0), 0.9, Color(1.0, 0.5, 0.2))
	if kneel:   # יד לאוזן
		z._arm(sh + Vector2(3, 1), head + Vector2(-2, 2), sk, shirt)
	else:
		z._arm(sh + Vector2(3, 1), sh + Vector2(9.0 + sin(p) * 3.0, 13.0), sk, shirt)
	end_draw()
	return true
