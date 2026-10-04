extends "res://enemies/zombie_type.gd"
# ============================================================
#  TACTICIAN (שלב 7) - הזומבי הכי חכם במפעל. לא נלחם - מתכנן.
#  צללית: גבוה, זקוף לגמרי (לא כפוף כמו זומבי!), מעיל מנהל עבודה ארוך שמתנופף,
#         קסדת מגן סדוקה עם עדשת פליז על העין, יד אחת מאחורי הגב, השנייה מצביעה.
#  צבעים: מעיל אפור-זית כהה, קסדה צהבהבה מלוכלכת, עדשה + קרן סריקה בטורקיז.
#  התנהגות:
#    * שומר מרחק (~330-450) ונסוג כשמתקרבים. עומד ו"לומד" את השחקן: קרן טורקיז
#      סורקת אותו וטבעת מתמלאת סביב העדשה.
#    * השחקן יורה שוב ושוב מאותו מקום (PlayerMemory.is_camping() / camp_shots, או שהוא
#      עצמו ראה אותו עומד במקום ~3 שניות) -> מצביע + פקודה: director().order_flank()
#      ששולח 2 זומבים לעקוף את השחקן ולתקוף מאחור.
#    * השחקן טוען מחסנית (is_reloading) מול העיניים שלו -> פקודת ATTACK קצרה לסביבה.
#  התקפה: כמעט לא תוקף (מכת מקל רק כשלוכדים אותו).
#  צלילים: "tac_scan" (סריקה אלקטרונית מצייצת), "tac_order" (נביחת פקודה כפולה).
# ============================================================

const SOUNDS := {
	"tac_scan": {"drive": 1.4, "layers": [["S", 1700, 2600, 0.0, 0.35, 0.02, 4.0, 0.22, 1.0, 0.02], ["C", 0, 0, 0.0, 0.35, 0.0, 5.0, 0.4, 1.0, 0], ["S", 2600, 1900, 0.35, 0.25, 0.0, 7.0, 0.15, 1.0, 0]]},
	"tac_order": {"drive": 2.6, "layers": [["V", 150, 120, 0.0, 0.28, 0.01, 7.0, 0.9, 1.0, 0.03, 0, [600, 1050, 30]], ["V", 190, 150, 0.32, 0.36, 0.01, 6.0, 0.95, 1.0, 0.03, 0, [650, 1150, 30]], ["S", 2200, 2200, 0.0, 0.08, 0.0, 30.0, 0.12, 1.0, 0]]},
}

var flank_orders := 0      # לבדיקות: כמה פעמים שלח איגוף
var attack_orders := 0
var _obs := 0.0            # כמה זמן ראה את השחקן עומד באותו מקום
var _obs_spot := Vector2.ZERO
var _flank_cd := 1.5
var _cmd_cd := 4.0
var _scan_cd := 1.0
var _point_t := 0.0
var _scan_a := 0.0
var _seeing := false


func stats() -> Dictionary:
	return {"name": "TACTICIAN", "hp": 26, "walk": 45.0, "chase": 115.0, "damage": 1, "bite_delay": 1.1, "scale": 1.08, "width": 0.8,
		"duck": 0.4, "cover": 0.5, "skin": Color("8a9488"), "shirt": Color("3e4236"), "pants": Color("26282a"), "shoe": Color("18161a"), "points": 340}


func brain_overrides() -> Dictionary:
	return {"keep_range": 380.0, "aggression": -0.4, "communication": 1, "awareness": 0.2}


func use_brain_movement() -> bool:
	return false


func setup() -> void:
	z.cover_chance = 0.0


func logic(pl: Node, d: Vector2, delta: float, speed: float) -> float:
	_flank_cd -= delta
	_cmd_cd -= delta
	_scan_cd -= delta
	_point_t -= delta
	var dist := absf(d.x)
	_seeing = z.brain != null and z.brain.sees
	z._dir = signf(d.x) if d.x != 0.0 else z._dir
	var target_a: float = (pl.global_position + Vector2(0, -30) - (z.global_position + Vector2(z._dir * 4.0, -54.0 * z.sc))).angle()
	_scan_a = lerp_angle(_scan_a, target_a + sin(z._time * 3.0) * 0.12, delta * 4.0)
	# ---- תצפית: השחקן עומד ויורה מאותו מקום? ----
	if _seeing:
		var pp: Vector2 = pl.global_position
		if pp.distance_to(_obs_spot) < 90.0:
			_obs += delta
		else:
			_obs_spot = pp
			_obs = 0.0
		if _scan_cd <= 0.0:
			_scan_cd = randf_range(3.0, 4.5)
			Sfx.play("tac_scan", z.global_position, -6.0, 0.05, 2)
	else:
		_obs = maxf(0.0, _obs - delta * 0.5)
	var camping: bool = PlayerMemory.is_camping() or _obs > 3.0
	var dr := director()
	if _seeing and camping and _flank_cd <= 0.0 and dr != null:
		var n: int = dr.order_flank(z, pl)
		if n > 0:
			flank_orders += 1
			_point_t = 1.4
			_obs = 0.0
			_flank_cd = 7.0
			Sfx.play("tac_order", z.global_position, 2.0, 0.05, 2)
		else:
			_flank_cd = 1.5
	# ---- השחקן טוען מולו: "עכשיו!" ----
	if _seeing and _cmd_cd <= 0.0 and dr != null and pl.is_reloading() and dist < 600.0:
		_cmd_cd = 9.0
		if dr.command(z, "ATTACK", 420.0, 1.8) > 0:
			attack_orders += 1
			_point_t = 1.0
	# ---- שומר מרחק ----
	if _point_t > 0.0:
		return 0.0
	if dist < 70.0:   # נלכד: נלחם
		return speed * 0.5
	if dist < 300.0:
		z._dir = -signf(d.x)
		return speed * 0.9
	if dist > 470.0:
		return speed * 0.7
	return 0.0


