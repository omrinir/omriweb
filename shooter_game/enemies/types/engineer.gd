extends "res://enemies/zombie_type.gd"
# ============================================================
#  ENGINEER (שלב 7) - זומבי תמיכה נדיר. לא תוקף - מפעיל את המפעל נגדך.
#  צללית: נמוך ורחב, אפוד זוהר כתום עם פסים מחזירי אור, מסכת ריתוך מורמת על הראש
#         עם פנס ראש, חגורת כלים, מפתח ברגים ענק ביד, סליל כבל + אנטנה עם נורה ירוקה על הגב.
#  צבעים: כתום-זוהר + כסוף, סרבל כחול כהה, נורת אנטנה ירוקה.
#  התנהגות ("הזומבים מתחילים לתמרן את הסביבה"):
#    1. שומר מרחק. כשהוא רואה / יודע איפה השחקן, ויש מכונה מחוברת ללוח בקרה ליד השחקן:
#    2. "!" + צליל קשר -> רץ אל לוח הבקרה (environment/s7_console.gd).
#    3. מושך בידית (אזעקה + נורה אדומה מסתובבת), ואז פולס אור רץ בכבל אל המכונה:
#       מכבש נוחת, קיטור מתפרץ, חשמל בשלולית, דלת נסגרת, או תריס נפתח לזומבים.
#    אם אין לוח בקרה: מרים שלט רחוק (צפצוף) ומפעיל hazard "triggerable" ליד השחקן.
#    נפגע -> בורח. נלכד -> מכה עם המפתח.
#  צלילים: "eng_radio" (רחש קשר + צפצוף), "eng_lever" (נקישת ידית מתכת).
# ============================================================

const SOUNDS := {
	"eng_radio": {"drive": 1.8, "layers": [["N", 0, 0, 0.0, 0.18, 0.0, 9.0, 0.5, 0.7, 0, 0.3], ["Q", 1250, 1250, 0.2, 0.08, 0.0, 20.0, 0.18, 0.6, 0], ["Q", 1650, 1650, 0.3, 0.1, 0.0, 18.0, 0.18, 0.6, 0], ["V", 140, 110, 0.0, 0.4, 0.02, 5.0, 0.4, 1.0, 0.04, 0, [500, 1500, 18]]]},
	"eng_lever": [["N", 0, 0, 0.0, 0.03, 0.0, 120.0, 0.8, 1.0, 0], ["S", 900, 600, 0.0, 0.08, 0.0, 40.0, 0.35, 1.0, 0], ["C", 0, 0, 0.03, 0.18, 0.0, 12.0, 0.6, 1.0, 0], ["S", 180, 80, 0.2, 0.12, 0.0, 30.0, 0.7, 1.0, 0]],
}

enum { KEEP, RUN, OPERATE, REMOTE, FLEE }
var state := KEEP
var triggers := 0          # לבדיקות: כמה פעמים הפעיל מכונה
var _st := 0.0
var _cd := 1.0
var _console: Node = null
var _remote_targets := []
var _blink := 0.0


func stats() -> Dictionary:
	return {"name": "ENGINEER", "hp": 24, "walk": 50.0, "chase": 135.0, "damage": 1, "bite_delay": 1.0, "scale": 0.9, "width": 1.15,
		"duck": 0.3, "cover": 0.3, "skin": Color("8c9a7a"), "shirt": Color("e06a10"), "pants": Color("1e2a40"), "shoe": Color("1a1612"), "points": 320}


func brain_overrides() -> Dictionary:
	return {"keep_range": 320.0, "aggression": -0.5, "hazard_awareness": 0.3}


func use_brain_movement() -> bool:
	return false


func setup() -> void:
	z.cover_chance = 0.0