func on_damage(_amount: int, _hit_pos: Vector2, _dir: Vector2, _src: Dictionary) -> bool:
	_obs = 0.0
	return true


func draw() -> bool:
	begin_draw()
	var sk := col(z.skin)
	var coat := col(z.shirt)
	var coat_d := col(Art.shade(z.shirt, 0.3))
	var p: float = z._walk_phase
	var t: float = z._time
	var f: Array = feet(5.5, 2.5)
	var hip := Vector2(0.0, -23.0)
	var sh := Vector2(1.0, -42.0)          # זקוף - כתפיים מעל הירכיים
	var head := sh + Vector2(1.5, -8.5)
	# רגליים ארוכות
	z._leg(hip + Vector2(-1.5, 0), f[1], col(Art.shade(z.pants, 0.2)), col(Art.shade(z.skin, 0.25)), col(z.shoe))
	z._leg(hip + Vector2(1.5, 0), f[0], col(z.pants), sk, col(z.shoe))
	# יד אחורית מאחורי הגב
	Art.limb(z, PackedVector2Array([sh + Vector2(-2, 1), sh + Vector2(-6, 9), hip + Vector2(-5, -3)]), 3.4, coat_d)
	# מעיל ארוך שמתנופף
	var flap := sin(t * 2.2) * 2.0 + absf(z.velocity.x) * 0.03
	var coat_pts := PackedVector2Array([sh + Vector2(-5, -1), sh + Vector2(5, -1), hip + Vector2(6, 2), hip + Vector2(7, 14), hip + Vector2(1, 12), hip + Vector2(-5, 15), hip + Vector2(-9 - flap, 12), hip + Vector2(-6, 2)])
	Art.fill_shaded(z, coat_pts, coat, 0.15, 0.4)
	z.draw_line(sh + Vector2(1, 0), hip + Vector2(2, 12), col(Art.shade(z.shirt, 0.45)), 1.0)   # שסע המעיל
	for i in 3:   # כפתורים
		z.draw_circle(sh.lerp(hip, 0.2 + float(i) * 0.25) + Vector2(3.5, 0), 0.8, col(Color("a89060")))
	# יד מצביעה (פקודה) / מחזיקה מקל מדידה
	var pointing: bool = _point_t > 0.0 and not z.dead
	var hand := sh + (Vector2(17, -5) if pointing else Vector2(8, 14))
	Art.limb(z, PackedVector2Array([sh + Vector2(3, 1), sh + (Vector2(10, -2) if pointing else Vector2(6, 7)), hand]), 3.4, coat)
	Art.disc(z, hand, 2.0, sk)
	if pointing:
		z.draw_line(hand, hand + Vector2(5, -1), sk, 1.4)   # אצבע
	else:
		z.draw_line(hand + Vector2(0, -2), hand + Vector2(1, 14), col(Color("6a5030")), 1.6)   # מקל
	# ראש + קסדה + עדשה
	Art.oval_shaded(z, head, 6.2, 7.2, sk, 0.0)
	z.draw_line(head + Vector2(1.0, 3.5), head + Vector2(5.5, 3.0), Color(0.15, 0.05, 0.05), 1.0)   # פה סגור בקו (רגוע)
	Art.oval(z, head + Vector2(-0.5, 0.0), 1.2, 1.0, Color("1a0e0e"), 0.0, Art.NONE)
	var helm := PackedVector2Array([head + Vector2(-7, -2), head + Vector2(-6, -7), head + Vector2(0, -10), head + Vector2(6, -7), head + Vector2(10, -3), head + Vector2(7, -2.5)])
	Art.fill_shaded(z, helm, col(Color("b0a060")), 0.2, 0.35)
	z.draw_line(head + Vector2(-2, -9), head + Vector2(1, -5), Color(0.2, 0.15, 0.05, 0.7), 0.8)   # סדק
	# עדשת פליז
	var lens := head + Vector2(4.5, -1.0)
	Art.disc(z, lens, 2.8, col(Color("8a6a2a")))
	var teal := Color(0.3, 1.0, 0.85)
	var pulse := 0.6 + 0.4 * sin(t * 6.0)
	Art.glow(z, lens, 6.0, Color(teal, 0.55 * pulse))
	z.draw_circle(lens, 1.4, teal)
	if not z.dead:
		# טבעת "למידה" שמתמלאת
		var obs_k := clampf(_obs / 3.0, 0.0, 1.0)
		if obs_k > 0.02:
			z.draw_arc(lens, 4.6, -PI * 0.5, -PI * 0.5 + TAU * obs_k, 16, Color(teal, 0.9), 1.0)
		# קרן סריקה אל השחקן
		if _seeing:
			end_draw()
			var lw: Vector2 = z.global_position + Vector2(z._dir * lens.x * z.wf * z.sc, lens.y * z.sc)
			var a := _scan_a
			var ln := 120.0
			var o: Vector2 = lw - z.global_position
			z.draw_colored_polygon(PackedVector2Array([o, o + Vector2.from_angle(a - 0.09) * ln, o + Vector2.from_angle(a + 0.09) * ln]), Color(teal, 0.07 + 0.04 * pulse))
			z.draw_line(o, o + Vector2.from_angle(a) * ln, Color(teal, 0.2), 1.0)
			return true
	end_draw()
	return true