func _enter(s: int) -> void:
	state = s
	_st = 0.0


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_st += delta
	_cd -= delta
	_blink += delta
	var dist := absf(d.x)
	var knows: bool = z.brain != null and (z.brain.sees or z.brain.tracking())
	match state:
		KEEP:
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if _cd <= 0.0 and knows:
				_cd = 1.0
				var c := _pick_console(pl)
				if c != null:
					_console = c
					_enter(RUN)
					z._popup("!", Color(1.0, 0.6, 0.15), 22, -74.0)
					Sfx.play("eng_radio", z.global_position, 0.0, 0.05, 2)
					return speed
				_remote_targets = _remote_hazards(pl)
				if not _remote_targets.is_empty():
					_enter(REMOTE)
					Sfx.play("beep", z.global_position, -2.0, 0.05, 2)
					return 0.0
			# שומר מרחק כמו טכנאי זהיר
			if dist < 70.0:
				return speed * 0.5   # נלכד: מכה עם המפתח
			if dist < 240.0:
				z._dir = -signf(d.x)
				return speed * 0.85
			if dist > 420.0:
				return speed * 0.6
			return 0.0
		RUN:
			if not is_instance_valid(_console) or _st > 7.0:
				_enter(KEEP)
				_cd = 1.5
				return 0.0
			var cx: float = _console.global_position.x - z.global_position.x
			if absf(cx) < 12.0:
				_enter(OPERATE)
				_console.begin_use()
				z.velocity.x = 0.0
				return 0.0
			z._dir = signf(cx)
			return speed * 1.25
		OPERATE:   # מושך בידית
			if _st >= 0.85:
				if is_instance_valid(_console):
					var n: int = _console.activate(pl.global_position.x)
					if n > 0:
						triggers += 1
				_enter(KEEP)
				_cd = randf_range(6.0, 8.0)
			z._dir = signf(_console.global_position.x - z.global_position.x + 0.01) if is_instance_valid(_console) else z._dir
			return 0.0
		REMOTE:   # שלט רחוק: מצפצף ואז מפעיל
			z._dir = signf(d.x) if d.x != 0.0 else z._dir
			if _st >= 0.8:
				for h in _remote_targets:
					if is_instance_valid(h):
						h.trigger()
				triggers += 1
				_remote_targets = []
				_enter(KEEP)
				_cd = randf_range(7.0, 9.0)
			return 0.0
		FLEE:
			z._dir = -signf(d.x) if d.x != 0.0 else z._dir
			if _st >= 2.0:
				_enter(KEEP)
			return speed * 1.2
	return speed


# לוח בקרה פנוי, באותו גובה, עם מכונה מחוברת שקרובה לשחקן
func _pick_console(pl: Node) -> Node:
	var best: Node = null
	var bd := INF
	var px: float = pl.global_position.x
	for c in z.get_tree().get_nodes_in_group("s7_consoles"):
		if not c.ready_to_use():
			continue
		var dx: float = absf(c.global_position.x - z.global_position.x)
		var dy: float = absf(c.global_position.y - z.global_position.y)
		if dx > 650.0 or dy > 40.0:
			continue
		# לא רץ דרך השחקן כדי להגיע ללוח
		var cx: float = c.global_position.x
		if (cx - px) * (z.global_position.x - px) < 0.0 and absf(cx - px) > 60.0:
			continue
		if absf(cx - px) < 90.0:
			continue
		if c.machines_near(px, 260.0).is_empty():
			continue
		if dx < bd:
			bd = dx
			best = c
	return best


# בלי לוח בקרה: מלכודות triggerable ליד השחקן
func _remote_hazards(pl: Node) -> Array:
	var out := []
	var pp: Vector2 = pl.global_position
	for h in z.get_tree().get_nodes_in_group("hazards"):
		if not h.triggerable or h.is_in_group("s7_gates"):
			continue
		var hc: Vector2 = h.world_rect().get_center()
		if absf(hc.x - pp.x) < 170.0 and absf(hc.y - pp.y) < 200.0 and absf(hc.x - z.global_position.x) < 520.0:
			out.append(h)
	return out


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	if state != OPERATE:
		_enter(FLEE)
		_console = null
	return true


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var vest := col(z.shirt)
	var suit := col(z.pants)
	var p: float = z._walk_phase
	var t: float = z._time
	var f: Array = feet(4.5, 2.5)
	var hip := Vector2(-1.0, -18.0 + absf(sin(p)) * 1.0)
	var sh := Vector2(2.0, -32.0)
	var head := sh + Vector2(3.0, -7.0)
	var operating: bool = state == OPERATE and not z.dead
	var remote: bool = state == REMOTE and not z.dead
	# סליל כבל + אנטנה על הגב
	var pack := sh + Vector2(-9.0, 5.0)
	Art.fill_shaded(z, PackedVector2Array([pack + Vector2(-5, -7), pack + Vector2(4, -7), pack + Vector2(4, 9), pack + Vector2(-5, 9)]), col(Color("3a3e44")), 0.2, 0.4)
	z.draw_circle(pack + Vector2(-0.5, 1.0), 4.0, col(Color("6a3a1a")))
	z.draw_circle(pack + Vector2(-0.5, 1.0), 1.5, col(Color("2a1a0a")))
	var ant := pack + Vector2(-3.0, -22.0 + sin(t * 3.0) * 0.8)
	z.draw_line(pack + Vector2(-3, -7), ant, col(Color("2a2a2a")), 1.0)
	var led_on := fmod(_blink * (5.0 if state != KEEP else 1.2), 1.0) < 0.5
	z.draw_circle(ant, 1.4, Color(0.3, 1.0, 0.4) if led_on else Color(0.1, 0.3, 0.12))
	if led_on:
		Art.glow(z, ant, 5.0, Color(0.3, 1.0, 0.4, 0.6))
	# רגליים קצרות וחזקות
	z._leg(hip + Vector2(-2, 0), f[1], col(Art.shade(z.pants, 0.2)), col(Art.shade(z.skin, 0.25)), col(z.shoe))
	z._leg(hip + Vector2(2, 0), f[0], suit, sk, col(z.shoe))
	# יד אחורית
	var bh := sh + Vector2(6.0, 12.0 + sin(p) * 2.0)
	if operating:
		bh = sh + Vector2(10.0, lerpf(-12.0, 4.0, clampf(_st / 0.85, 0.0, 1.0)))
	Art.limb(z, PackedVector2Array([sh + Vector2(-2, 1), sh.lerp(bh, 0.5) + Vector2(-1, 3), bh]), 4.2, col(Art.shade(z.pants, 0.15)))
	Art.disc(z, bh, 2.4, col(Art.shade(z.skin, 0.2)))
	# גוף רחב: סרבל + אפוד זוהר
	Art.fill_shaded(z, PackedVector2Array([hip + Vector2(-7, 3), hip + Vector2(7, 3), sh + Vector2(7, 1), sh + Vector2(-7, -2)]), suit, 0.15, 0.4)
	Art.fill_shaded(z, PackedVector2Array([sh + Vector2(-6, -1), sh + Vector2(6, 0), hip + Vector2(6, -2), hip + Vector2(-6, -2)]), vest, 0.2, 0.35)
	for yy in [0.35, 0.65]:   # פסים מחזירי אור
		var a: Vector2 = sh.lerp(hip, yy)
		z.draw_line(a + Vector2(-6, 0), a + Vector2(6, 0), col(Color(0.9, 0.92, 0.95)), 1.6)
	# חגורת כלים
	z.draw_line(hip + Vector2(-7, -1), hip + Vector2(7, -1), col(Color("3a2a1a")), 2.4)
	z.draw_rect(Rect2(hip + Vector2(-4, -1), Vector2(3, 4)), col(Color("4a3a24")))
	z.draw_line(hip + Vector2(3, 0), hip + Vector2(4, 6), col(Color("9a9ea0")), 1.2)   # מברג
	# ראש + מסכת ריתוך מורמת + פנס
	Art.oval_shaded(z, head, 6.0, 6.2, sk, 0.0)
	Art.fill(z, PackedVector2Array([head + Vector2(1, 2.5), head + Vector2(6, 2.0), head + Vector2(5.5, 4.5), head + Vector2(1.5, 4.5)]), Color("2a0a0c"), Art.OUTLINE, 0.8)
	z.draw_circle(head + Vector2(3.5, -1.2), 1.1, Color(1.0, 0.85, 0.3))
	var mask := PackedVector2Array([head + Vector2(-6, -3), head + Vector2(-4, -9), head + Vector2(4, -10), head + Vector2(8, -6), head + Vector2(7, -4), head + Vector2(0, -5)])
	Art.fill_shaded(z, mask, col(Color("2c3034")), 0.2, 0.4)
	z.draw_line(head + Vector2(1, -8), head + Vector2(6, -7), Color(0.3, 0.5, 0.55, 0.6), 1.4)   # זכוכית המסכה
	var lamp := head + Vector2(7.5, -5.5)
	z.draw_circle(lamp, 1.5, Color(1.0, 0.95, 0.7))
	Art.glow(z, lamp, 4.0, Color(1.0, 0.9, 0.5, 0.5))
	# יד קדמית: מפתח ברגים / שלט רחוק / מושכת ידית
	var fh := sh + Vector2(10.0, 9.0 - sin(p) * 2.0)
	if operating:
		fh = sh + Vector2(12.0, lerpf(-14.0, 2.0, clampf(_st / 0.85, 0.0, 1.0)))
	elif remote:
		fh = sh + Vector2(12.0, -10.0)
	Art.limb(z, PackedVector2Array([sh + Vector2(3, 1), sh.lerp(fh, 0.5) + Vector2(1, 3), fh]), 4.4, vest)
	Art.disc(z, fh, 2.4, sk)
	if remote:   # שלט עם נורה מהבהבת
		z.draw_rect(Rect2(fh + Vector2(-1.5, -7), Vector2(4, 7)), Color("1a1a1a"))
		var bl := fmod(_st * 8.0, 1.0) < 0.5
		z.draw_circle(fh + Vector2(0.5, -8.0), 1.3, Color(1.0, 0.2, 0.1) if bl else Color(0.4, 0.05, 0.05))
		if bl:
			Art.glow(z, fh + Vector2(0.5, -8.0), 6.0, Color(1.0, 0.2, 0.1, 0.6))
	elif not operating:   # מפתח ברגים ענק
		var w0 := fh + Vector2(1, 1)
		var w1 := fh + Vector2(6, 12)
		z.draw_line(w0, w1, col(Color("a8acb0")), 2.4)
		z.draw_arc(w1 + Vector2(1, 2), 3.0, -0.6, PI + 0.6, 8, col(Color("a8acb0")), 2.0)
	end_draw()
	return true
